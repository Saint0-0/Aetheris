--[[
	Aetheris/Components/Carousel.luau

	Horizontal page carousel: up to MAX_ITEMS image or video pages with a
	blob indicator row (the current blob doubles as the playing item's
	progress bar), drag swipe to change page, and off-view videos paused
	so only the visible page decodes.
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
local BLOB_ROW = 22
local SLOT_W = 20
local SLOT_H = 8
local DOT = 6
local SWIPE_COMMIT = 44 -- px of travel before a swipe flips the page

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

function Carousel.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local pages = collectPages(Settings)
	local count = #pages
	local height = Settings.Height or DEFAULT_HEIGHT
	-- Muted by default: a carousel that shouts over the rest of the UI is a
	-- bug; callers can opt back in with Settings.Volume.
	local volume = (Settings.Volume ~= nil) and Settings.Volume or 0

	local self = setmetatable({}, Carousel)
	self._theme = theme
	self._index = 0
	self._pageCount = count
	self._conns = {}

	local container = Instance.new("Frame")
	container.Name = UUID.Static("Carousel")
	container.BorderSizePixel = 0
	container.BackgroundColor3 = (theme and theme.ComponentBackgroundColor) or Color3.fromRGB(255, 255, 255)
	container.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	container.Size = UDim2.new(1, 0, 0, if count > 0 then height + BLOB_ROW + 6 else 0)
	container.Position = UDim2.fromScale(0, 0)
	container.BorderColor3 = Color3.fromRGB(0, 0, 0)
	-- Clips so the pages round through the container's own corner.
	container.ClipsDescendants = true
	container:SetAttribute(UUID.Static("IsComponentContainer"), true)
	container.Parent = parent
	self.Frame = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container
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

	local viewport = Instance.new("Frame")
	viewport.Name = UUID.Static("Viewport")
	viewport.BorderSizePixel = 0
	viewport.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.new(1, 0, 0, height)
	viewport.Position = UDim2.fromScale(0, 0)
	viewport.ClipsDescendants = true
	viewport.Parent = container

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
	self._viewport = viewport

	local blobRow = Instance.new("Frame")
	blobRow.Name = UUID.Static("Blobs")
	blobRow.BorderSizePixel = 0
	blobRow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	blobRow.BackgroundTransparency = 1
	blobRow.Position = UDim2.fromOffset(0, height + 6)
	blobRow.Size = UDim2.new(1, 0, 0, BLOB_ROW)
	blobRow.Parent = container

	-- Fixed-width slots keep the row from reflowing when a dot becomes a pill.
	local holder = Instance.new("Frame")
	holder.Name = UUID.Static("BlobHolder")
	holder.BorderSizePixel = 0
	holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromOffset(0, SLOT_H)
	holder.AutomaticSize = Enum.AutomaticSize.X
	holder.Parent = blobRow
	local holderLayout = Instance.new("UIListLayout")
	holderLayout.FillDirection = Enum.FillDirection.Horizontal
	holderLayout.Padding = UDim.new(0, 4)
	holderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	holderLayout.SortOrder = Enum.SortOrder.LayoutOrder
	holderLayout.Parent = holder

	local blobs = {}
	local videos = {}

	for i, page in ipairs(pages) do
		local slot = Instance.new("Frame")
		slot.Name = UUID.Static("BlobSlot")
		slot.BorderSizePixel = 0
		slot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		slot.BackgroundTransparency = 1
		slot.Size = UDim2.fromOffset(SLOT_W, SLOT_H)
		slot.LayoutOrder = i
		slot.Parent = holder

		local dot = Instance.new("Frame")
		dot.Name = UUID.Static("Dot")
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(0.5, 0.5)
		dot.Size = UDim2.fromOffset(DOT, DOT)
		dot.BackgroundColor3 = Color3.new(1, 1, 1)
		dot.BackgroundTransparency = 0.7
		dot.BorderSizePixel = 0
		dot.Parent = slot
		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(1, 0)
		dotCorner.Parent = dot
		ThemeManager.BindColor(dot, "BackgroundColor3", "PrimaryTextColor")

		-- The active pill: white track plus an accent fill that doubles as
		-- the video's playback progress (full for images).
		local pill = Instance.new("Frame")
		pill.Name = UUID.Static("Pill")
		pill.Size = UDim2.fromScale(1, 1)
		pill.BackgroundColor3 = Color3.new(1, 1, 1)
		pill.BackgroundTransparency = 0.85
		pill.BorderSizePixel = 0
		pill.Visible = false
		pill.Parent = slot
		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(0, 4)
		pillCorner.Parent = pill

		local fill = Instance.new("Frame")
		fill.Name = UUID.Static("PillFill")
		fill.Size = UDim2.fromScale(if page.Video then 0 else 1, 1)
		fill.BackgroundColor3 = Color3.new(1, 1, 1)
		fill.BackgroundTransparency = 0
		fill.BorderSizePixel = 0
		fill.Parent = pill
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 4)
		fillCorner.Parent = fill
		ThemeManager.BindColor(fill, "BackgroundColor3", "AccentColor")

		blobs[i] = { Dot = dot, Pill = pill, Fill = fill }

		local pageFrame = Instance.new("Frame")
		pageFrame.Name = UUID.Static("Page")
		pageFrame.BorderSizePixel = 0
		pageFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		pageFrame.BackgroundTransparency = 1
		pageFrame.Size = UDim2.fromScale(1 / count, 1)
		pageFrame.Position = UDim2.fromScale(i - 1, 0)
		pageFrame.Parent = track

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
				local length = videoFrame.TimeLength
				local fraction = if length > 0 then math.clamp(videoFrame.TimePosition / length, 0, 1) else 0
				blobs[i].Fill.Size = UDim2.fromScale(fraction, 1)
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
	Tween.Play(self._track, "Smooth", { Position = UDim2.fromScale(-index, 0) })
	if self._sync then
		self._sync()
	end
end

function Carousel:_syncBlobs()
	for i, blob in ipairs(self._blobs) do
		local active = i - 1 == self._index
		blob.Dot.Visible = not active
		blob.Pill.Visible = active
		if active then
			local video = self._videos[i]
			if video then
				local length = video.TimeLength
				local fraction = if length > 0 then math.clamp(video.TimePosition / length, 0, 1) else 0
				blob.Fill.Size = UDim2.fromScale(fraction, 1)
			else
				blob.Fill.Size = UDim2.fromScale(1, 1)
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
