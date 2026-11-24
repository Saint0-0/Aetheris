--[[
	Aetheris/Components/Carousel.luau

	Stacked page carousel of up to MAX_ITEMS image or video pages. Clicking the
	media crossfades to the next page; the frosted indicator shows the current
	page (with playback progress) and off-view videos pause.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local RunService = game:GetService("RunService")

local ThemeManager = require("../Themes/ThemeManager")
local ComponentAPI = require("../Utils/ComponentAPI")
local PageAwareness = require("../Utils/PageAwareness")
local Tween = require("../Utils/Tween")
local UUID = require("../Utils/UUID")

local Carousel = {}
Carousel.__index = Carousel
Carousel.MAX_ITEMS = 5

local DEFAULT_HEIGHT = 160
local CORNER = 6
local DOT = 6
local ACTIVE_W = 18
local SLOT_H = 6
local INDICATOR_PAD_X = 7
local INDICATOR_PAD_Y = 6
local INDICATOR_INSET = 10 -- px between the indicator capsule and the media edge
local FADE_PRESET = "Smooth"
local HIDE_DELAY = 0.34

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

-- Array part lists pages as { assetId, kind }; Height and Volume are keys.
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
	-- Silent by default; Settings.Volume opts back in.
	local volume = (Settings.Volume ~= nil) and Settings.Volume or 0
	local interval = tonumber(Settings.Interval) or 4
	-- AutoAdvance flips pages on a dwell timer; false disables it.
	local autoAdvance = Settings.AutoAdvance ~= false and interval > 0 and count > 1

	local self = setmetatable({}, Carousel)
	self._theme = theme
	self._index = 0
	self._pageCount = count
	self._advanceInterval = if autoAdvance then interval else 0
	self._advanceElapsed = 0
	self._lastVideoFraction = nil
	self._height = height

	local container = Instance.new("Frame")
	container.Name = UUID.Static("Carousel")
	container.BorderSizePixel = 0
	container.BackgroundColor3 = (theme and theme.ComponentBackgroundColor) or Color3.fromRGB(255, 255, 255)
	container.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	container.Size = UDim2.new(1, 0, 0, if count > 0 then height else 0)
	container.Position = UDim2.fromScale(0, 0)
	container.BorderColor3 = Color3.fromRGB(0, 0, 0)
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

	-- The viewport clips the stack; media carries the corners.
	local viewport = Instance.new("Frame")
	viewport.Name = UUID.Static("Viewport")
	viewport.BorderSizePixel = 0
	viewport.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.new(1, 0, 0, height)
	viewport.Position = UDim2.fromScale(0, 0)
	viewport.ClipsDescendants = true
	viewport.Active = true
	viewport.Parent = container
	self._viewport = viewport

	-- Frosted capsule indicator; the dots and active pill live inside.
	local indicator = Instance.new("Frame")
	indicator.Name = UUID.Static("Blobs")
	indicator.BorderSizePixel = 0
	indicator.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	indicator.BackgroundTransparency = 0.58
	indicator.AnchorPoint = Vector2.new(0.5, 1)
	indicator.Position = UDim2.new(0.5, 0, 1, -INDICATOR_INSET)
	indicator.Size = UDim2.fromOffset(0, SLOT_H + INDICATOR_PAD_Y * 2)
	indicator.AutomaticSize = Enum.AutomaticSize.X
	indicator.ZIndex = 11
	indicator.Parent = viewport
	pill(indicator)

	local indicatorStroke = Instance.new("UIStroke")
	indicatorStroke.Color = Color3.fromRGB(255, 255, 255)
	indicatorStroke.Transparency = 0.84
	indicatorStroke.Thickness = 1
	indicatorStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	indicatorStroke.Parent = indicator
	local indicatorShadow = Instance.new("UIShadow")
	indicatorShadow.Color = (theme and theme.PopupShadowColor) or Color3.fromRGB(0, 0, 0)
	indicatorShadow.Transparency = 0.55
	indicatorShadow.BlurRadius = UDim.new(0, 12)
	indicatorShadow.Parent = indicator
	ThemeManager.BindColor(indicatorShadow, "Color", "PopupShadowColor")

	local indicatorLayout = Instance.new("UIListLayout")
	indicatorLayout.FillDirection = Enum.FillDirection.Horizontal
	indicatorLayout.Padding = UDim.new(0, 6)
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
	local visuals = {}
	local videoFrames = {}

	for i, page in ipairs(pages) do
		local slot = Instance.new("Frame")
		slot.Name = UUID.Static("BlobSlot")
		slot.BorderSizePixel = 0
		slot.BackgroundTransparency = 1
		slot.Size = UDim2.fromOffset(if i == 1 then ACTIVE_W else DOT, SLOT_H)
		slot.LayoutOrder = i
		slot.ZIndex = 12
		slot.Parent = indicator

		local dot = Instance.new("Frame")
		dot.Name = UUID.Static("Dot")
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(0.5, 0.5)
		dot.Size = UDim2.fromOffset(DOT, DOT)
		dot.BackgroundColor3 = Color3.new(1, 1, 1)
		dot.BackgroundTransparency = 0.5
		dot.BorderSizePixel = 0
		dot.Visible = i ~= 1
		dot.ZIndex = 12
		dot.Parent = slot
		pill(dot)
		ThemeManager.BindColor(dot, "BackgroundColor3", "PrimaryTextColor")

		-- Active capsule: a soft track plus an accent fill that doubles as
		-- playback progress.
		local activePill = Instance.new("Frame")
		activePill.Name = UUID.Static("Pill")
		activePill.Size = UDim2.fromScale(1, 1)
		activePill.BackgroundColor3 = Color3.new(1, 1, 1)
		activePill.BackgroundTransparency = 0.7
		activePill.BorderSizePixel = 0
		activePill.Visible = i == 1
		activePill.ZIndex = 12
		activePill.Parent = slot
		pill(activePill)
		ThemeManager.BindColor(activePill, "BackgroundColor3", "PrimaryTextColor")
		local pillGlow = Instance.new("UIShadow")
		pillGlow.Color = (theme and theme.AccentColor) or Color3.fromRGB(96, 165, 250)
		pillGlow.Transparency = 0.6
		pillGlow.BlurRadius = UDim.new(0, 6)
		pillGlow.Parent = activePill
		ThemeManager.BindColor(pillGlow, "Color", "AccentColor")

		local fill = Instance.new("Frame")
		fill.Name = UUID.Static("PillFill")
		fill.Size = UDim2.fromScale(if i == 1 then (page.Video and 0 or 1) else 0, 1)
		fill.BackgroundColor3 = Color3.new(1, 1, 1)
		fill.BackgroundTransparency = 0
		fill.BorderSizePixel = 0
		fill.ZIndex = 13
		fill.Parent = activePill
		pill(fill)
		ThemeManager.BindColor(fill, "BackgroundColor3", "AccentColor")

		blobs[i] = { Slot = slot, Dot = dot, Pill = activePill, Fill = fill, Glow = pillGlow }

		-- Video pages need a CanvasGroup: a playing VideoFrame ignores both its
		-- own transparency and a gradient overlay. Image pages stay plain so the
		-- picture is never rasterised into a group texture.
		local isVideo = page.Video
		local pageFrame = Instance.new(if isVideo then "CanvasGroup" else "Frame")
		pageFrame.Name = UUID.Static("Page")
		pageFrame.BorderSizePixel = 0
		pageFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		pageFrame.BackgroundTransparency = 1
		pageFrame.Size = UDim2.fromScale(1, 1)
		pageFrame.Position = UDim2.fromScale(0, 0)
		pageFrame.ClipsDescendants = true
		if isVideo then
			pageFrame.GroupTransparency = if i == 1 then 0 else 1
		end
		pageFrame.Visible = i == 1
		pageFrame.ZIndex = 1
		pageFrame.Parent = viewport

		local visual
		local video
		if isVideo then
			local videoFrame = Instance.new("VideoFrame")
			videoFrame.Name = UUID.Static("PageVideo")
			videoFrame.BorderSizePixel = 0
			videoFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			videoFrame.BackgroundTransparency = 1
			videoFrame.Size = UDim2.fromScale(1, 1)
			videoFrame.Video = page.Id
			videoFrame.Looped = true
			videoFrame.Volume = volume
			videoFrame.ZIndex = 2
			videoFrame.Parent = pageFrame
			round(videoFrame, CORNER)
			video = videoFrame
			videoFrames[i] = videoFrame
			visual = videoFrame
		else
			local image = Instance.new("ImageLabel")
			image.Name = UUID.Static("PageImage")
			image.BorderSizePixel = 0
			image.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			image.BackgroundTransparency = 1
			image.Size = UDim2.fromScale(1, 1)
			image.Image = page.Id
			image.ScaleType = Enum.ScaleType.Crop
			image.ImageTransparency = if i == 1 then 0 else 1
			image.ZIndex = 2
			image.Parent = pageFrame
			round(image, CORNER)
			visual = image
		end

		visuals[i] = { Frame = pageFrame, Visual = visual, Video = video, Grouped = isVideo }
	end

	-- A single transparent button over the stack cycles pages on click.
	local clickCatcher = Instance.new("TextButton")
	clickCatcher.Name = UUID.Static("ClickCatcher")
	clickCatcher.BorderSizePixel = 0
	clickCatcher.BackgroundTransparency = 1
	clickCatcher.AutoButtonColor = false
	clickCatcher.Text = ""
	clickCatcher.Size = UDim2.fromScale(1, 1)
	clickCatcher.ZIndex = 10
	clickCatcher.Parent = viewport
	self._clickCatcher = clickCatcher
	clickCatcher.MouseButton1Click:Connect(function()
		if self._pageCount > 1 then
			self:_goTo((self._index + 1) % self._pageCount)
		end
	end)

	self._blobs = blobs
	self._visuals = visuals
	self._videos = videoFrames

	local function sync()
		self:_syncBlobs()
		self:_syncVideos()
	end
	self._sync = sync

	-- Off-view videos pause so only the visible page decodes.
	PageAwareness.Register(container, {
		OnActive = sync,
		OnInactive = sync,
	})

	-- Per-frame driver paints progress and advances pages when due.
	local progressConn = RunService.RenderStepped:Connect(function(dt)
		if not self.Frame or not self.Frame.Parent then
			return
		end
		if not PageAwareness.IsActive(self.Frame) then
			return
		end
		-- A stalled frame must not teleport the countdown.
		dt = math.min(dt, 0.1)
		local active = self._index + 1
		local blob = self._blobs[active]
		if not blob then
			return
		end
		if self._advanceInterval > 0 then
			self._advanceElapsed = self._advanceElapsed + dt
		end
		local video = self._videos[active]
		local advance = false
		if video then
			local fraction = videoFraction(video)
			self:_setBlobFill(active, fraction)
			if self._advanceInterval > 0 then
				if video.TimeLength > 0 then
					-- Video pages advance on loop wrap, after the blob fills.
					if self._lastVideoFraction and fraction < 0.1 and self._lastVideoFraction > 0.9 then
						advance = true
					end
					self._lastVideoFraction = fraction
				elseif self._advanceElapsed >= self._advanceInterval then
					-- A video with no reported length falls back to the dwell timer.
					advance = true
				end
			end
		elseif self._advanceInterval > 0 then
			self:_setBlobFill(active, self._advanceElapsed / self._advanceInterval)
			advance = self._advanceElapsed >= self._advanceInterval
		end
		if advance then
			self:_goTo((self._index + 1) % self._pageCount)
		end
	end)

	ComponentAPI.Apply(self, {
		Root = container,
		Name = Settings.Name,
		Methods = {
			-- Public pages are 1-based; the stack works in 0-based indices.
			SetPage = function(me, page)
				me:_goTo((tonumber(page) or 1) - 1)
			end,
			Next = function(me)
				me:_goTo((me._index + 1) % me._pageCount)
			end,
			Prev = function(me)
				me:_goTo((me._index - 1 + me._pageCount) % me._pageCount)
			end,
			GetPage = function(me)
				return me._index + 1
			end,
			GetPageCount = function(me)
				return me._pageCount
			end,
			-- Height in pixels, same as the Video component.
			SetHeight = function(me, newHeight)
				local pixels = tonumber(newHeight) or DEFAULT_HEIGHT
				me._height = pixels
				me.Frame.Size = UDim2.new(1, 0, 0, pixels)
				if me._viewport then
					me._viewport.Size = UDim2.new(1, 0, 0, pixels)
				end
			end,
			GetHeight = function(me)
				return me._height
			end,
		},
	})

	self.Destroy = function(me)
		if progressConn then
			progressConn:Disconnect()
			progressConn = nil
		end
		if me.Frame and me.Frame.Parent then
			me.Frame:Destroy()
		end
		me.Frame = nil
	end

	-- Prime the first page; PageAwareness re-syncs once it is on screen.
	sync()
	return self
end

-- Crossfades the outgoing page out while the incoming page fades in on top.
function Carousel:_goTo(index)
	if self._pageCount == 0 then
		return
	end
	index = math.clamp(index, 0, self._pageCount - 1)
	if index == self._index then
		return
	end
	local previous = self._index
	self._index = index

	self._advanceElapsed = 0
	self._lastVideoFraction = nil

	local function setOpacity(page, value)
		if page.Grouped then
			-- Video pages fade through their CanvasGroup.
			Tween.Play(page.Frame, FADE_PRESET, { GroupTransparency = value })
		else
			Tween.Play(page.Visual, FADE_PRESET, { ImageTransparency = value })
		end
	end

	-- Fixed ZIndex bands instead of a growing counter: the page stack has to
	-- stay under the indicator (11) and the click catcher (10) forever.
	for i, page in ipairs(self._visuals) do
		if i - 1 == index then
			page.Frame.Visible = true
			page.Frame.ZIndex = 2
			page.Visual.ZIndex = 3
			setOpacity(page, 0)
		elseif i - 1 == previous then
			page.Frame.ZIndex = 1
			page.Visual.ZIndex = 2
			setOpacity(page, 1)
			local pageNumber = i
			task.delay(HIDE_DELAY, function()
				if self._pageCount > 0 and pageNumber - 1 ~= self._index and page.Frame then
					page.Frame.Visible = false
					page.Frame.ZIndex = 1
					page.Visual.ZIndex = 2
				end
			end)
		else
			page.Frame.Visible = false
		end
	end

	if self._sync then
		self._sync()
	end
end

-- Direct set: the driver writes every frame, so no tween is needed.
function Carousel:_setBlobFill(index, fraction)
	local blob = self._blobs[index]
	if not blob then
		return
	end
	blob.Fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
end

function Carousel:_syncBlobs()
	local dwell = self._advanceInterval or 0
	for i, blob in ipairs(self._blobs) do
		local active = i - 1 == self._index
		blob.Dot.Visible = not active
		blob.Pill.Visible = active
		local targetWidth = active and ACTIVE_W or DOT
		if blob.Active ~= active then
			blob.Active = active
			Tween.Play(blob.Slot, "Smooth", { Size = UDim2.fromOffset(targetWidth, SLOT_H) })
		end
		if active then
			local video = self._videos[i]
			if video then
				self:_setBlobFill(i, videoFraction(video))
			else
				-- Images show the dwell countdown, full when auto-advance is off.
				local fraction = if dwell > 0 then (self._advanceElapsed or 0) / dwell else 1
				self:_setBlobFill(i, fraction)
			end
		end
	end
end

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
