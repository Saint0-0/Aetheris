--[[
	SettingsInit  ·  Aetheris UI Library

	Registers the default settings pages (Themes, then UI Settings) on a
	window's SettingsTabGroup. Called by Window.new via BuildDefaultPages;
	developer-added pages are appended afterwards from CreateWindow options.
]]

local Themes = require("./Themes")
local UISettings = require("./UISettings")

local SettingsInit = {}

function SettingsInit.BuildDefaultPages(window)
	local group = window.SettingsTabGroup

	local themesTab = group:Tab({
		Name = "Themes",
		Icon = "rbxassetid://86350350950064",
		Active = true,
	})
	Themes.Build(window, themesTab)

	local uiTab = group:Tab({
		Name = "UI Settings",
		Icon = "rbxassetid://80758916183665",
	})
	UISettings.Build(window, uiTab)
end

return SettingsInit
