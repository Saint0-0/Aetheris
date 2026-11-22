--[[
	Aetheris/Core/UIChangelog.luau

	Library release notes shown once per version, separate from the
	script-provided Changelog. Bump Version whenever entries ship.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local UIChangelog = {}

-- Compared against the stored UIChangeLogVersion to gate the auto-show.
UIChangelog.Version = "1.4.0"

UIChangelog.Entries = {
	{
		Title = "Config editor",
		Description = "The Configs page now has an editable JSON view: click the code, apply it to the UI, save it to a file, or paste a shared config from the clipboard. Saved files are pretty-printed with sorted keys.",
		Icon = "save",
		Tint = "teal",
	},
	{
		Title = "Config helpers",
		Description = "window.ConfigManager:Apply(json) restores component values from text without touching a file, and :Write(name, json) validates and saves editor JSON under a new name.",
		Icon = "clipboard",
		Tint = "purple",
	},
	{
		Title = "Hyperlinks and Info page",
		Description = "Paragraphs and Labels accept {label:page} and {label:copy} links. A new Info page links to the repo, Discord and creator, and copying confirms with a toast.",
		Icon = "link",
		Tint = "blue",
	},
	{
		Title = "Search narrows components",
		Description = "Search now fades sections and shows or hides individual components with a fade, instead of hiding whole sections only. Matches are highlighted in titles and descriptions.",
		Icon = "search",
		Tint = "teal",
	},
	{
		Title = "Close and clipboard helpers",
		Description = "window:Close() closes from code, window:NavigateTo(name) jumps to a page, and window:CopyToClipboard(text, label) copies with feedback. CodeView copies without an OnCopy handler.",
		Icon = "clipboard",
		Tint = "purple",
	},
	{
		Title = "Live theme details",
		Description = "The changelog shadow follows theme switches, the dropdown select-all and clear buttons stay circular on resize, and search highlights repaint with the accent.",
		Icon = "palette",
		Tint = "orange",
	},
	{
		Title = "Lighter text work",
		Description = "Font objects are cached per family, weight and style, and locale lookups are memoized until the language changes.",
		Icon = "type",
		Tint = "yellow",
	},
	{
		Title = "Aetheris changelog",
		Description = "The library keeps its own changelog and shows it once per version, with a button on the new Info page to open it again.",
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
