--[[
	Aetheris/Popups/Changelog.luau

	Startup changelog popup: a rim-lit shell over a scrolling column of
	gradient cards (falloff fill, faint top-bright rim, accent tint tile,
	brighten on hover) that cascade in when the popup opens. The design follows
	the card grammar in design-notes.md (Novoline reference); the code stays on
	Aetheris idioms - ThemeManager binds, Locale stamps, Tween registry.
	Version tracking lives in the window - this module only builds and shows
	the entries it is handed. Entries take optional Icon (Icons key) and Tint
	(blue/purple/teal/orange/red/yellow).
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local Sound = require("../Utils/Sound")
local Constants = require("../Constants")
local Locale = require("../Utils/Locale")
local Icons = require("../Assets/Icons")
local UUID = require("../Utils/UUID")
local UserInputService = game:GetService("UserInputService")

local Changelog = {}
Changelog.__index = Changelog

-- Motion (design-notes.md 4): one settle for the cascade, one lift for
-- hovers, one enter/exit for the shell. Tween.Play takes an explicit
-- TweenInfo, so these stay local instead of joining the preset registry.
local SETTLE = TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local LIFT = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local ENTER = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local EXIT = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local ICON_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ICON_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Cascade: 35 ms per card capped at 0.3 s (plus a short beat so the shell
-- lands first); scroll edges fade over 36 px.
local CASCADE_STEP = 0.035
local CASCADE_CAP = 0.3
local CASCADE_LEAD = 0.12
local EDGE_FADE_PX = 36

local CORNER_SHELL = 12
local CORNER_CARD = 10
local TILE = 30
local HIDDEN_SCALE = 0.96
local LIFT_BOOST = 0.1
local SHADOW_OPEN = 0.45

-- Rim ramps: the top edge catches the most light (design-notes.md 2).
local SHELL_RIM = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.84),
	NumberSequenceKeypoint.new(0.5, 0.92),
	NumberSequenceKeypoint.new(1, 0.78),
})
local CARD_RIM = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.86),
	NumberSequenceKeypoint.new(0.4, 0.96),
	NumberSequenceKeypoint.new(1, 0.97),
})

local FALLBACK_POPUP = Color3.fromRGB(15, 15, 16)
local FALLBACK_NEUTRAL = Color3.fromRGB(46, 46, 46)

local CLOSE_ICON = Icons["circle-x"] or "rbxassetid://76821953846248"
local DEFAULT_ICON = Icons["sparkles"] or CLOSE_ICON

-- Accent tints (design-notes.md 5): cards cycle them so a changelog reads
-- like a script grid; entry.Tint picks one by name instead.
local TINTS = {
	{ Name = "blue", Color = Color3.fromRGB(64, 186, 255) },
	{ Name = "purple", Color = Color3.fromRGB(168, 120, 255) },
	{ Name = "teal", Color = Color3.fromRGB(56, 224, 186) },
	{ Name = "orange", Color = Color3.fromRGB(255, 150, 50) },
	{ Name = "red", Color = Color3.fromRGB(255, 96, 96) },
	{ Name = "yellow", Color = Color3.fromRGB(245, 197, 66) },
}
local TINT_BY_NAME = {}
for _, tint in ipairs(TINTS) do
	TINT_BY_NAME[tint.Name] = tint.Color
end

local function isDark(color)
	return (color.R * 0.299 + color.G * 0.587 + color.B * 0.114) < 0.5
end

local function resolveTint(name, index)
	if type(name) == "string" then
		local found = TINT_BY_NAME[string.lower(name)]
		if found then
			return found
		end
	end
	return TINTS[((index - 1) % #TINTS) + 1].Color
end

-- Accent as readable text: keep the hue, cap saturation, force value on
-- dark grounds; darken on light ones (design-notes.md 5).
local function accentText(color, onDark)
	if onDark then
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, math.min(s, 0.75), math.max(v, 0.92))
	end
	return color:Lerp(Color3.new(0, 0, 0), 0.3)
end

-- Tile fills derive from the theme's card colour so they follow light and
-- dark themes instead of copying Novoline's fixed dark tints.
local function tileFill(tint, base)
	if isDark(base) then
		return base:Lerp(tint, 0.4):Lerp(Color3.new(0, 0, 0), 0.35)
	end
	return base:Lerp(tint, 0.3)
end

-- UIGradient.Color multiplies what it paints, so both ramps below are
-- multiplier pairs rather than literal colours (design-notes.md 10).
local function stampShellGradient(gradient, theme)
	local base = (theme and theme.PopupBackgroundColor) or FALLBACK_POPUP
	local top = if isDark(base) then 0.9 else 0.96
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(top, top, top)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
end

local function stampCardGradient(gradient, theme)
	local base = (theme and theme.PopupNeutralColor) or FALLBACK_NEUTRAL
	local bottom = if isDark(base) then 0.72 else 0.9
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(bottom, bottom, bottom)),
	})
end

local function restampTile(record, theme)
	local base = (theme and theme[record.baseSlot]) or FALLBACK_NEUTRAL
	local tint = record.tint or (theme and theme.AccentColor) or Color3.fromRGB(96, 165, 250)
	record.tile.BackgroundColor3 = tileFill(tint, base)
	record.glyph.ImageColor3 = accentText(tint, isDark(base))
end

-- Scroll edges melt into the shell: a CanvasGroup wrapper whose Rotation-90
-- gradient is rebuilt from CanvasPosition over a 36 px span.
local function attachScrollFade(scroll)
	local fade = Instance.new("CanvasGroup")
	fade.Name = UUID.Static("ScrollFade")
	fade.BorderSizePixel = 0
	fade.BackgroundTransparency = 1
	fade.Position = scroll.Position
	fade.Size = scroll.Size
	fade.ZIndex = scroll.ZIndex
	fade.Parent = scroll.Parent
	scroll.Position = UDim2.fromScale(0, 0)
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.Parent = fade

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Parent = fade

	local function sync()
		local view = scroll.AbsoluteWindowSize.Y
		local content = scroll.AbsoluteCanvasSize.Y
		if view <= 0 or content <= 0 then
			return
		end
		local top = scroll.CanvasPosition.Y
		local bottom = math.max(content - view - top, 0)
		local above = math.clamp(top / EDGE_FADE_PX, 0, 1)
		local below = math.clamp(bottom / EDGE_FADE_PX, 0, 1)
		local keys = {
			NumberSequenceKeypoint.new(0, if above > 0.5 then 1 else 0),
		}
		if above > 0.002 then
			keys[#keys + 1] = NumberSequenceKeypoint.new(math.min(above, 0.45), 0)
		end
		if below > 0.002 then
			keys[#keys + 1] = NumberSequenceKeypoint.new(math.max(1 - below, 0.55), 0)
		end
		keys[#keys + 1] = NumberSequenceKeypoint.new(1, if below > 0.5 then 1 else 0)
		gradient.Transparency = NumberSequence.new(keys)
	end
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(sync)
	scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(sync)
	scroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(sync)
	task.defer(sync)
end

function Changelog.new(parent, Settings)
	Settings = Settings or {}
	local theme = ThemeManager.GetTheme(Settings.Theme)
	local self = setmetatable({}, Changelog)

	self.IsOpen = false
	self.Version = Settings.Version or ""
	self.Entries = Settings.Entries or {}
	self._shellGradients = {}
	self._cardGradients = {}
	self._tiles = {}
	self._accentTexts = {}
	self._cards = {}
	self._revealToken = 0
	self._cardBase = (theme and theme.PopupNeutralColor) or FALLBACK_NEUTRAL
	self._popupTransparency = (theme and theme.PopupBackgroundTransparency) or 0.07

	local popup = Instance.new("CanvasGroup")
	popup.Name = UUID.Generate("ChangelogPopup")
	popup.BorderSizePixel = 0
	popup.GroupTransparency = 1
	popup.BackgroundColor3 = (theme and theme.PopupBackgroundColor) or FALLBACK_POPUP
	popup.BackgroundTransparency = self._popupTransparency
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Size = UDim2.new(0.6, 0, 0, 380)
	popup.Position = UDim2.fromScale(0.5, 0.5)
	popup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	popup.Visible = false
	popup.ZIndex = 12
	popup.Parent = parent

	local shellGradient = Instance.new("UIGradient")
	stampShellGradient(shellGradient, theme)
	shellGradient.Parent = popup
	self._shellGradients[1] = shellGradient

	local shadow = Instance.new("UIShadow")
	shadow.BlurRadius = UDim.new(0, 26)
	shadow.Offset = UDim2.fromOffset(0, 10)
	shadow.Transparency = 1
	shadow.Color = (theme and theme.NotificationShadowColor) or (theme and theme.PopupShadowColor)
	shadow.Parent = popup

	local rim = Instance.new("UIStroke")
	rim.Thickness = 1
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Color = (theme and theme.StrokeColor) or Color3.new(1, 1, 1)
	rim.Transparency = SHELL_RIM
	rim.Parent = popup

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CORNER_SHELL)
	corner.Parent = popup

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(360, 320)
	sizeConstraint.MaxSize = Vector2.new(560, 460)
	sizeConstraint.Parent = popup

	-- Header row: accent tile + title, close button opposite.
	local headTile = Instance.new("Frame")
	headTile.Name = UUID.Static("HeaderTile")
	headTile.BorderSizePixel = 0
	headTile.Size = UDim2.fromOffset(TILE, TILE)
	headTile.Position = UDim2.fromOffset(16, 14)
	headTile.ZIndex = 13
	headTile.Parent = popup
	local headTileCorner = Instance.new("UICorner")
	headTileCorner.CornerRadius = UDim.new(0, 10)
	headTileCorner.Parent = headTile
	local headGlyph = Instance.new("ImageLabel")
	headGlyph.Name = UUID.Static("HeaderGlyph")
	headGlyph.BorderSizePixel = 0
	headGlyph.BackgroundTransparency = 1
	headGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
	headGlyph.Position = UDim2.fromScale(0.5, 0.5)
	headGlyph.Size = UDim2.fromOffset(16, 16)
	headGlyph.Image = DEFAULT_ICON
	headGlyph.ZIndex = 14
	headGlyph.Parent = headTile
	self._tiles[#self._tiles + 1] = { tile = headTile, glyph = headGlyph, baseSlot = "PopupBackgroundColor" }

	local header = Instance.new("TextLabel")
	header.Name = UUID.Static("Header")
	header.BorderSizePixel = 0
	header.BackgroundTransparency = 1
	header.TextSize = 15
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextYAlignment = Enum.TextYAlignment.Center
	header.TextTransparency = 0.2
	header.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	header.TextColor3 = (theme and theme.PopupTextColor)
	header.Position = UDim2.fromOffset(56, 14)
	header.Size = UDim2.new(1, -110, 0, TILE)
	header.ZIndex = 13
	Locale.set(header, "Text", "Changelog")
	header.Parent = popup

	-- Version chip: only when the script writer actually stamped a version.
	if self.Version ~= "" then
		local chip = Instance.new("TextLabel")
		chip.Name = UUID.Static("VersionChip")
		chip.BorderSizePixel = 0
		chip.BackgroundColor3 = (theme and theme.AccentColor)
		chip.BackgroundTransparency = 0.85
		chip.Size = UDim2.fromOffset(0, 20)
		chip.AutomaticSize = Enum.AutomaticSize.X
		chip.TextSize = 11
		chip.FontFace = Constants.Font(Enum.FontWeight.Medium)
		chip.TextXAlignment = Enum.TextXAlignment.Left
		chip.TextYAlignment = Enum.TextYAlignment.Center
		chip.Position = UDim2.fromOffset(16, 52)
		chip.ZIndex = 13
		chip.Text = self.Version
		chip.TextColor3 = accentText(
			(theme and theme.AccentColor) or Color3.fromRGB(96, 165, 250),
			isDark((theme and theme.PopupBackgroundColor) or FALLBACK_POPUP)
		)
		chip.Parent = popup
		local chipCorner = Instance.new("UICorner")
		chipCorner.CornerRadius = UDim.new(1, 0)
		chipCorner.Parent = chip
		local chipPad = Instance.new("UIPadding")
		chipPad.PaddingLeft = UDim.new(0, 10)
		chipPad.PaddingRight = UDim.new(0, 10)
		chipPad.Parent = chip
		self._accentTexts[#self._accentTexts + 1] = chip
		ThemeManager.BindColor(chip, "BackgroundColor3", "AccentColor")
	end

	-- 28 px circle close with a 16 px glyph (design-notes.md 6).
	local closeBtn = Instance.new("ImageButton")
	closeBtn.Name = UUID.Static("Close")
	closeBtn.BorderSizePixel = 0
	closeBtn.BackgroundColor3 = Color3.new(1, 1, 1)
	closeBtn.BackgroundTransparency = 0.92
	closeBtn.AutoButtonColor = false
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.Position = UDim2.new(1, -10, 0, 15)
	closeBtn.ZIndex = 14
	closeBtn.Parent = popup
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeBtn
	local closeIcon = Instance.new("ImageLabel")
	closeIcon.Name = UUID.Static("CloseIcon")
	closeIcon.BorderSizePixel = 0
	closeIcon.BackgroundTransparency = 1
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.Position = UDim2.fromScale(0.5, 0.5)
	closeIcon.Size = UDim2.fromOffset(16, 16)
	closeIcon.Image = CLOSE_ICON
	closeIcon.ImageTransparency = 0.35
	closeIcon.ImageColor3 = (theme and theme.PopupTextColor)
	closeIcon.ZIndex = 15
	closeIcon.Parent = closeBtn

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = UUID.Static("Scroll")
	scroll.BorderSizePixel = 0
	scroll.BackgroundTransparency = 1
	scroll.Size = UDim2.new(1, -32, 1, -102)
	scroll.Position = UDim2.fromOffset(16, 86)
	scroll.ZIndex = 13
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = (theme and theme.AccentColor)
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = popup
	attachScrollFade(scroll)

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = scroll
	local scrollPad = Instance.new("UIPadding")
	scrollPad.PaddingBottom = UDim.new(0, 4)
	scrollPad.Parent = scroll

	for i, entry in ipairs(self.Entries) do
		if type(entry) == "table" then
			local title = type(entry.Title) == "string" and entry.Title or ""
			local description = type(entry.Description) == "string" and entry.Description or ""
			local tint = resolveTint(entry.Tint, i)
			local iconId = DEFAULT_ICON
			if type(entry.Icon) == "string" and Icons[entry.Icon] then
				iconId = Icons[entry.Icon]
			end

			-- CanvasGroup so one GroupTransparency tween reveals fill, rim and
			-- text together; the fill lives on the inner Frame so the gradient
			-- only paints the background.
			local card = Instance.new("CanvasGroup")
			card.Name = UUID.Generate("ChangeCard")
			card.BorderSizePixel = 0
			card.BackgroundTransparency = 1
			card.AutomaticSize = Enum.AutomaticSize.Y
			card.Size = UDim2.fromScale(1, 0)
			card.LayoutOrder = i
			card.ZIndex = 13
			card.GroupTransparency = 1
			card.Parent = scroll

			local cardScale = Instance.new("UIScale")
			cardScale.Scale = HIDDEN_SCALE
			cardScale.Parent = card

			local visual = Instance.new("Frame")
			visual.Name = UUID.Static("CardBody")
			visual.BorderSizePixel = 0
			visual.BackgroundColor3 = self._cardBase
			visual.BackgroundTransparency = 0
			visual.AutomaticSize = Enum.AutomaticSize.Y
			visual.Size = UDim2.fromScale(1, 0)
			visual.ZIndex = 2
			visual.Parent = card
			local visualCorner = Instance.new("UICorner")
			visualCorner.CornerRadius = UDim.new(0, CORNER_CARD)
			visualCorner.Parent = visual
			local cardGradient = Instance.new("UIGradient")
			stampCardGradient(cardGradient, theme)
			cardGradient.Parent = visual
			self._cardGradients[#self._cardGradients + 1] = cardGradient
			local cardRim = Instance.new("UIStroke")
			cardRim.Thickness = 1
			cardRim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			cardRim.Color = (theme and theme.StrokeColor) or Color3.new(1, 1, 1)
			cardRim.Transparency = CARD_RIM
			cardRim.Parent = visual
			local cardPad = Instance.new("UIPadding")
			cardPad.PaddingTop = UDim.new(0, 13)
			cardPad.PaddingBottom = UDim.new(0, 13)
			cardPad.PaddingLeft = UDim.new(0, 14)
			cardPad.PaddingRight = UDim.new(0, 14)
			cardPad.Parent = visual
			local cardLayout = Instance.new("UIListLayout")
			cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
			cardLayout.Padding = UDim.new(0, 5)
			cardLayout.Parent = visual

			local row = Instance.new("Frame")
			row.Name = UUID.Static("CardHead")
			row.BorderSizePixel = 0
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, TILE)
			row.LayoutOrder = 1
			row.Parent = visual
			local tile = Instance.new("Frame")
			tile.Name = UUID.Static("TintTile")
			tile.BorderSizePixel = 0
			tile.Size = UDim2.fromOffset(TILE, TILE)
			tile.Parent = row
			local tileCorner = Instance.new("UICorner")
			tileCorner.CornerRadius = UDim.new(0, 10)
			tileCorner.Parent = tile
			local glyph = Instance.new("ImageLabel")
			glyph.Name = UUID.Static("TintGlyph")
			glyph.BorderSizePixel = 0
			glyph.BackgroundTransparency = 1
			glyph.AnchorPoint = Vector2.new(0.5, 0.5)
			glyph.Position = UDim2.fromScale(0.5, 0.5)
			glyph.Size = UDim2.fromOffset(16, 16)
			glyph.Image = iconId
			glyph.Parent = tile
			self._tiles[#self._tiles + 1] = { tile = tile, glyph = glyph, tint = tint, baseSlot = "PopupNeutralColor" }

			local titleLabel = Instance.new("TextLabel")
			titleLabel.Name = UUID.Static("CardTitle")
			titleLabel.BorderSizePixel = 0
			titleLabel.BackgroundTransparency = 1
			titleLabel.Position = UDim2.fromOffset(40, 0)
			titleLabel.Size = UDim2.new(1, -40, 0, TILE)
			titleLabel.TextSize = 13
			titleLabel.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
			titleLabel.TextColor3 = (theme and theme.PopupTextColor)
			titleLabel.TextTransparency = 0.05
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.TextYAlignment = Enum.TextYAlignment.Center
			titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			titleLabel.Text = title
			titleLabel.Parent = row

			local descLabel = Instance.new("TextLabel")
			descLabel.Name = UUID.Static("CardDescription")
			descLabel.BorderSizePixel = 0
			descLabel.BackgroundTransparency = 1
			descLabel.AutomaticSize = Enum.AutomaticSize.Y
			descLabel.Size = UDim2.fromScale(1, 0)
			descLabel.TextSize = 12
			descLabel.FontFace = Constants.Font(Enum.FontWeight.Regular)
			descLabel.TextColor3 = (theme and theme.PopupTextColor)
			descLabel.TextTransparency = 0.45
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.TextYAlignment = Enum.TextYAlignment.Top
			descLabel.TextWrapped = true
			descLabel.RichText = true
			descLabel.LayoutOrder = 2
			descLabel.Text = description
			descLabel.Parent = visual

			-- Hover lifts the fill only; the gradient rides along, so the card
			-- brightens the same 5% a white lift wash would.
			visual.MouseEnter:Connect(function()
				Tween.Play(visual, LIFT, { BackgroundColor3 = self._cardBase:Lerp(Color3.new(1, 1, 1), LIFT_BOOST) })
			end)
			visual.MouseLeave:Connect(function()
				Tween.Play(visual, LIFT, { BackgroundColor3 = self._cardBase })
			end)

			ThemeManager.BindColor(visual, "BackgroundColor3", "PopupNeutralColor")
			ThemeManager.BindColor(cardRim, "Color", "StrokeColor")
			ThemeManager.BindColor(titleLabel, "TextColor3", "PopupTextColor")
			ThemeManager.BindColor(descLabel, "TextColor3", "PopupTextColor")

			self._cards[#self._cards + 1] = { Group = card, Scale = cardScale }
		end
	end

	closeBtn.MouseButton1Click:Connect(function()
		self:Close()
	end)
	closeBtn.MouseEnter:Connect(function()
		Tween.Play(closeBtn, ICON_IN, { BackgroundTransparency = 0.86 })
		Tween.Play(closeIcon, ICON_IN, { ImageTransparency = 0 })
	end)
	closeBtn.MouseLeave:Connect(function()
		Tween.Play(closeBtn, ICON_OUT, { BackgroundTransparency = 0.92 })
		Tween.Play(closeIcon, ICON_OUT, { ImageTransparency = 0.35 })
	end)

	self.Popup = popup
	self.Shadow = shadow
	self.Header = header
	self.Scroll = scroll
	self.CloseBtn = closeBtn

	-- Colour follows the theme through Bind; gradients, tiles and the accent
	-- text need the callback because they are derived, not theme slots.
	ThemeManager.BindColor(popup, "BackgroundColor3", "PopupBackgroundColor")
	ThemeManager.BindColor(rim, "Color", "StrokeColor")
	ThemeManager.BindColor(header, "TextColor3", "PopupTextColor")
	ThemeManager.BindColor(closeIcon, "ImageColor3", "PopupTextColor")
	ThemeManager.BindColor(scroll, "ScrollBarImageColor3", "AccentColor")
	ThemeManager.OnThemeApplied(function(applied)
		self._popupTransparency = applied.PopupBackgroundTransparency or 0.07
		self._cardBase = applied.PopupNeutralColor or FALLBACK_NEUTRAL
		if self.IsOpen then
			popup.BackgroundTransparency = self._popupTransparency
		end
		for _, gradient in ipairs(self._shellGradients) do
			stampShellGradient(gradient, applied)
		end
		for _, gradient in ipairs(self._cardGradients) do
			stampCardGradient(gradient, applied)
		end
		for _, record in ipairs(self._tiles) do
			restampTile(record, applied)
		end
		for _, label in ipairs(self._accentTexts) do
			label.TextColor3 = accentText(
				applied.AccentColor or Color3.fromRGB(96, 165, 250),
				isDark(applied.PopupBackgroundColor or FALLBACK_POPUP)
			)
		end
	end, popup)

	return self
end

-- Stagger the cards in: fade + settle per card, 35 ms apart, capped. The
-- token drops callbacks from a superseded open.
function Changelog:_cascade()
	local token = self._revealToken + 1
	self._revealToken = token
	for i, entry in ipairs(self._cards) do
		if entry.Group.Parent then
			entry.Group.GroupTransparency = 1
			entry.Scale.Scale = HIDDEN_SCALE
		end
		local delay = CASCADE_LEAD + math.min((i - 1) * CASCADE_STEP, CASCADE_CAP)
		task.delay(delay, function()
			if self._revealToken ~= token or not self.IsOpen or not entry.Group.Parent then
				return
			end
			Tween.Play(entry.Group, SETTLE, { GroupTransparency = 0 })
			Tween.Play(entry.Scale, SETTLE, { Scale = 1 })
		end)
	end
end

-- Connected only while the popup is open: armed in Open(), dropped in Close/Destroy.
function Changelog:_connectOutsideClick()
	if self._outsideConn then
		return
	end
	self._outsideConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		local inputType = input.UserInputType
		if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
			return
		end
		if not self.IsOpen or not self.Popup or not self.Popup.Visible then
			return
		end
		local p = input.Position
		local pos = self.Popup.AbsolutePosition
		local size = self.Popup.AbsoluteSize
		local inside = p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
		if not inside then
			self:Close()
		end
	end)
end

function Changelog:_disconnectOutsideClick()
	if self._outsideConn then
		self._outsideConn:Disconnect()
		self._outsideConn = nil
	end
end

function Changelog:Open()
	if self.IsOpen then
		return
	end
	self.IsOpen = true
	Sound.Play("Notification")
	local popup = self.Popup
	popup.Visible = true
	popup.GroupTransparency = 1
	popup.Position = UDim2.new(0.5, 0, 0.5, 8)
	self.Scroll.CanvasPosition = Vector2.zero
	self:_connectOutsideClick()
	self:_cascade()
	Tween.Play(popup, ENTER, {
		GroupTransparency = 0,
		BackgroundTransparency = self._popupTransparency,
		Position = UDim2.fromScale(0.5, 0.5),
	})
	Tween.Play(self.Shadow, ENTER, { Transparency = SHADOW_OPEN })
end

function Changelog:Close()
	if not self.IsOpen then
		return
	end
	self.IsOpen = false
	-- Disarm click-outside immediately so a click during the fade-out can't re-trigger it.
	self:_disconnectOutsideClick()
	Tween.Play(self.Popup, EXIT, {
		GroupTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 14),
	})
	Tween.Play(self.Shadow, EXIT, { Transparency = 1 })
	task.delay(0.55, function()
		if not self.IsOpen and self.Popup and self.Popup.Parent then
			self.Popup.Visible = false
			self.Popup.Position = UDim2.fromScale(0.5, 0.5)
		end
	end)
end

function Changelog:Destroy()
	self:_disconnectOutsideClick()
	if self.Popup then
		self.Popup:Destroy()
	end
end

return Changelog
