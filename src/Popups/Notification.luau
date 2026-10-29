--[[
	Aetheris/Popups/Notification.luau

	Self-destroying toast notifications in three flavours: Alert (amber),
	Error (red), and Variable (green; custom icon, colours, background image
	and up to MAX_ACTIONS action buttons). Created via window:Alert() /
	window:Error() / window:Toast(); each toast fades in, counts down via
	TimerFrame, then fades out and destroys itself.

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

local Notification = {}
Notification.__index = Notification

local MAX_ACTIONS = 2
local FADE_IN = 0.2
local FADE_OUT = 0.2

-- Card geometry: height derives from the row's content via syncHeight, so these are the only fixed numbers.
local TOAST_WIDTH = 233
local ROW_TOP_INSET = 17
local TOAST_MIN_HEIGHT = 40
-- Extra height below the row so a one-line toast isn't cramped; applied in syncHeight only.
local TOAST_EXTRA_HEIGHT = 7
-- Top-aligned title box taller than the glyphs, so the title sits level with the dismiss button and clears the divider.
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

-- Height is measured from the row (which converges on offset content), not auto-sized.
local function syncHeight(root, row)
	local height = math.max(TOAST_MIN_HEIGHT, row.AbsoluteSize.Y + ROW_TOP_INSET + TOAST_EXTRA_HEIGHT)
	root.Size = UDim2.fromOffset(TOAST_WIDTH, height)
end

local ACCENT_KEY = {
	Alert = "NotificationAlertAccent",
	Error = "NotificationErrorAccent",
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
	local title = Settings.Title or DEFAULT_TITLE[ntype] or "Notification"
	local description = Settings.Description or ""
	self.Duration = Settings.Duration or 5

	local accent = theme[ACCENT_KEY[ntype]] or FALLBACK_ACCENT[ntype] or FALLBACK_ACCENT.Alert
	local iconColor = Settings.IconColor or accent
	local washColor = Settings.GradientColor or accent

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

	-- Root has no UIPadding: it would inset the scale(1,1) wash and float the timer bar; the row below uses absolute offsets.
	new("UICorner", { Parent = root, CornerRadius = UDim.new(0, 6) })
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
		ColorKey = (Settings.GradientColor == nil) and ACCENT_KEY[ntype] or nil,
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

	-- Icon beside one in-flow text column; all-offset children so AutomaticSize.Y converges and syncHeight can copy it (14px left margin, 30px right gutter for the dismiss).
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
	-- Bottom band rides in the row's AutomaticSize.Y (root UIPadding would break the wash), so the timer bar clears the description.
	new("UIPadding", { Parent = row, PaddingBottom = UDim.new(0, ROW_TOP_INSET) })

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
		-- Icon (22) + gap (10); the dismiss button sits outside the row, so no extra reserve.
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
		-- Top-aligned in a taller box: the title rides the card's top edge and HEADER_GAP becomes room under it.
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT + HEADER_GAP),
		LayoutOrder = 1,
		ZIndex = 2,
		Text = title,
		Parent = col,
	})
	new("UIPadding", { Parent = header, PaddingBottom = UDim.new(0, 7) })
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

	-- Right-pinned so hover growth extends into the gutter, aligned with the header line.
	local dismiss = new("ImageButton", {
		Name = UUID.Static("DismissButton"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ImageTransparency = 0.5,
		Image = CLOSE_ICON,
		ImageColor3 = theme.NotificationDismissColor or Color3.fromRGB(255, 255, 255),
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 15),
		ZIndex = 3,
		Parent = root,
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

	-- Retained so ApplyTheme can recolour a toast already on screen (toasts live outside the window tree).
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

	-- Re-sync on reflow so text changes and font/theme swaps resize the card too.
	syncHeight(root, row)
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if root.Parent then
			syncHeight(root, row)
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
	local accent = theme[ACCENT_KEY[self._type]] or FALLBACK_ACCENT[self._type] or self._accent
	self._accent = accent
	local iconColor = self._iconOverride or accent
	local washColor = self._washOverride or accent

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

-- A theme switch cancels every tween under the ScreenGui; pick the bar back up from wherever the sweep left it.
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
		-- Clear the handle first: Close() cancels _dismissTask, and cancelling this running thread would abort before the destroy step below is scheduled.
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
