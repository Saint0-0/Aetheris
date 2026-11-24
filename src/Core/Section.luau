--[[
	Aetheris/Core/Section.luau

	A card inside a tab column that hosts components.
	Builders forward the section theme; windowed sections register controls for configs.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Toggle = require("../Components/Toggle")
local Slider = require("../Components/Slider")
local Keybind = require("../Components/Keybind")
local Divider = require("../Components/Divider")
local TextInput = require("../Components/TextInput")
local RadioButtonGroup = require("../Components/RadioButtonGroup")
local Video = require("../Components/Video")
local Viewport = require("../Components/Viewport")
local Status = require("../Components/Status")
local DataTable = require("../Components/DataTable")
local Graph = require("../Components/Graph")
local Dropdown = require("../Components/Dropdown")
local ProgressBar = require("../Components/ProgressBar")
local Stepper = require("../Components/Stepper")
local Carousel = require("../Components/Carousel")
local Button = require("../Components/Button")
local Label = require("../Components/Label")
local Paragraph = require("../Components/Paragraph")
local ColorPicker = require("../Components/ColorPicker")
local LiveStat = require("../Components/LiveStat")
local Console = require("../Components/Console")
local CodeView = require("../Components/CodeView")
local ThemeManager = require("../Themes/ThemeManager")
local Constants = require("../Constants")
local Locale = require("../Utils/Locale")
local UUID = require("../Utils/UUID")

local Section = {}
Section.__index = Section

-- Section card: wash fill, top-lit rim, radius 6, SemiBold 13 title.
local CORNER_SECTION = 6
local AURORA_TINT = 0.14

local function isDark(color)
	return (color.R * 0.299 + color.G * 0.587 + color.B * 0.114) < 0.5
end

-- Gradient keypoints are multipliers: accent tint fading to a darker bottom.
local function stampFillGradient(gradient, t)
	local base = (t and t.SectionBackgroundColor) or Color3.fromRGB(30, 30, 34)
	local bottom = if isDark(base) then 0.72 else 0.9
	local corner = Color3.new(1, 1, 1)
	if t and t.AccentColor then
		corner = corner:Lerp(t.AccentColor, AURORA_TINT)
	end
	gradient.Rotation = 35
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, corner),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(bottom, bottom, bottom)),
	})
end

function Section.new(parent, Settings, theme, window, noSave)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	if not theme or type(theme) ~= "table" then
		theme = ThemeManager.GetTheme(nil)
	end
	local self = setmetatable({}, Section)
	self._theme = theme
	self._window = window
	-- Settings pages pass noSave so configs never capture UI settings.
	self._noSave = noSave == true
	self._sectionName = Settings.Name or ""
	-- Popup engines come from the owning window.
	if window then
		self._notify = function(s)
			return window:UINotification(s)
		end
		self._openDropdown = function(id, s)
			return window:DropdownPopUp(id, s)
		end
		self._openColorPicker = function(id, s)
			return window:ColorPickerPopUp(id, s)
		end
	end
	local frame = Instance.new("Frame")
	frame.Name = UUID.Generate("Section")
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = theme.SectionBackgroundColor
	frame.BackgroundTransparency = theme.SectionBackgroundTransparency
	frame.ClipsDescendants = true
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Size = UDim2.fromScale(1, 0)
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame:SetAttribute(UUID.Static("IsSection"), true)
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.Name = UUID.Static("SectionUICorner")
	corner.CornerRadius = UDim.new(0, CORNER_SECTION)
	corner.Parent = frame
	-- The fill wash is restamped on every theme switch.
	local fillGradient = Instance.new("UIGradient")
	fillGradient.Name = UUID.Static("SectionFill")
	stampFillGradient(fillGradient, theme)
	fillGradient.Parent = frame
	-- Prefer the section stroke keys; general stroke keys are the fallback.
	local stroke = Instance.new("UIStroke")
	stroke.Name = UUID.Static("SectionUIStroke")
	stroke.Transparency = theme.SectionStrokeTransparency or theme.StrokeTransparency or 0.985
	stroke.Color = theme.SectionStrokeColor or theme.StrokeColor or Color3.fromRGB(255, 255, 255)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	-- The rim ramp keeps the top edge painted and fades the sides and bottom.
	local rim = Instance.new("UIGradient")
	rim.Name = UUID.Static("SectionRim")
	rim.Rotation = 90
	rim.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4, 0.55),
		NumberSequenceKeypoint.new(1, 0.7),
	})
	rim.Parent = stroke
	local layout = Instance.new("UIListLayout")
	layout.Name = UUID.Static("SectionUIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	local padding = Instance.new("UIPadding")
	padding.Name = UUID.Static("SectionUIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 15)
	padding.PaddingLeft = UDim.new(0, 15)
	padding.PaddingBottom = UDim.new(0, 20)
	padding.Parent = frame
	self.Frame = frame
	self.Layout = layout
	self.Padding = padding
	self.Parent = parent
	-- LayoutOrder -1 keeps the title above the components.
	if Settings.Name and Settings.Name ~= "" then
		local title = Instance.new("TextLabel")
		title.Name = UUID.Static("SectionTitle")
		title.BackgroundTransparency = 1
		title.BorderSizePixel = 0
		Locale.set(title, "Text", Settings.Name)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextYAlignment = Enum.TextYAlignment.Center
		title.TextSize = 13
		title.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
		title.TextColor3 = theme.TitleTextColor or Color3.fromRGB(255, 255, 255)
		title.TextTransparency = 0.7
		title.AutomaticSize = Enum.AutomaticSize.Y
		title.Size = UDim2.fromScale(1, 0)
		title.LayoutOrder = -1
		title.Parent = frame
		self.Title = title
	end
	-- Themed properties are bindings, so the section crossfades on theme switch.
	ThemeManager.BindColor(frame, "BackgroundColor3", "SectionBackgroundColor")
	ThemeManager.BindTransparency(frame, "BackgroundTransparency", "SectionBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "SectionStrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "SectionStrokeTransparency")
	if self.Title then
		ThemeManager.BindColor(self.Title, "TextColor3", "TitleTextColor")
	end
	-- The wash mixes fill and accent, so it rides the theme callback.
	ThemeManager.OnThemeApplied(function(applied)
		stampFillGradient(fillGradient, applied)
	end, frame)
	return self
end
-- Route control changes through the window config manager.
function Section:_wrapCallback(kind, Settings)
	local manager = self._noSave and nil or (self._window and self._window.ConfigManager)
	if not manager then
		return Settings
	end
	Settings = Settings or {}
	local original = Settings.Callback
	Settings.Callback = function(...)
		if original then
			original(...)
		end
		manager:NotifyChanged()
	end
	if kind == "Keybind" then
		-- Keybinds report through OnRebind, not Callback.
		local originalRebind = Settings.OnRebind
		Settings.OnRebind = function(...)
			if originalRebind then
				originalRebind(...)
			end
			manager:NotifyChanged()
		end
	end
	return Settings
end

function Section:_register(kind, Settings, component)
	local manager = self._noSave and nil or (self._window and self._window.ConfigManager)
	if not manager or not component then
		return component
	end
	if Settings and Settings.NoSave then
		return component
	end
	manager:Register(kind, self._sectionName, component)
	return component
end

function Section:Toggle(Settings, ShowNotification)
	Settings = self:_wrapCallback("Toggle", Settings)
	-- Defaults to the owning window's notification engine.
	ShowNotification = ShowNotification or self._notify
	return self:_register("Toggle", Settings, Toggle.new(self.Frame, Settings, ShowNotification, self._theme))
end
function Section:Slider(Settings)
	Settings = self:_wrapCallback("Slider", Settings)
	return self:_register("Slider", Settings, Slider.new(self.Frame, Settings, self._theme))
end
function Section:Keybind(Settings)
	Settings = self:_wrapCallback("Keybind", Settings)
	return self:_register("Keybind", Settings, Keybind.new(self.Frame, Settings, self._theme))
end
function Section:Button(Settings)
	return Button.new(self.Frame, Settings, self._theme)
end
function Section:Label(Settings)
	return Label.new(self.Frame, Settings, self._theme, self._window)
end
function Section:Divider(Settings)
	return Divider.new(self.Frame, Settings, self._theme)
end
function Section:TextInput(Settings)
	Settings = self:_wrapCallback("TextInput", Settings)
	return self:_register("TextInput", Settings, TextInput.new(self.Frame, Settings, self._theme))
end
function Section:RadioButtonGroup()
	local group = RadioButtonGroup.new(self.Frame, self._theme)
	return self:_register("RadioButtonGroup", nil, group)
end
function Section:Video(Settings)
	return Video.new(self.Frame, Settings, self._theme)
end
-- { {assetId, "image"|"video"}, ... }, hard max 5 pages.
function Section:Carousel(Settings)
	return Carousel.new(self.Frame, Settings, self._theme)
end
function Section:Viewport(Settings)
	return Viewport.new(self.Frame, Settings, self._theme)
end
function Section:Status(Settings)
	return Status.new(self.Frame, Settings, self._theme)
end
function Section:DataTable(Settings)
	return DataTable.new(self.Frame, Settings, self._theme)
end
function Section:Graph(Settings)
	return Graph.new(self.Frame, Settings, self._theme)
end
function Section:Dropdown(Settings, ShowPopup)
	Settings = self:_wrapCallback("Dropdown", Settings)
	ShowPopup = ShowPopup or self._openDropdown
	return self:_register("Dropdown", Settings, Dropdown.new(self.Frame, Settings, ShowPopup, self._theme))
end
function Section:ProgressBar(Settings)
	return ProgressBar.new(self.Frame, Settings, self._theme)
end
function Section:LiveStat(Settings)
	return LiveStat.new(self.Frame, Settings, self._theme)
end
function Section:Console(Settings)
	return Console.new(self.Frame, Settings, self._theme)
end
function Section:CodeView(Settings)
	return CodeView.new(self.Frame, Settings, self._theme)
end
function Section:Stepper(Settings)
	Settings = self:_wrapCallback("Stepper", Settings)
	return self:_register("Stepper", Settings, Stepper.new(self.Frame, Settings, self._theme))
end
function Section:Paragraph(Settings)
	return Paragraph.new(self.Frame, Settings, self._theme, self._window)
end
function Section:ColorPicker(Settings, ShowPopup)
	Settings = self:_wrapCallback("ColorPicker", Settings)
	ShowPopup = ShowPopup or self._openColorPicker
	return self:_register("ColorPicker", Settings, ColorPicker.new(self.Frame, Settings, ShowPopup, self._theme))
end

-- Section chrome is themed in Section.new; there is no ApplyTheme entry.
return Section
