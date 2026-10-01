--[[
	RadioButton  ·  Aetheris UI Library

	A single radio button. Create via RadioButtonGroup:RadioButton() rather
	than directly, so the group can enforce single selection. Stores an
	IsSelected attribute so ThemeManager restores its selected look correctly
	on a theme switch.
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local Constants = require("../Constants")
local ComponentRow = require("./ComponentRow")
local FallbackImage = Constants.FallbackImage
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
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "RadioButton",
		Theme = theme,
		LabelWidth = 0.48591,
	})
	-- RadioHolderFrame
	local holder = Instance.new("Frame")
	holder.Name = "RadioHolderFrame"
	holder.BorderSizePixel = 0
	holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(1, 0.5)
	holder.Size = UDim2.fromOffset(45, 29)
	holder.Position = UDim2.fromScale(1, 0.5)
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
	local bounceScale = Instance.new("UIScale")
	bounceScale.Scale = 1
	bounceScale.Parent = holder
	-- RadioButtonElement
	local button = Instance.new("TextButton")
	button.Name = "RadioButtonElement"
	button.BorderSizePixel = 0
	button.TextTransparency = 1
	button.AutoButtonColor = false
	button.BackgroundColor3 = (theme and theme.PrimaryColor)
	button.BackgroundTransparency = 1
	button.Size = UDim2.fromScale(1, 1)
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
	backImage.Size = UDim2.fromScale(1, 1)
	backImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	backImage.BackgroundTransparency = 1
	backImage.Position = UDim2.fromScale(0.5, 0.5)
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
	activatedImage.Size = UDim2.fromOffset(17, 17)
	activatedImage.BackgroundTransparency = 1
	activatedImage.Position = UDim2.fromScale(0.5, 0.5)
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
		-- Sync PageFade's cached fade-base: selection changes the stroke OUTSIDE
		-- ApplyTheme, so a stale base would leave the stroke hidden after a page
		-- switch (only a hover tween brought it back).
		holderStroke:SetAttribute("PageFadeBase", 1)
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
		-- Keep the cached fade-base in sync (see playOn).
		holderStroke:SetAttribute("PageFadeBase", theme.StrokeTransparency or 0.4)
	end
	----------------------------------------------------------------
	-- HOVER
	----------------------------------------------------------------
	button.MouseEnter:Connect(function()
		Tween.Play(bounceScale, "HoverIn", { Scale = 1.02 })
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
		Tween.Play(bounceScale, "HoverOut", { Scale = 1 })
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
	button.MouseButton1Down:Connect(function()
		Tween.Play(bounceScale, "Fast", { Scale = 0.97 })
	end)
	button.MouseButton1Up:Connect(function()
		Tween.Play(bounceScale, "HoverIn", { Scale = 1.02 })
	end)
	
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
	self.SetSelected = function(me, selected)
		me.IsSelected = selected
		me.Button:SetAttribute("IsSelected", selected)
		if me._strokeHandle then
			me._strokeHandle:SetState(selected and "Selected" or "Unselected")
		end
		if selected then
			playOn()
			if callback then
				callback(me)
			end
		else
			playOff()
		end
	end
	self.GetSelected = function(me)
		return me.IsSelected
	end
	self.SetVisibility = function(_self, visible)
		row.Visible = visible
	end
	self.UpdateName = function(_self, newName)
		label.Text = newName
	end
	self.EnableSpinning = function(_self, enabled)
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
	-- Declarative theming for the STATELESS themed properties: these are
	-- bindings, so a theme switch re-resolves them with no ApplyTheme body.
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(button, "BackgroundColor3", "PrimaryColor")
	ThemeManager.BindColor(holderStroke, "Color", "StrokeColor")
	-- SELECTION-driven stroke transparency, now a STATE binding: Selected is a
	-- LITERAL 1 (stroke hidden), Unselected reads the theme's StrokeTransparency.
	self._strokeHandle = ThemeManager.BindTransparency(holderStroke, "Transparency",
		{ Selected = { value = 1 }, Unselected = "StrokeTransparency" },
		{ state = "Unselected" })
	-- What remains imperative: the wallpaper (Image/Visible are not Color3 or
	-- number, so they can't be bindings) and the SELECTION-driven stroke
	-- transparency (selected hides the stroke). ApplyTheme therefore stays,
	-- slimmed to just those two concerns.
	self.ApplyTheme = function(me, newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		me._theme = theme
		-- Stroke transparency is a STATE binding now; re-point it so the
		-- literal-selected / theme-unselected values re-resolve on switch.
		if me._strokeHandle then
			me._strokeHandle:SetState(me.IsSelected and "Selected" or "Unselected")
		end
		holderStroke:SetAttribute("PageFadeBase", holderStroke.Transparency)
		backImage.Image = theme.Wallpaper or FallbackImage
		backImage.Visible = not (theme.WallpaperEnabled == false)
		-- Re-apply the selected visual state directly. ApplyTheme cancels all
		-- in-flight tweens first, which could otherwise leave a just-selected
		-- button (e.g. the default "Auto") looking unselected after the
		-- startup theme pass.
		if me.IsSelected then
			button.BackgroundTransparency = 0
			activatedImage.ImageTransparency = 0
			activatedImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
			backImage.ImageTransparency = 0
		else
			button.BackgroundTransparency = 1
			activatedImage.ImageTransparency = 1
			backImage.ImageTransparency = 1
		end
	end
	ThemeManager.Register(row, self)
	self.Destroy = function(_self)
		-- Stop the gradient spin.
		stopSpin()
		-- Cancel any in-flight tweens.
		Tween.CancelAll(label)
		Tween.CancelAll(button)
		Tween.CancelAll(activatedImage)
		Tween.CancelAll(backImage)
		Tween.CancelAll(holderStroke)
		-- Drop all ThemeManager bindings and unregister the component.
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(button)
		ThemeManager.UnbindInstance(holderStroke)
		ThemeManager.Unregister(row)
		-- Destroy the root instance.
		if row and row.Parent then
			row:Destroy()
		end
	end
	return self
end
return RadioButton