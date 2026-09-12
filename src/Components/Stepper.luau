--[[
	Stepper  ·  Aetheris UI Library

	Numeric input with +/- buttons. Clamps to Min/Max, advances by Step, and
	rounds to Precision. The text field is committed on FocusLost too.

	Usage:
		local stepper = section:Stepper({
			Name = "My Stepper",
			Min = 0,
			Max = 100,
			Default = 50,
			Step = 5,
			Callback = function(value) print(value) end,
		})
]]

local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local Stepper = {}
Stepper.__index = Stepper
function Stepper.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Stepper)
	self._theme = theme
	local name = Settings.Name or "Stepper"
	local minValue = Settings.Min or 0
	local maxValue = Settings.Max or 100
	local defaultValue = Settings.Default or 50
	local step = Settings.Step or 1
	local callback = Settings.Callback or function() end
	local isInteger = (Settings.Integer == nil) and true or Settings.Integer
	-- Build UI from export
	local row = Instance.new("Frame")
	row.Name = name .. "Stepper"
	row.BorderSizePixel = 0
	row.BackgroundColor3 = Color3.fromRGB(31, 32, 34)
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 45)
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.new(0.5, 0, 0.5, 0)
	row.BorderColor3 = Color3.fromRGB(0, 0, 0)
	row.Parent = parent
	-- ElementName
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
	label.BorderColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = name
	label.Position = UDim2.new(0, 0, 0.5, 0)
	label.Parent = row
	-- StepperInputBox
	local inputBox = Instance.new("TextBox")
	inputBox.Name = "StepperInputBox"
	inputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	inputBox.BorderSizePixel = 0
	inputBox.TextWrapped = true
	inputBox.TextTransparency = (theme and theme.SecondaryTextTransparency) or 0.4
	inputBox.TextSize = 13
	inputBox.TextColor3 = (theme and theme.SecondaryTextColor)
	inputBox.BackgroundColor3 = theme.InputBackgroundColor
	inputBox.BackgroundTransparency = theme.InputBackgroundTransparency
	inputBox:SetAttribute("IsInputBackground", true)
	inputBox.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	inputBox.AnchorPoint = Vector2.new(1, 0.5)
	inputBox.ClearTextOnFocus = false
	inputBox.PlaceholderText = tostring(defaultValue)
	inputBox.Size = UDim2.new(0.24189, 0, 0.563, 0)
	inputBox.Position = UDim2.new(0.89655, 0, 0.5, 0)
	inputBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	inputBox.Text = ""
	inputBox.Parent = row
	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 6)
	inputCorner.Parent = inputBox
	local inputStroke = Instance.new("UIStroke")
	inputStroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	inputStroke.Thickness = 0.7
	inputStroke.Color = (theme and theme.StrokeColor)
	inputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	inputStroke.Parent = inputBox
	-- StepUp button
	local stepUp = Instance.new("ImageButton")
	stepUp.Name = "StepUp"
	stepUp.BorderSizePixel = 0
	stepUp.ImageTransparency = 0.6
	stepUp.BackgroundTransparency = 1
	stepUp.BackgroundColor3 = (theme and theme.AccentColor)
	stepUp.AnchorPoint = Vector2.new(1, 0.5)
	stepUp.Image = Icons["chevron-up"]
	stepUp.ImageColor3 = (theme and theme.AccentColor)
	stepUp.Size = UDim2.new(0, 15, 0, 15)
	stepUp.BorderColor3 = Color3.fromRGB(0, 0, 0)
	stepUp.Position = UDim2.new(1, 0, 0.28, 0)
	stepUp.Parent = row
	local upAspect = Instance.new("UIAspectRatioConstraint")
	upAspect.Parent = stepUp
	local upCorner = Instance.new("UICorner")
	upCorner.CornerRadius = UDim.new(0, 4)
	upCorner.Parent = stepUp
	local upStroke = Instance.new("UIStroke")
	upStroke.Transparency = 0.95
	upStroke.Color = theme.StrokeColor
	upStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	upStroke.Parent = stepUp
	-- StepDown button
	local stepDown = Instance.new("ImageButton")
	stepDown.Name = "StepDown"
	stepDown.BorderSizePixel = 0
	stepDown.ImageTransparency = 0.6
	stepDown.BackgroundTransparency = 1
	stepDown.BackgroundColor3 = (theme and theme.AccentColor)
	stepDown.AnchorPoint = Vector2.new(1, 0.5)
	stepDown.Image = Icons["chevron-down"]
	stepDown.ImageColor3 = (theme and theme.AccentColor)
	stepDown.Size = UDim2.new(0, 15, 0, 15)
	stepDown.BorderColor3 = Color3.fromRGB(0, 0, 0)
	stepDown.Position = UDim2.new(1, 0, 0.7, 0)
	stepDown.Parent = row
	local downAspect = Instance.new("UIAspectRatioConstraint")
	downAspect.Parent = stepDown
	local downCorner = Instance.new("UICorner")
	downCorner.CornerRadius = UDim.new(0, 4)
	downCorner.Parent = stepDown
	local downStroke = Instance.new("UIStroke")
	downStroke.Transparency = 0.95
	downStroke.Color = theme.StrokeColor
	downStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	downStroke.Parent = stepDown
	-- Store references
	self.Row = row
	self.Label = label
	self.InputBox = inputBox
	self.InputStroke = inputStroke
	self.StepUp = stepUp
	self.StepDown = stepDown
	self.Min = minValue
	self.Max = maxValue
	self.Step = step
	self.IsInteger = isInteger
	self.Callback = callback
	self._currentValue = math.clamp(defaultValue, minValue, maxValue)
	-- Helper to update input box display
	local function updateDisplay(value)
		local displayValue = isInteger and math.round(value) or value
		inputBox.Text = tostring(displayValue)
		inputBox.PlaceholderText = tostring(displayValue)
	end
	-- Set value (with optional no callback)
	function self:SetValue(value, noCallback)
		local oldValue = self._currentValue
		local clamped = math.clamp(value, self.Min, self.Max)
		if self.IsInteger then
			clamped = math.round(clamped)
		end
		if clamped == oldValue then
			return
		end
		self._currentValue = clamped
		updateDisplay(clamped)
		if not noCallback then
			self.Callback(clamped)
		end
	end
	-- Increment / decrement
	local function stepValue(delta)
		local newValue = self._currentValue + delta * self.Step
		self:SetValue(newValue, false)
	end
	-- Button click handlers
	local function flashButton(btn)
		Tween.CancelAll(btn)
		Tween.Play(btn, "Fast", { BackgroundTransparency = 0 })
		task.wait(0.2)
		Tween.Play(btn, "Fast", { BackgroundTransparency = 1 })
	end
	stepUp.MouseButton1Click:Connect(function()
		stepValue(1)
		flashButton(stepUp)
	end)
	stepDown.MouseButton1Click:Connect(function()
		stepValue(-1)
		flashButton(stepDown)
	end)
	-- Input box focus lost: parse and set value
	inputBox.FocusLost:Connect(function()
		local inputText = inputBox.Text
		local num = tonumber(inputText)
		if num then
			self:SetValue(num, false)
		else
			updateDisplay(self._currentValue)
		end
	end)
	-- Input box stroke brightening on hover/focus (like Keybind/TextInput)
	local function setStrokeBright(bright)
		if not self.InputStroke then return end
		local liveTheme = ActiveTheme.theme or theme
		local targetTrans = bright and 0.3 or (liveTheme and liveTheme.StrokeTransparency or 0.95)
		local targetColor = liveTheme.StrokeColor
		Tween.Play(self.InputStroke, "Fast", {
			Transparency = targetTrans,
			Color = targetColor
		})
	end
	inputBox.MouseEnter:Connect(function()
		setStrokeBright(true)
	end)
	inputBox.MouseLeave:Connect(function()
		if not inputBox:IsFocused() then
			setStrokeBright(false)
		end
	end)
	inputBox.Focused:Connect(function()
		setStrokeBright(true)
	end)
	inputBox.FocusLost:Connect(function()
		setStrokeBright(false)
	end)
	-- Hover effects on buttons: brighten image transparency
	local function onButtonHover(button, bright)
		local targetTrans = bright and 0.3 or 0.6
		Tween.Play(button, "Fast", { ImageTransparency = targetTrans })
	end
	stepUp.MouseEnter:Connect(function() onButtonHover(stepUp, true) end)
	stepUp.MouseLeave:Connect(function() onButtonHover(stepUp, false) end)
	stepDown.MouseEnter:Connect(function() onButtonHover(stepDown, true) end)
	stepDown.MouseLeave:Connect(function() onButtonHover(stepDown, false) end)
	-- Initial display
	updateDisplay(self._currentValue)
	-- Public API
	self.GetValue = function()
		return self._currentValue
	end
	self.SetMin = function(newMin)
		self.Min = newMin
		self:SetValue(self._currentValue, true)
	end
	self.SetMax = function(newMax)
		self.Max = newMax
		self:SetValue(self._currentValue, true)
	end
	self.SetStep = function(newStep)
		self.Step = newStep
	end
	self.SetVisibility = function(visible)
		row.Visible = visible
	end
	self.UpdateName = function(newName)
		label.Text = newName
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
		inputStroke.Color = theme.StrokeColor or inputStroke.Color
		inputStroke.Transparency = theme.StrokeTransparency or inputStroke.Transparency
		stepUp.ImageColor3 = theme.AccentColor or stepUp.ImageColor3
		stepUp.BackgroundColor3 = theme.AccentColor or stepUp.BackgroundColor3
		stepDown.ImageColor3 = theme.AccentColor or stepDown.ImageColor3
		stepDown.BackgroundColor3 = theme.AccentColor or stepDown.BackgroundColor3
		upStroke.Color = theme.StrokeColor or upStroke.Color
		downStroke.Color = theme.StrokeColor or downStroke.Color
	end
	ThemeManager.Register(row, self)
	return self
end
return Stepper