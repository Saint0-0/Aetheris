--[[
	Aetheris/Popups/Changelog.luau

	Startup changelog popup: a themed shell over a scrolling column of aurora
	cards that cascade in on open. Version tracking lives in the window, and
	entries take an optional Icon and Tint.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local Sound = require("../Utils/Sound")
local ScrollFade = require("../Utils/ScrollFade")
local Constants = require("../Constants")
local Locale = require("../Utils/Locale")
local Icons = require("../Assets/Icons")
local UUID = require("../Utils/UUID")
local UserInputService = game:GetService("UserInputService")

local Changelog = {}
Changelog.__index = Changelog

-- Cascade settle and hover lift; the shell uses the shared "Fast" fade.
local SETTLE = TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local LIFT = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local ICON_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ICON_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Per-card cascade step and cap, plus a lead so the shell lands first.
local CASCADE_STEP = 0.035
local CASCADE_CAP = 0.3
local CASCADE_LEAD = 0.12

local CORNER_SHELL = 12
local CORNER_CARD = 10
local TILE = 30
local LIFT_BOOST = 0.16
local SHADOW_OPEN = 0.45
-- How far the aurora corner pulls toward the entry tint.
local AURORA_TINT = 0.14

local FALLBACK_POPUP = Color3.fromRGB(15, 15, 16)
local FALLBACK_NEUTRAL = Color3.fromRGB(46, 46, 46)

local CLOSE_ICON = Icons["circle-x"] or "rbxassetid://76821953846248"
local DEFAULT_ICON = Icons["sparkles"] or CLOSE_ICON

-- Cards cycle these tints by index; entry.Tint selects one by name.
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

-- Accent as text: hue kept, saturation capped, value forced on dark grounds.
local function accentText(color, onDark)
	if onDark then
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, math.min(s, 0.75), math.max(v, 0.92))
	end
	return color:Lerp(Color3.new(0, 0, 0), 0.3)
end

-- Tile fills derive from the card colour so they follow the theme.
local function tileFill(tint, base)
	if isDark(base) then
		return base:Lerp(tint, 0.4):Lerp(Color3.new(0, 0, 0), 0.35)
	end
	return base:Lerp(tint, 0.3)
end

-- UIGradient.Color multiplies, so these ramps are multipliers, not colours.
local function stampShellGradient(gradient, theme)
	local base = (theme and theme.PopupBackgroundColor) or FALLBACK_POPUP
	local top = if isDark(base) then 0.9 else 0.96
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(top, top, top)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
end

-- One gradient carries the falloff and the tinted aurora corner at 35 degrees.
local function stampCardGradient(gradient, theme, tint)
	local base = (theme and theme.PopupNeutralColor) or FALLBACK_NEUTRAL
	local bottom = if isDark(base) then 0.72 else 0.9
	local corner = Color3.new(1, 1, 1)
	if tint then
		corner = corner:Lerp(tint, AURORA_TINT)
	end
	gradient.Rotation = 35
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, corner),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(bottom, bottom, bottom)),
	})
end

local function restampTile(record, theme)
	local base = (theme and theme[record.baseSlot]) or FALLBACK_NEUTRAL
	local tint = record.tint or (theme and theme.AccentColor) or Color3.fromRGB(96, 165, 250)
	record.tile.BackgroundColor3 = tileFill(tint, base)
	record.glyph.ImageColor3 = accentText(tint, isDark(base))
end

function Changelog.new(parent, Settings)
	Settings = Settings or {}
	local theme = ThemeManager.GetTheme(Settings.Theme)
	local self = setmetatable({}, Changelog)

	self.IsOpen = false
	self.Version = Settings.Version or ""
	self.Title = Settings.Title or "Changelog"
	self.OnClose = Settings.OnClose
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
	-- Height scales with the layer so the shell fits; the constraint clamps it.
	popup.Size = UDim2.fromScale(0.6, 0.82)
	popup.Position = UDim2.fromScale(0.5, 0.5)
	popup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	popup.Visible = false
	popup.Active = true
	popup.ZIndex = 12
	popup.Parent = parent

	-- No stroke: the popup layer's z-order keeps it above the compact tab row.
	local shellGradient = Instance.new("UIGradient")
	stampShellGradient(shellGradient, theme)
	shellGradient.Parent = popup
	self._shellGradients[1] = shellGradient

	local shadow = Instance.new("UIShadow")
	shadow.BlurRadius = UDim.new(0, 20)
	shadow.Transparency = 1
	shadow.Color = (theme and theme.PopupShadowColor) or Color3.new(0, 0, 0)
	shadow.Parent = popup

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CORNER_SHELL)
	corner.Parent = popup

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(340, 210)
	sizeConstraint.MaxSize = Vector2.new(560, 500) -- Taller shell.
	sizeConstraint.Parent = popup

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
	-- Stamped at build so tint tiles show before the first theme switch.
	restampTile(self._tiles[#self._tiles], theme)

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
	Locale.set(header, "Text", self.Title)
	header.Parent = popup

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
	-- Scroll-fade edges carry the affordance, so the bar stays invisible.
	scroll.ScrollBarThickness = 1
	scroll.ScrollBarImageTransparency = 1
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = popup
	ScrollFade.Attach(scroll)

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

			-- Fill sits on the inner frame so the gradient paints only the background.
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
			stampCardGradient(cardGradient, theme, tint)
			cardGradient.Parent = visual
			self._cardGradients[#self._cardGradients + 1] = { Gradient = cardGradient, Tint = tint }
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
			restampTile(self._tiles[#self._tiles], theme)

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

			-- Hover: lift the fill, slide the aurora, brighten the text.
			visual.MouseEnter:Connect(function()
				Tween.Play(visual, LIFT, { BackgroundColor3 = self._cardBase:Lerp(Color3.new(1, 1, 1), LIFT_BOOST) })
				Tween.Play(cardGradient, LIFT, { Offset = Vector2.new(0.08, 0.08) })
				Tween.Play(titleLabel, LIFT, { TextTransparency = 0 })
				Tween.Play(descLabel, LIFT, { TextTransparency = 0.3 })
			end)
			visual.MouseLeave:Connect(function()
				Tween.Play(visual, LIFT, { BackgroundColor3 = self._cardBase })
				Tween.Play(cardGradient, LIFT, { Offset = Vector2.zero })
				Tween.Play(titleLabel, LIFT, { TextTransparency = 0.05 })
				Tween.Play(descLabel, LIFT, { TextTransparency = 0.45 })
			end)

			ThemeManager.BindColor(visual, "BackgroundColor3", "PopupNeutralColor")
			ThemeManager.BindColor(titleLabel, "TextColor3", "PopupTextColor")
			ThemeManager.BindColor(descLabel, "TextColor3", "PopupTextColor")

			self._cards[#self._cards + 1] = { Group = card }
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

	-- Gradients, tiles and accent text are derived, so they restamp here.
	ThemeManager.BindColor(popup, "BackgroundColor3", "PopupBackgroundColor")
	ThemeManager.BindColor(header, "TextColor3", "PopupTextColor")
	ThemeManager.BindColor(closeIcon, "ImageColor3", "PopupTextColor")
	ThemeManager.OnThemeApplied(function(applied)
		self._popupTransparency = applied.PopupBackgroundTransparency or 0.07
		self._cardBase = applied.PopupNeutralColor or FALLBACK_NEUTRAL
		if self.IsOpen then
			popup.BackgroundTransparency = self._popupTransparency
		end
		for _, gradient in ipairs(self._shellGradients) do
			stampShellGradient(gradient, applied)
		end
		for _, entry in ipairs(self._cardGradients) do
			stampCardGradient(entry.Gradient, applied, entry.Tint)
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

-- The token drops callbacks from a superseded open; no UIScale on auto-sized cards.
function Changelog:_cascade()
	local token = self._revealToken + 1
	self._revealToken = token
	for i, entry in ipairs(self._cards) do
		if entry.Group.Parent then
			entry.Group.GroupTransparency = 1
		end
		local delay = CASCADE_LEAD + math.min((i - 1) * CASCADE_STEP, CASCADE_CAP)
		task.delay(delay, function()
			if self._revealToken ~= token or not self.IsOpen or not entry.Group.Parent then
				return
			end
			Tween.Play(entry.Group, SETTLE, { GroupTransparency = 0 })
		end)
	end
end

-- Armed in Open, dropped in Close and Destroy.
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
		-- Descendants count as inside so overhanging content is not misread.
		local pos = self.Popup.AbsolutePosition
		local size = self.Popup.AbsoluteSize
		local inside = p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
		if not inside then
			local playerGui = self.Popup:FindFirstAncestorOfClass("PlayerGui")
			if playerGui then
				for _, obj in ipairs(playerGui:GetGuiObjectsAtPosition(p.X, p.Y)) do
					if obj == self.Popup or obj:IsDescendantOf(self.Popup) then
						inside = true
						break
					end
				end
			end
		end
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
	self.Scroll.CanvasPosition = Vector2.zero
	self:_connectOutsideClick()
	self:_cascade()
	Tween.Play(popup, "Fast", { GroupTransparency = 0 })
	Tween.Play(self.Shadow, "Fast", { Transparency = SHADOW_OPEN })
end

-- reason is "replaced" when another popup takes over, otherwise a user close.
function Changelog:Close(reason)
	if not self.IsOpen then
		return
	end
	self.IsOpen = false
	-- Disarmed before the fade so a click during it cannot re-trigger.
	self:_disconnectOutsideClick()
	if self.OnClose then
		self.OnClose(reason or "user")
	end
	Tween.Play(self.Popup, "Fast", { GroupTransparency = 1 })
	Tween.Play(self.Shadow, "Fast", { Transparency = 1 })
	-- Hidden after the fade; the instance is kept for reuse.
	if self._hideTimer then
		task.cancel(self._hideTimer)
	end
	self._hideTimer = task.delay(0.35, function()
		self._hideTimer = nil
		if not self.IsOpen and self.Popup and self.Popup.Parent then
			self.Popup.Visible = false
		end
	end)
end

-- Cross-popup dismissal; identical to clicking outside, but flagged.
function Changelog:Dismiss()
	self:Close("replaced")
end

function Changelog:Destroy()
	self:_disconnectOutsideClick()
	if self._hideTimer then
		task.cancel(self._hideTimer)
		self._hideTimer = nil
	end
	if self.Popup then
		self.Popup:Destroy()
	end
end

return Changelog
