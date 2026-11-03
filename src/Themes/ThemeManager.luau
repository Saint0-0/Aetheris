--[[
	Aetheris/Themes/ThemeManager.luau

	Resolves and applies themes, crossfading colors and restarting spins. Live
	colors are mirrored as attributes so handlers never read stale data.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeDefinitions = require("./ThemeDefinitions")
local Tween = require("../Utils/Tween")
local ActiveTheme = require("./ActiveTheme")
local PageFade = require("../Utils/PageFade")
local UUID = require("../Utils/UUID")

local ThemeManager = {}

-- Must be a number before ApplyTheme runs: TweenInfo.new errors on a nil time at the first animated binding.
ThemeManager.ColorFadeTime = 0.6

-- Independent of the merge base (Base), which only fills in the keys a theme omits.
ThemeManager.DefaultTheme = "Umbral"

-- Weak keys, so destroyed components drop out automatically.
ThemeManager._components = setmetatable({}, { __mode = "k" })

function ThemeManager.Register(root, component)
	if root and component then
		ThemeManager._components[root] = component
	end
end

-- Stamping ThemeOverride_<Property> makes the theme system skip that property, so custom colors survive theme switches.
local overrideCount = 0

function ThemeManager.SetColorOverride(instance, property, color)
	if not instance or not property then
		return
	end
	local attr = UUID.Static("ThemeOverride_" .. property)
	local had = instance:GetAttribute(attr) ~= nil
	if color then
		instance:SetAttribute(attr, color)
		instance[property] = color
		if not had then
			overrideCount += 1
		end
	else
		instance:SetAttribute(attr, nil)
		if had then
			overrideCount -= 1
		end
	end
end

function ThemeManager.ClearColorOverride(instance, property)
	if instance and property then
		local attr = UUID.Static("ThemeOverride_" .. property)
		if instance:GetAttribute(attr) ~= nil then
			instance:SetAttribute(attr, nil)
			overrideCount -= 1
		end
	end
end

-- Precedence on a switch: overrides win over bindings, which win over the prior value.

ThemeManager.THEME_KEYS = {
	"WindowColor",
	"WindowTransparency",
	"WindowControlColor",
	"ContentBackgroundColor",
	"ContentBackgroundTransparency",
	"MainframeShadowColor",
	"SidebarColor",
	"SidebarTransparency",
	"ComponentBackgroundColor",
	"ComponentBackgroundTransparency",
	"InputBackgroundColor",
	"InputBackgroundTransparency",
	"ComponentShadowColor",
	"StrokeColor",
	"StrokeTransparency",
	"PrimaryColor",
	"SecondaryColor",
	"TertiaryColor",
	"Undercolor",
	"AccentColor",
	"PrimaryTextColor",
	"PrimaryTextTransparency",
	"SecondaryTextColor",
	"SecondaryTextTransparency",
	"TitleTextColor",
	"InactiveTabTextColor",
	"InactiveTabIconColor",
	"ActiveTabTextColor",
	"ActiveTabIconColor",
	"ActiveTabTextTransparency",
	"InactiveTabTextTransparency",
	"ActiveTabIconTransparency",
	"InactiveTabIconTransparency",
	"ActiveTabButtonColor",
	"ActiveTabButtonTransparency",
	"InactiveTabButtonColor",
	"InactiveTabButtonTransparency",
	"SectionBackgroundColor",
	"SectionBackgroundTransparency",
	"SectionStrokeColor",
	"SectionStrokeTransparency",
	"SectionDividerColor",
	"SectionDividerTransparency",
	"SearchBarBackgroundColor",
	"SearchBarBackgroundTransparency",
	"PopupBackgroundColor",
	"PopupBackgroundTransparency",
	"PopupNeutralColor",
	"PopupShadowColor",
	"PopupTextColor",
	"PopupTextTransparency",
	"NotificationBackgroundColor",
	"NotificationBackgroundTransparency",
	"NotificationShadowColor",
	"NotificationStrokeColor",
	"NotificationStrokeTransparency",
	"NotificationHeaderColor",
	"NotificationHeaderTransparency",
	"NotificationTextColor",
	"NotificationTextTransparency",
	"NotificationDividerColor",
	"NotificationDividerTransparency",
	"NotificationDismissColor",
	"NotificationActionButtonColor",
	"NotificationActionButtonTextColor",
	"NotificationAlertAccent",
	"NotificationErrorAccent",
	"NotificationVariableAccent",
	"NotificationAlertAurora",
	"NotificationErrorAurora",
}

local THEME_KEY_SET = {}
for _, k in ipairs(ThemeManager.THEME_KEYS) do
	THEME_KEY_SET[k] = true
end

-- Turn on in Studio to catch omissions at build time instead of at switch time.
ThemeManager.strict = false

-- Entries are dropped on Destroying and compacted on the next apply, so the arrays never accumulate dead UI.
local bindings = {}
local bindingIndex = setmetatable({}, { __mode = "k" })

local function compactBindings()
	local w = 1
	for i = 1, #bindings do
		local e = bindings[i]
		if not e.dropped and e.instance then
			bindings[w] = e
			w = w + 1
		end
	end
	for i = w, #bindings do
		bindings[i] = nil
	end
end

-- TweenInfo is immutable; reuse one per duration instead of allocating a fresh
-- object for every animated binding on each theme switch.
local tweenInfoCache = {}
local function TweenInfoCache(duration)
	local info = tweenInfoCache[duration]
	if not info then
		info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		tweenInfoCache[duration] = info
	end
	return info
end

local function applyEntry(entry, theme, animate)
	local inst = entry.instance
	if not inst or entry.dropped or entry.disabled then
		return
	end
	if inst:GetAttribute(entry.overrideAttr) ~= nil then
		return
	end
	-- A literal is a state-map entry of the form { value = <any> }; it stays constant across theme switches.
	local value
	if entry.literal ~= nil then
		value = entry.literal
	else
		value = theme[entry.themeKey]
	end
	if value == nil then
		return
	end
	if entry.opts.transform then
		value = entry.opts.transform(value)
	end
	-- PageFade's decoration pass reads this authoritative resting value instead of guessing from a mid-tween property.
	if entry.opts.live or entry.kind == "color" or entry.kind == "number" then
		inst:SetAttribute(entry.liveAttr, value)
	end
	local current = inst[entry.property]
	if current == value then
		return
	end
	if animate and not entry.opts.instant and (entry.kind == "color" or entry.kind == "number") then
		local info = entry.tweenInfo or TweenInfoCache(entry.opts.duration or ThemeManager.ColorFadeTime)
		Tween.Play(inst, info, { [entry.property] = value })
	else
		inst[entry.property] = value
	end
end

local function makeHandle(entry)
	local handle = {}
	function handle:SetKey(key)
		if ThemeManager.strict and not THEME_KEY_SET[key] then
			error("[ThemeManager] SetKey: unknown theme key '" .. tostring(key) .. "'", 2)
		end
		entry.themeKey = key
		entry.stateName = nil -- a raw SetKey clears any named state
		local theme = ActiveTheme.theme
		if theme then
			applyEntry(entry, theme, true)
		end
	end
	-- No-op for single-key bindings (no state map), so callers can invoke it blindly.
	function handle:SetState(name)
		local map = entry.stateMap
		if not map then
			return
		end
		local spec = map[name]
		if spec == nil then
			error("[ThemeManager] SetState: no state '" .. tostring(name) .. "' on this binding", 2)
		end
		if type(spec) == "table" then
			entry.literal = spec.value
			entry.themeKey = nil
		else
			if ThemeManager.strict and not THEME_KEY_SET[spec] then
				error("[ThemeManager] SetState: unknown theme key '" .. tostring(spec) .. "'", 2)
			end
			entry.literal = nil
			entry.themeKey = spec
		end
		entry.stateName = name
		local theme = ActiveTheme.theme
		if theme then
			applyEntry(entry, theme, true)
		end
	end
	function handle:SetEnabled(on)
		entry.disabled = not on
		if on then
			local theme = ActiveTheme.theme
			if theme then
				applyEntry(entry, theme, false)
			end
		end
	end
	function handle:Destroy()
		entry.dropped = true
		entry.instance = nil
	end
	return handle
end

local function bind(instance, property, themeKey, kind, opts)
	opts = opts or {}

	-- A nil instance (an optional element that never got built) gets a no-op handle so it can't take the window down.
	if instance == nil then
		return {
			SetState = function() end,
			SetEnabled = function() end,
			Destroy = function() end,
		}
	end

	local stateMap = nil
	local initialStateName = nil
	local initialKey = themeKey
	if type(themeKey) == "table" then
		stateMap = themeKey
		initialStateName = opts.state or next(stateMap)
		if initialStateName == nil then
			error("[ThemeManager] Bind: empty state map for property '" .. tostring(property) .. "'", 3)
		end
		initialKey = stateMap[initialStateName]
		if initialKey == nil then
			error("[ThemeManager] Bind: state '" .. tostring(initialStateName) .. "' not in state map", 3)
		end
		if ThemeManager.strict then
			for stateName, k in pairs(stateMap) do
				if not THEME_KEY_SET[k] then
					error(
						"[ThemeManager] Bind: unknown theme key '"
							.. tostring(k)
							.. "' for state '"
							.. tostring(stateName)
							.. "'",
						3
					)
				end
			end
		end
	elseif ThemeManager.strict and not THEME_KEY_SET[initialKey] then
		error("[ThemeManager] Bind: unknown theme key '" .. tostring(initialKey) .. "'", 3)
	end

	local byProp = bindingIndex[instance]
	if not byProp then
		byProp = {}
		bindingIndex[instance] = byProp
		instance.Destroying:Connect(function()
			local props = bindingIndex[instance]
			if props then
				for _, e in pairs(props) do
					e.dropped = true
					e.instance = nil
				end
				bindingIndex[instance] = nil
			end
		end)
	end
	local old = byProp[property]
	if old then
		old.dropped = true
		old.instance = nil
	end
	local entry = {
		instance = instance,
		property = property,
		themeKey = initialKey,
		stateMap = stateMap,
		stateName = initialStateName,
		kind = kind,
		opts = opts,
		-- Precomputed attribute names + a shared TweenInfo: applyEntry runs once
		-- per binding on every theme switch, so avoid per-call string concat and
		-- TweenInfo allocation (the main source of theme-switch hitching).
		overrideAttr = UUID.Static("ThemeOverride_" .. property),
		liveAttr = UUID.Static("ThemeLive_" .. property),
		tweenInfo = (kind == "color" or kind == "number") and TweenInfoCache(
			opts.duration or ThemeManager.ColorFadeTime
		) or nil,
	}
	byProp[property] = entry
	bindings[#bindings + 1] = entry
	-- Apply immediately so the property is themed on the first frame, not only after the next switch.
	local theme = ActiveTheme.theme
	if theme then
		applyEntry(entry, theme, false)
	end
	return makeHandle(entry)
end

function ThemeManager.BindColor(instance, property, themeKey, opts)
	return bind(instance, property, themeKey, "color", opts)
end

function ThemeManager.BindTransparency(instance, property, themeKey, opts)
	return bind(instance, property, themeKey, "number", opts)
end

-- Non-tweenable kinds (string, boolean, asset id) snap instantly instead of crossfading.
function ThemeManager.Bind(instance, property, themeKey, opts)
	local t = typeof(instance[property])
	local kind = "value"
	if t == "Color3" then
		kind = "color"
	elseif t == "number" then
		kind = "number"
	end
	return bind(instance, property, themeKey, kind, opts)
end

function ThemeManager.Unbind(instance, property)
	local byProp = bindingIndex[instance]
	if byProp and byProp[property] then
		byProp[property].dropped = true
		byProp[property].instance = nil
		byProp[property] = nil
	end
end

function ThemeManager.UnbindInstance(instance)
	local props = bindingIndex[instance]
	if props then
		for _, e in pairs(props) do
			e.dropped = true
			e.instance = nil
		end
		bindingIndex[instance] = nil
	end
end

-- Handlers use this instead of reading a mid-tween instance[prop].
function ThemeManager.Get(themeKey)
	local theme = ActiveTheme.theme or ThemeManager.GetTheme(ThemeManager.DefaultTheme)
	return theme[themeKey]
end

-- For state the theme does not own (e.g. a hover transparency), which ApplyTheme's CancelAll can freeze mid-tween.
local themeAppliedCallbacks = {}

function ThemeManager.OnThemeApplied(fn, ownerInstance)
	local entry = { fn = fn, owner = ownerInstance }
	themeAppliedCallbacks[#themeAppliedCallbacks + 1] = entry
	if ownerInstance and typeof(ownerInstance) == "Instance" then
		ownerInstance.Destroying:Connect(function()
			for i, e in ipairs(themeAppliedCallbacks) do
				if e == entry then
					table.remove(themeAppliedCallbacks, i)
					break
				end
			end
		end)
	end
	return function()
		for i, e in ipairs(themeAppliedCallbacks) do
			if e == entry or e.fn == fn then
				table.remove(themeAppliedCallbacks, i)
				return
			end
		end
	end
end

local COLOR_PROPS = { "BackgroundColor3", "TextColor3", "ImageColor3" }
-- Precomputed override attribute names for the re-stamp loop, so it doesn't
-- concat + hash a key per descendant per property on every theme switch.
local COLOR_PROP_ATTRS = {}
for _, p in ipairs(COLOR_PROPS) do
	COLOR_PROP_ATTRS[p] = UUID.Static("ThemeOverride_" .. p)
end
local STROKE_OVERRIDE_ATTR = UUID.Static("ThemeOverride_Color")

-- Only named (string/nil) results are memoized; custom tables are caller-owned and merged fresh each time.
local themeMemo = {}

function ThemeManager.GetTheme(themeInput)
	if themeInput == "Default" then
		themeInput = ThemeManager.DefaultTheme
	end
	local key
	if type(themeInput) == "string" then
		key = themeInput
	elseif themeInput == nil then
		key = ThemeManager.DefaultTheme
	end

	if key then
		local cached = themeMemo[key]
		if cached then
			return cached
		end
	end

	local themeTable
	if type(themeInput) == "string" then
		themeTable = ThemeDefinitions[themeInput]
		if not themeTable then
			warn("[ThemeManager] Theme '" .. tostring(themeInput) .. "' not found, using Base")
			themeTable = ThemeDefinitions.Base
		end
	elseif type(themeInput) == "table" then
		themeTable = themeInput
	else
		themeTable = ThemeDefinitions.Base
	end

	local theme = {}
	for k, v in pairs(ThemeDefinitions.Base) do
		theme[k] = themeTable[k] ~= nil and themeTable[k] or v
	end

	-- Only named/nil results are interned; a bad name falls back to Base, so it never overwrites a real theme's memo entry.
	if key then
		themeMemo[key] = theme
	end
	return theme
end

-- Pushes onto each tab entry too, so tab-switch handlers read the live theme.
function ThemeManager.SyncTheme(target, theme)
	if not target then
		return
	end
	target._theme = theme
	if target.Tabs then
		for _, tab in ipairs(target.Tabs) do
			tab._theme = theme
		end
	end
end

-- Elements under a hidden ancestor (an inactive tab's FadeLayer, a minimized
-- window) can't be seen, so their values snap on a theme switch instead of
-- spawning tweens nobody watches. Visible elements still crossfade.
local function isHidden(inst)
	local node = inst
	while node and node ~= game do
		if node:IsA("CanvasGroup") then
			if (node.GroupTransparency or 0) >= 1 then
				return true
			end
		elseif node:IsA("GuiObject") and not node.Visible then
			return true
		end
		node = node.Parent
	end
	return false
end

function ThemeManager.ApplyTheme(window, themeInput)
	local theme = ThemeManager.GetTheme(themeInput)

	-- Publish the live theme so components read current colors at interaction time, not a stale construction-time table.
	ActiveTheme.theme = theme
	ActiveTheme.name = (type(themeInput) == "string") and themeInput or nil

	-- Cancel in-flight tweens first, or one started by the old theme can finish after this pass and overwrite the new values.
	Tween.CancelAllUnder(window.Base)

	-- Window shell colors are declarative bindings created in Window.new; the bindings pass below re-resolves them.
	window._theme = theme

	ThemeManager.SyncTheme(window.TabGroup, theme)
	ThemeManager.SyncTheme(window.SettingsTabGroup, theme)

	-- The window can't self-register (the registry walks Base's descendants, excluding Base itself), so call its ApplyTheme explicitly first.
	if window.ApplyTheme then
		pcall(function()
			window:ApplyTheme(theme)
		end)
	end

	for root, comp in pairs(ThemeManager._components) do
		if root and root.Parent and root:IsDescendantOf(window.Base) then
			if comp.ApplyTheme then
				pcall(function()
					comp:ApplyTheme(theme)
				end)
			end
		end
	end

	-- Re-stamp overrides after every pass so component theme colors can't clobber a pinned custom color.
	if overrideCount > 0 then
		local descendants = window.Base:GetDescendants()
		for _, d in ipairs(descendants) do
			for _, p in ipairs(COLOR_PROPS) do
				local v = d:GetAttribute(COLOR_PROP_ATTRS[p])
				if typeof(v) == "Color3" then
					pcall(function()
						d[p] = v
					end)
				end
			end
			if d:IsA("UIStroke") then
				local sv = d:GetAttribute(STROKE_OVERRIDE_ATTR)
				if typeof(sv) == "Color3" then
					pcall(function()
						d.Color = sv
					end)
				end
			end
		end
	end

	-- Additive with the component walk above; bindings skip overridden props, so re-stamped overrides survive.
	compactBindings()
	-- bindings is module-global, so scope the pass to this window's tree or a second window's ApplyTheme would re-theme the first.
	local scopeRoot = window.Base
	for _, entry in ipairs(bindings) do
		local inst = entry.instance
		if inst and (entry.scopeRoot == scopeRoot or inst == scopeRoot or inst:IsDescendantOf(scopeRoot)) then
			entry.scopeRoot = scopeRoot
			applyEntry(entry, theme, not isHidden(inst))
		end
	end

	-- CancelAll stopped these spins; restart them so the selected tab keeps its gradient instead of staying stopped until a tab switch.
	if window.TabGroup and window.TabGroup.ActiveTab and window.TabGroup.ActiveTab.BackImageGradient then
		window.TabGroup:_resumeSpin(window.TabGroup.ActiveTab.BackImageGradient, true)
	end
	if
		window.SettingsTabGroup
		and window.SettingsTabGroup.ActiveTab
		and window.SettingsTabGroup.ActiveTab.BackImageGradient
	then
		window.SettingsTabGroup:_resumeSpin(window.SettingsTabGroup.ActiveTab.BackImageGradient, true)
	end

	-- CancelAll kills these spins and nothing else restarts them, so a switch would silently freeze every one.
	Tween.RestartSpins()

	-- CancelAll leaves the initial SelectionStatus stuck at 1, so set the final state directly without disturbing future animations.
	if window.SettingsTabGroup and window.SettingsTabGroup.Tabs then
		local active = window.SettingsTabGroup.ActiveTab
		for _, tab in ipairs(window.SettingsTabGroup.Tabs) do
			local isActive = tab == active
			if isActive then
				tab.SelectionStatus.BackgroundTransparency = 0
				tab.SelectionStatus.Size = UDim2.new(0, 2, 0.7, 0)
				tab.BackImage.ImageTransparency = 0
			else
				tab.SelectionStatus.BackgroundTransparency = 1
				tab.SelectionStatus.Size = UDim2.fromOffset(2, 0)
				tab.BackImage.ImageTransparency = 1
			end
		end
	end

	-- Decorations read their resting transparency from ThemeLive_, which the bindings pass republished; restore the pages CancelAll killed.
	if PageFade.InvalidateDecorationBases then
		PageFade.InvalidateDecorationBases()
	end
	if window.TabGroup and window.TabGroup.RestoreActiveTab then
		window.TabGroup:RestoreActiveTab()
	end
	if window.SettingsTabGroup and window.SettingsTabGroup.RestoreActivePage then
		window.SettingsTabGroup:RestoreActivePage()
	end

	-- Let components re-stamp non-theme state (e.g. a mid-hover transparency) that CancelAll froze.
	for i = #themeAppliedCallbacks, 1, -1 do
		local entry = themeAppliedCallbacks[i]
		if entry.owner and (not entry.owner.Parent or not entry.owner:IsDescendantOf(game)) then
			table.remove(themeAppliedCallbacks, i)
		else
			pcall(entry.fn, theme)
		end
	end
end

function ThemeManager.UpdateTheme(window, newTheme)
	ThemeManager.ApplyTheme(window, newTheme)
end

return ThemeManager
