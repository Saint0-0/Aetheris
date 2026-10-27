--[[
	Aetheris/Constants.luau

	Shared library-wide constants: the fallback backdrop asset, the aurora
	glow texture, and the shared font family with its UI Settings choices.
	Add new constants here instead of scattering bare literals across modules.
	License: Saint0-0 Source License - use in your own scripts, no editing or
	redistribution without permission. (c) 2026 Saint0-0.
]]

local Constants = {}

Constants.FallbackImage = "rbxassetid://11094025229"

-- Optional aurora glow texture tinted from the active theme; clear it to
-- fall back to the procedural bloom.
Constants.AuroraGlow = "rbxassetid://90267840908213"

-- Shared font family: Constants.Font() builds FontFaces from it;
-- SetFontAsset swaps it live (nil resets to the built-in family).
Constants.FontAsset = "rbxassetid://12187365364"
local DEFAULT_FONT_ASSET = Constants.FontAsset

function Constants.Font(weight, style)
	return Font.new(Constants.FontAsset, weight or Enum.FontWeight.Regular, style or Enum.FontStyle.Normal)
end

function Constants.SetFontAsset(asset)
	Constants.FontAsset = (asset and asset ~= "") and asset or DEFAULT_FONT_ASSET
	return Constants.FontAsset
end

-- UI Settings dropdown choices; bundled families resolve through
-- Font.fromEnum so they need no asset ids. One entry per distinct family:
-- weight variants of one family would collide in the stored value.
Constants.FontChoices = {
	{ Name = "Aetheris", Value = DEFAULT_FONT_ASSET },
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
	{ Name = "Garamond", Value = Font.fromEnum(Enum.Font.Garamond).Family },
	{ Name = "Bodoni", Value = Font.fromEnum(Enum.Font.Bodoni).Family },
	{ Name = "Roman Antique", Value = Font.fromEnum(Enum.Font.Antique).Family },
	{ Name = "Fondamento", Value = Font.fromEnum(Enum.Font.Fondamento).Family },
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
	{ Name = "Special Elite", Value = Font.fromEnum(Enum.Font.SpecialElite).Family },
	{ Name = "Kalam", Value = Font.fromEnum(Enum.Font.Kalam).Family },
	{ Name = "Patrick Hand", Value = Font.fromEnum(Enum.Font.PatrickHand).Family },
	{ Name = "Indie Flower", Value = Font.fromEnum(Enum.Font.IndieFlower).Family },
	{ Name = "Permanent Marker", Value = Font.fromEnum(Enum.Font.PermanentMarker).Family },
}

return Constants
