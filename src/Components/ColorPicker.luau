--[[
	Aetheris/Components/ColorPicker.luau

	Color swatch row: clicking opens PopUps/ColorPickerPopUp, created lazily
	through the supplied ShowPopup factory. Callback receives a Color3 and an
	alpha, seeded by Settings.Alpha.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local ThemeManager = require("../Themes/ThemeManager")
local ComponentRow = require("./ComponentRow")
local ComponentAPI = require("../Utils/ComponentAPI")
local Locale = require("../Utils/Locale")
local UUID = require("../Utils/UUID")
local ColorPicker = {}
ColorPicker.__index = ColorPicker
-- Icon hover lifts in over 0.15s and settles back over 0.2s.
local ICON_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ICON_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ALPHA_MAX = 255

local function clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

function ColorPicker.new(parent, Settings, ShowPopup, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, ColorPicker)
	self._theme = theme
	local name = Settings.Name or "Color"
	local defaultColor = Settings.Default or Color3.fromRGB(255, 0, 0)
	local defaultAlpha = clamp(tonumber(Settings.Alpha) or ALPHA_MAX, 0, ALPHA_MAX)
	local callback = Settings.Callback or function() end
	-- The whole row is clickable and styled like Dropdown.
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. " [ColorPicker]",
		Theme = theme,
		Clickable = true,
		LabelWidth = 0.486,
		LabelTextSize = 13,
		BackgroundColor = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		CornerRadius = 6,
		Stroke = false,
		ComponentContainer = false,
	})
	local headerBar = Instance.new("Frame")
	headerBar.Name = UUID.Static("HeaderBar")
	headerBar.BorderSizePixel = 0
	headerBar.BackgroundTransparency = 1
	headerBar.AnchorPoint = Vector2.new(0.5, 0.5)
	headerBar.Size = UDim2.new(1, 0, 0, 32)
	headerBar.Position = UDim2.fromScale(0.5, 0.5)
	headerBar.Parent = row
	local display = Instance.new("TextButton")
	display.Name = UUID.Static("ColorDisplay")
	display.BorderSizePixel = 0
	display.AutoButtonColor = false
	display.BackgroundColor3 = defaultColor
	display.AnchorPoint = Vector2.new(1, 0.5)
	display.Size = UDim2.fromOffset(24, 24)
	display.Position = UDim2.fromScale(1, 0.5)
	display.Text = ""
	display.Parent = headerBar
	local displayCorner = Instance.new("UICorner")
	displayCorner.CornerRadius = UDim.new(0.5, 0) -- Pill-shaped swatch chip.
	displayCorner.Parent = display
	local displayScale = Instance.new("UIScale")
	displayScale.Parent = display
	local displayStroke = Instance.new("UIStroke")
	displayStroke.Transparency = 0.8
	displayStroke.Color = Color3.fromRGB(255, 255, 255)
	displayStroke.Parent = display
	local displayShadow = Instance.new("UIShadow")
	displayShadow.Color = defaultColor -- matches the display fill
	displayShadow.Transparency = 0.5
	displayShadow.BlurRadius = UDim.new(0, 20)
	displayShadow.Parent = display
	local chevron = Instance.new("ImageLabel")
	chevron.Name = UUID.Static("Chevron")
	chevron.BorderSizePixel = 0
	chevron.BackgroundTransparency = 1
	chevron.ImageTransparency = 0.5
	chevron.ImageColor3 = (theme and theme.AccentColor)
	chevron.AnchorPoint = Vector2.new(1, 0.5)
	chevron.Image = Icons["chevron-down"]
	chevron.Size = UDim2.fromOffset(20, 20)
	chevron.Position = UDim2.new(1, -40, 0.5, 0)
	-- Rest points down; open flips it up.
	chevron.Parent = headerBar
	self.Row = row
	self.Label = label
	self.HeaderBar = headerBar
	self.Display = display
	self.DisplayShadow = displayShadow
	self.Chevron = chevron
	self._currentColor = defaultColor
	self._alpha = defaultAlpha
	self._isOpen = false -- popup state
	self.Callback = callback
	self.ShowPopup = ShowPopup
	self._popupId = name .. "ColorPicker"
	-- Re-asserted because PageFade walks UIShadows and can leave one invisible.
	local SHADOW_TRANSPARENCY = 0.5
	displayShadow:SetAttribute(UUID.Static("PageFadeBase"), SHADOW_TRANSPARENCY)
	local function updateDisplay()
		display.BackgroundColor3 = self._currentColor
		displayShadow.Color = self._currentColor
		displayShadow.Transparency = SHADOW_TRANSPARENCY
	end
	row.MouseButton1Click:Connect(function()
		self:TogglePopup()
	end)
	display.MouseButton1Click:Connect(function()
		self:TogglePopup()
	end)
	row.MouseEnter:Connect(function()
		Tween.Play(chevron, ICON_IN, { ImageTransparency = 0 })
	end)
	row.MouseLeave:Connect(function()
		Tween.Play(chevron, ICON_OUT, { ImageTransparency = 0.5 })
	end)
	display.MouseButton1Down:Connect(function()
		Tween.Play(displayScale, "PressIn", { Scale = 0.94 })
	end)
	display.MouseButton1Up:Connect(function()
		Tween.Play(displayScale, "PressOut", { Scale = 1 })
	end)
	display.MouseLeave:Connect(function()
		Tween.Play(displayScale, "PressOut", { Scale = 1 })
	end)
	self.Destroy = function(me)
		if me._isOpen and me._popup and me._popup.Close then
			me._popup:Close()
		end
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(chevron)
		Tween.CancelAll(chevron)
		Tween.CancelAll(displayScale)
		if row.Parent then
			row:Destroy()
		end
	end
	-- The fill is not bound; it carries the user's colour.
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(chevron, "ImageColor3", "AccentColor")
	updateDisplay()
	ComponentAPI.Apply(self, {
		Root = row,
		Label = label,
		Name = name,
		OnName = function(me, newName)
			Locale.set(label, "Text", newName)
			me._popupId = newName .. "ColorPicker"
		end,
		Methods = {
			SetColor = function(me, newColor, noCallback)
				if typeof(newColor) ~= "Color3" then
					return
				end
				if newColor == me._currentColor then
					return
				end
				me._currentColor = newColor
				updateDisplay()
				if not noCallback then
					me.Callback(newColor, me._alpha)
				end
			end,
			GetColor = function(me)
				return me._currentColor
			end,
			SetAlpha = function(me, newAlpha, noCallback)
				local alpha = clamp(tonumber(newAlpha) or me._alpha, 0, ALPHA_MAX)
				if alpha == me._alpha then
					return
				end
				me._alpha = alpha
				updateDisplay()
				if not noCallback then
					me.Callback(me._currentColor, alpha)
				end
			end,
			GetAlpha = function(me)
				return me._alpha
			end,
			TogglePopup = function(me)
				me._isOpen = not me._isOpen
				local targetRotation = me._isOpen and 180 or 0
				Tween.Play(me.Chevron, "Smooth", { Rotation = targetRotation })
				if me._isOpen and me.ShowPopup then
					-- Kept so a second row click can close it.
					me._popup = me.ShowPopup(me._popupId, {
						Title = me.Label.Text,
						CurrentColor = me._currentColor,
						CurrentAlpha = me._alpha,
						OnConfirm = function(newColor, newAlpha)
							me._currentColor = newColor
							me._alpha = clamp(tonumber(newAlpha) or ALPHA_MAX, 0, ALPHA_MAX)
							updateDisplay()
							me.Callback(newColor, me._alpha)
							me:ClosePopup()
						end,
						OnCancel = function()
							me:ClosePopup()
						end,
					})
				elseif me._popup and me._popup.Close then
					-- Close the popup rather than only flipping the flag.
					me._popup:Close()
				end
			end,
			ClosePopup = function(me)
				me._isOpen = false
				Tween.Play(me.Chevron, "Smooth", { Rotation = 0 })
			end,
		},
	})
	return self
end
return ColorPicker
