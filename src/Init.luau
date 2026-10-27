--[[
	Aetheris  ·  UI Library facade

	Single entry point for the whole library. Require this once and reach
	everything through it, instead of deep-requiring individual modules:

		local Aetheris = require(game.StarterGui.NewScripts.Init)

		local window = Aetheris:CreateWindow({
			Title = "Aetheris | Jailbreak",
			Description = "hey",
			Theme = "Umbral",
			MinimizeKey = "LeftControl",
			AnimationStyle = "Smooth",  -- or "Snappy"
			AETHERIS_SECUREMODE = false, -- optional hardening; default false
			KeySystem = {                -- optional; shows the key card first
				SaveKey = true,
				API = { { Type = "platoboost", ServiceId = 1234, Secret = "..." } },
				Discord = "https://discord.gg/invite",
			},
			SettingsPages = {
				{ Name = "Keybinds", Icon = Aetheris.Icons["keyboard"] },
			},
		})

	Exposed surface:
		Aetheris.Icons         - Lucide icon set (name -> rbxassetid://)
		Aetheris.Window        - Window module (advanced use)
		Aetheris.ThemeManager  - theme utilities (GetTheme / ApplyTheme)
		Aetheris.ThemeDefinitions - the named theme tables
		Aetheris.SetAuroraTexture - point the aurora at an uploaded glow texture
		Aetheris:CreateWindow(Settings) - build a window (preferred entry)
]]

local Window = require("./Core/Window")
local KeyScreen = require("./Popups/KeyScreen")
local Icons = require("./Assets/Icons")
local Aurora = require("./Utils/Aurora")
local ThemeManager = require("./Themes/ThemeManager")
local ThemeDefinitions = require("./Themes/ThemeDefinitions")

local Aetheris = {}

Aetheris.Icons = Icons
Aetheris.Window = Window
Aetheris.ThemeManager = ThemeManager
Aetheris.ThemeDefinitions = ThemeDefinitions

-- Point the window aurora at an uploaded neutral glow texture (see
-- Constants.AuroraGlow). Pass nil to fall back to the procedural bloom.
function Aetheris.SetAuroraTexture(id)
	Aurora.SetTexture(id)
end

function Aetheris:CreateWindow(Settings)
	local options = table.clone(Settings or {})
	options.AETHERIS_SECUREMODE = options.AETHERIS_SECUREMODE == true

	-- KeySystem = {...} shows the loading + key card before the window builds.
	-- The call blocks until the key is accepted; it returns nil + reason if
	-- the card is dismissed without passing, so the window never opens.
	local keyConfig = options.KeySystem
	if keyConfig == true then
		keyConfig = {}
	end
	if type(keyConfig) == "table" then
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
