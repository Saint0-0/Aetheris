--[[
	ThemeManager  ·  Aetheris UI Library

	Applies and live-switches themes across an entire window.

	  GetTheme(input)          -> resolves a name/partial table into a full
	                              theme merged over Default.
	  ApplyTheme(window, t)    -> stamps the theme onto every UI element via
	                              attribute/name matching, crossfading colors.
	  UpdateTheme(window, t)   -> public entry used by Window:SetTheme.

	A theme switch snapshots current colors, applies the new values instantly,
	then tweens old -> new so it reads as a smooth crossfade. Spins are
	restarted afterwards (Tween.RestartSpins) since the blanket CancelAll kills
	them. Live colors are ALSO written as attributes on elements so component
	interaction handlers read the current theme instead of a stale captured
	table. ColorFadeTime controls the crossfade duration.
]]

local ThemeDefinitions = require("./ThemeDefinitions")
local Tween = require("../Utils/Tween")
local ActiveTheme = require("./ActiveTheme")
local PageFade = require("../Utils/PageFade")

local ThemeManager = {}

-- Crossfade duration (seconds) used by every animated binding and the color
-- crossfade pass. A binding can override it per-entry via opts.duration.
-- MUST be a number before any ApplyTheme runs: TweenInfo.new's first arg is
-- the tween time, so a nil here throws at the first animated binding.
ThemeManager.ColorFadeTime = 0.7

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

-- Color OVERRIDES. A component that gives one of its instances a custom
-- color can declare it as an override by stamping a Color3 attribute named
-- 'ThemeOverride_<Property>' on that instance. The theme system then treats
-- that property as owned by the caller: the color crossfade skips it, so a
-- custom color survives theme switches instead of every component having to
-- re-stamp it on each ApplyTheme pass.
--
--   ThemeManager.SetColorOverride(frame, "BackgroundColor3", Color3.new(1,0,0))
--   ThemeManager.ClearColorOverride(frame, "BackgroundColor3")
-- Count of live override attributes, so ApplyTheme can skip the
-- O(descendants x COLOR_PROPS) re-stamp sweep entirely when there are none
-- (the common case). The two functions below are the ONLY writers of the
-- ThemeOverride_* attributes, so this stays accurate.
local overrideCount = 0

function ThemeManager.SetColorOverride(instance, property, color)
    if not instance or not property then
        return
    end
    local attr = "ThemeOverride_" .. property
    local had = instance:GetAttribute(attr) ~= nil
    if color then
        instance:SetAttribute(attr, color)
        instance[property] = color
        if not had then overrideCount += 1 end
    else
        instance:SetAttribute(attr, nil)
        if had then overrideCount -= 1 end
    end
end

function ThemeManager.ClearColorOverride(instance, property)
    if instance and property then
        local attr = "ThemeOverride_" .. property
        if instance:GetAttribute(attr) ~= nil then
            instance:SetAttribute(attr, nil)
            overrideCount -= 1
        end
    end
end


-- ─────────────────────────────────────────────────────────────────────────
-- DECLARATIVE BINDINGS (the foolproof path)
-- ─────────────────────────────────────────────────────────────────────────
-- A component declares ONCE, at construction, which theme key drives each of
-- its themed properties:
--
--   ThemeManager.BindColor(frame, "BackgroundColor3", "ComponentBackgroundColor")
--   ThemeManager.BindTransparency(frame, "BackgroundTransparency", "ComponentBackgroundTransparency")
--
-- On every theme switch each binding is re-resolved (and crossfaded). Nothing
-- has to remember to re-apply: if a property is themed, it is a binding. A
-- component never defines an ApplyTheme that re-stamps colours by hand.
--
-- The handle exposes the ONE legal mutation a component may make:
--
--   handle:SetKey(themeKey)  -- swap which key drives this property, e.g.
--                            -- rest -> hover -> press. Keeps a stateful
--                            -- component declarative instead of reaching in
--                            -- and setting the colour itself.
--
-- opts (all optional):
--   transform = function(value) -> value  -- post-process the resolved value
--                                            (e.g. darken for a hover variant)
--   instant   = true                      -- snap instead of crossfading
--   duration  = number                    -- override the crossfade time
--   live      = true                      -- also stamp ThemeLive_<prop> so
--                                            interaction handlers can read it
--
-- Precedence is always:  ThemeOverride_<prop>  >  binding  >  prior value.
-- An override wins, so components that accept a caller colour via
-- SetColorOverride keep it across theme switches.

ThemeManager.THEME_KEYS = {
    "WindowColor", "WindowTransparency", "WindowControlColor",
    "ContentBackgroundColor", "ContentBackgroundTransparency", "MainframeShadowColor",
    "SidebarColor", "SidebarTransparency",
    "ComponentBackgroundColor", "ComponentBackgroundTransparency",
    "InputBackgroundColor", "InputBackgroundTransparency",
    "ComponentShadowColor", "StrokeColor", "StrokeTransparency",
    "PrimaryColor", "SecondaryColor", "TertiaryColor", "Undercolor", "AccentColor",
    "PrimaryTextColor", "PrimaryTextTransparency",
    "SecondaryTextColor", "SecondaryTextTransparency", "TitleTextColor",
    "InactiveTabTextColor", "InactiveTabIconColor", "ActiveTabTextColor", "ActiveTabIconColor",
    "ActiveTabTextTransparency", "InactiveTabTextTransparency",
    "ActiveTabIconTransparency", "InactiveTabIconTransparency",
    "ActiveTabButtonColor", "ActiveTabButtonTransparency",
    "InactiveTabButtonColor", "InactiveTabButtonTransparency",
    "SectionBackgroundColor", "SectionBackgroundTransparency",
    "SectionStrokeColor", "SectionStrokeTransparency",
    "SectionDividerColor", "SectionDividerTransparency",
    "SearchBarBackgroundColor", "SearchBarBackgroundTransparency",
    "PopupBackgroundColor", "PopupBackgroundTransparency", "PopupNeutralColor",
    "PopupShadowColor", "PopupTextColor", "PopupTextTransparency",
    "NotificationBackgroundColor", "NotificationBackgroundTransparency",
    "NotificationShadowColor", "NotificationHeaderColor", "NotificationHeaderTransparency",
    "NotificationTextColor", "NotificationTextTransparency",
    "NotificationDividerColor", "NotificationDividerTransparency", "NotificationDismissColor",
    "NotificationActionButtonColor", "NotificationActionButtonTextColor",
    "NotificationAlertAccent", "NotificationErrorAccent", "NotificationVariableAccent",
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
    if inst:GetAttribute("ThemeOverride_" .. entry.property) ~= nil then
        return
    end
    local value = theme[entry.themeKey]
    if value == nil then
        return
    end
    if entry.opts.transform then
        value = entry.opts.transform(value)
    end
    if entry.opts.live then
        inst:SetAttribute("ThemeLive_" .. entry.property, value)
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
    if ThemeManager.strict and not THEME_KEY_SET[themeKey] then
        error("[ThemeManager] Bind: unknown theme key '" .. tostring(themeKey) .. "'", 3)
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
        themeKey = themeKey,
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
    local theme = ActiveTheme.theme or ThemeManager.GetTheme("Default")
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

local function snapshotColors(descendants)
    local snap = {}
    for _, d in ipairs(descendants) do
        local boundProps = bindingIndex[d]
        local props = nil

        if d:IsA("GuiObject") then
            if not d:GetAttribute("ThemeOverride_BackgroundColor3") and not (boundProps and boundProps["BackgroundColor3"]) then
                props = props or {}
                table.insert(props, { "BackgroundColor3", d.BackgroundColor3 })
            end
            if d:IsA("TextLabel") or d:IsA("TextBox") or d:IsA("TextButton") then
                if not d:GetAttribute("ThemeOverride_TextColor3") and not (boundProps and boundProps["TextColor3"]) then
                    props = props or {}
                    table.insert(props, { "TextColor3", d.TextColor3 })
                end
            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                if not d:GetAttribute("ThemeOverride_ImageColor3") and not (boundProps and boundProps["ImageColor3"]) then
                    props = props or {}
                    table.insert(props, { "ImageColor3", d.ImageColor3 })
                end
            end
        elseif d:IsA("UIStroke") and not d:GetAttribute("ThemeOverride_Color") then
            if not (boundProps and boundProps["Color"]) then
                props = props or {}
                table.insert(props, { "Color", d.Color })
            end
        end

        if props then
            table.insert(snap, { instance = d, props = props })
        end
    end
    return snap
end

local function applyColorFade(snap)
    for _, entry in ipairs(snap) do
        local inst = entry.instance
        if inst.Parent then
            for _, pp in ipairs(entry.props) do
                local prop, old = pp[1], pp[2]
                local new = inst[prop]
                if typeof(new) == "Color3" and new ~= old then
                    inst[prop] = old
                    local info = TweenInfo.new(
                        ThemeManager.ColorFadeTime,
                        Enum.EasingStyle.Quad,
                        Enum.EasingDirection.Out
                    )
                    Tween.Play(inst, info, { [prop] = new })
                end
            end
        end
    end
end

-- Memo of merged tables for named themes (and nil -> Default). Section,
-- TabGroup, and every component call GetTheme at construct, and ApplyTheme
-- calls it again; without this each call re-allocated a full merged table.
-- Custom TABLES are still merged fresh each time (they are caller-owned and
-- may differ), so only the string/nil paths are cached.
local themeMemo = {}

function ThemeManager.GetTheme(themeInput)
    -- Cache key: a named theme, or "Default" for nil/unknown input.
    local key
    if type(themeInput) == "string" then
        key = themeInput
    elseif themeInput == nil then
        key = "Default"
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
            warn("[ThemeManager] Theme '" .. tostring(themeInput) .. "' not found, using Default")
            themeTable = ThemeDefinitions.Default
        end
    elseif type(themeInput) == "table" then
        themeTable = themeInput
    else
        themeTable = ThemeDefinitions.Default
    end

    -- Merge with defaults
    local theme = {}
    for k, v in pairs(ThemeDefinitions.Default) do
        theme[k] = themeTable[k] ~= nil and themeTable[k] or v
    end

    -- Only intern named/nil results; a missing name warns and falls back to
    -- Default, so cache it under "Default" rather than the bad name.
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
    if not target then return end
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
    -- walk, override re-stamp, color snapshot).
    local descendants = window.Base:GetDescendants()

    -- Snapshot current colors so the switch can crossfade old -> new.
    local colorSnap = snapshotColors(descendants)

    -- Apply window background color and transparency
    if theme.WindowColor then
        window.MainFrame.BackgroundColor3 = theme.WindowColor
    end
    if theme.WindowTransparency ~= nil then
        window.MainFrame.BackgroundTransparency = theme.WindowTransparency
    end

    -- Apply the content fill (region right of the sidebar). Falls back to the
    -- window color/transparency so themes that don't define it are unchanged.
    if window.ContentBackground then
        window.ContentBackground.BackgroundColor3 = theme.ContentBackgroundColor or theme.WindowColor
        local ct = theme.ContentBackgroundTransparency
        if ct == nil then ct = theme.WindowTransparency end
        if ct ~= nil then
            window.ContentBackground.BackgroundTransparency = ct
        end
    end

    -- Apply sidebar color and transparency
    if theme.SidebarColor then
        window.Sidebar.BackgroundColor3 = theme.SidebarColor
    end
    if theme.SidebarTransparency ~= nil then
        window.Sidebar.BackgroundTransparency = theme.SidebarTransparency
    end

    -- Apply mainframe shadow color
    if theme.MainframeShadowColor then
        local shadow = window.MainFrame:FindFirstChildWhichIsA("UIShadow")
        if shadow then
            shadow.Color = theme.MainframeShadowColor
        end
    end

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
        pcall(function() window:ApplyTheme(theme) end)
    end

    -- Component-owned theming: iterate registered components directly instead
    -- of scanning the entire descendant tree of Base.
    for root, comp in pairs(ThemeManager._components) do
        if root and root.Parent and root:IsDescendantOf(window.Base) then
            if comp.ApplyTheme then
                pcall(function() comp:ApplyTheme(theme) end)
            end
        end
    end

    -- Re-stamp declared overrides. A component's own ApplyTheme re-applies
    -- theme colors directly, which would otherwise clobber an override it
    -- declared on one of its instances. Overrides are the caller's explicit
    -- intent, so they always win: any instance carrying a ThemeOverride_<Prop>
    -- attribute gets that value re-applied here, AFTER every component
    -- ApplyTheme pass. snapshotColors/applyColorFade already skip these props,
    -- so the re-stamped value is never faded back to a theme value.
    if overrideCount > 0 then
        for _, d in ipairs(descendants) do
            for _, p in ipairs(COLOR_PROPS) do
                local v = d:GetAttribute("ThemeOverride_" .. p)
                if typeof(v) == "Color3" then
                    pcall(function() d[p] = v end)
                end
            end
            if d:IsA("UIStroke") then
                local sv = d:GetAttribute("ThemeOverride_Color")
                if typeof(sv) == "Color3" then
                    pcall(function() d.Color = sv end)
                end
            end
        end
    end

    -- Declarative bindings pass. ADDITIVE: components migrated to Bind* are
    -- themed here; components still on the registry path are themed by the
    -- component walk above. Bindings skip overridden props, so an override
    -- re-stamped just above is preserved.
    compactBindings()
    for _, entry in ipairs(bindings) do
        applyEntry(entry, theme, true)
    end

    -- ApplyTheme cancelled all active tweens above. Restart the active tab
    -- spins for both tab groups so the selected tab keeps its spinning
    -- gradient (it would otherwise stay stopped until a tab switch).
    if window.TabGroup and window.TabGroup.ActiveTab and window.TabGroup.ActiveTab.BackImageGradient then
        window.TabGroup:_resumeSpin(window.TabGroup.ActiveTab.BackImageGradient, true)
    end
    if window.SettingsTabGroup and window.SettingsTabGroup.ActiveTab and window.SettingsTabGroup.ActiveTab.BackImageGradient then
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
                tab.SelectionStatus.Size = UDim2.new(0, 2, 0, 0)
                tab.BackImage.ImageTransparency = 1
            end
        end
    end

    -- Invalidate the page-fade caches FIRST. They hold per-tab base
    -- transparencies captured at build time, but component ApplyTheme above just
    -- changed those bases (Section background, UIStroke, etc.). Clearing +
    -- re-priming here captures the NEW bases from the freshly-themed content.
    -- This MUST run BEFORE RestoreActiveTab below: otherwise the restore pulls
    -- the OLD cached bases and stomps the new theme values, and the re-prime
    -- then captures those stale values (the "section backgrounds / strokes don't
    -- return" bug).
    -- The CancelAll pass also killed any in-flight page fade, which could leave
    -- the active page stuck transparent. Restore both active pages to natural,
    -- using the freshly-primed caches from just above.
    --
    -- Drop PageFade's per-decoration cached fade-bases BEFORE restoring. Each
    -- decoration's resting transparency may have CHANGED with the theme (e.g. a
    -- radio's selection-driven UIStroke), so a base captured before the switch
    -- would restore a stale value forever -- the "stroke stays invisible until
    -- hover" bug. The next fade re-captures from the freshly-themed values.
    if PageFade.InvalidateDecorationBases then
        PageFade.InvalidateDecorationBases()
    end
    if window.TabGroup and window.TabGroup.RestoreActiveTab then
        window.TabGroup:RestoreActiveTab()
    end
    if window.SettingsTabGroup and window.SettingsTabGroup.RestoreActivePage then
        window.SettingsTabGroup:RestoreActivePage()
    end

    -- Crossfade every color that changed from the old theme into the new one.
    applyColorFade(colorSnap)

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