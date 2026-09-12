--[[
	Section  ·  Aetheris UI Library

	A card inside a tab column that hosts components (Toggle, Slider, etc.).
	Section is the component factory: call section:Toggle(...), section:Slider(...),
	etc., and each forwards the section theme to the component.

	Usage:
		local section = tab:Section({ Side = "Left", Name = "My Section" })
		local toggle = section:Toggle({ Name = "Enable", Default = true, Callback = function(state) end })
]]

local Tween = require("../Utils/Tween")
local Toggle = require("../Components/Toggle")
local Slider = require("../Components/Slider")
local Keybind = require("../Components/Keybind")
local Divider = require("../Components/Divider")
local TextInput = require("../Components/TextInput")
local RadioButtonGroup = require("../Components/RadioButtonGroup")
local Video = require("../Components/Video")
local Status = require("../Components/Status")
local Dropdown = require("../Components/Dropdown")
local ProgressBar = require("../Components/ProgressBar")
local Stepper = require("../Components/Stepper")
local Button = require("../Components/Button")
local Label = require("../Components/Label")
local Paragraph = require("../Components/Paragraph")
local ColorPicker = require("../Components/ColorPicker")
local ThemeManager = require("../Themes/ThemeManager")

local Section = {}
Section.__index = Section
function Section.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	-- Ensure we have a valid theme table
	if not theme or type(theme) ~= "table" then
		theme = ThemeManager.GetTheme(nil)
	end
	local self = setmetatable({}, Section)
	self._theme = theme
	-- Build the section frame
	local frame = Instance.new("Frame")
	frame.Name = Settings.Name or "Section"
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = theme.SectionBackgroundColor
	frame.BackgroundTransparency = theme.SectionBackgroundTransparency
	frame.ClipsDescendants = true
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame:SetAttribute("IsSection", true)
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.Name = "SectionUICorner"
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Name = "SectionUIStroke"
	stroke.Transparency = theme.StrokeTransparency
	stroke.Color = theme.StrokeColor
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.Name = "SectionUIListLayout"
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	local padding = Instance.new("UIPadding")
	padding.Name = "SectionUIPadding"
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 15)
	padding.PaddingLeft = UDim.new(0, 15)
	padding.PaddingBottom = UDim.new(0, 20)
	padding.Parent = frame
	self.Frame = frame
	self.Layout = layout
	self.Padding = padding
	self.Parent = parent
	-- Register with ThemeManager so the section's own background + stroke are
	-- themed without name-matching. The frame lives under window.Base.
	ThemeManager.Register(frame, self)
	return self
end
--[[
	Toggle component builder
	Settings:
		Name (string) - label text (required)
		Default (bool) - initial state (default: false)
		Callback (function) - called when toggled, receives new state
		Flag (string, optional) - for config save/load
	Returns a component object with:
		:UpdateState(newState) - set the toggle state (animates)
		:GetState() - get current state (bool)
		:SetVisibility(visible) - show/hide the component
		:UpdateName(newName) - change the label text
]]
function Section:Toggle(Settings, ShowNotification)
	return Toggle.new(self.Frame, Settings, ShowNotification, self._theme)
end
-- Stub methods for other components (waiting for GUI-to-Lua exports)
local function stub(name)
	return function(self, Settings)
		warn(string.format("[Section] %s not yet implemented - waiting for GUI-to-Lua export", name))
		return {}
	end
end
function Section:Slider(Settings)
	return Slider.new(self.Frame, Settings, self._theme)
end
function Section:Keybind(Settings)
	return Keybind.new(self.Frame, Settings, self._theme)
end
function Section:Button(Settings)
	return Button.new(self.Frame, Settings, self._theme)
end
function Section:Label(Settings)
	return Label.new(self.Frame, Settings, self._theme)
end
function Section:Divider(Settings)
	return Divider.new(self.Frame, Settings, self._theme)
end
function Section:TextInput(Settings)
	return TextInput.new(self.Frame, Settings, self._theme)
end
function Section:RadioButtonGroup()
	return RadioButtonGroup.new(self.Frame, self._theme)
end
function Section:Video(Settings)
	return Video.new(self.Frame, Settings, self._theme)
end
function Section:Status(Settings)
	return Status.new(self.Frame, Settings, self._theme)
end
function Section:Dropdown(Settings, ShowPopup)
	return Dropdown.new(self.Frame, Settings, ShowPopup, self._theme)
end
function Section:ProgressBar(Settings)
	return ProgressBar.new(self.Frame, Settings, self._theme)
end
function Section:Stepper(Settings)
	return Stepper.new(self.Frame, Settings, self._theme)
end
function Section:Paragraph(Settings)
	return Paragraph.new(self.Frame, Settings, self._theme)
end
function Section:ColorPicker(Settings, ShowPopup)
	return ColorPicker.new(self.Frame, Settings, ShowPopup, self._theme)
end

-- Component-owned theming. Called by ThemeManager via the component registry.
-- Restyles the section frame + stroke directly (no animation) so the
-- surrounding color crossfade still produces the old -> new fade.
function Section:ApplyTheme(newTheme)
	local theme = ThemeManager.GetTheme(newTheme)
	self._theme = theme
	self.Frame.BackgroundColor3 = theme.SectionBackgroundColor or self.Frame.BackgroundColor3
	if theme.SectionBackgroundTransparency ~= nil then
		self.Frame.BackgroundTransparency = theme.SectionBackgroundTransparency
	end
	local stroke = self.Frame:FindFirstChild("SectionUIStroke")
	if stroke then
		stroke.Color = theme.StrokeColor or stroke.Color
		stroke.Transparency = theme.SectionStrokeTransparency or theme.StrokeTransparency or stroke.Transparency
	end
end

-- Add other components as needed
return Section