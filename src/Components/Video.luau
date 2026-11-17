--[[
	Aetheris/Components/Video.luau

	Video player with a configurable source, height and looping. VideoFrame has
	no transparency, so fading rides a tagged UIGradient (see Utils/VideoFade).
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
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
	local frame = Instance.new("Frame")
	frame.Name = UUID.Static("Video")
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = (theme and theme.ComponentBackgroundColor)
	frame.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.Position = UDim2.fromScale(0, 0.8891) -- from export; anchor stays at top
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame:SetAttribute(UUID.Static("IsComponentContainer"), true)
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
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
	-- Fades tween the tagged UIGradient instead of transparency.
	local fadeGradient = VideoFade.attach(videoFrame)
	self.FadeGradient = fadeGradient
	videoFrame.Video = videoId
	videoFrame.Looped = loop
	videoFrame.Volume = (Settings.Volume ~= nil) and Settings.Volume or 1
	videoFrame:Play()
	self.Frame = frame
	self.VideoFrame = videoFrame
	-- True while playback is wanted, so an explicit Pause() sticks.
	self._wantPlay = true
	ThemeManager.BindColor(frame, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(frame, "BackgroundTransparency", "ComponentBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	-- Pause off-page and resume on return; this is not gated.
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
	-- Register does not fire handlers, so sync to the real page state once.
	if not PageAwareness.IsActive(frame) and self._wantPlay then
		videoFrame:Pause()
	end
	self.Destroy = function(_self)
		if frame and frame.Parent then
			frame:Destroy()
		end
	end
	ComponentAPI.Apply(self, {
		Root = frame,
		Name = Settings.Name,
		Methods = {
			SetVideo = function(_, newVideoId)
				videoFrame.Video = newVideoId
				self._wantPlay = true
				videoFrame:Play()
			end,
			Play = function()
				self._wantPlay = true
				videoFrame:Play()
			end,
			Pause = function()
				self._wantPlay = false
				videoFrame:Pause()
			end,
			Stop = function()
				self._wantPlay = false
				videoFrame:Stop()
			end,
			SetVolume = function(_, volume)
				videoFrame.Volume = volume
			end,
			GetVolume = function()
				return videoFrame.Volume
			end,
			SetLoop = function(_, loopState)
				videoFrame.Looped = loopState
			end,
			SetHeight = function(_, newHeight)
				frame.Size = UDim2.new(1, 0, 0, newHeight)
			end,
			-- Fades the video in (0) or out (1) via its gradient.
			SetFade = function(_, value, duration)
				VideoFade.fade(fadeGradient, value, duration)
			end,
		},
	})
	return self
end
return Video
