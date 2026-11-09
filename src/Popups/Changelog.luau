--[[
	Aetheris/Popups/Changelog.luau

	Startup changelog popup: a scrolling column of rectangular cards, each a
	title over a wrapped description. Cards carry a 0.85-transparency stroke
	and a diagonal sheen that only resolves in the top-right corner; no aurora,
	so it reads quieter than a notification. Version tracking lives in the
	window - this module only builds and shows the entries it is handed.
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

-- The card look: barely-there fill, faint accent edge, and a hover that only
-- nudges the fill so it stays subtle.
local CARD_TRANSPARENCY = 0.92
local CARD_HOVER_DELTA = 0.06
local STROKE_TRANSPARENCY = 0.85
local CLOSE_ICON = Icons["circle-x"] or "rbxassetid://76821953846248"

-- Re-stamped on every theme switch (UIGradient.Color is a ColorSequence, so
-- it can't go through Bind).
local function stampGradient(gradient, theme)
	local accent = (theme and theme.AccentColor) or Color3.fromRGB(255, 255, 255)
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, accent),
	})
end

function Changelog.new(parent, Settings)
	Settings = Settings or {}
	local theme = ThemeManager.GetTheme(Settings.Theme)
	local self = setmetatable({}, Changelog)

	self.IsOpen = false
	self.Version = Settings.Version or ""
	self.Entries = Settings.Entries or {}
	self._gradients = {}
	self._popupTransparency = (theme and theme.PopupBackgroundTransparency) or 0.07

	local popup = Instance.new("CanvasGroup")
	popup.Name = UUID.Generate("ChangelogPopup")
	popup.BorderSizePixel = 0
	popup.GroupTransparency = 1
	popup.BackgroundColor3 = (theme and theme.PopupBackgroundColor)
	popup.BackgroundTransparency = self._popupTransparency
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Size = UDim2.new(0.6, 0, 0, 380)
	popup.Position = UDim2.fromScale(0.5, 0.5)
	popup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	popup.Visible = false
	popup.ZIndex = 12
	popup.Parent = parent
	local shadow = Instance.new("UIShadow")
	shadow.BlurRadius = UDim.new(0, 24)
	shadow.Offset = UDim2.fromOffset(0, 6)
	shadow.Transparency = 1
	shadow.Color = (theme and theme.NotificationShadowColor) or (theme and theme.PopupShadowColor)
	shadow.Parent = popup
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = popup
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(360, 320)
	sizeConstraint.MaxSize = Vector2.new(560, 460)
	sizeConstraint.Parent = popup

	local header = Instance.new("TextLabel")
	header.Name = UUID.Static("Header")
	header.BorderSizePixel = 0
	header.BackgroundTransparency = 1
	header.TextSize = 15
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextTransparency = 0.2
	header.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	header.TextColor3 = (theme and theme.PopupTextColor)
	header.AnchorPoint = Vector2.new(0, 0)
	header.Size = UDim2.new(1, -70, 0, 20)
	header.Position = UDim2.fromOffset(16, 14)
	header.ZIndex = 13
	Locale.set(header, "Text", "Changelog")
	header.Parent = popup

	-- Version pill: only when the script writer actually stamped a version.
	if self.Version ~= "" then
		local pill = Instance.new("TextLabel")
		pill.Name = UUID.Static("VersionPill")
		pill.BorderSizePixel = 0
		pill.BackgroundColor3 = (theme and theme.AccentColor)
		pill.BackgroundTransparency = 0.85
		pill.AutomaticSize = Enum.AutomaticSize.X
		pill.Size = UDim2.fromOffset(0, 20)
		pill.Position = UDim2.fromOffset(16, 42)
		pill.TextSize = 11
		pill.FontFace = Constants.Font(Enum.FontWeight.Medium)
		pill.TextColor3 = (theme and theme.PopupTextColor)
		pill.TextTransparency = 0.15
		pill.TextXAlignment = Enum.TextXAlignment.Left
		pill.ZIndex = 13
		pill.Text = "  " .. self.Version .. "  "
		pill.Parent = popup
		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(1, 0)
		pillCorner.Parent = pill
	end

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = UUID.Static("Close")
	closeBtn.BorderSizePixel = 0
	closeBtn.BackgroundTransparency = 1
	closeBtn.AutoButtonColor = false
	closeBtn.Image = CLOSE_ICON
	closeBtn.ImageTransparency = 0.45
	closeBtn.ImageColor3 = (theme and theme.PopupTextColor)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Size = UDim2.fromOffset(26, 26)
	closeBtn.Position = UDim2.new(1, -12, 0, 10)
	closeBtn.ZIndex = 14
	closeBtn.Parent = popup

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = UUID.Static("Scroll")
	scroll.BorderSizePixel = 0
	scroll.BackgroundTransparency = 1
	scroll.Size = UDim2.new(1, -32, 1, -92)
	scroll.Position = UDim2.fromOffset(16, 76)
	scroll.ZIndex = 13
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = (theme and theme.AccentColor)
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = popup
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

			local card = Instance.new("Frame")
			card.Name = UUID.Generate("ChangeCard")
			card.BorderSizePixel = 0
			card.BackgroundColor3 = (theme and theme.PopupNeutralColor) or Color3.fromRGB(30, 30, 32)
			card.BackgroundTransparency = CARD_TRANSPARENCY
			card.AutomaticSize = Enum.AutomaticSize.Y
			card.Size = UDim2.fromScale(1, 0)
			card.LayoutOrder = i
			card.ZIndex = 13
			card.Parent = scroll
			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 6)
			cardCorner.Parent = card
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 1
			stroke.Transparency = STROKE_TRANSPARENCY
			stroke.Color = (theme and theme.AccentColor) or Color3.fromRGB(255, 255, 255)
			stroke.Parent = card

			-- Opaque white plate under a mostly-transparent gradient: only the
			-- top-right corner resolves into a faint accent tint.
			local sheen = Instance.new("Frame")
			sheen.Name = UUID.Static("Sheen")
			sheen.BorderSizePixel = 0
			sheen.BackgroundColor3 = Color3.new(1, 1, 1)
			sheen.Size = UDim2.fromScale(1, 1)
			sheen.ZIndex = 13
			sheen.Parent = card
			local sheenCorner = Instance.new("UICorner")
			sheenCorner.CornerRadius = UDim.new(0, 6)
			sheenCorner.Parent = sheen
			local sheenGradient = Instance.new("UIGradient")
			sheenGradient.Rotation = -45
			sheenGradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0.9),
			})
			sheenGradient.Parent = sheen
			stampGradient(sheenGradient, theme)
			self._gradients[#self._gradients + 1] = sheenGradient

			local cardPad = Instance.new("UIPadding")
			cardPad.PaddingTop = UDim.new(0, 12)
			cardPad.PaddingBottom = UDim.new(0, 12)
			cardPad.PaddingLeft = UDim.new(0, 12)
			cardPad.PaddingRight = UDim.new(0, 12)
			cardPad.Parent = card
			local cardLayout = Instance.new("UIListLayout")
			cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
			cardLayout.Padding = UDim.new(0, 4)
			cardLayout.Parent = card

			local titleLabel = Instance.new("TextLabel")
			titleLabel.Name = UUID.Static("CardTitle")
			titleLabel.BorderSizePixel = 0
			titleLabel.BackgroundTransparency = 1
			titleLabel.AutomaticSize = Enum.AutomaticSize.Y
			titleLabel.Size = UDim2.fromScale(1, 0)
			titleLabel.TextSize = 13
			titleLabel.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
			titleLabel.TextColor3 = (theme and theme.PopupTextColor)
			titleLabel.TextTransparency = 0.1
			titleLabel.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel.TextWrapped = true
			titleLabel.LayoutOrder = 1
			titleLabel.ZIndex = 14
			titleLabel.Text = title
			titleLabel.Parent = card

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
			descLabel.ZIndex = 14
			descLabel.Text = description
			descLabel.Parent = card

			-- Hover nudges the fill only; stroke and sheen stay put.
			card.MouseEnter:Connect(function()
				Tween.Play(card, "Fast", { BackgroundTransparency = CARD_TRANSPARENCY - CARD_HOVER_DELTA })
			end)
			card.MouseLeave:Connect(function()
				Tween.Play(card, "Fast", { BackgroundTransparency = CARD_TRANSPARENCY })
			end)
		end
	end

	closeBtn.MouseButton1Click:Connect(function()
		self:Close()
	end)
	closeBtn.MouseEnter:Connect(function()
		Tween.Play(closeBtn, "Fast", { ImageTransparency = 0.1 })
	end)
	closeBtn.MouseLeave:Connect(function()
		Tween.Play(closeBtn, "Fast", { ImageTransparency = 0.45 })
	end)

	self.Popup = popup
	self.Shadow = shadow
	self.Header = header
	self.Scroll = scroll
	self.CloseBtn = closeBtn

	-- Colour follows the theme through Bind; the gradient and the popup fill
	-- transparency need the callback because a ColorSequence can't be bound
	-- and Open()/Close() tween the fill.
	ThemeManager.BindColor(popup, "BackgroundColor3", "PopupBackgroundColor")
	ThemeManager.BindColor(header, "TextColor3", "PopupTextColor")
	ThemeManager.BindColor(closeBtn, "ImageColor3", "PopupTextColor")
	ThemeManager.BindColor(scroll, "ScrollBarImageColor3", "AccentColor")
	ThemeManager.OnThemeApplied(function(applied)
		self._popupTransparency = applied.PopupBackgroundTransparency or 0.07
		if self.IsOpen then
			popup.BackgroundTransparency = self._popupTransparency
		end
		for _, gradient in ipairs(self._gradients) do
			stampGradient(gradient, applied)
		end
	end, popup)

	return self
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
	self.Popup.Visible = true
	self.Popup.GroupTransparency = 1
	self:_connectOutsideClick()
	Tween.Play(self.Popup, "Fast", {
		BackgroundTransparency = self._popupTransparency,
		GroupTransparency = 0,
	})
	Tween.Play(self.Shadow, "Fast", {
		Transparency = 0.5,
	})
end

function Changelog:Close()
	if not self.IsOpen then
		return
	end
	self.IsOpen = false
	Tween.Play(self.Shadow, "Fast", {
		Transparency = 1,
	})
	-- Disarm click-outside immediately so a click during the fade-out can't re-trigger it.
	self:_disconnectOutsideClick()
	Tween.Play(self.Popup, "Fast", {
		BackgroundTransparency = 1,
		GroupTransparency = 1,
	})
	task.delay(0.35, function()
		if not self.IsOpen then
			self.Popup.Visible = false
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
