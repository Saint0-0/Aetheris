--[[
	Aetheris/Themes/ThemeDefinitions.luau

	Defines the merge base plus every named theme, then layers on wallpaper ids,
	window-control colors, per-theme transparency and derived surfaces. Any key a
	given theme omits falls back to Base.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeDefinitions = {}

-- Base is the merge fallback for every theme; ThemeManager.DefaultTheme is the
-- launch theme.
ThemeDefinitions.Base = {
	WindowColor = Color3.fromRGB(15, 15, 16),
	WindowTransparency = 0.1,
	WindowControlColor = Color3.fromRGB(255, 255, 255),
	ContentBackgroundColor = Color3.fromRGB(15, 15, 16),
	ContentBackgroundTransparency = 1,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(20, 20, 20),
	SidebarTransparency = 1,

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

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.98,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.985,
	SectionDividerColor = Color3.fromRGB(255, 255, 255),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(26, 30, 255),
	SearchBarBackgroundTransparency = 1,

	PopupBackgroundColor = Color3.fromRGB(15, 15, 16),
	PopupBackgroundTransparency = 0.07,
	PopupNeutralColor = Color3.fromRGB(46, 46, 46),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(255, 255, 255),
	PopupTextTransparency = 0.2,

	NotificationBackgroundColor = Color3.fromRGB(30, 41, 59),
	NotificationBackgroundTransparency = 0.1,
	NotificationShadowColor = Color3.fromRGB(0, 0, 0),
	NotificationStrokeColor = Color3.fromRGB(148, 163, 184),
	NotificationStrokeTransparency = 0.86,
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
	-- Aurora wash colours: tinted further toward the accent than the accents so they match the theme.
	NotificationAlertAurora = Color3.fromRGB(249, 115, 22),
	NotificationErrorAurora = Color3.fromRGB(226, 42, 42),

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Umbral: true navy. Near-black blue chrome with a saturated steel-blue
-- accent, the darkest and most saturated blue in the roster.
ThemeDefinitions.Umbral = {
	WindowColor = Color3.fromRGB(13, 15, 21),
	WindowTransparency = 0.15,
	ContentBackgroundColor = Color3.fromRGB(15, 17, 24),
	ContentBackgroundTransparency = 0.1,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(19, 22, 31),
	SidebarTransparency = 0.72,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(26, 30, 42),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(76, 110, 180),
	SecondaryColor = Color3.fromRGB(48, 66, 104),
	TertiaryColor = Color3.fromRGB(126, 142, 172),
	Undercolor = Color3.fromRGB(30, 36, 50),
	AccentColor = Color3.fromRGB(118, 152, 214),

	PrimaryTextColor = Color3.fromRGB(236, 241, 250),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(174, 186, 206),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(255, 255, 255),
	InactiveTabTextColor = Color3.fromRGB(174, 186, 206),
	InactiveTabIconColor = Color3.fromRGB(174, 186, 206),
	ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
	ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(214, 228, 248),
	ActiveTabButtonTransparency = 0.99,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(255, 255, 255),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(26, 30, 42),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(17, 19, 27),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(40, 47, 63),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(238, 243, 252),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Ember: cool slate with vivid lava. Slate-blue-black chrome makes the
-- molten orange accent pop like lava falls against a night cliff.
ThemeDefinitions.Ember = {
	WindowColor = Color3.fromRGB(15, 17, 23),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(17, 19, 25),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(21, 24, 32),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(30, 34, 44),
	InputBackgroundTransparency = 0.1,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(255, 96, 36),
	SecondaryColor = Color3.fromRGB(122, 58, 34),
	TertiaryColor = Color3.fromRGB(142, 154, 176),
	Undercolor = Color3.fromRGB(38, 44, 58),
	AccentColor = Color3.fromRGB(255, 146, 64),

	PrimaryTextColor = Color3.fromRGB(240, 243, 248),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(176, 186, 204),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(255, 255, 255),
	InactiveTabTextColor = Color3.fromRGB(176, 186, 204),
	InactiveTabIconColor = Color3.fromRGB(176, 186, 204),
	ActiveTabTextColor = Color3.fromRGB(255, 255, 255),
	ActiveTabIconColor = Color3.fromRGB(255, 255, 255),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(255, 146, 64),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(142, 154, 176),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(30, 34, 44),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(19, 22, 28),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(44, 52, 68),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(242, 245, 250),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Vesper: violet dusk. Deep indigo-violet chrome with translucent content
-- floating over the wallpaper and a solid sidebar to keep nav legible.
ThemeDefinitions.Vesper = {
	WindowColor = Color3.fromRGB(20, 16, 30),
	WindowTransparency = 0.28,
	ContentBackgroundColor = Color3.fromRGB(22, 18, 34),
	ContentBackgroundTransparency = 0.42,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(26, 22, 38),
	SidebarTransparency = 0,

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

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(255, 255, 255),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(38, 32, 54),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(24, 20, 36),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(54, 46, 76),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(242, 240, 252),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Duskfall: coral-red sky with a gold sun over plum hills. Plum-dark chrome,
-- a plum-berry primary drawn from the hills, and a warm gold sun accent.
ThemeDefinitions.Duskfall = {
	WindowColor = Color3.fromRGB(24, 17, 24),
	WindowTransparency = 0.28,
	ContentBackgroundColor = Color3.fromRGB(28, 20, 28),
	ContentBackgroundTransparency = 0.42,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(30, 21, 30),
	SidebarTransparency = 0,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(42, 29, 42),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(190, 80, 128),
	SecondaryColor = Color3.fromRGB(126, 74, 110),
	TertiaryColor = Color3.fromRGB(188, 144, 152),
	Undercolor = Color3.fromRGB(48, 32, 46),
	AccentColor = Color3.fromRGB(246, 178, 60),

	PrimaryTextColor = Color3.fromRGB(250, 242, 234),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(214, 192, 184),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(255, 250, 242),
	InactiveTabTextColor = Color3.fromRGB(214, 192, 184),
	InactiveTabIconColor = Color3.fromRGB(214, 192, 184),
	ActiveTabTextColor = Color3.fromRGB(255, 250, 242),
	ActiveTabIconColor = Color3.fromRGB(255, 238, 214),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(246, 178, 60),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(255, 255, 255),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(42, 29, 42),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(28, 20, 28),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(58, 40, 56),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(250, 242, 238),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Canopy: pale mint mist over piny woods; a dark theme carrying a light-value
-- mint-green lane. Forest-dark chrome with sage-green secondaries.
ThemeDefinitions.Canopy = {
	WindowColor = Color3.fromRGB(14, 21, 18),
	WindowTransparency = 0.28,
	ContentBackgroundColor = Color3.fromRGB(17, 26, 21),
	ContentBackgroundTransparency = 0.42,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(19, 30, 24),
	SidebarTransparency = 0,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(26, 41, 32),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(96, 214, 156),
	SecondaryColor = Color3.fromRGB(54, 106, 84),
	TertiaryColor = Color3.fromRGB(140, 190, 164),
	Undercolor = Color3.fromRGB(28, 46, 37),
	AccentColor = Color3.fromRGB(150, 230, 190),

	PrimaryTextColor = Color3.fromRGB(238, 247, 241),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(184, 208, 194),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(250, 255, 252),
	InactiveTabTextColor = Color3.fromRGB(184, 208, 194),
	InactiveTabIconColor = Color3.fromRGB(184, 208, 194),
	ActiveTabTextColor = Color3.fromRGB(250, 255, 252),
	ActiveTabIconColor = Color3.fromRGB(234, 252, 240),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(150, 230, 190),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(255, 255, 255),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(26, 41, 32),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(17, 26, 21),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(42, 60, 50),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(240, 249, 243),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Tidewater: dark teal lake with mountain reflection. Desaturated teal chrome
-- with a cool mint-teal accent, deliberately kept away from bright cyan.
ThemeDefinitions.Tidewater = {
	WindowColor = Color3.fromRGB(13, 21, 23),
	WindowTransparency = 0.28,
	ContentBackgroundColor = Color3.fromRGB(16, 26, 27),
	ContentBackgroundTransparency = 0.42,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(18, 31, 30),
	SidebarTransparency = 0,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(24, 41, 40),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(40, 162, 152),
	SecondaryColor = Color3.fromRGB(36, 94, 92),
	TertiaryColor = Color3.fromRGB(126, 176, 174),
	Undercolor = Color3.fromRGB(26, 45, 44),
	AccentColor = Color3.fromRGB(92, 208, 192),

	PrimaryTextColor = Color3.fromRGB(236, 246, 244),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(176, 200, 200),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(250, 255, 254),
	InactiveTabTextColor = Color3.fromRGB(176, 200, 200),
	InactiveTabIconColor = Color3.fromRGB(176, 200, 200),
	ActiveTabTextColor = Color3.fromRGB(250, 255, 254),
	ActiveTabIconColor = Color3.fromRGB(228, 250, 246),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(92, 208, 192),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(255, 255, 255),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(24, 41, 40),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(16, 26, 27),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(34, 56, 54),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(238, 248, 246),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Nocturne: black forest under a magenta-purple aurora. Near-black violet
-- chrome with a deep purple-magenta primary, hue leaning toward 300.
ThemeDefinitions.Nocturne = {
	WindowColor = Color3.fromRGB(15, 13, 22),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(17, 15, 26),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(23, 19, 35),
	SidebarTransparency = 0.68,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(29, 25, 44),
	InputBackgroundTransparency = 0.1,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(214, 64, 196),
	SecondaryColor = Color3.fromRGB(106, 74, 126),
	TertiaryColor = Color3.fromRGB(172, 152, 186),
	Undercolor = Color3.fromRGB(36, 30, 52),
	AccentColor = Color3.fromRGB(244, 116, 220),

	PrimaryTextColor = Color3.fromRGB(242, 238, 246),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(194, 186, 206),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(252, 250, 255),
	InactiveTabTextColor = Color3.fromRGB(194, 186, 206),
	InactiveTabIconColor = Color3.fromRGB(194, 186, 206),
	ActiveTabTextColor = Color3.fromRGB(252, 250, 255),
	ActiveTabIconColor = Color3.fromRGB(255, 232, 250),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(244, 116, 220),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(255, 255, 255),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(29, 25, 44),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(17, 15, 26),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(44, 36, 64),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(244, 240, 250),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Solace: white-blue winter forest. The softest, palest ice-blue light theme:
-- near-white chrome, gentlest saturation, cool slate-blue text.
ThemeDefinitions.Solace = {
	WindowColor = Color3.fromRGB(245, 248, 252),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(250, 252, 253),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(122, 142, 164),

	SidebarColor = Color3.fromRGB(226, 237, 248),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.1,
	InputBackgroundColor = Color3.fromRGB(231, 239, 248),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(148, 168, 192),
	StrokeColor = Color3.fromRGB(122, 142, 170),
	StrokeTransparency = 0.82,
	PrimaryColor = Color3.fromRGB(96, 152, 210),
	SecondaryColor = Color3.fromRGB(184, 204, 226),
	TertiaryColor = Color3.fromRGB(150, 170, 196),
	Undercolor = Color3.fromRGB(216, 228, 242),
	AccentColor = Color3.fromRGB(62, 138, 208),

	PrimaryTextColor = Color3.fromRGB(26, 40, 60),
	PrimaryTextTransparency = 0,
	SecondaryTextColor = Color3.fromRGB(88, 108, 132),
	SecondaryTextTransparency = 0.15,
	TitleTextColor = Color3.fromRGB(16, 28, 48),
	InactiveTabTextColor = Color3.fromRGB(88, 108, 132),
	InactiveTabIconColor = Color3.fromRGB(88, 108, 132),
	ActiveTabTextColor = Color3.fromRGB(20, 34, 56),
	ActiveTabIconColor = Color3.fromRGB(20, 34, 56),
	ActiveTabTextTransparency = 0,
	InactiveTabTextTransparency = 0.3,
	ActiveTabIconTransparency = 0,
	InactiveTabIconTransparency = 0.3,
	ActiveTabButtonColor = Color3.fromRGB(62, 138, 208),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(120, 140, 165),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(174, 190, 212),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(231, 239, 248),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(250, 252, 253),
	PopupBackgroundTransparency = 0,
	PopupNeutralColor = Color3.fromRGB(226, 237, 248),
	PopupShadowColor = Color3.fromRGB(122, 142, 164),
	PopupTextColor = Color3.fromRGB(26, 40, 60),
	PopupTextTransparency = 0,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Cielo: sky cobalt with a coral spark. Pale blue-white chrome over a bright
-- cobalt primary, with a warm coral accent drawn from the red wave in its wallpaper.
ThemeDefinitions.Cielo = {
	WindowColor = Color3.fromRGB(246, 248, 252),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(252, 253, 255),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(110, 130, 170),

	SidebarColor = Color3.fromRGB(226, 234, 248),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.1,
	InputBackgroundColor = Color3.fromRGB(232, 238, 250),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(140, 158, 188),
	StrokeColor = Color3.fromRGB(110, 130, 170),
	StrokeTransparency = 0.82,
	PrimaryColor = Color3.fromRGB(24, 86, 208),
	SecondaryColor = Color3.fromRGB(178, 194, 222),
	TertiaryColor = Color3.fromRGB(140, 158, 188),
	Undercolor = Color3.fromRGB(210, 222, 240),
	AccentColor = Color3.fromRGB(244, 104, 74),

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
	ActiveTabButtonColor = Color3.fromRGB(244, 104, 74),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(110, 130, 170),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(160, 178, 208),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(232, 238, 250),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(252, 253, 255),
	PopupBackgroundTransparency = 0,
	PopupNeutralColor = Color3.fromRGB(226, 234, 248),
	PopupShadowColor = Color3.fromRGB(110, 130, 170),
	PopupTextColor = Color3.fromRGB(22, 32, 52),
	PopupTextTransparency = 0,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Honey: warm morning light. Cream chrome, frosted sidebar over opaque
-- content, amber-gold accent.
ThemeDefinitions.Honey = {
	WindowColor = Color3.fromRGB(250, 247, 240),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(253, 251, 246),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(150, 130, 100),

	SidebarColor = Color3.fromRGB(242, 234, 216),
	SidebarTransparency = 0.62,

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

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(150, 130, 100),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(192, 176, 148),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(242, 235, 220),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(253, 251, 246),
	PopupBackgroundTransparency = 0,
	PopupNeutralColor = Color3.fromRGB(242, 234, 216),
	PopupShadowColor = Color3.fromRGB(150, 130, 100),
	PopupTextColor = Color3.fromRGB(48, 38, 24),
	PopupTextTransparency = 0,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Dawn: warm orchid silk. Pink-cast white chrome with an orchid-violet primary
-- and a soft rose accent, the warm violet answer to Lilac's cool periwinkle.
ThemeDefinitions.Dawn = {
	WindowColor = Color3.fromRGB(250, 245, 246),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(253, 250, 251),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(150, 120, 165),

	SidebarColor = Color3.fromRGB(240, 228, 244),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.1,
	InputBackgroundColor = Color3.fromRGB(240, 232, 242),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(176, 140, 182),
	StrokeColor = Color3.fromRGB(150, 120, 165),
	StrokeTransparency = 0.82,
	PrimaryColor = Color3.fromRGB(166, 110, 210),
	SecondaryColor = Color3.fromRGB(220, 204, 230),
	TertiaryColor = Color3.fromRGB(178, 152, 184),
	Undercolor = Color3.fromRGB(234, 222, 240),
	AccentColor = Color3.fromRGB(236, 148, 152),

	PrimaryTextColor = Color3.fromRGB(52, 36, 54),
	PrimaryTextTransparency = 0,
	SecondaryTextColor = Color3.fromRGB(118, 94, 124),
	SecondaryTextTransparency = 0.15,
	TitleTextColor = Color3.fromRGB(44, 28, 46),
	InactiveTabTextColor = Color3.fromRGB(122, 98, 128),
	InactiveTabIconColor = Color3.fromRGB(122, 98, 128),
	ActiveTabTextColor = Color3.fromRGB(46, 30, 48),
	ActiveTabIconColor = Color3.fromRGB(46, 30, 48),
	ActiveTabTextTransparency = 0,
	InactiveTabTextTransparency = 0.3,
	ActiveTabIconTransparency = 0,
	InactiveTabIconTransparency = 0.3,
	ActiveTabButtonColor = Color3.fromRGB(236, 148, 152),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(150, 120, 165),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(200, 178, 208),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(240, 232, 242),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(253, 250, 251),
	PopupBackgroundTransparency = 0,
	PopupNeutralColor = Color3.fromRGB(240, 228, 244),
	PopupShadowColor = Color3.fromRGB(150, 120, 165),
	PopupTextColor = Color3.fromRGB(52, 36, 54),
	PopupTextTransparency = 0,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Alpine: slate-teal mountain mist. Cool slate-white chrome with a grey-cyan
-- cast throughout and a slate-teal accent, away from the pure-blue lane.
ThemeDefinitions.Alpine = {
	WindowColor = Color3.fromRGB(242, 247, 247),
	WindowTransparency = 0.28,
	ContentBackgroundColor = Color3.fromRGB(246, 250, 250),
	ContentBackgroundTransparency = 0.42,
	MainframeShadowColor = Color3.fromRGB(120, 144, 156),

	SidebarColor = Color3.fromRGB(226, 238, 237),
	SidebarTransparency = 0,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.1,
	InputBackgroundColor = Color3.fromRGB(228, 239, 239),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(140, 162, 176),
	StrokeColor = Color3.fromRGB(118, 144, 158),
	StrokeTransparency = 0.82,
	PrimaryColor = Color3.fromRGB(54, 140, 164),
	SecondaryColor = Color3.fromRGB(180, 200, 206),
	TertiaryColor = Color3.fromRGB(142, 166, 174),
	Undercolor = Color3.fromRGB(212, 228, 230),
	AccentColor = Color3.fromRGB(72, 166, 188),

	PrimaryTextColor = Color3.fromRGB(22, 38, 42),
	PrimaryTextTransparency = 0,
	SecondaryTextColor = Color3.fromRGB(82, 104, 110),
	SecondaryTextTransparency = 0.15,
	TitleTextColor = Color3.fromRGB(14, 28, 32),
	InactiveTabTextColor = Color3.fromRGB(82, 104, 110),
	InactiveTabIconColor = Color3.fromRGB(82, 104, 110),
	ActiveTabTextColor = Color3.fromRGB(16, 32, 38),
	ActiveTabIconColor = Color3.fromRGB(16, 32, 38),
	ActiveTabTextTransparency = 0,
	InactiveTabTextTransparency = 0.3,
	ActiveTabIconTransparency = 0,
	InactiveTabIconTransparency = 0.3,
	ActiveTabButtonColor = Color3.fromRGB(72, 166, 188),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(120, 140, 170),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(168, 186, 192),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(228, 239, 239),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(246, 250, 250),
	PopupBackgroundTransparency = 0,
	PopupNeutralColor = Color3.fromRGB(226, 238, 237),
	PopupShadowColor = Color3.fromRGB(120, 144, 156),
	PopupTextColor = Color3.fromRGB(22, 38, 42),
	PopupTextTransparency = 0,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Peony: coral bloom. Soft blush-white chrome, translucent content over the
-- wallpaper, solid sidebar, warm coral accent.
ThemeDefinitions.Peony = {
	WindowColor = Color3.fromRGB(251, 244, 242),
	WindowTransparency = 0.28,
	ContentBackgroundColor = Color3.fromRGB(253, 248, 246),
	ContentBackgroundTransparency = 0.42,
	MainframeShadowColor = Color3.fromRGB(170, 120, 118),

	SidebarColor = Color3.fromRGB(246, 228, 224),
	SidebarTransparency = 0,

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

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(170, 120, 118),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(212, 178, 174),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(246, 232, 228),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(253, 248, 246),
	PopupBackgroundTransparency = 0,
	PopupNeutralColor = Color3.fromRGB(246, 228, 224),
	PopupShadowColor = Color3.fromRGB(170, 120, 118),
	PopupTextColor = Color3.fromRGB(58, 34, 36),
	PopupTextTransparency = 0,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Sakura: soft rose pink. Airy blush-white chrome, translucent content over
-- the wallpaper, solid sidebar, warm rose accent.
ThemeDefinitions.Sakura = {
	WindowColor = Color3.fromRGB(252, 245, 247),
	WindowTransparency = 0.28,
	ContentBackgroundColor = Color3.fromRGB(254, 249, 250),
	ContentBackgroundTransparency = 0.42,
	MainframeShadowColor = Color3.fromRGB(176, 128, 140),

	SidebarColor = Color3.fromRGB(248, 230, 234),
	SidebarTransparency = 0,

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

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(176, 128, 140),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(216, 180, 188),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(248, 234, 238),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(254, 249, 250),
	PopupBackgroundTransparency = 0,
	PopupNeutralColor = Color3.fromRGB(248, 230, 234),
	PopupShadowColor = Color3.fromRGB(176, 128, 140),
	PopupTextColor = Color3.fromRGB(58, 34, 42),
	PopupTextTransparency = 0,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Blush: fuchsia-magenta bloom. Pale pink-white chrome with a crimson-fuchsia
-- primary and a bright fuchsia accent, deeper and bluer than Nebula's pink.
ThemeDefinitions.Blush = {
	WindowColor = Color3.fromRGB(252, 245, 248),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(254, 249, 251),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(185, 120, 160),

	SidebarColor = Color3.fromRGB(246, 228, 238),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.1,
	InputBackgroundColor = Color3.fromRGB(246, 232, 240),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(195, 130, 170),
	StrokeColor = Color3.fromRGB(185, 120, 160),
	StrokeTransparency = 0.82,
	PrimaryColor = Color3.fromRGB(206, 52, 132),
	SecondaryColor = Color3.fromRGB(232, 196, 218),
	TertiaryColor = Color3.fromRGB(195, 140, 175),
	Undercolor = Color3.fromRGB(238, 212, 228),
	AccentColor = Color3.fromRGB(232, 88, 158),

	PrimaryTextColor = Color3.fromRGB(56, 28, 42),
	PrimaryTextTransparency = 0,
	SecondaryTextColor = Color3.fromRGB(126, 86, 108),
	SecondaryTextTransparency = 0.15,
	TitleTextColor = Color3.fromRGB(44, 22, 36),
	InactiveTabTextColor = Color3.fromRGB(130, 92, 114),
	InactiveTabIconColor = Color3.fromRGB(130, 92, 114),
	ActiveTabTextColor = Color3.fromRGB(48, 24, 38),
	ActiveTabIconColor = Color3.fromRGB(48, 24, 38),
	ActiveTabTextTransparency = 0,
	InactiveTabTextTransparency = 0.3,
	ActiveTabIconTransparency = 0,
	InactiveTabIconTransparency = 0.3,
	ActiveTabButtonColor = Color3.fromRGB(232, 88, 158),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(185, 120, 160),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(216, 178, 202),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(246, 232, 240),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(254, 249, 251),
	PopupBackgroundTransparency = 0,
	PopupNeutralColor = Color3.fromRGB(246, 228, 238),
	PopupShadowColor = Color3.fromRGB(185, 120, 160),
	PopupTextColor = Color3.fromRGB(56, 28, 42),
	PopupTextTransparency = 0,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Cinder: ash and muted ember. Warm-black ash chrome with a dim, desaturated
-- ember accent, the quiet and darker cousin of Ember.
ThemeDefinitions.Cinder = {
	WindowColor = Color3.fromRGB(17, 16, 17),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(19, 18, 19),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(24, 22, 23),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(31, 28, 29),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(190, 86, 54),
	SecondaryColor = Color3.fromRGB(102, 90, 84),
	TertiaryColor = Color3.fromRGB(166, 150, 144),
	Undercolor = Color3.fromRGB(44, 38, 36),
	AccentColor = Color3.fromRGB(218, 116, 74),

	PrimaryTextColor = Color3.fromRGB(242, 237, 234),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(190, 176, 170),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(242, 237, 234),
	InactiveTabTextColor = Color3.fromRGB(190, 176, 170),
	InactiveTabIconColor = Color3.fromRGB(190, 176, 170),
	ActiveTabTextColor = Color3.fromRGB(242, 237, 234),
	ActiveTabIconColor = Color3.fromRGB(242, 237, 234),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(218, 116, 74),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(166, 150, 144),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(31, 28, 29),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(21, 20, 21),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(44, 38, 36),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(242, 237, 234),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Mauve: dusky purple castle under a pink moon. The desaturated violet lane:
-- warm-grey plum chrome, dusty low-saturation plum accent, warm off-white text.
ThemeDefinitions.Mauve = {
	WindowColor = Color3.fromRGB(22, 18, 28),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(26, 22, 33),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(30, 24, 37),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(30, 24, 37),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(146, 108, 164),
	SecondaryColor = Color3.fromRGB(96, 76, 114),
	TertiaryColor = Color3.fromRGB(168, 150, 182),
	Undercolor = Color3.fromRGB(44, 37, 56),
	AccentColor = Color3.fromRGB(178, 142, 196),

	PrimaryTextColor = Color3.fromRGB(246, 241, 242),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(198, 188, 201),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(246, 241, 242),
	InactiveTabTextColor = Color3.fromRGB(198, 188, 201),
	InactiveTabIconColor = Color3.fromRGB(198, 188, 201),
	ActiveTabTextColor = Color3.fromRGB(246, 241, 242),
	ActiveTabIconColor = Color3.fromRGB(246, 241, 242),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(178, 142, 196),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(168, 150, 182),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(30, 24, 37),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(26, 22, 33),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(44, 37, 56),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(246, 241, 242),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Iris: purple cloud sea under a field of stars. Classic mid violet: deeper
-- and less bright than Vesper, bluer than Mauve's plum, on black-violet chrome.
ThemeDefinitions.Iris = {
	WindowColor = Color3.fromRGB(18, 16, 33),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(22, 19, 39),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(26, 22, 45),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(26, 22, 45),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(92, 74, 206),
	SecondaryColor = Color3.fromRGB(82, 68, 140),
	TertiaryColor = Color3.fromRGB(140, 126, 202),
	Undercolor = Color3.fromRGB(40, 34, 64),
	AccentColor = Color3.fromRGB(140, 118, 236),

	PrimaryTextColor = Color3.fromRGB(240, 238, 253),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(184, 180, 218),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(240, 238, 253),
	InactiveTabTextColor = Color3.fromRGB(184, 180, 218),
	InactiveTabIconColor = Color3.fromRGB(184, 180, 218),
	ActiveTabTextColor = Color3.fromRGB(240, 238, 253),
	ActiveTabIconColor = Color3.fromRGB(240, 238, 253),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(140, 118, 236),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(140, 126, 202),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(26, 22, 45),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(22, 19, 39),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(40, 34, 64),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(240, 238, 253),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Sundown: charcoal with a coral-red glow. Warm charcoal surfaces and a
-- coral accent, the last light band under black mountains.
ThemeDefinitions.Sundown = {
	WindowColor = Color3.fromRGB(22, 16, 18),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(25, 18, 20),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(30, 22, 24),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(36, 26, 28),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(236, 96, 74),
	SecondaryColor = Color3.fromRGB(134, 66, 58),
	TertiaryColor = Color3.fromRGB(188, 150, 146),
	Undercolor = Color3.fromRGB(48, 33, 36),
	AccentColor = Color3.fromRGB(250, 136, 110),

	PrimaryTextColor = Color3.fromRGB(248, 240, 238),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(202, 180, 176),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(248, 240, 238),
	InactiveTabTextColor = Color3.fromRGB(202, 180, 176),
	InactiveTabIconColor = Color3.fromRGB(202, 180, 176),
	ActiveTabTextColor = Color3.fromRGB(248, 240, 238),
	ActiveTabIconColor = Color3.fromRGB(248, 240, 238),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(250, 136, 110),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(188, 150, 146),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(36, 26, 28),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(26, 19, 21),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(48, 34, 37),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(248, 240, 238),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Twilight: navy sky with rose-pink glow clouds. The roster's only dark theme
-- with a rose-pink primary, resting on deep navy chrome outside the purples.
ThemeDefinitions.Twilight = {
	WindowColor = Color3.fromRGB(16, 18, 32),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(18, 20, 36),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(24, 26, 44),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(26, 30, 48),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(244, 128, 146),
	SecondaryColor = Color3.fromRGB(68, 84, 130),
	TertiaryColor = Color3.fromRGB(150, 166, 206),
	Undercolor = Color3.fromRGB(34, 40, 66),
	AccentColor = Color3.fromRGB(255, 150, 170),

	PrimaryTextColor = Color3.fromRGB(240, 244, 252),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(184, 196, 216),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(248, 250, 255),
	InactiveTabTextColor = Color3.fromRGB(184, 196, 216),
	InactiveTabIconColor = Color3.fromRGB(184, 196, 216),
	ActiveTabTextColor = Color3.fromRGB(248, 250, 255),
	ActiveTabIconColor = Color3.fromRGB(255, 238, 244),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(255, 150, 170),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(150, 166, 206),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(26, 30, 48),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(18, 20, 36),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(38, 44, 68),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(240, 244, 252),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Nebula: pink-magenta aurora over dark pines, violet-blue at the top. A
-- pink-magenta primary paired with the periwinkle blue accent on black-plum chrome.
ThemeDefinitions.Nebula = {
	WindowColor = Color3.fromRGB(17, 14, 26),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(21, 18, 31),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(24, 20, 38),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(24, 20, 38),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(242, 88, 158),
	SecondaryColor = Color3.fromRGB(148, 74, 118),
	TertiaryColor = Color3.fromRGB(204, 162, 196),
	Undercolor = Color3.fromRGB(39, 30, 50),
	AccentColor = Color3.fromRGB(148, 182, 242),

	PrimaryTextColor = Color3.fromRGB(242, 237, 252),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(212, 186, 209),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(242, 237, 252),
	InactiveTabTextColor = Color3.fromRGB(212, 186, 209),
	InactiveTabIconColor = Color3.fromRGB(212, 186, 209),
	ActiveTabTextColor = Color3.fromRGB(242, 237, 252),
	ActiveTabIconColor = Color3.fromRGB(242, 237, 252),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(148, 182, 242),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(204, 162, 196),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(24, 20, 38),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(21, 18, 31),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(39, 30, 50),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(242, 237, 252),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Monterey: blue-grey neutral. Charcoal with a faint blue cast and a
-- desaturated slate-blue accent, between Base's grey and Umbral's navy.
ThemeDefinitions.Monterey = {
	WindowColor = Color3.fromRGB(17, 19, 24),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(20, 23, 29),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(24, 27, 34),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(30, 34, 42),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(96, 120, 164),
	SecondaryColor = Color3.fromRGB(58, 72, 98),
	TertiaryColor = Color3.fromRGB(134, 148, 172),
	Undercolor = Color3.fromRGB(38, 44, 56),
	AccentColor = Color3.fromRGB(138, 158, 196),

	PrimaryTextColor = Color3.fromRGB(240, 243, 249),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(176, 186, 204),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(240, 243, 249),
	InactiveTabTextColor = Color3.fromRGB(176, 186, 204),
	InactiveTabIconColor = Color3.fromRGB(176, 186, 204),
	ActiveTabTextColor = Color3.fromRGB(240, 243, 249),
	ActiveTabIconColor = Color3.fromRGB(240, 243, 249),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(138, 158, 196),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(134, 148, 172),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(30, 34, 42),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(21, 24, 30),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(40, 46, 60),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(240, 243, 249),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Sonoma: sea-glass. Deep pine-teal chrome with a mint accent and an ocean-blue
-- secondary, matching the green-over-blue water of its wallpaper.
ThemeDefinitions.Sonoma = {
	WindowColor = Color3.fromRGB(13, 22, 20),
	WindowTransparency = 0.15,
	ContentBackgroundColor = Color3.fromRGB(16, 26, 24),
	ContentBackgroundTransparency = 0.1,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(20, 33, 30),
	SidebarTransparency = 0.72,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(26, 44, 40),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(130, 200, 180),
	StrokeTransparency = 0.9,
	PrimaryColor = Color3.fromRGB(45, 168, 130),
	SecondaryColor = Color3.fromRGB(34, 94, 84),
	TertiaryColor = Color3.fromRGB(120, 160, 150),
	Undercolor = Color3.fromRGB(26, 44, 40),
	AccentColor = Color3.fromRGB(74, 222, 160),

	PrimaryTextColor = Color3.fromRGB(232, 248, 242),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(160, 190, 182),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(232, 248, 242),
	InactiveTabTextColor = Color3.fromRGB(160, 190, 182),
	InactiveTabIconColor = Color3.fromRGB(160, 190, 182),
	ActiveTabTextColor = Color3.fromRGB(232, 248, 242),
	ActiveTabIconColor = Color3.fromRGB(232, 248, 242),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(74, 222, 160),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(130, 200, 180),
	SectionStrokeTransparency = 0.95,
	SectionDividerColor = Color3.fromRGB(120, 160, 150),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(26, 44, 40),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(16, 26, 24),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(26, 44, 40),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(232, 248, 242),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Ventura: burnt orange silk. Warm dark chrome with a burnt-orange accent
-- drawn from the smooth silk waves of its wallpaper.
ThemeDefinitions.Ventura = {
	WindowColor = Color3.fromRGB(20, 17, 16),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(23, 20, 19),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(28, 24, 22),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(36, 31, 29),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(230, 124, 48),
	SecondaryColor = Color3.fromRGB(124, 90, 64),
	TertiaryColor = Color3.fromRGB(180, 158, 142),
	Undercolor = Color3.fromRGB(46, 38, 34),
	AccentColor = Color3.fromRGB(244, 158, 78),

	PrimaryTextColor = Color3.fromRGB(246, 240, 236),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(198, 182, 170),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(246, 240, 236),
	InactiveTabTextColor = Color3.fromRGB(198, 182, 170),
	InactiveTabIconColor = Color3.fromRGB(198, 182, 170),
	ActiveTabTextColor = Color3.fromRGB(246, 240, 236),
	ActiveTabIconColor = Color3.fromRGB(246, 240, 236),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(244, 158, 78),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(180, 158, 142),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(36, 31, 29),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(24, 21, 20),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(46, 40, 36),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(246, 240, 236),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Vermilion: orange-leaning red. Warm black chrome with a vermilion accent,
-- red kept with green above blue so it never drifts toward crimson.
ThemeDefinitions.Vermilion = {
	WindowColor = Color3.fromRGB(26, 15, 17),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(29, 17, 19),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(35, 21, 23),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(41, 25, 27),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(232, 52, 46),
	SecondaryColor = Color3.fromRGB(138, 52, 44),
	TertiaryColor = Color3.fromRGB(196, 140, 132),
	Undercolor = Color3.fromRGB(52, 32, 34),
	AccentColor = Color3.fromRGB(252, 102, 78),

	PrimaryTextColor = Color3.fromRGB(248, 238, 236),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(208, 178, 174),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(248, 238, 236),
	InactiveTabTextColor = Color3.fromRGB(208, 178, 174),
	InactiveTabIconColor = Color3.fromRGB(208, 178, 174),
	ActiveTabTextColor = Color3.fromRGB(248, 238, 236),
	ActiveTabIconColor = Color3.fromRGB(248, 238, 236),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(252, 102, 78),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(196, 140, 132),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(41, 25, 27),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(30, 18, 20),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(52, 33, 35),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(248, 238, 236),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Grove: deep pine forest under a chartreuse sky. Near-black pine chrome with
-- a deep pine primary and a punchy yellow-green chartreuse accent.
ThemeDefinitions.Grove = {
	WindowColor = Color3.fromRGB(13, 22, 17),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(15, 26, 20),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(18, 32, 24),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(22, 37, 28),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(42, 150, 86),
	SecondaryColor = Color3.fromRGB(36, 94, 58),
	TertiaryColor = Color3.fromRGB(116, 166, 128),
	Undercolor = Color3.fromRGB(32, 50, 38),
	AccentColor = Color3.fromRGB(190, 226, 96),

	PrimaryTextColor = Color3.fromRGB(238, 247, 240),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(180, 206, 184),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(240, 250, 244),
	InactiveTabTextColor = Color3.fromRGB(180, 206, 184),
	InactiveTabIconColor = Color3.fromRGB(180, 206, 184),
	ActiveTabTextColor = Color3.fromRGB(240, 250, 244),
	ActiveTabIconColor = Color3.fromRGB(242, 250, 216),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(190, 226, 96),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(116, 166, 128),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(22, 37, 28),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(15, 26, 20),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(32, 50, 38),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(238, 248, 242),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Prism: deep indigo-violet silk waves. Electric indigo-blue chrome, the
-- roster's most blue-leaning violet: B highest and R held close to G.
ThemeDefinitions.Prism = {
	WindowColor = Color3.fromRGB(16, 17, 30),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(20, 21, 36),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(24, 26, 44),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(26, 28, 48),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.93,
	PrimaryColor = Color3.fromRGB(92, 84, 242),
	SecondaryColor = Color3.fromRGB(64, 76, 152),
	TertiaryColor = Color3.fromRGB(138, 150, 212),
	Undercolor = Color3.fromRGB(34, 36, 64),
	AccentColor = Color3.fromRGB(158, 150, 252),

	PrimaryTextColor = Color3.fromRGB(240, 242, 254),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(184, 190, 224),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(242, 244, 255),
	InactiveTabTextColor = Color3.fromRGB(184, 190, 224),
	InactiveTabIconColor = Color3.fromRGB(184, 190, 224),
	ActiveTabTextColor = Color3.fromRGB(242, 244, 255),
	ActiveTabIconColor = Color3.fromRGB(230, 232, 255),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(158, 150, 252),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.98,
	SectionDividerColor = Color3.fromRGB(138, 150, 212),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(26, 28, 48),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(20, 21, 36),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(36, 38, 66),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(242, 244, 255),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Sage: misty white-and-teal forest. The pale grey-teal lane: the most teal of
-- the greens (hue ~168, desaturated), cool white chrome, slate-teal text.
ThemeDefinitions.Sage = {
	WindowColor = Color3.fromRGB(244, 248, 246),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(247, 251, 249),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(144, 174, 168),

	SidebarColor = Color3.fromRGB(230, 240, 237),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.1,
	InputBackgroundColor = Color3.fromRGB(229, 239, 237),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(144, 174, 168),
	StrokeColor = Color3.fromRGB(112, 152, 146),
	StrokeTransparency = 0.82,
	PrimaryColor = Color3.fromRGB(74, 148, 132),
	SecondaryColor = Color3.fromRGB(148, 192, 184),
	TertiaryColor = Color3.fromRGB(152, 186, 178),
	Undercolor = Color3.fromRGB(212, 230, 226),
	AccentColor = Color3.fromRGB(110, 182, 166),

	PrimaryTextColor = Color3.fromRGB(22, 46, 45),
	PrimaryTextTransparency = 0,
	SecondaryTextColor = Color3.fromRGB(84, 120, 118),
	SecondaryTextTransparency = 0.15,
	TitleTextColor = Color3.fromRGB(22, 46, 45),
	InactiveTabTextColor = Color3.fromRGB(84, 120, 118),
	InactiveTabIconColor = Color3.fromRGB(84, 120, 118),
	ActiveTabTextColor = Color3.fromRGB(22, 46, 45),
	ActiveTabIconColor = Color3.fromRGB(22, 46, 45),
	ActiveTabTextTransparency = 0,
	InactiveTabTextTransparency = 0.3,
	ActiveTabIconTransparency = 0,
	InactiveTabIconTransparency = 0.3,
	ActiveTabButtonColor = Color3.fromRGB(110, 182, 166),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(120, 150, 130),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(152, 186, 178),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(229, 239, 237),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(247, 251, 249),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(212, 230, 226),
	PopupShadowColor = Color3.fromRGB(144, 174, 168),
	PopupTextColor = Color3.fromRGB(22, 46, 45),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Blossom: airy blossom pink. Blush-white chrome with the gentlest pink primary
-- and a pale petal accent.
ThemeDefinitions.Blossom = {
	WindowColor = Color3.fromRGB(252, 245, 246),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(254, 249, 250),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(208, 168, 180),

	SidebarColor = Color3.fromRGB(248, 234, 240),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.1,
	InputBackgroundColor = Color3.fromRGB(248, 236, 240),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(208, 168, 180),
	StrokeColor = Color3.fromRGB(208, 168, 180),
	StrokeTransparency = 0.82,
	PrimaryColor = Color3.fromRGB(230, 130, 166),
	SecondaryColor = Color3.fromRGB(242, 210, 224),
	TertiaryColor = Color3.fromRGB(216, 180, 196),
	Undercolor = Color3.fromRGB(246, 228, 236),
	AccentColor = Color3.fromRGB(244, 164, 192),

	PrimaryTextColor = Color3.fromRGB(62, 34, 46),
	PrimaryTextTransparency = 0,
	SecondaryTextColor = Color3.fromRGB(134, 98, 114),
	SecondaryTextTransparency = 0.15,
	TitleTextColor = Color3.fromRGB(62, 34, 46),
	InactiveTabTextColor = Color3.fromRGB(134, 98, 114),
	InactiveTabIconColor = Color3.fromRGB(134, 98, 114),
	ActiveTabTextColor = Color3.fromRGB(62, 34, 46),
	ActiveTabIconColor = Color3.fromRGB(62, 34, 46),
	ActiveTabTextTransparency = 0,
	InactiveTabTextTransparency = 0.3,
	ActiveTabIconTransparency = 0,
	InactiveTabIconTransparency = 0.3,
	ActiveTabButtonColor = Color3.fromRGB(244, 164, 192),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(208, 168, 180),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(216, 180, 196),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(248, 236, 240),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(254, 249, 250),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(246, 228, 236),
	PopupShadowColor = Color3.fromRGB(208, 168, 180),
	PopupTextColor = Color3.fromRGB(62, 34, 46),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Petal: salmon-rose warmth. Warm cream chrome with a deep salmon primary and
-- a warm coral accent, the orange-leaning pink of the roster.
ThemeDefinitions.Petal = {
	WindowColor = Color3.fromRGB(251, 243, 241),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(253, 248, 246),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(200, 150, 140),

	SidebarColor = Color3.fromRGB(246, 228, 224),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.1,
	InputBackgroundColor = Color3.fromRGB(246, 232, 228),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(205, 158, 148),
	StrokeColor = Color3.fromRGB(200, 150, 140),
	StrokeTransparency = 0.82,
	PrimaryColor = Color3.fromRGB(236, 116, 92),
	SecondaryColor = Color3.fromRGB(238, 206, 198),
	TertiaryColor = Color3.fromRGB(208, 162, 152),
	Undercolor = Color3.fromRGB(244, 222, 214),
	AccentColor = Color3.fromRGB(244, 142, 134),

	PrimaryTextColor = Color3.fromRGB(60, 34, 32),
	PrimaryTextTransparency = 0,
	SecondaryTextColor = Color3.fromRGB(130, 94, 86),
	SecondaryTextTransparency = 0.15,
	TitleTextColor = Color3.fromRGB(60, 34, 32),
	InactiveTabTextColor = Color3.fromRGB(130, 94, 86),
	InactiveTabIconColor = Color3.fromRGB(130, 94, 86),
	ActiveTabTextColor = Color3.fromRGB(60, 34, 32),
	ActiveTabIconColor = Color3.fromRGB(60, 34, 32),
	ActiveTabTextTransparency = 0,
	InactiveTabTextTransparency = 0.3,
	ActiveTabIconTransparency = 0,
	InactiveTabIconTransparency = 0.3,
	ActiveTabButtonColor = Color3.fromRGB(244, 142, 134),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(200, 150, 140),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(214, 172, 162),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(246, 232, 228),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(253, 248, 246),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(244, 222, 214),
	PopupShadowColor = Color3.fromRGB(200, 150, 140),
	PopupTextColor = Color3.fromRGB(60, 34, 32),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Frost: icy blue-white above a vivid red wave. Pale ice chrome with a cool
-- icy-cyan primary; the vivid red accent stays on highlight keys, not the whole theme.
ThemeDefinitions.Frost = {
	WindowColor = Color3.fromRGB(244, 247, 251),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(248, 251, 254),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(160, 180, 200),

	SidebarColor = Color3.fromRGB(232, 238, 246),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.1,
	InputBackgroundColor = Color3.fromRGB(232, 238, 246),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(160, 180, 200),
	StrokeColor = Color3.fromRGB(150, 172, 198),
	StrokeTransparency = 0.82,
	PrimaryColor = Color3.fromRGB(80, 168, 204),
	SecondaryColor = Color3.fromRGB(190, 206, 228),
	TertiaryColor = Color3.fromRGB(210, 150, 144),
	Undercolor = Color3.fromRGB(220, 230, 242),
	AccentColor = Color3.fromRGB(236, 64, 60),

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
	ActiveTabButtonColor = Color3.fromRGB(236, 64, 60),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(150, 172, 198),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(160, 180, 205),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(232, 238, 246),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(248, 251, 254),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(220, 230, 242),
	PopupShadowColor = Color3.fromRGB(160, 180, 200),
	PopupTextColor = Color3.fromRGB(28, 40, 58),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Amber: white, pale blue and pink with one yellow accent — the palette its
-- wallpaper shows; porcelain chrome with a vivid amber-yellow active control.
ThemeDefinitions.Amber = {
	WindowColor = Color3.fromRGB(247, 249, 253),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(252, 253, 255),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(150, 170, 200),

	SidebarColor = Color3.fromRGB(240, 245, 252),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.1,
	InputBackgroundColor = Color3.fromRGB(240, 245, 252),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(150, 170, 200),
	StrokeColor = Color3.fromRGB(180, 200, 225),
	StrokeTransparency = 0.82,
	PrimaryColor = Color3.fromRGB(60, 130, 220),
	SecondaryColor = Color3.fromRGB(232, 140, 180),
	TertiaryColor = Color3.fromRGB(150, 175, 205),
	Undercolor = Color3.fromRGB(228, 236, 246),
	AccentColor = Color3.fromRGB(245, 190, 60),

	PrimaryTextColor = Color3.fromRGB(30, 45, 70),
	PrimaryTextTransparency = 0,
	SecondaryTextColor = Color3.fromRGB(95, 120, 155),
	SecondaryTextTransparency = 0.15,
	TitleTextColor = Color3.fromRGB(30, 45, 70),
	InactiveTabTextColor = Color3.fromRGB(95, 120, 155),
	InactiveTabIconColor = Color3.fromRGB(95, 120, 155),
	ActiveTabTextColor = Color3.fromRGB(30, 45, 70),
	ActiveTabIconColor = Color3.fromRGB(30, 45, 70),
	ActiveTabTextTransparency = 0,
	InactiveTabTextTransparency = 0.3,
	ActiveTabIconTransparency = 0,
	InactiveTabIconTransparency = 0.3,
	ActiveTabButtonColor = Color3.fromRGB(245, 190, 60),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(180, 200, 225),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(226, 170, 200),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(240, 245, 252),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(252, 253, 255),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(228, 236, 246),
	PopupShadowColor = Color3.fromRGB(150, 170, 200),
	PopupTextColor = Color3.fromRGB(30, 45, 70),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Rosa: pastel pink peaks over periwinkle shadow. Pale pink chrome with a
-- pastel-pink primary and the periwinkle accent from its snow-peak wallpaper.
ThemeDefinitions.Rosa = {
	WindowColor = Color3.fromRGB(252, 243, 246),
	WindowTransparency = 0.22,
	ContentBackgroundColor = Color3.fromRGB(254, 247, 250),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(195, 155, 180),

	SidebarColor = Color3.fromRGB(246, 228, 238),
	SidebarTransparency = 0.62,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.1,
	InputBackgroundColor = Color3.fromRGB(246, 230, 238),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(202, 162, 182),
	StrokeColor = Color3.fromRGB(195, 155, 180),
	StrokeTransparency = 0.82,
	PrimaryColor = Color3.fromRGB(232, 124, 156),
	SecondaryColor = Color3.fromRGB(238, 198, 216),
	TertiaryColor = Color3.fromRGB(200, 164, 186),
	Undercolor = Color3.fromRGB(242, 220, 232),
	AccentColor = Color3.fromRGB(128, 142, 222),

	PrimaryTextColor = Color3.fromRGB(56, 30, 46),
	PrimaryTextTransparency = 0,
	SecondaryTextColor = Color3.fromRGB(124, 90, 118),
	SecondaryTextTransparency = 0.15,
	TitleTextColor = Color3.fromRGB(56, 30, 46),
	InactiveTabTextColor = Color3.fromRGB(124, 90, 118),
	InactiveTabIconColor = Color3.fromRGB(124, 90, 118),
	ActiveTabTextColor = Color3.fromRGB(56, 30, 46),
	ActiveTabIconColor = Color3.fromRGB(56, 30, 46),
	ActiveTabTextTransparency = 0,
	InactiveTabTextTransparency = 0.3,
	ActiveTabIconTransparency = 0,
	InactiveTabIconTransparency = 0.3,
	ActiveTabButtonColor = Color3.fromRGB(128, 142, 222),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(195, 155, 180),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(206, 168, 196),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(246, 230, 238),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(254, 247, 250),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(242, 220, 232),
	PopupShadowColor = Color3.fromRGB(195, 155, 180),
	PopupTextColor = Color3.fromRGB(56, 30, 46),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Gruvbox: warm retro terminal. Earthy greys with a mustard yellow primary
-- and burnt orange secondary, the roster's only warm-neutral theme.
ThemeDefinitions.Gruvbox = {
	WindowColor = Color3.fromRGB(29, 32, 33),
	WindowTransparency = 0.15,
	ContentBackgroundColor = Color3.fromRGB(40, 40, 40),
	ContentBackgroundTransparency = 0.1,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(40, 40, 40),
	SidebarTransparency = 0.72,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(50, 48, 47),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(168, 153, 132),
	StrokeTransparency = 0.88,
	PrimaryColor = Color3.fromRGB(250, 189, 47),
	SecondaryColor = Color3.fromRGB(214, 93, 14),
	TertiaryColor = Color3.fromRGB(146, 131, 116),
	Undercolor = Color3.fromRGB(60, 56, 54),
	AccentColor = Color3.fromRGB(250, 189, 47),

	PrimaryTextColor = Color3.fromRGB(235, 219, 178),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(168, 153, 132),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(251, 241, 199),
	InactiveTabTextColor = Color3.fromRGB(168, 153, 132),
	InactiveTabIconColor = Color3.fromRGB(168, 153, 132),
	ActiveTabTextColor = Color3.fromRGB(251, 241, 199),
	ActiveTabIconColor = Color3.fromRGB(251, 241, 199),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(250, 189, 47),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(168, 153, 132),
	SectionStrokeTransparency = 0.95,
	SectionDividerColor = Color3.fromRGB(146, 131, 116),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(50, 48, 47),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(40, 40, 40),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(60, 56, 54),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(235, 219, 178),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}
-- Graphite: the neutral. Zero hue anywhere — pure grey chrome with a single
-- cool silver accent, deliberately colourless.
ThemeDefinitions.Graphite = {
	WindowColor = Color3.fromRGB(28, 28, 30),
	WindowTransparency = 0.12,
	ContentBackgroundColor = Color3.fromRGB(34, 34, 36),
	ContentBackgroundTransparency = 0.08,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(38, 38, 41),
	SidebarTransparency = 0.7,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.965,
	InputBackgroundColor = Color3.fromRGB(46, 46, 49),
	InputBackgroundTransparency = 0.12,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.91,
	PrimaryColor = Color3.fromRGB(198, 202, 210),
	SecondaryColor = Color3.fromRGB(120, 124, 132),
	TertiaryColor = Color3.fromRGB(138, 142, 148),
	Undercolor = Color3.fromRGB(52, 52, 56),
	AccentColor = Color3.fromRGB(224, 228, 236),

	PrimaryTextColor = Color3.fromRGB(238, 238, 240),
	PrimaryTextTransparency = 0.08,
	SecondaryTextColor = Color3.fromRGB(160, 162, 168),
	SecondaryTextTransparency = 0.38,
	TitleTextColor = Color3.fromRGB(248, 248, 250),
	InactiveTabTextColor = Color3.fromRGB(160, 162, 168),
	InactiveTabIconColor = Color3.fromRGB(160, 162, 168),
	ActiveTabTextColor = Color3.fromRGB(248, 248, 250),
	ActiveTabIconColor = Color3.fromRGB(248, 248, 250),
	ActiveTabTextTransparency = 0.18,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.18,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(224, 228, 236),
	ActiveTabButtonTransparency = 0.86,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.972,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.95,
	SectionDividerColor = Color3.fromRGB(120, 124, 132),
	SectionDividerTransparency = 0.88,
	SearchBarBackgroundColor = Color3.fromRGB(46, 46, 49),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(34, 34, 36),
	PopupBackgroundTransparency = 0.04,
	PopupNeutralColor = Color3.fromRGB(52, 52, 56),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(238, 238, 240),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Mint: light and green. Soft mint paper with a deeper teal-green accent so
-- controls still read on white; the airy counterpart to the dark greens.
ThemeDefinitions.Mint = {
	WindowColor = Color3.fromRGB(245, 250, 247),
	WindowTransparency = 0.2,
	ContentBackgroundColor = Color3.fromRGB(250, 253, 251),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(150, 185, 170),

	SidebarColor = Color3.fromRGB(233, 245, 238),
	SidebarTransparency = 0.6,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.08,
	InputBackgroundColor = Color3.fromRGB(233, 245, 238),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(150, 185, 170),
	StrokeColor = Color3.fromRGB(178, 210, 196),
	StrokeTransparency = 0.8,
	PrimaryColor = Color3.fromRGB(38, 152, 116),
	SecondaryColor = Color3.fromRGB(150, 205, 180),
	TertiaryColor = Color3.fromRGB(140, 175, 162),
	Undercolor = Color3.fromRGB(224, 238, 231),
	AccentColor = Color3.fromRGB(30, 178, 132),

	PrimaryTextColor = Color3.fromRGB(24, 52, 42),
	PrimaryTextTransparency = 0,
	SecondaryTextColor = Color3.fromRGB(88, 122, 108),
	SecondaryTextTransparency = 0.15,
	TitleTextColor = Color3.fromRGB(24, 52, 42),
	InactiveTabTextColor = Color3.fromRGB(88, 122, 108),
	InactiveTabIconColor = Color3.fromRGB(88, 122, 108),
	ActiveTabTextColor = Color3.fromRGB(24, 52, 42),
	ActiveTabIconColor = Color3.fromRGB(24, 52, 42),
	ActiveTabTextTransparency = 0,
	InactiveTabTextTransparency = 0.3,
	ActiveTabIconTransparency = 0,
	InactiveTabIconTransparency = 0.3,
	ActiveTabButtonColor = Color3.fromRGB(30, 178, 132),
	ActiveTabButtonTransparency = 0.86,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.42,
	SectionStrokeColor = Color3.fromRGB(178, 210, 196),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(160, 200, 184),
	SectionDividerTransparency = 0.55,
	SearchBarBackgroundColor = Color3.fromRGB(233, 245, 238),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(250, 253, 251),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(224, 238, 231),
	PopupShadowColor = Color3.fromRGB(150, 185, 170),
	PopupTextColor = Color3.fromRGB(24, 52, 42),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Lilac: light violet. Lilac paper with a saturated periwinkle accent so it
-- stays legible instead of washing out like a tint would.
ThemeDefinitions.Lilac = {
	WindowColor = Color3.fromRGB(248, 246, 253),
	WindowTransparency = 0.2,
	ContentBackgroundColor = Color3.fromRGB(252, 251, 254),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(170, 160, 200),

	SidebarColor = Color3.fromRGB(240, 237, 250),
	SidebarTransparency = 0.6,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.08,
	InputBackgroundColor = Color3.fromRGB(240, 237, 250),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(170, 160, 200),
	StrokeColor = Color3.fromRGB(196, 188, 224),
	StrokeTransparency = 0.8,
	PrimaryColor = Color3.fromRGB(112, 90, 214),
	SecondaryColor = Color3.fromRGB(186, 170, 232),
	TertiaryColor = Color3.fromRGB(158, 148, 190),
	Undercolor = Color3.fromRGB(232, 228, 246),
	AccentColor = Color3.fromRGB(126, 96, 240),

	PrimaryTextColor = Color3.fromRGB(38, 32, 62),
	PrimaryTextTransparency = 0,
	SecondaryTextColor = Color3.fromRGB(104, 96, 136),
	SecondaryTextTransparency = 0.15,
	TitleTextColor = Color3.fromRGB(38, 32, 62),
	InactiveTabTextColor = Color3.fromRGB(104, 96, 136),
	InactiveTabIconColor = Color3.fromRGB(104, 96, 136),
	ActiveTabTextColor = Color3.fromRGB(38, 32, 62),
	ActiveTabIconColor = Color3.fromRGB(38, 32, 62),
	ActiveTabTextTransparency = 0,
	InactiveTabTextTransparency = 0.3,
	ActiveTabIconTransparency = 0,
	InactiveTabIconTransparency = 0.3,
	ActiveTabButtonColor = Color3.fromRGB(126, 96, 240),
	ActiveTabButtonTransparency = 0.86,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.42,
	SectionStrokeColor = Color3.fromRGB(196, 188, 224),
	SectionStrokeTransparency = 0.85,
	SectionDividerColor = Color3.fromRGB(186, 176, 216),
	SectionDividerTransparency = 0.55,
	SearchBarBackgroundColor = Color3.fromRGB(240, 237, 250),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(252, 251, 254),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(232, 228, 246),
	PopupShadowColor = Color3.fromRGB(170, 160, 200),
	PopupTextColor = Color3.fromRGB(38, 32, 62),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Crimson: deep red on near-black. A blood-red accent on a cold graphite base,
-- sitting on the cool-red side rather than the orange half of the wheel.
ThemeDefinitions.Crimson = {
	WindowColor = Color3.fromRGB(24, 18, 20),
	WindowTransparency = 0.15,
	ContentBackgroundColor = Color3.fromRGB(30, 22, 25),
	ContentBackgroundTransparency = 0.1,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(36, 26, 30),
	SidebarTransparency = 0.72,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(44, 32, 37),
	InputBackgroundTransparency = 0.15,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(226, 138, 152),
	StrokeTransparency = 0.9,
	PrimaryColor = Color3.fromRGB(214, 56, 84),
	SecondaryColor = Color3.fromRGB(126, 34, 54),
	TertiaryColor = Color3.fromRGB(158, 124, 134),
	Undercolor = Color3.fromRGB(54, 38, 44),
	AccentColor = Color3.fromRGB(240, 78, 104),

	PrimaryTextColor = Color3.fromRGB(250, 232, 236),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(196, 164, 174),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(252, 238, 242),
	InactiveTabTextColor = Color3.fromRGB(196, 164, 174),
	InactiveTabIconColor = Color3.fromRGB(196, 164, 174),
	ActiveTabTextColor = Color3.fromRGB(252, 238, 242),
	ActiveTabIconColor = Color3.fromRGB(252, 238, 242),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(240, 78, 104),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(226, 138, 152),
	SectionStrokeTransparency = 0.95,
	SectionDividerColor = Color3.fromRGB(158, 124, 134),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(44, 32, 37),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(30, 22, 25),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(54, 38, 44),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(250, 232, 236),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Umber: dark warm bronze. Desaturated umber brown with a brushed bronze
-- accent, deliberately flatter than Gruvbox's saturated yellow.
ThemeDefinitions.Umber = {
	WindowColor = Color3.fromRGB(26, 22, 19),
	WindowTransparency = 0.14,
	ContentBackgroundColor = Color3.fromRGB(33, 28, 24),
	ContentBackgroundTransparency = 0.08,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(38, 32, 27),
	SidebarTransparency = 0.7,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.97,
	InputBackgroundColor = Color3.fromRGB(46, 39, 33),
	InputBackgroundTransparency = 0.13,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(196, 168, 132),
	StrokeTransparency = 0.9,
	PrimaryColor = Color3.fromRGB(186, 138, 84),
	SecondaryColor = Color3.fromRGB(112, 86, 62),
	TertiaryColor = Color3.fromRGB(150, 132, 114),
	Undercolor = Color3.fromRGB(56, 47, 39),
	AccentColor = Color3.fromRGB(214, 162, 100),

	PrimaryTextColor = Color3.fromRGB(244, 236, 226),
	PrimaryTextTransparency = 0.1,
	SecondaryTextColor = Color3.fromRGB(186, 168, 150),
	SecondaryTextTransparency = 0.4,
	TitleTextColor = Color3.fromRGB(249, 242, 232),
	InactiveTabTextColor = Color3.fromRGB(186, 168, 150),
	InactiveTabIconColor = Color3.fromRGB(186, 168, 150),
	ActiveTabTextColor = Color3.fromRGB(249, 242, 232),
	ActiveTabIconColor = Color3.fromRGB(249, 242, 232),
	ActiveTabTextTransparency = 0.2,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.2,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(214, 162, 100),
	ActiveTabButtonTransparency = 0.85,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.975,
	SectionStrokeColor = Color3.fromRGB(196, 168, 132),
	SectionStrokeTransparency = 0.95,
	SectionDividerColor = Color3.fromRGB(150, 132, 114),
	SectionDividerTransparency = 0.9,
	SearchBarBackgroundColor = Color3.fromRGB(46, 39, 33),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(33, 28, 24),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(56, 47, 39),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(244, 236, 226),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Linen: neutral warm grey, light. Warm off-white paper with a slate accent,
-- the calm default for anyone who doesn't want their UI to have a mood.
ThemeDefinitions.Linen = {
	WindowColor = Color3.fromRGB(248, 247, 244),
	WindowTransparency = 0.18,
	ContentBackgroundColor = Color3.fromRGB(252, 251, 249),
	ContentBackgroundTransparency = 0,
	MainframeShadowColor = Color3.fromRGB(178, 172, 162),

	SidebarColor = Color3.fromRGB(240, 238, 234),
	SidebarTransparency = 0.58,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.06,
	InputBackgroundColor = Color3.fromRGB(240, 238, 234),
	InputBackgroundTransparency = 0,
	ComponentShadowColor = Color3.fromRGB(178, 172, 162),
	StrokeColor = Color3.fromRGB(212, 206, 196),
	StrokeTransparency = 0.78,
	PrimaryColor = Color3.fromRGB(84, 96, 112),
	SecondaryColor = Color3.fromRGB(186, 180, 170),
	TertiaryColor = Color3.fromRGB(168, 162, 152),
	Undercolor = Color3.fromRGB(232, 228, 222),
	AccentColor = Color3.fromRGB(96, 110, 128),

	PrimaryTextColor = Color3.fromRGB(42, 40, 37),
	PrimaryTextTransparency = 0,
	SecondaryTextColor = Color3.fromRGB(118, 112, 104),
	SecondaryTextTransparency = 0.12,
	TitleTextColor = Color3.fromRGB(42, 40, 37),
	InactiveTabTextColor = Color3.fromRGB(118, 112, 104),
	InactiveTabIconColor = Color3.fromRGB(118, 112, 104),
	ActiveTabTextColor = Color3.fromRGB(42, 40, 37),
	ActiveTabIconColor = Color3.fromRGB(42, 40, 37),
	ActiveTabTextTransparency = 0,
	InactiveTabTextTransparency = 0.28,
	ActiveTabIconTransparency = 0,
	InactiveTabIconTransparency = 0.28,
	ActiveTabButtonColor = Color3.fromRGB(96, 110, 128),
	ActiveTabButtonTransparency = 0.88,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.4,
	SectionStrokeColor = Color3.fromRGB(212, 206, 196),
	SectionStrokeTransparency = 0.84,
	SectionDividerColor = Color3.fromRGB(206, 200, 190),
	SectionDividerTransparency = 0.5,
	SearchBarBackgroundColor = Color3.fromRGB(240, 238, 234),
	SearchBarBackgroundTransparency = 0,

	PopupBackgroundColor = Color3.fromRGB(252, 251, 249),
	PopupBackgroundTransparency = 0.05,
	PopupNeutralColor = Color3.fromRGB(232, 228, 222),
	PopupShadowColor = Color3.fromRGB(178, 172, 162),
	PopupTextColor = Color3.fromRGB(42, 40, 37),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Slate: cool blue-grey dark mode. Navy chrome under the storm mountains,
-- steel-blue accent instead of flat grey.
ThemeDefinitions.Slate = {
	WindowColor = Color3.fromRGB(15, 18, 24),
	WindowTransparency = 0.13,
	ContentBackgroundColor = Color3.fromRGB(20, 24, 31),
	ContentBackgroundTransparency = 0.08,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(25, 29, 37),
	SidebarTransparency = 0.7,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.965,
	InputBackgroundColor = Color3.fromRGB(34, 39, 48),
	InputBackgroundTransparency = 0.12,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.91,
	PrimaryColor = Color3.fromRGB(122, 156, 214),
	SecondaryColor = Color3.fromRGB(74, 95, 130),
	TertiaryColor = Color3.fromRGB(108, 132, 170),
	Undercolor = Color3.fromRGB(40, 46, 57),
	AccentColor = Color3.fromRGB(158, 194, 252),

	PrimaryTextColor = Color3.fromRGB(235, 239, 246),
	PrimaryTextTransparency = 0.08,
	SecondaryTextColor = Color3.fromRGB(150, 163, 186),
	SecondaryTextTransparency = 0.38,
	TitleTextColor = Color3.fromRGB(246, 248, 252),
	InactiveTabTextColor = Color3.fromRGB(150, 163, 186),
	InactiveTabIconColor = Color3.fromRGB(150, 163, 186),
	ActiveTabTextColor = Color3.fromRGB(246, 248, 252),
	ActiveTabIconColor = Color3.fromRGB(246, 248, 252),
	ActiveTabTextTransparency = 0.18,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.18,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(158, 194, 252),
	ActiveTabButtonTransparency = 0.86,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.972,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.95,
	SectionDividerColor = Color3.fromRGB(74, 95, 130),
	SectionDividerTransparency = 0.88,
	SearchBarBackgroundColor = Color3.fromRGB(34, 39, 48),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(20, 24, 31),
	PopupBackgroundTransparency = 0.04,
	PopupNeutralColor = Color3.fromRGB(40, 46, 57),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(235, 239, 246),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Onyx: midnight blue dark mode. Near-black navy chrome under the night
-- peaks, electric blue accent.
ThemeDefinitions.Onyx = {
	WindowColor = Color3.fromRGB(11, 13, 20),
	WindowTransparency = 0.12,
	ContentBackgroundColor = Color3.fromRGB(15, 18, 27),
	ContentBackgroundTransparency = 0.08,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(20, 24, 35),
	SidebarTransparency = 0.7,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.965,
	InputBackgroundColor = Color3.fromRGB(28, 33, 47),
	InputBackgroundTransparency = 0.12,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.91,
	PrimaryColor = Color3.fromRGB(96, 140, 240),
	SecondaryColor = Color3.fromRGB(58, 84, 150),
	TertiaryColor = Color3.fromRGB(94, 117, 166),
	Undercolor = Color3.fromRGB(33, 39, 55),
	AccentColor = Color3.fromRGB(130, 172, 255),

	PrimaryTextColor = Color3.fromRGB(238, 241, 248),
	PrimaryTextTransparency = 0.08,
	SecondaryTextColor = Color3.fromRGB(148, 160, 190),
	SecondaryTextTransparency = 0.38,
	TitleTextColor = Color3.fromRGB(250, 251, 253),
	InactiveTabTextColor = Color3.fromRGB(148, 160, 190),
	InactiveTabIconColor = Color3.fromRGB(148, 160, 190),
	ActiveTabTextColor = Color3.fromRGB(250, 251, 253),
	ActiveTabIconColor = Color3.fromRGB(250, 251, 253),
	ActiveTabTextTransparency = 0.18,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.18,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(130, 172, 255),
	ActiveTabButtonTransparency = 0.86,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.972,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.95,
	SectionDividerColor = Color3.fromRGB(58, 84, 150),
	SectionDividerTransparency = 0.88,
	SearchBarBackgroundColor = Color3.fromRGB(28, 33, 47),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(15, 18, 27),
	PopupBackgroundTransparency = 0.04,
	PopupNeutralColor = Color3.fromRGB(33, 39, 55),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(238, 241, 248),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Ash: soft smoke lifted with violet. The lighter dark of the five, lilac
-- accent over warm-grey smoke.
ThemeDefinitions.Ash = {
	WindowColor = Color3.fromRGB(33, 31, 38),
	WindowTransparency = 0.14,
	ContentBackgroundColor = Color3.fromRGB(39, 37, 45),
	ContentBackgroundTransparency = 0.06,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(45, 43, 52),
	SidebarTransparency = 0.7,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.965,
	InputBackgroundColor = Color3.fromRGB(55, 52, 63),
	InputBackgroundTransparency = 0.12,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.91,
	PrimaryColor = Color3.fromRGB(158, 144, 200),
	SecondaryColor = Color3.fromRGB(124, 116, 146),
	TertiaryColor = Color3.fromRGB(144, 136, 168),
	Undercolor = Color3.fromRGB(60, 57, 69),
	AccentColor = Color3.fromRGB(198, 186, 236),

	PrimaryTextColor = Color3.fromRGB(239, 236, 244),
	PrimaryTextTransparency = 0.08,
	SecondaryTextColor = Color3.fromRGB(176, 170, 190),
	SecondaryTextTransparency = 0.38,
	TitleTextColor = Color3.fromRGB(248, 246, 250),
	InactiveTabTextColor = Color3.fromRGB(176, 170, 190),
	InactiveTabIconColor = Color3.fromRGB(176, 170, 190),
	ActiveTabTextColor = Color3.fromRGB(248, 246, 250),
	ActiveTabIconColor = Color3.fromRGB(248, 246, 250),
	ActiveTabTextTransparency = 0.18,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.18,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(198, 186, 236),
	ActiveTabButtonTransparency = 0.86,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.972,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.95,
	SectionDividerColor = Color3.fromRGB(124, 116, 146),
	SectionDividerTransparency = 0.88,
	SearchBarBackgroundColor = Color3.fromRGB(55, 52, 63),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(39, 37, 45),
	PopupBackgroundTransparency = 0.04,
	PopupNeutralColor = Color3.fromRGB(60, 57, 69),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(239, 236, 244),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Gunmetal: dark steel with a teal edge. Machined blue-grey chrome against
-- the alpine dusk, teal accent.
ThemeDefinitions.Gunmetal = {
	WindowColor = Color3.fromRGB(14, 18, 21),
	WindowTransparency = 0.13,
	ContentBackgroundColor = Color3.fromRGB(19, 24, 28),
	ContentBackgroundTransparency = 0.08,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(24, 30, 35),
	SidebarTransparency = 0.7,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.965,
	InputBackgroundColor = Color3.fromRGB(32, 40, 46),
	InputBackgroundTransparency = 0.12,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.91,
	PrimaryColor = Color3.fromRGB(94, 168, 178),
	SecondaryColor = Color3.fromRGB(70, 114, 124),
	TertiaryColor = Color3.fromRGB(96, 140, 150),
	Undercolor = Color3.fromRGB(38, 47, 54),
	AccentColor = Color3.fromRGB(126, 204, 212),

	PrimaryTextColor = Color3.fromRGB(234, 240, 241),
	PrimaryTextTransparency = 0.08,
	SecondaryTextColor = Color3.fromRGB(148, 172, 176),
	SecondaryTextTransparency = 0.38,
	TitleTextColor = Color3.fromRGB(245, 249, 250),
	InactiveTabTextColor = Color3.fromRGB(148, 172, 176),
	InactiveTabIconColor = Color3.fromRGB(148, 172, 176),
	ActiveTabTextColor = Color3.fromRGB(245, 249, 250),
	ActiveTabIconColor = Color3.fromRGB(245, 249, 250),
	ActiveTabTextTransparency = 0.18,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.18,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(126, 204, 212),
	ActiveTabButtonTransparency = 0.86,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.972,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.95,
	SectionDividerColor = Color3.fromRGB(70, 114, 124),
	SectionDividerTransparency = 0.88,
	SearchBarBackgroundColor = Color3.fromRGB(32, 40, 46),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(19, 24, 28),
	PopupBackgroundTransparency = 0.04,
	PopupNeutralColor = Color3.fromRGB(38, 47, 54),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(234, 240, 241),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Charcoal: warm dark grey with an ember accent. Smoke surfaces over the
-- lava glow, orange where Graphite keeps blue.
ThemeDefinitions.Charcoal = {
	WindowColor = Color3.fromRGB(26, 23, 22),
	WindowTransparency = 0.13,
	ContentBackgroundColor = Color3.fromRGB(32, 29, 28),
	ContentBackgroundTransparency = 0.08,
	MainframeShadowColor = Color3.fromRGB(0, 0, 0),

	SidebarColor = Color3.fromRGB(37, 34, 33),
	SidebarTransparency = 0.7,

	ComponentBackgroundColor = Color3.fromRGB(255, 255, 255),
	ComponentBackgroundTransparency = 0.965,
	InputBackgroundColor = Color3.fromRGB(46, 42, 41),
	InputBackgroundTransparency = 0.12,
	ComponentShadowColor = Color3.fromRGB(0, 0, 0),
	StrokeColor = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.91,
	PrimaryColor = Color3.fromRGB(214, 134, 74),
	SecondaryColor = Color3.fromRGB(146, 104, 76),
	TertiaryColor = Color3.fromRGB(168, 124, 94),
	Undercolor = Color3.fromRGB(52, 48, 46),
	AccentColor = Color3.fromRGB(255, 166, 96),

	PrimaryTextColor = Color3.fromRGB(243, 238, 234),
	PrimaryTextTransparency = 0.08,
	SecondaryTextColor = Color3.fromRGB(188, 168, 156),
	SecondaryTextTransparency = 0.38,
	TitleTextColor = Color3.fromRGB(250, 246, 242),
	InactiveTabTextColor = Color3.fromRGB(188, 168, 156),
	InactiveTabIconColor = Color3.fromRGB(188, 168, 156),
	ActiveTabTextColor = Color3.fromRGB(250, 246, 242),
	ActiveTabIconColor = Color3.fromRGB(250, 246, 242),
	ActiveTabTextTransparency = 0.18,
	InactiveTabTextTransparency = 0.5,
	ActiveTabIconTransparency = 0.18,
	InactiveTabIconTransparency = 0.5,
	ActiveTabButtonColor = Color3.fromRGB(255, 166, 96),
	ActiveTabButtonTransparency = 0.86,
	InactiveTabButtonColor = Color3.fromRGB(255, 255, 255),
	InactiveTabButtonTransparency = 1,

	SectionBackgroundColor = Color3.fromRGB(255, 255, 255),
	SectionBackgroundTransparency = 0.972,
	SectionStrokeColor = Color3.fromRGB(255, 255, 255),
	SectionStrokeTransparency = 0.95,
	SectionDividerColor = Color3.fromRGB(146, 104, 76),
	SectionDividerTransparency = 0.88,
	SearchBarBackgroundColor = Color3.fromRGB(46, 42, 41),
	SearchBarBackgroundTransparency = 0.5,

	PopupBackgroundColor = Color3.fromRGB(32, 29, 28),
	PopupBackgroundTransparency = 0.04,
	PopupNeutralColor = Color3.fromRGB(52, 48, 46),
	PopupShadowColor = Color3.fromRGB(0, 0, 0),
	PopupTextColor = Color3.fromRGB(243, 238, 234),
	PopupTextTransparency = 0.2,

	Wallpaper = nil,
	WallpaperEnabled = true,
}

-- Wallpaper asset ids per theme; the tab/backdrop images use them when present.
local WALLPAPERS = {
	Base = "rbxassetid://126475867393987",
	Umbral = "rbxassetid://108134687422467",
	Ember = "rbxassetid://112056619173488",
	Vesper = "rbxassetid://139008744622245",
	Duskfall = "rbxassetid://84448785488489",
	Canopy = "rbxassetid://117265363863813",
	Tidewater = "rbxassetid://135568871834704",
	Nocturne = "rbxassetid://95435913199118",
	Solace = "rbxassetid://92445107726358",
	Cielo = "rbxassetid://98569091830887",
	Honey = "rbxassetid://73850635447680",
	Dawn = "rbxassetid://88171125327716",
	Alpine = "rbxassetid://123969479560901",
	Peony = "rbxassetid://131979800493713",
	Sakura = "rbxassetid://83848197180836",
	Blush = "rbxassetid://8350591200",
	Cinder = "rbxassetid://91682462344785",
	Mauve = "rbxassetid://129556634773235",
	Iris = "rbxassetid://74675854421559",
	Sundown = "rbxassetid://80301124180881",
	Twilight = "rbxassetid://110295134647166",
	Nebula = "rbxassetid://110937489750863",
	Monterey = "rbxassetid://126475867393987",
	Sonoma = "rbxassetid://114699504726298",
	Ventura = "rbxassetid://100629172964437",
	Vermilion = "rbxassetid://18571374017",
	Grove = "rbxassetid://116321051235221",
	Prism = "rbxassetid://78613064348772",
	Sage = "rbxassetid://97394507475736",
	Blossom = "rbxassetid://13426533185317",
	Petal = "rbxassetid://119516266319751",
	Frost = "rbxassetid://81270141924137",
	Amber = "rbxassetid://79886157813963",
	Rosa = "rbxassetid://107522899082679",
	Gruvbox = "rbxassetid://73850635447680",
	Graphite = "rbxassetid://126475867393987",
	Crimson = "rbxassetid://112056619173488",
	Umber = "rbxassetid://88171125327716",
	Mint = "rbxassetid://116321051235221",
	Lilac = "rbxassetid://100629172964437",
	Linen = "rbxassetid://98569091830887",
	Slate = "rbxassetid://126475867393987",
	Onyx = "rbxassetid://108134687422467",
	Ash = "rbxassetid://88171125327716",
	Gunmetal = "rbxassetid://123969479560901",
	Charcoal = "rbxassetid://91682462344785",
}

-- Wire each wallpaper id onto its theme so the render path picks it up.
for name, assetId in pairs(WALLPAPERS) do
	if ThemeDefinitions[name] then
		ThemeDefinitions[name].Wallpaper = assetId
	end
end

-- Window control icon colors: dark themes get light icons and vice versa so they stay visible.
local WINDOW_CONTROLS = {
	Base = Color3.fromRGB(255, 255, 255),
	Umbral = Color3.fromRGB(226, 232, 240),
	Ember = Color3.fromRGB(238, 214, 196),
	Vesper = Color3.fromRGB(214, 206, 234),
	Duskfall = Color3.fromRGB(240, 214, 190),
	Canopy = Color3.fromRGB(206, 232, 210),
	Tidewater = Color3.fromRGB(200, 232, 240),
	Nocturne = Color3.fromRGB(238, 214, 244),
	Solace = Color3.fromRGB(40, 58, 80),
	Cielo = Color3.fromRGB(36, 52, 84),
	Honey = Color3.fromRGB(120, 96, 60),
	Dawn = Color3.fromRGB(128, 96, 98),
	Alpine = Color3.fromRGB(48, 72, 104),
	Peony = Color3.fromRGB(150, 88, 92),
	Sakura = Color3.fromRGB(154, 90, 108),
	Blush = Color3.fromRGB(128, 82, 98),
	Cinder = Color3.fromRGB(246, 238, 232),
	Mauve = Color3.fromRGB(242, 238, 250),
	Iris = Color3.fromRGB(240, 238, 252),
	Sundown = Color3.fromRGB(248, 238, 236),
	Twilight = Color3.fromRGB(238, 240, 250),
	Nebula = Color3.fromRGB(242, 236, 252),
	Monterey = Color3.fromRGB(238, 240, 246),
	Sonoma = Color3.fromRGB(246, 240, 234),
	Ventura = Color3.fromRGB(240, 238, 248),
	Vermilion = Color3.fromRGB(248, 238, 236),
	Grove = Color3.fromRGB(236, 246, 240),
	Prism = Color3.fromRGB(240, 243, 252),
	Sage = Color3.fromRGB(30, 48, 36),
	Blossom = Color3.fromRGB(60, 30, 42),
	Petal = Color3.fromRGB(58, 28, 40),
	Frost = Color3.fromRGB(28, 40, 58),
	Amber = Color3.fromRGB(58, 42, 22),
	Rosa = Color3.fromRGB(58, 30, 42),
	Gruvbox = Color3.fromRGB(246, 238, 224),
	Graphite = Color3.fromRGB(240, 242, 246),
	Crimson = Color3.fromRGB(250, 230, 236),
	Umber = Color3.fromRGB(248, 238, 224),
	Mint = Color3.fromRGB(30, 58, 48),
	Lilac = Color3.fromRGB(40, 34, 66),
	Linen = Color3.fromRGB(44, 42, 38),
	Slate = Color3.fromRGB(234, 238, 244),
	Onyx = Color3.fromRGB(232, 238, 250),
	Ash = Color3.fromRGB(242, 238, 250),
	Gunmetal = Color3.fromRGB(230, 244, 244),
	Charcoal = Color3.fromRGB(250, 240, 232),
}

for name, controlColor in pairs(WINDOW_CONTROLS) do
	if ThemeDefinitions[name] then
		ThemeDefinitions[name].WindowControlColor = controlColor
	end
end

-- Per-theme transparency as { WindowTransparency, SidebarTransparency, ContentBackgroundTransparency }; never both the sidebar and the content washed out.
local THEME_TRANSPARENCY = {
	-- Profiles: A = deeply frosted sidebar with a faint content tint, B = frosted sidebar with opaque content, C = solid sidebar with translucent content.

	-- Profile A: flagship darks.
	Base = { 0.15, 0.72, 0.1 },
	Umbral = { 0.15, 0.72, 0.1 },
	Nocturne = { 0.15, 0.72, 0.1 },

	-- Profile B: frosted sidebar, opaque content.
	Ember = { 0.22, 0.62, 0 },
	Solace = { 0.22, 0.62, 0 },
	Cielo = { 0.22, 0.62, 0 },
	Honey = { 0.22, 0.62, 0 },
	Dawn = { 0.22, 0.62, 0 },
	Blush = { 0.22, 0.62, 0 },

	-- Profile C: solid sidebar, translucent content.
	Vesper = { 0.28, 0, 0.42 },
	Duskfall = { 0.28, 0, 0.42 },
	Canopy = { 0.28, 0, 0.42 },
	Tidewater = { 0.28, 0, 0.42 },
	Alpine = { 0.28, 0, 0.42 },
	Peony = { 0.28, 0, 0.42 },
	Sakura = { 0.28, 0, 0.42 },
	Cinder = { 0.22, 0.62, 0 },
	Mauve = { 0.28, 0, 0.42 },
	Iris = { 0.28, 0, 0.42 },
	Sundown = { 0.28, 0, 0.42 },
	Twilight = { 0.28, 0, 0.42 },
	Nebula = { 0.15, 0.72, 0.1 },
	Monterey = { 0.15, 0.72, 0.1 },
	Sonoma = { 0.22, 0.62, 0 },
	Ventura = { 0.28, 0, 0.42 },
	Vermilion = { 0.28, 0, 0.42 },
	Grove = { 0.28, 0, 0.42 },
	Prism = { 0.22, 0.62, 0 },
	Sage = { 0.22, 0.62, 0 },
	Blossom = { 0.28, 0, 0.42 },
	Petal = { 0.28, 0, 0.42 },
	Frost = { 0.22, 0.62, 0 },
	Amber = { 0.22, 0.62, 0 },
	Rosa = { 0.28, 0, 0.42 },

	-- Darks take the frosted-sidebar profiles; the light additions take B.
	Gruvbox = { 0.22, 0.62, 0 },
	Graphite = { 0.15, 0.72, 0.1 },
	Crimson = { 0.22, 0.62, 0 },
	Umber = { 0.22, 0.62, 0 },
	Mint = { 0.22, 0.62, 0 },
	Lilac = { 0.22, 0.62, 0 },
	Linen = { 0.22, 0.62, 0 },
	Slate = { 0.15, 0.72, 0.1 },
	Onyx = { 0.15, 0.72, 0.1 },
	Ash = { 0.22, 0.62, 0 },
	Gunmetal = { 0.22, 0.62, 0 },
	Charcoal = { 0.22, 0.62, 0 },
}

for name, t in pairs(THEME_TRANSPARENCY) do
	local def = ThemeDefinitions[name]
	if def then
		def.WindowTransparency = t[1]
		def.SidebarTransparency = t[2]
		def.ContentBackgroundTransparency = t[3]
	end
end

-- Lift each theme's chrome off flat black/white with a small amount of its own accent; surfaces stay neutral enough for text.
local DARK_SURFACE_TINT = {
	Window = 0.045,
	Sidebar = 0.085,
	Content = 0.05,
	Input = 0.075,
	Popup = 0.06,
	Neutral = 0.08,
	Under = 0.07,
	Search = 0.07,
	Stroke = 0.1,
	Text = 0.04,
	SecondaryText = 0.07,
	Tertiary = 0.16,
}
local LIGHT_SURFACE_TINT = {
	Window = 0.025,
	Sidebar = 0.055,
	Content = 0.02,
	Input = 0.045,
	Popup = 0.03,
	Neutral = 0.05,
	Under = 0.04,
	Search = 0.045,
	Stroke = 0.12,
	Text = 0.055,
	SecondaryText = 0.08,
	Tertiary = 0.16,
}

local function luminance(color)
	return 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
end

for name, def in pairs(ThemeDefinitions) do
	if name ~= "Base" then
		local accent = def.AccentColor or def.PrimaryColor
		local dark = luminance(def.WindowColor) < 0.4
		local amounts = dark and DARK_SURFACE_TINT or LIGHT_SURFACE_TINT
		def.WindowColor = def.WindowColor:Lerp(accent, amounts.Window)
		def.SidebarColor = def.SidebarColor:Lerp(accent, amounts.Sidebar)
		def.ContentBackgroundColor = def.ContentBackgroundColor:Lerp(accent, amounts.Content)
		def.InputBackgroundColor = def.InputBackgroundColor:Lerp(accent, amounts.Input)
		def.PopupBackgroundColor = def.PopupBackgroundColor:Lerp(accent, amounts.Popup)
		def.PopupNeutralColor = def.PopupNeutralColor:Lerp(accent, amounts.Neutral)
		def.Undercolor = def.Undercolor:Lerp(accent, amounts.Under)
		def.SearchBarBackgroundColor = def.SearchBarBackgroundColor:Lerp(accent, amounts.Search)
		def.StrokeColor = def.StrokeColor:Lerp(accent, amounts.Stroke)
		def.PrimaryTextColor = def.PrimaryTextColor:Lerp(accent, amounts.Text)
		def.SecondaryTextColor = def.SecondaryTextColor:Lerp(accent, amounts.SecondaryText)
		def.TitleTextColor = def.TitleTextColor:Lerp(accent, amounts.Text)
		def.PopupTextColor = def.PopupTextColor:Lerp(accent, amounts.Text)
		def.TertiaryColor = def.TertiaryColor:Lerp(accent, amounts.Tertiary)
	end
end

-- Notifications derive their surface colors from each theme's popup/text colors so every theme stays coherent.
for _, t in pairs(ThemeDefinitions) do
	if t.NotificationBackgroundColor == nil then
		t.NotificationBackgroundColor = t.PopupBackgroundColor or t.WindowColor
		t.NotificationBackgroundTransparency = math.clamp((t.PopupBackgroundTransparency or 0) + 0.1, 0, 1)
		-- Shadow depth follows the surface so light themes don't get a soot-black halo.
		local surface = t.NotificationBackgroundColor
		local shadowDepth = luminance(surface) < 0.4 and 0.7 or 0.42
		t.NotificationShadowColor = surface:Lerp(Color3.fromRGB(0, 0, 0), shadowDepth)
		t.NotificationStrokeColor = t.StrokeColor or Color3.fromRGB(148, 163, 184)
		t.NotificationStrokeTransparency = 0.86
		t.NotificationHeaderColor = t.TitleTextColor or t.PopupTextColor or Color3.fromRGB(255, 255, 255)
		t.NotificationHeaderTransparency = 0.2
		t.NotificationTextColor = t.SecondaryTextColor or t.PopupTextColor or Color3.fromRGB(226, 232, 240)
		t.NotificationTextTransparency = 0.4
		t.NotificationDividerColor = t.TertiaryColor or Color3.fromRGB(148, 163, 184)
		t.NotificationDividerTransparency = 0.7
		t.NotificationDismissColor = t.SecondaryTextColor or Color3.fromRGB(203, 213, 225)
		t.NotificationActionButtonColor = t.InputBackgroundColor or t.PopupNeutralColor or Color3.fromRGB(51, 65, 85)
		t.NotificationActionButtonTextColor = t.PopupTextColor or Color3.fromRGB(241, 245, 249)
		-- Alert/Error keep their warning and danger read, tinted toward each theme's accent.
		local notifAccent = t.AccentColor or t.PrimaryColor or Color3.new(1, 1, 1)
		t.NotificationAlertAccent = Color3.fromRGB(249, 115, 22):Lerp(notifAccent, 0.25)
		t.NotificationErrorAccent = Color3.fromRGB(226, 42, 42):Lerp(notifAccent, 0.25)
		-- The card washes sit deeper in the theme so alerts feel themed first and alarming second.
		t.NotificationAlertAurora = Color3.fromRGB(249, 115, 22):Lerp(notifAccent, 0.6)
		t.NotificationErrorAurora = Color3.fromRGB(226, 42, 42):Lerp(notifAccent, 0.6)
		t.NotificationVariableAccent = t.PrimaryColor or Color3.fromRGB(74, 200, 120)
	end
end

-- Each theme gets its own section-card tint (popup/window surface blended toward the accent) and opacity, from fully opaque to nearly transparent.
local SECTION_OPACITY = {
	Base = 0.86,
	Umbral = 0.88,
	Ember = 0.80,
	Vesper = 0.66,
	Duskfall = 0.72,
	Canopy = 0.78,
	Tidewater = 0.80,
	Nocturne = 0.86,
	Solace = 0.58,
	Cielo = 0.60,
	Honey = 0.52,
	Dawn = 0.55,
	Alpine = 0.62,
	Peony = 0.68,
	Sakura = 0.70,
	Blush = 0.64,
	Cinder = 0.08,
	Mauve = 0.46,
	Iris = 0.48,
	Sundown = 0.52,
	Twilight = 0.50,
	Nebula = 0.84,
	Monterey = 0.85,
	Sonoma = 0.54,
	Ventura = 0.48,
	Vermilion = 0.56,
	Grove = 0.60,
	Prism = 0.14,
	Sage = 0.10,
	Blossom = 0.62,
	Petal = 0.64,
	Frost = 0.06,
	Amber = 0.12,
	Rosa = 0.62,
	Gruvbox = 0.08,
	Graphite = 0.10,
	Crimson = 0.08,
	Umber = 0.09,
	Mint = 0.12,
	Lilac = 0.14,
	Linen = 0.08,
	Slate = 0.10,
	Onyx = 0.08,
	Ash = 0.12,
	Gunmetal = 0.10,
	Charcoal = 0.11,
}
local SECTION_TINT = 0.12

local function blendColor(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

for name, def in pairs(ThemeDefinitions) do
	local opacity = SECTION_OPACITY[name] or 0.7
	local base = def.PopupBackgroundColor or def.WindowColor or Color3.fromRGB(20, 20, 22)
	local accent = def.AccentColor or def.PrimaryColor or Color3.fromRGB(108, 140, 255)
	def.SectionBackgroundColor = blendColor(base, accent, SECTION_TINT)
	def.SectionBackgroundTransparency = opacity
	-- Border leans further toward the accent so the card edge reads as part of the same theme.
	def.SectionStrokeColor = blendColor(base, accent, SECTION_TINT * 1.8)
	if def.SectionStrokeTransparency == nil then
		def.SectionStrokeTransparency = 0.9
	end
end

-- Component containers get a white-to-accent wash: dark themes read as a subtle raised card, light themes as a near-opaque tinted well.
local COMPONENT_WASH_TINT_DARK = 0.18
local COMPONENT_WASH_TINT_LIGHT = 0.12
local WHITE = Color3.fromRGB(255, 255, 255)
for _, def in pairs(ThemeDefinitions) do
	local accent = def.AccentColor or def.PrimaryColor or Color3.fromRGB(108, 140, 255)
	local surface = def.WindowColor or Color3.fromRGB(24, 24, 27)
	local dark = luminance(surface) < 0.4
	def.ComponentBackgroundColor =
		blendColor(WHITE, accent, dark and COMPONENT_WASH_TINT_DARK or COMPONENT_WASH_TINT_LIGHT)
	def.ComponentBackgroundTransparency = dark and 0.9 or 0.06
end

return ThemeDefinitions
