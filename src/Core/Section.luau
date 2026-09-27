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
local Constants = require("../Constants")

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
	-- Section strokes are their own thing: prefer the section-specific keys so
	-- construction matches ApplyTheme (previously construction used the general
	-- StrokeTransparency while ApplyTheme used SectionStrokeTransparency, so a
	-- freshly-built section and a theme-switched one disagreed). Fall back to the
	-- general stroke keys, then a sane default.
	local stroke = Instance.new("UIStroke")
	stroke.Name = "SectionUIStroke"
	stroke.Transparency = theme.SectionStrokeTransparency or theme.StrokeTransparency or 0.985
	stroke.Color = theme.SectionStrokeColor or theme.StrokeColor or Color3.fromRGB(255, 255, 255)
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
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 15)
	padding.PaddingLeft = UDim.new(0, 15)
	padding.PaddingBottom = UDim.new(0, 20)
	padding.Parent = frame
	self.Frame = frame
	self.Layout = layout
	self.Padding = padding
	self.Parent = parent
	-- Section title: a small, muted label naming what the section is for
	-- (e.g. "Gameplay", "Interface"). Only shown when a Name is provided.
	-- LayoutOrder -1 keeps it above the section's components (which default
	-- to LayoutOrder 0), and its TextColor3 crossfades on theme switch via
	-- the normal ThemeManager descendant pass (no override stamped).
	if Settings.Name and Settings.Name ~= "" then
		local title = Instance.new("TextLabel")
		title.Name = "SectionTitle"
		title.BackgroundTransparency = 1
		title.BorderSizePixel = 0
		title.Text = Settings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextYAlignment = Enum.TextYAlignment.Center
		title.TextSize = 12
		title.FontFace = Constants.Font(Enum.FontWeight.Medium)
		-- Match ScriptDescription exactly: TitleTextColor + 0.7 transparency.
		title.TextColor3 = theme.TitleTextColor or Color3.fromRGB(255, 255, 255)
		title.TextTransparency = 0.7
		title.AutomaticSize = Enum.AutomaticSize.Y
		title.Size = UDim2.new(1, 0, 0, 0)
		title.LayoutOrder = -1
		title.Parent = frame
		self.Title = title
	end
	-- Declarative theming: every themed property is a BINDING. The bind applies
	-- immediately (so the section is themed on the first frame) and crossfades
	-- on every theme switch, honouring overrides automatically. This replaces
	-- the old registry + Section:ApplyTheme path for the section's own chrome.
	ThemeManager.BindColor(frame, "BackgroundColor3", "SectionBackgroundColor")
	ThemeManager.BindTransparency(frame, "BackgroundTransparency", "SectionBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "SectionStrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "SectionStrokeTransparency")
	if self.Title then
		ThemeManager.BindColor(self.Title, "TextColor3", "TitleTextColor")
	end
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

-- Section chrome is themed declaratively via ThemeManager.Bind* in Section.new;
-- there is no Section:ApplyTheme and the section is not registered with
-- ThemeManager, so the registry walk no longer touches it.
return Section