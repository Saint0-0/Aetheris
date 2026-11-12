--[[
	Aetheris/Popups/ColorPickerPopUp.luau

	Modal colour picker: saturation/value square, hue and alpha pills, a hex
	field with a live swatch, RGB fields, preset/recent swatches and an
	original -> new footer pair. Cached per id by Window and reused; theme
	switches recolor it in place.

	Alpha is carried beside the colour (0-255) because Color3 has no alpha;
	OnConfirm receives (Color3, alpha).

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

local UserInputService = game:GetService("UserInputService")

local ColorPickerPopUp = {}
ColorPickerPopUp.__index = ColorPickerPopUp

local function clamp(v, min, max)
	return math.max(min, math.min(max, v))
end

-- design-notes 6/10: the shell carries a top-down multiplier wash (no rim
-- stroke - fill plus shadow edge it, same as the Changelog) at radius 12.
local CORNER_SHELL = 12
local CORNER_CARD = 10
local FALLBACK_POPUP = Color3.fromRGB(15, 15, 16)
local FALLBACK_NEUTRAL = Color3.fromRGB(46, 46, 46)

-- Fixed card geometry, scaled down on small windows by the UIScale below.
local POPUP_WIDTH = 440
local POPUP_HEIGHT = 460
local SIDE_PAD = 16
local LEFT_WIDTH = 244
local RIGHT_X = SIDE_PAD + LEFT_WIDTH + 12
local RIGHT_WIDTH = POPUP_WIDTH - SIDE_PAD - RIGHT_X
local FOOTER_HEIGHT = 54
local FOOTER_TOP = POPUP_HEIGHT - FOOTER_HEIGHT

local CHECKER_TONE = 0.22
local RECENT_LIMIT = 8
local ALPHA_MAX = 255

-- Neutral-to-hue row, twice four: grays then hues. Presets are fixed colour
-- references, not theme slots (design-notes 10: colour lives in the chips).
local PRESETS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(160, 160, 168),
	Color3.fromRGB(72, 72, 78),
	Color3.fromRGB(0, 0, 0),
	Color3.fromRGB(255, 92, 92),
	Color3.fromRGB(255, 159, 67),
	Color3.fromRGB(76, 217, 123),
	Color3.fromRGB(91, 140, 255),
}

-- Confirmed colours, newest first, shared by every picker in the session.
local RECENT = {}

local function isDark(color)
	return (color.R * 0.299 + color.G * 0.587 + color.B * 0.114) < 0.5
end

-- UIGradient.Color multiplies what it paints, so the ramp is a gray
-- multiplier pair rather than literal colours (design-notes 10).
local function stampShellGradient(gradient, t)
	local base = (t and t.PopupBackgroundColor) or FALLBACK_POPUP
	local top = if isDark(base) then 0.9 else 0.96
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(top, top, top)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
end

-- Accent-as-text derivation (design-notes 5): hue kept, saturation capped,
-- value forced up on dark grounds; darkened on light ones.
local function accentText(color, onDark)
	if onDark then
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, math.min(s, 0.75), math.max(v, 0.92))
	end
	return color:Lerp(Color3.new(0, 0, 0), 0.3)
end

-- Tile fills derive from theme slots so they follow light and dark themes
-- (design-notes 10) instead of copying Novoline's fixed dark tints.
local function tileFill(tint, base)
	if isDark(base) then
		return base:Lerp(tint, 0.4):Lerp(Color3.new(0, 0, 0), 0.35)
	end
	return base:Lerp(tint, 0.3)
end

local function stampHeaderTile(tile, glyph, t)
	local tint = (t and t.AccentColor) or Color3.fromRGB(96, 165, 250)
	local base = (t and t.PopupBackgroundColor) or FALLBACK_POPUP
	tile.BackgroundColor3 = tileFill(tint, base)
	glyph.ImageColor3 = accentText(tint, isDark(base))
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = parent
	return corner
end

local function formatHex(color)
	local r = math.floor(color.R * 255 + 0.5)
	local g = math.floor(color.G * 255 + 0.5)
	local b = math.floor(color.B * 255 + 0.5)
	return string.format("#%02X%02X%02X", r, g, b)
end

-- Accepts #abc, abc, aabbcc and 8-digit aabbccaa; leading # and spaces drop.
-- Returns the colour plus an optional alpha (nil when the text had none).
local function parseHex(text)
	if type(text) ~= "string" then
		return nil
	end
	local hex = string.upper((text:gsub("[%s#]", "")))
	if #hex == 3 or #hex == 4 then
		hex = hex:gsub(".", "%0%0")
	end
	if (#hex ~= 6 and #hex ~= 8) or not hex:match("^%x+$") then
		return nil
	end
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	if not r or not g or not b then
		return nil
	end
	local alpha = nil
	if #hex == 8 then
		alpha = tonumber(hex:sub(7, 8), 16)
	end
	return Color3.fromRGB(r, g, b), alpha
end

-- Checkerboard backing for translucent surfaces: frame-scale tiles, so the
-- same helper works for the alpha bar, the swatch dot and the footer wells.
local function newChecker(parent, cols, rows)
	local tiles = {}
	for row = 0, rows - 1 do
		for col = 0, cols - 1 do
			local tile = Instance.new("Frame")
			tile.Name = UUID.Static("CheckerTile")
			tile.BorderSizePixel = 0
			tile.Size = UDim2.fromScale(1 / cols, 1 / rows)
			tile.Position = UDim2.fromScale(col / cols, row / rows)
			tile.Parent = parent
			tiles[#tiles + 1] = { Tile = tile, Even = ((col + row) % 2 == 0) }
		end
	end
	return tiles
end

local function stampChecker(tiles, theme)
	local base = (theme and theme.PopupNeutralColor) or FALLBACK_NEUTRAL
	local light = base:Lerp(Color3.new(1, 1, 1), CHECKER_TONE)
	for _, record in ipairs(tiles) do
		record.Tile.BackgroundColor3 = if record.Even then base else light
	end
end

local function rememberColor(color)
	for i = #RECENT, 1, -1 do
		if RECENT[i] == color then
			table.remove(RECENT, i)
		end
	end
	table.insert(RECENT, 1, color)
	while #RECENT > RECENT_LIMIT do
		table.remove(RECENT)
	end
end

function ColorPickerPopUp.new(parent, Settings, cleanupCallback)
	Settings = Settings or {}
	local theme = ThemeManager.GetTheme(Settings.Theme)
	local self = setmetatable({}, ColorPickerPopUp)
	self._theme = theme
	self._parent = parent

	local popup = Instance.new("CanvasGroup")
	popup.Name = UUID.Generate("ColorPickerPopup")
	popup.BorderSizePixel = 0
	popup.GroupTransparency = 1
	popup.BackgroundColor3 = (theme and theme.PopupBackgroundColor) or FALLBACK_POPUP
	popup.BackgroundTransparency = (theme and theme.PopupBackgroundTransparency) or 0.07
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Size = UDim2.fromOffset(POPUP_WIDTH, POPUP_HEIGHT)
	popup.Position = UDim2.fromScale(0.5, 0.5)
	popup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	popup.Visible = false
	popup.Active = true
	popup.ZIndex = 12
	popup.Parent = parent

	-- Collections restamped by ApplyTheme (derived values, not theme slots).
	local texts = {}
	local fieldStrokes = {}
	local barStrokes = {}
	local checkers = {}

	-- Shell wash first: a top-down multiplier over the whole group (the
	-- CanvasGroup tints its subtree with it, matching the Changelog shell).
	local shellGradient = Instance.new("UIGradient")
	stampShellGradient(shellGradient, theme)
	shellGradient.Parent = popup
	local shadow = Instance.new("UIShadow")
	shadow.Color = (theme and theme.PopupShadowColor)
	shadow.BlurRadius = UDim.new(0, 20)
	shadow.Transparency = 1
	shadow.Parent = popup
	addCorner(popup, UDim.new(0, CORNER_SHELL))
	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = popup

	-- Accent tile + left-set title, the Changelog header (design-notes 6).
	local headTile = Instance.new("Frame")
	headTile.Name = UUID.Static("HeaderTile")
	headTile.BorderSizePixel = 0
	headTile.Size = UDim2.fromOffset(30, 30)
	headTile.Position = UDim2.fromOffset(SIDE_PAD, 14)
	headTile.Parent = popup
	addCorner(headTile, UDim.new(0, 10))
	local headGlyph = Instance.new("ImageLabel")
	headGlyph.Name = UUID.Static("HeaderGlyph")
	headGlyph.BorderSizePixel = 0
	headGlyph.BackgroundTransparency = 1
	headGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
	headGlyph.Position = UDim2.fromScale(0.5, 0.5)
	headGlyph.Size = UDim2.fromOffset(16, 16)
	headGlyph.Image = Icons["palette"] or Icons.droplet
	headGlyph.Parent = headTile
	stampHeaderTile(headTile, headGlyph, theme)

	local header = Instance.new("TextLabel")
	header.Name = UUID.Static("Header")
	header.BorderSizePixel = 0
	header.TextSize = 15
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextYAlignment = Enum.TextYAlignment.Center
	header.TextTruncate = Enum.TextTruncate.AtEnd
	header.TextTransparency = 0.2
	header.BackgroundTransparency = 1
	header.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	header.TextColor3 = (theme and theme.PopupTextColor)
	header.Size = UDim2.new(1, -140, 0, 30)
	header.Position = UDim2.fromOffset(56, 14)
	header.Parent = popup
	header.Text = "Color Picker"
	texts[#texts + 1] = header

	-- 28px circle close with a 16px glyph (design-notes 6); closes as cancel.
	local closeBtn = Instance.new("ImageButton")
	closeBtn.Name = UUID.Static("Close")
	closeBtn.BorderSizePixel = 0
	closeBtn.BackgroundColor3 = Color3.new(1, 1, 1)
	closeBtn.BackgroundTransparency = 0.92
	closeBtn.AutoButtonColor = false
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.Position = UDim2.new(1, -10, 0, 15)
	closeBtn.Parent = popup
	addCorner(closeBtn, UDim.new(1, 0))
	local closeIcon = Instance.new("ImageLabel")
	closeIcon.Name = UUID.Static("CloseIcon")
	closeIcon.BorderSizePixel = 0
	closeIcon.BackgroundTransparency = 1
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.Position = UDim2.fromScale(0.5, 0.5)
	closeIcon.Size = UDim2.fromOffset(16, 16)
	closeIcon.Image = Icons["x"] or "rbxassetid://110786993356448"
	closeIcon.ImageTransparency = 0.4
	closeIcon.ImageColor3 = (theme and theme.PopupTextColor)
	closeIcon.Parent = closeBtn
	texts[#texts + 1] = closeIcon

	-- =====================================================================
	--  Left column: saturation/value square, hue pill, alpha pill
	-- =====================================================================
	local colorSquare = Instance.new("TextButton")
	colorSquare.Name = UUID.Static("ColorSquare")
	colorSquare.AutoButtonColor = false
	colorSquare.BackgroundTransparency = 0
	colorSquare.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	colorSquare.Text = ""
	colorSquare.Size = UDim2.fromOffset(LEFT_WIDTH, 240)
	colorSquare.Position = UDim2.fromOffset(SIDE_PAD, 62)
	colorSquare.Parent = popup
	addCorner(colorSquare, UDim.new(0, CORNER_CARD))
	local squareShadow = Instance.new("UIShadow")
	squareShadow.Color = (theme and theme.PopupShadowColor)
	squareShadow.Parent = colorSquare
	-- Gradients, not a texture, so the rendered pixels match the s = x, v = 1 - y maths exactly.
	local satOverlay = Instance.new("Frame")
	satOverlay.Name = UUID.Static("SaturationOverlay")
	satOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	satOverlay.BorderSizePixel = 0
	satOverlay.Size = UDim2.fromScale(1, 1)
	satOverlay.Parent = colorSquare
	addCorner(satOverlay, UDim.new(0, CORNER_CARD))
	local satGradient = Instance.new("UIGradient")
	satGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.000, 1),
		NumberSequenceKeypoint.new(1.000, 0),
	})
	satGradient.Parent = satOverlay
	local valOverlay = Instance.new("Frame")
	valOverlay.Name = UUID.Static("ValueOverlay")
	valOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	valOverlay.BorderSizePixel = 0
	valOverlay.Size = UDim2.fromScale(1, 1)
	valOverlay.Parent = colorSquare
	addCorner(valOverlay, UDim.new(0, CORNER_CARD))
	local valGradient = Instance.new("UIGradient")
	valGradient.Rotation = 90
	valGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.000, 1),
		NumberSequenceKeypoint.new(1.000, 0),
	})
	valGradient.Parent = valOverlay
	local target = Instance.new("Frame")
	target.Name = UUID.Static("Target")
	target.BorderSizePixel = 0
	target.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	target.AnchorPoint = Vector2.new(0.5, 0.5)
	target.Size = UDim2.fromOffset(15, 15)
	target.Position = UDim2.fromScale(0.5, 0.5)
	target.Parent = colorSquare
	local targetStroke = Instance.new("UIStroke")
	targetStroke.Transparency = 0
	targetStroke.Thickness = 2
	targetStroke.Color = Color3.fromRGB(255, 255, 255)
	targetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	targetStroke.Parent = target
	addCorner(target, UDim.new(1, 0))

	local function newCaption(text, x, y, width, alignment)
		local label = Instance.new("TextLabel")
		label.Name = UUID.Static("RowLabel")
		label.BorderSizePixel = 0
		label.BackgroundTransparency = 1
		label.TextSize = 11
		label.FontFace = Constants.Font(Enum.FontWeight.Medium)
		label.TextColor3 = (theme and theme.PopupTextColor)
		label.TextTransparency = 0.45
		label.TextXAlignment = alignment or Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Size = UDim2.fromOffset(width, 14)
		label.Position = UDim2.fromOffset(x, y)
		label.Text = text
		label.Parent = popup
		texts[#texts + 1] = label
		return label
	end

	newCaption("Hue", SIDE_PAD, 312, 80)
	local hueValue = newCaption("0°", SIDE_PAD + LEFT_WIDTH - 60, 312, 60, Enum.TextXAlignment.Right)
	newCaption("Alpha", SIDE_PAD, 352, 80)
	local alphaValue = newCaption("100%", SIDE_PAD + LEFT_WIDTH - 60, 352, 60, Enum.TextXAlignment.Right)

	local hueBar = Instance.new("TextButton")
	hueBar.Name = UUID.Static("HueBar")
	hueBar.AutoButtonColor = false
	hueBar.BorderSizePixel = 0
	hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	hueBar.Text = ""
	hueBar.Size = UDim2.fromOffset(LEFT_WIDTH, 16)
	hueBar.Position = UDim2.fromOffset(SIDE_PAD, 328)
	hueBar.Parent = popup
	addCorner(hueBar, UDim.new(0.5, 0))
	local hueGradient = Instance.new("UIGradient")
	hueGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.160, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.330, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.660, Color3.fromRGB(0, 81, 255)),
		ColorSequenceKeypoint.new(0.830, Color3.fromRGB(171, 0, 255)),
		ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 171)),
	})
	hueGradient.Parent = hueBar
	local hueStroke = Instance.new("UIStroke")
	hueStroke.Color = (theme and theme.StrokeColor) or Color3.fromRGB(255, 255, 255)
	hueStroke.Transparency = math.max((theme and theme.StrokeTransparency) or 0.95, 0.85)
	hueStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	hueStroke.Parent = hueBar
	barStrokes[#barStrokes + 1] = hueStroke
	local hueKnob = Instance.new("Frame")
	hueKnob.Name = UUID.Static("HueKnob")
	hueKnob.BorderSizePixel = 0
	hueKnob.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	hueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	hueKnob.Size = UDim2.fromOffset(14, 14)
	hueKnob.Position = UDim2.fromScale(0, 0.5)
	hueKnob.Parent = hueBar
	local hueKnobStroke = Instance.new("UIStroke")
	hueKnobStroke.Transparency = 0
	hueKnobStroke.Thickness = 2
	hueKnobStroke.Color = Color3.fromRGB(255, 255, 255)
	hueKnobStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	hueKnobStroke.Parent = hueKnob
	addCorner(hueKnob, UDim.new(1, 0))

	local alphaBar = Instance.new("TextButton")
	alphaBar.Name = UUID.Static("AlphaBar")
	alphaBar.AutoButtonColor = false
	alphaBar.BorderSizePixel = 0
	alphaBar.BackgroundColor3 = (theme and theme.PopupNeutralColor) or FALLBACK_NEUTRAL
	alphaBar.Text = ""
	alphaBar.Size = UDim2.fromOffset(LEFT_WIDTH, 16)
	alphaBar.Position = UDim2.fromOffset(SIDE_PAD, 368)
	alphaBar.ClipsDescendants = true
	alphaBar.Parent = popup
	addCorner(alphaBar, UDim.new(0.5, 0))
	checkers[#checkers + 1] = newChecker(alphaBar, 24, 2)
	local alphaFill = Instance.new("Frame")
	alphaFill.Name = UUID.Static("AlphaFill")
	alphaFill.BorderSizePixel = 0
	alphaFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	alphaFill.Size = UDim2.fromScale(1, 1)
	alphaFill.Parent = alphaBar
	local alphaGradient = Instance.new("UIGradient")
	alphaGradient.Rotation = 0
	alphaGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	alphaGradient.Parent = alphaFill
	local alphaStroke = Instance.new("UIStroke")
	alphaStroke.Color = (theme and theme.StrokeColor) or Color3.fromRGB(255, 255, 255)
	alphaStroke.Transparency = math.max((theme and theme.StrokeTransparency) or 0.95, 0.85)
	alphaStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	alphaStroke.Parent = alphaBar
	barStrokes[#barStrokes + 1] = alphaStroke
	-- The knob lives beside the bar, not inside it: the bar clips its checker.
	local alphaKnob = Instance.new("Frame")
	alphaKnob.Name = UUID.Static("AlphaKnob")
	alphaKnob.BorderSizePixel = 0
	alphaKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	alphaKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	alphaKnob.Size = UDim2.fromOffset(14, 14)
	alphaKnob.Position = UDim2.fromOffset(SIDE_PAD + LEFT_WIDTH, 376)
	alphaKnob.Parent = popup
	local alphaKnobStroke = Instance.new("UIStroke")
	alphaKnobStroke.Transparency = 0
	alphaKnobStroke.Thickness = 2
	alphaKnobStroke.Color = Color3.fromRGB(255, 255, 255)
	alphaKnobStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	alphaKnobStroke.Parent = alphaKnob
	addCorner(alphaKnob, UDim.new(1, 0))

	-- =====================================================================
	--  Right column: hex + swatch dot, RGB fields, presets, recents
	-- =====================================================================
	local hexShell = Instance.new("Frame")
	hexShell.Name = UUID.Static("HexField")
	hexShell.BorderSizePixel = 0
	hexShell.BackgroundTransparency = 1
	hexShell.Size = UDim2.fromOffset(RIGHT_WIDTH, 40)
	hexShell.Position = UDim2.fromOffset(RIGHT_X, 62)
	hexShell.ClipsDescendants = true
	hexShell.Parent = popup
	addCorner(hexShell, UDim.new(0.5, 0))
	local hexStroke = Instance.new("UIStroke")
	hexStroke.Name = UUID.Static("HexStroke")
	hexStroke.Color = (theme and theme.StrokeColor) or Color3.fromRGB(255, 255, 255)
	hexStroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	hexStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	hexStroke.Parent = hexShell
	fieldStrokes[#fieldStrokes + 1] = hexStroke
	local hexDot = Instance.new("Frame")
	hexDot.Name = UUID.Static("HexDot")
	hexDot.BorderSizePixel = 0
	hexDot.BackgroundTransparency = 1
	hexDot.Size = UDim2.fromOffset(22, 22)
	hexDot.Position = UDim2.fromOffset(10, 9)
	hexDot.ClipsDescendants = true
	hexDot.Parent = hexShell
	addCorner(hexDot, UDim.new(1, 0))
	checkers[#checkers + 1] = newChecker(hexDot, 5, 5)
	local hexFill = Instance.new("Frame")
	hexFill.Name = UUID.Static("HexFill")
	hexFill.BorderSizePixel = 0
	hexFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	hexFill.Size = UDim2.fromScale(1, 1)
	hexFill.Parent = hexDot
	local hexInput = Instance.new("TextBox")
	hexInput.Name = UUID.Static("HexInput")
	hexInput.BorderSizePixel = 0
	hexInput.BackgroundTransparency = 1
	hexInput.TextXAlignment = Enum.TextXAlignment.Left
	hexInput.TextSize = 13
	hexInput.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	hexInput.TextColor3 = (theme and theme.PopupTextColor)
	hexInput.TextTransparency = 0.15
	hexInput.ClearTextOnFocus = false
	hexInput.ClipsDescendants = true
	hexInput.Size = UDim2.new(1, -76, 1, 0)
	hexInput.Position = UDim2.fromOffset(40, 0)
	hexInput.Text = "#FFFFFF"
	hexInput.Parent = hexShell
	texts[#texts + 1] = hexInput
	local hexTag = Instance.new("TextLabel")
	hexTag.Name = UUID.Static("HexTag")
	hexTag.BorderSizePixel = 0
	hexTag.BackgroundTransparency = 1
	hexTag.AnchorPoint = Vector2.new(1, 0.5)
	hexTag.Position = UDim2.new(1, -10, 0.5, 0)
	hexTag.Size = UDim2.fromOffset(26, 14)
	hexTag.TextSize = 9
	hexTag.FontFace = Constants.Font(Enum.FontWeight.Bold)
	hexTag.TextColor3 = (theme and theme.PopupTextColor)
	hexTag.TextTransparency = 0.55
	hexTag.Text = "HEX"
	hexTag.Parent = hexShell
	texts[#texts + 1] = hexTag

	local fieldWidth = 46
	local channelGap = 7
	local channels = { "R", "G", "B" }
	local channelBoxes = {}
	for i, channel in ipairs(channels) do
		local x = RIGHT_X + (i - 1) * (fieldWidth + channelGap)
		local caption = Instance.new("TextLabel")
		caption.Name = UUID.Static("ChannelLabel")
		caption.BorderSizePixel = 0
		caption.BackgroundTransparency = 1
		caption.TextSize = 10
		caption.FontFace = Constants.Font(Enum.FontWeight.Medium)
		caption.TextColor3 = (theme and theme.PopupTextColor)
		caption.TextTransparency = 0.5
		caption.Text = channel
		caption.Size = UDim2.fromOffset(fieldWidth, 12)
		caption.Position = UDim2.fromOffset(x, 118)
		caption.Parent = popup
		texts[#texts + 1] = caption
		local box = Instance.new("TextBox")
		box.Name = UUID.Static("ChannelField")
		box.BorderSizePixel = 0
		box.BackgroundTransparency = 1
		box.TextXAlignment = Enum.TextXAlignment.Center
		box.TextSize = 12
		box.FontFace = Constants.Font(Enum.FontWeight.Medium)
		box.TextColor3 = (theme and theme.PopupTextColor)
		box.TextTransparency = 0.15
		box.ClearTextOnFocus = false
		box.ClipsDescendants = true
		box.Size = UDim2.fromOffset(fieldWidth, 28)
		box.Position = UDim2.fromOffset(x, 134)
		box.Text = "255"
		box.Parent = popup
		texts[#texts + 1] = box
		addCorner(box, UDim.new(0.5, 0))
		local stroke = Instance.new("UIStroke")
		stroke.Color = (theme and theme.StrokeColor) or Color3.fromRGB(255, 255, 255)
		stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = box
		fieldStrokes[#fieldStrokes + 1] = stroke
		channelBoxes[channel] = { Box = box, Stroke = stroke }
	end

	newCaption("Presets", RIGHT_X, 190, RIGHT_WIDTH)
	local presetsGrid = Instance.new("Frame")
	presetsGrid.Name = UUID.Static("PresetsGrid")
	presetsGrid.BorderSizePixel = 0
	presetsGrid.BackgroundTransparency = 1
	presetsGrid.Size = UDim2.fromOffset(RIGHT_WIDTH, 62)
	presetsGrid.Position = UDim2.fromOffset(RIGHT_X, 206)
	presetsGrid.Parent = popup
	local presetsLayout = Instance.new("UIGridLayout")
	presetsLayout.CellSize = UDim2.fromOffset(28, 28)
	presetsLayout.CellPadding = UDim2.fromOffset(6, 6)
	presetsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	presetsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	presetsLayout.Parent = presetsGrid

	newCaption("Recent", RIGHT_X, 282, RIGHT_WIDTH)
	local recentGrid = Instance.new("Frame")
	recentGrid.Name = UUID.Static("RecentGrid")
	recentGrid.BorderSizePixel = 0
	recentGrid.BackgroundTransparency = 1
	recentGrid.Size = UDim2.fromOffset(RIGHT_WIDTH, 62)
	recentGrid.Position = UDim2.fromOffset(RIGHT_X, 298)
	recentGrid.Parent = popup
	local recentLayout = Instance.new("UIGridLayout")
	recentLayout.CellSize = UDim2.fromOffset(28, 28)
	recentLayout.CellPadding = UDim2.fromOffset(6, 6)
	recentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	recentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	recentLayout.Parent = recentGrid

	-- =====================================================================
	--  Footer: original -> new pair, cancel + confirm
	-- =====================================================================
	local interactions = Instance.new("Frame")
	interactions.Name = UUID.Static("Interactions")
	interactions.BorderSizePixel = 0
	interactions.BackgroundColor3 = (theme and theme.PopupShadowColor) or Color3.fromRGB(15, 15, 16)
	interactions.BackgroundTransparency = 0.8
	interactions.Size = UDim2.fromOffset(POPUP_WIDTH, FOOTER_HEIGHT)
	interactions.Position = UDim2.fromOffset(0, FOOTER_TOP)
	interactions.Parent = popup
	local interactionsCorner = Instance.new("UICorner")
	interactionsCorner.BottomLeftRadius = UDim.new(0, CORNER_SHELL)
	interactionsCorner.BottomRightRadius = UDim.new(0, CORNER_SHELL)
	interactionsCorner.TopLeftRadius = UDim.new(0, 0)
	interactionsCorner.TopRightRadius = UDim.new(0, 0)
	interactionsCorner.Parent = interactions

	local function newWell(name, x)
		local well = Instance.new("Frame")
		well.Name = UUID.Static(name)
		well.BorderSizePixel = 0
		well.BackgroundTransparency = 1
		well.Size = UDim2.fromOffset(22, 22)
		well.Position = UDim2.fromOffset(x, 16)
		well.ClipsDescendants = true
		well.Parent = interactions
		addCorner(well, UDim.new(1, 0))
		checkers[#checkers + 1] = newChecker(well, 5, 5)
		local fill = Instance.new("Frame")
		fill.Name = UUID.Static("WellFill")
		fill.BorderSizePixel = 0
		fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		fill.Size = UDim2.fromScale(1, 1)
		fill.Parent = well
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Transparency = 0.7
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = well
		return fill
	end

	local oldFill = newWell("OldWell", 16)
	local arrow = Instance.new("ImageLabel")
	arrow.Name = UUID.Static("WellArrow")
	arrow.BorderSizePixel = 0
	arrow.BackgroundTransparency = 1
	arrow.Image = Icons["arrow-right"] or "rbxassetid://113692007244654"
	arrow.ImageColor3 = (theme and theme.PopupTextColor)
	arrow.ImageTransparency = 0.55
	arrow.Size = UDim2.fromOffset(14, 14)
	arrow.Position = UDim2.fromOffset(42, 20)
	arrow.Parent = interactions
	texts[#texts + 1] = arrow
	local newFill = newWell("NewWell", 60)

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Name = UUID.Static("Cancel")
	cancelBtn.BorderSizePixel = 0
	cancelBtn.TextTransparency = 0.5
	cancelBtn.TextSize = 13
	cancelBtn.AutoButtonColor = false
	cancelBtn.TextColor3 = (theme and theme.PopupTextColor)
	cancelBtn.BackgroundColor3 = (theme and theme.PopupNeutralColor) or Color3.fromRGB(46, 46, 46)
	cancelBtn.BackgroundTransparency = 0.5
	cancelBtn.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	cancelBtn.Size = UDim2.fromOffset(96, 34)
	cancelBtn.Position = UDim2.fromOffset(POPUP_WIDTH - SIDE_PAD - 108 - 8 - 96, 10)
	cancelBtn.Text = "Cancel"
	cancelBtn.Parent = interactions
	addCorner(cancelBtn, UDim.new(0, CORNER_CARD))
	local cancelShadow = Instance.new("UIShadow")
	cancelShadow.BlurRadius = UDim.new(0, 20)
	cancelShadow.Color = (theme and theme.PopupNeutralColor) or Color3.fromRGB(0, 0, 0)
	cancelShadow.Transparency = 1
	cancelShadow.Parent = cancelBtn
	texts[#texts + 1] = cancelBtn

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Name = UUID.Static("Confirm")
	confirmBtn.BorderSizePixel = 0
	confirmBtn.TextTransparency = 0.2
	confirmBtn.TextSize = 13
	confirmBtn.AutoButtonColor = false
	confirmBtn.TextColor3 = (theme and theme.PopupTextColor)
	confirmBtn.BackgroundColor3 = (theme and theme.PrimaryColor) or Color3.fromRGB(14, 45, 178)
	confirmBtn.FontFace = Constants.Font(Enum.FontWeight.Bold)
	confirmBtn.Size = UDim2.fromOffset(108, 34)
	confirmBtn.Position = UDim2.fromOffset(POPUP_WIDTH - SIDE_PAD - 108, 10)
	confirmBtn.Text = "Confirm"
	confirmBtn.Parent = interactions
	addCorner(confirmBtn, UDim.new(0, CORNER_CARD))
	local confirmShadow = Instance.new("UIShadow")
	confirmShadow.BlurRadius = UDim.new(0, 20)
	confirmShadow.Color = (theme and theme.PrimaryColor) or Color3.fromRGB(13, 44, 177)
	confirmShadow.Transparency = 1
	confirmShadow.Parent = confirmBtn
	texts[#texts + 1] = confirmBtn

	for _, tiles in ipairs(checkers) do
		stampChecker(tiles, theme)
	end

	-- =====================================================================
	--  State + shared refreshers
	-- =====================================================================
	self.Popup = popup
	self.Shadow = shadow
	self.Header = header
	self.HeaderTile = headTile
	self.HeaderGlyph = headGlyph
	self._shellGradient = shellGradient
	self._scale = scale
	self.ColorSquare = colorSquare
	self.SatOverlay = satOverlay
	self.ValOverlay = valOverlay
	self.Target = target
	self.HueBar = hueBar
	self.HueKnob = hueKnob
	self.AlphaBar = alphaBar
	self.AlphaKnob = alphaKnob
	self.AlphaFill = alphaFill
	self.HexShell = hexShell
	self.HexInput = hexInput
	self.HexFill = hexFill
	self.ChannelBoxes = channelBoxes
	self.PresetsGrid = presetsGrid
	self.RecentGrid = recentGrid
	self.OldFill = oldFill
	self.NewFill = newFill
	self.Interactions = interactions
	self.ConfirmBtn = confirmBtn
	self.ConfirmShadow = confirmShadow
	self.CancelBtn = cancelBtn
	self.CancelShadow = cancelShadow
	self.CloseBtn = closeBtn
	self._texts = texts
	self._fieldStrokes = fieldStrokes
	self._barStrokes = barStrokes
	self._checkers = checkers
	self._cleanupCallback = cleanupCallback

	self.OnConfirm = function() end
	self.OnCancel = function() end
	self.IsOpen = false
	self._isOpen = false
	self._resolved = false
	self._hideTimer = nil
	self._outsideConn = nil
	self._currentColor = Color3.fromRGB(255, 255, 255)
	self._oldColor = Color3.fromRGB(255, 255, 255)
	self._alpha = ALPHA_MAX
	self._oldAlpha = ALPHA_MAX
	self._hue = 0
	self._sat = 0
	self._val = 1

	local function refreshVisuals()
		local h, s, v = self._hue, self._sat, self._val
		local hueColor = Color3.fromHSV(h, 1, 1)
		local color = Color3.fromHSV(h, s, v)
		self.SatOverlay.BackgroundColor3 = hueColor
		self.HueKnob.BackgroundColor3 = hueColor
		self.HueKnob.Position = UDim2.fromScale(h, 0.5)
		self.Target.BackgroundColor3 = color
		self.Target.Position = UDim2.fromScale(s, 1 - v)
		self.AlphaFill.BackgroundColor3 = color
		self.AlphaKnob.BackgroundColor3 = color
		self.AlphaKnob.Position = UDim2.fromOffset(SIDE_PAD + (self._alpha / ALPHA_MAX) * LEFT_WIDTH, 376)
		self.HexFill.BackgroundColor3 = color
		self.HexFill.BackgroundTransparency = 1 - self._alpha / ALPHA_MAX
		self.NewFill.BackgroundColor3 = color
		self.NewFill.BackgroundTransparency = 1 - self._alpha / ALPHA_MAX
		self.OldFill.BackgroundColor3 = self._oldColor
		self.OldFill.BackgroundTransparency = 1 - self._oldAlpha / ALPHA_MAX
		hueValue.Text = string.format("%d°", math.floor(h * 360 + 0.5))
		alphaValue.Text = string.format("%d%%", math.floor(self._alpha / ALPHA_MAX * 100 + 0.5))
	end

	local function refreshInputs()
		local color = Color3.fromHSV(self._hue, self._sat, self._val)
		local r = math.floor(color.R * 255 + 0.5)
		local g = math.floor(color.G * 255 + 0.5)
		local b = math.floor(color.B * 255 + 0.5)
		channelBoxes.R.Box.Text = tostring(r)
		channelBoxes.G.Box.Text = tostring(g)
		channelBoxes.B.Box.Text = tostring(b)
		hexInput.Text = formatHex(color)
	end

	local function refreshAll()
		refreshVisuals()
		refreshInputs()
	end

	self._setColorAndUpdate = function(me, color)
		me._currentColor = color
		me._hue, me._sat, me._val = color:ToHSV()
		refreshAll()
	end

	-- Keep the dragged HSV verbatim (not ToHSV of the rebuilt colour) so the handles never snap at the s/v/h boundaries.
	self._setHSVAndUpdate = function(me, h, s, v)
		me._hue = clamp(h, 0, 1)
		me._sat = clamp(s, 0, 1)
		me._val = clamp(v, 0, 1)
		me._currentColor = Color3.fromHSV(me._hue, me._sat, me._val)
		refreshAll()
	end

	self._setAlphaAndUpdate = function(me, alpha)
		me._alpha = clamp(alpha, 0, ALPHA_MAX)
		refreshVisuals()
	end

	local function newSwatch(parentFrame, color, layoutOrder)
		local chip = Instance.new("TextButton")
		chip.Name = UUID.Generate("Swatch")
		chip.BorderSizePixel = 0
		chip.AutoButtonColor = false
		chip.Text = ""
		chip.BackgroundColor3 = color
		chip.LayoutOrder = layoutOrder
		chip.Parent = parentFrame
		addCorner(chip, UDim.new(1, 0))
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Transparency = 0.75
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = chip
		local chipScale = Instance.new("UIScale")
		chipScale.Parent = chip
		chip.MouseButton1Click:Connect(function()
			self:_setColorAndUpdate(color)
		end)
		chip.MouseButton1Down:Connect(function()
			Tween.Play(chipScale, "PressIn", { Scale = 0.9 })
		end)
		chip.MouseButton1Up:Connect(function()
			Tween.Play(chipScale, "PressOut", { Scale = 1 })
		end)
		chip.MouseLeave:Connect(function()
			Tween.Play(chipScale, "PressOut", { Scale = 1 })
		end)
		return chip
	end

	self._rebuildRecent = function(me)
		for _, child in ipairs(me.RecentGrid:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		for i, color in ipairs(RECENT) do
			newSwatch(me.RecentGrid, color, i)
		end
	end

	for i, color in ipairs(PRESETS) do
		newSwatch(presetsGrid, color, i)
	end

	self.SetContent = function(me, contentSettings)
		contentSettings = contentSettings or {}
		me.OnConfirm = contentSettings.OnConfirm or function() end
		me.OnCancel = contentSettings.OnCancel or function() end
		me.Header.Text = contentSettings.Title or "Color Picker"
		local color = contentSettings.CurrentColor or contentSettings.Default
		if typeof(color) ~= "Color3" then
			color = Color3.fromRGB(255, 255, 255)
		end
		me._oldColor = color
		me._oldAlpha = clamp(contentSettings.CurrentAlpha or contentSettings.Alpha or ALPHA_MAX, 0, ALPHA_MAX)
		me._alpha = me._oldAlpha
		me._resolved = false
		me:_setColorAndUpdate(color)
		me:_rebuildRecent()
	end

	-- Recolor in place without rebuilding so an open or cached picker follows a live theme switch.
	self.ApplyTheme = function(me, newTheme)
		if not me.Popup then
			return
		end
		newTheme = ThemeManager.GetTheme(newTheme)
		me._theme = newTheme
		me.Popup.BackgroundColor3 = newTheme.PopupBackgroundColor or me.Popup.BackgroundColor3
		me.Popup.BackgroundTransparency = newTheme.PopupBackgroundTransparency or 0.07
		if me.Shadow then
			me.Shadow.Color = newTheme.PopupShadowColor or me.Shadow.Color
		end
		if me._shellGradient then
			stampShellGradient(me._shellGradient, newTheme)
		end
		if me.HeaderTile and me.HeaderGlyph then
			stampHeaderTile(me.HeaderTile, me.HeaderGlyph, newTheme)
		end
		for _, item in ipairs(me._texts) do
			if item:IsA("ImageLabel") then
				item.ImageColor3 = newTheme.PopupTextColor or item.ImageColor3
			else
				item.TextColor3 = newTheme.PopupTextColor or item.TextColor3
			end
		end
		for _, stroke in ipairs(me._fieldStrokes) do
			stroke.Color = newTheme.StrokeColor or stroke.Color
			stroke.Transparency = newTheme.StrokeTransparency or 0.95
		end
		for _, stroke in ipairs(me._barStrokes) do
			stroke.Color = newTheme.StrokeColor or stroke.Color
			stroke.Transparency = math.max(newTheme.StrokeTransparency or 0.95, 0.85)
		end
		for _, tiles in ipairs(me._checkers) do
			stampChecker(tiles, newTheme)
		end
		me.Interactions.BackgroundColor3 = newTheme.PopupShadowColor or me.Interactions.BackgroundColor3
		me.ConfirmBtn.BackgroundColor3 = newTheme.PrimaryColor or me.ConfirmBtn.BackgroundColor3
		me.ConfirmShadow.Color = newTheme.PrimaryColor or me.ConfirmShadow.Color
		me.CancelBtn.BackgroundColor3 = newTheme.PopupNeutralColor or me.CancelBtn.BackgroundColor3
		me.CancelShadow.Color = newTheme.PopupNeutralColor or me.CancelShadow.Color
	end

	local function computeFit()
		local area = parent.AbsoluteSize
		if area.X <= 0 or area.Y <= 0 then
			return 1
		end
		return clamp(math.min((area.X - 24) / POPUP_WIDTH, (area.Y - 24) / POPUP_HEIGHT), 0.35, 1)
	end

	self.Open = function(me)
		if not me.Popup then
			return
		end
		if me._hideTimer then
			task.cancel(me._hideTimer)
			me._hideTimer = nil
		end
		me.IsOpen = true
		me._isOpen = true
		me._resolved = false
		me:_rebuildRecent()
		me:_setColorAndUpdate(me._currentColor)
		me._fit = computeFit()
		me._scale.Scale = me._fit * 0.94
		me.Popup.Visible = true
		me.Popup.GroupTransparency = 1
		Tween.Play(me.Popup, "Fast", { GroupTransparency = 0 })
		Tween.Play(me.Shadow, "Fast", { Transparency = 0.5 })
		Tween.Play(me._scale, "Fast", { Scale = me._fit })
		me:_connectOutsideClick()
	end

	-- Connected only while the popup is open: armed in Open(), dropped in Close/Destroy.
	self._connectOutsideClick = function(me)
		if me._outsideConn then
			return
		end
		me._outsideConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			local inputType = input.UserInputType
			if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
				return
			end
			if not me.IsOpen or not me.Popup or not me.Popup.Visible then
				return
			end
			local p = input.Position
			-- Inside if the point hits the popup's rect or any descendant, so overhanging content isn't misread as outside.
			local pos = me.Popup.AbsolutePosition
			local size = me.Popup.AbsoluteSize
			local inside = p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
			if not inside then
				local playerGui = me.Popup:FindFirstAncestorOfClass("PlayerGui")
				if playerGui then
					for _, obj in ipairs(playerGui:GetGuiObjectsAtPosition(p.X, p.Y)) do
						if obj == me.Popup or obj:IsDescendantOf(me.Popup) then
							inside = true
							break
						end
					end
				end
			end
			if not inside then
				-- Outside is a dismissal: keep the colour the popup opened with.
				me:_Cancel()
			end
		end)
	end

	self._disconnectOutsideClick = function(me)
		if me._outsideConn then
			me._outsideConn:Disconnect()
			me._outsideConn = nil
		end
	end

	self.Close = function(me)
		if not me.Popup or not me.IsOpen then
			return
		end
		me.IsOpen = false
		me._isOpen = false
		-- Disarm the click-outside listener immediately on close.
		me:_disconnectOutsideClick()
		if me._hideTimer then
			task.cancel(me._hideTimer)
			me._hideTimer = nil
		end
		local fit = me._fit or 1
		Tween.Play(me.Popup, "Fast", { GroupTransparency = 1 })
		Tween.Play(me.Shadow, "Fast", { Transparency = 1 })
		Tween.Play(me._scale, "Fast", { Scale = fit * 0.94 })
		me._hideTimer = task.delay(0.35, function()
			if not me.IsOpen and me.Popup then
				me.Popup.Visible = false
			end
			me._hideTimer = nil
		end)
	end

	self._Confirm = function(me)
		if me._resolved then
			return
		end
		me._resolved = true
		rememberColor(me._currentColor)
		me:Close()
		me.OnConfirm(me._currentColor, math.floor(me._alpha + 0.5))
	end

	self._Cancel = function(me)
		if me._resolved then
			return
		end
		me._resolved = true
		me:Close()
		me.OnCancel()
	end

	-- Hide without firing callbacks (used by Window when another popup opens)
	self.Hide = function(me)
		me:Close()
	end

	self.Destroy = function(me)
		if me._dragChangedConnection then
			me._dragChangedConnection:Disconnect()
			me._dragChangedConnection = nil
		end
		if me._dragEndedConnection then
			me._dragEndedConnection:Disconnect()
			me._dragEndedConnection = nil
		end
		me:_disconnectOutsideClick()
		if me._hideTimer then
			task.cancel(me._hideTimer)
			me._hideTimer = nil
		end
		if me.Popup then
			me.Popup:Destroy()
			me.Popup = nil
		end
		if me._cleanupCallback then
			me._cleanupCallback()
			me._cleanupCallback = nil
		end
	end

	-- =====================================================================
	--  Interactions
	-- =====================================================================
	closeBtn.MouseButton1Click:Connect(function()
		self:_Cancel()
	end)
	closeBtn.MouseEnter:Connect(function()
		Tween.Play(closeBtn, "Fast", { BackgroundTransparency = 0.86 })
		Tween.Play(closeIcon, "Fast", { ImageTransparency = 0 })
	end)
	closeBtn.MouseLeave:Connect(function()
		Tween.Play(closeBtn, "Fast", { BackgroundTransparency = 0.92 })
		Tween.Play(closeIcon, "Fast", { ImageTransparency = 0.4 })
	end)

	confirmBtn.MouseButton1Click:Connect(function()
		self:_Confirm()
	end)
	cancelBtn.MouseButton1Click:Connect(function()
		self:_Cancel()
	end)
	confirmBtn.MouseEnter:Connect(function()
		Tween.Play(confirmShadow, "Fast", { BlurRadius = UDim.new(0, 50), Transparency = 0 })
	end)
	confirmBtn.MouseLeave:Connect(function()
		Tween.Play(confirmShadow, "Fast", { BlurRadius = UDim.new(0, 20), Transparency = 1 })
	end)
	cancelBtn.MouseEnter:Connect(function()
		Tween.Play(cancelBtn, "Fast", { TextTransparency = 0.2 })
	end)
	cancelBtn.MouseLeave:Connect(function()
		Tween.Play(cancelBtn, "Fast", { TextTransparency = 0.5 })
	end)

	local function setFromSquarePosition(screenPosition)
		local size = colorSquare.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end
		local squarePos = colorSquare.AbsolutePosition
		local x = clamp((screenPosition.X - squarePos.X) / size.X, 0, 1)
		local y = clamp((screenPosition.Y - squarePos.Y) / size.Y, 0, 1)
		-- Keep the existing hue; saturation = x, value = 1 - y, set via the HSV-preserving path so the handle never snaps.
		self:_setHSVAndUpdate(self._hue, x, 1 - y)
	end
	local function setFromHuePosition(screenPosition)
		local size = hueBar.AbsoluteSize
		if size.X <= 0 then
			return
		end
		local barPos = hueBar.AbsolutePosition
		local h = clamp((screenPosition.X - barPos.X) / size.X, 0, 1)
		self:_setHSVAndUpdate(h, self._sat, self._val)
	end
	local function setFromAlphaPosition(screenPosition)
		local size = alphaBar.AbsoluteSize
		if size.X <= 0 then
			return
		end
		local barPos = alphaBar.AbsolutePosition
		local t = clamp((screenPosition.X - barPos.X) / size.X, 0, 1)
		self:_setAlphaAndUpdate(t * ALPHA_MAX)
	end
	-- Click-and-drag anywhere on the square/bars: UIDragDetector only drags its own instance, so the whole surface is tracked manually.
	local squareDragging = false
	local hueDragging = false
	local alphaDragging = false
	colorSquare.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			squareDragging = true
			setFromSquarePosition(input.Position)
		end
	end)
	hueBar.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			hueDragging = true
			setFromHuePosition(input.Position)
		end
	end)
	alphaBar.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			alphaDragging = true
			setFromAlphaPosition(input.Position)
		end
	end)
	-- Follow the drag globally so it survives the cursor leaving the square/bars; disconnected in Destroy().
	self._dragChangedConnection = UserInputService.InputChanged:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if squareDragging then
				setFromSquarePosition(input.Position)
			elseif hueDragging then
				setFromHuePosition(input.Position)
			elseif alphaDragging then
				setFromAlphaPosition(input.Position)
			end
		end
	end)
	self._dragEndedConnection = UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			squareDragging = false
			hueDragging = false
			alphaDragging = false
		end
	end)

	local function setStrokeBright(stroke, bright)
		-- Read the live theme (ApplyTheme keeps self._theme current) so hover/focus after a switch doesn't write old colours back.
		local liveTheme = ThemeManager.GetTheme(self._theme)
		local baseTrans = liveTheme.StrokeTransparency or 0.95
		local baseColor = liveTheme.StrokeColor or Color3.fromRGB(255, 255, 255)
		local targetTrans = if bright then 0.3 else baseTrans
		local targetColor = if bright then (liveTheme.PrimaryColor or baseColor) else baseColor
		Tween.Play(stroke, "Fast", { Transparency = targetTrans, Color = targetColor })
	end

	hexInput.Focused:Connect(function()
		setStrokeBright(hexStroke, true)
	end)
	hexInput.FocusLost:Connect(function()
		local parsed, parsedAlpha = parseHex(hexInput.Text)
		if parsed then
			self:_setColorAndUpdate(parsed)
			if parsedAlpha then
				self:_setAlphaAndUpdate(parsedAlpha)
			end
		end
		-- Always rewrite canonical state: invalid text snaps back, valid text normalizes.
		refreshInputs()
		setStrokeBright(hexStroke, false)
	end)
	hexInput.MouseEnter:Connect(function()
		setStrokeBright(hexStroke, true)
	end)
	hexInput.MouseLeave:Connect(function()
		if not hexInput:IsFocused() then
			setStrokeBright(hexStroke, false)
		end
	end)

	for channel, info in pairs(channelBoxes) do
		info.Box.FocusLost:Connect(function()
			local value = tonumber(info.Box.Text)
			if value then
				local color = Color3.fromHSV(self._hue, self._sat, self._val)
				local r = math.floor(color.R * 255 + 0.5)
				local g = math.floor(color.G * 255 + 0.5)
				local b = math.floor(color.B * 255 + 0.5)
				value = clamp(math.floor(value + 0.5), 0, 255)
				if channel == "R" then
					r = value
				elseif channel == "G" then
					g = value
				else
					b = value
				end
				self:_setColorAndUpdate(Color3.fromRGB(r, g, b))
			end
			refreshInputs()
		end)
		info.Box.Focused:Connect(function()
			setStrokeBright(info.Stroke, true)
		end)
		info.Box.FocusLost:Connect(function()
			setStrokeBright(info.Stroke, false)
		end)
		info.Box.MouseEnter:Connect(function()
			setStrokeBright(info.Stroke, true)
		end)
		info.Box.MouseLeave:Connect(function()
			if not info.Box:IsFocused() then
				setStrokeBright(info.Stroke, false)
			end
		end)
	end

	return self
end

return ColorPickerPopUp
