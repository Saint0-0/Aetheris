--[[
	Constants  ·  Aetheris UI Library

	Shared library-wide constants. Add new constants here instead of
	scattering bare literals across modules.

	  FallbackImage - branded backdrop asset used when a theme defines no
	                  wallpaper (or WallpaperEnabled is false).
	  AuroraGlow    - optional texture for the window aurora. Empty keeps the
	                  procedural bloom; see assets/aurora/ for a ready glow.
]]

local Constants = {}

Constants.FallbackImage = "rbxassetid://11094025229"

-- Aurora glow texture: a neutral white radial glow PNG, tinted from the
-- active theme. assets/aurora/ holds the source file + generator script;
-- clear this ("") to fall back to the procedural layered-circle bloom.
Constants.AuroraGlow = "rbxassetid://90267840908213"

-- Shared font asset. Every component used to hardcode this id inline; use
-- Constants.Font(weight) instead so the family is defined in one place.
Constants.FontAsset = "rbxassetid://12187365364"

function Constants.Font(weight, style)
	return Font.new(Constants.FontAsset, weight or Enum.FontWeight.Regular, style or Enum.FontStyle.Normal)
end

return Constants
