--[[
	ColorPickerPopUp  ·  Aetheris UI Library

	Modal colour picker: saturation/value square, value slider, RGB + Hex
	inputs, and colour wells. Cached per id by Window and reused; theme
	switches drop the cache so the next open rebuilds with current colors.
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local Sound = require("../Utils/Sound")
local ColorPickerPopUp = {}
ColorPickerPopUp.__index = ColorPickerPopUp
local function sanitizeName(str)
	return str:gsub("[^%w_]", "_")
end
local function clamp(v, min, max)
	return math.max(min, math.min(max, v))
end
function ColorPickerPopUp.new(parent, Settings, cleanupCallback)
	Settings = Settings or {}
	local self = setmetatable({}, ColorPickerPopUp)
	local theme = Settings.Theme
	self._theme = theme
	-- Popup root
	local popup = Instance.new("Frame")
	popup.Name = "ColorPickerPopup"
	popup.BorderSizePixel = 0
	popup.BackgroundColor3 = (theme and theme.PopupBackgroundColor)
	popup.BackgroundTransparency = (theme and theme.PopupBackgroundTransparency) or 1
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Size = UDim2.new(0.694, 0, 1.02153, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	popup.Visible = false
	popup.ZIndex = 11
	popup.Parent = parent
	local shadow = Instance.new("UIShadow")
	shadow.Color = (theme and theme.PopupShadowColor)
	shadow.BlurRadius = UDim.new(0, 20)
	shadow.Transparency = 1
	shadow.Parent = popup
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = popup
	local scale = Instance.new("UIScale")
	scale.Scale = 0.9
	scale.Parent = popup
	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.BorderSizePixel = 0
	header.TextSize = 16
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextTransparency = (theme and theme.PopupTextTransparency) or 0.4
	header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	header.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	header.TextColor3 = (theme and theme.PopupTextColor)
	header.BackgroundTransparency = 1
	header.RichText = true
	header.AnchorPoint = Vector2.new(0.5, 0.5)
	header.Size = UDim2.new(0.21429, 0, 0.03775, 0)
	header.AutomaticSize = Enum.AutomaticSize.X
	header.Position = UDim2.new(0.5, 0, 0, 25)
	header.Parent = popup
	header.Text = "Color Picker"
	-- ColorSquare (plain button; SV square is rendered by its two gradient overlays)
	local colorSquare = Instance.new("TextButton")
	colorSquare.Name = "ColorSquare"
	colorSquare.AutoButtonColor = false
	colorSquare.BackgroundTransparency = 0
	colorSquare.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	colorSquare.Text = ""
	colorSquare.Size = UDim2.new(0.44792, 0, 0.43228, 0)
	colorSquare.ClipsDescendants = false
	colorSquare.Position = UDim2.new(0.0506, 0, 0.16117, 0)
	colorSquare.Parent = popup
	local squareCorner = Instance.new("UICorner")
	squareCorner.CornerRadius = UDim.new(0, 4)
	squareCorner.Parent = colorSquare
	local squareShadow = Instance.new("UIShadow")
	squareShadow.Color = (theme and theme.PopupShadowColor)
	squareShadow.Parent = colorSquare
	-- The SV square is built from gradients (no mystery texture) so the rendered
	-- pixels EXACTLY match the maths s = x, v = 1 - y:
	--   white base -> saturation overlay (hue-tinted, transparent left -> opaque
	--   right) -> value overlay (black, transparent top -> opaque bottom).
	local satOverlay = Instance.new("Frame")
	satOverlay.Name = "SaturationOverlay"
	satOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	satOverlay.BorderSizePixel = 0
	satOverlay.Size = UDim2.new(1, 0, 1, 0)
	satOverlay.Parent = colorSquare
	local satCorner = Instance.new("UICorner")
	satCorner.CornerRadius = UDim.new(0, 4)
	satCorner.Parent = satOverlay
	local satGradient = Instance.new("UIGradient")
	satGradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0.000, 1),
		NumberSequenceKeypoint.new(1.000, 0),
	}
	satGradient.Parent = satOverlay
	local valOverlay = Instance.new("Frame")
	valOverlay.Name = "ValueOverlay"
	valOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	valOverlay.BorderSizePixel = 0
	valOverlay.Size = UDim2.new(1, 0, 1, 0)
	valOverlay.Parent = colorSquare
	local valCorner = Instance.new("UICorner")
	valCorner.CornerRadius = UDim.new(0, 4)
	valCorner.Parent = valOverlay
	local valGradient = Instance.new("UIGradient")
	valGradient.Rotation = 90
	valGradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0.000, 1),
		NumberSequenceKeypoint.new(1.000, 0),
	}
	valGradient.Parent = valOverlay
	-- Target (visual indicator + drag surface)
	local target = Instance.new("TextButton")
	target.Name = "Target"
	target.BorderSizePixel = 0
	target.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	target.AnchorPoint = Vector2.new(0.5, 0.5)
	target.Size = UDim2.new(0, 15, 0, 15)
	target.Position = UDim2.new(0.5, 0, 0.5, 0)
	target.Active = true
	target.AutoButtonColor = false
	target.Parent = colorSquare
	local targetStroke = Instance.new("UIStroke")
	targetStroke.Transparency = 0
	targetStroke.Thickness = 2
	targetStroke.Color = Color3.fromRGB(255, 255, 255)
	targetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	targetStroke.Parent = target
	local targetCorner = Instance.new("UICorner")
	targetCorner.CornerRadius = UDim.new(1, 0)
	targetCorner.Parent = target
	-- ColorValue (TextButton with gradient)
	local colorValue = Instance.new("TextButton")
	colorValue.Name = "ColorValue"
	colorValue.BorderSizePixel = 0
	colorValue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	colorValue.AnchorPoint = Vector2.new(0.5, 0.5)
	colorValue.Size = UDim2.new(0.938, 0, 0.04291, 0)
	colorValue.LayoutOrder = 1
	colorValue.BorderColor3 = Color3.fromRGB(0, 0, 0)
	colorValue.Position = UDim2.new(0.5, 0, 0.66864, 0)
	colorValue.Text = ""
	colorValue.AutoButtonColor = false
	colorValue.ClipsDescendants = false
	colorValue.Parent = popup
	local valueGradient = Instance.new("UIGradient")
	valueGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.160, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.330, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.660, Color3.fromRGB(0, 81, 255)),
		ColorSequenceKeypoint.new(0.830, Color3.fromRGB(171, 0, 255)),
		ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 171))
	}
	valueGradient.Parent = colorValue
	local valueCorner = Instance.new("UICorner")
	valueCorner.CornerRadius = UDim.new(0, 6)
	valueCorner.Parent = colorValue
	local valueShadow = Instance.new("UIShadow")
	valueShadow.Color = (theme and theme.PopupShadowColor)
	valueShadow.Parent = colorValue
	-- Slide (visual indicator + drag surface)
	local slide = Instance.new("TextButton")
	slide.Name = "Slide"
	slide.BorderSizePixel = 0
	slide.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	slide.AnchorPoint = Vector2.new(0.5, 0.5)
	slide.Size = UDim2.new(0, 15, 1, 0)
	slide.Position = UDim2.new(0, 0, 0.5, 0)
	slide.Active = true
	slide.AutoButtonColor = false
	slide.Parent = colorValue
	local slideStroke = Instance.new("UIStroke")
	slideStroke.Transparency = 0
	slideStroke.Thickness = 2
	slideStroke.Color = Color3.fromRGB(255, 255, 255)
	slideStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	slideStroke.Parent = slide
	local slideCorner = Instance.new("UICorner")
	slideCorner.CornerRadius = UDim.new(1, 0)
	slideCorner.Parent = slide
	-- Inputs frame
	local inputsFrame = Instance.new("Frame")
	inputsFrame.Name = "Inputs"
	inputsFrame.BorderSizePixel = 0
	inputsFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	inputsFrame.AnchorPoint = Vector2.new(1, 0.5)
	inputsFrame.Size = UDim2.new(0.39286, 0, 0.37207, 0)
	inputsFrame.Position = UDim2.new(1, 0, 0.35319, 0)
	inputsFrame.BackgroundTransparency = 1
	inputsFrame.Parent = popup
	local inputsLayout = Instance.new("UIListLayout")
	inputsLayout.Padding = UDim.new(0, 7)
	inputsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	inputsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	inputsLayout.Parent = inputsFrame
	
	local inputsLayoutPadding = Instance.new("UIPadding")
	inputsLayoutPadding.PaddingRight = UDim.new(0, 10)
	inputsLayoutPadding.Parent = inputsFrame
	
	local function createInputRow(parent, labelText, defaultText, layoutOrder)
		local row = Instance.new("Frame")
		row.Name = labelText
		row.BorderSizePixel = 0
		row.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		row.BackgroundTransparency = 1
		row.AutomaticSize = Enum.AutomaticSize.XY
		row.LayoutOrder = layoutOrder
		row.Parent = parent
		local rowLayout = Instance.new("UIListLayout")
		rowLayout.Padding = UDim.new(0, 15)
		rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.Parent = row
		local label = Instance.new("TextLabel")
		label.Name = "InputName"
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.BorderSizePixel = 0
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTransparency = 0.5
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		label.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		label.TextColor3 = (theme and theme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.BorderColor3 = Color3.fromRGB(0, 0, 0)
		label.Text = labelText
		label.LayoutOrder = 1
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.Size = UDim2.new(0, 40, 0, 0)
		label.Position = UDim2.new(0, 0, 0.5, 0)
		label.Parent = row
		local inputBox = Instance.new("TextBox")
		inputBox.Name = "InputBox"
		inputBox.TextXAlignment = Enum.TextXAlignment.Left
		inputBox.BorderSizePixel = 0
		inputBox.TextTransparency = 0.5
		inputBox.TextSize = 12
		inputBox.TextColor3 = (theme and theme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
		inputBox.BackgroundColor3 = (theme and theme.PopupBackgroundColor) or Color3.fromRGB(255, 255, 255)
		inputBox.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		inputBox.AnchorPoint = Vector2.new(1, 0.5)
		inputBox.ClearTextOnFocus = false
		inputBox.ClipsDescendants = true
		inputBox.Size = UDim2.new(0, 75, 0, 25)
		inputBox.Position = UDim2.new(1, 0, 0.5, 0)
		inputBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
		inputBox.Text = defaultText
		inputBox.LayoutOrder = 2
		inputBox.BackgroundTransparency = 1
		inputBox.Parent = row
		local inputCorner = Instance.new("UICorner")
		inputCorner.Name = "InputBoxUICorner"
		inputCorner.CornerRadius = UDim.new(0, 4)
		inputCorner.Parent = inputBox
		local inputStroke = Instance.new("UIStroke")
		inputStroke.Name = "InputBoxUIStroke"
		inputStroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
		inputStroke.Color = (theme and theme.StrokeColor) or Color3.fromRGB(255, 255, 255)
		inputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		inputStroke.Parent = inputBox
		local inputPadding = Instance.new("UIPadding")
		inputPadding.Name = "InputBoxUIPadding"
		inputPadding.PaddingRight = UDim.new(0, 10)
		inputPadding.PaddingLeft = UDim.new(0, 8)
		inputPadding.Parent = inputBox
		return row, inputBox, inputStroke
	end
	local redRow, redInput, redStroke = createInputRow(inputsFrame, "Red", "255", 1)
	local greenRow, greenInput, greenStroke = createInputRow(inputsFrame, "Green", "255", 2)
	local blueRow, blueInput, blueStroke = createInputRow(inputsFrame, "Blue", "255", 3)
	local hexRow, hexInput, hexStroke = createInputRow(inputsFrame, "Hex", "#FFFFFF", 4)
	-- ColorWells
	local colorWells = Instance.new("Frame")
	colorWells.Name = "ColorWells"
	colorWells.BorderSizePixel = 0
	colorWells.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	colorWells.AnchorPoint = Vector2.new(0.5, 0.5)
	colorWells.AutomaticSize = Enum.AutomaticSize.Y
	colorWells.Size = UDim2.new(0.9375, 0, 0.08267, 0)
	colorWells.Position = UDim2.new(0.5, 0, 0.76301, 0)
	colorWells.BackgroundTransparency = 1
	colorWells.Parent = popup
	local wellsLayout = Instance.new("UIGridLayout")
	wellsLayout.CellSize = UDim2.new(0.5, -5, 0, 30)
	wellsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	wellsLayout.CellPadding = UDim2.new(0, 10, 0, 0)
	wellsLayout.Parent = colorWells
	-- Plain colour frames (only a UICorner child): the old one shows the colour
	-- the picker opened on, the new one shows the colour being picked.
	local function createColorWell(parent, name, layoutOrder)
		local well = Instance.new("Frame")
		well.Name = name
		well.BorderSizePixel = 0
		well.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		well.BackgroundTransparency = 0
		well.Size = UDim2.new(0, 100, 0, 100)
		well.LayoutOrder = layoutOrder
		well.Parent = parent
		local wellCorner = Instance.new("UICorner")
		wellCorner.CornerRadius = UDim.new(0, 6)
		wellCorner.Parent = well
		return well
	end
	local oldWell = createColorWell(colorWells, "OldColor", 1)
	local newWell = createColorWell(colorWells, "NewColor", 0)
	-- Interactions
	local interactions = Instance.new("Frame")
	interactions.Name = "Interactions"
	interactions.BorderSizePixel = 0
	interactions.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	interactions.AnchorPoint = Vector2.new(0.5, 0.5)
	interactions.Size = UDim2.new(0.9375, 0, 0.13562, 0)
	interactions.Position = UDim2.new(0.5, 0, 0.90934, 0)
	interactions.BackgroundTransparency = 1
	interactions.Parent = popup
	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Name = "Confirm"
	confirmBtn.BorderSizePixel = 0
	confirmBtn.TextTransparency = 0.2
	confirmBtn.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.TextSize = 12
	confirmBtn.AutoButtonColor = false
	confirmBtn.TextColor3 = (theme and theme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
	confirmBtn.BackgroundColor3 = (theme and theme.PrimaryColor) or Color3.fromRGB(14, 45, 178)
	confirmBtn.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	confirmBtn.AnchorPoint = Vector2.new(0.5, 0)
	confirmBtn.Size = UDim2.new(1, 0, 0.43911, 0)
	confirmBtn.Position = UDim2.new(0.5, 0, 0, 0)
	confirmBtn.Text = "Confirm"
	confirmBtn.Parent = interactions
	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 4)
	confirmCorner.Parent = confirmBtn
	local confirmShadow = Instance.new("UIShadow")
	confirmShadow.BlurRadius = UDim.new(0, 20)
	confirmShadow.Color = (theme and theme.PrimaryColor) or Color3.fromRGB(13, 44, 177)
	confirmShadow.Transparency = 1
	confirmShadow.Parent = confirmBtn
	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Name = "Cancel"
	cancelBtn.BorderSizePixel = 0
	cancelBtn.TextTransparency = 0.5
	cancelBtn.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.TextSize = 12
	cancelBtn.AutoButtonColor = false
	cancelBtn.TextColor3 = (theme and theme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
	cancelBtn.BackgroundColor3 = (theme and theme.PopupNeutralColor) or Color3.fromRGB(46, 46, 46)
	cancelBtn.BackgroundTransparency = 0.5
	cancelBtn.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	cancelBtn.AnchorPoint = Vector2.new(0.5, 1)
	cancelBtn.Size = UDim2.new(1, 0, 0.43882, 0)
	cancelBtn.Position = UDim2.new(0.5, 0, 1, 0)
	cancelBtn.Text = "Cancel"
	cancelBtn.Parent = interactions
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 4)
	cancelCorner.Parent = cancelBtn
	local cancelShadow = Instance.new("UIShadow")
	cancelShadow.BlurRadius = UDim.new(0, 20)
	cancelShadow.Color = (theme and theme.PopupNeutralColor) or Color3.fromRGB(0, 0, 0)
	cancelShadow.Transparency = 1
	cancelShadow.Parent = cancelBtn
	-- Store references
	self.Popup = popup
	self.Shadow = shadow
	self.Header = header
	self.ColorSquare = colorSquare
	self.SatOverlay = satOverlay
	self.ValOverlay = valOverlay
	self.Target = target
	self.ColorValue = colorValue
	self.Slide = slide
	self.ValueGradient = valueGradient
	self.Inputs = {
		Red = { Row = redRow, Input = redInput, Stroke = redStroke },
		Green = { Row = greenRow, Input = greenInput, Stroke = greenStroke },
		Blue = { Row = blueRow, Input = blueInput, Stroke = blueStroke },
		Hex = { Row = hexRow, Input = hexInput, Stroke = hexStroke },
	}
	self.OldWell = oldWell
	self.NewWell = newWell
	self.ConfirmBtn = confirmBtn
	self.ConfirmShadow = confirmShadow
	self.CancelBtn = cancelBtn
	self.CancelShadow = cancelShadow
	self._cleanupCallback = cleanupCallback
	-- Default callbacks
	self.OnConfirm = function() end
	self.OnCancel = function() end
	-- State
	self._currentColor = Color3.fromRGB(255, 255, 255)
	self._oldColor = Color3.fromRGB(255, 255, 255)
	self._hue = 0
	self._sat = 0
	self._val = 1
	self._isOpen = false
	self._resolved = false
	self._inputConnection = nil
	self._hideTimer = nil
	-- Repaint every visual from the stored HSV state. The square's saturation
	-- overlay is tinted to the hue; its position maths (s = x, v = 1 - y) then
	-- matches the rendered gradient exactly, so the picked colour equals the
	-- colour under the target.
	local function refreshVisuals()
		local h, s, v = self._hue, self._sat, self._val
		local hueColor = Color3.fromHSV(h, 1, 1)
		self.SatOverlay.BackgroundColor3 = hueColor
		self.Slide.BackgroundColor3 = hueColor
		self.Target.BackgroundColor3 = Color3.fromHSV(h, s, v)
		self.Target.Position = UDim2.new(s, 0, 1 - v, 0)
		self.Slide.Position = UDim2.new(h, 0, 0.5, 0)
		self.NewWell.BackgroundColor3 = Color3.fromHSV(h, s, v)
		self.OldWell.BackgroundColor3 = self._oldColor
	end
	-- Push the stored HSV into the RGB/Hex input boxes.
	local function refreshInputsFromState()
		local color = Color3.fromHSV(self._hue, self._sat, self._val)
		local r = math.round(color.R * 255)
		local g = math.round(color.G * 255)
		local b = math.round(color.B * 255)
		self.Inputs.Red.Input.Text = tostring(r)
		self.Inputs.Green.Input.Text = tostring(g)
		self.Inputs.Blue.Input.Text = tostring(b)
		self.Inputs.Hex.Input.Text = string.format("#%02X%02X%02X", r, g, b)
	end
	function self:_setColorAndUpdate(color)
		self._currentColor = color
		self._hue, self._sat, self._val = color:ToHSV()
		refreshVisuals()
		refreshInputsFromState()
	end
	-- Drag path: keep the picked HSV verbatim (NOT ToHSV of the rebuilt colour),
	-- so dragging to s=0 / v=0 / h=1 boundaries never loses the handle's position
	-- or makes it snap.
	function self:_setHSVAndUpdate(h, s, v)
		self._hue = math.clamp(h, 0, 1)
		self._sat = math.clamp(s, 0, 1)
		self._val = math.clamp(v, 0, 1)
		self._currentColor = Color3.fromHSV(self._hue, self._sat, self._val)
		refreshVisuals()
		refreshInputsFromState()
	end
	function self:SetContent(Settings)
		local title = Settings.Title or "Color Picker"
		local currentColor = Settings.CurrentColor
		self.OnConfirm = Settings.OnConfirm or function() end
		self.OnCancel = Settings.OnCancel or function() end
		self.Header.Text = title
		self._oldColor = currentColor
		self._currentColor = currentColor
		self._resolved = false
		self:_setColorAndUpdate(currentColor)
		self.OldWell.BackgroundColor3 = currentColor
	end
	-- Re-apply every theme-driven color to a new theme WITHOUT rebuilding.
	-- Called by Window:SetTheme so an open (or cached) picker recolors live
	-- instead of being destroyed and recreated.
	function self:ApplyTheme(theme)
		if not self.Popup then return end
		theme = ThemeManager.GetTheme(theme)
		self._theme = theme
		self.Popup.BackgroundColor3 = theme.PopupBackgroundColor or self.Popup.BackgroundColor3
		if self.Shadow then self.Shadow.Color = theme.PopupShadowColor or self.Shadow.Color end
		self.Header.TextColor3 = theme.PopupTextColor or self.Header.TextColor3
		for _, info in pairs(self.Inputs) do
			info.Input.TextColor3 = theme.PopupTextColor or info.Input.TextColor3
			info.Input.BackgroundColor3 = theme.PopupBackgroundColor or info.Input.BackgroundColor3
			info.Stroke.Color = theme.StrokeColor or info.Stroke.Color
			local label = info.Row:FindFirstChild("InputName")
			if label then label.TextColor3 = theme.PopupTextColor or label.TextColor3 end
		end
		local squareShadow = self.ColorSquare:FindFirstChildOfClass("UIShadow")
		if squareShadow then squareShadow.Color = theme.PopupShadowColor or squareShadow.Color end
		local valueShadow = self.ColorValue:FindFirstChildOfClass("UIShadow")
		if valueShadow then valueShadow.Color = theme.PopupShadowColor or valueShadow.Color end
		-- Target/Slide handle strokes stay opaque white; not theme-driven.
		local targetStroke = self.Target:FindFirstChildOfClass("UIStroke")
		if targetStroke then targetStroke.Color = Color3.fromRGB(255, 255, 255); targetStroke.Transparency = 0 end
		local slideStroke = self.Slide:FindFirstChildOfClass("UIStroke")
		if slideStroke then slideStroke.Color = Color3.fromRGB(255, 255, 255); slideStroke.Transparency = 0 end
		self.ConfirmBtn.TextColor3 = theme.PopupTextColor or self.ConfirmBtn.TextColor3
		self.ConfirmBtn.BackgroundColor3 = theme.PrimaryColor or self.ConfirmBtn.BackgroundColor3
		self.ConfirmShadow.Color = theme.PrimaryColor or self.ConfirmShadow.Color
		self.CancelBtn.TextColor3 = theme.PopupTextColor or self.CancelBtn.TextColor3
		self.CancelBtn.BackgroundColor3 = theme.PopupNeutralColor or self.CancelBtn.BackgroundColor3
		self.CancelShadow.Color = theme.PopupNeutralColor or self.CancelShadow.Color
	end
	function self:Open()
		if not self.Popup then return end
		if self._hideTimer then
			task.cancel(self._hideTimer)
			self._hideTimer = nil
		end
		self.IsOpen = true
		self._isOpen = true
		self._resolved = false
		self.Popup.Visible = true
		self.Popup.BackgroundTransparency = 1
		self.Shadow.Transparency = 1
		local function resetTransparency(obj)
			if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
				obj.TextTransparency = 1
			end
			if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
				obj.ImageTransparency = 1
			end
			if obj:IsA("Frame") and obj ~= self.Popup and obj ~= self.Shadow then
				obj.BackgroundTransparency = 1
			end
			if obj:IsA("UIStroke") then
				obj.Transparency = 1
			end
			if obj:IsA("UIShadow") then
				obj.Transparency = 1
			end
			for _, child in ipairs(obj:GetChildren()) do
				resetTransparency(child)
			end
		end
		resetTransparency(self.Popup)
		-- Restore the elements resetTransparency blanked. ColorSquare is a plain
		-- white frame (transparency 0) with two gradient overlays; ColorValue
		-- carries the hue gradient; the wells are plain colour frames.
		self.ColorSquare.BackgroundTransparency = 0
		self.SatOverlay.BackgroundTransparency = 0
		self.ValOverlay.BackgroundTransparency = 0
		self.ColorValue.BackgroundTransparency = 0
		self.Target.BackgroundTransparency = 0
		self.Slide.BackgroundTransparency = 0
		self.OldWell.BackgroundTransparency = 0
		self.NewWell.BackgroundTransparency = 0
		-- Target/Slide handles always use an opaque white stroke (not theme-driven).
		local targetStroke = self.Target:FindFirstChildOfClass("UIStroke")
		if targetStroke then targetStroke.Color = Color3.fromRGB(255, 255, 255); targetStroke.Transparency = 0 end
		local slideStroke = self.Slide:FindFirstChildOfClass("UIStroke")
		if slideStroke then slideStroke.Color = Color3.fromRGB(255, 255, 255); slideStroke.Transparency = 0 end
		-- Input strokes initialised inconsistently; set them ALL to one uniform
		-- base (read from the live theme) on every open.
		local liveStroke = ThemeManager.GetTheme(self._theme)
		local baseStrokeT = liveStroke.StrokeTransparency or 0.95
		for _, info in pairs(self.Inputs) do
			info.Stroke.Color = liveStroke.StrokeColor or Color3.fromRGB(255, 255, 255)
			info.Stroke.Transparency = baseStrokeT
		end
		Tween.Play(self.Popup, "Smooth", { BackgroundTransparency = 0.07 })
		Tween.Play(self.Shadow, "Smooth", { Transparency = 0.5 })
		Tween.Play(self.Header, "Smooth", { TextTransparency = 0.4 })
		Tween.Play(self.SatOverlay, "Smooth", { BackgroundTransparency = 0 })
		Tween.Play(self.ValOverlay, "Smooth", { BackgroundTransparency = 0 })
		Tween.Play(self.ColorValue, "Smooth", { BackgroundTransparency = 0 })
		for _, info in pairs(self.Inputs) do
			Tween.Play(info.Input, "Smooth", { TextTransparency = 0.5 })
			local label = info.Row:FindFirstChild("InputName")
			if label then Tween.Play(label, "Smooth", { TextTransparency = 0.5 }) end
		end
		Tween.Play(self.ConfirmBtn, "Smooth", { TextTransparency = 0.2, BackgroundTransparency = 0 })
		Tween.Play(self.CancelBtn, "Smooth", { TextTransparency = 0.5, BackgroundTransparency = 0.5 })
		Tween.Play(self.ConfirmShadow, "Smooth", { Transparency = 0.5 })
		self:_setColorAndUpdate(self._currentColor)
		local UserInputService = game:GetService("UserInputService")
		-- Avoid stacking duplicate connections if Open() is called twice in a row
		if self._inputConnection then
			self._inputConnection:Disconnect()
			self._inputConnection = nil
		end
		local function onInputBegan(input, processed)
			if processed then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local pos = input.Position
				local popupPos = self.Popup.AbsolutePosition
				local popupSize = self.Popup.AbsoluteSize
				local inside = pos.X >= popupPos.X and pos.X <= popupPos.X + popupSize.X
					and pos.Y >= popupPos.Y and pos.Y <= popupPos.Y + popupSize.Y
				if not inside then
					self:_Confirm()
				end
			end
		end
		self._inputConnection = UserInputService.InputBegan:Connect(onInputBegan)
	end
	function self:Close()
		if not self.Popup or not self.IsOpen then return end
		self.IsOpen = false
		self._isOpen = false
		if self._inputConnection then
			self._inputConnection:Disconnect()
			self._inputConnection = nil
		end
		if self._hideTimer then
			task.cancel(self._hideTimer)
			self._hideTimer = nil
		end
		Tween.Play(self.Popup, "Smooth", { BackgroundTransparency = 1 })
		Tween.Play(self.Shadow, "Smooth", { Transparency = 1 })
		local function fadeObject(obj)
			local goals = {}
			if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
				goals.TextTransparency = 1
				goals.BackgroundTransparency = 1
			end
			if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
				goals.ImageTransparency = 1
				goals.BackgroundTransparency = 1
			end
			if obj:IsA("Frame") and obj ~= self.Popup then
				goals.BackgroundTransparency = 1
			end
			if obj:IsA("UIStroke") then
				goals.Transparency = 1
			end
			if obj:IsA("UIShadow") then
				goals.Transparency = 1
			end
			if next(goals) then
				Tween.Play(obj, "Smooth", goals)
			end
		end
		for _, descendant in ipairs(self.Popup:GetDescendants()) do
			fadeObject(descendant)
		end
		Tween.Play(self.Popup:FindFirstChildOfClass("UIScale"), "Smooth", { Scale = 0.9 })
		self._hideTimer = task.delay(0.35, function()
			if self.Popup and not self.IsOpen then
				self.Popup.Visible = false
			end
			self._hideTimer = nil
		end)
	end
	function self:_Confirm()
		if self._resolved then return end
		self._resolved = true
		self:Close()
		self.OnConfirm(self._currentColor)
	end
	function self:_Cancel()
		if self._resolved then return end
		self._resolved = true
		self:Close()
		self.OnCancel()
	end
	-- Hide without firing callbacks (used by Window when another popup opens)
	function self:Hide()
		self:Close()
	end
	function self:Destroy()
		if self._inputConnection then
			self._inputConnection:Disconnect()
			self._inputConnection = nil
		end
		if self._dragChangedConnection then
			self._dragChangedConnection:Disconnect()
			self._dragChangedConnection = nil
		end
		if self._dragEndedConnection then
			self._dragEndedConnection:Disconnect()
			self._dragEndedConnection = nil
		end
		if self.Popup then
			self.Popup:Destroy()
			self.Popup = nil
		end
		if self._cleanupCallback then
			self._cleanupCallback()
			self._cleanupCallback = nil
		end
	end
	-- Event connections
	self.ConfirmBtn.MouseButton1Click:Connect(function() self:_Confirm() end)
	self.CancelBtn.MouseButton1Click:Connect(function() self:_Cancel() end)
	self.ConfirmBtn.MouseEnter:Connect(function()
		Tween.Play(self.ConfirmShadow, "Smooth", { BlurRadius = UDim.new(0, 50), Transparency = 0 })
	end)
	self.ConfirmBtn.MouseLeave:Connect(function()
		Tween.Play(self.ConfirmShadow, "Smooth", { BlurRadius = UDim.new(0, 20), Transparency = 1 })
	end)
	self.CancelBtn.MouseEnter:Connect(function()
		Tween.Play(self.CancelBtn, "Smooth", { TextTransparency = 0.2 })
	end)
	self.CancelBtn.MouseLeave:Connect(function()
		Tween.Play(self.CancelBtn, "Smooth", { TextTransparency = 0.5 })
	end)
	-- Drag functions
	local function setFromSquarePosition(screenPosition)
		local size = self.ColorSquare.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then return end
		local squarePos = self.ColorSquare.AbsolutePosition
		local x = clamp((screenPosition.X - squarePos.X) / size.X, 0, 1)
		local y = clamp((screenPosition.Y - squarePos.Y) / size.Y, 0, 1)
		-- Keep the existing hue; saturation = x, value = 1 - y. Set via the
		-- HSV-preserving path so the handle never snaps at the edges.
		self:_setHSVAndUpdate(self._hue, x, 1 - y)
	end
	local function setFromHuePosition(screenPosition)
		local size = self.ColorValue.AbsoluteSize
		if size.X <= 0 then return end
		local barPos = self.ColorValue.AbsolutePosition
		local h = clamp((screenPosition.X - barPos.X) / size.X, 0, 1)
		self:_setHSVAndUpdate(h, self._sat, self._val)
	end
	-- Click-and-drag anywhere on the square/bar to move the indicator.
	-- UIDragDetector only drags the instance it's attached to (the handle),
	-- so we track the whole surface manually instead.
	local UserInputService = game:GetService("UserInputService")
	local squareDragging = false
	local barDragging = false
	colorSquare.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			squareDragging = true
			setFromSquarePosition(input.Position)
		end
	end)
	colorValue.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			barDragging = true
			setFromHuePosition(input.Position)
		end
	end)
	-- Follow the drag globally so it keeps working even if the cursor leaves the
	-- square/bar. These live on UserInputService, so they are disconnected in
	-- Destroy() (otherwise each picker leaks two global connections).
	self._dragChangedConnection = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if squareDragging then
				setFromSquarePosition(input.Position)
			elseif barDragging then
				setFromHuePosition(input.Position)
			end
		end
	end)
	self._dragEndedConnection = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			squareDragging = false
			barDragging = false
		end
	end)
	-- Input focus lost
	local function onFocusLost(inputBox, channel)
		inputBox.FocusLost:Connect(function()
			local text = inputBox.Text
			if channel == "Hex" then
				-- Handle hex first so values like "123456" aren't parsed as numbers
				local hex = text:gsub("#", "")
				if #hex == 6 then
					local r = tonumber(hex:sub(1,2), 16)
					local g = tonumber(hex:sub(3,4), 16)
					local b = tonumber(hex:sub(5,6), 16)
					if r and g and b then
						self:_setColorAndUpdate(Color3.fromRGB(r, g, b))
					end
				end
			else
				local num = tonumber(text)
				if num ~= nil then
					local r, g, b
					if channel == "Red" then
						r = math.clamp(num, 0, 255)
						g = self._currentColor.G * 255
						b = self._currentColor.B * 255
						self:_setColorAndUpdate(Color3.fromRGB(r, g, b))
					elseif channel == "Green" then
						r = self._currentColor.R * 255
						g = math.clamp(num, 0, 255)
						b = self._currentColor.B * 255
						self:_setColorAndUpdate(Color3.fromRGB(r, g, b))
					elseif channel == "Blue" then
						r = self._currentColor.R * 255
						g = self._currentColor.G * 255
						b = math.clamp(num, 0, 255)
						self:_setColorAndUpdate(Color3.fromRGB(r, g, b))
					end
				end
			end
		end)
	end
	for channel, info in pairs(self.Inputs) do
		onFocusLost(info.Input, channel)
		local function setStrokeBright(bright)
			-- Read the LIVE theme (self._theme is kept current by ApplyTheme), not
			-- the construction-time Settings.Theme, so hover/focus after a theme
			-- switch doesn't write the old theme's colors back.
			local liveTheme = ThemeManager.GetTheme(self._theme)
			local baseTrans = liveTheme.StrokeTransparency or 0.95
			local baseColor = liveTheme.StrokeColor or Color3.fromRGB(255, 255, 255)
			local targetTrans = bright and 0.3 or baseTrans
			local targetColor = bright and (liveTheme.PrimaryColor or baseColor) or baseColor
			Tween.Play(info.Stroke, "Fast", { Transparency = targetTrans, Color = targetColor })
		end
		info.Input.MouseEnter:Connect(function() setStrokeBright(true) end)
		info.Input.MouseLeave:Connect(function()
			if not info.Input:IsFocused() then setStrokeBright(false) end
		end)
		info.Input.Focused:Connect(function() setStrokeBright(true) end)
		info.Input.FocusLost:Connect(function() setStrokeBright(false) end)
	end
	return self
end
return ColorPickerPopUp