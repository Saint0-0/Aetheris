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
	-- Main row frame
	local row = Instance.new("Frame")
	row.Name = name .. "TextInput"
	row.BorderSizePixel = 0
	row.BackgroundColor3 = Color3.fromRGB(31, 32, 34)
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 45)
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.new(0.5, 0, 0.5, 0)
	row.BorderColor3 = Color3.fromRGB(0, 0, 0)
	row.Parent = parent
	-- ElementName (label)
	local label = Instance.new("TextLabel")
	label.Name = "ElementName"
	label.TextWrapped = true
	label.BorderSizePixel = 0
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTransparency = (theme and theme.PrimaryTextTransparency) or 0.45
	label.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	label.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	label.TextColor3 = (theme and theme.PrimaryTextColor)
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Size = UDim2.new(0.48591, 0, 0.71359, 0)
	label.Position = UDim2.new(0, 0, 0.5, 0)
	label.BorderColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = name
	label.Parent = row
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
	inputBox.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
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
		local targetTrans = bright and 0.3 or (liveTheme and liveTheme.StrokeTransparency or 0.95)
		local targetColor = liveTheme.StrokeColor
		Tween.Play(stroke, "Fast", { Transparency = targetTrans, Color = targetColor })
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
	self.SetVisibility = function(visible)
		row.Visible = visible
	end
	self.UpdateName = function(newName)
		label.Text = newName
	end
	self.SetPlaceholder = function(newPlaceholder)
		inputBox.PlaceholderText = newPlaceholder
	end
	-- Component-owned theming (see ThemeManager registry).
	function self:ApplyTheme(newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		self._theme = theme
		label.TextColor3 = theme.PrimaryTextColor or label.TextColor3
		label.TextTransparency = theme.PrimaryTextTransparency or label.TextTransparency
		inputBox.TextColor3 = theme.SecondaryTextColor or inputBox.TextColor3
		inputBox.TextTransparency = theme.SecondaryTextTransparency or inputBox.TextTransparency
		inputBox.BackgroundColor3 = theme.InputBackgroundColor or inputBox.BackgroundColor3
		inputBox.BackgroundTransparency = theme.InputBackgroundTransparency or inputBox.BackgroundTransparency
		stroke.Color = theme.StrokeColor or stroke.Color
		stroke.Transparency = theme.StrokeTransparency or stroke.Transparency
	end
	ThemeManager.Register(row, self)
	return self
end
return TextInput