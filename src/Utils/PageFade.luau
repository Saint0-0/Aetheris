--[[
	PageFade  ·  Aetheris UI Library

	Fades whole pages through one CanvasGroup.GroupTransparency per layer.
	This keeps component-owned transparency state untouched during transitions.
]]

local Tween = require("./Tween")
local UUID = require("./UUID")

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

-- Set the layer's fade instantly. 0 = visible, 1 = hidden.
function PageFade.Snap(layer, transparency)
	if not layer then
		return
	end
	Tween.CancelAll(layer)
	layer.GroupTransparency = transparency or 0
	PageFade.FadeDecorations(layer, (transparency or 0) >= 0.5, true)
end

-- CanvasGroup does not fade UIStroke/UIShadow, so a group fade explicitly
-- tweens each decoration to hidden or back to its PageFadeBase. The decoration
-- list is cached per layer and re-scanned only when the layer changes.
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
	if not group then
		return
	end
	for _, d in ipairs(getDecorations(group)) do
		-- Resting transparency. The theme system is the source of truth: every
		-- colour/number binding publishes its RESOLVED value as ThemeLive_<prop>
		-- (ThemeManager.applyEntry), so a theme-bound decoration's resting value
		-- tracks every theme switch. Read that; only fall back to the one-time
		-- PageFadeBase snapshot for a decoration the theme does NOT own (a fixed
		-- shadow, a component-set stroke).
		local themeRest = d:GetAttribute("ThemeLive_Transparency")
		local base
		if themeRest ~= nil then
			base = themeRest
		else
			base = d:GetAttribute("PageFadeBase")
		end
		if base == nil then
			-- Capture the resting transparency ONLY from a visible value. If the
			-- decoration is currently at the hidden sentinel (1) -- e.g. this page
			-- was hidden when a theme switch ran InvalidateDecorationBases and
			-- nil'd the base -- capturing 1 here would pin the stroke to fully
			-- invisible forever. Skip the capture; the next fade from a visible
			-- state records the real resting value.
			if d.Transparency < 1 then
				base = d.Transparency
				d:SetAttribute("PageFadeBase", base)
			end
		end
		-- If no base was captured (the decoration rests at the hidden sentinel 1,
		-- e.g. an unfocused search stroke), leave it at its CURRENT value on show
		-- instead of forcing it to 0 (which would snap it fully opaque).
		local target = hidden and 1 or (base or d.Transparency)
		if instant then
			-- Cancel ONLY this instance's Transparency tween so an in-flight
			-- theme Color crossfade on the same stroke/shadow is left running.
			Tween.CancelProperty(d, "Transparency")
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
		if onComplete then
			onComplete()
		end
		return
	end
	PageFade.FadeDecorations(layer, false, instant)
	if instant then
		Tween.CancelAll(layer)
		layer.GroupTransparency = 0
		if onComplete then
			onComplete()
		end
	else
		local h = Tween.Play(layer, PageFade.PRESET, { GroupTransparency = 0 })
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

-- Fade the layer fully out (hidden). `instant` snaps instead of tweening.
-- `onComplete` fires only on a normal finish (see Show).
function PageFade.Hide(layer, instant, onComplete)
	if not layer then
		if onComplete then
			onComplete()
		end
		return
	end
	PageFade.FadeDecorations(layer, true, instant)
	if instant then
		Tween.CancelAll(layer)
		layer.GroupTransparency = 1
		if onComplete then
			onComplete()
		end
	else
		local h = Tween.Play(layer, PageFade.PRESET, { GroupTransparency = 1 })
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
			-- Only count a real finish. A rapid tab spam Cancels an in-flight
			-- fade; the old code fired `done` on Cancelled too and could hide
			-- the outgoing page while a newer fade was still running.
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
			-- Only count a real finish. A rapid tab spam Cancels an in-flight
			-- fade; the old code fired `done` on Cancelled too and could hide
			-- the outgoing page while a newer fade was still running.
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

-- Theme-bound decorations read their resting value from ThemeLive_, so there is
-- nothing to clear here -- just re-mark dirty so the next fade re-scans.
function PageFade.InvalidateDecorationBases()
	for _, entry in pairs(decorationCache) do
		entry.dirty = true
	end
end

return PageFade
