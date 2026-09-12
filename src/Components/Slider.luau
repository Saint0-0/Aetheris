--[[
	Slider  ·  Aetheris UI Library

	Draggable value slider with a spinning fill gradient, a numeric readout,
	and a reset button. Clamps to Min/Max and rounds to Precision.

	Usage:
		local slider = section:Slider({
			Name = "Smoothness",
			Min = 0,
			Max = 100,
			Default = 50,
			Callback = function(value) end,
		})
]]

local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")

local Slider = {}
Slider.__index = Slider
-- Global control for spinning animations (can be toggled later via settings)
Slider.SpinningEnabled = true
function Slider.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Slider)
	self._theme = theme
	local name = Settings.Name or "Slider"
	local min = Settings.Min or 0
	local max = Settings.Max or 100
	local default = Settings.Default or 50
	local precision = Settings.Precision or 0 -- decimal places for display
	-- Main row frame
	local row = Instance.new("Frame")
	row.Name = name .. "Slider"
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
	label.Position = UDim2.new(0, 0, 0.12063, 0)
	label.BorderColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = name
	label.Parent = row
	-- SliderHolder (track background)
	local holder = Instance.new("Frame")
	holder.Name = "SliderHolder"
	holder.BorderSizePixel = 0
	holder.BackgroundColor3 = theme.Undercolor
	holder.BackgroundTransparency = 0
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Size = UDim2.new(1, 0, 0.18946, 0)
	holder.Position = UDim2.new(0.5003, 0, 0.72338, 0)
	holder.BorderColor3 = Color3.fromRGB(255, 255, 255)
	holder.Parent = row
	local holderCorner = Instance.new("UICorner")
	holderCorner.CornerRadius = UDim.new(0, 5)
	holderCorner.Parent = holder
	local holderShadow = Instance.new("UIShadow")
	holderShadow.Parent = holder
	-- SliderVisual (fill progress)
	local visual = Instance.new("Frame")
	visual.Name = "SliderVisual"
	visual.BorderSizePixel = 0
	visual.BackgroundColor3 = (theme and theme.PrimaryColor)
	visual.Size = UDim2.new(0.201, 0, 1, 0) -- initial fill
	visual.BorderColor3 = Color3.fromRGB(0, 0, 0)
	visual.Parent = holder
	local visualCorner = Instance.new("UICorner")
	visualCorner.CornerRadius = UDim.new(0, 6)
	visualCorner.Parent = visual
	-- BackImage with spinning gradient
	local backImage = Instance.new("ImageLabel")
	backImage.Name = "BackImage"
	backImage.BorderSizePixel = 0
	backImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	backImage.ImageTransparency = 0.5
	backImage.AnchorPoint = Vector2.new(0.5, 0.5)
	backImage.Image = theme.Wallpaper or "rbxassetid://11094025229"
	backImage:SetAttribute("IsThemeSheen", true)
	backImage.Size = UDim2.new(1, 0, 1, 0)
	backImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	backImage.BackgroundTransparency = 1
	backImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	backImage.Parent = visual
	-- Set visibility based on theme's WallpaperEnabled
	if theme and theme.WallpaperEnabled == false then
		backImage.Visible = false
	else
		backImage.Visible = true
	end
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
	-- SliderButton (thumb)
	local thumb = Instance.new("ImageButton")
	thumb.Name = "SliderButton"
	thumb.BorderSizePixel = 0
	thumb.AutoButtonColor = false
	thumb.ImageTransparency = 1
	thumb.BackgroundTransparency = 1
	thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	thumb.AnchorPoint = Vector2.new(1, 0.5) -- locked right edge
	thumb.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	thumb.Size = UDim2.new(0.4, 0, 1, 0)
	thumb.Position = UDim2.new(1, 0, 0.5, 0)
	thumb.BorderColor3 = Color3.fromRGB(0, 0, 0)
	thumb.Parent = visual
	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(0, 10)
	thumbCorner.Parent = thumb
	
	local controlHolder = Instance.new("Frame")
	controlHolder.Name = "ControlHolder"
	controlHolder.AnchorPoint = Vector2.new(1, 0)
	controlHolder.Position = UDim2.new(1, 0, 0.12063, 0)
	controlHolder.Size = UDim2.new(0, 50, 0, 10)
	controlHolder.BackgroundTransparency = 1
	controlHolder.Parent = row
	
	local controlLayout = Instance.new("UIListLayout")
	controlLayout.FillDirection = Enum.FillDirection.Horizontal
	controlLayout.Padding = UDim.new(0, 5)
	controlLayout.SortOrder = Enum.SortOrder.LayoutOrder
	controlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	controlLayout.Parent = controlHolder
	
	-- ResetButton
	local resetBtn = Instance.new("ImageButton")
	resetBtn.Name = "ResetButton"
	resetBtn.LayoutOrder = 3
	resetBtn.BorderSizePixel = 0
	resetBtn.AutoButtonColor = false
	resetBtn.BackgroundTransparency = 1
	resetBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	resetBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	resetBtn.Image = Icons["rotate-ccw"] or "rbxassetid://110116685948665"
	resetBtn.ImageColor3 = theme.AccentColor
	resetBtn.Size = UDim2.new(0, 13, 0, 13)
	resetBtn.BorderColor3 = Color3.fromRGB(0, 0, 0)
	resetBtn.AnchorPoint = Vector2.new(1, 0.5)
	resetBtn.Parent = controlHolder
	local resetAspect = Instance.new("UIAspectRatioConstraint")
	resetAspect.Parent = resetBtn
	-- PercentageStat (shows percentage)
	local percentLabel = Instance.new("TextLabel")
	percentLabel.Name = "PercentageStat"
	percentLabel.LayoutOrder = 2
	percentLabel.TextWrapped = true
	percentLabel.TextTruncate = Enum.TextTruncate.AtEnd
	percentLabel.BorderSizePixel = 0
	percentLabel.TextSize = 11
	percentLabel.TextTransparency = theme.SecondaryTextTransparency
	percentLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	percentLabel.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	percentLabel.TextColor3 = theme.SecondaryTextColor
	percentLabel.BackgroundTransparency = 1
	-- Right-anchored with fixed offsets so it stays clustered with the input box
	-- and reset button instead of drifting apart when the row is stretched.
	percentLabel.AnchorPoint = Vector2.new(1, 0)
	percentLabel.Size = UDim2.new(0, 35, 0, 14)
	percentLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	percentLabel.Text = "0%"
	percentLabel.Parent = controlHolder
	-- SliderStat (TextBox for direct input)
	local statBox = Instance.new("TextBox")
	statBox.Name = "SliderStat"
	statBox.LayoutOrder = 1
	statBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	statBox.BorderSizePixel = 0
	statBox.TextTransparency = theme.SecondaryTextTransparency
	statBox.TextSize = 9
	statBox.TextColor3 = theme.SecondaryTextColor
	statBox.BackgroundColor3 = theme.InputBackgroundColor
	statBox.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	statBox.AutomaticSize = Enum.AutomaticSize.X
	statBox.AnchorPoint = Vector2.new(1, 0)
	statBox.TextTruncate = Enum.TextTruncate.AtEnd
	statBox.PlaceholderText = "0"
	statBox.Size = UDim2.new(0, 56, 0, 14)
	statBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	statBox.Text = ""
	statBox.BackgroundTransparency = theme.InputBackgroundTransparency
	statBox.Parent = controlHolder
	local statStroke = Instance.new("UIStroke")
	statStroke.Transparency = theme.StrokeTransparency
	statStroke.Color = theme.StrokeColor
	statStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	statStroke.Parent = statBox
	local statCorner = Instance.new("UICorner")
	statCorner.CornerRadius = UDim.new(0, 4)
	statCorner.Parent = statBox
	local statPadding = Instance.new("UIPadding")
	statPadding.PaddingBottom = UDim.new(0, 3)
	statPadding.Parent = statBox
	local statConstraint = Instance.new("UISizeConstraint")
	statConstraint.MaxSize = Vector2.new(56, 20)
	statConstraint.Parent = statBox
	-- State
	local currentValue = default
	local isDragging = false
	local isHovered = false
	local spinTween = nil
	-- Helper to format numbers
	local function formatValue(val)
		return string.format("%." .. precision .. "f", val)
	end
	-- Update slider visuals and text
	local function updateSlider(value, snapSmooth)
		value = math.clamp(value, min, max)
		currentValue = value
		local percentage = (value - min) / (max - min)
		local targetSize = UDim2.new(percentage, 0, 1, 0)
		if snapSmooth then
			Tween.Play(visual, "Smooth", { Size = targetSize })
		else
			visual.Size = targetSize
		end
		-- Update labels
		percentLabel.Text = math.round(percentage * 100) .. "%"
		statBox.Text = formatValue(value)
		statBox.PlaceholderText = formatValue(value)
		if Settings.Callback then
			Settings.Callback(value)
		end
	end
	-- Text box input handling
	statBox.FocusLost:Connect(function()
		local inputValue = tonumber(statBox.Text)
		if inputValue then
			updateSlider(inputValue, true)
		else
			statBox.Text = formatValue(currentValue)
		end
	end)
	-- Update visibility of overlay elements (hover/drag)
	local function updateVisibility()
		local target = (isHovered or isDragging) and 0 or 0.5
		Tween.Play(percentLabel, "Fast", { TextTransparency = target })
		Tween.Play(backImage, "Fast", { ImageTransparency = target })
		-- Also tween reset button color?
	end
	-- Process mouse/touch input
	local function processInput(input)
		local trackLength = holder.AbsoluteSize.X
		if trackLength <= 0 then return end
		local relativeX = input.Position.X - holder.AbsolutePosition.X
		local percentage = math.clamp(relativeX / trackLength, 0, 1)
		local value = min + percentage * (max - min)
		updateSlider(value, false)
	end
	-- Drag handlers
	thumb.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			updateVisibility()
		end
	end)
	-- Global drag listeners. These live on UserInputService (NOT under the row),
	-- so they MUST be disconnected when the slider is destroyed or they leak for
	-- the session - one pair per slider ever created.
	local UserInputService = game:GetService("UserInputService")
	local dragChangedConnection = UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			processInput(input)
		end
	end)
	local dragEndedConnection = UserInputService.InputEnded:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			isDragging = false
			updateVisibility()
		end
	end)
	row.Destroying:Connect(function()
		dragChangedConnection:Disconnect()
		dragEndedConnection:Disconnect()
		Tween.StopSpin(gradient)
	end)
	-- Click on track
	holder.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			updateVisibility()
			processInput(input)
		end
	end)
	-- Hover on thumb
	thumb.MouseEnter:Connect(function()
		isHovered = true
		updateVisibility()
	end)
	thumb.MouseLeave:Connect(function()
		isHovered = false
		updateVisibility()
	end)
	-- Reset button
	resetBtn.MouseButton1Click:Connect(function()
		updateSlider(default, true)
	end)
	resetBtn.MouseEnter:Connect(function()
		resetBtn.ImageColor3 = (ActiveTheme.theme or theme).AccentColor
		Tween.Play(resetBtn, "Fast", { ImageTransparency = 0.2 })
	end)
	resetBtn.MouseLeave:Connect(function()
		resetBtn.ImageColor3 = (ActiveTheme.theme or theme).AccentColor
		Tween.Play(resetBtn, "Fast", { ImageTransparency = 0 })
	end)
	-- Spinning gradient animation (using centralized Tween.StartSpin/StopSpin)
	local function startSpin()
		if not Slider.SpinningEnabled then return end
		gradient.Rotation = 0
		Tween.StartSpin(gradient, { Rotation = 360 }, "SpinIdle")
	end
	local function stopSpin()
		Tween.StopSpin(gradient)
	end
	-- Start spinning if enabled
	if Slider.SpinningEnabled then
		startSpin()
	end
	-- Initial value
	updateSlider(default, false)
	updateVisibility()
	-- Public API
	self.UpdateValue = function(newValue)
		updateSlider(newValue, true)
	end
	self.GetValue = function()
		return currentValue
	end
	self.SetVisibility = function(visible)
		row.Visible = visible
	end
	self.UpdateName = function(newName)
		label.Text = newName
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
		holder.BackgroundColor3 = theme.Undercolor or holder.BackgroundColor3
		visual.BackgroundColor3 = theme.PrimaryColor or visual.BackgroundColor3
		resetBtn.ImageColor3 = theme.AccentColor or resetBtn.ImageColor3
		percentLabel.TextColor3 = theme.SecondaryTextColor or percentLabel.TextColor3
		statBox.TextColor3 = theme.SecondaryTextColor or statBox.TextColor3
		statBox.BackgroundColor3 = theme.InputBackgroundColor or statBox.BackgroundColor3
		statBox.BackgroundTransparency = theme.InputBackgroundTransparency or statBox.BackgroundTransparency
		statStroke.Color = theme.StrokeColor or statStroke.Color
		statStroke.Transparency = theme.StrokeTransparency or statStroke.Transparency
		backImage.Image = theme.Wallpaper or "rbxassetid://11094025229"
		backImage.Visible = not (theme.WallpaperEnabled == false)
		holderShadow.Color = theme.ComponentShadowColor or holderShadow.Color
	end
	ThemeManager.Register(row, self)
	return self
end
return Slider