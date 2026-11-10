--[[
	Aetheris/Popups/Notification.luau

	Self-destroying toast notifications in three flavours: Alert (amber),
	Error (red), and Variable (green; custom icon, colours, background image
	and up to MAX_ACTIONS action buttons). Created via window:Alert() /
	window:Error() / window:Toast().

	Motion follows the Novoline toast: the glass shell grows in from a small
	square pill and rounds out, the body fades in behind it, hovering pauses
	the countdown while a progress bar drains, then the card shrinks back
	down and destroys itself.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Tween = require("../Utils/Tween")
local UUID = require("../Utils/UUID")
local ThemeManager = require("../Themes/ThemeManager")
local Aurora = require("../Utils/Aurora")
local FallbackImage = require("../Constants").FallbackImage
local Icons = require("../Assets/Icons")
local Sound = require("../Utils/Sound")
local Constants = require("../Constants")
local Locale = require("../Utils/Locale")

local Notification = {}
Notification.__index = Notification

local MAX_ACTIONS = 2

-- Card geometry: height derives from the row's content via syncHeight, so these are the only fixed numbers.
local TOAST_WIDTH = 280
local ROW_TOP_INSET = 17
local TOAST_MIN_HEIGHT = 40
-- Extra height below the row so a one-line toast isn't cramped; applied in syncHeight only.
local TOAST_EXTRA_HEIGHT = 7
local HEADER_HEIGHT = 16
-- Novoline tint tile: a 34px pill with the glyph inside, 10px clear of the text column.
local TILE_SIZE = 34
local TILE_GAP = 10
local TEXT_X = 14 + TILE_SIZE + TILE_GAP -- left edge of the text column (58, like the reference)
local DISMISS_GUTTER = 30
local CARD_CORNER = 20

-- Open: the shell grows from a small square pill, the body fades in behind it.
local OPEN_W = 132
local OPEN_H = 30
local OPEN_GROW = 0.55
local OPEN_CORNER_TIME = 0.45
local OPEN_SHELL_TIME = 0.5
local BODY_DELAY = 0.12
local BODY_FADE_TIME = 0.32

-- Close: body out first, then the shell shrinks back toward a pill.
local CLOSE_W = 120
local CLOSE_H = 28
local CLOSE_RADIUS = 14
local CLOSE_BODY_TIME = 0.16
local CLOSE_GROW_TIME = 0.34
local CLOSE_SHELL_TIME = 0.28
local CLOSE_SHELL_DELAY = 0.08
local CLOSE_CORNER_TIME = 0.3
local CLOSE_DESTROY_DELAY = 0.42

local function new(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		if k == "Parent" then
			inst.Parent = v
		else
			inst[k] = v
		end
	end
	return inst
end

-- Snapshot decorations CanvasGroup transparency does not cover (UIStroke/UIShadow) so they can fade along.
local function captureFade(root)
	local targets = {}
	local function scan(inst)
		if inst:IsA("UIStroke") or inst:IsA("UIShadow") then
			table.insert(targets, { inst, "Transparency", inst.Transparency })
		end
		for _, c in ipairs(inst:GetChildren()) do
			scan(c)
		end
	end
	scan(root)
	return targets
end

local function setAll(targets, value)
	for _, t in ipairs(targets) do
		t[1][t[2]] = value
	end
end

local function tweenAll(targets, value, duration)
	for _, t in ipairs(targets) do
		local target = value
		if target == nil then
			target = t[3]
		end
		Tween.Play(t[1], TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { [t[2]] = target })
	end
end

-- Novoline tint recipe: the tile washes to a dark tint of the flavour accent so the bright glyph reads.
local function darkTint(color)
	local h, s = color:ToHSV()
	return Color3.fromHSV(h, math.min(s, 0.75), 0.24)
end

-- Height is measured from the row (which converges on offset content), not auto-sized.
-- While the shell grows, root.Size belongs to the open tween, so this retargets that
-- tween instead of snapping: wrapped text converges a layout pass after build, and
-- freezing the pass (the old guard) left the card short until the grow finished.
-- During close the shrink tween owns root.Size, so the pass is skipped entirely.
function Notification:_syncHeight()
	local root = self.Root
	if not root or self._closing then
		return
	end
	local height = math.max(TOAST_MIN_HEIGHT, self._row.AbsoluteSize.Y + ROW_TOP_INSET + TOAST_EXTRA_HEIGHT)
	local size = UDim2.fromOffset(TOAST_WIDTH, height)
	-- Content width never changes, so updating it mid-open only moves the vertical
	-- rhythm (progress track, bottom band) — no horizontal reflow of the text.
	self._content.Size = size
	self._fullSize = size
	if self._openTweening then
		Tween.Play(root, TweenInfo.new(OPEN_GROW, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = size })
	else
		root.Size = size
	end
end

local ACCENT_KEY = {
	Alert = "NotificationAlertAccent",
	Error = "NotificationErrorAccent",
	Variable = "NotificationVariableAccent",
}

-- The card wash uses the aurora keys so Alert/Error read as themed colours first, warning/danger second.
local WASH_KEY = {
	Alert = "NotificationAlertAurora",
	Error = "NotificationErrorAurora",
	Variable = "NotificationVariableAccent",
}

-- Per-type fallbacks so a theme missing its Notification*Accent keys still colour-matches each flavour.
local FALLBACK_ACCENT = {
	Alert = Color3.fromRGB(249, 115, 22),
	Error = Color3.fromRGB(226, 42, 42),
	Variable = Color3.fromRGB(74, 200, 120),
}

local DEFAULT_TITLE = {
	Alert = "Alert",
	Error = "Error",
	Variable = "Changes saved!",
}

-- Default icon per type; all full images, so no rect offset/size is set.
local DEFAULT_ICON = {
	Alert = Icons["triangle-alert"] or "rbxassetid://125920361880643",
	Error = Icons["shield-alert"] or "rbxassetid://114995877719925",
	Variable = Icons["bell"] or "rbxassetid://97392696311902",
}
local CLOSE_ICON = Icons["minimize-2"] or "rbxassetid://116269596042539"

function Notification.new(container, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Notification)

	local ntype = Settings.Type or "Alert"
	local title = Locale.resolve(Settings.Title or DEFAULT_TITLE[ntype] or "Notification")
	local description = Settings.Description or ""
	self.Duration = Settings.Duration or 5
	self._hovered = false
	self._openTweening = false
	self._bodyShown = false

	local accent = theme[ACCENT_KEY[ntype]] or FALLBACK_ACCENT[ntype] or FALLBACK_ACCENT.Alert
	local iconColor = Settings.IconColor or accent
	local washColor = Settings.GradientColor or theme[WASH_KEY[ntype]] or accent

	-- Sized by syncHeight from the row below, not AutomaticSize: scale(1,1) wash frames measured against this card and grew it every pass.
	local root = new("CanvasGroup", {
		Name = UUID.Generate("Toast"),
		ZIndex = 999,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		BackgroundColor3 = theme.NotificationBackgroundColor or Color3.fromRGB(16, 16, 17),
		BackgroundTransparency = theme.NotificationBackgroundTransparency or 0.1,
		-- No ClipsDescendants: it would clip this card's own UIShadow glow; the wash/background already clip themselves.
		Size = UDim2.fromOffset(TOAST_WIDTH, TOAST_MIN_HEIGHT),
		BorderColor3 = Color3.fromRGB(41, 41, 41),
		LayoutOrder = 2,
		Parent = container,
	})
	self.Root = root

	local rootCorner = new("UICorner", { Parent = root, CornerRadius = UDim.new(0, CARD_CORNER) })
	self._corners = { rootCorner }

	-- Card chrome colour-matched to the flavour accent; theme keys only tune transparency.
	local stroke = new("UIStroke", {
		Parent = root,
		Color = accent,
		Transparency = theme.NotificationStrokeTransparency or 0.65,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})

	-- The card's glow, colour-matched to the accent; captureFade carries it with the group fade.
	local shadow = new("UIShadow", {
		Parent = root,
		Color = accent,
		Transparency = theme.NotificationShadowTransparency or 0.45,
		BlurRadius = UDim.new(0, 18),
		Offset = UDim2.fromOffset(0, 6),
	})
	-- Stamp PageFadeBase so any FadeDecorations sweep that reaches out-of-tree toasts returns to the rest state.
	shadow:SetAttribute(UUID.Static("PageFadeBase"), shadow.Transparency)
	self._shadow = shadow

	-- Accent bloom wash clipped to the toast; ColorKey binds it to the live theme accent unless the caller overrode the gradient.
	local wash = Aurora.Wash(root, {
		Color = washColor,
		ColorKey = (Settings.GradientColor == nil) and WASH_KEY[ntype] or nil,
		CornerRadius = UDim.new(1, 1),
		Intensity = 0.1,
	})

	if Settings.ShowBackground then
		local bg = new("ImageLabel", {
			Name = UUID.Static("Background"),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			ImageTransparency = 0.5,
			Image = Settings.BackgroundImage or theme.Wallpaper or FallbackImage,
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			ZIndex = 0,
			Parent = root,
		})
		local bgCorner = new("UICorner", { Parent = bg, CornerRadius = UDim.new(0, CARD_CORNER) })
		table.insert(self._corners, bgCorner)
		self._background = bg
		self._backgroundOverride = Settings.BackgroundImage
		new("UIGradient", {
			Parent = bg,
			Rotation = 180,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0.000, 0),
				NumberSequenceKeypoint.new(0.134, 0.3),
				NumberSequenceKeypoint.new(0.242, 0.53125),
				NumberSequenceKeypoint.new(0.371, 0.69375),
				NumberSequenceKeypoint.new(0.484, 0.80625),
				NumberSequenceKeypoint.new(0.590, 0.91875),
				NumberSequenceKeypoint.new(0.681, 0.975),
				NumberSequenceKeypoint.new(1.000, 1),
			}),
		})
	end

	-- Shell-only scan: Content does not exist yet, so this captures just the rim and glow.
	self._shellFade = captureFade(root)

	-- Body layer: fades in behind the shell on open and out before the shrink, so the
	-- card reads as glass first and text second (Novoline ordering). Fixed-size and
	-- centre-anchored so it never reflows while the shell grows around it.
	local content = new("CanvasGroup", {
		Name = UUID.Static("Content"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(TOAST_WIDTH, TOAST_MIN_HEIGHT),
		ZIndex = 2,
		Parent = root,
	})
	self._content = content

	-- Tile + one in-flow text column; all-offset children so AutomaticSize.Y converges and syncHeight can copy it (14px left margin, 30px right gutter for the dismiss).
	local row = new("Frame", {
		Name = UUID.Static("Row"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -(14 + DISMISS_GUTTER), 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(14, ROW_TOP_INSET),
		ZIndex = 2,
		Parent = content,
	})
	new("UIListLayout", {
		Parent = row,
		Padding = UDim.new(0, TILE_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
	})
	-- Bottom band rides in the row's AutomaticSize.Y (root UIPadding would break the wash), so the progress track clears the description.
	new("UIPadding", { Parent = row, PaddingBottom = UDim.new(0, ROW_TOP_INSET) })

	local tile = new("Frame", {
		Name = UUID.Static("Tile"),
		BorderSizePixel = 0,
		BackgroundColor3 = darkTint(iconColor),
		Size = UDim2.fromOffset(TILE_SIZE, TILE_SIZE),
		LayoutOrder = 1,
		ZIndex = 2,
		Parent = row,
	})
	new("UICorner", { Parent = tile, CornerRadius = UDim.new(1, 0) })
	new("UIStroke", {
		Parent = tile,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Color3.new(1, 1, 1),
		Transparency = 0.9,
		Thickness = 1,
	})

	local glyph = new("ImageLabel", {
		Name = UUID.Static("Glyph"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(18, 18),
		ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = iconColor,
		Image = Settings.Icon or DEFAULT_ICON[ntype] or DEFAULT_ICON.Alert,
		ZIndex = 3,
		Parent = tile,
	})

	local col = new("Frame", {
		Name = UUID.Static("Column"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		-- Tile (34) + gap (10); the dismiss button sits outside the row, so no extra reserve.
		Size = UDim2.new(1, -(TILE_SIZE + TILE_GAP), 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		ZIndex = 2,
		Parent = row,
	})
	new("UIListLayout", {
		Parent = col,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local header = new("TextLabel", {
		Name = UUID.Static("Header"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTransparency = theme.NotificationHeaderTransparency or 0.3,
		TextColor3 = theme.NotificationHeaderColor or Color3.fromRGB(255, 255, 255),
		FontFace = Constants.Font(Enum.FontWeight.Bold),
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		LayoutOrder = 1,
		ZIndex = 2,
		Text = title,
		Parent = col,
	})
	local desc = new("TextLabel", {
		Name = UUID.Static("Description"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextWrapped = true,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTransparency = theme.NotificationTextTransparency or 0.5,
		TextColor3 = theme.NotificationTextColor or Color3.fromRGB(255, 255, 255),
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
		ZIndex = 2,
		Text = description,
		Parent = col,
	})

	local actions = Settings.Actions or {}
	self._actions = {}
	if #actions > 0 then
		local holder = new("Frame", {
			Name = UUID.Static("InterractionHolder"),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			LayoutOrder = 4,
			ZIndex = 3,
			Parent = col,
		})
		new("UIListLayout", {
			Parent = holder,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
		})
		new("UIPadding", { Parent = holder, PaddingTop = UDim.new(0, 5) })
		local baseBg = theme.NotificationActionButtonColor or Color3.fromRGB(81, 81, 81)
		for i = 1, math.min(#actions, MAX_ACTIONS) do
			local action = actions[i]
			local btn = new("TextButton", {
				Name = UUID.Generate("ToastAction"),
				BorderSizePixel = 0,
				AutoButtonColor = false,
				TextSize = 12,
				TextColor3 = theme.NotificationActionButtonTextColor or Color3.fromRGB(255, 255, 255),
				BackgroundColor3 = baseBg,
				FontFace = Constants.Font(Enum.FontWeight.Medium),
				Size = UDim2.fromOffset(60, 20),
				Text = Locale.resolve(action.Text or "Click"),
				LayoutOrder = i,
				ZIndex = 4,
				Parent = holder,
			})
			btn:SetAttribute(UUID.Static("ToastBaseBackground"), baseBg)
			new("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 4) })

			-- Button-component motion 1:1: hover 1.02, press 0.97, click wash in/out.
			local btnScale = new("UIScale", { Parent = btn, Scale = 1 })

			local btnShadow = new("UIShadow", {
				Color = accent,
				Transparency = 1,
				BlurRadius = UDim.new(0, 12),
				Parent = btn,
			})

			local btnFlash = new("Frame", {
				Name = UUID.Static("ToastActionFlash"),
				BorderSizePixel = 0,
				BackgroundColor3 = theme.PrimaryColor or accent,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Parent = btn,
			})
			new("UICorner", { Parent = btnFlash, CornerRadius = UDim.new(0, 4) })

			local isHovered = false
			btn.MouseEnter:Connect(function()
				isHovered = true
				btn:SetAttribute(UUID.Static("ToastHovered"), true)
				Tween.Play(btnShadow, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Transparency = 0.4 })
				Tween.Play(btnScale, "HoverIn", { Scale = 1.02 })
			end)
			btn.MouseLeave:Connect(function()
				isHovered = false
				btn:SetAttribute(UUID.Static("ToastHovered"), false)
				Tween.Play(btnShadow, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Transparency = 1 })
				Tween.Play(btnScale, "HoverOut", { Scale = 1 })
			end)
			btn.MouseButton1Down:Connect(function()
				Tween.Play(btnScale, "Fast", { Scale = 0.97 })
			end)
			btn.MouseButton1Up:Connect(function()
				Tween.Play(btnScale, "HoverIn", { Scale = isHovered and 1.02 or 1 })
			end)

			btn.MouseButton1Click:Connect(function()
				-- Overlay in over 0.12s, out over 0.5s; rapid clicks restart it instead of locking.
				Tween.CancelAll(btnFlash)
				Tween.Play(btnFlash, "Click", { BackgroundTransparency = 0.15 })
				task.delay(0.12, function()
					if not btnFlash.Parent then
						return
					end
					Tween.Play(btnFlash, "Release", { BackgroundTransparency = 1 })
				end)
				-- Callback fires immediately; the toast exits just after the flash-in lands.
				if action.Callback then
					action.Callback(self)
				end
				task.delay(0.15, function()
					self:Close()
				end)
			end)

			table.insert(self._actions, { button = btn, shadow = btnShadow, flash = btnFlash })
		end
	end

	-- Centre-pinned so hover growth stays centred against the card's right edge.
	local dismiss = new("ImageButton", {
		Name = UUID.Static("DismissButton"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ImageTransparency = 0.5,
		Image = CLOSE_ICON,
		ImageColor3 = theme.NotificationDismissColor or Color3.fromRGB(255, 255, 255),
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		ZIndex = 3,
		Parent = content,
	})
	new("UIAspectRatioConstraint", { Parent = dismiss, DominantAxis = Enum.DominantAxis.Height })

	local function dismissTween(prop, dur)
		Tween.Play(dismiss, TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), prop)
	end
	dismiss.MouseEnter:Connect(function()
		dismissTween({ ImageTransparency = 0.1, Size = UDim2.fromOffset(18, 18) })
	end)
	dismiss.MouseLeave:Connect(function()
		dismissTween({ ImageTransparency = 0.5, Size = UDim2.fromOffset(16, 16) })
	end)
	dismiss.MouseButton1Down:Connect(function()
		dismissTween({ Size = UDim2.fromOffset(14, 14) }, 0.08)
	end)
	dismiss.MouseButton1Up:Connect(function()
		dismissTween({ Size = UDim2.fromOffset(18, 18) }, 0.08)
	end)
	dismiss.MouseButton1Click:Connect(function()
		self:Close()
	end)

	-- Countdown track: a hairline under the text that drains with the timer.
	local track = new("Frame", {
		Name = UUID.Static("ProgressTrack"),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.91,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, TEXT_X, 1, -10),
		Size = UDim2.new(1, -(TEXT_X + DISMISS_GUTTER), 0, 3),
		ZIndex = 3,
		Parent = content,
	})
	new("UICorner", { Parent = track, CornerRadius = UDim.new(1, 0) })
	local fill = new("Frame", {
		Name = UUID.Static("ProgressFill"),
		BorderSizePixel = 0,
		BackgroundColor3 = accent,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 4,
		Parent = track,
	})
	new("UICorner", { Parent = fill, CornerRadius = UDim.new(1, 0) })
	self._fill = fill

	-- Body scan (tile rim, action glows) captured with everything already inside Content.
	self._contentFade = captureFade(content)

	self._shown = false
	self._closing = false

	-- Retained so ApplyTheme can recolour a toast already on screen (toasts live outside the window tree).
	self._type = ntype
	self._accent = accent
	self._iconOverride = Settings.IconColor
	self._washOverride = Settings.GradientColor
	self._wash = wash
	self._stroke = stroke
	self._header = header
	self._icon = glyph
	self._tile = tile
	self._desc = desc
	self._dismiss = dismiss
	self._row = row

	-- Hovering anywhere on the card (children included) pauses the countdown.
	root.MouseEnter:Connect(function()
		self._hovered = true
	end)
	root.MouseLeave:Connect(function()
		self._hovered = false
	end)

	-- Re-sync on reflow so text changes and font/theme swaps resize the card too;
	-- mid-open this retargets the grow tween (see _syncHeight) instead of being dropped.
	self:_syncHeight()
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if root.Parent then
			self:_syncHeight()
		end
	end)

	return self
end

-- Live theme switch: recolour in place so an open toast follows the UI instead of being rebuilt.
function Notification:ApplyTheme(themeInput)
	if not self.Root then
		return
	end
	local theme = ThemeManager.GetTheme(themeInput)

	-- A theme switch sweeps CancelAllUnder the ScreenGui; if it lands mid-open the
	-- grow tweens die, so snap the card to its final open state first (the recolour
	-- below then overwrites anything this restored).
	if self._openTweening and not self._closing then
		self._openTweening = false
		self.Root.GroupTransparency = 0
		for _, t in ipairs(self._shellFade) do
			t[1][t[2]] = t[3]
		end
		for _, corner in ipairs(self._corners) do
			corner.CornerRadius = UDim.new(0, CARD_CORNER)
		end
		if self._bodyShown then
			self._content.GroupTransparency = 0
			for _, t in ipairs(self._contentFade) do
				t[1][t[2]] = t[3]
			end
		end
		self:_syncHeight()
	end

	local accent = theme[ACCENT_KEY[self._type]] or FALLBACK_ACCENT[self._type] or self._accent
	self._accent = accent
	local iconColor = self._iconOverride or accent
	local washColor = self._washOverride or theme[WASH_KEY[self._type]] or accent

	self.Root.BackgroundColor3 = theme.NotificationBackgroundColor or self.Root.BackgroundColor3
	self.Root.BackgroundTransparency = theme.NotificationBackgroundTransparency or self.Root.BackgroundTransparency

	-- Rim and glow follow the flavour accent; theme keys only tune transparency.
	self._shadow.Color = accent
	if theme.NotificationShadowTransparency then
		self._shadow.Transparency = theme.NotificationShadowTransparency
	end
	self._stroke.Color = accent
	self._stroke.Transparency = theme.NotificationStrokeTransparency or 0.65
	if self._wash then
		self._wash:SetColor(washColor)
	end

	-- Wallpaper is an asset id, not a colour binding, so re-stamp it on every switch.
	if self._background then
		self._background.Image = self._backgroundOverride or theme.Wallpaper or FallbackImage
		self._background.Visible = (self._backgroundOverride ~= nil) or theme.WallpaperEnabled ~= false
	end

	if self._header then
		if theme.NotificationHeaderColor then
			self._header.TextColor3 = theme.NotificationHeaderColor
		end
		if theme.NotificationHeaderTransparency then
			self._header.TextTransparency = theme.NotificationHeaderTransparency
		end
	end

	if self._tile then
		self._tile.BackgroundColor3 = darkTint(iconColor)
	end
	if self._icon then
		self._icon.ImageColor3 = iconColor
	end
	if self._fill then
		self._fill.BackgroundColor3 = accent
	end

	if self._desc then
		if theme.NotificationTextColor then
			self._desc.TextColor3 = theme.NotificationTextColor
		end
		if theme.NotificationTextTransparency then
			self._desc.TextTransparency = theme.NotificationTextTransparency
		end
	end

	local baseBg = theme.NotificationActionButtonColor or Color3.fromRGB(81, 81, 81)
	local buttonText = theme.NotificationActionButtonTextColor or Color3.fromRGB(255, 255, 255)
	for _, entry in ipairs(self._actions) do
		local button = entry.button
		button:SetAttribute(UUID.Static("ToastBaseBackground"), baseBg)
		button.BackgroundColor3 = baseBg
		button.TextColor3 = buttonText
		if entry.flash then
			entry.flash.BackgroundColor3 = theme.PrimaryColor or accent
			entry.flash.BackgroundTransparency = 1
		end
		entry.shadow.Color = accent
	end

	if self._dismiss then
		self._dismiss.ImageColor3 = theme.NotificationDismissColor or self._dismiss.ImageColor3
	end
end

-- Frame-step countdown (not a tween) so a theme switch's tween sweep can't kill it;
-- hovering the card pauses the drain until the mouse leaves.
function Notification:_runTimer()
	task.spawn(function()
		local left = self.Duration
		while left > 0 and not self._closing do
			local dt = task.wait()
			if not self._hovered then
				left = left - dt
			end
			if self._fill and self._fill.Parent then
				self._fill.Size = UDim2.fromScale(math.clamp(left / self.Duration, 0, 1), 1)
			end
		end
		if not self._closing then
			self:Close()
		end
	end)
end

function Notification:Show()
	if self._shown then
		return self
	end
	self._shown = true
	Sound.Play("Notification")

	local root = self.Root
	if not root then
		return self
	end

	-- Open: the shell starts as a small square pill and grows/rounds out to the
	-- measured card. _openTweening hands Size to the tween: reflows during the grow
	-- retarget it (see _syncHeight) rather than snapping the card mid-animation.
	self._openTweening = true
	local full = root.Size
	root.Size = UDim2.fromOffset(math.min(full.X.Offset, OPEN_W), OPEN_H)
	for _, corner in ipairs(self._corners) do
		corner.CornerRadius = UDim.new(0, 0)
	end
	root.GroupTransparency = 1
	setAll(self._shellFade, 1)
	self._content.GroupTransparency = 1
	setAll(self._contentFade, 1)

	Tween.Play(root, TweenInfo.new(OPEN_GROW, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = full })
	for _, corner in ipairs(self._corners) do
		Tween.Play(
			corner,
			TweenInfo.new(OPEN_CORNER_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ CornerRadius = UDim.new(0, CARD_CORNER) }
		)
	end
	Tween.Play(
		root,
		TweenInfo.new(OPEN_SHELL_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ GroupTransparency = 0 }
	)
	tweenAll(self._shellFade, nil, OPEN_SHELL_TIME)

	task.delay(BODY_DELAY, function()
		if not self._content or self._closing then
			return
		end
		self._bodyShown = true
		Tween.Play(
			self._content,
			TweenInfo.new(BODY_FADE_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ GroupTransparency = 0 }
		)
		tweenAll(self._contentFade, nil, BODY_FADE_TIME)
	end)

	task.delay(OPEN_GROW, function()
		if self._closing or not self.Root then
			return
		end
		self._openTweening = false
		self:_syncHeight()
	end)

	self:_runTimer()
	return self
end

function Notification:Close()
	if self._closing then
		return
	end
	self._closing = true
	local root = self.Root
	if not root then
		return
	end

	-- Body out first, then the shell shrinks back toward a pill and fades.
	Tween.Play(
		self._content,
		TweenInfo.new(CLOSE_BODY_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = 1 }
	)
	tweenAll(self._contentFade, 1, CLOSE_BODY_TIME)
	Tween.Play(
		root,
		TweenInfo.new(CLOSE_GROW_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
		{ Size = UDim2.fromOffset(CLOSE_W, CLOSE_H) }
	)
	for _, corner in ipairs(self._corners) do
		Tween.Play(
			corner,
			TweenInfo.new(CLOSE_CORNER_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{ CornerRadius = UDim.new(0, CLOSE_RADIUS) }
		)
	end
	Tween.Play(
		root,
		TweenInfo.new(CLOSE_SHELL_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, CLOSE_SHELL_DELAY),
		{ GroupTransparency = 1 }
	)
	tweenAll(self._shellFade, 1, CLOSE_SHELL_TIME)
	task.delay(CLOSE_DESTROY_DELAY, function()
		if self.Root then
			self.Root:Destroy()
			self.Root = nil
		end
	end)
end

return Notification
