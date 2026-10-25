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
-- SetFontAsset swaps the family live (used by Window:SetFont); nil resets to
-- the built-in Aetheris font.
Constants.FontAsset = "rbxassetid://12187365364"
local DEFAULT_FONT_ASSET = Constants.FontAsset

function Constants.Font(weight, style)
	return Font.new(Constants.FontAsset, weight or Enum.FontWeight.Regular, style or Enum.FontStyle.Normal)
end

function Constants.SetFontAsset(asset)
	Constants.FontAsset = (asset and asset ~= "") and asset or DEFAULT_FONT_ASSET
	return Constants.FontAsset
end

-- Font choices for the UI Settings dropdown. The first entry is the built-in
-- Aetheris font (asset above); the rest are Roblox's bundled families resolved
-- through Font.fromEnum so they need no asset ids.
Constants.FontChoices = {
	{ Name = "Aetheris", Value = DEFAULT_FONT_ASSET },
	{ Name = "Gotham", Value = Font.fromEnum(Enum.Font.Gotham).Family },
	{ Name = "Source Sans", Value = Font.fromEnum(Enum.Font.SourceSans).Family },
	{ Name = "Roboto", Value = Font.fromEnum(Enum.Font.Roboto).Family },
	{ Name = "Ubuntu", Value = Font.fromEnum(Enum.Font.Ubuntu).Family },
	{ Name = "Nunito", Value = Font.fromEnum(Enum.Font.Nunito).Family },
	{ Name = "Titillium Web", Value = Font.fromEnum(Enum.Font.TitilliumWeb).Family },
}

return Constants
