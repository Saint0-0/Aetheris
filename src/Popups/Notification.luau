--[[
	Notification  ·  Aetheris UI Library

	Self-destroying toast notifications in three flavours:
	  Alert    - informational (amber accent)
	  Error    - error (red accent)
	  Variable - success/custom (green accent by default); supports a custom
	             icon, icon/gradient colours, an optional background image,
	             and up to MAX_ACTIONS interaction buttons with callbacks.

	Create via window:Alert() / window:Error() / window:Toast().
	Each toast builds itself, fades in, counts down via TimerFrame, then fades
	out and :Destroy()s itself to avoid leaking memory.
]]

local Tween = require("../Utils/Tween")
local UUID = require("../Utils/UUID")
local ThemeManager = require("../Themes/ThemeManager")
local Aurora = require("../Utils/Aurora")
local FallbackImage = require("../Constants").FallbackImage
local Icons = require("../Assets/Icons")
local Sound = require("../Utils/Sound")
local Constants = require("../Constants")

local Notification = {}
Notification.__index = Notification

local MAX_ACTIONS = 2
local FADE_IN = 0.2
local FADE_OUT = 0.2

-- Card geometry. The toast's height is derived from the row's content rather
-- than from AutomaticSize (see syncHeight), so these are the only fixed
-- numbers: the card width, the top inset above the row, and the floor that
-- keeps a very short toast from collapsing.
local TOAST_WIDTH = 233
local ROW_TOP_INSET = 17
local TOAST_MIN_HEIGHT = 40
-- Extra card height added below the row so a one-line toast is not cramped.
-- Applied in syncHeight only, so the row keeps its top alignment (the top
-- inset above the row and the row's own bottom padding stay untouched) and
-- the timer bar keeps a little breathing room under the description.
local TOAST_EXTRA_HEIGHT = 7
-- Header box. The title rides at the very top of the text column and is
-- followed by a 1px divider; its box is taller than the glyphs and
-- top-aligned, which lifts the title (level with the dismiss button) AND
-- pushes the divider -- plus everything below it -- down, so the title is no
-- longer jammed against the rule.
local HEADER_HEIGHT = 16
local HEADER_GAP = 10

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

-- Snapshot the decorations that CanvasGroup transparency does NOT cover
-- (UIStroke/UIShadow), so they can fade alongside the group.
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

-- The card's height is measured, not auto-sized. `row` keeps AutomaticSize.Y
-- but only holds offset-sized content, so it converges; the card copies it.
local function syncHeight(root, row)
	-- `row` already includes its own 12px bottom band (UIPadding.PaddingBottom),
	-- so the card only adds the top inset plus TOAST_EXTRA_HEIGHT.
	-- One-line alert ≈ 75px.
	local height = math.max(TOAST_MIN_HEIGHT, row.AbsoluteSize.Y + ROW_TOP_INSET + TOAST_EXTRA_HEIGHT)
	root.Size = UDim2.fromOffset(TOAST_WIDTH, height)
end

local ACCENT_KEY = {
	Alert = "NotificationAlertAccent",
	Error = "NotificationErrorAccent",
	Variable = "NotificationVariableAccent",
}

-- Per-type fallbacks: even if a theme is missing its Notification*Accent keys
-- the rim still colour-matches the toast (alert = orange, error = red,
-- variable = green) instead of every flavour sharing one colour.
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

-- Default icon per notification type, from the shared Icons module. These are
-- full-images (no ImageRect), so no rect offset/size is set.
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
	local title = Settings.Title or DEFAULT_TITLE[ntype] or "Notification"
	local description = Settings.Description or ""
	self.Duration = Settings.Duration or 5

	local accent = theme[ACCENT_KEY[ntype]] or FALLBACK_ACCENT[ntype] or FALLBACK_ACCENT.Alert
	local iconColor = Settings.IconColor or accent
	local washColor = Settings.GradientColor or accent

	-- Height is driven from the row below (see syncHeight), NOT by AutomaticSize.
	-- AutomaticSize measures children by AbsoluteSize, so the wash / background
	-- scale(1,1) frames measured against the very card they were sizing and the
	-- toast grew a little on every layout pass -- that is what made them far too
	-- tall once the aurora landed. X stays fixed at 233.
	local root = new("CanvasGroup", {
		Name = UUID.Generate("Toast"),
		ZIndex = 999,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		BackgroundColor3 = theme.NotificationBackgroundColor or Color3.fromRGB(16, 16, 17),
		BackgroundTransparency = theme.NotificationBackgroundTransparency or 0.1,
		-- NOT AutomaticSize: see syncHeight below. No ClipsDescendants here --
		-- it would also clip this card's own UIShadow glow. The wash and
		-- background already clip themselves to their own scale(1,1) frame.
		Size = UDim2.fromOffset(TOAST_WIDTH, TOAST_MIN_HEIGHT),
		BorderColor3 = Color3.fromRGB(41, 41, 41),
		LayoutOrder = 2,
		Parent = container,
	})
	self.Root = root

	-- NOTE: root deliberately has NO UIPadding -- it would inset the scale(1,1)
	-- wash/background and float the bottom timer bar. The row below uses
	-- absolute offsets instead (14 left, 30 right gutter for the dismiss).

	new("UICorner", { Parent = root, CornerRadius = UDim.new(0, 6) })
	-- Card-style chrome, colour-matched to the flavour: the stroke AND shadow
	-- take the per-type accent (alert = orange rim, error = red, variable =
	-- theme-derived). Theme keys only tune transparency now -- their neutral
	-- colours used to win over the accent and flattened every toast to one
	-- look. Stroke sits a touch more transparent than the theme cards' 0.55.
	local stroke = new("UIStroke", {
		Parent = root,
		Color = accent,
		Transparency = theme.NotificationStrokeTransparency or 0.65,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})

	-- Root accent shadow: the card's glow. Colour-matched to the flavour accent
	-- (ApplyTheme re-resolves it live); transparency from the theme key with a
	-- fixed fallback. It's a UIShadow under root, so captureFade() picks it up
	-- and the toast's own Show/Close fade carries it with the group.
	local shadow = new("UIShadow", {
		Parent = root,
		Color = accent,
		Transparency = theme.NotificationShadowTransparency or 0.45,
		BlurRadius = UDim.new(0, 18),
		Offset = UDim2.fromOffset(0, 6),
	})
	-- PageFade restores a decoration to its PageFadeBase; toasts live outside
	-- the window tree so PageFade never touches them, but stamp it so any
	-- FadeDecorations sweep that does reach here returns to the rest state.
	shadow:SetAttribute(UUID.Static("PageFadeBase"), shadow.Transparency)
	self._shadow = shadow

	-- Aurora wash replaces the old corner gradient: two low-opacity accent
	-- blooms clipped to the toast shape. Static, so it costs nothing at idle.
	-- ColorKey binds each bloom to the live theme accent so a theme switch
	-- repaints the wash in place (falls back to the static washColor when the
	-- caller overrode the gradient).
	local wash = Aurora.Wash(root, {
		Color = washColor,
		ColorKey = (Settings.GradientColor == nil) and ACCENT_KEY[ntype] or nil,
		CornerRadius = UDim.new(1, 1),
		Intensity = 0.1,
	})

	-- Optional sheen background image
	if Settings.ShowBackground then
		local bg = new("ImageLabel", {
			Name = UUID.Static("Background"),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			ImageTransparency = 0.5,
			-- Default to the active theme's wallpaper (falls back to the brand
			-- asset if the theme has none).
			Image = Settings.BackgroundImage or theme.Wallpaper or FallbackImage,
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			ZIndex = 0,
			Parent = root,
		})
		new("UICorner", { Parent = bg, CornerRadius = UDim.new(0, 6) })
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

	-- Row: icon beside a single in-flow text column. Every child uses offset
	-- sizes and UIListLayouts -- nothing is scale-positioned -- so this frame's
	-- AutomaticSize.Y converges deterministically and syncHeight can copy it
	-- straight onto the card: a one-line alert is ~65px tall and growth is
	-- linear with the description. (The old layout pinned the header/divider/
	-- icon at absolute offsets and stacked a 40px top offset on top, which is
	-- what made every toast long.) Absolute insets: 14px left margin, 30px
	-- right gutter for the dismiss button.
	local row = new("Frame", {
		Name = UUID.Static("Row"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -44, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(14, ROW_TOP_INSET),
		ZIndex = 2,
		Parent = root,
	})
	new("UIListLayout", {
		Parent = row,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
	})
	-- Bottom band: included in row's AutomaticSize.Y (unlike root UIPadding,
	-- which would break the wash), so the timer bar at the card's bottom edge
	-- never overlaps the description.
	new("UIPadding", { Parent = row, PaddingBottom = UDim.new(0, ROW_TOP_INSET) })

	-- Icon (full image from the Icons module; no rect offset/size)
	local icon = new("ImageLabel", {
		Name = UUID.Static("Icon"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ImageColor3 = iconColor,
		Size = UDim2.fromOffset(22, 22),
		LayoutOrder = 1,
		ZIndex = 2,
		Image = Settings.Icon or DEFAULT_ICON[ntype] or DEFAULT_ICON.Alert,
		Parent = row,
	})
	new("UIAspectRatioConstraint", { Parent = icon, DominantAxis = Enum.DominantAxis.Height })

	local col = new("Frame", {
		Name = UUID.Static("Column"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		-- Icon (22) + gap (10); the dismiss button sits outside the row at the
		-- card edge, so no extra reserve is needed here.
		Size = UDim2.new(1, -32, 0, 0),
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
		TextSize = ntype == "Variable" and 13 or 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTransparency = theme.NotificationHeaderTransparency or 0.3,
		TextColor3 = theme.NotificationHeaderColor or Color3.fromRGB(255, 255, 255),
		FontFace = Constants.Font(Enum.FontWeight.SemiBold),
		-- Top-aligned text in a box taller than the glyphs: the title sits at
		-- the card's top edge while HEADER_GAP becomes breathing room under it.
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT + HEADER_GAP),
		LayoutOrder = 1,
		ZIndex = 2,
		Text = title,
		Parent = col,
	})
	new("UIPadding", { Parent = header, PaddingBottom = UDim.new(0, 7) })
	-- Description
	local desc = new("TextLabel", {
		Name = UUID.Static("Description"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextWrapped = true,
		TextSize = 13,
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

	-- Interaction buttons (up to MAX_ACTIONS)
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
				Text = action.Text or "Click",
				LayoutOrder = i,
				ZIndex = 4,
				Parent = holder,
			})
			btn:SetAttribute(UUID.Static("ToastBaseBackground"), baseBg)
			new("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 4) })

			-- Button-component motion, 1:1: hover grows 1.02 (HoverIn), press
			-- dips 0.97 (Fast), click washes a PrimaryColor overlay in over
			-- 0.12s and back out over 0.5s — exactly Button's performClick.
			-- No hover/press background tint (Button has none) and the accent
			-- UIShadow bloom is deliberately left as-is.
			local btnScale = new("UIScale", { Parent = btn, Scale = 1 })

			-- Accent-tinted shadow (hidden at rest, blooms on hover).
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
				-- Button's click flash: overlay in over 0.12s, out over 0.5s.
				-- Rapid clicks restart it instead of locking (Button does the
				-- same via CancelAll).
				Tween.CancelAll(btnFlash)
				Tween.Play(btnFlash, "Click", { BackgroundTransparency = 0.15 })
				task.delay(0.12, function()
					if not btnFlash.Parent then
						return
					end
					Tween.Play(btnFlash, "Release", { BackgroundTransparency = 1 })
				end)
				-- Callback fires immediately (Button never blocks behaviour);
				-- the toast exits just after the flash-in lands. Close is
				-- guarded by _closing, so the timer race is harmless.
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

	-- Dismiss button (full image from the Icons module; no rect offset/size)
	local dismiss = new("ImageButton", {
		Name = UUID.Static("DismissButton"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ImageTransparency = 0.5,
		Image = CLOSE_ICON,
		ImageColor3 = theme.NotificationDismissColor or Color3.fromRGB(255, 255, 255),
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0), -- right-pinned: hover growth extends into the gutter, not past the card edge
		Position = UDim2.new(1, -12, 0, 15), -- 30px gutter right of the row, aligned with the header line
		ZIndex = 3,
		Parent = root,
	})
	new("UIAspectRatioConstraint", { Parent = dismiss, DominantAxis = Enum.DominantAxis.Height })

	-- Hover brightens + scales the close icon; press shrinks it for feedback.
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

	-- Timer bar
	self.TimerFrame = new("Frame", {
		Name = UUID.Static("TimerFrame"),
		BorderSizePixel = 0,
		BackgroundColor3 = accent,
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.new(0.7, 0, 0, 2),
		Position = UDim2.fromScale(0.5, 0.97),
		ZIndex = 3,
		Parent = root,
	})

	self._fadeTargets = captureFade(root)
	self._shown = false
	self._closing = false

	-- Theme context retained so ApplyTheme can recolor a toast that is already
	-- on screen when the theme changes (toasts live outside the window tree,
	-- so ThemeManager's own pass never reaches them).
	self._type = ntype
	self._accent = accent
	self._iconOverride = Settings.IconColor
	self._washOverride = Settings.GradientColor
	self._wash = wash
	self._stroke = stroke
	self._header = header
	self._icon = icon
	self._desc = desc
	self._dismiss = dismiss

	-- Height: the row measures its own content (wrapped description, optional
	-- action buttons) and the card copies that. Re-running on AbsoluteSize
	-- covers text reflow after font/theme swaps as well as the initial pass.
	syncHeight(root, row)
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if root.Parent then
			syncHeight(root, row)
		end
	end)

	return self
end

-- Live theme switch: re-resolve this toast's themed properties in place so an
-- open notification crossfades with the rest of the UI instead of being
-- destroyed and rebuilt (which is what Window:SetTheme does to popups that
-- lack ApplyTheme).
function Notification:ApplyTheme(themeInput)
	if not self.Root then
		return
	end
	local theme = ThemeManager.GetTheme(themeInput)
	local accent = theme[ACCENT_KEY[self._type]] or FALLBACK_ACCENT[self._type] or self._accent
	self._accent = accent
	local iconColor = self._iconOverride or accent
	local washColor = self._washOverride or accent

	self.Root.BackgroundColor3 = theme.NotificationBackgroundColor or self.Root.BackgroundColor3
	self.Root.BackgroundTransparency = theme.NotificationBackgroundTransparency or self.Root.BackgroundTransparency

	-- Colour-matched card chrome: rim and glow follow the flavour accent, so
	-- alerts glow amber, errors red, toasts green. Theme keys only tune
	-- transparency now -- their neutral colours used to win the `or` and
	-- flattened every flavour to one look.
	self._shadow.Color = accent
	if theme.NotificationShadowTransparency then
		self._shadow.Transparency = theme.NotificationShadowTransparency
	end
	self._stroke.Color = accent
	self._stroke.Transparency = theme.NotificationStrokeTransparency or 0.65
	if self._wash then
		self._wash:SetColor(washColor)
	end

	-- Wallpaper is an asset id, so it is not a color binding. Re-stamp it on
	-- every switch so an open toast follows the live theme.
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

	if self._icon then
		self._icon.ImageColor3 = iconColor
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
		-- No hover tint any more (Button-style); bg stays at its base.
		button.BackgroundColor3 = baseBg
		button.TextColor3 = buttonText
		if entry.flash then
			entry.flash.BackgroundColor3 = theme.PrimaryColor or accent
			entry.flash.BackgroundTransparency = 1
		end
		entry.shadow.Color = accent
	end

	self.TimerFrame.BackgroundColor3 = accent
	if self._dismiss then
		self._dismiss.ImageColor3 = theme.NotificationDismissColor or self._dismiss.ImageColor3
	end
	self:_resumeTimer()
end

function Notification:_startTimer()
	self._timerStarted = os.clock()
	self._timerTween = Tween.Play(
		self.TimerFrame,
		TweenInfo.new(self.Duration, Enum.EasingStyle.Linear),
		{ Size = UDim2.fromOffset(0, 2) }
	)
end

-- A theme switch cancels every tween under the ScreenGui, including this
-- bar's. Pick it back up from wherever the sweep left it.
function Notification:_resumeTimer()
	if self._closing or not self._timerStarted then
		return
	end
	local remaining = self.Duration - (os.clock() - self._timerStarted)
	if remaining <= 0 then
		return
	end
	self._timerTween = Tween.Play(
		self.TimerFrame,
		TweenInfo.new(remaining, Enum.EasingStyle.Linear),
		{ Size = UDim2.fromOffset(0, 2) }
	)
end

function Notification:Show()
	if self._shown then
		return self
	end
	self._shown = true
	Sound.Play("Notification")
	setAll(self._fadeTargets, 1)
	self.Root.Visible = true
	self.Root.GroupTransparency = 1
	Tween.Play(
		self.Root,
		TweenInfo.new(FADE_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = 0 }
	)
	tweenAll(self._fadeTargets, nil, FADE_IN)
	self:_startTimer()
	self._dismissTask = task.delay(self.Duration, function()
		-- Clear the handle first: Close() cancels _dismissTask, and cancelling
		-- the thread we're currently running on would abort before the
		-- destroy step below is scheduled.
		self._dismissTask = nil
		self:Close()
	end)
	return self
end

function Notification:Close()
	if self._closing then
		return
	end
	self._closing = true
	if self._timerTween then
		Tween.Cancel(self._timerTween)
		self._timerTween = nil
	end
	if self._dismissTask then
		task.cancel(self._dismissTask)
		self._dismissTask = nil
	end
	tweenAll(self._fadeTargets, 1, FADE_OUT)
	Tween.Play(
		self.Root,
		TweenInfo.new(FADE_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = 1 }
	)
	task.delay(FADE_OUT, function()
		if self.Root then
			self.Root:Destroy()
			self.Root = nil
		end
	end)
end

return Notification
