--[[
	ActiveTheme  ·  Aetheris UI Library

	Shared holder for the currently applied theme. Components read from this
	at interaction time (e.g. a toggle click) instead of relying on the theme
	table captured at construction, which would otherwise go stale after a
	theme switch.

	Note: per-element state is ultimately driven by ATTRIBUTES stamped by
	ThemeManager; ActiveTheme is a convenience fallback, not the source of
	truth. Fields: theme (resolved table | nil), name (theme name | nil).
]]

local ActiveTheme = {}
ActiveTheme.theme = nil
ActiveTheme.name = nil
return ActiveTheme