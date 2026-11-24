--[[
	Aetheris/Utils/ScrollFade.luau

	Scroll edge fade. `Attach` wraps a small ScrollingFrame in a CanvasGroup whose
	gradient is rebuilt from CanvasPosition; `AttachOverlay` paints a themed
	gradient band over the edges instead, for page-sized scrollers where a
	CanvasGroup would soften the content. One gate shows or hides every fade at
	once.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local UUID = require("./UUID")
local SettingsStore = require("../Core/Settings/SettingsStore")
local ThemeManager = require("../Themes/ThemeManager")

local ScrollFade = {}

local EDGE_FADE_PX = 18

-- Attached fades for the Visuals toggle; stale entries prune on the next pass.
local attached = {}
local edgeFadeEnabled = nil -- lazily resolved once, then owned by SetEnabled

local function isEnabled()
	if edgeFadeEnabled == nil then
		edgeFadeEnabled = SettingsStore.Get("EdgeFadeEnabled") == true
	end
	return edgeFadeEnabled
end

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

	-- Geometry, layout slot and z-order live on the wrapper so the swap is invisible.
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

-- Edge melt without a CanvasGroup. Used for page-sized scrollers: wrapping a
-- wide page in a CanvasGroup is what downscaled its text. This paints a thin
-- background-coloured overlay over each scrollable edge instead.
function ScrollFade.AttachOverlay(scroll, themeKey)
	local parent = scroll.Parent
	if not parent then
		error("[ScrollFade] AttachOverlay needs a parented scroll frame", 2)
	end

	local overlay = Instance.new("Frame")
	overlay.Name = UUID.Static("ScrollFadeOverlay")
	overlay.BorderSizePixel = 0
	overlay.BackgroundTransparency = 0
	overlay.AnchorPoint = scroll.AnchorPoint
	overlay.Position = scroll.Position
	overlay.Size = scroll.Size
	overlay.ZIndex = 10
	overlay.Active = false
	ThemeManager.BindColor(overlay, "BackgroundColor3", themeKey or "ContentBackgroundColor")
	-- Match the page fill's own transparency, so a themed translucent page
	-- does not get an opaque band laid over it.
	ThemeManager.BindTransparency(overlay, "BackgroundTransparency", "ContentBackgroundTransparency")

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	-- Transparent until the first sync measures the scroll position; otherwise
	-- the overlay would flash as a solid band on the first frame.
	gradient.Transparency = NumberSequence.new(1)
	gradient.Parent = overlay
	overlay.Parent = parent

	local function key(time, value)
		return NumberSequenceKeypoint.new(time, value)
	end

	local function sync()
		if not isEnabled() then
			-- Fully transparent overlay leaves the content untouched.
			gradient.Transparency = NumberSequence.new(1)
			return
		end
		local view = scroll.AbsoluteWindowSize.Y
		local content = scroll.AbsoluteCanvasSize.Y
		if view <= 0 or content <= 0 then
			return
		end
		local top = scroll.CanvasPosition.Y
		local bottom = math.max(content - view - top, 0)
		local hasTop = top > 0.5
		local hasBottom = bottom > 0.5
		local insetTop = math.clamp(math.clamp(top, 0, EDGE_FADE_PX) / view, 0, 0.45)
		local insetBottom = math.clamp(math.clamp(bottom, 0, EDGE_FADE_PX) / view, 0, 0.45)

		local keys = {}
		if hasTop then
			keys[#keys + 1] = key(0, 0)
			keys[#keys + 1] = key(math.max(insetTop, 0.001), 1)
		else
			keys[#keys + 1] = key(0, 1)
		end
		if hasBottom then
			keys[#keys + 1] = key(math.max(1 - insetBottom, 0.55), 1)
			keys[#keys + 1] = key(1, 0)
		else
			keys[#keys + 1] = key(1, 1)
		end
		gradient.Transparency = NumberSequence.new(keys)
	end
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(sync)
	scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(sync)
	scroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(sync)
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(sync)
	task.defer(sync)

	attached[#attached + 1] = { gradient = gradient, sync = sync }

	return overlay
end

return ScrollFade
