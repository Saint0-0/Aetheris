--[[
	Aetheris/Components/RadioButtonGroup.luau

	Manages a set of radio buttons, enforcing single selection. Create buttons
	through the group so selection state stays consistent; the first button (or
	any marked Default) is selected automatically.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
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
	if Settings.Default or (not self._hasSelection and #self.Buttons == 1) then
		self:Select(button)
	end
	return button
end
function RadioButtonGroup:Select(button)
	if self.Selected == button then
		return
	end
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

function RadioButtonGroup:SetVisible(visible)
	for _, button in ipairs(self.Buttons) do
		if button.SetVisible then
			button:SetVisible(visible)
		end
	end
end

RadioButtonGroup.SetVisibility = RadioButtonGroup.SetVisible

function RadioButtonGroup:GetVisible()
	local first = self.Buttons[1]
	return first ~= nil and first:GetVisible() or false
end

function RadioButtonGroup:Destroy()
	for _, button in ipairs(self.Buttons) do
		if button.Destroy then
			button:Destroy()
		end
	end
	self.Buttons = {}
	self.Selected = nil
end

return RadioButtonGroup
