--[[
	Aetheris/Utils/PageFade.luau

	Fades whole pages through one CanvasGroup.GroupTransparency per layer.
	This keeps component-owned transparency state untouched during transitions.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Tween = require("./Tween")
local UUID = require("./UUID")

local PageFade = {}

PageFade.TIME = 0.2

-- A preset name (not a TweenInfo) so it routes through Tween.Play's registry.
PageFade.PRESET = "Fast"

-- Window open/close/minimize uses a slower, more deliberate fade than page swaps.
PageFade.WINDOW_PRESET = "WindowFade"

function PageFade.Layer(parent, name)
	local cg = Instance.new("CanvasGroup")
	cg.Name = name or UUID.Generate("PageFadeLayer")
	cg.BackgroundTransparency = 1
	cg.BorderSizePixel = 0
	cg.AnchorPoint = Vector2.new(0, 0)
	cg.Position = UDim2.fromScale(0, 0)
	cg.Size = UDim2.fromScale(1, 1)
	cg.GroupTransparency = 0
	cg.Parent = parent
	return cg
end

function PageFade.Snap(layer, transparency)
	if not layer then
		return
	end
	Tween.CancelAll(layer)
	layer.GroupTransparency = transparency or 0
	PageFade.FadeDecorations(layer, (transparency or 0) >= 0.5, true)
end

-- CanvasGroup doesn't fade UIStroke/UIShadow, so those tween separately; cached per layer.
local decorationCache = setmetatable({}, { __mode = "k" })

local function getDecorations(group)
	local entry = decorationCache[group]
	if not entry then
		entry = { list = {}, dirty = true }
		decorationCache[group] = entry
		-- Structural changes only flip the flag; the re-scan happens on the next fade.
		group.DescendantAdded:Connect(function()
			entry.dirty = true
		end)
		group.DescendantRemoving:Connect(function()
			entry.dirty = true
		end)
	end
	if entry.dirty then
		table.clear(entry.list)
		for _, d in ipairs(group:GetDescendants()) do
			if d:IsA("UIStroke") or d:IsA("UIShadow") then
				entry.list[#entry.list + 1] = d
			end
		end
		entry.dirty = false
	end
	return entry.list
end

function PageFade.FadeDecorations(group, hidden, instant, preset)
	if not group then
		return
	end
	for _, d in ipairs(getDecorations(group)) do
		-- Resting transparency: prefer the theme's live value, fall back to the captured base.
		local themeRest = d:GetAttribute(UUID.Static("ThemeLive_Transparency"))
		local base
		if themeRest ~= nil then
			base = themeRest
		else
			base = d:GetAttribute(UUID.Static("PageFadeBase"))
		end
		if base == nil then
			-- Capture only from a visible value, or a hidden stroke would stay invisible forever.
			if d.Transparency < 1 then
				base = d.Transparency
				d:SetAttribute(UUID.Static("PageFadeBase"), base)
			end
		end
		-- No base: keep the current value rather than forcing the stroke opaque.
		local target = hidden and 1 or (base or d.Transparency)
		if instant then
			-- Cancel only Transparency so an in-flight theme Color crossfade keeps running.
			Tween.CancelProperty(d, "Transparency")
			d.Transparency = target
		else
			Tween.Play(d, preset or PageFade.PRESET, { Transparency = target })
		end
	end
end

-- `instant` snaps; `onComplete` fires only on a normal finish, never on a superseded fade.
-- `preset` overrides the fade preset (e.g. the slower WINDOW_PRESET for the shell).
function PageFade.Show(layer, instant, onComplete, preset)
	if not layer then
		if onComplete then
			onComplete()
		end
		return
	end
	PageFade.FadeDecorations(layer, false, instant, preset)
	if instant then
		Tween.CancelAll(layer)
		layer.GroupTransparency = 0
		if onComplete then
			onComplete()
		end
	else
		local h = Tween.Play(layer, preset or PageFade.PRESET, { GroupTransparency = 0 })
		if h and h.Tween and onComplete then
			h.Tween.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed then
					onComplete()
				end
			end)
		elseif onComplete then
			onComplete()
		end
	end
end

-- `instant` snaps; `onComplete` fires only on a normal finish.
function PageFade.Hide(layer, instant, onComplete, preset)
	if not layer then
		if onComplete then
			onComplete()
		end
		return
	end
	PageFade.FadeDecorations(layer, true, instant, preset)
	if instant then
		Tween.CancelAll(layer)
		layer.GroupTransparency = 1
		if onComplete then
			onComplete()
		end
	else
		local h = Tween.Play(layer, preset or PageFade.PRESET, { GroupTransparency = 1 })
		if h and h.Tween and onComplete then
			h.Tween.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed then
					onComplete()
				end
			end)
		elseif onComplete then
			onComplete()
		end
	end
end

-- Overlapped crossfade; `onComplete` fires once both layers finish.
function PageFade.Crossfade(outgoing, incoming, onComplete)
	local expected = 0
	local completed = 0
	local fired = false
	local function done()
		completed = completed + 1
		if completed >= expected and not fired then
			fired = true
			if onComplete then
				onComplete()
			end
		end
	end

	if outgoing then
		expected = expected + 1
		Tween.CancelAll(outgoing)
		PageFade.FadeDecorations(outgoing, true, false)
		local h = Tween.Play(outgoing, PageFade.PRESET, { GroupTransparency = 1 })
		if h and h.Tween then
			-- A cancelled fade must not count as finished.
			h.Tween.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed then
					done()
				end
			end)
		else
			done()
		end
	end

	if incoming then
		expected = expected + 1
		Tween.CancelAll(incoming)
		PageFade.FadeDecorations(incoming, false, false)
		local h = Tween.Play(incoming, PageFade.PRESET, { GroupTransparency = 0 })
		if h and h.Tween then
			-- A cancelled fade must not count as finished.
			h.Tween.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed then
					done()
				end
			end)
		else
			done()
		end
	end

	if expected == 0 and onComplete then
		onComplete()
	end
end

-- Theme-bound decorations resolve their resting value at fade time, so just re-mark dirty.
function PageFade.InvalidateDecorationBases()
	for _, entry in pairs(decorationCache) do
		entry.dirty = true
	end
end

return PageFade
