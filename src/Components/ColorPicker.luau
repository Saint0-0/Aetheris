--[[
	ColorPicker  ·  Aetheris UI Library

	Color swatch row for a section. Clicking it opens PopUps/ColorPickerPopUp
	(created lazily via the supplied ShowPopup factory). The swatch itself is
	kept opaque across theme switches (protected in ThemeManager).

	Usage:
		local picker = section:ColorPicker({
			Name = "My Color",
			Default = Color3.fromRGB(255, 0, 0),
			Callback = function(color) print(color) end,
		}, ShowColorPickerPopup)
]]

local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local ThemeManager = require("../Themes/ThemeManager")
local ComponentRow = require("./ComponentRow")
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
    -- Main row (TextButton so the whole row is clickable)
    local row, label = ComponentRow.new(parent, {
        Name = name,
        RowName = name .. " [ColorPicker]",
        Theme = theme,
        Clickable = true,
        LabelWidth = 0.486,
    })
    -- HeaderBar (transparent container for display and chevron)
    local headerBar = Instance.new("Frame")
    headerBar.Name = "HeaderBar"
    headerBar.BorderSizePixel = 0
    headerBar.BackgroundTransparency = 1
    headerBar.AnchorPoint = Vector2.new(0.5, 0.5)
    headerBar.Size = UDim2.new(1, 0, 0, 32)
    headerBar.Position = UDim2.fromScale(0.5, 0.5)
    headerBar.Parent = row
    -- ColorDisplay (TextButton but used as display)
    local display = Instance.new("TextButton")
    display.Name = "ColorDisplay"
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
    displayShadow.Color = defaultColor  -- same as display background
    displayShadow.Transparency = 0.5
    displayShadow.BlurRadius = UDim.new(0, 20)
    displayShadow.Parent = display
    -- Chevron (ImageLabel)
    local chevron = Instance.new("ImageLabel")
    chevron.Name = "Chevron"
    chevron.BorderSizePixel = 0
    chevron.BackgroundTransparency = 1
    chevron.ImageTransparency = 0.5
    chevron.ImageColor3 = (theme and theme.AccentColor)
    chevron.AnchorPoint = Vector2.new(1, 0.5)
    chevron.Image = Icons["paintbrush"]  -- using existing icon
    chevron.Size = UDim2.fromOffset(20, 20)  -- 9.167% width, 62.5% height
    chevron.Position = UDim2.new(1, -40, 0.5, 0)
    chevron.Rotation = -90  -- initially pointing right (collapsed)
    chevron.Parent = headerBar
    -- Store references
    self.Row = row
    self.Label = label
    self.HeaderBar = headerBar
    self.Display = display
    self.DisplayShadow = displayShadow
    self.Chevron = chevron
    self._currentColor = defaultColor
    self._isOpen = false  -- popup state
    self.Callback = callback
    self.ShowPopup = ShowPopup
    self._popupId = name .. "ColorPicker"  -- unique ID for popup
    -- Helper: update display and shadow
    -- Resting shadow transparency. Re-asserted here (not just at construction)
    -- because PageFade walks every UIShadow on page fades and can otherwise
    -- leave it stuck at 1 (fully invisible) after a hide/invalidate cycle.
    local SHADOW_TRANSPARENCY = 0.5
    displayShadow:SetAttribute("PageFadeBase", SHADOW_TRANSPARENCY)
    local function updateDisplay(color)
        display.BackgroundColor3 = color
        displayShadow.Color = color
        displayShadow.Transparency = SHADOW_TRANSPARENCY
    end
    -- Set color (with optional no callback)
    self.SetColor = function(me, newColor, noCallback)
        if typeof(newColor) ~= "Color3" then return end
        if newColor == me._currentColor then return end
        me._currentColor = newColor
        updateDisplay(newColor)
        if not noCallback then
            me.Callback(newColor)
        end
    end
    self.GetColor = function(me)
        return me._currentColor
    end
    -- Toggle popup open/close
    self.TogglePopup = function(me)
        me._isOpen = not me._isOpen
        local targetRotation = me._isOpen and 0 or -90  -- 0 = down, -90 = right
        Tween.Play(me.Chevron, "Smooth", { Rotation = targetRotation })
        if me._isOpen and me.ShowPopup then
            -- Keep the returned popup so clicking the row again can close it.
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
            -- Row clicked again while open: actually close the popup (the old
            -- empty else-branch left it visible, only flipping the flag).
            me._popup:Close()
        end
    end
    self.ClosePopup = function(me)
        me._isOpen = false
        Tween.Play(me.Chevron, "Smooth", { Rotation = -90 })
        -- If the popup has a close method, we could call it, but the popup should handle its own dismissal.
        -- We'll rely on the popup's OnCancel/OnConfirm to close itself and call this to sync chevron.
    end
    -- Public API
    self.SetVisibility = function(_self, visible)
        row.Visible = visible
    end
    self.UpdateName = function(me, newName)
        label.Text = newName
        me._popupId = newName .. "ColorPicker"
    end
    -- Row and display click handlers
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
    -- Declarative theming: label text + chevron follow the theme via bindings.
    -- The ColorDisplay itself is left alone (it shows the user's colour).
    ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
    ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
    ThemeManager.BindColor(chevron, "ImageColor3", "AccentColor")
    -- Initialize display
    updateDisplay(defaultColor)
    return self
end
return ColorPicker