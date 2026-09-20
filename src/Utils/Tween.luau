--[[
	Tween  ·  Aetheris UI Library

	Central tween registry and spin manager for the whole library. Every
	animation routes through Tween.Play so that:

	  * only one tween runs per instance + property-set at a time
	    (new tweens cancel the previous one instead of fighting it),
	  * tweens are tracked in a weak-keyed registry so destroyed
	    instances never leak,
	  * ThemeManager can blanket-cancel (CancelAll) and then restart the
	    infinite spin gradients (RestartSpins) after a theme switch.

	Public API: Play, Pause, Resume, Cancel, CancelAll, Group,
	CancelGroup, PauseGroup, ResumeGroup, StartSpin, StopSpin,
	PauseSpin, ResumeSpin, GateSpinOnVisibility, UngateSpin,
	SetSpinWanted, RestartSpins, SetSpinsEnabled, Presets,
	SpinsEnabled.
]]

local TweenService = game:GetService("TweenService")

local TweenUtil = {}

-- Canonical presets, pulled from every distinct TweenInfo actually used across
-- the existing mechanics scripts. Where a name was reused with two different
-- values (e.g. T_SMOOTH was 0.3 in UIConstants/TextInput but 0.4 in Slider/
-- ColorPicker), the UIConstants value wins as canonical and the pieces that
-- drifted should be migrated to use this module instead of their own locals.
TweenUtil.Presets = {
	Fast         = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Smooth       = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	Burst        = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	SpinIdle     = TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0),
	SpinBurst    = TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0),
	Click        = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	ClickQuint   = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
	Release      = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	ClickRelease = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	HoverIn      = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	HoverOut     = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Hover        = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	OnOff        = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	PageSwap     = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	FadeOut      = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	Minimize     = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	MinimizeSnappy = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

-- activeTweens[instance][propertyKey] = handle
-- Weak keys: if an instance is destroyed and dropped elsewhere, its tween
-- bookkeeping doesn't keep it (or itself) alive in memory.
local activeTweens = setmetatable({}, { __mode = "k" })

-- Forward declaration: the spin registry is declared further down, but Cancel/
-- CancelAll must be able to clear a spin's handle when they kill its tween.
-- Without this, a theme switch's blanket CancelAll leaves
-- spinHandles[inst].handle pointing at a dead tween, so ResumeSpin can never
-- start a live one again and every component spin silently freezes.
local spinHandles

local function propertyKey(properties)
	local firstKey = next(properties)
	if firstKey ~= nil and next(properties, firstKey) == nil then
		return tostring(firstKey)
	end
	local keys = {}
	for k in pairs(properties) do
		table.insert(keys, tostring(k))
	end
	table.sort(keys)
	return table.concat(keys, ",")
end

-- Play(instance, tweenInfoOrPresetName, properties, replace)
--
-- tweenInfoOrPresetName: a real TweenInfo, OR a string key into TweenUtil.Presets
-- replace (default true): if a tween is already running on this instance for
-- this exact set of properties, cancel it first instead of letting two
-- tweens fight over the same property. This generalizes the
-- `currentSpinTween:Cancel()` pattern from ButtonMechanics so every
-- component gets it for free.
--
-- Returns a handle: { Tween, Instance, Key, Paused }
function TweenUtil.Play(instance, tweenInfoOrPresetName, properties, replace)
	if replace == nil then
		replace = true
	end

	local tweenInfo = tweenInfoOrPresetName
	if type(tweenInfoOrPresetName) == "string" then
		tweenInfo = TweenUtil.Presets[tweenInfoOrPresetName]
		assert(tweenInfo, "Unknown tween preset: " .. tweenInfoOrPresetName)
	end

	local key = propertyKey(properties)
	activeTweens[instance] = activeTweens[instance] or {}

	local existing = activeTweens[instance][key]
	if existing and replace then
		existing.Tween:Cancel()
	end

	local tween = TweenService:Create(instance, tweenInfo, properties)
	local handle = {
		Tween = tween,
		Instance = instance,
		Key = key,
		Paused = false,
	}

	tween.Completed:Connect(function()
		local bucket = activeTweens[instance]
		if bucket and bucket[key] == handle then
			bucket[key] = nil
			if next(bucket) == nil then
				activeTweens[instance] = nil
			end
		end
	end)

	activeTweens[instance][key] = handle
	tween:Play()
	return handle
end

-- Pause a tween mid-motion without losing its current progress or resetting
-- the property. Cheap: keeps the Tween object alive for a quick Resume.
function TweenUtil.Pause(handle)
	if handle and handle.Tween then
		handle.Tween:Pause()
		handle.Paused = true
	end
end

-- Resume a paused tween from exactly where it left off.
function TweenUtil.Resume(handle)
	if handle and handle.Tween then
		handle.Tween:Play()
		handle.Paused = false
	end
end

-- Fully stop a tween and drop it from the registry so it (and its connection)
-- can be garbage collected. Use this over Pause when you don't expect to
-- resume soon and want the memory back (e.g. a component scrolled out of
-- view, or an infinite spin on something that's now hidden).
function TweenUtil.Cancel(handle)
	if not handle or not handle.Tween then
		return
	end
	handle.Tween:Cancel()
	local bucket = activeTweens[handle.Instance]
	if bucket then
		bucket[handle.Key] = nil
		if next(bucket) == nil then
			activeTweens[handle.Instance] = nil
		end
	end
	-- If this handle was a registered spin, drop it: a cancelled tween cannot
	-- be resumed, so ResumeSpin must build a fresh one on the next call.
	local spin = spinHandles[handle.Instance]
	if spin and spin.handle == handle then
		spin.handle = nil
	end
end

-- Stop every tracked tween running on a given instance at once -- e.g. when a
-- component is hidden or destroyed and you want to free every animation
-- attached to it in one call rather than tracking each handle individually.
function TweenUtil.CancelAll(instance)
	local bucket = activeTweens[instance]
	if not bucket then
		return
	end
	for _, handle in pairs(bucket) do
		handle.Tween:Cancel()
		-- Clear the spin's handle too, otherwise a theme switch's blanket
		-- CancelAll leaves every component spin pointing at a dead tween and
		-- ResumeSpin can never restart it.
		local spin = spinHandles[instance]
		if spin and spin.handle == handle then
			spin.handle = nil
		end
	end
	activeTweens[instance] = nil
end

-- Cancel every tracked tween on `root` AND all of its descendants in one sweep.
-- Iterates the SPARSE activeTweens registry (only instances that are actually
-- animating) instead of walking the whole GUI tree, so this is O(active tweens)
-- rather than O(descendants). ThemeManager uses this to blanket-cancel a window
-- before a theme switch without a per-descendant hash probe.
function TweenUtil.CancelAllUnder(root)
	if not root then
		return
	end
	-- Snapshot first: CancelAll nils entries in activeTweens, so we must not
	-- mutate the registry while iterating it.
	local snapshot = {}
	for instance in pairs(activeTweens) do
		if instance == root or instance:IsDescendantOf(root) then
			table.insert(snapshot, instance)
		end
	end
	for _, instance in ipairs(snapshot) do
		TweenUtil.CancelAll(instance)
	end
end

-- Play several tweens as one logical batch (mirrors TabController's pattern
-- of playing a list of tweens together for a single hover/active transition).
-- list = { {instance, tweenInfoOrPresetName, properties}, ... }
-- Returns a list of handles you can pass to CancelGroup/PauseGroup/ResumeGroup.
function TweenUtil.Group(list)
	local handles = {}
	for _, entry in ipairs(list) do
		table.insert(handles, TweenUtil.Play(entry[1], entry[2], entry[3], entry[4]))
	end
	return handles
end

function TweenUtil.CancelGroup(handles)
	for _, handle in ipairs(handles) do
		TweenUtil.Cancel(handle)
	end
end

function TweenUtil.PauseGroup(handles)
	for _, handle in ipairs(handles) do
		TweenUtil.Pause(handle)
	end
end

function TweenUtil.ResumeGroup(handles)
	for _, handle in ipairs(handles) do
		TweenUtil.Resume(handle)
	end
end

-- ---------------------------------------------------------------------
-- SPIN MANAGEMENT (centralized spinning gradient control)
-- ---------------------------------------------------------------------

-- Weak table: instance -> spin handle (assigned to the forward declaration
-- made up near activeTweens so Cancel/CancelAll can clear stale handles).
spinHandles = setmetatable({}, { __mode = "k" })

-- Start an infinite spinning tween on a given instance (e.g. a UIGradient).
-- Returns a handle that can be passed to StopSpin.
-- propertyTable should contain the property to animate (e.g. { Rotation = 360 })
-- presetName defaults to "SpinIdle"
-- Global on/off for spinning gradients. When false, no spin tween runs;
-- StartSpin still REGISTERS the spin so enabling later can restart it.
TweenUtil.SpinsEnabled = true

-- Launch the infinite spin. The SpinIdle/SpinBurst presets carry
-- RepeatCount = -1, so ONE tween loops forever with no gap between cycles.
-- For a Rotation spin the 360 -> 0 reset each cycle is the same visual angle,
-- so it reads as a seamless, never-stopping 0 -> 360 sweep.
local function launchSpinSegment(instance, data)
	-- Use the PRESET directly: it carries RepeatCount = -1 (infinite), so the
	-- tween loops FOREVER with no gap between cycles. For a Rotation spin,
	-- 360 -> 0 at each loop is the SAME visual angle, so the reset is invisible
	-- and the whole thing reads as one continuous 0 -> 360 sweep.
	--
	-- (Previously this chained one-shot segments built from the CURRENT value;
	-- the frame gap between one segment finishing and the next starting caused
	-- the visible play -> pause -> play stutter, and rotation climbed
	-- 360 -> 720 -> 1080 instead of cleanly looping.)
	-- A freshly launched spin must always start from the property origin (0).
	-- TweenService captures the instance's CURRENT value as the tween's start,
	-- so rebuilding a spin after a theme switch's blanket CancelAll (which froze
	-- the rotation at ~180) without this reset would sweep 180 -> 360 forever
	-- instead of a full 0 -> 360. Reset first so every (re)launched spin is a
	-- complete sweep from 0, whether it comes from StartSpin or a ResumeSpin
	-- rebuild.
	for prop in pairs(data.properties) do
		pcall(function() instance[prop] = 0 end)
	end
	local handle = TweenUtil.Play(instance, data.preset or "SpinIdle", data.properties)
	data.handle = handle
end

function TweenUtil.StartSpin(instance, propertyTable, presetName)
	-- Cancel any existing spin on this instance
	TweenUtil.StopSpin(instance)

	-- The reset to 0 that guarantees a full sweep now lives in launchSpinSegment,
	-- so BOTH the initial launch here and the rebuild path in ResumeSpin get it.
	-- (Kept as a single source of truth so a rebuilt spin can never resume from
	-- a frozen mid-sweep angle.)

	-- Always register so a later enable can start it, even if spins are off now.
	local data = {
		handle = nil,
		properties = propertyTable,
		preset = presetName,
		paused = false,
		wanted = true,
	}
	spinHandles[instance] = data

	if not TweenUtil.SpinsEnabled then
		-- Spins are off: still register the gate so a later enable can resume
		-- this spin on screen without a manual restart.
		TweenUtil.GateSpinOnVisibility(instance)
		return nil
	end

	launchSpinSegment(instance, data)
	local handle = data.handle
	-- Auto-gate AFTER the handle exists: a spin only runs while its instance is
	-- on screen (paused, and resumed from its frozen angle, when hidden). Shared
	-- here so no component implements its own visibility handling.
	TweenUtil.GateSpinOnVisibility(instance)
	return handle
end

-- Stop and clean up a spinning tween on a given instance.
function TweenUtil.StopSpin(instance)
	TweenUtil.UngateSpin(instance)
	local data = spinHandles[instance]
	if data then
		if data.handle then
			TweenUtil.Cancel(data.handle)
		end
		spinHandles[instance] = nil
	end
end

-- Pause a spin WITHOUT losing its current rotation. Unlike StopSpin (which
-- cancels the tween and forgets it), the tween object is kept alive but paused,
-- so ResumeSpin picks the sweep back up from exactly the angle it was frozen
-- at instead of snapping back to 0. Use this for temporary hiding (a slider on
-- an inactive tab, a collapsed section): zero animation cost while hidden, and
-- no visual jump when it comes back.
function TweenUtil.PauseSpin(instance)
	local data = spinHandles[instance]
	if not data then
		return
	end
	data.paused = true
	if data.handle then
		TweenUtil.Pause(data.handle)
	end
end

-- Resume a spin paused by PauseSpin, continuing from its frozen rotation.
-- Returns true if the instance has a registered spin (whether or not it is
-- currently globally disabled), false if it was never registered so the caller
-- can fall back to a fresh StartSpin. If the handle was dropped (e.g. spins
-- were globally disabled) it is (re)created here.
function TweenUtil.ResumeSpin(instance)
	local data = spinHandles[instance]
	if not data then
		return false
	end
	data.paused = false
	if not TweenUtil.SpinsEnabled then
		return true
	end
	-- A handle can exist yet be dead (cancelled by a theme switch's blanket
	-- CancelAll). Only Resume a tween that is still playable/paused; otherwise
	-- build a fresh one, or the spin stays frozen forever.
	if
		data.handle
		and data.handle.Tween
		and data.handle.Tween.PlaybackState ~= Enum.PlaybackState.Cancelled
	then
		TweenUtil.Resume(data.handle)
	else
		launchSpinSegment(instance, data)
	end
	return true
end

-- ---------------------------------------------------------------------
-- VISIBILITY GATING (shared, so components don't each reinvent it)
-- ---------------------------------------------------------------------
-- GateSpinOnVisibility keeps an infinite spin running ONLY while its instance
-- is actually on screen. Roblox does NOT cascade Visible, so the whole ancestor
-- chain is walked: a spin inside an inactive tab's ContentScroller / a hidden
-- Settings page / a collapsed section is paused (costing nothing per frame) and
-- resumed from its frozen angle when the page comes back.
local spinGates = setmetatable({}, { __mode = "k" })

local function spinOnScreen(instance)
	local node = instance
	while node and node ~= game do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		elseif node:IsA("LayerCollector") then
			return node.Enabled
		end
		node = node.Parent
	end
	return true
end

function TweenUtil.GateSpinOnVisibility(instance)
	if spinGates[instance] then
		return
	end
	local state = { connections = {}, ancestry = nil, destroying = nil }
	spinGates[instance] = state

	local function sync()
		local data = spinHandles[instance]
		if not data then
			return
		end
		-- A spin runs only when the component WANTS it and it is on screen.
		if data.wanted and spinOnScreen(instance) then
			TweenUtil.ResumeSpin(instance)
		else
			TweenUtil.PauseSpin(instance)
		end
	end

	local function unbind()
		for _, connection in ipairs(state.connections) do
			connection:Disconnect()
		end
		table.clear(state.connections)
	end

	local function bind()
		unbind()
		local node = instance
		while node and node ~= game do
			if node:IsA("GuiObject") then
				table.insert(
					state.connections,
					node:GetPropertyChangedSignal("Visible"):Connect(sync)
				)
			elseif node:IsA("LayerCollector") then
				table.insert(
					state.connections,
					node:GetPropertyChangedSignal("Enabled"):Connect(sync)
				)
				break
			end
			node = node.Parent
		end
	end

	bind()
	state.ancestry = instance.AncestryChanged:Connect(bind)
	state.destroying = instance.Destroying:Connect(function()
		TweenUtil.UngateSpin(instance)
	end)
	sync()
end

-- Declare whether a spin SHOULD run at all, independent of visibility and the
-- global toggle. An OFF Toggle's sheen is invisible, so it doesn't WANT to spin
-- even though it's on screen -- SetSpinWanted(gradient, false) parks it at zero
-- cost without the visibility gate later resurrecting it. Composition: a spin
-- actually runs only when wanted AND SpinsEnabled AND on screen.
function TweenUtil.SetSpinWanted(instance, wanted)
	local data = spinHandles[instance]
	if not data then
		return
	end
	data.wanted = wanted
	if wanted then
		-- Resume now if allowed; if it's off screen the gate keeps it paused and
		-- will resume it when it comes back.
		if spinOnScreen(instance) then
			TweenUtil.ResumeSpin(instance)
		end
	else
		TweenUtil.PauseSpin(instance)
	end
end

-- Remove a gate (called by StopSpin: a permanently stopped spin no longer needs
-- its visibility connections).
function TweenUtil.UngateSpin(instance)
	local state = spinGates[instance]
	if not state then
		return
	end
	for _, connection in ipairs(state.connections) do
		connection:Disconnect()
	end
	table.clear(state.connections)
	if state.ancestry then
		state.ancestry:Disconnect()
		state.ancestry = nil
	end
	if state.destroying then
		state.destroying:Disconnect()
		state.destroying = nil
	end
	spinGates[instance] = nil
end

-- Restart every registered spin. Call this after a blanket CancelAll pass
-- (theme switches cancel every tween on the window, which would otherwise
-- permanently stop all component spin gradients).
function TweenUtil.RestartSpins()
	-- Snapshot first: StartSpin (re)writes spinHandles, and mutating a table
	-- while iterating it with pairs can skip entries, leaving some spins dead.
	local snapshot = {}
	for instance, data in pairs(spinHandles) do
		table.insert(snapshot, { instance = instance, data = data })
	end
	for _, entry in ipairs(snapshot) do
		local instance = entry.instance
		local data = entry.data
		if instance and instance.Parent and data.properties then
			if data.paused then
				-- A deliberately paused spin stays paused. The blanket CancelAll killed
				-- its tween, so drop the dead handle; when the spin next resumes,
				-- ResumeSpin rebuilds it via launchSpinSegment, which resets rotation
				-- to 0 so the sweep is a full 0 -> 360 rather than a partial arc.
				data.handle = nil
			else
				TweenUtil.StartSpin(instance, data.properties, data.preset)
			end
		end
	end
end

-- Turn spins on/off globally. Disabling stops all active spins (and resets
-- their rotation to 0); enabling restarts every registered spin.
function TweenUtil.SetSpinsEnabled(enabled)
	TweenUtil.SpinsEnabled = enabled
	if enabled then
		TweenUtil.RestartSpins()
		return
	end
	local snapshot = {}
	for instance, data in pairs(spinHandles) do
		table.insert(snapshot, { instance = instance, data = data })
	end
	for _, entry in ipairs(snapshot) do
		local instance = entry.instance
		local data = entry.data
		if data.handle then
			TweenUtil.Cancel(data.handle)
			data.handle = nil
		end
		if instance and instance.Parent then
			for prop in pairs(data.properties) do
				pcall(function() instance[prop] = 0 end)
			end
		end
	end
end

return TweenUtil
