--[[
	RadioButton  ·  Aetheris UI Library

	A single radio button. Create via RadioButtonGroup:RadioButton() rather
	than directly, so the group can enforce single selection. Stores an
	IsSelected attribute so ThemeManager restores its selected look correctly
	on a theme switch.
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local FallbackImage = require("../Constants").FallbackImage
local RadioButton = {}
RadioButton.__index = RadioButton
function RadioButton.new(parent, group, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, RadioButton)
	self._theme = theme
	local name = Settings.Name or "Radio Button"
	local default = Settings.Default or false
	local callback = Settings.Callback
	-- Main row
	local row = Instance.new("Frame")
	row.Name = name .. "RadioButton"
	row.BorderSizePixel = 0
	row.BackgroundColor3 = Color3.fromRGB(38, 39, 41)
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 45)
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.new(0.5, 0, 0.5, 0)
	row.BorderColor3 = Color3.fromRGB(0, 0, 0)
	row.Parent = parent
	-- Label
	local label = Instance.new("TextLabel")
	label.Name = "ElementName"
	label.TextWrapped = true
	label.BorderSizePixel = 0
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTransparency = theme.PrimaryTextTransparency
	label.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	label.FontFace = Font.new(
		"rbxassetid://12187365364",
		Enum.FontWeight.Regular,
		Enum.FontStyle.Normal
	)
	label.TextColor3 = theme.PrimaryTextColor
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Size = UDim2.new(0.48591, 0, 0.71359, 0)
	label.Position = UDim2.new(0, 0, 0.5, 0)
	label.BorderColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = name
	label.Parent = row
	-- RadioHolderFrame
	local holder = Instance.new("Frame")
	holder.Name = "RadioHolderFrame"
	holder.BorderSizePixel = 0
	holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(1, 0.5)
	holder.Size = UDim2.new(0.16584, 0, 0.563, 0)
	holder.Position = UDim2.new(1, 0, 0.5, 0)
	holder.BorderColor3 = Color3.fromRGB(0, 0, 0)
	holder.Parent = row
	local holderCorner = Instance.new("UICorner")
	holderCorner.CornerRadius = UDim.new(0, 6)
	holderCorner.Parent = holder
	local holderStroke = Instance.new("UIStroke")
	holderStroke.Transparency = theme.StrokeTransparency or 0.4
	holderStroke.Thickness = 0.7
	holderStroke.Color = theme.StrokeColor
	holderStroke.Parent = holder
	-- RadioButtonElement
	local button = Instance.new("TextButton")
	button.Name = "RadioButtonElement"
	button.BorderSizePixel = 0
	button.TextTransparency = 1
	button.AutoButtonColor = false
	button.BackgroundColor3 = (theme and theme.PrimaryColor)
	button.BackgroundTransparency = 1
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BorderColor3 = Color3.fromRGB(0, 0, 0)
	button.Text = ""
	button.Parent = holder
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = button
	-- BackImage
	local backImage = Instance.new("ImageLabel")
	backImage.Name = "BackImage"
	backImage.BorderSizePixel = 0
	backImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	backImage.ImageTransparency = 1
	backImage.AnchorPoint = Vector2.new(0.5, 0.5)
	local imageId = (theme and theme.Wallpaper) or FallbackImage
	backImage.Image = imageId
	backImage:SetAttribute("IsThemeSheen", true)
	backImage.Size = UDim2.new(1, 0, 1, 0)
	backImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	backImage.BackgroundTransparency = 1
	backImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	backImage.Parent = button
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
	-- ActivatedImage
	local activatedImage = Instance.new("ImageLabel")
	activatedImage.Name = "ActivatedImage"
	activatedImage.ImageTransparency = 1
	activatedImage.AnchorPoint = Vector2.new(0.5, 0.5)
	activatedImage.Image = "rbxassetid://8445470984"
	activatedImage.ImageRectSize = Vector2.new(96, 96)
	activatedImage.ImageRectOffset = Vector2.new(804, 904)
	activatedImage.Size = UDim2.new(0, 17, 0, 17)
	activatedImage.BackgroundTransparency = 1
	activatedImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	activatedImage.Parent = button
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.DominantAxis = Enum.DominantAxis.Height
	aspect.Parent = activatedImage
	-- Store references
	self.Row = row
	self.Label = label
	self.Button = button
	self.Holder = holder
	self.HolderStroke = holderStroke
	self.ActivatedImage = activatedImage
	self.BackImage = backImage
	self.Gradient = gradient
	self.Group = group
	self.IsSelected = false
	-- Tween definitions
	local baseSize = activatedImage.Size
	local expandedSize = UDim2.new(
		baseSize.X.Scale * 1.20,
		baseSize.X.Offset,
		baseSize.Y.Scale * 1.20,
		baseSize.Y.Offset
	)
	----------------------------------------------------------------
	-- SELECTED
	----------------------------------------------------------------
	local function playOn()
		-- IMPORTANT:
		-- Do NOT instantly set transparency here.
		-- The current values become the starting point of the tween.
		Tween.Play(label, "OnOff", {
			TextTransparency = theme.PrimaryTextTransparency
		})
		Tween.Play(button, "OnOff", {
			BackgroundTransparency = 0
		})
		Tween.Play(activatedImage, "OnOff", {
			ImageTransparency = 0,
			Size = baseSize,
			ImageColor3 = Color3.fromRGB(255, 255, 255)
		})
		Tween.Play(backImage, "OnOff", {
			ImageTransparency = 0
		})
		Tween.Play(holderStroke, "OnOff", {
			Transparency = 1
		})
	end
	----------------------------------------------------------------
	-- DESELECTED
	----------------------------------------------------------------
	local function playOff()
		-- Again, don't instantly set the transparency.
		-- Tween from the current visual state to the hidden state.
		Tween.Play(label, "OnOff", {
			TextTransparency = theme.PrimaryTextTransparency
		})
		Tween.Play(button, "OnOff", {
			BackgroundTransparency = 1
		})
		Tween.Play(activatedImage, "OnOff", {
			ImageTransparency = 1,
			Size = baseSize,
			ImageColor3 = Color3.fromRGB(180, 180, 180)
		})
		Tween.Play(backImage, "OnOff", {
			ImageTransparency = 1
		})
		Tween.Play(holderStroke, "OnOff", {
			Transparency = theme.StrokeTransparency or 0.4
		})
	end
	----------------------------------------------------------------
	-- HOVER
	----------------------------------------------------------------
	button.MouseEnter:Connect(function()
		if self.IsSelected then
			Tween.Play(activatedImage, "HoverIn", {
				Size = expandedSize,
				ImageColor3 = Color3.fromRGB(255, 255, 255)
			})
			Tween.Play(holderStroke, "HoverIn", {
				Transparency = 1
			})
		else
			Tween.Play(holderStroke, "HoverIn", {
				Transparency = (theme.StrokeTransparency or 0.4) * 0.5
			})
		end
	end)
	button.MouseLeave:Connect(function()
		local isOn = self.IsSelected
		local targetColor = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
		Tween.Play(activatedImage, "HoverOut", {
			Size = baseSize,
			ImageColor3 = targetColor
		})
		Tween.Play(holderStroke, "HoverOut", {
			Transparency = isOn and 1 or (theme.StrokeTransparency or 0.4)
		})
	end)
	----------------------------------------------------------------
	-- CLICK
	----------------------------------------------------------------
	button.MouseButton1Click:Connect(function()
		if self.Group then
			self.Group:Select(self)
		end
	end)
	----------------------------------------------------------------
	-- SPINNING GRADIENT (using centralized Tween.StartSpin/StopSpin)
	----------------------------------------------------------------
	local function startSpin()
		gradient.Rotation = 0
		Tween.StartSpin(gradient, { Rotation = 360 }, "SpinIdle")
	end
	local function stopSpin()
		Tween.StopSpin(gradient)
	end
	startSpin()
	----------------------------------------------------------------
	-- PUBLIC API
	----------------------------------------------------------------
	function self:SetSelected(selected)
		self.IsSelected = selected
		self.Button:SetAttribute("IsSelected", selected)
		if selected then
			playOn()
			if callback then
				callback(self)
			end
		else
			playOff()
		end
	end
	function self:GetSelected()
		return self.IsSelected
	end
	function self:SetVisibility(visible)
		row.Visible = visible
	end
	function self:UpdateName(newName)
		label.Text = newName
	end
	function self:EnableSpinning(enabled)
		if enabled then
			startSpin()
		else
			stopSpin()
		end
	end
	----------------------------------------------------------------
	-- DEFAULT
	----------------------------------------------------------------
	if default then
		self._default = true
	end
	-- Component-owned theming (see ThemeManager registry).
	function self:ApplyTheme(newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		self._theme = theme
		label.TextColor3 = theme.PrimaryTextColor or label.TextColor3
		label.TextTransparency = theme.PrimaryTextTransparency or label.TextTransparency
		button.BackgroundColor3 = theme.PrimaryColor or button.BackgroundColor3
		holderStroke.Color = theme.StrokeColor or holderStroke.Color
		holderStroke.Transparency = self.IsSelected and 1 or (theme.StrokeTransparency or 0.4)
		backImage.Image = theme.Wallpaper or FallbackImage
		backImage.Visible = not (theme.WallpaperEnabled == false)
	end
	ThemeManager.Register(row, self)
	return self
end
return RadioButton