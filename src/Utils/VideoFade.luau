--[[
	Aetheris/Utils/VideoFade.luau

	Fades video through a tagged UIGradient, since VideoFrame.Transparency does
	not affect the rendered video. The NumberSequence is lerped per frame.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local RunService = game:GetService("RunService")
local UUID = require("./UUID")

local VideoFade = {}

-- Shared tag so fades (including Utils/TreeFade) can find the gradient.
VideoFade.ATTRIBUTE = UUID.Static("IsVideoFade")

function VideoFade.attach(videoFrame)
	local grad = Instance.new("UIGradient")
	grad.Name = UUID.Static("FadeGradient")
	grad:SetAttribute(VideoFade.ATTRIBUTE, true)
	grad.Transparency = NumberSequence.new(0)
	grad.Parent = videoFrame
	return grad
end

function VideoFade.set(grad, value)
	grad.Transparency = NumberSequence.new(value)
end

function VideoFade.get(grad)
	local kp = grad.Transparency.Keypoints
	if kp and kp[1] then
		return kp[1].Value
	end
	return 0
end

-- Easing matches the UI's tween presets; a raw linear lerp lingers at the start.
local EASING = {
	Out = function(t)
		return 1 - (1 - t) * (1 - t)
	end,
	InOut = function(t)
		if t < 0.5 then
			return 2 * t * t
		end
		return 1 - ((-2 * t + 2) ^ 2) / 2
	end,
	Linear = function(t)
		return t
	end,
}

function VideoFade.fade(grad, target, duration, easingName, onComplete)
	duration = duration or 0.3
	local ease = EASING[easingName or "Out"] or EASING.Out
	local start = VideoFade.get(grad)
	task.spawn(function()
		local t0 = os.clock()
		while true do
			if not grad.Parent then
				break
			end
			local raw = math.clamp((os.clock() - t0) / duration, 0, 1)
			VideoFade.set(grad, start + (target - start) * ease(raw))
			if raw >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		if onComplete then
			onComplete()
		end
	end)
end

return VideoFade
