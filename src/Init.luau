--[[
	Aetheris  ·  UI Library facade

	Single entry point for the whole library. Require this once and reach
	everything through it, instead of deep-requiring individual modules:

		local Aetheris = require(game.StarterGui.NewScripts.Init)

		local window = Aetheris:CreateWindow({
			Title = "Aetheris | Jailbreak",
			Description = "hey",
			Theme = "Default",
			MinimizeKey = "LeftControl",
			AnimationStyle = "Smooth",  -- or "Snappy"
			SettingsPages = {
				{ Name = "Keybinds", Icon = Aetheris.Icons["keyboard"] },
			},
		})

	Exposed surface:
		Aetheris.Icons         - Lucide icon set (name -> rbxassetid://)
		Aetheris.Window        - Window module (advanced use)
		Aetheris.ThemeManager  - theme utilities (GetTheme / ApplyTheme)
		Aetheris.ThemeDefinitions - the named theme tables
		Aetheris:CreateWindow(Settings) - build a window (preferred entry)
]]

local Window = require("./Core/Window")
local Icons = require("./Assets/Icons")
local ThemeManager = require("./Themes/ThemeManager")
local ThemeDefinitions = require("./Themes/ThemeDefinitions")

local Aetheris = {}

Aetheris.Icons = Icons
Aetheris.Window = Window
Aetheris.ThemeManager = ThemeManager
Aetheris.ThemeDefinitions = ThemeDefinitions

function Aetheris:CreateWindow(Settings)
	return Window.new(Settings)
end

return Aetheris
