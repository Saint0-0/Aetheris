--[[
	Aetheris/Components/Button.luau

	Clickable action row with a hover/press bounce and an optional trailing
	fingerprint icon. Clicking runs the callback and plays a short flash
	animation that restarts cleanly on rapid clicks.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local ComponentRow = require("./ComponentRow")
local ComponentAPI = require("../Utils/ComponentAPI")
local UUID = require("../Utils/UUID")
local Button = {}
Button.__index = Button
function Button.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Button)
	self._theme = theme
	local name = Settings.Name or "Button"
	local callback = Settings.Callback or function() end
	local FINGERPRINT_IMAGE = Icons["fingerprint-pattern"]
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. " [Button]",
		Theme = theme,
		Clickable = true,
		LabelWidth = 0.486,
		LabelPosition = UDim2.new(0, 10, 0.5, 0),
		BackgroundColor = (theme and theme.ComponentBackgroundColor),
		BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985,
		CornerRadius = 6,
		ComponentContainer = true,
	})
	label.ZIndex = 2
	local buttonColor = Instance.new("Frame")
	buttonColor.Name = UUID.Static("ButtonColor")
	buttonColor.BorderSizePixel = 0
	buttonColor.BackgroundColor3 = (theme and theme.PrimaryColor)
	buttonColor.BackgroundTransparency = 1
	buttonColor.AnchorPoint = Vector2.new(0.5, 0.5)
	buttonColor.Size = UDim2.fromScale(1, 1)
	buttonColor.Position = UDim2.fromScale(0.5, 0.5)
	buttonColor.Parent = row
	local colorCorner = Instance.new("UICorner")
	colorCorner.CornerRadius = UDim.new(0, 6)
	colorCorner.Parent = buttonColor
	local fingerprint = Instance.new("ImageLabel")
	fingerprint.Name = UUID.Static("Fingerprint")
	fingerprint.BorderSizePixel = 0
	fingerprint.BackgroundTransparency = 1
	fingerprint.ImageTransparency = 0.5
	fingerprint.AnchorPoint = Vector2.new(0.5, 0.5)
	fingerprint.Image = FINGERPRINT_IMAGE
	fingerprint.ImageColor3 = (theme and theme.AccentColor)
	fingerprint.Size = UDim2.fromOffset(24, 24)
	fingerprint.Position = UDim2.new(1, -30, 0.5, 0)
	fingerprint.Parent = row
	local fpAspect = Instance.new("UIAspectRatioConstraint")
	fpAspect.DominantAxis = Enum.DominantAxis.Height
	fpAspect.Parent = fingerprint
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	stroke.Thickness = 0.7
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = row
	self.Row = row
	self.Label = label
	self.ButtonColor = buttonColor
	self.Fingerprint = fingerprint
	self.Callback = callback
	self._clicking = false
	local FINGERPRINT_BASE = 0.5
	local BUTTONCOLOR_BASE = 1
	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = row
	local isHovered = false
	row.MouseEnter:Connect(function()
		isHovered = true
		Tween.CancelAll(fingerprint)
		Tween.Play(fingerprint, "Smooth", {
			ImageTransparency = 0.2,
		})
		Tween.Play(scale, "HoverIn", { Scale = 1.02 })
	end)
	row.MouseLeave:Connect(function()
		isHovered = false
		Tween.CancelAll(fingerprint)
		Tween.Play(fingerprint, "Smooth", {
			ImageTransparency = FINGERPRINT_BASE,
		})
		Tween.Play(scale, "HoverOut", { Scale = 1 })
	end)
	row.MouseButton1Down:Connect(function()
		Tween.Play(scale, "Fast", { Scale = 0.97 })
	end)
	row.MouseButton1Up:Connect(function()
		Tween.Play(scale, "HoverIn", { Scale = isHovered and 1.02 or 1 })
	end)
	local function performClick()
		-- Rapid clicks restart the flash instead of stacking or locking the button.
		Tween.CancelAll(buttonColor)
		Tween.CancelAll(fingerprint)
		Tween.Play(buttonColor, "Click", {
			BackgroundTransparency = 0.15,
		})
		Tween.Play(fingerprint, "Click", {
			ImageTransparency = 0.1,
		})
		task.delay(0.12, function()
			if not row.Parent then
				return
			end
			Tween.Play(buttonColor, "Release", {
				BackgroundTransparency = BUTTONCOLOR_BASE,
			})
			Tween.Play(fingerprint, "Smooth", {
				ImageTransparency = isHovered and 0.2 or FINGERPRINT_BASE,
			})
		end)
		self.Callback()
	end
	row.MouseButton1Click:Connect(performClick)
	self.UpdateName = function(_, newName)
		label.Text = newName
	end
	self.Click = function()
		performClick()
	end
	ThemeManager.BindColor(row, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(buttonColor, "BackgroundColor3", "PrimaryColor")
	ThemeManager.BindColor(fingerprint, "ImageColor3", "AccentColor")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	-- Interaction transparencies aren't theme-bound; re-stamp them on theme
	-- switch so a mid-tween hover/click value isn't captured.
	local function restampInteractionBases()
		fingerprint.ImageTransparency = isHovered and 0.2 or FINGERPRINT_BASE
		buttonColor.BackgroundTransparency = BUTTONCOLOR_BASE
	end
	local unregisterTheme = ThemeManager.OnThemeApplied(restampInteractionBases, row)

	self.SetVisibility = function(_self, visible)
		row.Visible = visible
	end
	self.Destroy = function(_self)
		if unregisterTheme then
			unregisterTheme()
			unregisterTheme = nil
		end
		ThemeManager.UnbindInstance(row)
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(buttonColor)
		ThemeManager.UnbindInstance(fingerprint)
		ThemeManager.UnbindInstance(stroke)
		Tween.CancelAll(buttonColor)
		Tween.CancelAll(fingerprint)
		if row.Parent then
			row:Destroy()
		end
	end

	ComponentAPI.Apply(self, { Root = row, Label = label, Name = name })
	return self
end
return Button
