--[[
	Aetheris/Utils/PageFade.luau

	Fades whole pages through Utils/TreeFade instead of a CanvasGroup, so page
	content is never rasterised into the 1024px group texture that made wide
	windows and tall sections soft. Component-owned transparency is captured on
	hide and restored on show.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Tween = require("./Tween")
local TreeFade = require("./TreeFade")
local UUID = require("./UUID")

local PageFade = {}

PageFade.TIME = 0.2

-- A preset name (not a TweenInfo) so it routes through Tween.Play's registry.
PageFade.PRESET = "Fast"

PageFade.WINDOW_PRESET = "WindowFade"

-- Plain Frame layer; TreeFade owns the opacity. The window shell marks itself
-- to skip these roots so window fades and page fades stay independent.
function PageFade.Layer(parent, name)
	local layer = Instance.new("Frame")
	layer.Name = name or UUID.Generate("PageFadeLayer")
	layer.BackgroundTransparency = 1
	layer.BorderSizePixel = 0
	layer.AnchorPoint = Vector2.new(0, 0)
	layer.Position = UDim2.fromScale(0, 0)
	layer.Size = UDim2.fromScale(1, 1)
	layer.Parent = parent
	TreeFade.MarkRoot(layer)
	layer:SetAttribute(UUID.Static("FadeHidden"), true)
	return layer
end

local function skipRootsFor(layer)
	return layer:GetAttribute(UUID.Static("SkipFadeRoots")) == true
end

function PageFade.Snap(layer, transparency)
	if not layer then
		return
	end
	Tween.CancelAll(layer)
	TreeFade.Snap(layer, (transparency or 0) >= 0.5, skipRootsFor(layer))
end

-- CanvasGroup leaves UIStroke/UIShadow alone, so those tween separately.
-- Kept for the still-CanvasGroup minimize pill and popups.
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

-- The callback fires only on a normal finish; preset overrides the fade preset.
function PageFade.Show(layer, instant, onComplete, preset)
	if not layer then
		if onComplete then
			onComplete()
		end
		return
	end
	TreeFade.Set(layer, false, instant, preset or PageFade.PRESET, onComplete, skipRootsFor(layer))
end

function PageFade.Hide(layer, instant, onComplete, preset)
	if not layer then
		if onComplete then
			onComplete()
		end
		return
	end
	TreeFade.Set(layer, true, instant, preset or PageFade.PRESET, onComplete, skipRootsFor(layer))
end

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
		TreeFade.Set(outgoing, true, false, PageFade.PRESET, done, skipRootsFor(outgoing))
	end

	if incoming then
		expected = expected + 1
		TreeFade.Set(incoming, false, false, PageFade.PRESET, done, skipRootsFor(incoming))
	end

	if expected == 0 and onComplete then
		onComplete()
	end
end

-- Decorations resolve their resting value at fade time; re-mark them dirty.
function PageFade.InvalidateDecorationBases()
	for _, entry in pairs(decorationCache) do
		entry.dirty = true
	end
end

return PageFade
