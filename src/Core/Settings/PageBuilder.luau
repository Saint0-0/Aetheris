--[[
	SettingsInit  ·  Aetheris UI Library

	Registers the default settings pages (Themes, UI Settings, Configs) on a
	window's SettingsTabGroup. Called by Window.new via BuildDefaultPages;
	developer-added pages are appended afterwards from CreateWindow options.
]]

local Themes = require("./Themes")
local UISettings = require("./UISettings")
local Configs = require("./Configs")
local Icons = require("../../Assets/Icons")

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

	local configsTab = group:Tab({
		Name = "Configs",
		Icon = Icons["save"],
	})
	Configs.Build(window, configsTab)
end

return SettingsInit
