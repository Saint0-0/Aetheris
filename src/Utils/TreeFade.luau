--[[
	Aetheris/Utils/TreeFade.luau

	Fades a whole UI subtree without a CanvasGroup. CanvasGroups rasterise their
	content into a texture capped at 1024px, so wide windows and tall pages came
	out soft; this walks the tree and tweens each instance's own opacity
	properties instead, leaving colours, layout and hit areas untouched.

	State is captured when a root hides and restored when it shows, so a page
	can sit invisible for a while without losing its per-component values.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Tween = require("./Tween")
local UUID = require("./UUID")
local VideoFade = require("./VideoFade")

local TreeFade = {}

-- Roots owned by another fade (page layers inside the window shell). A parent
-- fade can skip them so the two states never fight.
local roots = setmetatable({}, { __mode = "k" })

-- root -> { entries = flat instance/property/base triples }
local states = setmetatable({}, { __mode = "k" })

-- Every Set on a root bumps its generation; callbacks from superseded fades
-- (a fast tab double-click, a theme switch) then decline to run.
local generations = setmetatable({}, { __mode = "k" })

local HIDDEN_ATTRIBUTE = UUID.Static("FadeHidden")
local VEIL_ATTRIBUTE = UUID.Static("IsFadeVeil")

-- Fade modes per entry.
-- VALUE: a numeric opacity property that fades to 1 when hidden.
-- VIDEO: a tagged UIGradient whose NumberSequence carries video opacity.
-- VEIL: an opaque cover whose transparency fades to 0 (opaque) when hidden,
-- so rendering that has no transparency (ViewportFrame) can still fade.
local MODE_VALUE = 0
local MODE_VIDEO = 1
local MODE_VEIL = 2

function TreeFade.MarkRoot(root)
	if root then
		roots[root] = true
	end
end

function TreeFade.IsRoot(root)
	return roots[root] == true
end

-- Flat 4-tuples (instance, property, base, mode) keep a full-window capture
-- cheap: one array instead of thousands of small entry tables per switch.
local function captureProperty(entries, inst, prop, mode, base)
	local value = base
	if value == nil then
		value = inst[prop]
	end
	if type(value) == "number" then
		local index = #entries
		entries[index + 1] = inst
		entries[index + 2] = prop
		entries[index + 3] = value
		entries[index + 4] = mode or MODE_VALUE
	end
end

local function captureInstance(entries, inst)
	-- ViewportFrame has no transparency, so components cover it with a tagged
	-- veil and the fade inverts it: opaque when hidden, invisible when shown.
	if inst:IsA("GuiObject") and inst:GetAttribute(VEIL_ATTRIBUTE) == true then
		captureProperty(entries, inst, "BackgroundTransparency", MODE_VEIL)
		return
	end
	-- VideoFrame.Transparency does not affect rendered video; its tagged
	-- UIGradient is the only working fade.
	if inst:IsA("UIGradient") and inst:GetAttribute(VideoFade.ATTRIBUTE) == true then
		captureProperty(entries, inst, "Transparency", MODE_VIDEO, VideoFade.get(inst))
		return
	end
	-- CanvasGroups composite their children, so fading the group is enough.
	if inst:IsA("UIStroke") or inst:IsA("UIShadow") then
		captureProperty(entries, inst, "Transparency")
		return
	end
	if inst:IsA("CanvasGroup") then
		captureProperty(entries, inst, "GroupTransparency")
		return
	end
	if inst:IsA("GuiObject") then
		captureProperty(entries, inst, "BackgroundTransparency")
	end
	if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
		captureProperty(entries, inst, "TextTransparency")
		captureProperty(entries, inst, "TextStrokeTransparency")
	end
	if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
		captureProperty(entries, inst, "ImageTransparency")
	end
	if inst:IsA("ScrollingFrame") then
		captureProperty(entries, inst, "ScrollBarImageTransparency")
	end
	if inst:IsA("VideoFrame") then
		captureProperty(entries, inst, "Transparency")
	end
end

local function capture(root, skipRoots)
	local entries = {}
	local function visit(inst)
		captureInstance(entries, inst)
	end
	visit(root)
	local stack = { root }
	while #stack > 0 do
		local current = table.remove(stack)
		-- A CanvasGroup composites its children, so fading the group is enough.
		if current:IsA("CanvasGroup") then
			continue
		end
		for _, child in ipairs(current:GetChildren()) do
			if skipRoots and roots[child] then
				continue
			end
			visit(child)
			stack[#stack + 1] = child
		end
	end
	return { entries = entries }
end

local function durationOf(preset)
	local info = preset
	if type(info) == "string" then
		info = Tween.Presets[info]
	end
	if info and info.Time then
		return info.Time
	end
	return 0.3
end

local function apply(state, hidden, instant, preset)
	local handles = {}
	local entries = state.entries
	for index = 1, #entries, 4 do
		local inst, prop, base, mode = entries[index], entries[index + 1], entries[index + 2], entries[index + 3]
		if inst.Parent then
			local target = base
			if hidden then
				target = mode == MODE_VEIL and 0 or 1
			end
			Tween.CancelProperty(inst, prop)
			if mode == MODE_VIDEO then
				-- A NumberSequence cannot be tweened, so the gradient is lerped
				-- per frame by VideoFade instead.
				VideoFade.cancel(inst)
				if instant or math.abs(VideoFade.get(inst) - target) < 0.001 then
					inst.Transparency = NumberSequence.new(target)
				else
					local handle = VideoFade.fade(inst, target, durationOf(preset or TreeFade.PRESET), "InOut")
					if handle then
						table.insert(handles, handle)
					end
				end
			elseif instant or math.abs(inst[prop] - target) < 0.001 then
				inst[prop] = target
			else
				local handle = Tween.Play(inst, preset or TreeFade.PRESET, { [prop] = target })
				if handle then
					table.insert(handles, handle)
				end
			end
		end
	end
	return handles
end

local function after(handles, onComplete, duration)
	if not onComplete then
		return
	end
	local fired = false
	local function fire()
		if fired then
			return
		end
		fired = true
		onComplete()
	end
	if #handles == 0 then
		fire()
		return
	end
	local remaining = #handles
	for _, handle in ipairs(handles) do
		handle.Tween.Completed:Connect(function(playback)
			if playback ~= Enum.PlaybackState.Completed then
				return
			end
			remaining = remaining - 1
			if remaining <= 0 then
				fire()
			end
		end)
	end
	-- A cancelled tween never reports Completed, so a fallback keeps a
	-- superseded fade from stranding the caller. Generation guards discard it
	-- when a newer fade on the same root has taken over.
	task.delay(duration + 0.12, fire)
end

TreeFade.PRESET = "Fast"

-- Capturing a root that is already hidden would read the faded values and
-- overwrite the real base, so reuse the stored state in that case.
local function stateForHide(root, skipRoots)
	if root:GetAttribute(HIDDEN_ATTRIBUTE) == true then
		local existing = states[root]
		if existing then
			return existing
		end
	end
	local state = capture(root, skipRoots)
	states[root] = state
	return state
end

-- hidden=true captures the current look and fades out; hidden=false restores
-- the look captured on the last hide.
function TreeFade.Set(root, hidden, instant, preset, onComplete, skipRoots)
	if not root then
		if onComplete then
			onComplete()
		end
		return
	end
	local state
	if hidden then
		state = stateForHide(root, skipRoots)
	else
		state = states[root]
	end
	root:SetAttribute(HIDDEN_ATTRIBUTE, hidden == true)
	if not state then
		if onComplete then
			onComplete()
		end
		return
	end
	local generation = (generations[root] or 0) + 1
	generations[root] = generation
	local handles = apply(state, hidden, instant, preset)
	after(handles, function()
		if generations[root] ~= generation then
			return
		end
		if not hidden and states[root] == state then
			states[root] = nil
		end
		if onComplete then
			onComplete()
		end
	end, durationOf(preset))
end

function TreeFade.Snap(root, hidden, skipRoots)
	if not root then
		return
	end
	local state
	if hidden then
		state = stateForHide(root, skipRoots)
	else
		state = states[root]
		if not state then
			generations[root] = (generations[root] or 0) + 1
			root:SetAttribute(HIDDEN_ATTRIBUTE, false)
			return
		end
	end
	generations[root] = (generations[root] or 0) + 1
	root:SetAttribute(HIDDEN_ATTRIBUTE, hidden == true)
	apply(state, hidden, true)
end

-- True when this instance or an ancestor was left faded out.
function TreeFade.IsHidden(inst)
	local node = inst
	while node and node ~= game do
		if node:GetAttribute(HIDDEN_ATTRIBUTE) == true then
			return true
		end
		node = node.Parent
	end
	return false
end

return TreeFade
