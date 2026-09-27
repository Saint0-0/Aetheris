--[[
	TextInput  ·  Aetheris UI Library

	Single-line text field with hover/focus stroke effects. Callback fires on
	FocusLost (committed value), matching the rest of the input family.

	Usage:
		local textInput = section:TextInput({
			Name = "Input Label",
			Placeholder = "Enter text...",
			Default = "",
			Callback = function(text) end,
		})
]]

local Tween = require("../Utils/Tween")
local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local Constants = require("../Constants")
local ComponentRow = require("./ComponentRow")

local TextInput = {}
TextInput.__index = TextInput
function TextInput.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, TextInput)
	self._theme = theme
	local name = Settings.Name or "Text Input"
	local placeholder = Settings.Placeholder or "[...]"
	local default = Settings.Default or ""
	-- Shared row factory (row name + label width preserved for layout parity).
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "TextInput",
		Theme = theme,
		LabelWidth = 0.48591,
	})
	-- Input box
	local inputBox = Instance.new("TextBox")
	inputBox.Name = "InputBox"
	inputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	inputBox.BorderSizePixel = 0
	inputBox.TextWrapped = true
	inputBox.TextTransparency = (theme and theme.SecondaryTextTransparency) or 0.4
	inputBox.TextSize = 11
	inputBox.TextColor3 = (theme and theme.SecondaryTextColor)
	inputBox.BackgroundColor3 = theme.InputBackgroundColor
	inputBox.BackgroundTransparency = theme.InputBackgroundTransparency
	inputBox:SetAttribute("IsInputBackground", true)
	inputBox.FontFace = Constants.Font(Enum.FontWeight.Medium)
	inputBox.AutomaticSize = Enum.AutomaticSize.X
	inputBox.AnchorPoint = Vector2.new(1, 0.5)
	inputBox.ClearTextOnFocus = false
	inputBox.PlaceholderText = placeholder
	inputBox.Position = UDim2.new(1, 0, 0.5, 0)
	inputBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	inputBox.Text = default
	inputBox.Parent = row
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = inputBox
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	stroke.Thickness = 0.7
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = inputBox
	local padding = Instance.new("UIPadding")
	padding.PaddingRight = UDim.new(0, 7)
	padding.PaddingLeft = UDim.new(0, 7)
	padding.Parent = inputBox
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(60, 25)
	sizeConstraint.MaxSize = Vector2.new(105, 25)
	sizeConstraint.Parent = inputBox
	-- Brighten stroke (hover/focus effect) – same as keybind
	local function setStrokeBright(bright)
		local liveTheme = ActiveTheme.theme or theme
		local restTrans = liveTheme and liveTheme.StrokeTransparency or 0.95
		local targetTrans = bright and 0.3 or restTrans
		local targetColor = liveTheme.StrokeColor
		Tween.Play(stroke, "Fast", { Transparency = targetTrans, Color = targetColor })
		-- PageFade restores this stroke to its cached base on a page switch; pin
		-- that base to the RESTING transparency so a transient hover/focus
		-- brighten is never what a page fade restores (the "stroke stays
		-- bright/invisible until re-hover" bug).
		stroke:SetAttribute("PageFadeBase", restTrans)
	end
	-- Hover events on input box
	inputBox.MouseEnter:Connect(function()
		setStrokeBright(true)
	end)
	inputBox.MouseLeave:Connect(function()
		if not inputBox:IsFocused() then
			setStrokeBright(false)
		end
	end)
	-- Focus events
	inputBox.Focused:Connect(function()
		setStrokeBright(true)
	end)
	inputBox.FocusLost:Connect(function()
		setStrokeBright(false)
		if Settings.Callback then
			Settings.Callback(inputBox.Text)
		end
	end)
	-- Public API
	self.GetText = function()
		return inputBox.Text
	end
	self.SetText = function(newText)
		inputBox.Text = newText
	end
	self.UpdateName = function(newName)
		label.Text = newName
	end
	self.SetPlaceholder = function(newPlaceholder)
		inputBox.PlaceholderText = newPlaceholder
	end
	-- Declarative theming: every themed property is a BINDING.
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(inputBox, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(inputBox, "TextTransparency", "SecondaryTextTransparency")
	ThemeManager.BindColor(inputBox, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindTransparency(inputBox, "BackgroundTransparency", "InputBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	-- Uniform component API (p2-4).
	function self:SetVisibility(visible)
		row.Visible = visible
	end
	function self:Destroy()
		-- Cancel any in-flight tweens on the stroke.
		Tween.CancelAll(stroke)
		-- Drop all ThemeManager bindings.
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(inputBox)
		ThemeManager.UnbindInstance(stroke)
		-- Destroy the root instance.
		if row and row.Parent then
			row:Destroy()
		end
	end
	return self
end
return TextInput