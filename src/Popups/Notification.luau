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

local ACCENT_KEY = {
	Alert = "NotificationAlertAccent",
	Error = "NotificationErrorAccent",
	Variable = "NotificationVariableAccent",
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

	local accent = theme[ACCENT_KEY[ntype] or "NotificationAlertAccent"] or Color3.fromRGB(96, 165, 250)
	local iconColor = Settings.IconColor or accent
	local washColor = Settings.GradientColor or accent

	-- AutomaticSize.Y hugs the content: a nonzero base height would be pinned
	-- by the wash's scale(1,1) frame below, so short toasts stay bulky. X stays
	-- fixed; the wash and background resolve their scale sizes against the
	-- converged height each layout pass.
	local root = new("CanvasGroup", {
		Name = UUID.Generate("Toast"),
		ZIndex = 999,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		BackgroundColor3 = theme.NotificationBackgroundColor or Color3.fromRGB(16, 16, 17),
		BackgroundTransparency = theme.NotificationBackgroundTransparency or 0.1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromOffset(233, 0),
		BorderColor3 = Color3.fromRGB(41, 41, 41),
		LayoutOrder = 2,
		Parent = container,
	})
	self.Root = root

	new("UICorner", { Parent = root, CornerRadius = UDim.new(0, 6) })
	-- Card-style chrome: accent-tinted stroke + shadow like the theme cards'
	-- makeCard (stroke 0.55 there), but the stroke sits slightly more
	-- transparent here so stacked toasts don't read as heavy. Theme keys still
	-- override both.
	local shadow = new("UIShadow", {
		Parent = root,
		Color = theme.NotificationShadowColor or accent,
		BlurRadius = UDim.new(0, 18),
		Offset = UDim2.fromOffset(0, 6),
		Transparency = theme.NotificationShadowTransparency or 0.45,
	})
	local stroke = new("UIStroke", {
		Parent = root,
		Color = theme.NotificationStrokeColor or accent,
		Transparency = theme.NotificationStrokeTransparency or 0.65,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})

	-- Aurora wash replaces the old corner gradient: two low-opacity accent
	-- blooms clipped to the toast shape. Static, so it costs nothing at idle.
	local wash = Aurora.Wash(root, {
		Color = washColor,
		CornerRadius = UDim.new(0, 6),
		Intensity = 0.9,
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

	-- Header + divider
	local header = new("TextLabel", {
		Name = UUID.Static("Header"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextSize = ntype == "Variable" and 13 or 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = theme.NotificationHeaderTransparency or 0.3,
		TextColor3 = theme.NotificationHeaderColor or Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.X,
		FontFace = Constants.Font(Enum.FontWeight.SemiBold),
		Size = UDim2.fromOffset(0, 14),
		Position = UDim2.fromOffset(42, 11),
		ZIndex = 2,
		Text = title,
		Parent = root,
	})
	local divider = new("Frame", {
		Name = UUID.Static("Divider"),
		BorderSizePixel = 0,
		BackgroundColor3 = theme.NotificationDividerColor or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = theme.NotificationDividerTransparency or 0.7,
		Size = UDim2.new(0.7, 0, 0, 1),
		Position = UDim2.fromOffset(0, 22),
		ZIndex = 3,
		Parent = header,
	})

	-- Icon (full image from the Icons module; no rect offset/size)
	local icon = new("ImageLabel", {
		Name = UUID.Static("Icon"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ImageColor3 = iconColor,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Image = Settings.Icon or DEFAULT_ICON[ntype] or DEFAULT_ICON.Alert,
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.fromOffset(21, 24),
		ZIndex = 2,
		Parent = root,
	})
	new("UIAspectRatioConstraint", { Parent = icon, DominantAxis = Enum.DominantAxis.Height })

	-- Body column: the description and the optional action row stack in flow
	-- (UIListLayout) inside one auto-sizing frame. Positioning the action row
	-- by scale inside an auto-sizing parent used to diverge -- each pass grew
	-- the parent, which pushed the row further down -- so neither child may be
	-- scale-positioned here.
	local body = new("Frame", {
		Name = UUID.Static("Body"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.68, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(42, 40),
		ZIndex = 2,
		Parent = root,
	})
	new("UIListLayout", {
		Parent = body,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	new("UIPadding", {
		Parent = body,
		PaddingTop = (ntype == "Variable") and UDim.new(0, 5) or UDim.new(0, 0),
		PaddingBottom = UDim.new(0, 15),
	})

	-- Description
	local desc = new("TextLabel", {
		Name = UUID.Static("Description"),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextWrapped = true,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTransparency = theme.NotificationTextTransparency or 0.5,
		TextColor3 = theme.NotificationTextColor or Color3.fromRGB(255, 255, 255),
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		ZIndex = 2,
		Text = description,
		Parent = body,
	})

	-- Interaction buttons (up to MAX_ACTIONS)
	local actions = Settings.Actions or {}
	self._actions = {}
	if #actions > 0 then
		local holder = new("Frame", {
			Name = UUID.Static("InterractionHolder"),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = 2,
			ZIndex = 3,
			Parent = body,
		})
		new("UIListLayout", {
			Parent = holder,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
		})
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
			btn:SetAttribute("ToastBaseBackground", baseBg)
			new("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 4) })

			-- Accent-tinted shadow (hidden at rest, blooms on hover).
			local btnShadow = new("UIShadow", {
				Color = accent,
				Transparency = 1,
				BlurRadius = UDim.new(0, 12),
				Parent = btn,
			})

			local function baseColor()
				return btn:GetAttribute("ToastBaseBackground") or baseBg
			end
			local function hoverColor()
				return baseColor():Lerp(Color3.fromRGB(255, 255, 255), 0.18)
			end
			local function tween(prop, dur)
				Tween.Play(btn, TweenInfo.new(dur or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), prop)
			end
			btn.MouseEnter:Connect(function()
				btn:SetAttribute("ToastHovered", true)
				tween({ BackgroundColor3 = hoverColor() })
				Tween.Play(btnShadow, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Transparency = 0.4 })
			end)
			btn.MouseLeave:Connect(function()
				btn:SetAttribute("ToastHovered", false)
				tween({ BackgroundColor3 = baseColor() })
				Tween.Play(btnShadow, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Transparency = 1 })
			end)
			-- Pressed state: darken briefly for a tactile click feel.
			btn.MouseButton1Down:Connect(function()
				tween({ BackgroundColor3 = baseColor():Lerp(Color3.fromRGB(0, 0, 0), 0.25) }, 0.08)
			end)
			btn.MouseButton1Up:Connect(function()
				tween({ BackgroundColor3 = hoverColor() }, 0.08)
			end)

			btn.MouseButton1Click:Connect(function()
				if action.Callback then
					action.Callback(self)
				end
				self:Close()
			end)

			table.insert(self._actions, { button = btn, shadow = btnShadow })
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
		Position = UDim2.fromScale(0.888, 0.13),
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
	self._shadow = shadow
	self._stroke = stroke
	self._header = header
	self._divider = divider
	self._icon = icon
	self._desc = desc
	self._dismiss = dismiss

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
	local accent = theme[ACCENT_KEY[self._type] or "NotificationAlertAccent"] or self._accent
	self._accent = accent
	local iconColor = self._iconOverride or accent
	local washColor = self._washOverride or accent

	self.Root.BackgroundColor3 = theme.NotificationBackgroundColor or self.Root.BackgroundColor3
	self.Root.BackgroundTransparency = theme.NotificationBackgroundTransparency or self.Root.BackgroundTransparency

	-- Accent-tinted, card-style chrome; theme keys override the tint.
	self._shadow.Color = theme.NotificationShadowColor or accent
	if theme.NotificationShadowTransparency then
		self._shadow.Transparency = theme.NotificationShadowTransparency
	end
	self._stroke.Color = theme.NotificationStrokeColor or accent
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
	if self._divider then
		if theme.NotificationDividerColor then
			self._divider.BackgroundColor3 = theme.NotificationDividerColor
		end
		if theme.NotificationDividerTransparency then
			self._divider.BackgroundTransparency = theme.NotificationDividerTransparency
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
		button:SetAttribute("ToastBaseBackground", baseBg)
		button.BackgroundColor3 = button:GetAttribute("ToastHovered")
				and baseBg:Lerp(Color3.fromRGB(255, 255, 255), 0.18)
			or baseBg
		button.TextColor3 = buttonText
		entry.shadow.Color = accent
	end

	self.TimerFrame.BackgroundColor3 = accent
	if self._dismiss then
		self._dismiss.ImageColor3 = theme.NotificationDismissColor or self._dismiss.ImageColor3
	end
end

function Notification:_startTimer()
	self._timerTween = Tween.Play(
		self.TimerFrame,
		TweenInfo.new(self.Duration, Enum.EasingStyle.Linear),
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
