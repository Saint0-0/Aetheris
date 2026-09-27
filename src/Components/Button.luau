--[[
	Button  ·  Aetheris UI Library

	Clickable action row with a hover/press bounce and an optional trailing
	fingerprint icon. No BackImage (removed by design).

	Usage:
		local button = section:Button({
			Name = "Reset Layout",
			Callback = function() end,
		})
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local Constants = require("../Constants")
local ComponentRow = require("./ComponentRow")
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
	-- Main row (TextButton)
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
	-- ButtonColor frame (background glow)
	local buttonColor = Instance.new("Frame")
	buttonColor.Name = "ButtonColor"
	buttonColor.BorderSizePixel = 0
	buttonColor.BackgroundColor3 = (theme and theme.PrimaryColor)
	buttonColor.BackgroundTransparency = 1
	buttonColor.AnchorPoint = Vector2.new(0.5, 0.5)
	buttonColor.Size = UDim2.new(1, 0, 1, 0)
	buttonColor.Position = UDim2.new(0.5, 0, 0.5, 0)
	buttonColor.Parent = row
	local colorCorner = Instance.new("UICorner")
	colorCorner.CornerRadius = UDim.new(0, 6)
	colorCorner.Parent = buttonColor
	-- Fingerprint ImageLabel
	local fingerprint = Instance.new("ImageLabel")
	fingerprint.Name = "Fingerprint"
	fingerprint.BorderSizePixel = 0
	fingerprint.BackgroundTransparency = 1
	fingerprint.ImageTransparency = 0.5
	fingerprint.AnchorPoint = Vector2.new(0.5, 0.5)
	fingerprint.Image = FINGERPRINT_IMAGE
	fingerprint.ImageColor3 = (theme and theme.AccentColor)
	fingerprint.Size = UDim2.new(0, 24, 0, 24)
	fingerprint.Position = UDim2.new(1, -30, 0.5, 0)
	fingerprint.Parent = row
	local fpAspect = Instance.new("UIAspectRatioConstraint")
	fpAspect.DominantAxis = Enum.DominantAxis.Height
	fpAspect.Parent = fingerprint
	-- UIStroke for the button border
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	stroke.Thickness = 0.7
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = row
	-- Store references
	self.Row = row
	self.Label = label
	self.ButtonColor = buttonColor
	self.Fingerprint = fingerprint
	self.Callback = callback
	self._clicking = false
	-- Base transparencies
	local FINGERPRINT_BASE = 0.5
	local BUTTONCOLOR_BASE = 1
	-- Hover/press scale bounce, matching the window-control buttons' feel.
	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = row
	-- Hover state
	local isHovered = false
	-- Hover effects
	row.MouseEnter:Connect(function()
		isHovered = true
		Tween.CancelAll(fingerprint)
		Tween.Play(fingerprint, "Smooth", {
			ImageTransparency = 0.2
		})
		Tween.Play(scale, "HoverIn", { Scale = 1.02 })
	end)
	row.MouseLeave:Connect(function()
		isHovered = false
		Tween.CancelAll(fingerprint)
		Tween.Play(fingerprint, "Smooth", {
			ImageTransparency = FINGERPRINT_BASE
		})
		Tween.Play(scale, "HoverOut", { Scale = 1 })
	end)
	row.MouseButton1Down:Connect(function()
		Tween.Play(scale, "Fast", { Scale = 0.97 })
	end)
	row.MouseButton1Up:Connect(function()
		Tween.Play(scale, "HoverIn", { Scale = isHovered and 1.02 or 1 })
	end)
	-- Click flash sequence
	local function performClick()
		-- Restart the visual feedback immediately on every click
		Tween.CancelAll(buttonColor)
		Tween.CancelAll(fingerprint)
		-- Flash in
		Tween.Play(buttonColor, "Click", {
			BackgroundTransparency = 0.15
		})
		Tween.Play(fingerprint, "Click", {
			ImageTransparency = 0.1
		})
		-- Fade back out shortly after the flash.
		-- Rapid clicks restart the animation instead of locking the button.
		task.delay(0.12, function()
			if not row.Parent then
				return
			end
			Tween.Play(buttonColor, "Release", {
				BackgroundTransparency = BUTTONCOLOR_BASE
			})
			Tween.Play(fingerprint, "Smooth", {
				ImageTransparency = isHovered and 0.2 or FINGERPRINT_BASE
			})
		end)
		-- Fire callback immediately; animation never blocks button behavior.
		self.Callback()
	end
	row.MouseButton1Click:Connect(performClick)
	-- Public API
	self.UpdateName = function(newName)
		label.Text = newName
	end
	self.Click = function()
		performClick()
	end
	-- Declarative theming: every themed property is a BINDING.
	ThemeManager.BindColor(row, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(buttonColor, "BackgroundColor3", "PrimaryColor")
	ThemeManager.BindColor(fingerprint, "ImageColor3", "AccentColor")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	-- Fingerprint / glow transparencies are INTERACTION state (hover/click),
	-- not theme-driven, so they are NOT bound. Re-stamp them to their natural
	-- base on each theme switch: a switch cancels in-flight hover/click tweens
	-- and the page-fade cache re-primes right after, so without this it would
	-- capture a mid-tween value and the fingerprint would never restore.
	local unregisterTheme = ThemeManager.OnThemeApplied(restampInteractionBases, row)

	-- Uniform component API (p2-4).
	function self:SetVisibility(visible)
		row.Visible = visible
	end
	function self:Destroy()
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

	return self
end
return Button