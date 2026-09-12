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

local ThemeManager = {}

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

-- How long (seconds) the theme color crossfade takes. Tweak this one number to
-- make theme switches fade slower/faster. Can also be changed at runtime:
--   require(...Themes.ThemeManager).ColorFadeTime = 0.4
ThemeManager.ColorFadeTime = 0.35

-- Color crossfade: snapshot every element's current colors, let ApplyTheme set
-- the new theme instantly, then for any element whose color changed, restore
-- the old color and tween it to the new one. This makes a theme switch read as
-- the colors fading from the old theme into the new one (no dim/flash overlay).
local COLOR_PROPS = { "BackgroundColor3", "TextColor3", "ImageColor3" }

local function snapshotColors(window)
    local snap = {}
    for _, d in ipairs(window.Base:GetDescendants()) do
        local props = {}
        for _, p in ipairs(COLOR_PROPS) do
            local ok, v = pcall(function() return d[p] end)
            if ok and typeof(v) == "Color3" then
                table.insert(props, { p, v })
            end
        end
        if d:IsA("UIStroke") then
            local ok, v = pcall(function() return d.Color end)
            if ok and typeof(v) == "Color3" then
                table.insert(props, { "Color", v })
            end
        end
        if #props > 0 then
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

function ThemeManager.GetTheme(themeInput)
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
    return theme
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
    Tween.CancelAll(window.Base)
    for _, descendant in ipairs(window.Base:GetDescendants()) do
        Tween.CancelAll(descendant)
    end

    -- Snapshot current colors so the switch can crossfade old -> new.
    local colorSnap = snapshotColors(window)

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

    -- Keep TabGroup's copy of the theme in sync and invalidate fade caches
    -- so tab switches re-read the new theme instead of stale base values.
    if window.TabGroup then
        window.TabGroup._theme = theme
        window.TabGroup._fadeCaches = {}
        if window.TabGroup.Tabs then
            for _, tab in ipairs(window.TabGroup.Tabs) do
                tab._theme = theme
            end
        end
    end

    -- Keep SettingsTabGroup's copy of the theme in sync as well.
    if window.SettingsTabGroup then
        window.SettingsTabGroup._theme = theme
        window.SettingsTabGroup._fadeCaches = {}
        if window.SettingsTabGroup.Tabs then
            for _, tab in ipairs(window.SettingsTabGroup.Tabs) do
                tab._theme = theme
            end
        end
    end

    -- The WINDOW is the root of the tree (window.Base == the ScreenGui), so it
    -- cannot self-register: the registry iterates Base's DESCENDANTS, which
    -- excludes Base itself. Call the window's own ApplyTheme explicitly first.
    if window.ApplyTheme then
        pcall(function() window:ApplyTheme(theme) end)
    end

    -- Component-owned theming: any component that registered itself gets its
    -- ApplyTheme(theme) called here. This is the robust path - new components
    -- can theme themselves fully without ThemeManager having to know their
    -- structure. Runs before the color crossfade so changes are still faded.
    for _, descendant in ipairs(window.Base:GetDescendants()) do
        local comp = ThemeManager._components[descendant]
        if comp and comp.ApplyTheme then
            pcall(function() comp:ApplyTheme(theme) end)
        end
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

    -- The CancelAll pass also killed any in-flight page fade, which could leave
    -- the active page stuck transparent. Restore both active pages to natural.
    if window.TabGroup and window.TabGroup.RestoreActiveTab then
        window.TabGroup:RestoreActiveTab()
    end
    if window.SettingsTabGroup and window.SettingsTabGroup.RestoreActivePage then
        window.SettingsTabGroup:RestoreActivePage()
    end

    -- Crossfade every color that changed from the old theme into the new one.
    applyColorFade(colorSnap)
end

-- Update theme at runtime (e.g., window:SetTheme("Black"))
function ThemeManager.UpdateTheme(window, newTheme)
    ThemeManager.ApplyTheme(window, newTheme)
end

return ThemeManager