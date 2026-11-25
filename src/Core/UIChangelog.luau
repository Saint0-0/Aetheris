--[[
	Aetheris/Core/UIChangelog.luau

	Library release notes shown once per version, separate from the
	script-provided Changelog. Bump Version whenever entries ship.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local UIChangelog = {}

-- Compared against the stored UIChangeLogVersion to gate the auto-show.
UIChangelog.Version = "1.7.0"

UIChangelog.Entries = {
	{
		Title = "Theme Creator",
		Description = "A new settings page builds custom palettes from 17 colour pickers, grouped into Brand, Surfaces, Text and Borders. Load a base preset, tune each surface, then save the result to Aetheris/Custom Themes as JSON. Saved themes join the theme gallery and the theme switch.",
		Icon = "paintbrush",
		Tint = "purple",
	},
	{
		Title = "Live theme preview",
		Description = "Preview Theme opens a miniature Aetheris window that reflects every edit as you make it. It fades in with the shared popup cue, dismisses on an outside click and closes from its title-bar button.",
		Icon = "palette",
		Tint = "blue",
	},
	{
		Title = "Local and GitHub wallpapers",
		Description = "Theme wallpapers now check Aetheris/Wallpapers first, then the repository's assets/wallpapers folder, and fall back to the built-in assets. The creator lists only local image files and keeps the name field and dropdown in sync.",
		Icon = "wallpaper",
		Tint = "teal",
	},
	{
		Title = "Single-select dropdowns",
		Description = "The base preset, wallpaper and saved-theme pickers now allow one selection at a time, so loading a preset replaces the previous pick instead of stacking values.",
		Icon = "chevrons-up-down",
		Tint = "orange",
	},
	{
		Title = "Saved themes stay current",
		Description = "Re-saving a custom theme refreshes its gallery card in place with the new colours, copy and wallpaper, instead of leaving stale visuals behind. Custom entries also sort deterministically.",
		Icon = "images",
		Tint = "teal",
	},
	{
		Title = "Popup polish",
		Description = "Every popup now shares the changelog-style close button, a single-at-a-time rule and the same fade timing. The theme preview matches the dropdown's open and close behaviour exactly.",
		Icon = "layers",
		Tint = "purple",
	},
	{
		Title = "Fading video and viewports",
		Description = "VideoFrames sit in a media CanvasGroup and ViewportFrames fade through their own ImageTransparency, so page switches and the carousel crossfade fade the rendered media itself instead of letting it pop in or out.",
		Icon = "video",
		Tint = "blue",
	},
	{
		Title = "Crisp fades",
		Description = "Page and window transitions no longer composite through a CanvasGroup, whose 1024px texture cap blurred wide windows and tall sections. A tree fade walks each element's own transparency instead, so text stays sharp at any size.",
		Icon = "sparkles",
		Tint = "blue",
	},
	{
		Title = "Data Table popup",
		Description = "section:DataTable is now a compact field card that opens a searchable, sortable table in a modal popup. The popup plays the shared open cue and keeps the full row API unchanged.",
		Icon = "table",
		Tint = "teal",
	},
	{
		Title = "Stat cards redesigned",
		Description = "LiveStat keeps its rolling values and direction tint but now sits on a neutral card with a soft accent wash, accent bar, icon tile and a change chip instead of a solid coloured fill.",
		Icon = "activity",
		Tint = "teal",
	},
	{
		Title = "Carousel crossfade",
		Description = "The carousel stacks its pages and crossfades between them; clicking cycles forward. The indicator is a frosted capsule with an elongating active pill and playback progress.",
		Icon = "gallery-horizontal",
		Tint = "purple",
	},
	{
		Title = "Theme card hover",
		Description = "Gallery cards lift by whole pixels on hover and press with the standard enter and release timing, avoiding the blurry text that UIScale caused at fractional scales.",
		Icon = "move",
		Tint = "blue",
	},
	{
		Title = "Config editor",
		Description = "The Configs page now has an editable JSON view: click the code, apply it to the UI, save it to a file, or paste a shared config from the clipboard. Saved files are pretty-printed with sorted keys.",
		Icon = "save",
		Tint = "teal",
	},
	{
		Title = "Search narrows components",
		Description = "Search fades sections and shows or hides individual components with a fade, instead of hiding whole sections only. Matches are highlighted in titles and descriptions.",
		Icon = "search",
		Tint = "teal",
	},
	{
		Title = "Hyperlinks and Info page",
		Description = "Paragraphs and Labels accept {label:page} and {label:copy} links. A new Info page links to the repo, Discord and creator, and copying confirms with a toast.",
		Icon = "link",
		Tint = "blue",
	},
	{
		Title = "Loading screen refresh",
		Description = "The key card now shows the running step in a status row with its own icon, a step counter and a live percent chip, over a thin progress rail and a task list that fills in with checks as each step finishes.",
		Icon = "loader-circle",
		Tint = "blue",
	},
	{
		Title = "Theme and wallpaper fixes",
		Description = "Custom theme names are trimmed and checked before saving, invalid base themes fall back to Base instead of breaking the palette, mixed-case wallpaper filenames resolve on case-sensitive filesystems, and the manual wallpaper placeholder is gone.",
		Icon = "wrench",
		Tint = "yellow",
	},
	{
		Title = "Live theme details",
		Description = "Pages switched while hidden restore the current theme, DataTable row hover returns to the live resting shade, and the minimize pill no longer scrolls past its last tab.",
		Icon = "palette",
		Tint = "orange",
	},
}

return UIChangelog
