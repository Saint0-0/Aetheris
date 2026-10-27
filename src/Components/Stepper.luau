--[[
	Aetheris/Components/Stepper.luau

	Numeric input with +/- buttons. Clamps to Min/Max, advances by Step, and
	rounds to Precision. The value shows on a shared chip (ValueReadout):
	focusing its odometer swaps in a text field, and the typed number commits
	on focus loss.
	License: Saint0-0 Source License - use in your own scripts, no editing or
	redistribution without permission. (c) 2026 Saint0-0.
]]

local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local ThemeManager = require("../Themes/ThemeManager")
local ComponentRow = require("./ComponentRow")
local ValueReadout = require("./ValueReadout")
local PageAwareness = require("../Utils/PageAwareness")
local UUID = require("../Utils/UUID")
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
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "Stepper",
		Theme = theme,
		LabelWidth = 0.48591,
	})
	local readout = ValueReadout.new(row, {
		Theme = theme,
		Size = UDim2.new(0, 50, 0.6, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -50, 0.5, 0),
		TextSize = 13,
		OdometerHeight = 20,
		CornerRadius = 6,
		ClearTextOnFocus = false,
	})

	-- bare icon buttons at the right edge: no chrome, 20x20 targets with a
	-- 6px gap so the cluster stays compact but tappable
	local controls = Instance.new("Frame")
	controls.Name = UUID.Static("StepControls")
	controls.AnchorPoint = Vector2.new(1, 0.5)
	controls.Position = UDim2.fromScale(1, 0.5)
	controls.Size = UDim2.fromOffset(44, 20)
	controls.BackgroundTransparency = 1
	controls.BorderSizePixel = 0
	controls.Parent = row
	local controlsLayout = Instance.new("UIListLayout")
	controlsLayout.FillDirection = Enum.FillDirection.Horizontal
	controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	controlsLayout.Padding = UDim.new(0, 4)
	controlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	controlsLayout.Parent = controls

	local function makeStepButton(icon, order)
		local btn = Instance.new("ImageButton")
		btn.Name = UUID.Generate("StepButton")
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Image = Icons[icon]
		btn.ImageColor3 = theme.AccentColor
		btn.ImageTransparency = 0.15
		btn.BackgroundTransparency = 1
		btn.LayoutOrder = order
		btn.Size = UDim2.fromOffset(20, 20)
		btn.Parent = controls
		local scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = btn
		btn.MouseEnter:Connect(function()
			Tween.Play(btn, "Fast", { ImageTransparency = 0 })
			Tween.Play(scale, "HoverIn", { Scale = 1.08 })
		end)
		btn.MouseLeave:Connect(function()
			Tween.Play(btn, "Fast", { ImageTransparency = 0.15 })
			Tween.Play(scale, "HoverOut", { Scale = 1 })
		end)
		btn.MouseButton1Down:Connect(function()
			Tween.Play(scale, "Fast", { Scale = 0.9 })
		end)
		btn.MouseButton1Up:Connect(function()
			Tween.Play(scale, "HoverIn", { Scale = 1.08 })
		end)
		return btn
	end
	local stepUp = makeStepButton("arrow-up-1-0", 1)
	local stepDown = makeStepButton("arrow-down-0-1", 2)
	self.Row = row
	self.Label = label
	self.InputBox = readout.Instance
	self.InputStroke = readout.Stroke
	self.StepUp = stepUp
	self.StepDown = stepDown
	self.Controls = controls
	self.Odometer = readout.Odometer
	self._name = name
	self.Min = minValue
	self.Max = maxValue
	self.Step = step
	self.IsInteger = isInteger
	self.Callback = callback
	self._currentValue = math.clamp(defaultValue, minValue, maxValue)
	local function updateDisplay(value, up)
		local displayValue = isInteger and math.round(value) or value
		readout:SetValue(tostring(displayValue), up)
	end
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
	-- typed values take the same clamp/round path as the buttons
	readout.OnCommit = function(num)
		self:SetValue(num, false)
	end
	updateDisplay(self._currentValue)

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
	-- the chip runs its own theme pass (accent card, state alphas, colours)
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(stepUp, "ImageColor3", "AccentColor")
	ThemeManager.BindColor(stepDown, "ImageColor3", "AccentColor")

	-- off-page the readout dims and the step icons fade; `instant` snaps at
	-- registration so the first restore has distance to cover
	PageAwareness.Register(row, {
		Gate = "PageAnimations",
		OnInactive = function(instant)
			readout:SetDimmed(true, instant)
			if instant then
				stepUp.ImageTransparency = 1
				stepDown.ImageTransparency = 1
			else
				Tween.Play(stepUp, "Fast", { ImageTransparency = 1 })
				Tween.Play(stepDown, "Fast", { ImageTransparency = 1 })
			end
		end,
		OnActive = function()
			readout:SetDimmed(false)
			Tween.Play(stepUp, "Fast", { ImageTransparency = 0.15 })
			Tween.Play(stepDown, "Fast", { ImageTransparency = 0.15 })
		end,
	})

	self.Destroy = function(me)
		Tween.CancelAll(stepUp)
		Tween.CancelAll(stepDown)
		readout:Destroy()
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(stepUp)
		ThemeManager.UnbindInstance(stepDown)
		ThemeManager.UnbindInstance(controls)
		if me.Row and me.Row.Parent then
			me.Row:Destroy()
		end
	end
	return self
end
return Stepper
