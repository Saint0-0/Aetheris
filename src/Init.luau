--[[
	Aetheris/Init.luau

	Single entry point for the library; require this once and reach every module through it.
	CreateWindow accepts Theme, KeySystem, Version, Changelog and SettingsPages.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Window = require("./Core/Window")
local KeyScreen = require("./Popups/KeyScreen")
local SettingsStore = require("./Core/Settings/SettingsStore")
local Locale = require("./Utils/Locale")
local Icons = require("./Assets/Icons")
local Aurora = require("./Utils/Aurora")
local ThemeManager = require("./Themes/ThemeManager")
local ThemeDefinitions = require("./Themes/ThemeDefinitions")

local Aetheris = {}

Aetheris.Icons = Icons
Aetheris.Window = Window
Aetheris.ThemeManager = ThemeManager
Aetheris.ThemeDefinitions = ThemeDefinitions

-- Point the aurora at a glow texture; nil restores the procedural bloom.
function Aetheris.SetAuroraTexture(id)
	Aurora.SetTexture(id)
end

function Aetheris:CreateWindow(Settings)
	local options = table.clone(Settings or {})
	options.AETHERIS_SECUREMODE = options.AETHERIS_SECUREMODE == true

	-- A dismissed key card returns nil, so the window never opens.
	local keyConfig = options.KeySystem
	if keyConfig == true then
		keyConfig = {}
	end
	if type(keyConfig) == "table" then
		-- The key screen builds before Window.new, so load the saved locale first.
		SettingsStore.Load()
		Locale.setActive(SettingsStore.Get("Locale"))
		local passed = KeyScreen.Run(keyConfig, {
			Theme = options.Theme,
			Title = options.Title,
			SecureMode = options.AETHERIS_SECUREMODE,
			DragStyle = Window.DragStyle,
		})
		if not passed then
			return nil, "key system closed before a key was accepted."
		end
	end

	return Window.new(options)
end

return Aetheris
