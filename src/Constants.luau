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
-- through Font.fromEnum so they need no asset ids. One entry per distinct
-- family (SourceSans/BuilderSans/Arimo weight variants share a family and
-- would collide in the stored value).
Constants.FontChoices = {
	{ Name = "Aetheris", Value = DEFAULT_FONT_ASSET },
	-- UI / body
	{ Name = "Gotham", Value = Font.fromEnum(Enum.Font.Gotham).Family },
	{ Name = "Source Sans", Value = Font.fromEnum(Enum.Font.SourceSans).Family },
	{ Name = "Roboto", Value = Font.fromEnum(Enum.Font.Roboto).Family },
	{ Name = "Ubuntu", Value = Font.fromEnum(Enum.Font.Ubuntu).Family },
	{ Name = "Nunito", Value = Font.fromEnum(Enum.Font.Nunito).Family },
	{ Name = "Titillium Web", Value = Font.fromEnum(Enum.Font.TitilliumWeb).Family },
	{ Name = "Builder Sans", Value = Font.fromEnum(Enum.Font.BuilderSans).Family },
	{ Name = "Arimo", Value = Font.fromEnum(Enum.Font.Arimo).Family },
	{ Name = "Roboto Condensed", Value = Font.fromEnum(Enum.Font.RobotoCondensed).Family },
	{ Name = "Roboto Mono", Value = Font.fromEnum(Enum.Font.RobotoMono).Family },
	{ Name = "Oswald", Value = Font.fromEnum(Enum.Font.Oswald).Family },
	{ Name = "Merriweather", Value = Font.fromEnum(Enum.Font.Merriweather).Family },
	{ Name = "Josefin Sans", Value = Font.fromEnum(Enum.Font.JosefinSans).Family },
	{ Name = "Jura", Value = Font.fromEnum(Enum.Font.Jura).Family },
	{ Name = "Sarpanch", Value = Font.fromEnum(Enum.Font.Sarpanch).Family },
	{ Name = "Michroma", Value = Font.fromEnum(Enum.Font.Michroma).Family },
	-- Serif / classic
	{ Name = "Garamond", Value = Font.fromEnum(Enum.Font.Garamond).Family },
	{ Name = "Bodoni", Value = Font.fromEnum(Enum.Font.Bodoni).Family },
	{ Name = "Roman Antique", Value = Font.fromEnum(Enum.Font.Antique).Family },
	{ Name = "Fondamento", Value = Font.fromEnum(Enum.Font.Fondamento).Family },
	-- Display
	{ Name = "Fredoka One", Value = Font.fromEnum(Enum.Font.FredokaOne).Family },
	{ Name = "Fantasy", Value = Font.fromEnum(Enum.Font.Fantasy).Family },
	{ Name = "Cartoon", Value = Font.fromEnum(Enum.Font.Cartoon).Family },
	{ Name = "Highway", Value = Font.fromEnum(Enum.Font.Highway).Family },
	{ Name = "SciFi", Value = Font.fromEnum(Enum.Font.SciFi).Family },
	{ Name = "Arcade", Value = Font.fromEnum(Enum.Font.Arcade).Family },
	{ Name = "Luckiest Guy", Value = Font.fromEnum(Enum.Font.LuckiestGuy).Family },
	{ Name = "Bangers", Value = Font.fromEnum(Enum.Font.Bangers).Family },
	{ Name = "Creepster", Value = Font.fromEnum(Enum.Font.Creepster).Family },
	{ Name = "Denk One", Value = Font.fromEnum(Enum.Font.DenkOne).Family },
	{ Name = "Grenze Gotisch", Value = Font.fromEnum(Enum.Font.GrenzeGotisch).Family },
	{ Name = "Amatic SC", Value = Font.fromEnum(Enum.Font.AmaticSC).Family },
	-- Handwriting / typewriter
	{ Name = "Special Elite", Value = Font.fromEnum(Enum.Font.SpecialElite).Family },
	{ Name = "Kalam", Value = Font.fromEnum(Enum.Font.Kalam).Family },
	{ Name = "Patrick Hand", Value = Font.fromEnum(Enum.Font.PatrickHand).Family },
	{ Name = "Indie Flower", Value = Font.fromEnum(Enum.Font.IndieFlower).Family },
	{ Name = "Permanent Marker", Value = Font.fromEnum(Enum.Font.PermanentMarker).Family },
}

return Constants
