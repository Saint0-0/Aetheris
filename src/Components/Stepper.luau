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
local Constants = require("../Constants")
local ComponentRow = require("./ComponentRow")
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
	-- Shared row factory (row name + label width preserved for layout parity).
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "Stepper",
		Theme = theme,
		LabelWidth = 0.48591,
	})
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
	inputBox.FontFace = Constants.Font(Enum.FontWeight.Medium)
	inputBox.AnchorPoint = Vector2.new(1, 0.5)
	inputBox.ClearTextOnFocus = false
	inputBox.PlaceholderText = tostring(defaultValue)
	inputBox.Size = UDim2.new(0, 60, 0.6, 0)
	inputBox.AutomaticSize = Enum.AutomaticSize.X
	inputBox.Position = UDim2.new(1, -30, 0.5, 0)
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
		local restTrans = liveTheme and liveTheme.StrokeTransparency or 0.95
		local targetTrans = bright and 0.3 or restTrans
		local targetColor = liveTheme.StrokeColor
		Tween.Play(self.InputStroke, "Fast", {
			Transparency = targetTrans,
			Color = targetColor
		})
		-- Keep PageFade's cached base at the RESTING transparency so a page fade
		-- never restores a transient hover/focus brighten.
		self.InputStroke:SetAttribute("PageFadeBase", restTrans)
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
	self.UpdateName = function(newName)
		label.Text = newName
	end
	-- Declarative theming: every themed property is a BINDING.
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(inputBox, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(inputBox, "TextTransparency", "SecondaryTextTransparency")
	ThemeManager.BindColor(inputBox, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindTransparency(inputBox, "BackgroundTransparency", "InputBackgroundTransparency")
	ThemeManager.BindColor(inputStroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(inputStroke, "Transparency", "StrokeTransparency")
	ThemeManager.BindColor(stepUp, "ImageColor3", "AccentColor")
	ThemeManager.BindColor(stepUp, "BackgroundColor3", "AccentColor")
	ThemeManager.BindColor(stepDown, "ImageColor3", "AccentColor")
	ThemeManager.BindColor(stepDown, "BackgroundColor3", "AccentColor")
	ThemeManager.BindColor(upStroke, "Color", "StrokeColor")
	ThemeManager.BindColor(downStroke, "Color", "StrokeColor")
	-- Uniform component API (p2-4).
	function self:SetVisibility(visible)
		row.Visible = visible
	end
	function self:Destroy()
		-- Cancel any in-flight tweens on the buttons and stroke.
		Tween.CancelAll(stepUp)
		Tween.CancelAll(stepDown)
		Tween.CancelAll(inputStroke)
		-- Drop all ThemeManager bindings.
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(inputBox)
		ThemeManager.UnbindInstance(inputStroke)
		ThemeManager.UnbindInstance(stepUp)
		ThemeManager.UnbindInstance(stepDown)
		ThemeManager.UnbindInstance(upStroke)
		ThemeManager.UnbindInstance(downStroke)
		-- Destroy the root instance.
		if row and row.Parent then
			row:Destroy()
		end
	end
	return self
end
return Stepper