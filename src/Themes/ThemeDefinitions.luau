--[[
	ThemeDefinitions  ·  Aetheris UI Library

	Defines every named theme and the full theme-key schema. Each theme table
	overrides specific visual properties; GetTheme merges a theme over Default
	so any missing key falls back safely. Three post-processing maps are
	applied before `return ThemeDefinitions`:

	  * WALLPAPERS          - per-theme backdrop asset (brand imagery)
	  * WINDOW_CONTROLS     - per-theme close/max/min icon color
	  * THEME_TRANSPARENCY  - per-theme {WindowT, SidebarT, ContentT}

	Public access is via Themes.ThemeManager (GetTheme / ApplyTheme / Update).
]]

--[[
    THEME KEYS & THEIR EFFECTS

    Window:
        WindowColor                     - Background of the main window frame.
        WindowTransparency              - Transparency of the window background.
        WindowControlColor              - Color of the close/maximize/minimize icons.
        ContentBackgroundColor          - Fill for the region right of the sidebar (falls back to WindowColor).
        ContentBackgroundTransparency   - Transparency of that content fill (falls back to WindowTransparency).
        MainframeShadowColor            - Color of the drop shadow behind the window.

    Sidebar:
        SidebarColor                    - Background color of the sidebar.
        SidebarTransparency             - Transparency of the sidebar.

    Components (common):
        ComponentBackgroundColor        - Background color for component containers (rows, frames).
        ComponentBackgroundTransparency - Transparency for component backgrounds.
        InputBackgroundColor            - Background color for text inputs (Slider, Stepper, Keybind, TextInput).
        InputBackgroundTransparency     - Transparency for text input backgrounds.
        ComponentShadowColor            - Color of shadows on interactive components.
        StrokeColor                     - Color of borders/outlines.
        StrokeTransparency              - Transparency of borders/outlines.
        PrimaryColor                    - Main fill/accent color (e.g., slider fill, toggle on, button glow, radio selected).
        SecondaryColor                  - Secondary fill color (e.g., toggle track off, selection status background).
        TertiaryColor                   - Tertiary fill (e.g., some inactive indicators).
        Undercolor                      - Color for unfilled portions (e.g., progress bar track).
        AccentColor                     - Highlight color (e.g., icons, chevrons, dividers, search icon, tab image, active elements).

    Text:
        PrimaryTextColor                - Main text for labels, titles, inputs.
        PrimaryTextTransparency         - Transparency of primary text (0=opaque, 1=transparent).
        SecondaryTextColor              - Less prominent text (e.g., descriptions, stats, placeholders).
        SecondaryTextTransparency       - Transparency for secondary text.
        TitleTextColor                  - Title text (PageTitle, ScriptName, DisplayName, etc.).
        InactiveTabTextColor            - Text color for tab labels when not selected.
        InactiveTabIconColor            - Icon color for tab icons when not selected.
        ActiveTabTextColor              - Text color for tab labels when selected.
        ActiveTabIconColor              - Icon color for tab icons when selected.
        ActiveTabTextTransparency       - Transparency for active tab text (0=opaque, 1=transparent).
        InactiveTabTextTransparency     - Transparency for inactive tab text.
        ActiveTabIconTransparency       - Transparency for active tab icon.
        InactiveTabIconTransparency     - Transparency for inactive tab icon.

    Tabs:
        ActiveTabButtonColor            - Background color for the active tab button.
        ActiveTabButtonTransparency     - Transparency for the active tab button.
        InactiveTabButtonColor          - Background color for inactive tab buttons.
        InactiveTabButtonTransparency   - Transparency for inactive tab buttons.

    Section:
        SectionBackgroundColor          - Background of section containers.
        SectionBackgroundTransparency   - Transparency of section backgrounds.
        SectionStrokeColor              - Color of the section's own border stroke (falls back to StrokeColor).
        SectionStrokeTransparency       - Transparency of the section's own border stroke (falls back to StrokeTransparency).
        SectionDividerColor             - Background color of section dividers.
        SectionDividerTransparency      - Transparency of section dividers.

    Search bar:
        SearchBarBackgroundColor        - Background color of the sidebar search bar.
        SearchBarBackgroundTransparency - Transparency of the sidebar search bar.

    Popups (notifications, dropdowns, color picker):
        PopupBackgroundColor            - Main background of popup frames.
        PopupBackgroundTransparency     - Transparency of popup background.
        PopupNeutralColor               - Neutral color (e.g., cancel buttons, inactive elements).
        PopupShadowColor                - Shadow color for popups.
        PopupTextColor                  - Text color inside popups.
        PopupTextTransparency           - Transparency of popup text.

    Wallpaper:
        Wallpaper                       - Image asset ID for the decorative background.
        WallpaperEnabled                - Whether the wallpaper and all brand back images are shown.
--]]

local ThemeDefinitions = {}

-- Base: the structural merge base. Every theme is merged over this table, so
-- any key a theme omits falls back here. It is NOT the launch default -- that
-- lives in ThemeManager.DefaultTheme. Matches the original Aetheris look:
-- near-black window @ 0.1, dark sidebar, white strokes/icons, deep blue accents.
ThemeDefinitions.Base = {
    -- Window
    WindowColor = Color3.fromRGB(15, 15, 16),
    WindowTransparency = 0.1,
    WindowControlColor = Color3.fromRGB(255, 255, 255),
    ContentBackgroundColor = Color3.fromRGB(15, 15, 16),
    ContentBackgroundTransparency = 1,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(20, 20, 20),
    SidebarTransparency = 1,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.985,
    InputBackgroundColor = Color3.fromRGB(26, 26, 28),
    InputBackgroundTransparency = 1,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.95,
    PrimaryColor = Color3.fromRGB(13, 44, 177),
	SecondaryColor = Color3.fromRGB(13, 44, 177),
    TertiaryColor = Color3.fromRGB(150, 150, 150),
    Undercolor = Color3.fromRGB(30, 30, 30),
    AccentColor = Color3.fromRGB(14, 45, 178),

    -- Text
    PrimaryTextColor = Color3.fromRGB(255, 255, 255),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(200, 200, 200),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(200, 200, 200),
    InactiveTabIconColor = Color3.fromRGB(200, 200, 200),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    ActiveTabButtonTransparency = 0.99,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    -- Section strokes are independent of the general StrokeColor/Transparency so
    -- a theme can soften section borders without touching every other outline.
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.98,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(255, 255, 255),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(26, 30, 255),
    SearchBarBackgroundTransparency = 1,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(15, 15, 16),
    PopupBackgroundTransparency = 0.07,
    PopupNeutralColor = Color3.fromRGB(46, 46, 46),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(255, 255, 255),
    PopupTextTransparency = 0.2,

    -- Notifications (Alert / Error / Variable toasts)
    NotificationBackgroundColor = Color3.fromRGB(30, 41, 59),
    NotificationBackgroundTransparency = 0.1,
    NotificationShadowColor = Color3.fromRGB(0, 0, 0),
    NotificationHeaderColor = Color3.fromRGB(255, 255, 255),
    NotificationHeaderTransparency = 0.2,
    NotificationTextColor = Color3.fromRGB(226, 232, 240),
    NotificationTextTransparency = 0.4,
    NotificationDividerColor = Color3.fromRGB(148, 163, 184),
    NotificationDividerTransparency = 0.7,
    NotificationDismissColor = Color3.fromRGB(203, 213, 225),
    NotificationActionButtonColor = Color3.fromRGB(51, 65, 85),
    NotificationActionButtonTextColor = Color3.fromRGB(241, 245, 249),
    NotificationAlertAccent = Color3.fromRGB(249, 115, 22),
    NotificationErrorAccent = Color3.fromRGB(226, 42, 42),
    NotificationVariableAccent = Color3.fromRGB(74, 200, 120),

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Umbral: flagship dark. Cool blue-grey near-black, deeply frosted sidebar,
-- a faint content tint, and a muted steel-blue accent. This is the launch
-- default and the reference point for every other dark theme.
ThemeDefinitions.Umbral = {
    -- Window
    WindowColor = Color3.fromRGB(14, 16, 22),
    WindowTransparency = 0.15,
    ContentBackgroundColor = Color3.fromRGB(16, 19, 26),
    ContentBackgroundTransparency = 0.1,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(19, 23, 31),
    SidebarTransparency = 0.72,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(28, 33, 44),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(92, 124, 176),
    SecondaryColor = Color3.fromRGB(58, 72, 96),
    TertiaryColor = Color3.fromRGB(120, 132, 150),
    Undercolor = Color3.fromRGB(34, 40, 52),
    AccentColor = Color3.fromRGB(122, 156, 210),

    -- Text
    PrimaryTextColor = Color3.fromRGB(238, 242, 248),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(178, 188, 202),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(178, 188, 202),
    InactiveTabIconColor = Color3.fromRGB(178, 188, 202),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    ActiveTabButtonTransparency = 0.99,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(255, 255, 255),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(28, 33, 44),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(18, 22, 30),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(44, 51, 65),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(240, 244, 250),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Ember: warm dark. Charcoal-brown surfaces lit by a burnt-orange accent,
-- frosted sidebar over an opaque content area.
ThemeDefinitions.Ember = {
    -- Window
    WindowColor = Color3.fromRGB(18, 14, 12),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(20, 15, 13),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(24, 18, 15),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(34, 25, 21),
    InputBackgroundTransparency = 0.1,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(196, 92, 30),
    SecondaryColor = Color3.fromRGB(122, 62, 34),
    TertiaryColor = Color3.fromRGB(170, 120, 96),
    Undercolor = Color3.fromRGB(42, 30, 25),
    AccentColor = Color3.fromRGB(214, 104, 40),

    -- Text
    PrimaryTextColor = Color3.fromRGB(244, 238, 233),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(198, 180, 168),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(198, 180, 168),
    InactiveTabIconColor = Color3.fromRGB(198, 180, 168),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 236, 224),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(214, 104, 40),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(255, 255, 255),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(34, 25, 21),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(22, 16, 13),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(52, 38, 31),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(246, 240, 235),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Vesper: violet dusk. Deep indigo-violet chrome with translucent content
-- floating over the wallpaper and a solid sidebar to keep nav legible.
ThemeDefinitions.Vesper = {
    -- Window
    WindowColor = Color3.fromRGB(20, 16, 30),
    WindowTransparency = 0.28,
    ContentBackgroundColor = Color3.fromRGB(22, 18, 34),
    ContentBackgroundTransparency = 0.42,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(26, 22, 38),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(38, 32, 54),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(139, 92, 246),
    SecondaryColor = Color3.fromRGB(91, 60, 158),
    TertiaryColor = Color3.fromRGB(150, 130, 180),
    Undercolor = Color3.fromRGB(44, 37, 62),
    AccentColor = Color3.fromRGB(167, 139, 250),

    -- Text
    PrimaryTextColor = Color3.fromRGB(240, 237, 250),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(190, 182, 210),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(190, 182, 210),
    InactiveTabIconColor = Color3.fromRGB(190, 182, 210),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(139, 92, 246),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(255, 255, 255),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(38, 32, 54),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(24, 20, 36),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(54, 46, 76),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(242, 240, 252),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Duskfall: plum and amber dusk. Warm plum-dark chrome, translucent content
-- over the wallpaper, solid sidebar, orange accent.
ThemeDefinitions.Duskfall = {
    -- Window
    WindowColor = Color3.fromRGB(26, 18, 26),
    WindowTransparency = 0.28,
    ContentBackgroundColor = Color3.fromRGB(30, 20, 30),
    ContentBackgroundTransparency = 0.42,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(32, 22, 32),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(44, 30, 44),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(214, 122, 54),
    SecondaryColor = Color3.fromRGB(122, 74, 110),
    TertiaryColor = Color3.fromRGB(180, 140, 150),
    Undercolor = Color3.fromRGB(52, 36, 50),
    AccentColor = Color3.fromRGB(232, 140, 70),

    -- Text
    PrimaryTextColor = Color3.fromRGB(246, 238, 240),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(204, 184, 196),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(204, 184, 196),
    InactiveTabIconColor = Color3.fromRGB(204, 184, 196),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 236, 222),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(232, 140, 70),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(255, 255, 255),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(44, 30, 44),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(30, 20, 30),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(62, 44, 60),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(246, 238, 242),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Canopy: forest green. Deep mossy-dark chrome, translucent content over the
-- wallpaper, solid sidebar, emerald-lime accent.
ThemeDefinitions.Canopy = {
    -- Window
    WindowColor = Color3.fromRGB(14, 22, 18),
    WindowTransparency = 0.28,
    ContentBackgroundColor = Color3.fromRGB(16, 26, 21),
    ContentBackgroundTransparency = 0.42,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(18, 30, 24),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(26, 40, 32),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(52, 168, 104),
    SecondaryColor = Color3.fromRGB(38, 92, 62),
    TertiaryColor = Color3.fromRGB(120, 168, 140),
    Undercolor = Color3.fromRGB(30, 46, 38),
    AccentColor = Color3.fromRGB(132, 204, 92),

    -- Text
    PrimaryTextColor = Color3.fromRGB(236, 244, 238),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(176, 200, 186),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(176, 200, 186),
    InactiveTabIconColor = Color3.fromRGB(176, 200, 186),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(230, 248, 232),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(132, 204, 92),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(255, 255, 255),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(26, 40, 32),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(16, 26, 21),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(40, 58, 48),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(238, 246, 240),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Tidewater: coastal blue. Deep teal-dark chrome, translucent content over the
-- wallpaper, solid sidebar, cyan accent.
ThemeDefinitions.Tidewater = {
    -- Window
    WindowColor = Color3.fromRGB(12, 22, 28),
    WindowTransparency = 0.28,
    ContentBackgroundColor = Color3.fromRGB(14, 26, 33),
    ContentBackgroundTransparency = 0.42,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(16, 30, 38),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(24, 42, 52),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(34, 170, 200),
    SecondaryColor = Color3.fromRGB(30, 90, 110),
    TertiaryColor = Color3.fromRGB(110, 168, 186),
    Undercolor = Color3.fromRGB(28, 48, 58),
    AccentColor = Color3.fromRGB(84, 214, 234),

    -- Text
    PrimaryTextColor = Color3.fromRGB(234, 244, 248),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(172, 198, 208),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(172, 198, 208),
    InactiveTabIconColor = Color3.fromRGB(172, 198, 208),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(226, 248, 252),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(84, 214, 234),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(255, 255, 255),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(24, 42, 52),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(14, 26, 33),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(36, 58, 70),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(236, 246, 250),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Nocturne: vivid night. Indigo-dark chrome, frosted sidebar over opaque
-- content, magenta-indigo accent.
ThemeDefinitions.Nocturne = {
    -- Window
    WindowColor = Color3.fromRGB(16, 14, 26),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(18, 16, 30),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(24, 20, 40),
    SidebarTransparency = 0.68,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(32, 27, 52),
    InputBackgroundTransparency = 0.1,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(190, 72, 200),
    SecondaryColor = Color3.fromRGB(88, 62, 158),
    TertiaryColor = Color3.fromRGB(160, 130, 190),
    Undercolor = Color3.fromRGB(40, 34, 62),
    AccentColor = Color3.fromRGB(224, 108, 220),

    -- Text
    PrimaryTextColor = Color3.fromRGB(240, 236, 248),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(190, 180, 208),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(190, 180, 208),
    InactiveTabIconColor = Color3.fromRGB(190, 180, 208),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 236, 252),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(224, 108, 220),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(255, 255, 255),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(32, 27, 52),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(20, 17, 34),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(48, 40, 72),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(242, 238, 250),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Solace: soft ice-blue light. Near-white chrome, frosted light sidebar over
-- opaque content, cool ice-blue accent.
ThemeDefinitions.Solace = {
    -- Window
    WindowColor = Color3.fromRGB(244, 247, 251),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(250, 251, 253),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(120, 140, 160),

    -- Sidebar
    SidebarColor = Color3.fromRGB(228, 236, 245),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(233, 239, 246),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(150, 168, 188),
    StrokeColor = Color3.fromRGB(120, 140, 165),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(70, 140, 210),
    SecondaryColor = Color3.fromRGB(180, 200, 220),
    TertiaryColor = Color3.fromRGB(150, 168, 188),
    Undercolor = Color3.fromRGB(214, 226, 238),
    AccentColor = Color3.fromRGB(56, 130, 205),

    -- Text
    PrimaryTextColor = Color3.fromRGB(28, 40, 56),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(90, 106, 126),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(18, 28, 42),
    InactiveTabTextColor = Color3.fromRGB(96, 114, 136),
    InactiveTabIconColor = Color3.fromRGB(96, 114, 136),
    ActiveTabTextColor = Color3.fromRGB(20, 34, 52),
    ActiveTabIconColor = Color3.fromRGB(20, 34, 52),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(70, 140, 210),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(120, 140, 165),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(170, 186, 204),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(233, 239, 246),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(252, 253, 255),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(228, 236, 245),
    PopupShadowColor = Color3.fromRGB(120, 140, 160),
    PopupTextColor = Color3.fromRGB(28, 40, 56),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Cielo: clean daylight. Bright white chrome, frosted sidebar over opaque
-- content, saturated cobalt-blue accent.
ThemeDefinitions.Cielo = {
    -- Window
    WindowColor = Color3.fromRGB(246, 248, 252),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(252, 253, 255),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(110, 130, 170),

    -- Sidebar
    SidebarColor = Color3.fromRGB(226, 234, 248),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(232, 238, 250),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(140, 158, 188),
    StrokeColor = Color3.fromRGB(110, 130, 170),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(24, 82, 200),
    SecondaryColor = Color3.fromRGB(178, 194, 222),
    TertiaryColor = Color3.fromRGB(140, 158, 188),
    Undercolor = Color3.fromRGB(210, 222, 240),
    AccentColor = Color3.fromRGB(28, 96, 224),

    -- Text
    PrimaryTextColor = Color3.fromRGB(22, 32, 52),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(82, 98, 124),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(14, 22, 40),
    InactiveTabTextColor = Color3.fromRGB(88, 104, 132),
    InactiveTabIconColor = Color3.fromRGB(88, 104, 132),
    ActiveTabTextColor = Color3.fromRGB(16, 28, 50),
    ActiveTabIconColor = Color3.fromRGB(16, 28, 50),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(28, 96, 224),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(110, 130, 170),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(160, 178, 208),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(232, 238, 250),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(252, 253, 255),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(226, 234, 248),
    PopupShadowColor = Color3.fromRGB(110, 130, 170),
    PopupTextColor = Color3.fromRGB(22, 32, 52),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Honey: warm morning light. Cream chrome, frosted sidebar over opaque
-- content, amber-gold accent.
ThemeDefinitions.Honey = {
    -- Window
    WindowColor = Color3.fromRGB(250, 247, 240),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(253, 251, 246),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(150, 130, 100),

    -- Sidebar
    SidebarColor = Color3.fromRGB(242, 234, 216),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(242, 235, 220),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(168, 148, 118),
    StrokeColor = Color3.fromRGB(150, 130, 100),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(196, 142, 34),
    SecondaryColor = Color3.fromRGB(216, 200, 170),
    TertiaryColor = Color3.fromRGB(176, 156, 124),
    Undercolor = Color3.fromRGB(228, 216, 192),
    AccentColor = Color3.fromRGB(222, 168, 48),

    -- Text
    PrimaryTextColor = Color3.fromRGB(48, 38, 24),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(112, 96, 72),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(38, 30, 18),
    InactiveTabTextColor = Color3.fromRGB(118, 100, 76),
    InactiveTabIconColor = Color3.fromRGB(118, 100, 76),
    ActiveTabTextColor = Color3.fromRGB(40, 32, 18),
    ActiveTabIconColor = Color3.fromRGB(40, 32, 18),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(222, 168, 48),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(150, 130, 100),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(192, 176, 148),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(242, 235, 220),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(253, 251, 246),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(242, 234, 216),
    PopupShadowColor = Color3.fromRGB(150, 130, 100),
    PopupTextColor = Color3.fromRGB(48, 38, 24),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Dawn: soft rose-peach morning. Warm blush-white chrome, frosted sidebar
-- over opaque content, gentle coral accent.
ThemeDefinitions.Dawn = {
    -- Window
    WindowColor = Color3.fromRGB(250, 244, 244),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(253, 249, 248),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(160, 120, 120),

    -- Sidebar
    SidebarColor = Color3.fromRGB(244, 228, 226),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(244, 232, 230),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(180, 140, 138),
    StrokeColor = Color3.fromRGB(160, 120, 120),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(214, 122, 128),
    SecondaryColor = Color3.fromRGB(226, 200, 198),
    TertiaryColor = Color3.fromRGB(190, 156, 156),
    Undercolor = Color3.fromRGB(236, 214, 212),
    AccentColor = Color3.fromRGB(236, 146, 140),

    -- Text
    PrimaryTextColor = Color3.fromRGB(56, 36, 40),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(124, 94, 96),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(46, 28, 32),
    InactiveTabTextColor = Color3.fromRGB(128, 98, 100),
    InactiveTabIconColor = Color3.fromRGB(128, 98, 100),
    ActiveTabTextColor = Color3.fromRGB(48, 30, 34),
    ActiveTabIconColor = Color3.fromRGB(48, 30, 34),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(236, 146, 140),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(160, 120, 120),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(206, 178, 178),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(244, 232, 230),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(253, 249, 248),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(244, 228, 226),
    PopupShadowColor = Color3.fromRGB(160, 120, 120),
    PopupTextColor = Color3.fromRGB(56, 36, 40),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Alpine: crisp mountain daylight. Clean white chrome, translucent content
-- over the wallpaper, solid sidebar, bright sky-blue accent.
ThemeDefinitions.Alpine = {
    -- Window
    WindowColor = Color3.fromRGB(242, 246, 251),
    WindowTransparency = 0.28,
    ContentBackgroundColor = Color3.fromRGB(246, 250, 254),
    ContentBackgroundTransparency = 0.42,
    MainframeShadowColor = Color3.fromRGB(120, 140, 170),

    -- Sidebar
    SidebarColor = Color3.fromRGB(226, 234, 244),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(230, 238, 248),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(140, 160, 190),
    StrokeColor = Color3.fromRGB(120, 140, 170),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(42, 130, 210),
    SecondaryColor = Color3.fromRGB(180, 198, 220),
    TertiaryColor = Color3.fromRGB(140, 162, 190),
    Undercolor = Color3.fromRGB(212, 226, 240),
    AccentColor = Color3.fromRGB(60, 154, 232),

    -- Text
    PrimaryTextColor = Color3.fromRGB(24, 38, 58),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(84, 104, 130),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(16, 28, 46),
    InactiveTabTextColor = Color3.fromRGB(90, 110, 138),
    InactiveTabIconColor = Color3.fromRGB(90, 110, 138),
    ActiveTabTextColor = Color3.fromRGB(18, 32, 52),
    ActiveTabIconColor = Color3.fromRGB(18, 32, 52),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(60, 154, 232),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(120, 140, 170),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(168, 184, 206),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(230, 238, 248),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(246, 250, 254),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(226, 234, 244),
    PopupShadowColor = Color3.fromRGB(120, 140, 170),
    PopupTextColor = Color3.fromRGB(24, 38, 58),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Peony: coral bloom. Soft blush-white chrome, translucent content over the
-- wallpaper, solid sidebar, warm coral accent.
ThemeDefinitions.Peony = {
    -- Window
    WindowColor = Color3.fromRGB(251, 244, 242),
    WindowTransparency = 0.28,
    ContentBackgroundColor = Color3.fromRGB(253, 248, 246),
    ContentBackgroundTransparency = 0.42,
    MainframeShadowColor = Color3.fromRGB(170, 120, 118),

    -- Sidebar
    SidebarColor = Color3.fromRGB(246, 228, 224),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(246, 232, 228),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(184, 140, 136),
    StrokeColor = Color3.fromRGB(170, 120, 118),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(228, 112, 104),
    SecondaryColor = Color3.fromRGB(232, 202, 198),
    TertiaryColor = Color3.fromRGB(196, 152, 148),
    Undercolor = Color3.fromRGB(240, 214, 210),
    AccentColor = Color3.fromRGB(244, 132, 118),

    -- Text
    PrimaryTextColor = Color3.fromRGB(58, 34, 36),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(126, 92, 92),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(46, 26, 28),
    InactiveTabTextColor = Color3.fromRGB(130, 96, 96),
    InactiveTabIconColor = Color3.fromRGB(130, 96, 96),
    ActiveTabTextColor = Color3.fromRGB(50, 28, 30),
    ActiveTabIconColor = Color3.fromRGB(50, 28, 30),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(244, 132, 118),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(170, 120, 118),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(212, 178, 174),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(246, 232, 228),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(253, 248, 246),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(246, 228, 224),
    PopupShadowColor = Color3.fromRGB(170, 120, 118),
    PopupTextColor = Color3.fromRGB(58, 34, 36),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Sakura: soft rose pink. Airy blush-white chrome, translucent content over
-- the wallpaper, solid sidebar, warm rose accent.
ThemeDefinitions.Sakura = {
    -- Window
    WindowColor = Color3.fromRGB(252, 245, 247),
    WindowTransparency = 0.28,
    ContentBackgroundColor = Color3.fromRGB(254, 249, 250),
    ContentBackgroundTransparency = 0.42,
    MainframeShadowColor = Color3.fromRGB(176, 128, 140),

    -- Sidebar
    SidebarColor = Color3.fromRGB(248, 230, 234),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(248, 234, 238),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(190, 146, 158),
    StrokeColor = Color3.fromRGB(176, 128, 140),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(226, 110, 138),
    SecondaryColor = Color3.fromRGB(234, 204, 212),
    TertiaryColor = Color3.fromRGB(198, 156, 168),
    Undercolor = Color3.fromRGB(242, 216, 222),
    AccentColor = Color3.fromRGB(240, 128, 158),

    -- Text
    PrimaryTextColor = Color3.fromRGB(58, 34, 42),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(126, 92, 102),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(46, 26, 34),
    InactiveTabTextColor = Color3.fromRGB(132, 96, 106),
    InactiveTabIconColor = Color3.fromRGB(132, 96, 106),
    ActiveTabTextColor = Color3.fromRGB(52, 28, 38),
    ActiveTabIconColor = Color3.fromRGB(52, 28, 38),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(240, 128, 158),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(176, 128, 140),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(216, 180, 188),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(248, 234, 238),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(254, 249, 250),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(248, 230, 234),
    PopupShadowColor = Color3.fromRGB(176, 128, 140),
    PopupTextColor = Color3.fromRGB(58, 34, 42),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Blush: deep rose minimal. Warm off-white chrome, frosted sidebar over
-- opaque content, deep rose accent.
ThemeDefinitions.Blush = {
    -- Window
    WindowColor = Color3.fromRGB(252, 246, 248),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(254, 250, 251),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(180, 140, 155),

    -- Sidebar
    SidebarColor = Color3.fromRGB(246, 230, 236),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(246, 234, 240),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(190, 152, 168),
    StrokeColor = Color3.fromRGB(180, 140, 155),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(196, 54, 96),
    SecondaryColor = Color3.fromRGB(228, 200, 214),
    TertiaryColor = Color3.fromRGB(190, 156, 172),
    Undercolor = Color3.fromRGB(236, 216, 226),
    AccentColor = Color3.fromRGB(212, 74, 116),

    -- Text
    PrimaryTextColor = Color3.fromRGB(56, 30, 40),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(124, 88, 102),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(44, 24, 34),
    InactiveTabTextColor = Color3.fromRGB(130, 94, 108),
    InactiveTabIconColor = Color3.fromRGB(130, 94, 108),
    ActiveTabTextColor = Color3.fromRGB(48, 26, 36),
    ActiveTabIconColor = Color3.fromRGB(48, 26, 36),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(212, 74, 116),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(180, 140, 155),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(214, 184, 196),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(246, 234, 240),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(254, 250, 251),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(246, 230, 236),
    PopupShadowColor = Color3.fromRGB(180, 140, 155),
    PopupTextColor = Color3.fromRGB(56, 30, 40),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Cinder: Vivid fire. Near-black chrome with a bright molten-orange accent.
ThemeDefinitions.Cinder = {
    -- Window
    WindowColor = Color3.fromRGB(20, 13, 10),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(22, 15, 12),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(28, 18, 14),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(28, 18, 14),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(236, 110, 40),
    SecondaryColor = Color3.fromRGB(150, 70, 30),
    TertiaryColor = Color3.fromRGB(190, 130, 100),
    Undercolor = Color3.fromRGB(44, 28, 22),
    AccentColor = Color3.fromRGB(255, 145, 65),

    -- Text
    PrimaryTextColor = Color3.fromRGB(246, 238, 232),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(200, 178, 164),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(246, 238, 232),
    InactiveTabTextColor = Color3.fromRGB(200, 178, 164),
    InactiveTabIconColor = Color3.fromRGB(200, 178, 164),
    ActiveTabTextColor = Color3.fromRGB(246, 238, 232),
    ActiveTabIconColor = Color3.fromRGB(246, 238, 232),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(255, 145, 65),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(190, 130, 100),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(28, 18, 14),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(22, 15, 12),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(44, 28, 22),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(246, 238, 232),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Mauve: Soft violet. Muted lavender accent over deep plum-grey chrome.
ThemeDefinitions.Mauve = {
    -- Window
    WindowColor = Color3.fromRGB(22, 18, 30),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(26, 21, 34),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(30, 24, 40),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(30, 24, 40),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(150, 110, 190),
    SecondaryColor = Color3.fromRGB(95, 70, 125),
    TertiaryColor = Color3.fromRGB(160, 140, 185),
    Undercolor = Color3.fromRGB(46, 38, 60),
    AccentColor = Color3.fromRGB(180, 140, 220),

    -- Text
    PrimaryTextColor = Color3.fromRGB(242, 238, 250),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(190, 182, 208),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(242, 238, 250),
    InactiveTabTextColor = Color3.fromRGB(190, 182, 208),
    InactiveTabIconColor = Color3.fromRGB(190, 182, 208),
    ActiveTabTextColor = Color3.fromRGB(242, 238, 250),
    ActiveTabIconColor = Color3.fromRGB(242, 238, 250),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(180, 140, 220),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(160, 140, 185),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(30, 24, 40),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(26, 21, 34),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(46, 38, 60),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(242, 238, 250),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Iris: Deep purple. Saturated indigo-violet accent, moody and rich.
ThemeDefinitions.Iris = {
    -- Window
    WindowColor = Color3.fromRGB(18, 16, 34),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(22, 19, 40),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(26, 22, 46),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(26, 22, 46),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(120, 95, 200),
    SecondaryColor = Color3.fromRGB(75, 60, 135),
    TertiaryColor = Color3.fromRGB(145, 130, 195),
    Undercolor = Color3.fromRGB(40, 34, 66),
    AccentColor = Color3.fromRGB(155, 130, 235),

    -- Text
    PrimaryTextColor = Color3.fromRGB(240, 238, 252),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(186, 180, 214),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(240, 238, 252),
    InactiveTabTextColor = Color3.fromRGB(186, 180, 214),
    InactiveTabIconColor = Color3.fromRGB(186, 180, 214),
    ActiveTabTextColor = Color3.fromRGB(240, 238, 252),
    ActiveTabIconColor = Color3.fromRGB(240, 238, 252),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(155, 130, 235),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(145, 130, 195),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(26, 22, 46),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(22, 19, 40),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(40, 34, 66),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(240, 238, 252),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Sundown: Warm dusk. Amber-rose sunset glow on dark warm chrome.
ThemeDefinitions.Sundown = {
    -- Window
    WindowColor = Color3.fromRGB(28, 18, 20),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(32, 21, 23),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(36, 24, 26),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(36, 24, 26),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(220, 110, 80),
    SecondaryColor = Color3.fromRGB(140, 72, 66),
    TertiaryColor = Color3.fromRGB(190, 140, 135),
    Undercolor = Color3.fromRGB(52, 34, 36),
    AccentColor = Color3.fromRGB(245, 140, 105),

    -- Text
    PrimaryTextColor = Color3.fromRGB(248, 238, 236),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(206, 182, 180),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(248, 238, 236),
    InactiveTabTextColor = Color3.fromRGB(206, 182, 180),
    InactiveTabIconColor = Color3.fromRGB(206, 182, 180),
    ActiveTabTextColor = Color3.fromRGB(248, 238, 236),
    ActiveTabIconColor = Color3.fromRGB(248, 238, 236),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(245, 140, 105),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(190, 140, 135),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(36, 24, 26),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(32, 21, 23),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(52, 34, 36),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(248, 238, 236),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Twilight: Cool dusk. Blue-violet accent, calm and deep.
ThemeDefinitions.Twilight = {
    -- Window
    WindowColor = Color3.fromRGB(20, 20, 32),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(24, 24, 38),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(28, 28, 44),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(28, 28, 44),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(120, 120, 210),
    SecondaryColor = Color3.fromRGB(80, 80, 145),
    TertiaryColor = Color3.fromRGB(150, 150, 200),
    Undercolor = Color3.fromRGB(42, 42, 64),
    AccentColor = Color3.fromRGB(155, 155, 240),

    -- Text
    PrimaryTextColor = Color3.fromRGB(238, 240, 250),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(184, 188, 210),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(238, 240, 250),
    InactiveTabTextColor = Color3.fromRGB(184, 188, 210),
    InactiveTabIconColor = Color3.fromRGB(184, 188, 210),
    ActiveTabTextColor = Color3.fromRGB(238, 240, 250),
    ActiveTabIconColor = Color3.fromRGB(238, 240, 250),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(155, 155, 240),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(150, 150, 200),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(28, 28, 44),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(24, 24, 38),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(42, 42, 64),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(238, 240, 250),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Nebula: Aurora glow. Magenta accent with a cool cyan secondary.
ThemeDefinitions.Nebula = {
    -- Window
    WindowColor = Color3.fromRGB(16, 14, 26),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(20, 17, 32),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(24, 20, 38),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(24, 20, 38),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(190, 90, 210),
    SecondaryColor = Color3.fromRGB(120, 60, 140),
    TertiaryColor = Color3.fromRGB(170, 140, 200),
    Undercolor = Color3.fromRGB(38, 30, 58),
    AccentColor = Color3.fromRGB(140, 180, 240),

    -- Text
    PrimaryTextColor = Color3.fromRGB(242, 236, 252),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(192, 180, 214),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(242, 236, 252),
    InactiveTabTextColor = Color3.fromRGB(192, 180, 214),
    InactiveTabIconColor = Color3.fromRGB(192, 180, 214),
    ActiveTabTextColor = Color3.fromRGB(242, 236, 252),
    ActiveTabIconColor = Color3.fromRGB(242, 236, 252),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(140, 180, 240),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(170, 140, 200),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(24, 20, 38),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(20, 17, 32),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(38, 30, 58),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(242, 236, 252),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Monterey: Classic dark. Balanced steel-blue accent, restrained.
ThemeDefinitions.Monterey = {
    -- Window
    WindowColor = Color3.fromRGB(18, 18, 22),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(22, 22, 27),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(26, 26, 32),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(26, 26, 32),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(90, 120, 200),
    SecondaryColor = Color3.fromRGB(58, 78, 130),
    TertiaryColor = Color3.fromRGB(130, 145, 180),
    Undercolor = Color3.fromRGB(40, 44, 58),
    AccentColor = Color3.fromRGB(125, 155, 230),

    -- Text
    PrimaryTextColor = Color3.fromRGB(238, 240, 246),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(180, 186, 200),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(238, 240, 246),
    InactiveTabTextColor = Color3.fromRGB(180, 186, 200),
    InactiveTabIconColor = Color3.fromRGB(180, 186, 200),
    ActiveTabTextColor = Color3.fromRGB(238, 240, 246),
    ActiveTabIconColor = Color3.fromRGB(238, 240, 246),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(125, 155, 230),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(130, 145, 180),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(26, 26, 32),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(22, 22, 27),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(40, 44, 58),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(238, 240, 246),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Sonoma: Warm dark. Golden-tan accent, softer than Ember.
ThemeDefinitions.Sonoma = {
    -- Window
    WindowColor = Color3.fromRGB(22, 18, 16),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(26, 21, 18),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(30, 26, 22),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(30, 26, 22),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(190, 130, 80),
    SecondaryColor = Color3.fromRGB(120, 82, 50),
    TertiaryColor = Color3.fromRGB(170, 145, 120),
    Undercolor = Color3.fromRGB(48, 40, 34),
    AccentColor = Color3.fromRGB(220, 160, 110),

    -- Text
    PrimaryTextColor = Color3.fromRGB(246, 240, 234),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(200, 186, 172),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(246, 240, 234),
    InactiveTabTextColor = Color3.fromRGB(200, 186, 172),
    InactiveTabIconColor = Color3.fromRGB(200, 186, 172),
    ActiveTabTextColor = Color3.fromRGB(246, 240, 234),
    ActiveTabIconColor = Color3.fromRGB(246, 240, 234),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(220, 160, 110),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(170, 145, 120),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(30, 26, 22),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(26, 21, 18),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(48, 40, 34),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(246, 240, 234),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Ventura: Deep dusk. Soft violet-blue, low contrast, easy on the eye.
ThemeDefinitions.Ventura = {
    -- Window
    WindowColor = Color3.fromRGB(18, 16, 24),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(22, 20, 29),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(26, 24, 34),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(26, 24, 34),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(130, 110, 190),
    SecondaryColor = Color3.fromRGB(82, 70, 125),
    TertiaryColor = Color3.fromRGB(150, 140, 180),
    Undercolor = Color3.fromRGB(42, 38, 56),
    AccentColor = Color3.fromRGB(165, 145, 225),

    -- Text
    PrimaryTextColor = Color3.fromRGB(240, 238, 248),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(188, 184, 206),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(240, 238, 248),
    InactiveTabTextColor = Color3.fromRGB(188, 184, 206),
    InactiveTabIconColor = Color3.fromRGB(188, 184, 206),
    ActiveTabTextColor = Color3.fromRGB(240, 238, 248),
    ActiveTabIconColor = Color3.fromRGB(240, 238, 248),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(165, 145, 225),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(150, 140, 180),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(26, 24, 34),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(22, 20, 29),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(42, 38, 56),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(240, 238, 248),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Vermilion: Scarlet dusk. Bold red-orange accent with plum shadows.
ThemeDefinitions.Vermilion = {
    -- Window
    WindowColor = Color3.fromRGB(28, 16, 20),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(32, 19, 24),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(38, 22, 28),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(38, 22, 28),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(226, 90, 60),
    SecondaryColor = Color3.fromRGB(140, 58, 48),
    TertiaryColor = Color3.fromRGB(195, 135, 125),
    Undercolor = Color3.fromRGB(54, 32, 36),
    AccentColor = Color3.fromRGB(248, 120, 80),

    -- Text
    PrimaryTextColor = Color3.fromRGB(248, 238, 236),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(208, 180, 178),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(248, 238, 236),
    InactiveTabTextColor = Color3.fromRGB(208, 180, 178),
    InactiveTabIconColor = Color3.fromRGB(208, 180, 178),
    ActiveTabTextColor = Color3.fromRGB(248, 238, 236),
    ActiveTabIconColor = Color3.fromRGB(248, 238, 236),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(248, 120, 80),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(195, 135, 125),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(38, 22, 28),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(32, 19, 24),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(54, 32, 36),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(248, 238, 236),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Grove: Deep forest. Emerald accent, darker and denser than Canopy.
ThemeDefinitions.Grove = {
    -- Window
    WindowColor = Color3.fromRGB(14, 24, 18),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(17, 28, 22),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(20, 34, 26),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(20, 34, 26),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(60, 150, 90),
    SecondaryColor = Color3.fromRGB(38, 95, 58),
    TertiaryColor = Color3.fromRGB(120, 170, 140),
    Undercolor = Color3.fromRGB(30, 50, 40),
    AccentColor = Color3.fromRGB(110, 195, 120),

    -- Text
    PrimaryTextColor = Color3.fromRGB(236, 246, 240),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(178, 204, 190),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(236, 246, 240),
    InactiveTabTextColor = Color3.fromRGB(178, 204, 190),
    InactiveTabIconColor = Color3.fromRGB(178, 204, 190),
    ActiveTabTextColor = Color3.fromRGB(236, 246, 240),
    ActiveTabIconColor = Color3.fromRGB(236, 246, 240),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(110, 195, 120),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(120, 170, 140),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(20, 34, 26),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(17, 28, 22),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(30, 50, 40),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(236, 246, 240),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Prism: Vivid blue. Bright saturated azure, crisp and clean.
ThemeDefinitions.Prism = {
    -- Window
    WindowColor = Color3.fromRGB(16, 18, 28),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(20, 22, 34),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(24, 28, 42),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.97,
    InputBackgroundColor = Color3.fromRGB(24, 28, 42),
    InputBackgroundTransparency = 0.15,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.93,
    PrimaryColor = Color3.fromRGB(100, 140, 230),
    SecondaryColor = Color3.fromRGB(65, 90, 150),
    TertiaryColor = Color3.fromRGB(135, 155, 205),
    Undercolor = Color3.fromRGB(38, 44, 66),
    AccentColor = Color3.fromRGB(145, 185, 250),

    -- Text
    PrimaryTextColor = Color3.fromRGB(240, 243, 252),
    PrimaryTextTransparency = 0.1,
    SecondaryTextColor = Color3.fromRGB(184, 192, 214),
    SecondaryTextTransparency = 0.4,
    TitleTextColor = Color3.fromRGB(240, 243, 252),
    InactiveTabTextColor = Color3.fromRGB(184, 192, 214),
    InactiveTabIconColor = Color3.fromRGB(184, 192, 214),
    ActiveTabTextColor = Color3.fromRGB(240, 243, 252),
    ActiveTabIconColor = Color3.fromRGB(240, 243, 252),
    ActiveTabTextTransparency = 0.2,
    InactiveTabTextTransparency = 0.5,
    ActiveTabIconTransparency = 0.2,
    InactiveTabIconTransparency = 0.5,
    ActiveTabButtonColor = Color3.fromRGB(145, 185, 250),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.975,
    SectionStrokeColor = Color3.fromRGB(255, 255, 255),
    SectionStrokeTransparency = 0.98,
    SectionDividerColor = Color3.fromRGB(135, 155, 205),
    SectionDividerTransparency = 0.9,
    SearchBarBackgroundColor = Color3.fromRGB(24, 28, 42),
    SearchBarBackgroundTransparency = 0.5,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(20, 22, 34),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(38, 44, 66),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(240, 243, 252),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Sage: Soft green. Airy sage-grey chrome with a muted leaf accent.
ThemeDefinitions.Sage = {
    -- Window
    WindowColor = Color3.fromRGB(244, 248, 242),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(248, 251, 246),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(150, 175, 158),

    -- Sidebar
    SidebarColor = Color3.fromRGB(232, 240, 230),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(232, 240, 230),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(150, 175, 158),
    StrokeColor = Color3.fromRGB(120, 150, 130),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(78, 140, 92),
    SecondaryColor = Color3.fromRGB(150, 190, 160),
    TertiaryColor = Color3.fromRGB(150, 180, 160),
    Undercolor = Color3.fromRGB(214, 230, 218),
    AccentColor = Color3.fromRGB(110, 175, 120),

    -- Text
    PrimaryTextColor = Color3.fromRGB(30, 48, 36),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(96, 124, 106),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(30, 48, 36),
    InactiveTabTextColor = Color3.fromRGB(96, 124, 106),
    InactiveTabIconColor = Color3.fromRGB(96, 124, 106),
    ActiveTabTextColor = Color3.fromRGB(30, 48, 36),
    ActiveTabIconColor = Color3.fromRGB(30, 48, 36),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(110, 175, 120),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(120, 150, 130),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(150, 180, 160),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(232, 240, 230),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(248, 251, 246),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(214, 230, 218),
    PopupShadowColor = Color3.fromRGB(150, 175, 158),
    PopupTextColor = Color3.fromRGB(30, 48, 36),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Blossom: Pink bloom. Bright coral-pink accent on soft rose white.
ThemeDefinitions.Blossom = {
    -- Window
    WindowColor = Color3.fromRGB(252, 244, 246),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(254, 248, 250),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(200, 160, 178),

    -- Sidebar
    SidebarColor = Color3.fromRGB(246, 232, 238),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(246, 232, 238),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(200, 160, 178),
    StrokeColor = Color3.fromRGB(200, 160, 178),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(216, 110, 150),
    SecondaryColor = Color3.fromRGB(238, 200, 215),
    TertiaryColor = Color3.fromRGB(210, 170, 188),
    Undercolor = Color3.fromRGB(244, 222, 232),
    AccentColor = Color3.fromRGB(236, 140, 175),

    -- Text
    PrimaryTextColor = Color3.fromRGB(60, 30, 42),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(130, 92, 110),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(60, 30, 42),
    InactiveTabTextColor = Color3.fromRGB(130, 92, 110),
    InactiveTabIconColor = Color3.fromRGB(130, 92, 110),
    ActiveTabTextColor = Color3.fromRGB(60, 30, 42),
    ActiveTabIconColor = Color3.fromRGB(60, 30, 42),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(236, 140, 175),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(200, 160, 178),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(210, 170, 188),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(246, 232, 238),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(254, 248, 250),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(244, 222, 232),
    PopupShadowColor = Color3.fromRGB(200, 160, 178),
    PopupTextColor = Color3.fromRGB(60, 30, 42),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Petal: Rose petal. Deeper dusty pink, gentler than Peony.
ThemeDefinitions.Petal = {
    -- Window
    WindowColor = Color3.fromRGB(250, 240, 244),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(252, 245, 248),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(198, 155, 175),

    -- Sidebar
    SidebarColor = Color3.fromRGB(244, 226, 234),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(244, 226, 234),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(198, 155, 175),
    StrokeColor = Color3.fromRGB(196, 152, 172),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(200, 85, 130),
    SecondaryColor = Color3.fromRGB(232, 190, 208),
    TertiaryColor = Color3.fromRGB(204, 160, 180),
    Undercolor = Color3.fromRGB(240, 214, 226),
    AccentColor = Color3.fromRGB(226, 115, 158),

    -- Text
    PrimaryTextColor = Color3.fromRGB(58, 28, 40),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(128, 88, 106),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(58, 28, 40),
    InactiveTabTextColor = Color3.fromRGB(128, 88, 106),
    InactiveTabIconColor = Color3.fromRGB(128, 88, 106),
    ActiveTabTextColor = Color3.fromRGB(58, 28, 40),
    ActiveTabIconColor = Color3.fromRGB(58, 28, 40),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(226, 115, 158),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(196, 152, 172),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(204, 160, 180),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(244, 226, 234),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(252, 245, 248),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(240, 214, 226),
    PopupShadowColor = Color3.fromRGB(198, 155, 175),
    PopupTextColor = Color3.fromRGB(58, 28, 40),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Frost: Cool white. Crisp icy blue-grey, brighter than Solace.
ThemeDefinitions.Frost = {
    -- Window
    WindowColor = Color3.fromRGB(244, 247, 251),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(248, 251, 254),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(160, 180, 200),

    -- Sidebar
    SidebarColor = Color3.fromRGB(232, 238, 246),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(232, 238, 246),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(160, 180, 200),
    StrokeColor = Color3.fromRGB(150, 172, 198),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(90, 130, 190),
    SecondaryColor = Color3.fromRGB(190, 206, 228),
    TertiaryColor = Color3.fromRGB(160, 180, 205),
    Undercolor = Color3.fromRGB(220, 230, 242),
    AccentColor = Color3.fromRGB(130, 170, 220),

    -- Text
    PrimaryTextColor = Color3.fromRGB(28, 40, 58),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(94, 112, 136),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(28, 40, 58),
    InactiveTabTextColor = Color3.fromRGB(94, 112, 136),
    InactiveTabIconColor = Color3.fromRGB(94, 112, 136),
    ActiveTabTextColor = Color3.fromRGB(28, 40, 58),
    ActiveTabIconColor = Color3.fromRGB(28, 40, 58),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(130, 170, 220),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(150, 172, 198),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(160, 180, 205),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(232, 238, 246),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(248, 251, 254),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(220, 230, 242),
    PopupShadowColor = Color3.fromRGB(160, 180, 200),
    PopupTextColor = Color3.fromRGB(28, 40, 58),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Amber: Warm gold. Golden-hour warmth, richer than Honey.
ThemeDefinitions.Amber = {
    -- Window
    WindowColor = Color3.fromRGB(252, 246, 236),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(254, 249, 242),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(200, 175, 135),

    -- Sidebar
    SidebarColor = Color3.fromRGB(246, 236, 220),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(246, 236, 220),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(200, 175, 135),
    StrokeColor = Color3.fromRGB(196, 172, 132),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(200, 140, 60),
    SecondaryColor = Color3.fromRGB(238, 214, 175),
    TertiaryColor = Color3.fromRGB(210, 186, 150),
    Undercolor = Color3.fromRGB(244, 230, 205),
    AccentColor = Color3.fromRGB(230, 175, 90),

    -- Text
    PrimaryTextColor = Color3.fromRGB(58, 42, 22),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(126, 102, 68),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(58, 42, 22),
    InactiveTabTextColor = Color3.fromRGB(126, 102, 68),
    InactiveTabIconColor = Color3.fromRGB(126, 102, 68),
    ActiveTabTextColor = Color3.fromRGB(58, 42, 22),
    ActiveTabIconColor = Color3.fromRGB(58, 42, 22),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(230, 175, 90),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(196, 172, 132),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(210, 186, 150),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(246, 236, 220),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(254, 249, 242),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(244, 230, 205),
    PopupShadowColor = Color3.fromRGB(200, 175, 135),
    PopupTextColor = Color3.fromRGB(58, 42, 22),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Rosa: Dusty rose. Muted pink-grey, subtler than Blush.
ThemeDefinitions.Rosa = {
    -- Window
    WindowColor = Color3.fromRGB(252, 242, 246),
    WindowTransparency = 0.22,
    ContentBackgroundColor = Color3.fromRGB(254, 246, 250),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(200, 158, 178),

    -- Sidebar
    SidebarColor = Color3.fromRGB(246, 228, 238),
    SidebarTransparency = 0.62,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0.1,
    InputBackgroundColor = Color3.fromRGB(246, 228, 238),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(200, 158, 178),
    StrokeColor = Color3.fromRGB(198, 158, 176),
    StrokeTransparency = 0.82,
    PrimaryColor = Color3.fromRGB(200, 100, 140),
    SecondaryColor = Color3.fromRGB(236, 196, 214),
    TertiaryColor = Color3.fromRGB(208, 166, 186),
    Undercolor = Color3.fromRGB(242, 220, 232),
    AccentColor = Color3.fromRGB(228, 135, 170),

    -- Text
    PrimaryTextColor = Color3.fromRGB(58, 30, 42),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(128, 90, 108),
    SecondaryTextTransparency = 0.15,
    TitleTextColor = Color3.fromRGB(58, 30, 42),
    InactiveTabTextColor = Color3.fromRGB(128, 90, 108),
    InactiveTabIconColor = Color3.fromRGB(128, 90, 108),
    ActiveTabTextColor = Color3.fromRGB(58, 30, 42),
    ActiveTabIconColor = Color3.fromRGB(58, 30, 42),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(228, 135, 170),
    ActiveTabButtonTransparency = 0.85,
    InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    InactiveTabButtonTransparency = 1,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.4,
    SectionStrokeColor = Color3.fromRGB(198, 158, 176),
    SectionStrokeTransparency = 0.85,
    SectionDividerColor = Color3.fromRGB(208, 166, 186),
    SectionDividerTransparency = 0.5,
    SearchBarBackgroundColor = Color3.fromRGB(246, 228, 238),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(254, 246, 250),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(242, 220, 232),
    PopupShadowColor = Color3.fromRGB(200, 158, 178),
    PopupTextColor = Color3.fromRGB(58, 30, 42),
    PopupTextTransparency = 0.2,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}
-- Wallpapers (from the MaterialService decals). Assigned per theme so each
-- keeps its character; the tab/backdrop images use these when present.
local WALLPAPERS = {
    -- Custom art set (2026-10). Each theme gets one dominant-hue backdrop that
    -- matches its chrome; the image sits behind frosted chrome, so these are
    -- deliberately even-toned and low-clutter.
    Base      = "rbxassetid://126475867393987", -- Monterey dark (structural base)
    Umbral    = "rbxassetid://108134687422467", -- navy night range
    Ember     = "rbxassetid://112056619173488", -- molten coals
    Vesper    = "rbxassetid://139008744622245", -- violet twilight
    Duskfall  = "rbxassetid://84448785488489",  -- plum + amber dusk
    Canopy    = "rbxassetid://117265363863813", -- misty forest
    Tidewater = "rbxassetid://135568871834704", -- blue mountains (legacy)
    Nocturne  = "rbxassetid://95435913199118",  -- aurora
    Solace    = "rbxassetid://92445107726358",  -- ice-blue mist
    Cielo     = "rbxassetid://98569091830887",  -- WhiteSur (legacy)
    Honey     = "rbxassetid://73850635447680",  -- golden hour
    Dawn      = "rbxassetid://88171125327716",  -- Monterey morning (legacy)
    Alpine    = "rbxassetid://123969479560901", -- blue + white mountains (legacy)
    Peony     = "rbxassetid://131979800493713", -- pink waves (legacy)
    Sakura    = "rbxassetid://83848197180836",  -- rose blossom
    Blush     = "rbxassetid://8350591200",      -- pink minimal (legacy)
    Cinder     = "rbxassetid://91682462344785",
    Mauve      = "rbxassetid://129556634773235",
    Iris       = "rbxassetid://74675854421559",
    Sundown    = "rbxassetid://80301124180881",
    Twilight   = "rbxassetid://110295134647166",
    Nebula     = "rbxassetid://110937489750863",
    Monterey   = "rbxassetid://126475867393987",
    Sonoma     = "rbxassetid://114699504726298",
    Ventura    = "rbxassetid://100629172964437",
    Vermilion  = "rbxassetid://18571374017",
    Grove      = "rbxassetid://116321051235221",
    Prism      = "rbxassetid://78613064348772",
    Sage       = "rbxassetid://97394507475736",
    Blossom    = "rbxassetid://13426533185317",
    Petal      = "rbxassetid://119516266319751",
    Frost      = "rbxassetid://81270141924137",
    Amber      = "rbxassetid://79886157813963",
    Rosa       = "rbxassetid://107522899082679",
}

-- Window control icon colors (close/maximize/minimize). Dark themes get light
-- icons, light themes get dark ones, so they stay visible on the window chrome.
local WINDOW_CONTROLS = {
    Base      = Color3.fromRGB(255, 255, 255),
    Umbral    = Color3.fromRGB(226, 232, 240),
    Ember     = Color3.fromRGB(238, 214, 196),
    Vesper    = Color3.fromRGB(214, 206, 234),
    Duskfall  = Color3.fromRGB(240, 214, 190),
    Canopy    = Color3.fromRGB(206, 232, 210),
    Tidewater = Color3.fromRGB(200, 232, 240),
    Nocturne  = Color3.fromRGB(238, 214, 244),
    Solace    = Color3.fromRGB(40, 58, 80),
    Cielo     = Color3.fromRGB(36, 52, 84),
    Honey     = Color3.fromRGB(120, 96, 60),
    Dawn      = Color3.fromRGB(128, 96, 98),
    Alpine    = Color3.fromRGB(48, 72, 104),
    Peony     = Color3.fromRGB(150, 88, 92),
    Sakura    = Color3.fromRGB(154, 90, 108),
    Blush     = Color3.fromRGB(128, 82, 98),
    Cinder     = Color3.fromRGB(246, 238, 232),
    Mauve      = Color3.fromRGB(242, 238, 250),
    Iris       = Color3.fromRGB(240, 238, 252),
    Sundown    = Color3.fromRGB(248, 238, 236),
    Twilight   = Color3.fromRGB(238, 240, 250),
    Nebula     = Color3.fromRGB(242, 236, 252),
    Monterey   = Color3.fromRGB(238, 240, 246),
    Sonoma     = Color3.fromRGB(246, 240, 234),
    Ventura    = Color3.fromRGB(240, 238, 248),
    Vermilion  = Color3.fromRGB(248, 238, 236),
    Grove      = Color3.fromRGB(236, 246, 240),
    Prism      = Color3.fromRGB(240, 243, 252),
    Sage       = Color3.fromRGB(30, 48, 36),
    Blossom    = Color3.fromRGB(60, 30, 42),
    Petal      = Color3.fromRGB(58, 28, 40),
    Frost      = Color3.fromRGB(28, 40, 58),
    Amber      = Color3.fromRGB(58, 42, 22),
    Rosa       = Color3.fromRGB(58, 30, 42),
}

for name, controlColor in pairs(WINDOW_CONTROLS) do
    if ThemeDefinitions[name] then
        ThemeDefinitions[name].WindowControlColor = controlColor
    end
end

-- Per-theme transparency. Each theme is either sidebar-frosted over opaque
-- content, or content-translucent over a solid sidebar -- never both washed
-- out. { WindowTransparency, SidebarTransparency, ContentBackgroundTransparency }.
local THEME_TRANSPARENCY = {
    -- Three profiles, deliberately never both washed out:
    --   A = { 0.15, 0.72, 0.10 } deeply frosted sidebar, faint content tint
    --   B = { 0.22, 0.62, 0.00 } frosted sidebar, fully opaque content
    --   C = { 0.28, 0.00, 0.42 } solid sidebar, translucent content

    -- Profile A: flagship darks. The sidebar reads as glass over the wallpaper
    -- while the content area keeps only a hint of tint.
    Base      = { 0.15, 0.72, 0.1  },
    Umbral    = { 0.15, 0.72, 0.1  },
    Nocturne  = { 0.15, 0.72, 0.1  },

    -- Profile B: frosted sidebar, opaque content. Keeps text-heavy pages clean.
    Ember     = { 0.22, 0.62, 0    },
    Solace    = { 0.22, 0.62, 0    },
    Cielo     = { 0.22, 0.62, 0    },
    Honey     = { 0.22, 0.62, 0    },
    Dawn      = { 0.22, 0.62, 0    },
    Blush     = { 0.22, 0.62, 0    },

    -- Profile C: solid sidebar, translucent content. The wallpaper carries the
    -- content region instead of the rail.
    Vesper    = { 0.28, 0,    0.42 },
    Duskfall  = { 0.28, 0,    0.42 },
    Canopy    = { 0.28, 0,    0.42 },
    Tidewater = { 0.28, 0,    0.42 },
    Alpine    = { 0.28, 0,    0.42 },
    Peony     = { 0.28, 0,    0.42 },
    Sakura    = { 0.28, 0,    0.42 },
    Cinder     = { 0.22, 0.62, 0    },
    Mauve      = { 0.28, 0,    0.42 },
    Iris       = { 0.28, 0,    0.42 },
    Sundown    = { 0.28, 0,    0.42 },
    Twilight   = { 0.28, 0,    0.42 },
    Nebula     = { 0.15, 0.72, 0.1  },
    Monterey   = { 0.15, 0.72, 0.1  },
    Sonoma     = { 0.22, 0.62, 0    },
    Ventura    = { 0.28, 0,    0.42 },
    Vermilion  = { 0.28, 0,    0.42 },
    Grove      = { 0.28, 0,    0.42 },
    Prism      = { 0.22, 0.62, 0    },
    Sage       = { 0.22, 0.62, 0    },
    Blossom    = { 0.28, 0,    0.42 },
    Petal      = { 0.28, 0,    0.42 },
    Frost      = { 0.22, 0.62, 0    },
    Amber      = { 0.22, 0.62, 0    },
    Rosa       = { 0.28, 0,    0.42 },
}

for name, t in pairs(THEME_TRANSPARENCY) do
    local def = ThemeDefinitions[name]
    if def then
        def.WindowTransparency = t[1]
        def.SidebarTransparency = t[2]
        def.ContentBackgroundTransparency = t[3]
    end
end

-- Notifications derive their surface colors from the theme's popup/text colors
-- so every theme stays coherent without hand-authoring 15 keys x 19 themes.
for name, t in pairs(ThemeDefinitions) do
    if t.NotificationBackgroundColor == nil then
        t.NotificationBackgroundColor = t.PopupBackgroundColor or t.WindowColor
        t.NotificationBackgroundTransparency = math.clamp((t.PopupBackgroundTransparency or 0) + 0.1, 0, 1)
        t.NotificationShadowColor = t.PopupShadowColor or Color3.fromRGB(0, 0, 0)
        t.NotificationHeaderColor = t.TitleTextColor or t.PopupTextColor or Color3.fromRGB(255, 255, 255)
        t.NotificationHeaderTransparency = 0.2
        t.NotificationTextColor = t.SecondaryTextColor or t.PopupTextColor or Color3.fromRGB(226, 232, 240)
        t.NotificationTextTransparency = 0.4
        t.NotificationDividerColor = t.TertiaryColor or Color3.fromRGB(148, 163, 184)
        t.NotificationDividerTransparency = 0.7
        t.NotificationDismissColor = t.SecondaryTextColor or Color3.fromRGB(203, 213, 225)
        t.NotificationActionButtonColor = t.InputBackgroundColor or t.PopupNeutralColor or Color3.fromRGB(51, 65, 85)
        t.NotificationActionButtonTextColor = t.PopupTextColor or Color3.fromRGB(241, 245, 249)
        t.NotificationAlertAccent = Color3.fromRGB(249, 115, 22)
        t.NotificationErrorAccent = Color3.fromRGB(226, 42, 42)
        t.NotificationVariableAccent = t.PrimaryColor or Color3.fromRGB(74, 200, 120)
    end
end

return ThemeDefinitions