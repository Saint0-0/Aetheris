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

-- Helper to create Color3 from RGB if needed
-- Default: the original Aetheris near-black look (matches the original UI at
-- StarterGui.MainTemplate.Window): near-black window @ 0.1, dark sidebar,
-- white strokes/icons, deep blue accents.
ThemeDefinitions.Default = {
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
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0.98,
    SectionStrokeTransparency = 0.95,
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
    NotificationAlertAccent = Color3.fromRGB(219, 153, 10),
    NotificationErrorAccent = Color3.fromRGB(220, 70, 60),
    NotificationVariableAccent = Color3.fromRGB(74, 200, 120),

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Black: OLED true-black. Near-black surfaces with a bright blue accent.
ThemeDefinitions.Black = {
    -- Window
    WindowColor = Color3.fromRGB(3, 3, 4),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(3, 3, 4),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(9, 9, 11),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(9, 9, 11),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(24, 24, 27),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(39, 39, 42),
    StrokeTransparency = 0.4,
    PrimaryColor = Color3.fromRGB(59, 130, 246),
    SecondaryColor = Color3.fromRGB(63, 63, 70),
    TertiaryColor = Color3.fromRGB(113, 113, 122),
    Undercolor = Color3.fromRGB(39, 39, 42),
    AccentColor = Color3.fromRGB(96, 165, 250),

    -- Text
    PrimaryTextColor = Color3.fromRGB(250, 250, 250),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(161, 161, 170),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(161, 161, 170),
    InactiveTabIconColor = Color3.fromRGB(161, 161, 170),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(59, 130, 246),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(9, 9, 11),
    InactiveTabButtonTransparency = 0,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(9, 9, 11),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(39, 39, 42),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(24, 24, 27),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(9, 9, 11),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(24, 24, 27),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(250, 250, 250),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Light: modern high-contrast light (Tailwind slate-inspired).
-- Light gray canvas, white cards, soft visible borders, blue accent,
-- neutral gray toggle track, fully opaque (no haze).
ThemeDefinitions.Light = {
    -- Window
    WindowColor = Color3.fromRGB(241, 245, 249),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(241, 245, 249),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(148, 163, 184),

    -- Sidebar
    SidebarColor = Color3.fromRGB(248, 250, 252),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(248, 250, 252),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(203, 213, 225),
    StrokeColor = Color3.fromRGB(203, 213, 225),
    StrokeTransparency = 0,
    PrimaryColor = Color3.fromRGB(37, 99, 235),
    SecondaryColor = Color3.fromRGB(148, 163, 184),
    TertiaryColor = Color3.fromRGB(100, 116, 139),
    Undercolor = Color3.fromRGB(226, 232, 240),
    AccentColor = Color3.fromRGB(37, 99, 235),

    -- Text
    PrimaryTextColor = Color3.fromRGB(15, 23, 42),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(71, 85, 105),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(15, 23, 42),
    InactiveTabTextColor = Color3.fromRGB(100, 116, 139),
    InactiveTabIconColor = Color3.fromRGB(100, 116, 139),
    ActiveTabTextColor = Color3.fromRGB(15, 23, 42),
    ActiveTabIconColor = Color3.fromRGB(15, 23, 42),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.2,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(248, 250, 252),
    InactiveTabButtonTransparency = 0,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(226, 232, 240),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(241, 245, 249),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(255, 255, 255),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(241, 245, 249),
    PopupShadowColor = Color3.fromRGB(148, 163, 184),
    PopupTextColor = Color3.fromRGB(15, 23, 42),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Midnight: deep indigo dark with a violet accent.
ThemeDefinitions.Midnight = {
    -- Window
    WindowColor = Color3.fromRGB(17, 17, 27),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(17, 17, 27),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(27, 27, 41),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(27, 27, 41),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(39, 39, 58),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(55, 55, 78),
    StrokeTransparency = 0.4,
    PrimaryColor = Color3.fromRGB(129, 140, 248),
    SecondaryColor = Color3.fromRGB(71, 85, 105),
    TertiaryColor = Color3.fromRGB(113, 113, 122),
    Undercolor = Color3.fromRGB(55, 55, 78),
    AccentColor = Color3.fromRGB(167, 139, 250),

    -- Text
    PrimaryTextColor = Color3.fromRGB(238, 238, 245),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(161, 161, 178),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(161, 161, 178),
    InactiveTabIconColor = Color3.fromRGB(161, 161, 178),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(129, 140, 248),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(27, 27, 41),
    InactiveTabButtonTransparency = 0,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(27, 27, 41),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(55, 55, 78),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(39, 39, 58),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(27, 27, 41),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(39, 39, 58),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(238, 238, 245),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Graphite: cool gray dark with a teal accent.
ThemeDefinitions.Graphite = {
    -- Window
    WindowColor = Color3.fromRGB(24, 26, 30),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(24, 26, 30),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(33, 36, 41),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(33, 36, 41),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(45, 49, 56),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(55, 61, 69),
    StrokeTransparency = 0.4,
    PrimaryColor = Color3.fromRGB(45, 212, 191),
    SecondaryColor = Color3.fromRGB(71, 85, 105),
    TertiaryColor = Color3.fromRGB(113, 122, 135),
    Undercolor = Color3.fromRGB(55, 61, 69),
    AccentColor = Color3.fromRGB(56, 189, 248),

    -- Text
    PrimaryTextColor = Color3.fromRGB(229, 231, 235),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(156, 163, 175),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(156, 163, 175),
    InactiveTabIconColor = Color3.fromRGB(156, 163, 175),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(45, 212, 191),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(33, 36, 41),
    InactiveTabButtonTransparency = 0,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(33, 36, 41),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(55, 61, 69),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(45, 49, 56),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(33, 36, 41),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(45, 49, 56),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(229, 231, 235),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Pearl: warm light (stone) with an indigo primary and violet accent.
ThemeDefinitions.Pearl = {
    -- Window
    WindowColor = Color3.fromRGB(250, 249, 247),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(250, 249, 247),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(180, 170, 160),

    -- Sidebar
    SidebarColor = Color3.fromRGB(245, 243, 240),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(246, 244, 241),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(214, 211, 209),
    StrokeColor = Color3.fromRGB(231, 229, 228),
    StrokeTransparency = 0,
    PrimaryColor = Color3.fromRGB(99, 102, 241),
    SecondaryColor = Color3.fromRGB(168, 162, 158),
    TertiaryColor = Color3.fromRGB(120, 113, 108),
    Undercolor = Color3.fromRGB(231, 229, 228),
    AccentColor = Color3.fromRGB(124, 58, 237),

    -- Text
    PrimaryTextColor = Color3.fromRGB(28, 25, 23),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(87, 83, 78),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(28, 25, 23),
    InactiveTabTextColor = Color3.fromRGB(120, 113, 108),
    InactiveTabIconColor = Color3.fromRGB(120, 113, 108),
    ActiveTabTextColor = Color3.fromRGB(28, 25, 23),
    ActiveTabIconColor = Color3.fromRGB(28, 25, 23),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.2,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(245, 243, 240),
    InactiveTabButtonTransparency = 0,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(231, 229, 228),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(246, 244, 241),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(255, 255, 255),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(245, 243, 240),
    PopupShadowColor = Color3.fromRGB(180, 170, 160),
    PopupTextColor = Color3.fromRGB(28, 25, 23),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Slate: cool light gray with an emerald primary and teal accent.
ThemeDefinitions.Slate = {
    -- Window
    WindowColor = Color3.fromRGB(248, 250, 252),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(248, 250, 252),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(148, 163, 184),

    -- Sidebar
    SidebarColor = Color3.fromRGB(241, 245, 249),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(241, 245, 249),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(203, 213, 225),
    StrokeColor = Color3.fromRGB(226, 232, 240),
    StrokeTransparency = 0,
    PrimaryColor = Color3.fromRGB(16, 185, 129),
    SecondaryColor = Color3.fromRGB(148, 163, 184),
    TertiaryColor = Color3.fromRGB(100, 116, 139),
    Undercolor = Color3.fromRGB(226, 232, 240),
    AccentColor = Color3.fromRGB(20, 184, 166),

    -- Text
    PrimaryTextColor = Color3.fromRGB(15, 23, 42),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(71, 85, 105),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(15, 23, 42),
    InactiveTabTextColor = Color3.fromRGB(100, 116, 139),
    InactiveTabIconColor = Color3.fromRGB(100, 116, 139),
    ActiveTabTextColor = Color3.fromRGB(15, 23, 42),
    ActiveTabIconColor = Color3.fromRGB(15, 23, 42),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.2,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(241, 245, 249),
    InactiveTabButtonTransparency = 0,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(226, 232, 240),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(241, 245, 249),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(255, 255, 255),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(241, 245, 249),
    PopupShadowColor = Color3.fromRGB(148, 163, 184),
    PopupTextColor = Color3.fromRGB(15, 23, 42),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Ocean: deep navy dark with a bright sky primary and cyan accent.
ThemeDefinitions.Ocean = {
    -- Window
    WindowColor = Color3.fromRGB(8, 15, 26),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(8, 15, 26),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(15, 25, 41),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(15, 25, 41),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(26, 40, 61),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(35, 53, 79),
    StrokeTransparency = 0.4,
    PrimaryColor = Color3.fromRGB(56, 189, 248),
    SecondaryColor = Color3.fromRGB(71, 85, 105),
    TertiaryColor = Color3.fromRGB(100, 116, 139),
    Undercolor = Color3.fromRGB(35, 53, 79),
    AccentColor = Color3.fromRGB(34, 211, 238),

    -- Text
    PrimaryTextColor = Color3.fromRGB(226, 240, 253),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(148, 173, 199),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(148, 173, 199),
    InactiveTabIconColor = Color3.fromRGB(148, 173, 199),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(56, 189, 248),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(15, 25, 41),
    InactiveTabButtonTransparency = 0,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(15, 25, 41),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(35, 53, 79),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(26, 40, 61),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(15, 25, 41),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(26, 40, 61),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(226, 240, 253),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Nord: arctic blue-gray dark (Nord palette), frost primary, aurora accent.
ThemeDefinitions.Nord = {
    -- Window
    WindowColor = Color3.fromRGB(46, 52, 64),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(46, 52, 64),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(59, 66, 82),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(59, 66, 82),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(67, 76, 94),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(76, 86, 106),
    StrokeTransparency = 0.4,
    PrimaryColor = Color3.fromRGB(136, 192, 208),
    SecondaryColor = Color3.fromRGB(76, 86, 106),
    TertiaryColor = Color3.fromRGB(129, 161, 193),
    Undercolor = Color3.fromRGB(67, 76, 94),
    AccentColor = Color3.fromRGB(94, 129, 172),

    -- Text
    PrimaryTextColor = Color3.fromRGB(236, 239, 244),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(180, 190, 205),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(236, 239, 244),
    InactiveTabTextColor = Color3.fromRGB(180, 190, 205),
    InactiveTabIconColor = Color3.fromRGB(180, 190, 205),
    ActiveTabTextColor = Color3.fromRGB(236, 239, 244),
    ActiveTabIconColor = Color3.fromRGB(236, 239, 244),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(136, 192, 208),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(59, 66, 82),
    InactiveTabButtonTransparency = 0,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(59, 66, 82),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(76, 86, 106),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(67, 76, 94),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(59, 66, 82),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(67, 76, 94),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(236, 239, 244),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Forest: deep green dark with an emerald primary and lime accent.
ThemeDefinitions.Forest = {
    -- Window
    WindowColor = Color3.fromRGB(11, 20, 16),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(11, 20, 16),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(18, 31, 26),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(18, 31, 26),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(28, 45, 38),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(37, 58, 49),
    StrokeTransparency = 0.4,
    PrimaryColor = Color3.fromRGB(52, 211, 153),
    SecondaryColor = Color3.fromRGB(71, 85, 105),
    TertiaryColor = Color3.fromRGB(107, 128, 120),
    Undercolor = Color3.fromRGB(37, 58, 49),
    AccentColor = Color3.fromRGB(163, 230, 53),

    -- Text
    PrimaryTextColor = Color3.fromRGB(226, 245, 236),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(148, 173, 162),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(148, 173, 162),
    InactiveTabIconColor = Color3.fromRGB(148, 173, 162),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(52, 211, 153),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(18, 31, 26),
    InactiveTabButtonTransparency = 0,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(18, 31, 26),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(37, 58, 49),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(28, 45, 38),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(18, 31, 26),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(28, 45, 38),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(226, 245, 236),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Rose: dark plum with a pink primary and magenta accent.
ThemeDefinitions.Rose = {
    -- Window
    WindowColor = Color3.fromRGB(24, 15, 22),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(24, 15, 22),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(38, 24, 35),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(38, 24, 35),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(55, 36, 51),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(68, 45, 63),
    StrokeTransparency = 0.4,
    PrimaryColor = Color3.fromRGB(244, 114, 182),
    SecondaryColor = Color3.fromRGB(71, 85, 105),
    TertiaryColor = Color3.fromRGB(130, 108, 122),
    Undercolor = Color3.fromRGB(68, 45, 63),
    AccentColor = Color3.fromRGB(217, 70, 239),

    -- Text
    PrimaryTextColor = Color3.fromRGB(250, 240, 246),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(178, 156, 171),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(178, 156, 171),
    InactiveTabIconColor = Color3.fromRGB(178, 156, 171),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(244, 114, 182),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(38, 24, 35),
    InactiveTabButtonTransparency = 0,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(38, 24, 35),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(68, 45, 63),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(55, 36, 51),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(38, 24, 35),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(55, 36, 51),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(250, 240, 246),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Amethyst: deep purple dark with a violet primary and fuchsia accent.
ThemeDefinitions.Amethyst = {
    -- Window
    WindowColor = Color3.fromRGB(20, 16, 32),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(20, 16, 32),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(31, 26, 48),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(31, 26, 48),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(44, 38, 66),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(57, 49, 84),
    StrokeTransparency = 0.4,
    PrimaryColor = Color3.fromRGB(167, 139, 250),
    SecondaryColor = Color3.fromRGB(71, 85, 105),
    TertiaryColor = Color3.fromRGB(126, 122, 148),
    Undercolor = Color3.fromRGB(57, 49, 84),
    AccentColor = Color3.fromRGB(232, 121, 249),

    -- Text
    PrimaryTextColor = Color3.fromRGB(240, 238, 250),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(165, 160, 190),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(165, 160, 190),
    InactiveTabIconColor = Color3.fromRGB(165, 160, 190),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(167, 139, 250),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(31, 26, 48),
    InactiveTabButtonTransparency = 0,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(31, 26, 48),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(57, 49, 84),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(44, 38, 66),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(31, 26, 48),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(44, 38, 66),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(240, 238, 250),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Retro: warm 70s cream/tan light with a burnt-orange primary and teal accent.
ThemeDefinitions.Retro = {
    -- Window
    WindowColor = Color3.fromRGB(240, 230, 211),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(240, 230, 211),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(150, 120, 90),

    -- Sidebar
    SidebarColor = Color3.fromRGB(232, 220, 198),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(250, 243, 228),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(232, 220, 198),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(201, 178, 145),
    StrokeColor = Color3.fromRGB(214, 190, 156),
    StrokeTransparency = 0,
    PrimaryColor = Color3.fromRGB(217, 119, 6),
    SecondaryColor = Color3.fromRGB(168, 152, 128),
    TertiaryColor = Color3.fromRGB(146, 116, 84),
    Undercolor = Color3.fromRGB(224, 208, 180),
    AccentColor = Color3.fromRGB(15, 118, 110),

    -- Text
    PrimaryTextColor = Color3.fromRGB(60, 42, 26),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(120, 96, 70),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(60, 42, 26),
    InactiveTabTextColor = Color3.fromRGB(146, 116, 84),
    InactiveTabIconColor = Color3.fromRGB(146, 116, 84),
    ActiveTabTextColor = Color3.fromRGB(60, 42, 26),
    ActiveTabIconColor = Color3.fromRGB(60, 42, 26),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.2,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(250, 243, 228),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(232, 220, 198),
    InactiveTabButtonTransparency = 0,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(250, 243, 228),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(214, 190, 156),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(232, 220, 198),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(250, 243, 228),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(232, 220, 198),
    PopupShadowColor = Color3.fromRGB(150, 120, 90),
    PopupTextColor = Color3.fromRGB(60, 42, 26),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Glass: frosted dark. Translucent window + sidebar, semi-opaque content
-- fill so text stays readable over the game. Shows off the ContentBackground
-- layer (window can be see-through while content keeps its own opacity).
ThemeDefinitions.Glass = {
    -- Window
    WindowColor = Color3.fromRGB(20, 24, 33),
    WindowTransparency = 0.35,
    ContentBackgroundColor = Color3.fromRGB(20, 24, 33),
    ContentBackgroundTransparency = 0.15,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(28, 33, 45),
    SidebarTransparency = 0.45,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(38, 45, 60),
    ComponentBackgroundTransparency = 0.25,
    InputBackgroundColor = Color3.fromRGB(48, 56, 74),
    InputBackgroundTransparency = 0.2,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(120, 140, 170),
    StrokeTransparency = 0.6,
    PrimaryColor = Color3.fromRGB(96, 165, 250),
    SecondaryColor = Color3.fromRGB(100, 116, 139),
    TertiaryColor = Color3.fromRGB(148, 163, 184),
    Undercolor = Color3.fromRGB(71, 85, 105),
    AccentColor = Color3.fromRGB(56, 189, 248),

    -- Text
    PrimaryTextColor = Color3.fromRGB(241, 245, 249),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(203, 213, 225),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(203, 213, 225),
    InactiveTabIconColor = Color3.fromRGB(203, 213, 225),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(96, 165, 250),
    ActiveTabButtonTransparency = 0.1,
    InactiveTabButtonColor = Color3.fromRGB(28, 33, 45),
    InactiveTabButtonTransparency = 0.6,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(38, 45, 60),
    SectionBackgroundTransparency = 0.35,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(100, 116, 139),
    SectionDividerTransparency = 0.4,
    SearchBarBackgroundColor = Color3.fromRGB(48, 56, 74),
    SearchBarBackgroundTransparency = 0.2,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(28, 33, 45),
    PopupBackgroundTransparency = 0.05,
    PopupNeutralColor = Color3.fromRGB(48, 56, 74),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(241, 245, 249),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Porcelain: light theme with a translucent sidebar over an opaque, crisp
-- content area. Demonstrates a see-through sidebar while keeping content solid.
ThemeDefinitions.Porcelain = {
    -- Window
    WindowColor = Color3.fromRGB(245, 247, 250),
    WindowTransparency = 0.2,
    ContentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(148, 163, 184),

    -- Sidebar
    SidebarColor = Color3.fromRGB(226, 232, 240),
    SidebarTransparency = 0.5,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(248, 250, 252),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(203, 213, 225),
    StrokeColor = Color3.fromRGB(203, 213, 225),
    StrokeTransparency = 0,
    PrimaryColor = Color3.fromRGB(14, 165, 233),
    SecondaryColor = Color3.fromRGB(148, 163, 184),
    TertiaryColor = Color3.fromRGB(100, 116, 139),
    Undercolor = Color3.fromRGB(226, 232, 240),
    AccentColor = Color3.fromRGB(14, 165, 233),

    -- Text
    PrimaryTextColor = Color3.fromRGB(15, 23, 42),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(71, 85, 105),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(15, 23, 42),
    InactiveTabTextColor = Color3.fromRGB(100, 116, 139),
    InactiveTabIconColor = Color3.fromRGB(100, 116, 139),
    ActiveTabTextColor = Color3.fromRGB(15, 23, 42),
    ActiveTabIconColor = Color3.fromRGB(15, 23, 42),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.2,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(226, 232, 240),
    InactiveTabButtonTransparency = 0.4,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(226, 232, 240),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(248, 250, 252),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(255, 255, 255),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(241, 245, 249),
    PopupShadowColor = Color3.fromRGB(148, 163, 184),
    PopupTextColor = Color3.fromRGB(15, 23, 42),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Mist: cool light theme, translucent frosted sidebar over solid white content.
ThemeDefinitions.Mist = {
    -- Window
    WindowColor = Color3.fromRGB(226, 232, 240),
    WindowTransparency = 0.35,
    ContentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ContentBackgroundTransparency = 0,
    WindowControlColor = Color3.fromRGB(71, 85, 105),
    MainframeShadowColor = Color3.fromRGB(148, 163, 184),

    -- Sidebar
    SidebarColor = Color3.fromRGB(203, 213, 225),
    SidebarTransparency = 0.5,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(248, 250, 252),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(203, 213, 225),
    StrokeColor = Color3.fromRGB(203, 213, 225),
    StrokeTransparency = 0,
    PrimaryColor = Color3.fromRGB(99, 102, 241),
    SecondaryColor = Color3.fromRGB(148, 163, 184),
    TertiaryColor = Color3.fromRGB(100, 116, 139),
    Undercolor = Color3.fromRGB(226, 232, 240),
    AccentColor = Color3.fromRGB(14, 165, 233),

    -- Text
    PrimaryTextColor = Color3.fromRGB(15, 23, 42),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(71, 85, 105),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(15, 23, 42),
    InactiveTabTextColor = Color3.fromRGB(100, 116, 139),
    InactiveTabIconColor = Color3.fromRGB(100, 116, 139),
    ActiveTabTextColor = Color3.fromRGB(15, 23, 42),
    ActiveTabIconColor = Color3.fromRGB(15, 23, 42),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.2,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(226, 232, 240),
    InactiveTabButtonTransparency = 0.35,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(226, 232, 240),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(248, 250, 252),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(255, 255, 255),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(241, 245, 249),
    PopupShadowColor = Color3.fromRGB(148, 163, 184),
    PopupTextColor = Color3.fromRGB(15, 23, 42),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Dusk: warm dark theme, translucent plum sidebar over solid content.
ThemeDefinitions.Dusk = {
    -- Window
    WindowColor = Color3.fromRGB(30, 22, 38),
    WindowTransparency = 0.3,
    ContentBackgroundColor = Color3.fromRGB(26, 19, 34),
    ContentBackgroundTransparency = 0,
    WindowControlColor = Color3.fromRGB(196, 181, 212),
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(44, 33, 55),
    SidebarTransparency = 0.45,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(38, 28, 48),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(52, 39, 65),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(70, 54, 88),
    StrokeTransparency = 0.4,
    PrimaryColor = Color3.fromRGB(192, 132, 252),
    SecondaryColor = Color3.fromRGB(71, 85, 105),
    TertiaryColor = Color3.fromRGB(148, 138, 168),
    Undercolor = Color3.fromRGB(70, 54, 88),
    AccentColor = Color3.fromRGB(244, 114, 182),

    -- Text
    PrimaryTextColor = Color3.fromRGB(245, 240, 250),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(190, 176, 205),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(190, 176, 205),
    InactiveTabIconColor = Color3.fromRGB(190, 176, 205),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(192, 132, 252),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(44, 33, 55),
    InactiveTabButtonTransparency = 0.35,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(38, 28, 48),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(70, 54, 88),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(52, 39, 65),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(38, 28, 48),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(52, 39, 65),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(245, 240, 250),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Frost: deep blue-gray dark, translucent glass sidebar over solid content.
ThemeDefinitions.Frost = {
    -- Window
    WindowColor = Color3.fromRGB(24, 32, 44),
    WindowTransparency = 0.3,
    ContentBackgroundColor = Color3.fromRGB(20, 27, 38),
    ContentBackgroundTransparency = 0,
    WindowControlColor = Color3.fromRGB(148, 190, 220),
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(37, 49, 66),
    SidebarTransparency = 0.45,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(30, 40, 54),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(43, 56, 74),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(56, 72, 94),
    StrokeTransparency = 0.4,
    PrimaryColor = Color3.fromRGB(125, 211, 252),
    SecondaryColor = Color3.fromRGB(71, 85, 105),
    TertiaryColor = Color3.fromRGB(148, 163, 184),
    Undercolor = Color3.fromRGB(56, 72, 94),
    AccentColor = Color3.fromRGB(45, 212, 191),

    -- Text
    PrimaryTextColor = Color3.fromRGB(226, 240, 253),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(160, 180, 200),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(160, 180, 200),
    InactiveTabIconColor = Color3.fromRGB(160, 180, 200),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(125, 211, 252),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(37, 49, 66),
    InactiveTabButtonTransparency = 0.35,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(30, 40, 54),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(56, 72, 94),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(43, 56, 74),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(30, 40, 54),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(43, 56, 74),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(226, 240, 253),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Sandstone: warm neutral light, translucent tan sidebar over solid content.
ThemeDefinitions.Sandstone = {
    -- Window
    WindowColor = Color3.fromRGB(233, 224, 209),
    WindowTransparency = 0.3,
    ContentBackgroundColor = Color3.fromRGB(252, 248, 240),
    ContentBackgroundTransparency = 0,
    WindowControlColor = Color3.fromRGB(120, 96, 70),
    MainframeShadowColor = Color3.fromRGB(180, 170, 160),

    -- Sidebar
    SidebarColor = Color3.fromRGB(216, 202, 180),
    SidebarTransparency = 0.45,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 252, 246),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(246, 240, 230),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(214, 205, 190),
    StrokeColor = Color3.fromRGB(224, 214, 196),
    StrokeTransparency = 0,
    PrimaryColor = Color3.fromRGB(180, 83, 9),
    SecondaryColor = Color3.fromRGB(168, 162, 158),
    TertiaryColor = Color3.fromRGB(146, 116, 84),
    Undercolor = Color3.fromRGB(228, 220, 205),
    AccentColor = Color3.fromRGB(15, 118, 110),

    -- Text
    PrimaryTextColor = Color3.fromRGB(60, 42, 26),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(120, 96, 70),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(60, 42, 26),
    InactiveTabTextColor = Color3.fromRGB(146, 116, 84),
    InactiveTabIconColor = Color3.fromRGB(146, 116, 84),
    ActiveTabTextColor = Color3.fromRGB(60, 42, 26),
    ActiveTabIconColor = Color3.fromRGB(60, 42, 26),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.2,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(255, 252, 246),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(216, 202, 180),
    InactiveTabButtonTransparency = 0.35,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 252, 246),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(224, 214, 196),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(246, 240, 230),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(255, 252, 246),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(246, 240, 230),
    PopupShadowColor = Color3.fromRGB(180, 170, 160),
    PopupTextColor = Color3.fromRGB(60, 42, 26),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Azure: deep cool blue dark with a sky/blue accent (mountain wallpaper).
ThemeDefinitions.Azure = {
    -- Window
    WindowColor = Color3.fromRGB(10, 18, 30),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(15, 24, 40),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(17, 27, 45),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(20, 31, 50),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(30, 44, 68),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(40, 58, 86),
    StrokeTransparency = 0.4,
    PrimaryColor = Color3.fromRGB(56, 189, 248),
    SecondaryColor = Color3.fromRGB(71, 85, 105),
    TertiaryColor = Color3.fromRGB(100, 116, 139),
    Undercolor = Color3.fromRGB(40, 58, 86),
    AccentColor = Color3.fromRGB(96, 165, 250),

    -- Text
    PrimaryTextColor = Color3.fromRGB(226, 240, 253),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(148, 173, 199),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(148, 173, 199),
    InactiveTabIconColor = Color3.fromRGB(148, 173, 199),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(56, 189, 248),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(17, 27, 45),
    InactiveTabButtonTransparency = 0.35,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(20, 31, 50),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(40, 58, 86),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(30, 44, 68),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(20, 31, 50),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(30, 44, 68),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(226, 240, 253),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Blossom: soft light pink with a rose accent (pink waves wallpaper).
ThemeDefinitions.Blossom = {
    -- Window
    WindowColor = Color3.fromRGB(253, 245, 249),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(255, 250, 253),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(214, 170, 190),

    -- Sidebar
    SidebarColor = Color3.fromRGB(248, 233, 241),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(251, 242, 247),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(219, 196, 208),
    StrokeColor = Color3.fromRGB(238, 222, 231),
    StrokeTransparency = 0,
    PrimaryColor = Color3.fromRGB(236, 72, 153),
    SecondaryColor = Color3.fromRGB(168, 162, 158),
    TertiaryColor = Color3.fromRGB(150, 110, 128),
    Undercolor = Color3.fromRGB(238, 222, 231),
    AccentColor = Color3.fromRGB(219, 39, 119),

    -- Text
    PrimaryTextColor = Color3.fromRGB(60, 30, 45),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(130, 90, 110),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(60, 30, 45),
    InactiveTabTextColor = Color3.fromRGB(150, 110, 128),
    InactiveTabIconColor = Color3.fromRGB(150, 110, 128),
    ActiveTabTextColor = Color3.fromRGB(60, 30, 45),
    ActiveTabIconColor = Color3.fromRGB(60, 30, 45),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.2,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(248, 233, 241),
    InactiveTabButtonTransparency = 0.35,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(238, 222, 231),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(251, 242, 247),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(255, 255, 255),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(251, 242, 247),
    PopupShadowColor = Color3.fromRGB(214, 170, 190),
    PopupTextColor = Color3.fromRGB(60, 30, 45),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Fjord: muted blue-grey dark (soft blue/greyish-yellow mountain wallpaper).
ThemeDefinitions.Fjord = {
    -- Window
    WindowColor = Color3.fromRGB(26, 32, 44),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(32, 40, 54),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(0, 0, 0),

    -- Sidebar
    SidebarColor = Color3.fromRGB(36, 44, 58),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(36, 44, 58),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(48, 58, 74),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(0, 0, 0),
    StrokeColor = Color3.fromRGB(58, 70, 88),
    StrokeTransparency = 0.4,
    PrimaryColor = Color3.fromRGB(125, 211, 252),
    SecondaryColor = Color3.fromRGB(71, 85, 105),
    TertiaryColor = Color3.fromRGB(130, 145, 165),
    Undercolor = Color3.fromRGB(58, 70, 88),
    AccentColor = Color3.fromRGB(56, 189, 248),

    -- Text
    PrimaryTextColor = Color3.fromRGB(226, 236, 248),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(160, 175, 195),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    InactiveTabTextColor = Color3.fromRGB(160, 175, 195),
    InactiveTabIconColor = Color3.fromRGB(160, 175, 195),
    ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
    ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.3,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(125, 211, 252),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(36, 44, 58),
    InactiveTabButtonTransparency = 0.35,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(36, 44, 58),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(58, 70, 88),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(48, 58, 74),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(36, 44, 58),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(48, 58, 74),
    PopupShadowColor = Color3.fromRGB(0, 0, 0),
    PopupTextColor = Color3.fromRGB(226, 236, 248),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Summit: crisp light blue/white (blue + white mountain wallpaper).
ThemeDefinitions.Summit = {
    -- Window
    WindowColor = Color3.fromRGB(240, 246, 252),
    WindowTransparency = 0,
    ContentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ContentBackgroundTransparency = 0,
    MainframeShadowColor = Color3.fromRGB(148, 163, 184),

    -- Sidebar
    SidebarColor = Color3.fromRGB(226, 236, 248),
    SidebarTransparency = 0,

    -- Components
    ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
    ComponentBackgroundTransparency = 0,
    InputBackgroundColor = Color3.fromRGB(240, 246, 252),
    InputBackgroundTransparency = 0,
    ComponentShadowColor = Color3.fromRGB(203, 213, 225),
    StrokeColor = Color3.fromRGB(214, 226, 240),
    StrokeTransparency = 0,
    PrimaryColor = Color3.fromRGB(59, 130, 246),
    SecondaryColor = Color3.fromRGB(148, 163, 184),
    TertiaryColor = Color3.fromRGB(100, 116, 139),
    Undercolor = Color3.fromRGB(226, 236, 248),
    AccentColor = Color3.fromRGB(14, 165, 233),

    -- Text
    PrimaryTextColor = Color3.fromRGB(15, 30, 50),
    PrimaryTextTransparency = 0,
    SecondaryTextColor = Color3.fromRGB(71, 90, 115),
    SecondaryTextTransparency = 0,
    TitleTextColor = Color3.fromRGB(15, 30, 50),
    InactiveTabTextColor = Color3.fromRGB(100, 116, 139),
    InactiveTabIconColor = Color3.fromRGB(100, 116, 139),
    ActiveTabTextColor = Color3.fromRGB(15, 30, 50),
    ActiveTabIconColor = Color3.fromRGB(15, 30, 50),
    ActiveTabTextTransparency = 0,
    InactiveTabTextTransparency = 0.2,
    ActiveTabIconTransparency = 0,
    InactiveTabIconTransparency = 0.3,
    ActiveTabButtonColor = Color3.fromRGB(255, 255, 255),
    ActiveTabButtonTransparency = 0,
    InactiveTabButtonColor = Color3.fromRGB(226, 236, 248),
    InactiveTabButtonTransparency = 0.35,

    -- Section
    SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
    SectionBackgroundTransparency = 0,
    SectionStrokeTransparency = 0.985,
    SectionDividerColor = Color3.fromRGB(214, 226, 240),
    SectionDividerTransparency = 0,
    SearchBarBackgroundColor = Color3.fromRGB(240, 246, 252),
    SearchBarBackgroundTransparency = 0,

    -- Popups
    PopupBackgroundColor = Color3.fromRGB(255, 255, 255),
    PopupBackgroundTransparency = 0,
    PopupNeutralColor = Color3.fromRGB(240, 246, 252),
    PopupShadowColor = Color3.fromRGB(148, 163, 184),
    PopupTextColor = Color3.fromRGB(15, 30, 50),
    PopupTextTransparency = 0,

    -- Wallpaper
    Wallpaper = nil,
    WallpaperEnabled = true,
}

-- Wallpapers (from the MaterialService decals). Assigned per theme so each
-- keeps its character; the tab/backdrop images use these when present.
local WALLPAPERS = {
    Default   = "rbxassetid://11094025229",  -- branded Aetheris backdrop (original)
    Black     = "rbxassetid://18571374017",  -- dark purple + slight orange
    Light     = "rbxassetid://5164282825",   -- beige minimalist
    Midnight  = "rbxassetid://107868116663356", -- purple minimalist
    Graphite  = "rbxassetid://116321051235221", -- green with trees
    Pearl     = "rbxassetid://117100465436400", -- beige/orange/red
    Slate     = "rbxassetid://121017686291110", -- pale blue
    Ocean     = "rbxassetid://135568871834704", -- blue mountain range
    Nord      = "rbxassetid://121017686291110", -- pale blue
    Forest    = "rbxassetid://116321051235221", -- green with trees
    Rose      = "rbxassetid://8350591200",   -- pink minimalist
    Amethyst  = "rbxassetid://107868116663356", -- purple minimalist
    Retro     = "rbxassetid://12868775918",  -- sun orange
    Glass     = "rbxassetid://15955473206",  -- blue + slight purple
    Porcelain = "rbxassetid://121017686291110", -- pale blue
    Mist      = "rbxassetid://309321999",     -- white and black
    Dusk      = "rbxassetid://123519222162021", -- pink/orange/yellow sunset
    Frost     = "rbxassetid://84403490778114", -- blue river/ocean sunset
    Sandstone = "rbxassetid://123519222162021", -- pink/orange/yellow sunset
    Azure     = "rbxassetid://121017686291110", -- pale blue
    Blossom   = "rbxassetid://131979800493713", -- pink waves
    Fjord     = "rbxassetid://98228102412425",  -- soft blue / greyish-yellow mountain
    Summit    = "rbxassetid://123969479560901", -- blue + white mountain range
}

for name, wallpaper in pairs(WALLPAPERS) do
    if ThemeDefinitions[name] then
        ThemeDefinitions[name].Wallpaper = wallpaper
    end
end

-- Window control icon colors (close/maximize/minimize). Dark themes get light
-- icons, light themes get dark ones, so they stay visible on the window chrome.
local WINDOW_CONTROLS = {
    Default   = Color3.fromRGB(255, 255, 255),
    Black     = Color3.fromRGB(161, 161, 170),
    Light     = Color3.fromRGB(51, 65, 85),
    Midnight  = Color3.fromRGB(165, 160, 190),
    Graphite  = Color3.fromRGB(156, 163, 175),
    Pearl     = Color3.fromRGB(87, 83, 78),
    Slate     = Color3.fromRGB(71, 85, 105),
    Ocean     = Color3.fromRGB(148, 173, 199),
    Nord      = Color3.fromRGB(180, 190, 205),
    Forest    = Color3.fromRGB(148, 173, 162),
    Rose      = Color3.fromRGB(178, 156, 171),
    Amethyst  = Color3.fromRGB(165, 160, 190),
    Retro     = Color3.fromRGB(120, 96, 70),
    Glass     = Color3.fromRGB(203, 213, 225),
    Porcelain = Color3.fromRGB(71, 85, 105),
    Mist      = Color3.fromRGB(71, 85, 105),
    Sandstone = Color3.fromRGB(120, 96, 70),
    Dusk      = Color3.fromRGB(196, 181, 212),
    Frost     = Color3.fromRGB(148, 190, 220),
    Azure     = Color3.fromRGB(148, 173, 199),
    Blossom   = Color3.fromRGB(150, 110, 128),
    Fjord     = Color3.fromRGB(160, 175, 195),
    Summit    = Color3.fromRGB(71, 90, 115),
}

for name, controlColor in pairs(WINDOW_CONTROLS) do
    if ThemeDefinitions[name] then
        ThemeDefinitions[name].WindowControlColor = controlColor
    end
end

-- Per-theme transparency. Most themes use a translucent sidebar over an opaque
-- content area; a few invert it (translucent content, opaque sidebar). Only
-- Black and Nord are fully opaque. { WindowTransparency, SidebarTransparency,
-- ContentBackgroundTransparency }.
local THEME_TRANSPARENCY = {
    -- Fully opaque, solid chrome (window + sidebar + content all solid).
    Black     = { 0,    0,    0    },
    Nord      = { 0,    0,    0    },

    -- Default: near-black window, frosted-glass sidebar, near-solid content.
    Default   = { 0.15, 0.65, 0.1  },

    -- Translucent SIDEBAR over an opaque content area (the classic frosted
    -- sidebar look). Sidebar transparency raised from 0.45 -> 0.6/0.65 so it
    -- reads as genuinely see-through instead of merely tinted.
    Light     = { 0.2,  0.6,  0    },
    Midnight  = { 0.2,  0.6,  0    },
    Graphite  = { 0.2,  0.6,  0    },
    Pearl     = { 0.2,  0.6,  0    },
    Slate     = { 0.2,  0.6,  0    },
    Forest    = { 0.2,  0.6,  0    },
    Amethyst  = { 0.2,  0.65, 0    },
    Rose      = { 0.2,  0.6,  0    },
    Retro     = { 0.2,  0.6,  0    },
    Azure     = { 0.2,  0.6,  0    },
    Blossom   = { 0.2,  0.6,  0    },
    Fjord     = { 0.2,  0.6,  0    },
    Summit    = { 0.2,  0.6,  0    },

    -- Translucent CONTENT over an opaque sidebar (content floats above the
    -- wallpaper while the sidebar stays solid for readability).
    Ocean     = { 0.3,  0,    0.45 },
    Mist      = { 0.3,  0,    0.45 },
    Sandstone = { 0.3,  0,    0.45 },
    Dusk      = { 0.3,  0,    0.45 },
    Frost     = { 0.3,  0,    0.45 },

    -- Full glass: both sidebar and content are strongly translucent.
    Glass     = { 0.45, 0.7,  0.4  },
    Porcelain = { 0.3,  0.6,  0    },
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
        t.NotificationAlertAccent = Color3.fromRGB(219, 153, 10)
        t.NotificationErrorAccent = Color3.fromRGB(220, 70, 60)
        t.NotificationVariableAccent = t.PrimaryColor or Color3.fromRGB(74, 200, 120)
    end
end

return ThemeDefinitions