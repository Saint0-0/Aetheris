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
	row.Size = UDim2.new(1, 0, 0, 52)
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
	label.Position = UDim2.new(0, 0, 0.121, 0)
	label.BorderColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = name
	label.Parent = row
	-- SliderHolder (track background)
	local holder = Instance.new("Frame")
	holder.Name = "SliderHolder"
	holder.BorderSizePixel = 0
	holder.BackgroundColor3 = theme.Undercolor
	holder.BackgroundTransparency = 0
	holder.AnchorPoint = Vector2.new(0, 0.5)
	holder.Size = UDim2.new(1, 0, 0, 4)
	holder.Position = UDim2.new(0, 0, 0.723, 5)
	holder.BorderColor3 = Color3.fromRGB(255, 255, 255)
	holder.Parent = row
	local holderCorner = Instance.new("UICorner")
	holderCorner.CornerRadius = UDim.new(0, 4)
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
	visualCorner.CornerRadius = UDim.new(0, 4)
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
	backCorner.CornerRadius = UDim.new(0, 4)
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
	thumb.BackgroundTransparency = 0
	-- Thumb (the draggable handle) uses the theme's accent color so it reads
	-- as an interactive control, matching the reset button / settings gear.
	thumb.BackgroundColor3 = theme.AccentColor or Color3.fromRGB(255, 255, 255)
	-- Parented to the HOLDER (not the fill) so its position is an absolute
	-- fraction of the track and can be clamped to the ends independently of
	-- how full the fill is.
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	thumb.Size = UDim2.new(0, 35, 4, 0)
	thumb.Position = UDim2.new(0, 0, 0.5, 0)
	thumb.BorderColor3 = Color3.fromRGB(0, 0, 0)
	thumb.Parent = holder
	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0)
	thumbCorner.Parent = thumb

	local controlHolder = Instance.new("Frame")
	controlHolder.Name = "ControlHolder"
	controlHolder.AnchorPoint = Vector2.new(1, 0)
	controlHolder.Position = UDim2.new(1, 0, 0.121, 0)
	controlHolder.Size = UDim2.new(0, 50, 0, 10)
	controlHolder.BackgroundTransparency = 1
	controlHolder.Parent = row
	
	local controlLayout = Instance.new("UIListLayout")
	controlLayout.FillDirection = Enum.FillDirection.Horizontal
	controlLayout.Padding = UDim.new(0, 5)
	controlLayout.SortOrder = Enum.SortOrder.LayoutOrder
	controlLayout.VerticalAlignment = Enum.VerticalAlignment.Top
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
	statBox.TextSize = 10
	statBox.TextColor3 = theme.SecondaryTextColor
	statBox.BackgroundColor3 = theme.InputBackgroundColor
	statBox.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	statBox.AutomaticSize = Enum.AutomaticSize.X
	statBox.AnchorPoint = Vector2.new(1, 0)
	statBox.TextTruncate = Enum.TextTruncate.AtEnd
	statBox.PlaceholderText = "0"
	statBox.Size = UDim2.new(0, 56, 0, 16)
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
	local statConstraint = Instance.new("UISizeConstraint")
	statConstraint.MaxSize = Vector2.new(56, 20)
	statConstraint.Parent = statBox
	-- State
	local currentValue = default
	local currentPercentage = (default - min) / (max - min)
	local isDragging = false
	local isHovered = false
	local spinTween = nil
	-- Helper to format numbers
	local function formatValue(val)
		return string.format("%." .. precision .. "f", val)
	end
	-- Place the thumb so value 0 puts its LEFT edge flush with the track's LEFT
	-- edge, and value 1 puts its RIGHT edge flush with the track's RIGHT edge.
	-- The thumb centre therefore travels over (trackWidth - thumbWidth), inset
	-- by half a thumb at each end -- that inset is what keeps it in frame.
	local function positionThumb(percentage)
		local trackWidth = holder.AbsoluteSize.X
		local thumbWidth = thumb.AbsoluteSize.X
		if trackWidth <= 0 then return end
		local travel = math.max(trackWidth - thumbWidth, 0)
		local x = percentage * travel + thumbWidth / 2
		thumb.Position = UDim2.new(0, x, 0.5, 0)
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
		currentPercentage = percentage
		positionThumb(percentage)
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
		local active = isHovered or isDragging
		local target = active and 0 or 0.5
		Tween.Play(percentLabel, "Fast", { TextTransparency = target })
		Tween.Play(backImage, "Fast", { ImageTransparency = target })
		-- Thumb grows on hover/drag and shrinks back on release. HoverIn uses
		-- Back/Out easing, so it overshoots slightly -- that's the bounce.
		-- Plain fast grow/shrink (no HoverIn/HoverOut bounce), and the thumb
		-- stays fully opaque while dragging.
		if active then
			Tween.Play(thumb, "Fast", { Size = UDim2.new(0, 40, 5, 0) })
		else
			Tween.Play(thumb, "Fast", { Size = UDim2.new(0, 35, 4, 0) })
		end
	end
	-- Process mouse/touch input
	local function processInput(input)
		local trackLength = holder.AbsoluteSize.X
		if trackLength <= 0 then return end
		-- Map the cursor over the thumb's TRAVEL range (track minus the thumb's
		-- own width), not the raw track, so the cursor at either extreme lines up
		-- with the clamped thumb positions above.
		local thumbWidth = thumb.AbsoluteSize.X
		local travel = math.max(trackLength - thumbWidth, 1)
		local relativeX = input.Position.X - holder.AbsolutePosition.X - thumbWidth / 2
		local percentage = math.clamp(relativeX / travel, 0, 1)
		local value = min + percentage * (max - min)
		updateSlider(value, false)
	end
	-- Drag handling on-demand (only connected while active drag is in progress)
	local UserInputService = game:GetService("UserInputService")
	local dragChangedConnection = nil
	local dragEndedConnection = nil

	local function stopDragging()
		if not isDragging then return end
		isDragging = false
		if dragChangedConnection then
			dragChangedConnection:Disconnect()
			dragChangedConnection = nil
		end
		if dragEndedConnection then
			dragEndedConnection:Disconnect()
			dragEndedConnection = nil
		end
		updateVisibility()
	end

	local function startDragging(input)
		isDragging = true
		updateVisibility()
		if not dragChangedConnection then
			dragChangedConnection = UserInputService.InputChanged:Connect(function(changedInput)
				if isDragging and (changedInput.UserInputType == Enum.UserInputType.MouseMovement or changedInput.UserInputType == Enum.UserInputType.Touch) then
					processInput(changedInput)
				end
			end)
		end
		if not dragEndedConnection then
			dragEndedConnection = UserInputService.InputEnded:Connect(function(endedInput)
				if endedInput.UserInputType == Enum.UserInputType.MouseButton1 or endedInput.UserInputType == Enum.UserInputType.Touch then
					stopDragging()
				end
			end)
		end
	end

	thumb.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			startDragging(input)
		end
	end)

	local function disconnectAll()
		stopDragging()
		Tween.StopSpin(gradient)
	end
	row.Destroying:Connect(disconnectAll)

	-- Click on track
	holder.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			startDragging(input)
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
	-- The thumb's hover size tween and any window/layout resize both change the
	-- travel range, so re-clamp the thumb whenever either size changes.
	thumb:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		positionThumb(currentPercentage)
	end)
	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		positionThumb(currentPercentage)
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
	-- Spinning gradient animation, routed through the shared Tween spin system.
	-- StartSpin now gates the spin on visibility (Tween.GateSpinOnVisibility), so
	-- an off-screen slider pauses automatically and resumes from its frozen angle
	-- when its tab/page returns -- no per-component visibility plumbing needed.
	local function startSpin()
		if not Slider.SpinningEnabled then return end
		gradient.Rotation = 0
		Tween.StartSpin(gradient, { Rotation = 360 }, "SpinIdle")
	end
	local function stopSpin()
		Tween.StopSpin(gradient)
	end
	startSpin()
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
	self.Destroy = function()
		disconnectAll()
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(holder)
		ThemeManager.UnbindInstance(visual)
		ThemeManager.UnbindInstance(resetBtn)
		ThemeManager.UnbindInstance(percentLabel)
		ThemeManager.UnbindInstance(statBox)
		ThemeManager.UnbindInstance(statStroke)
		ThemeManager.UnbindInstance(holderShadow)
		ThemeManager.UnbindInstance(thumb)
		if row.Parent then
			row:Destroy()
		end
	end
	-- Declarative theming: every colour / transparency property is a BINDING,
	-- so a theme switch re-resolves them with no hand-written re-stamp.
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(holder, "BackgroundColor3", "Undercolor")
	ThemeManager.BindColor(visual, "BackgroundColor3", "PrimaryColor")
	ThemeManager.BindColor(resetBtn, "ImageColor3", "AccentColor")
	ThemeManager.BindColor(percentLabel, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(percentLabel, "TextTransparency", "SecondaryTextTransparency")
	ThemeManager.BindColor(statBox, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(statBox, "TextTransparency", "SecondaryTextTransparency")
	ThemeManager.BindColor(statBox, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindTransparency(statBox, "BackgroundTransparency", "InputBackgroundTransparency")
	ThemeManager.BindColor(statStroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(statStroke, "Transparency", "StrokeTransparency")
	ThemeManager.BindColor(holderShadow, "Color", "ComponentShadowColor")
	ThemeManager.BindColor(thumb, "BackgroundColor3", "AccentColor")
	-- What remains imperative: the wallpaper (Image / Visible are not Color3 or
	-- number, so they can't be bindings) plus a defensive re-stamp of the
	-- NATURAL transparencies, which are constants here. ApplyTheme stays,
	-- slimmed to just that.
	function self:ApplyTheme(newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		self._theme = theme
		backImage.Image = theme.Wallpaper or "rbxassetid://11094025229"
		backImage.Visible = not (theme.WallpaperEnabled == false)
		holder.BackgroundTransparency = 0
		visual.BackgroundTransparency = 0
		resetBtn.ImageTransparency = 0
		thumb.BackgroundTransparency = 0
		backImage.ImageTransparency = 0.5
		updateVisibility()
	end
	ThemeManager.Register(row, self)
	return self
end
return Slider