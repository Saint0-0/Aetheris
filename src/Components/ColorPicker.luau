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
local ColorPicker = {}
ColorPicker.__index = ColorPicker
local function colorToHex(c)
    return string.format("#%02X%02X%02X", math.round(c.R*255), math.round(c.G*255), math.round(c.B*255))
end
function ColorPicker.new(parent, Settings, ShowPopup, theme)
	theme = ThemeManager.GetTheme(theme)
    Settings = Settings or {}
    local self = setmetatable({}, ColorPicker)
    self._theme = theme
    local name = Settings.Name or "Color"
    local defaultColor = Settings.Default or Color3.fromRGB(255, 0, 0)
    local callback = Settings.Callback or function() end
    -- Main row (TextButton so the whole row is clickable)
    local row = Instance.new("TextButton")
    row.Name = name .. " [ColorPicker]"
    row.BorderSizePixel = 0
    row.BackgroundColor3 = Color3.fromRGB(31, 32, 34)
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 45)
    row.AnchorPoint = Vector2.new(0.5, 0.5)
    row.Position = UDim2.new(0.5, 0, 0.5, 0)
    row.Text = ""
    row.TextTransparency = 1
    row.AutoButtonColor = false
    row.Parent = parent
    -- Label
    local label = Instance.new("TextLabel")
    label.Name = "ElementName"
    label.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    label.Text = name
    label.TextColor3 = (theme and theme.PrimaryTextColor)
    label.TextSize = 14
    label.TextTransparency = (theme and theme.PrimaryTextTransparency) or 0.45
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.AnchorPoint = Vector2.new(0, 0.5)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.486, 0, 0.714, 0)
    label.Position = UDim2.new(0, 0, 0.5, 0)
    label.Parent = row
    -- HeaderBar (transparent container for display and chevron)
    local headerBar = Instance.new("Frame")
    headerBar.Name = "HeaderBar"
    headerBar.BorderSizePixel = 0
    headerBar.BackgroundTransparency = 1
    headerBar.AnchorPoint = Vector2.new(0.5, 0.5)
    headerBar.Size = UDim2.new(1, 0, 0, 32)
    headerBar.Position = UDim2.new(0.5, 0, 0.5, 0)
    headerBar.Parent = row
    -- ColorDisplay (TextButton but used as display)
    local display = Instance.new("TextButton")
    display.Name = "ColorDisplay"
    display.BorderSizePixel = 0
    display.AutoButtonColor = false
    display.BackgroundColor3 = defaultColor
    display.AnchorPoint = Vector2.new(1, 0.5)
    display.Size = UDim2.new(0, 24, 0, 24)
    display.Position = UDim2.new(1, 0, 0.5, 0)
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
    chevron.Size = UDim2.new(0, 20, 0, 20)  -- 9.167% width, 62.5% height
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
    local function updateDisplay(color)
        display.BackgroundColor3 = color
        displayShadow.Color = color
    end
    -- Set color (with optional no callback)
    function self:SetColor(newColor, noCallback)
        if typeof(newColor) ~= "Color3" then return end
        if newColor == self._currentColor then return end
        self._currentColor = newColor
        updateDisplay(newColor)
        if not noCallback then
            self.Callback(newColor)
        end
    end
    function self:GetColor()
        return self._currentColor
    end
    -- Toggle popup open/close
    function self:TogglePopup()
        self._isOpen = not self._isOpen
        local targetRotation = self._isOpen and 0 or -90  -- 0 = down, -90 = right
        Tween.Play(self.Chevron, "Smooth", { Rotation = targetRotation })
        if self._isOpen and self.ShowPopup then
            -- Keep the returned popup so clicking the row again can close it.
            self._popup = self.ShowPopup(self._popupId, {
                Title = self.Label.Text,
                CurrentColor = self._currentColor,
                OnConfirm = function(newColor)
                    self:SetColor(newColor, false)
                    self:ClosePopup()
                end,
                OnCancel = function()
                    self:ClosePopup()
                end,
            })
        elseif self._popup and self._popup.Close then
            -- Row clicked again while open: actually close the popup (the old
            -- empty else-branch left it visible, only flipping the flag).
            self._popup:Close()
        end
    end
    function self:ClosePopup()
        self._isOpen = false
        Tween.Play(self.Chevron, "Smooth", { Rotation = -90 })
        -- If the popup has a close method, we could call it, but the popup should handle its own dismissal.
        -- We'll rely on the popup's OnCancel/OnConfirm to close itself and call this to sync chevron.
    end
    -- Public API
    function self:SetVisibility(visible)
        row.Visible = visible
    end
    function self:UpdateName(newName)
        label.Text = newName
        self._popupId = newName .. "ColorPicker"
    end
    -- Row click handler
    row.MouseButton1Click:Connect(function()
        self:TogglePopup()
    end)
    -- Component-owned theming (see ThemeManager registry). The ColorDisplay
    -- itself is left alone (it shows the user's colour); only text/chevron
    -- follow the theme.
    function self:ApplyTheme(newTheme)
        theme = ThemeManager.GetTheme(newTheme)
        self._theme = theme
        label.TextColor3 = theme.PrimaryTextColor or label.TextColor3
        label.TextTransparency = theme.PrimaryTextTransparency or label.TextTransparency
        chevron.ImageColor3 = theme.AccentColor or chevron.ImageColor3
    end
    ThemeManager.Register(row, self)
    -- Initialize display
    updateDisplay(defaultColor)
    return self
end
return ColorPicker