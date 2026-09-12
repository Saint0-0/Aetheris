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
	local row = Instance.new("TextButton")
	row.Name = name .. " [Button]"
	row.BorderSizePixel = 0
	row.BackgroundColor3 = (theme and theme.ComponentBackgroundColor)
	row.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	row.Size = UDim2.new(1, 0, 0, 45)
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.new(0.5, 0, 0.5, 0)
	row.Text = ""
	row.TextTransparency = 1
	row.AutoButtonColor = false
	row:SetAttribute("IsComponentContainer", true)
	row.Parent = parent
	-- UI Corner Button
	local corner = Instance.new("UICorner")
	corner.Name = "UICorner"
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = row
	-- Label
	local label = Instance.new("TextLabel")
	label.Name = "ElementName"
	label.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	label.Text = name
	label.TextColor3 = (theme and theme.PrimaryTextColor)
	label.TextSize = 14
	label.TextTransparency = (theme and theme.PrimaryTextTransparency) or 0.45
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.486, 0, 0.714, 0)
	label.Position = UDim2.new(0, 10, 0.5, 0)
	label.ZIndex = 2
	label.Parent = row
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
	-- Hover state
	local isHovered = false
	-- Hover effects
	row.MouseEnter:Connect(function()
		isHovered = true
		Tween.CancelAll(fingerprint)
		Tween.Play(fingerprint, "Smooth", {
			ImageTransparency = 0.2
		})
	end)
	row.MouseLeave:Connect(function()
		isHovered = false
		Tween.CancelAll(fingerprint)
		Tween.Play(fingerprint, "Smooth", {
			ImageTransparency = FINGERPRINT_BASE
		})
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
	self.SetVisibility = function(visible)
		row.Visible = visible
	end
	self.UpdateName = function(newName)
		label.Text = newName
	end
	self.Click = function()
		performClick()
	end
	-- Component-owned theming (see ThemeManager registry).
	function self:ApplyTheme(newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		self._theme = theme
		row.BackgroundColor3 = theme.ComponentBackgroundColor or row.BackgroundColor3
		label.TextColor3 = theme.PrimaryTextColor or label.TextColor3
		buttonColor.BackgroundColor3 = theme.PrimaryColor or buttonColor.BackgroundColor3
		fingerprint.ImageColor3 = theme.AccentColor or fingerprint.ImageColor3
		stroke.Color = theme.StrokeColor or stroke.Color
		stroke.Transparency = theme.StrokeTransparency or stroke.Transparency
	end
	ThemeManager.Register(row, self)
	return self
end
return Button