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
	RestartSpins, SetSpinsEnabled, Presets, SpinsEnabled.
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

local function propertyKey(properties)
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
	end
	activeTweens[instance] = nil
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

-- Weak table: instance -> spin handle
local spinHandles = setmetatable({}, { __mode = "k" })

-- Start an infinite spinning tween on a given instance (e.g. a UIGradient).
-- Returns a handle that can be passed to StopSpin.
-- propertyTable should contain the property to animate (e.g. { Rotation = 360 })
-- presetName defaults to "SpinIdle"
-- Global on/off for spinning gradients. When false, no spin tween runs;
-- StartSpin still REGISTERS the spin so enabling later can restart it.
TweenUtil.SpinsEnabled = true

function TweenUtil.StartSpin(instance, propertyTable, presetName)
	-- Cancel any existing spin on this instance
	TweenUtil.StopSpin(instance)

	-- Reset every animated property to its starting value (0) BEFORE tweening,
	-- so a spin always sweeps from the same angle. Without this, a spin
	-- restarted after a theme switch resumes from whatever frozen angle it was
	-- cancelled at (e.g. 180) instead of starting at 0 like the sidebar tab.
	for prop in pairs(propertyTable) do
		pcall(function() instance[prop] = 0 end)
	end

	-- Always register so a later enable can start it, even if spins are off now.
	local data = {
		handle = nil,
		properties = propertyTable,
		preset = presetName,
	}
	spinHandles[instance] = data

	if not TweenUtil.SpinsEnabled then
		return nil
	end

	local handle = TweenUtil.Play(
		instance,
		presetName or "SpinIdle",
		propertyTable
	)
	data.handle = handle
	return handle
end

-- Stop and clean up a spinning tween on a given instance.
function TweenUtil.StopSpin(instance)
	local data = spinHandles[instance]
	if data then
		if data.handle then
			TweenUtil.Cancel(data.handle)
		end
		spinHandles[instance] = nil
	end
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
			TweenUtil.StartSpin(instance, data.properties, data.preset)
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
