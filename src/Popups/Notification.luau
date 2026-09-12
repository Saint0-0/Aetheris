--[[
	Notification  ·  Aetheris UI Library

	Self-destroying toast notifications in three flavours:
	  Alert    - informational (amber accent)
	  Error    - error (red accent)
	  Variable - success/custom (green accent by default); supports a custom
	             icon, icon/gradient colours, an optional background image,
	             and up to MAX_ACTIONS interaction buttons with callbacks.

	Create via window:Alert() / window:Error() / window:VariableNotification().
	Each toast builds itself, fades in, counts down via TimerFrame, then fades
	out and :Destroy()s itself to avoid leaking memory.
]]

local Tween = require("../Utils/Tween")
local ThemeManager = require("../Themes/ThemeManager")
local FallbackImage = require("../Constants").FallbackImage
local Icons = require("../Assets/Icons")
local Sound = require("../Utils/Sound")

local Notification = {}
Notification.__index = Notification

local MAX_ACTIONS = 2
local FADE_IN = 0.25
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

-- Snapshot every transparency in the notification so it can be faded as a
-- whole (set all to 1 = invisible, tween back to base = visible).
local function captureFade(root)
	local targets = {}
	local function scan(inst)
		if inst:IsA("GuiObject") then
			for _, p in ipairs({ "BackgroundTransparency", "TextTransparency", "ImageTransparency" }) do
				local ok, v = pcall(function() return inst[p] end)
				if ok and type(v) == "number" then
					table.insert(targets, { inst, p, v })
				end
			end
		end
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
		Tween.Play(
			t[1],
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ [t[2]] = target }
		)
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
	local gradientColor = Settings.GradientColor or accent

	local root = new("Frame", {
		Name = ntype .. "Notification",
		ZIndex = 999,
		BorderSizePixel = 0,
		BackgroundColor3 = theme.NotificationBackgroundColor or Color3.fromRGB(16, 16, 17),
		BackgroundTransparency = theme.NotificationBackgroundTransparency or 0.1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(0, 233, 0, ntype == "Variable" and 118 or 92),
		BorderColor3 = Color3.fromRGB(41, 41, 41),
		LayoutOrder = 2,
		Parent = container,
	})
	self.Root = root

	new("UICorner", { Parent = root, CornerRadius = UDim.new(0, 6) })
	new("UIShadow", { Parent = root, Color = theme.NotificationShadowColor or Color3.fromRGB(0, 0, 0) })

	-- Gradient glow (behind the content)
	local grad = new("Frame", {
		Name = "GradientBackground",
		BorderSizePixel = 0,
		BackgroundColor3 = gradientColor,
		BackgroundTransparency = 0.65,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, 0, 0.5, 0),
		Position = UDim2.new(0.5, 0, 0.25, 0),
		ZIndex = 0,
		Parent = root,
	})
	new("UICorner", { Parent = grad, CornerRadius = UDim.new(0, 6) })
	new("UIGradient", {
		Parent = grad,
		Rotation = 270,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.000, 1),
			NumberSequenceKeypoint.new(0.297, 1),
			NumberSequenceKeypoint.new(0.531, 1),
			NumberSequenceKeypoint.new(0.712, 0.93125),
			NumberSequenceKeypoint.new(0.825, 0.8625),
			NumberSequenceKeypoint.new(0.881, 0.7875),
			NumberSequenceKeypoint.new(0.921, 0.69375),
			NumberSequenceKeypoint.new(0.952, 0.6),
			NumberSequenceKeypoint.new(0.975, 0.5),
			NumberSequenceKeypoint.new(1.000, 0.39375),
		}),
	})

	-- Optional sheen background image
	if Settings.ShowBackground then
		local bg = new("ImageLabel", {
			Name = "Background",
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			ImageTransparency = 0.5,
			-- Default to the active theme's wallpaper (falls back to the brand
			-- asset if the theme has none).
			Image = Settings.BackgroundImage or theme.Wallpaper or FallbackImage,
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			ZIndex = 0,
			Parent = root,
		})
		new("UICorner", { Parent = bg, CornerRadius = UDim.new(0, 6) })
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
		Name = "Header",
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextSize = ntype == "Variable" and 13 or 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = theme.NotificationHeaderTransparency or 0.3,
		TextColor3 = theme.NotificationHeaderColor or Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.X,
		FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		Size = UDim2.new(0, 0, 0, 14),
		Position = UDim2.new(0, 42, 0, 11),
		ZIndex = 2,
		Text = title,
		Parent = root,
	})
	new("Frame", {
		Name = "Divider",
		BorderSizePixel = 0,
		BackgroundColor3 = theme.NotificationDividerColor or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = theme.NotificationDividerTransparency or 0.7,
		Size = UDim2.new(0.7, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 22),
		ZIndex = 3,
		Parent = header,
	})

	-- Icon (full image from the Icons module; no rect offset/size)
	local icon = new("ImageLabel", {
		Name = "Icon",
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ImageColor3 = iconColor,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Image = Settings.Icon or DEFAULT_ICON[ntype] or DEFAULT_ICON.Alert,
		Size = UDim2.new(0, 22, 0, 22),
		Position = UDim2.new(0, 21, 0, 24),
		ZIndex = 2,
		Parent = root,
	})
	new("UIAspectRatioConstraint", { Parent = icon, DominantAxis = Enum.DominantAxis.Height })

	-- Description
	local desc = new("TextLabel", {
		Name = "Description",
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextWrapped = true,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTransparency = theme.NotificationTextTransparency or 0.5,
		TextColor3 = theme.NotificationTextColor or Color3.fromRGB(255, 255, 255),
		FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		Size = UDim2.new(0.68, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 42, 0, 40),
		ZIndex = 2,
		Text = description,
		Parent = root,
	})
	new("UIPadding", {
		Parent = desc,
		PaddingTop = (ntype == "Variable") and UDim.new(0, 5) or UDim.new(0, 0),
		PaddingBottom = UDim.new(0, (ntype == "Variable") and 45 or 15),
	})

	-- Interaction buttons (up to MAX_ACTIONS)
	local actions = Settings.Actions or {}
	if #actions > 0 then
		local holder = new("Frame", {
			Name = "InterractionHolder",
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 1.25, 0),
			ZIndex = 3,
			Parent = desc,
		})
		new("UIListLayout", {
			Parent = holder,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
		})
		local baseBg = theme.NotificationActionButtonColor or Color3.fromRGB(81, 81, 81)
		-- A slightly brighter variant for the hover state.
		local hoverBg = baseBg:Lerp(Color3.fromRGB(255, 255, 255), 0.18)
		for i = 1, math.min(#actions, MAX_ACTIONS) do
			local action = actions[i]
			local btn = new("TextButton", {
				Name = "Interraction",
				BorderSizePixel = 0,
				AutoButtonColor = false,
				TextSize = 12,
				TextColor3 = theme.NotificationActionButtonTextColor or Color3.fromRGB(255, 255, 255),
				BackgroundColor3 = baseBg,
				FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Size = UDim2.new(0, 60, 0, 20),
				Text = action.Text or "Click",
				LayoutOrder = i,
				ZIndex = 4,
				Parent = holder,
			})
			new("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 4) })

			-- Accent-tinted shadow (hidden at rest, blooms on hover).
			local btnShadow = new("UIShadow", {
				Color = accent,
				Transparency = 1,
				BlurRadius = UDim.new(0, 12),
				Parent = btn,
			})

			local function tween(prop, target, dur)
				Tween.Play(
					btn,
					TweenInfo.new(dur or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					prop
				)
			end
			btn.MouseEnter:Connect(function()
				tween({ BackgroundColor3 = hoverBg })
				Tween.Play(btnShadow, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Transparency = 0.4 })
			end)
			btn.MouseLeave:Connect(function()
				tween({ BackgroundColor3 = baseBg })
				Tween.Play(btnShadow, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Transparency = 1 })
			end)
			-- Pressed state: darken briefly for a tactile click feel.
			btn.MouseButton1Down:Connect(function()
				tween({ BackgroundColor3 = baseBg:Lerp(Color3.fromRGB(0, 0, 0), 0.25) }, 0.08)
			end)
			btn.MouseButton1Up:Connect(function()
				tween({ BackgroundColor3 = hoverBg }, 0.08)
			end)

			btn.MouseButton1Click:Connect(function()
				if action.Callback then
					action.Callback(self)
				end
				self:Close()
			end)
		end
	end

	-- Dismiss button (full image from the Icons module; no rect offset/size)
	local dismiss = new("ImageButton", {
		Name = "DismissButton",
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ImageTransparency = 0.5,
		Image = CLOSE_ICON,
		ImageColor3 = theme.NotificationDismissColor or Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(0.888, 0, 0.13, 0),
		ZIndex = 3,
		Parent = root,
	})
	new("UIAspectRatioConstraint", { Parent = dismiss, DominantAxis = Enum.DominantAxis.Height })

	-- Hover brightens + scales the close icon; press shrinks it for feedback.
	local function dismissTween(prop, dur)
		Tween.Play(
			dismiss,
			TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			prop
		)
	end
	dismiss.MouseEnter:Connect(function()
		dismissTween({ ImageTransparency = 0.1, Size = UDim2.new(0, 18, 0, 18) })
	end)
	dismiss.MouseLeave:Connect(function()
		dismissTween({ ImageTransparency = 0.5, Size = UDim2.new(0, 16, 0, 16) })
	end)
	dismiss.MouseButton1Down:Connect(function()
		dismissTween({ Size = UDim2.new(0, 14, 0, 14) }, 0.08)
	end)
	dismiss.MouseButton1Up:Connect(function()
		dismissTween({ Size = UDim2.new(0, 18, 0, 18) }, 0.08)
	end)
	dismiss.MouseButton1Click:Connect(function()
		self:Close()
	end)

	-- Timer bar
	self.TimerFrame = new("Frame", {
		Name = "TimerFrame",
		BorderSizePixel = 0,
		BackgroundColor3 = accent,
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.new(0.7, 0, 0, 2),
		Position = UDim2.new(0.5, 0, 0.97, 0),
		ZIndex = 3,
		Parent = root,
	})

	self._fadeTargets = captureFade(root)
	self._shown = false
	self._closing = false

	return self
end

function Notification:_startTimer()
	self._timerTween = Tween.Play(
		self.TimerFrame,
		TweenInfo.new(self.Duration, Enum.EasingStyle.Linear),
		{ Size = UDim2.new(0, 0, 0, 2) }
	)
end

function Notification:Show()
	if self._shown then return self end
	self._shown = true
	Sound.Play("Notification")
	setAll(self._fadeTargets, 1)
	self.Root.Visible = true
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
	if self._closing then return end
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
	task.delay(FADE_OUT, function()
		if self.Root then
			self.Root:Destroy()
			self.Root = nil
		end
	end)
end

return Notification