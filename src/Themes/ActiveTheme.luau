--[[
	Aetheris/Themes/ActiveTheme.luau

	Shared holder for the currently applied theme. Components read it at
	interaction time instead of a theme table captured at construction.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ActiveTheme = {}
ActiveTheme.theme = nil
ActiveTheme.name = nil
return ActiveTheme
