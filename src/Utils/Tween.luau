--[[
	Aetheris/Utils/Tween.luau

	Central tween registry and spin manager. Play replaces conflicting tweens
	per instance/property and tracks them weakly so destroyed instances do not leak.
	Spins are infinite linear sweeps (gradient rotation, sheen offsets) with
	visibility gating so a hidden component costs nothing.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local TweenService = game:GetService("TweenService")

local TweenUtil = {}

-- Spin* presets are linear infinite sweeps for gradient rotation and sheen offsets.
TweenUtil.Presets = {
	Fast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Smooth = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	Burst = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	SpinIdle = TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0),
	SpinStat = TweenInfo.new(12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0),
	SpinBurst = TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0),
	Click = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	ClickQuint = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
	Release = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	ClickRelease = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	HoverIn = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	HoverOut = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Hover = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	OnOff = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	PageSwap = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	FadeOut = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	Minimize = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	MinimizeSnappy = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	WindowToggle = TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	WindowToggleSnappy = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	-- Window open/close/minimize shell fade: quick, so toggling the window feels immediate.
	WindowFade = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

-- Weak keys: a destroyed instance's tween bookkeeping must not keep it alive.
local activeTweens = setmetatable({}, { __mode = "k" })

-- Declared here so Cancel/CancelAll can clear spin handles; defined further down.
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

-- Returns a handle; replace (default true) cancels a conflicting tween on the same properties.
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
		-- Cancel fires the old tween's Completed synchronously, which may have nil'd the bucket.
		activeTweens[instance] = activeTweens[instance] or {}
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

-- Pause mid-motion without losing progress; cheap to Resume.
function TweenUtil.Pause(handle)
	if handle and handle.Tween then
		handle.Tween:Pause()
		handle.Paused = true
	end
end

function TweenUtil.Resume(handle)
	if handle and handle.Tween then
		handle.Tween:Play()
		handle.Paused = false
	end
end

-- Full stop: drops the tween from the registry so it can be collected.
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
	-- A cancelled spin cannot be resumed, so drop the handle.
	local spin = spinHandles[handle.Instance]
	if spin and spin.handle == handle then
		spin.handle = nil
	end
end

-- Stop every tracked tween on one instance at once.
function TweenUtil.CancelAll(instance)
	local bucket = activeTweens[instance]
	if not bucket then
		return
	end
	for _, handle in pairs(bucket) do
		handle.Tween:Cancel()
		local spin = spinHandles[instance]
		if spin and spin.handle == handle then
			spin.handle = nil
		end
	end
	activeTweens[instance] = nil
end

-- Cancel one property's tween without touching the others' (PageFade relies on this).
function TweenUtil.CancelProperty(instance, propertyName)
	local bucket = activeTweens[instance]
	if not bucket then
		return
	end
	local key = tostring(propertyName)
	local handle = bucket[key]
	if handle then
		handle.Tween:Cancel()
		bucket[key] = nil
		if next(bucket) == nil then
			activeTweens[instance] = nil
		end
	end
end

-- Cancel every tween under root by scanning the registry, preserving infinite spins.
function TweenUtil.CancelAllUnder(root)
	if not root then
		return
	end
	local snapshot = {}
	for instance in pairs(activeTweens) do
		if instance == root or instance:IsDescendantOf(root) then
			table.insert(snapshot, instance)
		end
	end
	for _, instance in ipairs(snapshot) do
		local bucket = activeTweens[instance]
		if bucket then
			for key, handle in pairs(bucket) do
				if not handle.isSpin then
					handle.Tween:Cancel()
					bucket[key] = nil
				end
			end
			if next(bucket) == nil then
				activeTweens[instance] = nil
			end
		end
	end
end

-- Play a list of tweens as one batch; returns handles for the helpers below.
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

-- Weak: instance -> spin data.
spinHandles = setmetatable({}, { __mode = "k" })

-- Global toggle; disabled spins still register so enabling can restart them.
TweenUtil.SpinsEnabled = true

-- Reset the property to 0 first so each launch is a full sweep.
local function launchSpinSegment(instance, data)
	for prop in pairs(data.properties) do
		pcall(function()
			instance[prop] = 0
		end)
	end
	local handle = TweenUtil.Play(instance, data.preset or "SpinIdle", data.properties)
	if handle then
		handle.isSpin = true
	end
	data.handle = handle
end

-- Start an infinite spin on one property (e.g. { Rotation = 360 }); returns a handle.
function TweenUtil.StartSpin(instance, propertyTable, presetName)
	TweenUtil.StopSpin(instance)

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
		TweenUtil.GateSpinOnVisibility(instance)
		return nil
	end

	launchSpinSegment(instance, data)
	local handle = data.handle
	-- Spins pause while their instance is off screen.
	TweenUtil.GateSpinOnVisibility(instance)
	return handle
end

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

-- Pause without losing the current angle; StopSpin forgets instead.
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

-- Resume a paused spin from its frozen angle; false if it was never registered.
function TweenUtil.ResumeSpin(instance)
	local data = spinHandles[instance]
	if not data then
		return false
	end
	data.paused = false
	if not TweenUtil.SpinsEnabled then
		return true
	end
	-- A blanket CancelAll can leave a dead handle; rebuild in that case.
	if data.handle and data.handle.Tween and data.handle.Tween.PlaybackState ~= Enum.PlaybackState.Cancelled then
		TweenUtil.Resume(data.handle)
	else
		launchSpinSegment(instance, data)
	end
	return true
end

-- Spins run only while their instance is on screen.
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
				table.insert(state.connections, node:GetPropertyChangedSignal("Visible"):Connect(sync))
			elseif node:IsA("LayerCollector") then
				table.insert(state.connections, node:GetPropertyChangedSignal("Enabled"):Connect(sync))
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

-- Declare whether a spin wants to run, independent of visibility and the global toggle.
function TweenUtil.SetSpinWanted(instance, wanted)
	local data = spinHandles[instance]
	if not data then
		return
	end
	data.wanted = wanted
	if wanted then
		if spinOnScreen(instance) then
			TweenUtil.ResumeSpin(instance)
		end
	else
		TweenUtil.PauseSpin(instance)
	end
end

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

-- Restart every registered spin, e.g. after a theme switch's CancelAll.
function TweenUtil.RestartSpins()
	-- Snapshot first; StartSpin rewrites the table being iterated.
	local snapshot = {}
	for instance, data in pairs(spinHandles) do
		table.insert(snapshot, { instance = instance, data = data })
	end
	for _, entry in ipairs(snapshot) do
		local instance = entry.instance
		local data = entry.data
		if instance and instance.Parent and data.properties then
			if data.paused then
				-- A paused spin stays paused; drop the dead handle so ResumeSpin rebuilds it.
				data.handle = nil
			else
				TweenUtil.StartSpin(instance, data.properties, data.preset)
			end
		end
	end
end

-- Global on/off; disabling stops every spin and resets it to 0.
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
				pcall(function()
					instance[prop] = 0
				end)
			end
		end
	end
end

return TweenUtil
