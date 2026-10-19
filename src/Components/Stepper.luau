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
local Odometer = require("../Utils/Odometer")
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
	-- Input shell: the real editable TextBox is transparent at rest; a rolling
	-- Odometer sits on top. Focusing swaps them so typing still works.
	local inputBox = Instance.new("TextBox")
	inputBox.Name = "StepperInputBox"
	inputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	inputBox.BorderSizePixel = 0
	inputBox.TextWrapped = false
	inputBox.TextTransparency = 1
	inputBox.TextSize = 13
	inputBox.TextXAlignment = Enum.TextXAlignment.Center
	inputBox.TextColor3 = (theme and theme.SecondaryTextColor)
	inputBox.BackgroundColor3 = theme.InputBackgroundColor
	inputBox.BackgroundTransparency = theme.InputBackgroundTransparency
	inputBox:SetAttribute("IsInputBackground", true)
	inputBox.FontFace = Constants.Font(Enum.FontWeight.Medium)
	inputBox.AnchorPoint = Vector2.new(1, 0.5)
	inputBox.ClearTextOnFocus = false
	inputBox.PlaceholderText = ""
	inputBox.Size = UDim2.new(0, 64, 0.6, 0)
	inputBox.Position = UDim2.new(1, -36, 0.5, 0)
	inputBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	inputBox.Text = ""
	inputBox.ClipsDescendants = true
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

	local valueReel = Instance.new("Frame")
	valueReel.Name = "ValueReel"
	valueReel.BackgroundTransparency = 1
	valueReel.BorderSizePixel = 0
	valueReel.Size = UDim2.fromScale(1, 1)
	valueReel.ClipsDescendants = true
	valueReel.ZIndex = 2
	valueReel.Parent = inputBox

	local odo = Odometer.new(valueReel, {
		textSize = 13,
		alignment = Enum.HorizontalAlignment.Center,
		transparency = (theme and theme.SecondaryTextTransparency) or 0.4,
		weight = Enum.FontWeight.Medium,
		duration = 0.28,
	})

	-- Step controls: one compact two-segment pill at the right edge.
	local controls = Instance.new("Frame")
	controls.Name = "StepControls"
	controls.AnchorPoint = Vector2.new(1, 0.5)
	controls.Position = UDim2.fromScale(1, 0.5)
	controls.Size = UDim2.fromOffset(24, 32)
	controls.BackgroundColor3 = theme.InputBackgroundColor
	controls.BackgroundTransparency = math.min(0.4, (theme.InputBackgroundTransparency or 0.15) + 0.2)
	controls.BorderSizePixel = 0
	controls.Parent = row
	local controlsCorner = Instance.new("UICorner")
	controlsCorner.CornerRadius = UDim.new(0, 6)
	controlsCorner.Parent = controls
	local controlsStroke = Instance.new("UIStroke")
	controlsStroke.Color = theme.StrokeColor
	controlsStroke.Transparency = 0.9
	controlsStroke.Thickness = 0.7
	controlsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	controlsStroke.Parent = controls
	local controlsPad = Instance.new("UIPadding")
	controlsPad.PaddingTop = UDim.new(0, 2)
	controlsPad.PaddingBottom = UDim.new(0, 2)
	controlsPad.PaddingLeft = UDim.new(0, 2)
	controlsPad.PaddingRight = UDim.new(0, 2)
	controlsPad.Parent = controls
	local controlsLayout = Instance.new("UIListLayout")
	controlsLayout.FillDirection = Enum.FillDirection.Vertical
	controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	controlsLayout.Padding = UDim.new(0, 1)
	controlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	controlsLayout.Parent = controls

	local function makeStepButton(buttonName, icon, order)
		local btn = Instance.new("ImageButton")
		btn.Name = buttonName
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Image = Icons[icon]
		btn.ImageColor3 = theme.AccentColor
		btn.ImageTransparency = 0.1
		btn.BackgroundColor3 = theme.AccentColor
		btn.BackgroundTransparency = 0.82
		btn.LayoutOrder = order
		btn.Size = UDim2.new(1, 0, 0, 13)
		btn.Parent = controls
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = btn
		local scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = btn
		btn.MouseEnter:Connect(function()
			Tween.Play(btn, "Fast", { BackgroundTransparency = 0.62, ImageTransparency = 0 })
			Tween.Play(scale, "HoverIn", { Scale = 1.06 })
		end)
		btn.MouseLeave:Connect(function()
			Tween.Play(btn, "Fast", { BackgroundTransparency = 0.82, ImageTransparency = 0.1 })
			Tween.Play(scale, "HoverOut", { Scale = 1 })
		end)
		btn.MouseButton1Down:Connect(function()
			Tween.Play(scale, "Fast", { Scale = 0.92 })
		end)
		btn.MouseButton1Up:Connect(function()
			Tween.Play(scale, "HoverIn", { Scale = 1.06 })
		end)
		return btn
	end
	local stepUp = makeStepButton("StepUp", "chevron-up", 1)
	local stepDown = makeStepButton("StepDown", "chevron-down", 2)
	-- Store references
	self.Row = row
	self.Label = label
	self.InputBox = inputBox
	self.InputStroke = inputStroke
	self.StepUp = stepUp
	self.StepDown = stepDown
	self.Controls = controls
	self.ValueReel = valueReel
	self.Odometer = odo
	self._name = name
	self.Min = minValue
	self.Max = maxValue
	self.Step = step
	self.IsInteger = isInteger
	self.Callback = callback
	self._currentValue = math.clamp(defaultValue, minValue, maxValue)
	-- Keep the hidden text box and the reel in sync.
	local function updateDisplay(value, up)
		local displayValue = isInteger and math.round(value) or value
		local text = tostring(displayValue)
		inputBox.Text = text
		inputBox.PlaceholderText = ""
		if up == nil then
			odo:snap(text)
		else
			odo:to(text, up)
		end
	end
	-- Set value (with optional no callback)
	self.SetValue = function(me, value, noCallback)
		local oldValue = me._currentValue
		local clamped = math.clamp(value, me.Min, me.Max)
		if me.IsInteger then
			clamped = math.round(clamped)
		end
		if clamped == oldValue then
			return
		end
		me._currentValue = clamped
		updateDisplay(clamped, clamped > oldValue)
		if not noCallback then
			me.Callback(clamped)
		end
	end
	-- Increment / decrement
	local function stepValue(delta)
		local newValue = self._currentValue + delta * self.Step
		self:SetValue(newValue, false)
	end
	stepUp.MouseButton1Click:Connect(function()
		stepValue(1)
	end)
	stepDown.MouseButton1Click:Connect(function()
		stepValue(-1)
	end)
	-- Parse typed values, then restore the reel when the field loses focus.
	inputBox.FocusLost:Connect(function()
		local num = tonumber(inputBox.Text)
		if num then
			self:SetValue(num, false)
		else
			updateDisplay(self._currentValue)
		end
		odo:setTransparency((ActiveTheme.theme or theme).SecondaryTextTransparency or 0.4)
		inputBox.TextTransparency = 1
	end)
	-- Input box stroke brightening on hover/focus (like Keybind/TextInput)
	local function setStrokeBright(bright)
		if not self.InputStroke then
			return
		end
		local liveTheme = ActiveTheme.theme or theme
		local restTrans = liveTheme and liveTheme.StrokeTransparency or 0.95
		local targetTrans = bright and 0.3 or restTrans
		local targetColor = liveTheme.StrokeColor
		Tween.Play(self.InputStroke, "Fast", {
			Transparency = targetTrans,
			Color = targetColor,
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
		odo:setTransparency(1)
		inputBox.TextTransparency = (ActiveTheme.theme or theme).SecondaryTextTransparency or 0.4
		setStrokeBright(true)
	end)
	inputBox.FocusLost:Connect(function()
		setStrokeBright(false)
	end)
	-- Initial display
	updateDisplay(self._currentValue)
	-- Public API
	self.GetValue = function(me)
		return me._currentValue
	end
	self.SetMin = function(me, newMin)
		me.Min = newMin
		me:SetValue(me._currentValue, true)
	end
	self.SetMax = function(me, newMax)
		me.Max = newMax
		me:SetValue(me._currentValue, true)
	end
	self.SetStep = function(me, newStep)
		me.Step = newStep
	end
	self.SetName = function(me, newName)
		me._name = newName
		label.Text = newName
	end
	self.UpdateName = self.SetName
	self.SetVisible = function(me, visible)
		me.Row.Visible = visible
	end
	self.SetVisibility = self.SetVisible
	self.GetVisible = function(me)
		return me.Row.Visible
	end
	-- Declarative theming: every themed property is a BINDING.
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(inputBox, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindColor(inputBox, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindTransparency(inputBox, "BackgroundTransparency", "InputBackgroundTransparency")
	ThemeManager.BindColor(inputStroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(inputStroke, "Transparency", "StrokeTransparency")
	ThemeManager.BindColor(stepUp, "ImageColor3", "AccentColor")
	ThemeManager.BindColor(stepUp, "BackgroundColor3", "AccentColor")
	ThemeManager.BindColor(stepDown, "ImageColor3", "AccentColor")
	ThemeManager.BindColor(stepDown, "BackgroundColor3", "AccentColor")
	ThemeManager.BindColor(controls, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindColor(controlsStroke, "Color", "StrokeColor")
	ThemeManager.OnThemeApplied(function(liveTheme)
		if not inputBox:IsFocused() then
			odo:setTransparency(liveTheme.SecondaryTextTransparency or 0.4)
		end
	end, valueReel)
	self.Destroy = function(me)
		-- Cancel any in-flight tweens on the buttons, reel, and stroke.
		Tween.CancelAll(stepUp)
		Tween.CancelAll(stepDown)
		Tween.CancelAll(inputStroke)
		Tween.CancelAllUnder(valueReel)
		-- Drop all ThemeManager bindings.
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(inputBox)
		ThemeManager.UnbindInstance(inputStroke)
		ThemeManager.UnbindInstance(stepUp)
		ThemeManager.UnbindInstance(stepDown)
		ThemeManager.UnbindInstance(controls)
		ThemeManager.UnbindInstance(controlsStroke)
		ThemeManager.UnbindInstance(valueReel)
		for _, descendant in ipairs(valueReel:GetDescendants()) do
			ThemeManager.UnbindInstance(descendant)
		end
		-- Destroy the root instance.
		if me.Row and me.Row.Parent then
			me.Row:Destroy()
		end
	end
	return self
end
return Stepper
