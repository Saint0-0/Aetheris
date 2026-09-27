--[[
	Constants  ·  Aetheris UI Library

	Shared library-wide constants. Add new constants here instead of
	scattering bare literals across modules.

	  FallbackImage - branded backdrop asset used when a theme defines no
	                  wallpaper (or WallpaperEnabled is false).
]]

local Constants = {}

Constants.FallbackImage = "rbxassetid://11094025229"

-- Shared font asset. Every component used to hardcode this id inline; use
-- Constants.Font(weight) instead so the family is defined in one place.
Constants.FontAsset = "rbxassetid://12187365364"

function Constants.Font(weight, style)
	return Font.new(
		Constants.FontAsset,
		weight or Enum.FontWeight.Regular,
		style or Enum.FontStyle.Normal
	)
end

return Constants