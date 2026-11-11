--[[
	Aetheris/Utils/ScrollFade.luau

	Scroll edge fade (design-notes 2/9): wrap a ScrollingFrame in a
	CanvasGroup whose Rotation-90 transparency gradient is rebuilt from the
	frame's CanvasPosition over an 18 px span, so content melts into the
	surface at both edges. The wrapper inherits the frame's rect, layout
	slot and z-order, and the frame fills it - callers keep using the same
	scroll instance. Returns the wrapper. One global gate (UI Settings >
	Visuals) shows or hides every attached fade at once.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local UUID = require("./UUID")
local SettingsStore = require("../Core/Settings/SettingsStore")

local ScrollFade = {}

local EDGE_FADE_PX = 18

-- Every attached fade, so the Visuals toggle can flip them all live; dead
-- entries (destroyed popups) are pruned on the next pass.
local attached = {}
local edgeFadeEnabled = nil -- lazily resolved once, then owned by SetEnabled

local function isEnabled()
	if edgeFadeEnabled == nil then
		edgeFadeEnabled = SettingsStore.Get("EdgeFadeEnabled") ~= false
	end
	return edgeFadeEnabled
end

-- Show/hide every scroll edge fade from one switch (UI Settings > Visuals).
function ScrollFade.SetEnabled(state)
	edgeFadeEnabled = state == true
	local live = {}
	for _, entry in ipairs(attached) do
		if entry.gradient.Parent then
			entry.sync()
			live[#live + 1] = entry
		end
	end
	attached = live
end

function ScrollFade.Attach(scroll)
	local parent = scroll.Parent
	if not parent then
		error("[ScrollFade] Attach needs a parented scroll frame", 2)
	end

	local fade = Instance.new("CanvasGroup")
	fade.Name = UUID.Static("ScrollFade")
	fade.BorderSizePixel = 0
	fade.BackgroundTransparency = 1
	fade.AnchorPoint = scroll.AnchorPoint
	fade.Position = scroll.Position
	fade.Size = scroll.Size
	fade.LayoutOrder = scroll.LayoutOrder
	fade.ZIndex = scroll.ZIndex
	fade.Parent = parent

	-- The frame fills the wrapper now; geometry, layout slot and z-order
	-- live on the wrapper so nothing outside the frame notices the swap.
	scroll.AnchorPoint = Vector2.new(0, 0)
	scroll.Position = UDim2.fromScale(0, 0)
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.Parent = fade

	-- Gradient last so it paints over the frame inside the group.
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Parent = fade

	local function sync()
		if not isEnabled() then
			-- Gate off: flat transparency so the wrapper paints untouched.
			gradient.Transparency = NumberSequence.new(0)
			return
		end
		local view = scroll.AbsoluteWindowSize.Y
		local content = scroll.AbsoluteCanvasSize.Y
		if view <= 0 or content <= 0 then
			return
		end
		local top = scroll.CanvasPosition.Y
		local bottom = math.max(content - view - top, 0)
		local above = math.clamp(top / EDGE_FADE_PX, 0, 1)
		local below = math.clamp(bottom / EDGE_FADE_PX, 0, 1)
		local keys = {
			NumberSequenceKeypoint.new(0, if above > 0.5 then 1 else 0),
		}
		if above > 0.002 then
			keys[#keys + 1] = NumberSequenceKeypoint.new(math.min(above, 0.45), 0)
		end
		if below > 0.002 then
			keys[#keys + 1] = NumberSequenceKeypoint.new(math.max(1 - below, 0.55), 0)
		end
		keys[#keys + 1] = NumberSequenceKeypoint.new(1, if below > 0.5 then 1 else 0)
		gradient.Transparency = NumberSequence.new(keys)
	end
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(sync)
	scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(sync)
	scroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(sync)
	task.defer(sync)

	attached[#attached + 1] = { gradient = gradient, sync = sync }

	return fade
end

return ScrollFade
