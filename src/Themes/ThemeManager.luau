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

-- Must be a number before ApplyTheme runs; TweenInfo.new rejects a nil time.
ThemeManager.ColorFadeTime = 0.6

ThemeManager.DefaultTheme = "Umbral"

ThemeManager._components = setmetatable({}, { __mode = "k" })

function ThemeManager.Register(root, component)
	if root and component then
		ThemeManager._components[root] = component
	end
end

-- A ThemeOverride attribute makes the theme system skip that property.
local overrideCount = 0
-- Pinned colours are tracked so a switch re-stamps only them, not the whole tree.
local overrideProps = setmetatable({}, { __mode = "k" })

function ThemeManager.SetColorOverride(instance, property, color)
	if not instance or not property then
		return
	end
	local attr = UUID.Static("ThemeOverride_" .. property)
	local had = instance:GetAttribute(attr) ~= nil
	if color then
		instance:SetAttribute(attr, color)
		instance[property] = color
		local props = overrideProps[instance]
		if not props then
			props = {}
			overrideProps[instance] = props
		end
		props[property] = true
		if not had then
			overrideCount += 1
		end
	else
		instance:SetAttribute(attr, nil)
		local props = overrideProps[instance]
		if props then
			props[property] = nil
			if next(props) == nil then
				overrideProps[instance] = nil
			end
		end
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
			local props = overrideProps[instance]
			if props then
				props[property] = nil
				if next(props) == nil then
					overrideProps[instance] = nil
				end
			end
			overrideCount -= 1
		end
	end
end

-- Overrides win over bindings, which win over the prior value.

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

-- Entries drop on Destroying and compact on the next apply, so arrays stay small.
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

-- TweenInfo is immutable, so one instance is reused per duration.
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
	-- A literal state entry stays constant across theme switches.
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
	-- PageFade reads this resting value instead of a mid-tween property.
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
	-- No-op without a state map, so callers can invoke it unconditionally.
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

	-- A nil instance gets a no-op handle so an optional element cannot break the build.
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
		-- Precomputed attributes and TweenInfo avoid per-switch string work.
		overrideAttr = UUID.Static("ThemeOverride_" .. property),
		liveAttr = UUID.Static("ThemeLive_" .. property),
		tweenInfo = (kind == "color" or kind == "number") and TweenInfoCache(
			opts.duration or ThemeManager.ColorFadeTime
		) or nil,
	}
	byProp[property] = entry
	bindings[#bindings + 1] = entry
	-- Applied immediately, so the property is themed on the first frame.
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

-- Non-tweenable kinds snap instead of crossfading.
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

-- The live theme, falling back to the default before the first apply.
function ThemeManager.GetCurrent()
	return ActiveTheme.theme or ThemeManager.GetTheme(ThemeManager.DefaultTheme)
end

function ThemeManager.Get(themeKey)
	return ThemeManager.GetCurrent()[themeKey]
end

-- For non-theme state that CancelAll can freeze mid-tween.
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
-- Precomputed attribute names keep the re-stamp loop allocation-free.
local COLOR_PROP_ATTRS = {}
for _, p in ipairs(COLOR_PROPS) do
	COLOR_PROP_ATTRS[p] = UUID.Static("ThemeOverride_" .. p)
end
local STROKE_OVERRIDE_ATTR = UUID.Static("ThemeOverride_Color")

local function overrideAttrFor(property)
	if property == "Color" then
		return STROKE_OVERRIDE_ATTR
	end
	return COLOR_PROP_ATTRS[property] or UUID.Static("ThemeOverride_" .. property)
end

-- Only named results are memoized; custom tables are merged fresh each time.
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

-- Values under a hidden ancestor snap instead of spawning unwatched tweens.
local function isHidden(inst)
	local node = inst
	while node and node ~= game do
		-- TreeFade roots mark themselves when faded out.
		if node:GetAttribute(UUID.Static("FadeHidden")) == true then
			return true
		end
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

	-- Published so components read current colors at interaction time.
	ActiveTheme.theme = theme
	ActiveTheme.name = (type(themeInput) == "string") and themeInput or nil

	-- Cancel first; an old-theme tween could otherwise finish after this pass.
	Tween.CancelAllUnder(window.Base)

	-- Window shell colours are bindings created in Window.new and re-resolved below.
	window._theme = theme

	ThemeManager.SyncTheme(window.TabGroup, theme)
	ThemeManager.SyncTheme(window.SettingsTabGroup, theme)

	-- The window cannot self-register, so its ApplyTheme is called explicitly first.
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

	-- Re-stamp pinned colours last so component colours cannot clobber them.
	if overrideCount > 0 then
		for inst, props in pairs(overrideProps) do
			if inst.Parent then
				for p in pairs(props) do
					local v = inst:GetAttribute(overrideAttrFor(p))
					if typeof(v) == "Color3" then
						pcall(function()
							inst[p] = v
						end)
					end
				end
			end
		end
	end

	-- Additive with the component walk above; bindings skip overridden props.
	compactBindings()
	-- The binding index is module-global, so each pass is scoped to this window.
	local scopeRoot = window.Base
	-- One visibility climb per instance per switch, and only for bindings that tween.
	local hiddenCache = {}
	local function shouldAnimate(inst, entry)
		if entry.opts.instant or (entry.kind ~= "color" and entry.kind ~= "number") then
			return false
		end
		local cached = hiddenCache[inst]
		if cached == nil then
			cached = isHidden(inst)
			hiddenCache[inst] = cached
		end
		return not cached
	end
	for _, entry in ipairs(bindings) do
		local inst = entry.instance
		if inst and (entry.scopeRoot == scopeRoot or inst == scopeRoot or inst:IsDescendantOf(scopeRoot)) then
			entry.scopeRoot = scopeRoot
			-- Each binding is isolated; a throw must not strand later bindings on the old theme.
			local ok, err = pcall(function()
				applyEntry(entry, theme, shouldAnimate(inst, entry))
			end)
			if not ok then
				warn("[ThemeManager] theme bind failed for " .. tostring(inst) .. ": " .. tostring(err))
			end
		end
	end

	-- CancelAll stopped these spins; restart so the selected tab keeps its gradient.
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

	-- CancelAll kills the remaining spins, so they restart here.
	Tween.RestartSpins()

	-- CancelAll leaves tab backdrops mid-tween, so the final state is set directly.
	if window.SettingsTabGroup and window.SettingsTabGroup.Tabs then
		local active = window.SettingsTabGroup.ActiveTab
		for _, tab in ipairs(window.SettingsTabGroup.Tabs) do
			tab.BackImage.ImageTransparency = (tab == active) and 0 or 1
		end
	end

	-- Decorations re-read ThemeLive_; restore the pages CancelAll killed.
	if PageFade.InvalidateDecorationBases then
		PageFade.InvalidateDecorationBases()
	end
	if window.TabGroup and window.TabGroup.RestoreActiveTab then
		window.TabGroup:RestoreActiveTab()
	end
	if window.SettingsTabGroup and window.SettingsTabGroup.RestoreActivePage then
		window.SettingsTabGroup:RestoreActivePage()
	end

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
