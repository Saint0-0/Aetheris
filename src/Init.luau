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
	return Window.new(options)
end

-- Let Window:RequestReload rebuild through this facade without a back-require
-- (Window -> Init -> Window would be a module cycle the bundler rejects).
Window.SetFacade(Aetheris)

return Aetheris
