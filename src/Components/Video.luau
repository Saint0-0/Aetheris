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
		})
]]

local VideoFade = require("../Utils/VideoFade")
local ThemeManager = require("../Themes/ThemeManager")
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
	frame.Name = "Video"
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = (theme and theme.ComponentBackgroundColor)
	frame.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.Position = UDim2.new(0, 0, 0.8891, 0) -- This position is from export; we'll keep anchor at top
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame:SetAttribute("IsComponentContainer", true)
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
	videoFrame.Name = "VideoFrame"
	videoFrame.BorderSizePixel = 0
	videoFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	videoFrame.BackgroundTransparency = 1
	videoFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	videoFrame.Size = UDim2.new(1, 0, 1, 0)
	videoFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
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
	videoFrame:Play()
	self.Frame = frame
	self.VideoFrame = videoFrame
	-- Public API
	self.SetVideo = function(newVideoId)
		videoFrame.Video = newVideoId
		videoFrame:Play()
	end
	self.Play = function()
		videoFrame:Play()
	end
	self.Pause = function()
		videoFrame:Pause()
	end
	self.Stop = function()
		videoFrame:Stop()
	end
	self.SetLoop = function(loopState)
		videoFrame.Looped = loopState
	end
	self.SetHeight = function(newHeight)
		frame.Size = UDim2.new(1, 0, 0, newHeight)
	end
	self.SetVisibility = function(visible)
		frame.Visible = visible
	end
	-- Fade the video in (0) or out (1) via its gradient.
	self.SetFade = function(value, duration)
		VideoFade.fade(fadeGradient, value, duration)
	end
	-- Component-owned theming (see ThemeManager registry).
	function self:ApplyTheme(newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		self._theme = theme
		frame.BackgroundColor3 = theme.ComponentBackgroundColor or frame.BackgroundColor3
		frame.BackgroundTransparency = theme.ComponentBackgroundTransparency or frame.BackgroundTransparency
		stroke.Color = theme.StrokeColor or stroke.Color
		stroke.Transparency = theme.StrokeTransparency or stroke.Transparency
	end
	ThemeManager.Register(frame, self)
	return self
end
return Video