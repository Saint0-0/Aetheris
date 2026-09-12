--[[
	ProgressBar  ·  Aetheris UI Library

	Read-only progress bar: label, track, spinning-gradient fill, and an
	optional value/percentage readout. Use SetValue to animate the fill.

	Usage:
		local bar = section:ProgressBar({
			Name = "Loading",
			MinValue = 0,
			MaxValue = 100,
			Value = 0,
			ShowPercentage = true,
		})
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local FallbackImage = require("../Constants").FallbackImage
local ProgressBar = {}
ProgressBar.__index = ProgressBar
-- Global control for spinning animations
ProgressBar.SpinningEnabled = true
function ProgressBar.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, ProgressBar)
	self._theme = theme
	local name = Settings.Name or "Progress Bar"
	local minValue = Settings.MinValue or 0
	local maxValue = Settings.MaxValue or 100
	local currentValue = Settings.Value or 0
	local showPercentage = (Settings.ShowPercentage == nil) and true or Settings.ShowPercentage
	local showFraction = Settings.ShowFraction or false
	local color = Settings.Color
	local animate = (Settings.Animate == nil) and true or Settings.Animate
	local spinEnabled = (Settings.SpinningEnabled == nil) and true or Settings.SpinningEnabled
	-- Build UI from export
	local row = Instance.new("Frame")
	row.Name = name .. "ProgressBar"
	row.BorderSizePixel = 0
	row.BackgroundColor3 = Color3.fromRGB(31, 32, 34)
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 45)
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.new(0.5, 0, 0.5, 0)
	row.BorderColor3 = Color3.fromRGB(0, 0, 0)
	row.Parent = parent
	local label = Instance.new("TextLabel")
	label.Name = "ElementName"
	label.TextWrapped = true
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.BorderSizePixel = 0
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTransparency = theme.PrimaryTextTransparency
	label.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	label.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	label.TextColor3 = theme.PrimaryTextColor
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.59985, 0, 0.31745, 0)
	label.BorderColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = name
	label.Position = UDim2.new(0, 0, 0.12063, 0)
	label.Parent = row
	local holder = Instance.new("Frame")
	holder.Name = "ProgressBarHolder"
	holder.BorderSizePixel = 0
	holder.BackgroundColor3 = theme.Undercolor
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Size = UDim2.new(1, 0, 0.07, 0)
	holder.Position = UDim2.new(0.5003, 0, 0.72338, 0)
	holder.BorderColor3 = Color3.fromRGB(255, 255, 255)
	holder.Parent = row
	local holderCorner = Instance.new("UICorner")
	holderCorner.CornerRadius = UDim.new(0, 5)
	holderCorner.Parent = holder
	local holderShadow = Instance.new("UIShadow")
	holderShadow.Parent = holder
	local visual = Instance.new("Frame")
	visual.Name = "Visual"
	visual.BorderSizePixel = 0
	visual.BackgroundColor3 = (theme and theme.PrimaryColor)
	visual.Size = UDim2.new(0, 0, 1, 0) -- start empty
	visual.BorderColor3 = Color3.fromRGB(0, 0, 0)
	visual.Parent = holder
	local visualCorner = Instance.new("UICorner")
	visualCorner.CornerRadius = UDim.new(0, 6)
	visualCorner.Parent = visual
	local backImage = Instance.new("ImageLabel")
	backImage.Name = "BackImage"
	backImage.BorderSizePixel = 0
	backImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	backImage.ImageTransparency = 0.5
	backImage.AnchorPoint = Vector2.new(0.5, 0.5)
	local imageId = (theme and theme.Wallpaper) or FallbackImage
	backImage.Image = imageId
	backImage:SetAttribute("IsThemeSheen", true)
	backImage.Size = UDim2.new(1, 0, 1, 0)
	backImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	backImage.BackgroundTransparency = 1
	backImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	backImage.Parent = visual
	-- Set visibility based on theme's WallpaperEnabled
	backImage.Visible = not (theme and theme.WallpaperEnabled == false)
	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 6)
	backCorner.Parent = backImage
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0.000, 1),
		NumberSequenceKeypoint.new(0.324, 0.80625),
		NumberSequenceKeypoint.new(0.600, 0.6875),
		NumberSequenceKeypoint.new(0.726, 0.55),
		NumberSequenceKeypoint.new(0.844, 0.36875),
		NumberSequenceKeypoint.new(1.000, 0)
	}
	gradient.Parent = backImage
	local stats = Instance.new("TextLabel")
	stats.Name = "ProgressBarStats"
	stats.TextTruncate = Enum.TextTruncate.AtEnd
	stats.BorderSizePixel = 0
	stats.TextSize = 12
	stats.TextXAlignment = Enum.TextXAlignment.Right
	stats.TextTransparency = theme.PrimaryTextTransparency
	stats.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	stats.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	stats.TextColor3 = theme.PrimaryTextColor
	stats.BackgroundTransparency = 1
	stats.RichText = true
	stats.AnchorPoint = Vector2.new(1, 0)
	stats.Size = UDim2.new(0.43, 0, 0, 14)
	stats.BorderColor3 = Color3.fromRGB(0, 0, 0)
	stats.Text = ""
	stats.Position = UDim2.new(1, 0, 0.12063, 0)
	stats.Parent = row
	-- Store references
	self.Row = row
	self.Label = label
	self.Holder = holder
	self.Visual = visual
	self.BackImage = backImage
	self.Gradient = gradient
	self.Stats = stats
	self.MinValue = minValue
	self.MaxValue = maxValue
	self.Color = color
	self.Animate = animate
	self._spinTween = nil
	self._currentValue = nil
	-- Helper to update stats text
	local function updateStats(value)
		if showPercentage and showFraction then
			local percent = (value - minValue) / (maxValue - minValue) * 100
			stats.Text = string.format("<b>%d%%</b> | %d/%d", math.round(percent), value, maxValue)
		elseif showPercentage then
			local percent = (value - minValue) / (maxValue - minValue) * 100
			stats.Text = string.format("<b>%d%%</b>", math.round(percent))
		elseif showFraction then
			stats.Text = string.format("%d/%d", value, maxValue)
		else
			stats.Text = ""
		end
	end
	-- Set progress value
	function self:SetValue(value, noAnimate)
		value = math.clamp(value, self.MinValue, self.MaxValue)
		self._currentValue = value
		local percentage = (value - self.MinValue) / (self.MaxValue - self.MinValue)
		local targetSize = UDim2.new(percentage, 0, 1, 0)
		local animateProgress = (noAnimate == nil) and self.Animate or not noAnimate
		if animateProgress then
			Tween.Play(self.Visual, "Smooth", { Size = targetSize })
		else
			self.Visual.Size = targetSize
		end
		updateStats(value)
		if Settings.Callback then
			Settings.Callback(value)
		end
	end
	-- Initialize value
	self:SetValue(currentValue, true)
	-- Spinning gradient
	local function startSpin()
		if not ProgressBar.SpinningEnabled then return end
		self.Gradient.Rotation = 0
		self._spinTween = Tween.StartSpin(self.Gradient, { Rotation = 360 }, "SpinIdle")
	end
	local function stopSpin()
		Tween.StopSpin(self.Gradient)
		self._spinTween = nil
	end
	if spinEnabled and ProgressBar.SpinningEnabled then
		startSpin()
	end
	-- Public API
	self.GetValue = function()
		return self._currentValue
	end
	self.SetMin = function(newMin)
		self.MinValue = newMin
		self:SetValue(self._currentValue, true)
	end
	self.SetMax = function(newMax)
		self.MaxValue = newMax
		self:SetValue(self._currentValue, true)
	end
	self.SetColor = function(newColor)
		self.Color = newColor
		self.Visual.BackgroundColor3 = newColor
	end
	self.SetVisibility = function(visible)
		self.Row.Visible = visible
	end
	self.UpdateName = function(newName)
		self.Label.Text = newName
	end
	self.EnableSpinning = function(enabled)
		if enabled then
			startSpin()
		else
			stopSpin()
		end
	end
	-- Component-owned theming (see ThemeManager registry).
	function self:ApplyTheme(newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		self._theme = theme
		label.TextColor3 = theme.PrimaryTextColor or label.TextColor3
		label.TextTransparency = theme.PrimaryTextTransparency or label.TextTransparency
		stats.TextColor3 = theme.PrimaryTextColor or stats.TextColor3
		stats.TextTransparency = theme.PrimaryTextTransparency or stats.TextTransparency
		holder.BackgroundColor3 = theme.Undercolor or holder.BackgroundColor3
		-- A custom Color (Settings.Color) wins over the theme's PrimaryColor.
		visual.BackgroundColor3 = self.Color or theme.PrimaryColor or visual.BackgroundColor3
		backImage.Image = theme.Wallpaper or FallbackImage
		backImage.Visible = not (theme.WallpaperEnabled == false)
		holderShadow.Color = theme.ComponentShadowColor or holderShadow.Color
	end
	ThemeManager.Register(row, self)
	return self
end
return ProgressBar