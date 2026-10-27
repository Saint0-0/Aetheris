--[[
	ThemeManager  ·  Aetheris UI Library

	Resolves and applies themes, crossfading colors and restarting spins.
	Live colors are mirrored as attributes so handlers never read stale data.
]]

local ThemeDefinitions = require("./ThemeDefinitions")
local Tween = require("../Utils/Tween")
local ActiveTheme = require("./ActiveTheme")
local PageFade = require("../Utils/PageFade")
local UUID = require("../Utils/UUID")

local ThemeManager = {}

-- Crossfade duration (seconds) used by every animated binding and the color
-- crossfade pass. A binding can override it per-entry via opts.duration.
-- MUST be a number before any ApplyTheme runs: TweenInfo.new's first arg is
-- the tween time, so a nil here throws at the first animated binding.
ThemeManager.ColorFadeTime = 0.7

-- Launch default. The theme applied when a caller does not pass one (or when
-- GetTheme is given nil). Change this ONE string to make any theme the
-- default -- dark, light, whatever. It is independent of the structural merge
-- base (`Base`), which only fills in keys a theme omits.
ThemeManager.DefaultTheme = "Umbral"

-- Component registry. Components call ThemeManager.Register(rootInstance, self)
-- at construction; ApplyTheme then invokes each component's own ApplyTheme(theme)
-- instead of relying solely on fragile name/attribute matching. Keyed by the
-- component's ROOT instance with weak keys, so destroyed components drop out
-- automatically.
ThemeManager._components = setmetatable({}, { __mode = "k" })

function ThemeManager.Register(root, component)
	if root and component then
		ThemeManager._components[root] = component
	end
end

-- Caller-pinned colors: stamping ThemeOverride_<Property> makes the theme
-- system skip that property, so custom colors survive theme switches. The two
-- functions below are the only writers, which keeps overrideCount accurate.
--   ThemeManager.SetColorOverride(frame, "BackgroundColor3", Color3.new(1,0,0))
--   ThemeManager.ClearColorOverride(frame, "BackgroundColor3")
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

-- ─────────────────────────────────────────────────────────────────────────
-- DECLARATIVE BINDINGS (the foolproof path)
-- ─────────────────────────────────────────────────────────────────────────
-- Declare the driving theme key once; every switch re-resolves it. Overrides
-- win over bindings, which win over the prior value.

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
}

local THEME_KEY_SET = {}
for _, k in ipairs(ThemeManager.THEME_KEYS) do
	THEME_KEY_SET[k] = true
end

-- When true, Bind*/SetKey error on an unknown theme key, and ApplyTheme can be
-- made to assert that every themed property on a registered instance is bound.
-- Turn on in Studio to catch omissions at build time instead of on a switch.
ThemeManager.strict = false

-- Flat binding registry. `bindingIndex[inst][prop]` is the live entry (also in
-- `bindings`, the ordered array the apply pass walks). Entries are dropped on
-- Instance.Destroying and compacted on the next apply, so the arrays never
-- accumulate dead UI.
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

-- Resolve + write one binding. `animate` crossfades; overrides always win.
local function applyEntry(entry, theme, animate)
	local inst = entry.instance
	if not inst or entry.dropped or entry.disabled then
		return
	end
	-- Caller owns this property via an override: never touch it.
	if inst:GetAttribute(UUID.Static("ThemeOverride_" .. entry.property)) ~= nil then
		return
	end
	-- A binding is either a theme key lookup or a LITERAL value (a state map
	-- entry of the form { value = <any> }). Literals are constant and do not
	-- change on a theme switch, but still resolve through the binding system.
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
	-- Publish the RESOLVED value as data. Consumers that fade this instance
	-- (PageFade's decoration pass) read the theme's AUTHORITATIVE resting value
	-- from here instead of guessing one from a mid-tween property -- so a page
	-- fade DEPENDS on the theme system rather than snapshotting its own base.
	-- colour/number are always published (they are the fadable kinds); `live`
	-- additionally publishes other kinds.
	if entry.opts.live or entry.kind == "color" or entry.kind == "number" then
		inst:SetAttribute(UUID.Static("ThemeLive_" .. entry.property), value)
	end
	local current = inst[entry.property]
	if current == value then
		return
	end
	if animate and not entry.opts.instant and (entry.kind == "color" or entry.kind == "number") then
		-- Capture-then-restore so the crossfade starts from the CURRENT look,
		-- then let the central Tween registry own the tween (replace-per-
		-- property-set, so a rapid re-switch cancels cleanly).
		inst[entry.property] = value
		inst[entry.property] = current
		local info = TweenInfo.new(
			entry.opts.duration or ThemeManager.ColorFadeTime,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)
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
	-- Multi-state binding: flip to the theme key mapped to `name`. No-op for
	-- single-key bindings (no state map), so callers can invoke it blindly.
	function handle:SetState(name)
		local map = entry.stateMap
		if not map then
			return
		end
		local spec = map[name]
		if spec == nil then
			error("[ThemeManager] SetState: no state '" .. tostring(name) .. "' on this binding", 2)
		end
		-- A state spec is either a theme key (string) or a LITERAL
		-- ({ value = <any> }). Literals are constant; they clear the theme
		-- key so applyEntry uses entry.literal directly.
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

	-- Defensive: a caller passed a nil instance (typically an optional element
	-- that never got built). Binding into bindingIndex[nil] throws "table index
	-- is nil"; instead hand back a no-op handle so a missing optional element
	-- can never take the whole window down. This is expected for optional
	-- chrome, so it is intentionally silent.
	if instance == nil then
		return {
			SetState = function() end,
			SetEnabled = function() end,
			Destroy = function() end,
		}
	end

	-- themeKey is either a single key (string) or a state map
	-- ({ StateName = "ThemeKey", ... }). For a state map, resolve the initial
	-- state up front so entry.themeKey always starts on a real string key.
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
	}
	byProp[property] = entry
	bindings[#bindings + 1] = entry
	-- Apply immediately so the property is themed on the very first frame,
	-- not only after the next switch.
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

-- Infers kind from the property's current value type. Color3 -> colour,
-- number -> transparency/number (both crossfade); anything else (string,
-- boolean, asset id) is a 'value' binding that snaps instantly, since those
-- cannot be tweened.
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

-- Interaction-time read: current value of a theme key, without touching an
-- instance. Handlers use this instead of reading a mid-tween instance[prop].
function ThemeManager.Get(themeKey)
	local theme = ActiveTheme.theme or ThemeManager.GetTheme(ThemeManager.DefaultTheme)
	return theme[themeKey]
end

-- Callbacks run at the END of every ApplyTheme (after bindings + crossfade).
-- A component whose state is encoded in a property the theme does NOT own
-- (e.g. Button's hover/click fingerprint transparency) uses this to re-stamp
-- that state, because ApplyTheme's CancelAll can freeze it mid-tween.
-- Passing an optional ownerInstance automatically unregisters the callback
-- when the instance is destroyed.
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

-- Color crossfade: snapshot every element's current colors, let ApplyTheme set
-- the new theme instantly, then for any element whose color changed, restore
-- the old color and tween it to the new one. This makes a theme switch read as
-- the colors fading from the old theme into the new one (no dim/flash overlay).
local COLOR_PROPS = { "BackgroundColor3", "TextColor3", "ImageColor3" }

-- (snapshotColors removed: the old color-snapshot/crossfade system was the
-- second theming system. All themed colors are declarative BINDINGS now and
-- crossfade through the bindings pass in ApplyTheme.)

-- (applyColorFade removed alongside snapshotColors -- the old second
-- theming system. Theme color crossfades now run entirely through Bind*.)

-- Memo of merged tables for named themes (and nil -> Default). Section,
-- TabGroup, and every component call GetTheme at construct, and ApplyTheme
-- calls it again; without this each call re-allocated a full merged table.
-- Custom TABLES are still merged fresh each time (they are caller-owned and
-- may differ), so only the string/nil paths are cached.
local themeMemo = {}

function ThemeManager.GetTheme(themeInput)
	-- Legacy alias: "Default" resolves to the library default theme.
	if themeInput == "Default" then
		themeInput = ThemeManager.DefaultTheme
	end
	-- Cache key: a named theme, or the launch default for nil input.
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

	-- Determine theme table
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

	-- Merge with the structural base (fills any key a theme omits).
	local theme = {}
	for k, v in pairs(ThemeDefinitions.Base) do
		theme[k] = themeTable[k] ~= nil and themeTable[k] or v
	end

	-- Only intern named/nil results; a missing name warns and falls back to
	-- Base, so a bad name never poisons the memo with a real theme's table.
	if key then
		themeMemo[key] = theme
	end
	return theme
end

-- Theme-sync hook. Pushes the resolved theme onto a target and, if the
-- target exposes a .Tabs list, onto each tab entry so tab-switch handlers read
-- the live theme. (The old InvalidateCaches() call was removed: it had no
-- implementer anywhere in the library and was a permanent no-op behind pcall.)
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

function ThemeManager.ApplyTheme(window, themeInput)
	local theme = ThemeManager.GetTheme(themeInput)

	-- Publish the live theme so stateful components (e.g. Toggle) read the
	-- current colors at interaction time instead of a stale construction-time
	-- table.
	ActiveTheme.theme = theme
	ActiveTheme.name = (type(themeInput) == "string") and themeInput or nil

	-- Cancel every in-flight tween first. Otherwise a fade/switch tween
	-- started by the old theme can finish after this pass and overwrite the
	-- new theme's values with stale transparency/color targets.
	-- Cancel every in-flight tween first, via a sparse-registry sweep
	-- (O(active tweens)) rather than a per-descendant hash probe (O(descendants)).
	Tween.CancelAllUnder(window.Base)
	-- One traversal of the tree, reused by every pass below (component registry
	-- walk, override re-stamp).
	local descendants = window.Base:GetDescendants()

	-- NOTE: window shell colors/transparencies (MainFrame, ContentBackground,
	-- Sidebar, MainFrameShadow) are DECLARATIVE BINDINGS created in Window.new.
	-- NOT stamped here anymore -- that was a DOUBLE-STAMP of the same four
	-- properties window:ApplyTheme also set. The bindings pass below re-resolves
	-- them now.

	-- Store theme values for later use by components
	window._theme = theme

	-- Keep each tab group's live theme copy in sync so tab-switch handlers read
	-- the new theme. SyncTheme pushes _theme (and each tab's _theme) onto the
	-- target; it no longer calls any cache-invalidation hook.
	ThemeManager.SyncTheme(window.TabGroup, theme)
	ThemeManager.SyncTheme(window.SettingsTabGroup, theme)

	-- The WINDOW is the root of the tree (window.Base == the ScreenGui), so it
	-- cannot self-register: the registry iterates Base's DESCENDANTS, which
	-- excludes Base itself. Call the window's own ApplyTheme explicitly first.
	if window.ApplyTheme then
		pcall(function()
			window:ApplyTheme(theme)
		end)
	end

	-- Component-owned theming: iterate registered components directly instead
	-- of scanning the entire descendant tree of Base.
	for root, comp in pairs(ThemeManager._components) do
		if root and root.Parent and root:IsDescendantOf(window.Base) then
			if comp.ApplyTheme then
				pcall(function()
					comp:ApplyTheme(theme)
				end)
			end
		end
	end

	-- Re-stamp caller overrides after every ApplyTheme pass so a component's own
	-- theme colors cannot clobber a pinned custom color.
	if overrideCount > 0 then
		for _, d in ipairs(descendants) do
			for _, p in ipairs(COLOR_PROPS) do
				local v = d:GetAttribute(UUID.Static("ThemeOverride_" .. p))
				if typeof(v) == "Color3" then
					pcall(function()
						d[p] = v
					end)
				end
			end
			if d:IsA("UIStroke") then
				local sv = d:GetAttribute(UUID.Static("ThemeOverride_Color"))
				if typeof(sv) == "Color3" then
					pcall(function()
						d.Color = sv
					end)
				end
			end
		end
	end

	-- Declarative bindings pass. ADDITIVE: components migrated to Bind* are
	-- themed here; components still on the registry path are themed by the
	-- component walk above. Bindings skip overridden props, so an override
	-- re-stamped just above is preserved.
	compactBindings()
	-- Scope the binding pass to THIS window's tree, matching the component walk
	-- above. Without this, a second window's ApplyTheme would re-theme the first
	-- window's instances too (bindings is a module-global registry). Everything
	-- a window owns — chrome, tabs, popups, pill, tooltip — lives under
	-- window.Base (the ScreenGui), so this covers them all.
	local scopeRoot = window.Base
	for _, entry in ipairs(bindings) do
		local inst = entry.instance
		if inst and (inst == scopeRoot or inst:IsDescendantOf(scopeRoot)) then
			applyEntry(entry, theme, true)
		end
	end

	-- ApplyTheme cancelled all active tweens above. Restart the active tab
	-- spins for both tab groups so the selected tab keeps its spinning
	-- gradient (it would otherwise stay stopped until a tab switch).
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

	-- Restart every component spin gradient (slider fill, progress bar fill,
	-- radio sheen, dropdown items). The CancelAll pass above cancels them,
	-- and unlike the tab backdrops they are not restarted anywhere else, so
	-- without this the theme switch would silently freeze every spin.
	Tween.RestartSpins()

	-- Fix settings-tab final state after all tween cancellation. The tabs
	-- themselves animate normally on click, but ApplyTheme cancels those
	-- tweens at startup/theme-switch, leaving the initial SelectionStatus
	-- stuck at 1. Set the final visual state directly without disturbing
	-- future animations.
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

	-- Theme-bound decorations read their resting transparency from ThemeLive_,
	-- which the bindings pass above republished, so there is no stale base to
	-- clear -- just re-mark layers dirty and restore the active pages, since the
	-- CancelAll pass killed any in-flight page fade.
	if PageFade.InvalidateDecorationBases then
		PageFade.InvalidateDecorationBases()
	end
	if window.TabGroup and window.TabGroup.RestoreActiveTab then
		window.TabGroup:RestoreActiveTab()
	end
	if window.SettingsTabGroup and window.SettingsTabGroup.RestoreActivePage then
		window.SettingsTabGroup:RestoreActivePage()
	end

	-- (No color-fade pass: all themed colors are DECLARATIVE BINDINGS now, and
	-- the bindings pass above already crossfaded them. snapshotColors/
	-- applyColorFade were the second theming system and have been removed.)

	-- Let components re-stamp any non-theme state the CancelAll above may have
	-- frozen (e.g. a mid-hover interaction transparency).
	-- Automatically prune dead callbacks if their owner was destroyed.
	for i = #themeAppliedCallbacks, 1, -1 do
		local entry = themeAppliedCallbacks[i]
		if entry.owner and (not entry.owner.Parent or not entry.owner:IsDescendantOf(game)) then
			table.remove(themeAppliedCallbacks, i)
		else
			pcall(entry.fn, theme)
		end
	end
end

-- Update theme at runtime (e.g., window:SetTheme("Black"))
function ThemeManager.UpdateTheme(window, newTheme)
	ThemeManager.ApplyTheme(window, newTheme)
end

return ThemeManager
