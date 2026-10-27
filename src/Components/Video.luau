--[[
	Video  ·  Aetheris UI Library

	Video player component with a configurable source, height, and looping.
	Because VideoFrame.Transparency does not affect the rendered video, it
	fades via a tagged UIGradient instead (see Utils/VideoFade).

	Usage:
		local video = section:Video({
			VideoId = "rbxassetid://123456789",
			Loop = true,        -- default true
			Height = 100,       -- offset pixels, default 100
			Volume = 0.5,       -- 0..1, default 1
		})
]]

local VideoFade = require("../Utils/VideoFade")
local ThemeManager = require("../Themes/ThemeManager")
local ComponentAPI = require("../Utils/ComponentAPI")
local PageAwareness = require("../Utils/PageAwareness")
local UUID = require("../Utils/UUID")
local Video = {}
Video.__index = Video
function Video.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Video)
	self._theme = theme
	local videoId = Settings.VideoId or "rbxassetid://5670794788"
	local loop = Settings.Loop or true
	local height = Settings.Height or 100
	-- Container frame
	local frame = Instance.new("Frame")
	frame.Name = UUID.Static("Video")
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = (theme and theme.ComponentBackgroundColor)
	frame.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.Position = UDim2.fromScale(0, 0.8891) -- This position is from export; we'll keep anchor at top
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame:SetAttribute(UUID.Static("IsComponentContainer"), true)
	frame.Parent = parent
	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame
	-- Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	-- VideoFrame
	local videoFrame = Instance.new("VideoFrame")
	videoFrame.Name = UUID.Static("VideoFrame")
	videoFrame.BorderSizePixel = 0
	videoFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	videoFrame.BackgroundTransparency = 1
	videoFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	videoFrame.Size = UDim2.fromScale(1, 1)
	videoFrame.Position = UDim2.fromScale(0.5, 0.5)
	videoFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	videoFrame.Parent = frame
	local videoCorner = Instance.new("UICorner")
	videoCorner.CornerRadius = UDim.new(0, 6)
	videoCorner.Parent = videoFrame
	-- VideoFrame.Transparency does not render, so a UIGradient (FadeGradient)
	-- is used as the fade handle. The fade systems (Window minimize, tab
	-- switches) tween THIS instead. See Utils/VideoFade.lua.
	local fadeGradient = VideoFade.attach(videoFrame)
	self.FadeGradient = fadeGradient
	-- Load video
	videoFrame.Video = videoId
	videoFrame.Looped = loop
	-- Volume: Settings.Volume in 0..1 (default 1). nil is treated as 1.
	videoFrame.Volume = (Settings.Volume ~= nil) and Settings.Volume or 1
	videoFrame:Play()
	self.Frame = frame
	self.VideoFrame = videoFrame
	-- Whether the user/creator intends this video to be playing. Page switches
	-- pause off-page and resume on-page ONLY if this is true, so an explicit
	-- Pause() is never overridden when the page comes back.
	self._wantPlay = true
	-- Public API
	self.SetVideo = function(_, newVideoId)
		videoFrame.Video = newVideoId
		self._wantPlay = true
		videoFrame:Play()
	end
	self.Play = function()
		self._wantPlay = true
		videoFrame:Play()
	end
	self.Pause = function()
		self._wantPlay = false
		videoFrame:Pause()
	end
	self.Stop = function()
		self._wantPlay = false
		videoFrame:Stop()
	end
	self.SetVolume = function(_, volume)
		videoFrame.Volume = volume
	end
	self.GetVolume = function()
		return videoFrame.Volume
	end
	self.SetLoop = function(_, loopState)
		videoFrame.Looped = loopState
	end
	self.SetHeight = function(_, newHeight)
		frame.Size = UDim2.new(1, 0, 0, newHeight)
	end
	-- Fade the video in (0) or out (1) via its gradient.
	self.SetFade = function(_, value, duration)
		VideoFade.fade(fadeGradient, value, duration)
	end
	-- Declarative theming: the themed properties are BINDINGS -- no ApplyTheme
	-- body to forget. Bind applies immediately and re-resolves each switch.
	ThemeManager.BindColor(frame, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(frame, "BackgroundTransparency", "ComponentBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	-- Uniform component API (p2-4): visibility toggle + teardown.
	self.SetVisibility = function(_self, visible)
		frame.Visible = visible
	end
	-- Page awareness: pause the moment the page is switched away, resume when it
	-- returns -- but only if the video still intends to play. No Gate: pausing
	-- off-page is always on (it saves decode/battery while invisible).
	PageAwareness.Register(frame, {
		OnInactive = function()
			if self._wantPlay then
				videoFrame:Pause()
			end
		end,
		OnActive = function()
			if self._wantPlay then
				videoFrame:Play()
			end
		end,
	})
	-- Register doesn't fire handlers, so an off-page video built on an inactive
	-- tab would keep playing. Sync it to its real page state once.
	if not PageAwareness.IsActive(frame) and self._wantPlay then
		videoFrame:Pause()
	end
	self.Destroy = function(_self)
		if frame and frame.Parent then
			frame:Destroy()
		end
	end
	ComponentAPI.Apply(self, { Root = frame, Name = Settings.Name })
	return self
end
return Video
