--[[
	Aetheris/Core/Settings/PageBuilder.luau

	Registers the default settings pages on a window's SettingsTabGroup.
	CreateWindow options append developer pages afterwards.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Themes = require("./Themes")
local UISettings = require("./UISettings")
local Configs = require("./Configs")
local Info = require("./Info")
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

	local infoTab = group:Tab({
		Name = "Info",
		Icon = Icons["info"],
	})
	Info.Build(window, infoTab)
end

return SettingsInit
