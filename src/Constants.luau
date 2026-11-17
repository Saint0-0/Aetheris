--[[
	Aetheris/Constants.luau

	Shared library constants, plus the shared font family and its UI Settings choices.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = {}

Constants.FallbackImage = "rbxassetid://11094025229"

-- Optional aurora glow texture; nil falls back to the procedural bloom.
Constants.AuroraGlow = "rbxassetid://90267840908213"

-- Space reserved at the bottom of settings pages for the docked tab bar.
Constants.SettingsBottomReserve = 72

-- Shared font family; SetFontAsset swaps it live, and nil restores the default.
Constants.FontAsset = "rbxassetid://12187365364"
local DEFAULT_FONT_ASSET = Constants.FontAsset

function Constants.Font(weight, style)
	return Font.new(Constants.FontAsset, weight or Enum.FontWeight.Regular, style or Enum.FontStyle.Normal)
end

function Constants.SetFontAsset(asset)
	Constants.FontAsset = (asset and asset ~= "") and asset or DEFAULT_FONT_ASSET
	return Constants.FontAsset
end

-- UI Settings font choices; one entry per distinct family.
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
