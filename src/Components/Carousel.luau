--[[
	Aetheris/Components/Carousel.luau

	Horizontal page carousel: up to MAX_ITEMS image or video pages with a
	floating blob indicator over the media (the current blob doubles as the
	playing item's progress bar), drag swipe to change page, and off-view
	videos paused so only the visible page decodes.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local UserInputService = game:GetService("UserInputService")

local ThemeManager = require("../Themes/ThemeManager")
local ComponentAPI = require("../Utils/ComponentAPI")
local PageAwareness = require("../Utils/PageAwareness")
local Tween = require("../Utils/Tween")
local UUID = require("../Utils/UUID")
local VideoFade = require("../Utils/VideoFade")

local Carousel = {}
Carousel.__index = Carousel
Carousel.MAX_ITEMS = 5

local DEFAULT_HEIGHT = 160
local CORNER = 6
local SLOT_W = 20
local SLOT_H = 8
local DOT = 6
local INDICATOR_PAD_X = 8
local INDICATOR_PAD_Y = 5
local INDICATOR_INSET = 10 -- px between the indicator capsule and the media edge
local SWIPE_COMMIT = 44 -- px of travel before a swipe flips the page
local TICK = 0.05 -- dwell sampling rate
-- Each tick retargets the fill; a short linear tween bridges the gap so the
-- progress reads as one continuous sweep instead of 20 discrete jumps.
local FILL_TWEEN = TweenInfo.new(TICK * 1.6, Enum.EasingStyle.Linear)

-- Accept "rbxassetid://123", "123" or 123.
local function assetId(value)
	if type(value) == "number" then
		return "rbxassetid://" .. tostring(value)
	end
	if type(value) == "string" and value ~= "" and not value:find("rbxassetid://", 1, true) then
		return "rbxassetid://" .. value
	end
	return value
end

-- The table's array part is the page list: { {assetId, "image"|"video"}, ... };
-- Height/Volume ride as named keys alongside it.
local function collectPages(settings)
	local pages = {}
	for _, entry in ipairs(settings) do
		if #pages >= Carousel.MAX_ITEMS then
			warn("[Aetheris] Carousel takes at most " .. Carousel.MAX_ITEMS .. " items; extra ignored")
			break
		end
		if type(entry) == "table" and entry[1] ~= nil then
			pages[#pages + 1] = {
				Id = assetId(entry[1]),
				Video = tostring(entry[2] or "image"):lower() == "video",
			}
		end
	end
	return pages
end

-- 0..1 playback position; a still-loading video reports length 0.
local function videoFraction(video)
	local length = video.TimeLength
	if length <= 0 then
		return 0
	end
	return math.clamp(video.TimePosition / length, 0, 1)
end

local function round(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function pill(parent)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = parent
	return corner
end

function Carousel.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local pages = collectPages(Settings)
	local count = #pages
	local height = Settings.Height or DEFAULT_HEIGHT
	-- Muted by default: a carousel that shouts over the rest of the UI is a
	-- bug; callers can opt back in with Settings.Volume.
	local volume = (Settings.Volume ~= nil) and Settings.Volume or 0
	local interval = tonumber(Settings.Interval) or 4
	-- Auto-advance (user call): flip to the next page on a dwell timer,
	-- wrapping at the end. AutoAdvance = false opts out.
	local autoAdvance = Settings.AutoAdvance ~= false and interval > 0 and count > 1

	local self = setmetatable({}, Carousel)
	self._theme = theme
	self._index = 0
	self._pageCount = count
	self._conns = {}
	self._advanceInterval = if autoAdvance then interval else 0
	self._advanceElapsed = 0

	local container = Instance.new("Frame")
	container.Name = UUID.Static("Carousel")
	container.BorderSizePixel = 0
	container.BackgroundColor3 = (theme and theme.ComponentBackgroundColor) or Color3.fromRGB(255, 255, 255)
	container.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	container.Size = UDim2.new(1, 0, 0, if count > 0 then height else 0)
	container.Position = UDim2.fromScale(0, 0)
	container.BorderColor3 = Color3.fromRGB(0, 0, 0)
	-- The indicator floats over the media, so the shell is exactly one page
	-- tall; the corner clips every page edge to the card radius.
	container.ClipsDescendants = true
	container:SetAttribute(UUID.Static("IsComponentContainer"), true)
	container.Parent = parent
	self.Frame = container

	round(container, CORNER)
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = container
	ThemeManager.BindColor(container, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(container, "BackgroundTransparency", "ComponentBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")

	if count == 0 then
		warn("[Aetheris] Carousel needs at least one { assetId, kind } item")
		ComponentAPI.Apply(self, { Root = container, Name = Settings.Name })
		return self
	end

	-- The viewport owns the visible frame: it clips the page strip to its own
	-- rounded bounds, so a page never pokes a square corner out of the card.
	local viewport = Instance.new("Frame")
	viewport.Name = UUID.Static("Viewport")
	viewport.BorderSizePixel = 0
	viewport.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.new(1, 0, 0, height)
	viewport.Position = UDim2.fromScale(0, 0)
	viewport.ClipsDescendants = true
	-- The swipe handler lives on the viewport; it must sink input itself so
	-- a drag always lands here regardless of which page is under the cursor.
	viewport.Active = true
	viewport.Parent = container
	round(viewport, CORNER)
	self._viewport = viewport

	-- Track holds every page side by side; its X scale is in viewport widths,
	-- so page i sits at Position X = i and the track hides page i at -i.
	local track = Instance.new("Frame")
	track.Name = UUID.Static("Track")
	track.BorderSizePixel = 0
	track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	track.BackgroundTransparency = 1
	track.Size = UDim2.fromScale(count, 1)
	track.Position = UDim2.fromScale(0, 0)
	track.Parent = viewport
	self._track = track

	-- Indicator capsule: a dark scrim pill floating over the bottom of the
	-- media, so the dots read over any artwork (light pages included).
	local indicator = Instance.new("Frame")
	indicator.Name = UUID.Static("Blobs")
	indicator.BorderSizePixel = 0
	indicator.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	indicator.BackgroundTransparency = 0.72
	indicator.AnchorPoint = Vector2.new(0.5, 1)
	indicator.Position = UDim2.new(0.5, 0, 1, -INDICATOR_INSET)
	indicator.Size = UDim2.fromOffset(0, SLOT_H + INDICATOR_PAD_Y * 2)
	indicator.AutomaticSize = Enum.AutomaticSize.X
	indicator.ZIndex = 5
	indicator.Parent = viewport
	pill(indicator)
	local indicatorLayout = Instance.new("UIListLayout")
	indicatorLayout.FillDirection = Enum.FillDirection.Horizontal
	indicatorLayout.Padding = UDim.new(0, 4)
	indicatorLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	indicatorLayout.SortOrder = Enum.SortOrder.LayoutOrder
	indicatorLayout.Parent = indicator
	local indicatorPadding = Instance.new("UIPadding")
	indicatorPadding.PaddingLeft = UDim.new(0, INDICATOR_PAD_X)
	indicatorPadding.PaddingRight = UDim.new(0, INDICATOR_PAD_X)
	indicatorPadding.PaddingTop = UDim.new(0, INDICATOR_PAD_Y)
	indicatorPadding.PaddingBottom = UDim.new(0, INDICATOR_PAD_Y)
	indicatorPadding.Parent = indicator

	local blobs = {}
	local videos = {}

	for i, page in ipairs(pages) do
		-- Fixed-width slots keep the capsule from reflowing when a dot
		-- becomes a pill.
		local slot = Instance.new("Frame")
		slot.Name = UUID.Static("BlobSlot")
		slot.BorderSizePixel = 0
		slot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		slot.BackgroundTransparency = 1
		slot.Size = UDim2.fromOffset(SLOT_W, SLOT_H)
		slot.LayoutOrder = i
		slot.ZIndex = 5
		slot.Parent = indicator

		local dot = Instance.new("Frame")
		dot.Name = UUID.Static("Dot")
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(0.5, 0.5)
		dot.Size = UDim2.fromOffset(DOT, DOT)
		dot.BackgroundColor3 = Color3.new(1, 1, 1)
		dot.BackgroundTransparency = 0.55
		dot.BorderSizePixel = 0
		dot.ZIndex = 6
		dot.Parent = slot
		pill(dot)
		ThemeManager.BindColor(dot, "BackgroundColor3", "PrimaryTextColor")

		-- The active pill: faint white track plus an accent fill that doubles
		-- as the video's playback progress (a dwell countdown for images).
		local activePill = Instance.new("Frame")
		activePill.Name = UUID.Static("Pill")
		activePill.Size = UDim2.fromScale(1, 1)
		activePill.BackgroundColor3 = Color3.new(1, 1, 1)
		activePill.BackgroundTransparency = 0.82
		activePill.BorderSizePixel = 0
		activePill.Visible = false
		activePill.ZIndex = 6
		activePill.Parent = slot
		pill(activePill)

		local fill = Instance.new("Frame")
		fill.Name = UUID.Static("PillFill")
		fill.Size = UDim2.fromScale(if page.Video then 0 else 1, 1)
		fill.BackgroundColor3 = Color3.new(1, 1, 1)
		fill.BackgroundTransparency = 0
		fill.BorderSizePixel = 0
		fill.ZIndex = 7
		fill.Parent = activePill
		pill(fill)
		ThemeManager.BindColor(fill, "BackgroundColor3", "AccentColor")

		blobs[i] = { Dot = dot, Pill = activePill, Fill = fill }

		local pageFrame = Instance.new("Frame")
		pageFrame.Name = UUID.Static("Page")
		pageFrame.BorderSizePixel = 0
		pageFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		pageFrame.BackgroundTransparency = 1
		pageFrame.Size = UDim2.fromScale(1 / count, 1)
		-- Position scales against the track, so page i sits at i/count of it
		-- (= one viewport width per step).
		pageFrame.Position = UDim2.fromScale((i - 1) / count, 0)
		pageFrame.ClipsDescendants = true
		pageFrame.Parent = track
		round(pageFrame, CORNER)

		if page.Video then
			local videoFrame = Instance.new("VideoFrame")
			videoFrame.Name = UUID.Static("PageVideo")
			videoFrame.BorderSizePixel = 0
			videoFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			videoFrame.BackgroundTransparency = 1
			videoFrame.Size = UDim2.fromScale(1, 1)
			videoFrame.Video = page.Id
			videoFrame.Looped = true
			videoFrame.Volume = volume
			videoFrame.Parent = pageFrame
			-- Window/tab fades tween this gradient; VideoFrame has no transparency.
			VideoFade.attach(videoFrame)
			videos[i] = videoFrame
			-- Drive the active pill from playback position.
			local conn = videoFrame:GetPropertyChangedSignal("TimePosition"):Connect(function()
				if i - 1 ~= self._index then
					return
				end
				self:_setBlobFill(i, videoFraction(videoFrame), false)
			end)
			table.insert(self._conns, conn)
		else
			local image = Instance.new("ImageLabel")
			image.Name = UUID.Static("PageImage")
			image.BorderSizePixel = 0
			image.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			image.BackgroundTransparency = 1
			image.Size = UDim2.fromScale(1, 1)
			image.Image = page.Id
			image.ScaleType = Enum.ScaleType.Crop
			image.Parent = pageFrame
		end
	end

	self._blobs = blobs
	self._videos = videos

	-- One sync point: blob visibility and video play state both follow the
	-- current page and whether the page itself is on screen.
	local function sync()
		self:_syncBlobs()
		self:_syncVideos()
	end
	self._sync = sync

	-- Off-view videos pause so only the visible page decodes (user call).
	PageAwareness.Register(container, {
		OnActive = sync,
		OnInactive = sync,
	})

	-- Drag swipe: mouse or touch, tracked through UserInputService so the
	-- drag keeps working when the cursor leaves the viewport.
	local dragging = false
	local dragStartX = 0
	local moveConn
	local endConn

	local function endDrag(ended)
		dragging = false
		if moveConn then
			moveConn:Disconnect()
			moveConn = nil
		end
		if endConn then
			endConn:Disconnect()
			endConn = nil
		end
		local dx = ended.Position.X - dragStartX
		if dx <= -SWIPE_COMMIT then
			self:_goTo(self._index + 1)
		elseif dx >= SWIPE_COMMIT then
			self:_goTo(self._index - 1)
		else
			-- A tap (or a short nudge) snaps back to the current page.
			self:_goTo(self._index)
		end
	end

	viewport.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		dragging = true
		dragStartX = input.Position.X
		Tween.CancelProperty(track, "Position")
		if moveConn then
			moveConn:Disconnect()
		end
		moveConn = UserInputService.InputChanged:Connect(function(changed)
			if not dragging then
				return
			end
			if
				changed.UserInputType ~= Enum.UserInputType.MouseMovement
				and changed.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end
			local vpWidth = viewport.AbsoluteSize.X
			if vpWidth <= 0 then
				return
			end
			local dx = changed.Position.X - dragStartX
			track.Position = UDim2.fromScale(math.clamp(-self._index + dx / vpWidth, -(count - 1), 0), 0)
		end)
		if endConn then
			endConn:Disconnect()
		end
		endConn = UserInputService.InputEnded:Connect(function(ended)
			if
				ended.UserInputType ~= Enum.UserInputType.MouseButton1
				and ended.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end
			endDrag(ended)
		end)
	end)

	-- Dwell timer: flips to the next page every interval seconds (wrapping)
	-- and draws the active image blob as a countdown fill. Videos keep their
	-- own playback progress on the pill instead.
	if autoAdvance then
		task.spawn(function()
			while true do
				task.wait(TICK)
				if not self.Frame or not self.Frame.Parent then
					return
				end
				-- Hold the countdown while dragging or while off screen.
				if dragging or not PageAwareness.IsActive(self.Frame) then
					continue
				end
				self._advanceElapsed = math.min(self._advanceElapsed + TICK, self._advanceInterval)
				local active = self._index + 1
				local blob = self._blobs[active]
				if blob and blob.Pill.Visible and not self._videos[active] then
					self:_setBlobFill(active, self._advanceElapsed / self._advanceInterval, true)
				end
				if self._advanceElapsed >= self._advanceInterval then
					self:_goTo((self._index + 1) % self._pageCount)
				end
			end
		end)
	end

	ComponentAPI.Apply(self, {
		Root = container,
		Name = Settings.Name,
		Methods = {
			-- Public pages are 1-based; the track works in 0-based offsets.
			SetPage = function(me, page)
				me:_goTo((tonumber(page) or 1) - 1)
			end,
			Next = function(me)
				me:_goTo(me._index + 1)
			end,
			Prev = function(me)
				me:_goTo(me._index - 1)
			end,
			GetPage = function(me)
				return me._index + 1
			end,
			GetPageCount = function(me)
				return me._pageCount
			end,
		},
	})

	self.Destroy = function(me)
		for _, conn in ipairs(me._conns) do
			conn:Disconnect()
		end
		table.clear(me._conns)
		if moveConn then
			moveConn:Disconnect()
			moveConn = nil
		end
		if endConn then
			endConn:Disconnect()
			endConn = nil
		end
		if me.Frame and me.Frame.Parent then
			me.Frame:Destroy()
		end
		me.Frame = nil
	end

	-- Prime the first page: Register fires OnInactive first, then a deferred
	-- OnActive when the page is on screen, so both syncs land here too.
	sync()
	return self
end

-- Slide the track to a page (0-based, clamped) and re-sync indicators/media.
function Carousel:_goTo(index)
	if self._pageCount == 0 then
		return
	end
	index = math.clamp(index, 0, self._pageCount - 1)
	self._index = index
	self._advanceElapsed = 0
	Tween.Play(self._track, "Smooth", { Position = UDim2.fromScale(-index, 0) })
	if self._sync then
		self._sync()
	end
end

-- Draw one blob's progress. Snapping is for page changes and video frames
-- (both already arrive smoothly); the dwell countdown tweens instead.
function Carousel:_setBlobFill(index, fraction, animate)
	local blob = self._blobs[index]
	if not blob then
		return
	end
	local size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
	if not animate then
		Tween.CancelProperty(blob.Fill, "Size")
		blob.Fill.Size = size
		return
	end
	Tween.Play(blob.Fill, FILL_TWEEN, { Size = size })
end

function Carousel:_syncBlobs()
	local dwell = self._advanceInterval or 0
	for i, blob in ipairs(self._blobs) do
		local active = i - 1 == self._index
		blob.Dot.Visible = not active
		blob.Pill.Visible = active
		if active then
			local video = self._videos[i]
			if video then
				self:_setBlobFill(i, videoFraction(video), false)
			else
				-- Images show the auto-advance countdown (full when the
				-- carousel is set to hold on one page).
				local fraction = if dwell > 0 then (self._advanceElapsed or 0) / dwell else 1
				self:_setBlobFill(i, fraction, false)
			end
		end
	end
end

-- Play only the current page's video, and only while its page is on screen.
function Carousel:_syncVideos()
	local onScreen = PageAwareness.IsActive(self.Frame)
	for i, video in pairs(self._videos) do
		if i - 1 == self._index and onScreen then
			video:Play()
		else
			video:Pause()
		end
	end
end

return Carousel
