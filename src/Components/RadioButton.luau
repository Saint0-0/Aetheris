--[[
	Aetheris/Components/RadioButton.luau

	Single radio row; create through RadioButtonGroup so selection stays unique.
	An IsSelected attribute preserves the selected look across theme switches.
	License: Saint0-0 Source License - use in your own scripts, no editing or
	redistribution without permission. (c) 2026 Saint0-0.
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local Constants = require("../Constants")
local ComponentRow = require("./ComponentRow")
local ComponentAPI = require("../Utils/ComponentAPI")
local UUID = require("../Utils/UUID")
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
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "RadioButton",
		Theme = theme,
		LabelWidth = 0.48591,
	})
	-- unactivated pill carries the same InputBackground tint as Keybind/TextInput;
	-- the selected button paints opaque over it
	local holder = Instance.new("Frame")
	holder.Name = UUID.Static("RadioHolderFrame")
	holder.BorderSizePixel = 0
	holder.BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(255, 255, 255)
	holder.BackgroundTransparency = theme.InputBackgroundTransparency or 1
	holder:SetAttribute(UUID.Static("IsInputBackground"), true)
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
	local button = Instance.new("TextButton")
	button.Name = UUID.Static("RadioButtonElement")
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
	local backImage = Instance.new("ImageLabel")
	backImage.Name = UUID.Static("BackImage")
	backImage.BorderSizePixel = 0
	backImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	backImage.ImageTransparency = 1
	backImage.AnchorPoint = Vector2.new(0.5, 0.5)
	local imageId = (theme and theme.Wallpaper) or FallbackImage
	backImage.Image = imageId
	backImage:SetAttribute(UUID.Static("IsThemeSheen"), true)
	backImage.Size = UDim2.fromScale(1, 1)
	backImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	backImage.BackgroundTransparency = 1
	backImage.Position = UDim2.fromScale(0.5, 0.5)
	backImage.Parent = button
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
	local activatedImage = Instance.new("ImageLabel")
	activatedImage.Name = UUID.Static("ActivatedImage")
	activatedImage.ImageTransparency = 1
	activatedImage.AnchorPoint = Vector2.new(0.5, 0.5)
	activatedImage.Image = "rbxassetid://8445470984"
	activatedImage.ImageRectSize = Vector2.new(96, 96)
	activatedImage.ImageRectOffset = Vector2.new(804, 904)
	-- Settings.Icon replaces the default mark; a plain asset id clears the
	-- sprite-sheet crop, while omitting it keeps the built-in glyph
	local iconOverride = Settings.Icon
	if type(iconOverride) == "string" and iconOverride ~= "" then
		activatedImage.Image = iconOverride
		activatedImage.ImageRectSize = Vector2.new(0, 0)
		activatedImage.ImageRectOffset = Vector2.new(0, 0)
	end
	activatedImage.Size = UDim2.fromOffset(17, 17)
	activatedImage.BackgroundTransparency = 1
	activatedImage.Position = UDim2.fromScale(0.5, 0.5)
	activatedImage.Parent = button
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.DominantAxis = Enum.DominantAxis.Height
	aspect.Parent = activatedImage
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

	local baseSize = activatedImage.Size
	local expandedSize =
		UDim2.new(baseSize.X.Scale * 1.20, baseSize.X.Offset, baseSize.Y.Scale * 1.20, baseSize.Y.Offset)

	-- transparencies are never set instantly here: current values are the
	-- tween's starting point
	local function playOn()
		Tween.Play(label, "OnOff", {
			TextTransparency = theme.PrimaryTextTransparency,
		})
		Tween.Play(button, "OnOff", {
			BackgroundTransparency = 0,
		})
		Tween.Play(activatedImage, "OnOff", {
			ImageTransparency = 0,
			Size = baseSize,
			ImageColor3 = Color3.fromRGB(255, 255, 255),
		})
		Tween.Play(backImage, "OnOff", {
			ImageTransparency = 0,
		})
		Tween.Play(holderStroke, "OnOff", {
			Transparency = 1,
		})
		-- selection changes the stroke outside ApplyTheme, so the cached
		-- PageFade base must follow or a page switch leaves it hidden
		holderStroke:SetAttribute(UUID.Static("PageFadeBase"), 1)
	end

	local function playOff()
		Tween.Play(label, "OnOff", {
			TextTransparency = theme.PrimaryTextTransparency,
		})
		Tween.Play(button, "OnOff", {
			BackgroundTransparency = 1,
		})
		Tween.Play(activatedImage, "OnOff", {
			ImageTransparency = 1,
			Size = baseSize,
			ImageColor3 = Color3.fromRGB(180, 180, 180),
		})
		Tween.Play(backImage, "OnOff", {
			ImageTransparency = 1,
		})
		Tween.Play(holderStroke, "OnOff", {
			Transparency = theme.StrokeTransparency or 0.4,
		})
		holderStroke:SetAttribute(UUID.Static("PageFadeBase"), theme.StrokeTransparency or 0.4)
	end

	-- hovering or pressing either the holder frame or the inner button drives
	-- the same visuals; selection is idempotent so bubbling is harmless
	local function enterHover()
		Tween.Play(bounceScale, "HoverIn", { Scale = 1.02 })
		if self.IsSelected then
			Tween.Play(activatedImage, "HoverIn", {
				Size = expandedSize,
				ImageColor3 = Color3.fromRGB(255, 255, 255),
			})
			Tween.Play(holderStroke, "HoverIn", {
				Transparency = 1,
			})
		else
			Tween.Play(holderStroke, "HoverIn", {
				Transparency = (theme.StrokeTransparency or 0.4) * 0.5,
			})
		end
	end
	local function leaveHover()
		Tween.Play(bounceScale, "HoverOut", { Scale = 1 })
		local isOn = self.IsSelected
		local targetColor = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
		Tween.Play(activatedImage, "HoverOut", {
			Size = baseSize,
			ImageColor3 = targetColor,
		})
		Tween.Play(holderStroke, "HoverOut", {
			Transparency = isOn and 1 or (theme.StrokeTransparency or 0.4),
		})
	end
	local function pressDown()
		Tween.Play(bounceScale, "Fast", { Scale = 0.97 })
	end
	local function pressUp()
		Tween.Play(bounceScale, "HoverIn", { Scale = 1.02 })
	end
	local function handleClick()
		if self.Group then
			self.Group:Select(self)
		end
	end
	for _, hit in ipairs({ holder, button }) do
		hit.MouseEnter:Connect(enterHover)
		hit.MouseLeave:Connect(leaveHover)
	end
	-- holder is a Frame (no MouseButton members); the button fills it, so
	-- button-only click connections still cover the whole pill
	button.MouseButton1Down:Connect(pressDown)
	button.MouseButton1Up:Connect(pressUp)
	button.MouseButton1Click:Connect(handleClick)

	local function startSpin()
		gradient.Rotation = 0
		Tween.StartSpin(gradient, { Rotation = 360 }, "SpinIdle")
	end
	local function stopSpin()
		Tween.StopSpin(gradient)
	end
	startSpin()

	self.SetSelected = function(me, selected)
		me.IsSelected = selected
		me.Button:SetAttribute(UUID.Static("IsSelected"), selected)
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
	if default then
		self._default = true
	end
	-- stateless themed properties are bindings, so a theme switch re-resolves
	-- them with no ApplyTheme body
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(button, "BackgroundColor3", "PrimaryColor")
	ThemeManager.BindColor(holder, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindTransparency(holder, "BackgroundTransparency", "InputBackgroundTransparency")
	ThemeManager.BindColor(holderStroke, "Color", "StrokeColor")
	-- Selected is a literal 1 (stroke hidden), Unselected reads the theme value
	self._strokeHandle = ThemeManager.BindTransparency(
		holderStroke,
		"Transparency",
		{ Selected = { value = 1 }, Unselected = "StrokeTransparency" },
		{ state = "Unselected" }
	)
	-- only the wallpaper and the selection-driven stroke stay imperative:
	-- Image/Visible aren't bindable types, and selection hides the stroke
	self.ApplyTheme = function(me, newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		me._theme = theme
		if me._strokeHandle then
			me._strokeHandle:SetState(me.IsSelected and "Selected" or "Unselected")
		end
		holderStroke:SetAttribute(UUID.Static("PageFadeBase"), holderStroke.Transparency)
		backImage.Image = theme.Wallpaper or FallbackImage
		backImage.Visible = not (theme.WallpaperEnabled == false)
		-- re-apply the selected state directly: ApplyTheme cancels in-flight
		-- tweens, which could leave a just-selected button looking unselected
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
		stopSpin()
		Tween.CancelAll(label)
		Tween.CancelAll(button)
		Tween.CancelAll(activatedImage)
		Tween.CancelAll(backImage)
		Tween.CancelAll(holderStroke)
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(button)
		ThemeManager.UnbindInstance(holder)
		ThemeManager.UnbindInstance(holderStroke)
		ThemeManager.Unregister(row)
		if row and row.Parent then
			row:Destroy()
		end
	end
	ComponentAPI.Apply(self, { Root = row, Label = label, Name = name })
	return self
end
return RadioButton
