--[[
	Aetheris/Components/ColorPicker.luau

	Color swatch row for a section. Clicking it opens PopUps/ColorPickerPopUp
	(created lazily via the supplied ShowPopup factory). The swatch itself is
	kept opaque across theme switches (protected in ThemeManager).
	License: Saint0-0 Source License - use in your own scripts, no editing or
	redistribution without permission. (c) 2026 Saint0-0.
]]

local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local ThemeManager = require("../Themes/ThemeManager")
local ComponentRow = require("./ComponentRow")
local ComponentAPI = require("../Utils/ComponentAPI")
local UUID = require("../Utils/UUID")
local ColorPicker = {}
ColorPicker.__index = ColorPicker
function ColorPicker.new(parent, Settings, ShowPopup, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, ColorPicker)
	self._theme = theme
	local name = Settings.Name or "Color"
	local defaultColor = Settings.Default or Color3.fromRGB(255, 0, 0)
	local callback = Settings.Callback or function() end
	-- whole row is clickable; container styling matches Dropdown
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. " [ColorPicker]",
		Theme = theme,
		Clickable = true,
		LabelWidth = 0.486,
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
	displayCorner.CornerRadius = UDim.new(0, 6)
	displayCorner.Parent = display
	local displayStroke = Instance.new("UIStroke")
	displayStroke.Transparency = 0.8
	displayStroke.Color = Color3.fromRGB(255, 255, 255)
	displayStroke.Parent = display
	local displayShadow = Instance.new("UIShadow")
	displayShadow.Color = defaultColor -- matches the display background
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
	chevron.Image = Icons["paintbrush"]
	chevron.Size = UDim2.fromOffset(20, 20)
	chevron.Position = UDim2.new(1, -40, 0.5, 0)
	chevron.Rotation = -90 -- collapsed: pointing right
	chevron.Parent = headerBar
	self.Row = row
	self.Label = label
	self.HeaderBar = headerBar
	self.Display = display
	self.DisplayShadow = displayShadow
	self.Chevron = chevron
	self._currentColor = defaultColor
	self._isOpen = false -- popup state
	self.Callback = callback
	self.ShowPopup = ShowPopup
	self._popupId = name .. "ColorPicker"
	-- re-asserted (not just at construction) because PageFade walks every
	-- UIShadow on fades and can otherwise leave it stuck invisible at 1
	local SHADOW_TRANSPARENCY = 0.5
	displayShadow:SetAttribute(UUID.Static("PageFadeBase"), SHADOW_TRANSPARENCY)
	local function updateDisplay(color)
		display.BackgroundColor3 = color
		displayShadow.Color = color
		displayShadow.Transparency = SHADOW_TRANSPARENCY
	end
	self.SetColor = function(me, newColor, noCallback)
		if typeof(newColor) ~= "Color3" then
			return
		end
		if newColor == me._currentColor then
			return
		end
		me._currentColor = newColor
		updateDisplay(newColor)
		if not noCallback then
			me.Callback(newColor)
		end
	end
	self.GetColor = function(me)
		return me._currentColor
	end
	self.TogglePopup = function(me)
		me._isOpen = not me._isOpen
		local targetRotation = me._isOpen and 0 or -90
		Tween.Play(me.Chevron, "Smooth", { Rotation = targetRotation })
		if me._isOpen and me.ShowPopup then
			-- kept so clicking the row again can close it
			me._popup = me.ShowPopup(me._popupId, {
				Title = me.Label.Text,
				CurrentColor = me._currentColor,
				OnConfirm = function(newColor)
					me:SetColor(newColor, false)
					me:ClosePopup()
				end,
				OnCancel = function()
					me:ClosePopup()
				end,
			})
		elseif me._popup and me._popup.Close then
			-- row clicked again while open: actually close it, don't just flip the flag
			me._popup:Close()
		end
	end
	self.ClosePopup = function(me)
		me._isOpen = false
		Tween.Play(me.Chevron, "Smooth", { Rotation = -90 })
	end
	self.SetVisibility = function(_self, visible)
		row.Visible = visible
	end
	self.UpdateName = function(me, newName)
		label.Text = newName
		me._popupId = newName .. "ColorPicker"
	end
	row.MouseButton1Click:Connect(function()
		self:TogglePopup()
	end)
	display.MouseButton1Click:Connect(function()
		self:TogglePopup()
	end)
	self.Destroy = function(me)
		if me._isOpen and me._popup and me._popup.Close then
			me._popup:Close()
		end
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(chevron)
		Tween.CancelAll(chevron)
		if row.Parent then
			row:Destroy()
		end
	end
	-- the ColorDisplay itself is left alone: it shows the user's colour
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(chevron, "ImageColor3", "AccentColor")
	updateDisplay(defaultColor)
	ComponentAPI.Apply(self, {
		Root = row,
		Label = label,
		Name = name,
		OnName = function(me, newName)
			label.Text = newName
			me._popupId = newName .. "ColorPicker"
		end,
	})
	return self
end
return ColorPicker
