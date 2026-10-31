--[[
	Aetheris/Components/ProgressBar.luau

	Read-only progress bar: label, track, spinning-gradient fill, and an
	optional value/percentage readout. Use SetValue to animate the fill.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local Constants = require("../Constants")
local ComponentRow = require("./ComponentRow")
local ComponentAPI = require("../Utils/ComponentAPI")
local UUID = require("../Utils/UUID")
local FallbackImage = Constants.FallbackImage
local ProgressBar = {}
ProgressBar.__index = ProgressBar

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
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "ProgressBar",
		Theme = theme,
		LabelWidth = 0.59985,
		LabelHeight = 0.31745,
		LabelPosition = UDim2.fromScale(0, 0.12063),
	})
	local holder = Instance.new("Frame")
	holder.Name = UUID.Static("ProgressBarHolder")
	holder.BorderSizePixel = 0
	holder.BackgroundColor3 = theme.Undercolor
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Size = UDim2.fromScale(1, 0.07)
	holder.Position = UDim2.fromScale(0.5003, 0.72338)
	holder.BorderColor3 = Color3.fromRGB(255, 255, 255)
	holder.Parent = row
	local holderCorner = Instance.new("UICorner")
	holderCorner.CornerRadius = UDim.new(0, 5)
	holderCorner.Parent = holder
	local holderShadow = Instance.new("UIShadow")
	holderShadow.Parent = holder
	local visual = Instance.new("Frame")
	visual.Name = UUID.Static("Visual")
	visual.BorderSizePixel = 0
	visual.BackgroundColor3 = color or (theme and theme.PrimaryColor)
	visual.Size = UDim2.fromScale(0, 1)
	visual.BorderColor3 = Color3.fromRGB(0, 0, 0)
	visual.Parent = holder
	local visualCorner = Instance.new("UICorner")
	visualCorner.CornerRadius = UDim.new(0, 6)
	visualCorner.Parent = visual
	local backImage = Instance.new("ImageLabel")
	backImage.Name = UUID.Static("BackImage")
	backImage.BorderSizePixel = 0
	backImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	backImage.ImageTransparency = 0.5
	backImage.AnchorPoint = Vector2.new(0.5, 0.5)
	local imageId = (theme and theme.Wallpaper) or FallbackImage
	backImage.Image = imageId
	backImage:SetAttribute(UUID.Static("IsThemeSheen"), true)
	backImage.Size = UDim2.fromScale(1, 1)
	backImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	backImage.BackgroundTransparency = 1
	backImage.Position = UDim2.fromScale(0.5, 0.5)
	backImage.Parent = visual
	backImage.Visible = not (theme and theme.WallpaperEnabled == false)
	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 6)
	backCorner.Parent = backImage
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.000, 1),
		NumberSequenceKeypoint.new(0.324, 0.80625),
		NumberSequenceKeypoint.new(0.600, 0.6875),
		NumberSequenceKeypoint.new(0.726, 0.55),
		NumberSequenceKeypoint.new(0.844, 0.36875),
		NumberSequenceKeypoint.new(1.000, 0),
	})
	gradient.Parent = backImage
	local stats = Instance.new("TextLabel")
	stats.Name = UUID.Static("ProgressBarStats")
	stats.TextTruncate = Enum.TextTruncate.AtEnd
	stats.BorderSizePixel = 0
	stats.TextSize = 12
	stats.TextXAlignment = Enum.TextXAlignment.Right
	stats.TextTransparency = theme.PrimaryTextTransparency
	stats.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	stats.FontFace = Constants.Font(Enum.FontWeight.Regular)
	stats.TextColor3 = theme.PrimaryTextColor
	stats.BackgroundTransparency = 1
	stats.RichText = true
	stats.AnchorPoint = Vector2.new(1, 0)
	stats.Size = UDim2.new(0.43, 0, 0, 14)
	stats.BorderColor3 = Color3.fromRGB(0, 0, 0)
	stats.Text = ""
	stats.Position = UDim2.fromScale(1, 0.12063)
	stats.Parent = row
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
	-- a custom colour is override-locked so theme switches leave it alone
	if color then
		ThemeManager.SetColorOverride(visual, "BackgroundColor3", color)
	end
	self.Animate = animate
	self._spinTween = nil
	self._currentValue = nil
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
	self.SetValue = function(me, value, noAnimate)
		value = math.clamp(value, me.MinValue, me.MaxValue)
		me._currentValue = value
		local percentage = (value - me.MinValue) / (me.MaxValue - me.MinValue)
		local targetSize = UDim2.fromScale(percentage, 1)
		local animateProgress = (noAnimate == nil) and me.Animate or not noAnimate
		if animateProgress then
			Tween.Play(me.Visual, "Smooth", { Size = targetSize })
		else
			me.Visual.Size = targetSize
		end
		updateStats(value)
		if Settings.Callback then
			Settings.Callback(value)
		end
	end
	self:SetValue(currentValue, true)

	local function startSpin()
		self.Gradient.Rotation = 0
		self._spinTween = Tween.StartSpin(self.Gradient, { Rotation = 360 }, "SpinIdle")
	end
	local function stopSpin()
		Tween.StopSpin(self.Gradient)
		self._spinTween = nil
	end
	if spinEnabled then
		startSpin()
	end
	self.GetValue = function()
		return self._currentValue
	end
	self.SetMin = function(_, newMin)
		self.MinValue = newMin
		self:SetValue(self._currentValue, true)
	end
	self.SetMax = function(_, newMax)
		self.MaxValue = newMax
		self:SetValue(self._currentValue, true)
	end
	self.SetColor = function(_, newColor)
		self.Color = newColor
		ThemeManager.SetColorOverride(self.Visual, "BackgroundColor3", newColor)
	end
	self.EnableSpinning = function(_, enabled)
		if enabled then
			startSpin()
		else
			stopSpin()
		end
	end
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(stats, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(stats, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(holder, "BackgroundColor3", "Undercolor")
	ThemeManager.BindColor(visual, "BackgroundColor3", "PrimaryColor")
	ThemeManager.Bind(backImage, "Image", "Wallpaper")
	ThemeManager.Bind(backImage, "Visible", "WallpaperEnabled")
	ThemeManager.BindColor(holderShadow, "Color", "ComponentShadowColor")
	self.Destroy = function(me)
		stopSpin()
		Tween.CancelAll(me.Visual)
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(stats)
		ThemeManager.UnbindInstance(holder)
		ThemeManager.UnbindInstance(visual)
		ThemeManager.UnbindInstance(backImage)
		ThemeManager.UnbindInstance(holderShadow)
		if row and row.Parent then
			row:Destroy()
		end
	end
	ComponentAPI.Apply(self, { Root = row, Label = label, Name = name })
	return self
end
return ProgressBar
