--[[
	PageFade  ·  Aetheris UI Library

	The ONE source of truth for page transitions. A page is faded by a single
	CanvasGroup.GroupTransparency on a per-page layer -- never by scanning and
	snapshotting each descendant's own transparency.

	Why this exists: the old TabGroup / SettingsTabGroup fade systems captured a
	per-element transparency "base" into a cache and restored it on page return.
	That fights any component state that is itself encoded as transparency (a
	radio's selected image, a slider's sheen, a label's resting alpha), so a
	stale snapshot would REVERT a user's selection / hide elements after a theme
	or page switch. Collapsing a whole page into ONE GroupTransparency removes
	that entire class of bug: a page transition can never touch the per-element
	state a component owns.

	A CanvasGroup also fades a playing VideoFrame, so the page-level VideoFade
	special case is no longer needed for page transitions.

	Public API (used by Core/TabGroup and Core/Settings/SettingsTabGroup):
		PageFade.Layer(parent, name?) -> CanvasGroup
			Create a full-size, transparent CanvasGroup under `parent`. The
			caller reparents the page content into it. GroupTransparency is the
			page's fade value (0 = visible, 1 = hidden).

		PageFade.Snap(layer, transparency)
			Set GroupTransparency instantly (no tween). Cancels any in-flight
			fade on that layer first.

		PageFade.Show(layer, instant?)
			Fade the layer fully in (GroupTransparency -> 0). instant = true snaps.

		PageFade.Hide(layer, instant?)
			Fade the layer fully out (GroupTransparency -> 1). instant = true snaps.

		PageFade.Crossfade(outgoing, incoming, onComplete?)
			Overlapped crossfade: the incoming layer fades in (-> 0) WHILE the
			outgoing layer fades out (-> 1), both over PageFade.TIME so every page
			transition in the library is identical. onComplete fires once both
			tweens have finished.

	PageFade.TIME is the single shared page-transition duration so TabGroup,
	SettingsTabGroup and the window settings-button switch all match.
]]

local Tween = require("./Tween")

local PageFade = {}

-- The single shared page-transition duration. Every page fade in the library
-- uses this so all crossfades are the same speed.
PageFade.TIME = 0.2

-- Preset used for page transitions: the library's standard quick quad-out.
-- Kept as a name (not a TweenInfo) so it routes through Tween.Play's registry
-- (single-tween-per-instance, cancellation-safe).
PageFade.PRESET = "Fast"

-- Create a full-size transparent CanvasGroup under `parent`. The caller is
-- responsible for reparenting page content into it. Idempotency is not needed
-- here: each call is for a distinct page/tab.
function PageFade.Layer(parent, name)
	local cg = Instance.new("CanvasGroup")
	cg.Name = name or "PageFade"
	cg.BackgroundTransparency = 1
	cg.BorderSizePixel = 0
	cg.AnchorPoint = Vector2.new(0, 0)
	cg.Position = UDim2.new(0, 0, 0, 0)
	cg.Size = UDim2.new(1, 0, 1, 0)
	cg.GroupTransparency = 0
	cg.Parent = parent
	return cg
end

-- Set the layer's fade instantly. 0 = visible, 1 = hidden.
function PageFade.Snap(layer, transparency)
	if not layer then return end
	Tween.CancelAll(layer)
	layer.GroupTransparency = transparency or 0
	PageFade.FadeDecorations(layer, (transparency or 0) >= 0.5, true)
end

-- UIStroke / UIShadow are NOT covered by CanvasGroup.GroupTransparency, so a
-- group fade leaves strokes and shadows fully visible until Visible toggles --
-- they "pop" instead of fading. Fade them explicitly in sync: snapshot each
-- decoration's base Transparency once (stored as an attribute), then tween it
-- toward hidden (1) or back to that base. Called from Snap/Show/Hide so EVERY
-- group fade in the library (window, pill, tab pages, settings pages) fades its
-- shadows and strokes with the rest of the UI. The UIStroke/UIShadow set is
-- cached per layer (see getDecorations below), so a fade never walks the full
-- page subtree -- it touches only the decorations, and only re-scans when the
-- layer's contents actually change.
-- Per-layer decoration cache. Scanning group:GetDescendants() on every fade is
-- O(subtree) and runs TWICE per crossfade; instead we scan once, keep the list
-- of UIStroke/UIShadow instances, and only re-scan when the layer's contents
-- change (DescendantAdded/DescendantRemoving set a dirty flag). This keeps the
-- decoration pass proportional to the handful of decorations, not the page size.
local decorationCache = setmetatable({}, { __mode = "k" })

local function getDecorations(group)
	local entry = decorationCache[group]
	if not entry then
		entry = { list = {}, dirty = true }
		decorationCache[group] = entry
		-- One connection per layer (not per descendant). Structural changes only
		-- flip the flag; the actual re-scan happens lazily on the next fade.
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

function PageFade.FadeDecorations(group, hidden, instant)
	if not group then return end
	for _, d in ipairs(getDecorations(group)) do
		local base = d:GetAttribute("PageFadeBase")
		if base == nil then
			base = d.Transparency
			d:SetAttribute("PageFadeBase", base)
		end
		local target = hidden and 1 or base
		if instant then
			Tween.CancelAll(d)
			d.Transparency = target
		else
			Tween.Play(d, PageFade.PRESET, { Transparency = target })
		end
	end
end

-- Fade the layer fully in (visible). `instant` snaps instead of tweening.
-- `onComplete` (optional) fires once the fade FINISHED NORMALLY. It is NOT
-- called when the tween is cancelled by a later fade, so a caller that
-- sequences off it (e.g. "hide, then set Visible=false") can't run its
-- completion for a fade that was superseded.
function PageFade.Show(layer, instant, onComplete)
	if not layer then
		if onComplete then onComplete() end
		return
	end
	PageFade.FadeDecorations(layer, false, instant)
	if instant then
		Tween.CancelAll(layer)
		layer.GroupTransparency = 0
		if onComplete then onComplete() end
	else
		local h = Tween.Play(layer, PageFade.PRESET, { GroupTransparency = 0 })
		if h and h.Tween and onComplete then
			h.Tween.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed then onComplete() end
			end)
		elseif onComplete then
			onComplete()
		end
	end
end

-- Fade the layer fully out (hidden). `instant` snaps instead of tweening.
-- `onComplete` fires only on a normal finish (see Show).
function PageFade.Hide(layer, instant, onComplete)
	if not layer then
		if onComplete then onComplete() end
		return
	end
	PageFade.FadeDecorations(layer, true, instant)
	if instant then
		Tween.CancelAll(layer)
		layer.GroupTransparency = 1
		if onComplete then onComplete() end
	else
		local h = Tween.Play(layer, PageFade.PRESET, { GroupTransparency = 1 })
		if h and h.Tween and onComplete then
			h.Tween.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed then onComplete() end
			end)
		elseif onComplete then
			onComplete()
		end
	end
end

-- Overlapped crossfade. `outgoing` fades to 1 while `incoming` fades to 0,
-- both over PageFade.TIME. `onComplete` fires once BOTH have finished (or, if
-- a layer is missing, once the present one has).
function PageFade.Crossfade(outgoing, incoming, onComplete)
	local expected = 0
	local completed = 0
	local fired = false
	local function done()
		completed = completed + 1
		if completed >= expected and not fired then
			fired = true
			if onComplete then onComplete() end
		end
	end

	if outgoing then
		expected = expected + 1
		Tween.CancelAll(outgoing)
		PageFade.FadeDecorations(outgoing, true, false)
		local h = Tween.Play(outgoing, PageFade.PRESET, { GroupTransparency = 1 })
		if h and h.Tween then
			h.Tween.Completed:Connect(done)
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
			h.Tween.Completed:Connect(done)
		else
			done()
		end
	end

	if expected == 0 and onComplete then onComplete() end
end

return PageFade
