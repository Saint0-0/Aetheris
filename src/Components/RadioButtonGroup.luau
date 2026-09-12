--[[
	RadioButtonGroup  ·  Aetheris UI Library

	Manages a set of radio buttons, enforcing single selection. Create buttons
	through the group so selection state stays consistent.

	Usage:
		local group = RadioButtonGroup.new(parent)
		group:RadioButton({ Name = "Option 1", Default = true })
		group:RadioButton({ Name = "Option 2" })
		group:GetSelected()  -- returns the selected button object
]]

local ThemeManager = require("../Themes/ThemeManager")
local RadioButton = require("./RadioButton")
local RadioButtonGroup = {}
RadioButtonGroup.__index = RadioButtonGroup
function RadioButtonGroup.new(parent, theme)
	theme = ThemeManager.GetTheme(theme)
	local self = setmetatable({}, RadioButtonGroup)
	self.Parent = parent
	self.Buttons = {}
	self.Selected = nil
	self._hasSelection = false
	self._theme = theme
	return self
end
function RadioButtonGroup:RadioButton(Settings)
	Settings = Settings or {}
	local button = RadioButton.new(self.Parent, self, Settings, self._theme)
	table.insert(self.Buttons, button)
	-- Selection logic: if this button is marked default, select it.
	-- Otherwise, if no button has been selected yet and this is the first button, select it.
	if Settings.Default then
		self:Select(button)
	elseif not self._hasSelection and #self.Buttons == 1 then
		self:Select(button)
	end
	return button
end
function RadioButtonGroup:Select(button)
	if self.Selected == button then return end
	-- Deselect previous
	if self.Selected then
		self.Selected.SetSelected(self.Selected, false)
	end
	self.Selected = button
	button.SetSelected(button, true)
	self._hasSelection = true
end
function RadioButtonGroup:GetSelected()
	return self.Selected
end
return RadioButtonGroup