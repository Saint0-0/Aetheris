--[[
	Aetheris/Core/UIChangelog.luau

	Library release notes shown once per version, separate from the
	script-provided Changelog. Bump Version whenever entries ship.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local UIChangelog = {}

-- Compared against the stored UIChangeLogVersion to gate the auto-show.
UIChangelog.Version = "1.2.0"

UIChangelog.Entries = {
	{
		Title = "Aetheris changelog",
		Description = "The library keeps its own changelog and shows it once per version, with a button in Settings to open it again.",
		Icon = "scroll-text",
		Tint = "yellow",
	},
	{
		Title = "Carousel",
		Description = "New Carousel component for image and video pages: drag or let it auto-advance, with dots that double as playback progress.",
		Icon = "images",
		Tint = "blue",
	},
	{
		Title = "Colour picker",
		Description = "New ColorPicker component and popup: SV square, hue and alpha bars, preset and recent swatches, plus hex entry.",
		Icon = "palette",
		Tint = "purple",
	},
	{
		Title = "One popup at a time",
		Description = "Opening a popup closes the one before it, and clicking away confirms a colour pick or dismisses the rest.",
		Icon = "layers",
		Tint = "teal",
	},
	{
		Title = "Dropdown values",
		Description = "Dropdown rows now show the picked values beside the label, so a closed dropdown still reads as selected.",
		Icon = "chevrons-up-down",
		Tint = "orange",
	},
	{
		Title = "Locale applies live",
		Description = "Spanish and Portuguese now switch every chrome string the moment you pick them in UI Settings, no relaunch.",
		Icon = "languages",
		Tint = "blue",
	},
	{
		Title = "Changelog popup",
		Description = "New Version and Changelog keys in CreateWindow: the script's own release notes open once per version.",
		Icon = "rocket",
		Tint = "purple",
	},
	{
		Title = "Viewport options",
		Description = "HealthBar = false drops the side bar, and an Info table is now the opt-in for the info column (ShowInfo is gone).",
		Icon = "list-checks",
		Tint = "teal",
	},
}

return UIChangelog
