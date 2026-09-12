--[[
	VideoFade  ·  Aetheris UI Library

	VideoFrame.Transparency does not actually affect the rendered video, so the
	Video component puts a UIGradient ("FadeGradient", tagged IsVideoFade) on
	the frame and fades THAT instead. UIGradient.Transparency is a NumberSequence
	which TweenService cannot interpolate, so it is lerped manually per frame.

	Public API: attach, set, get, fade.
]]

local RunService = game:GetService("RunService")

local VideoFade = {}

function VideoFade.attach(videoFrame)
	local grad = Instance.new("UIGradient")
	grad.Name = "FadeGradient"
	grad:SetAttribute("IsVideoFade", true)
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

-- Easing curves matching the Tween presets used across the UI, so the video
-- fades in lockstep with everything else ("Smooth" = Quad InOut, "Fast" =
-- Quad Out). A raw linear lerp makes the video linger visibly at the start.
local EASING = {
	Out = function(t) return 1 - (1 - t) * (1 - t) end,
	InOut = function(t)
		if t < 0.5 then
			return 2 * t * t
		end
		return 1 - ((-2 * t + 2) ^ 2) / 2
	end,
	Linear = function(t) return t end,
}

-- Animate a video fade gradient's uniform transparency to `target` over
-- `duration`, using `easingName` ("Out"|"InOut"|"Linear"). Calls `onComplete`
-- when it finishes (or the gradient is gone).
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