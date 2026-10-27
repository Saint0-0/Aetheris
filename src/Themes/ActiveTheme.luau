--[[
	Aetheris/Themes/ActiveTheme.luau

	Shared holder for the currently applied theme. Components read from this at
	interaction time (e.g. a toggle click) instead of relying on the theme table
	captured at construction, which would otherwise go stale after a theme switch.
	License: Saint0-0 Source License - use in your own scripts, no editing or
	redistribution without permission. (c) 2026 Saint0-0.
]]

local ActiveTheme = {}
ActiveTheme.theme = nil
ActiveTheme.name = nil
return ActiveTheme
