--[[
	UINotification  ·  Aetheris UI Library

	Modal dialog with confirm/cancel buttons. Open via window:UINotification().
	Descriptions support RichText; colours are emitted as hex (Roblox RichText
	rejects rgb()).

	Usage:
		window:UINotification({
			Title = "Confirm Action",
			Description = "Are you sure?",
			TitleColor = Color3.fromRGB(255, 255, 255),
			ConfirmText = "Confirm",
			CancelText = "Cancel",
			OnConfirm = function() end,
			OnCancel = function() end,
		})
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local Sound = require("../Utils/Sound")
local UINotification = {}
UINotification.__index = UINotification
local function colorToString(color)
	-- Roblox RichText accepts hex (#RRGGBB) or named colors, NOT rgb(...).
	if typeof(color) == "string" then
		return color
	elseif typeof(color) == "Color3" then
		return string.format(
			"#%02X%02X%02X",
			math.round(color.R * 255),
			math.round(color.G * 255),
			math.round(color.B * 255)
		)
	end
	return "#FFFFFF"
end
function UINotification.new(parent, Settings)
	-- Safety: ensure Settings is a table
	if type(Settings) ~= "table" then
		warn("[UINotification] Settings is not a table, defaulting to empty table")
		Settings = {}
	end
	local self = setmetatable({}, UINotification)
	local theme = Settings.Theme
	local title = Settings.Title or "Notification"
	local description = Settings.Description or ""
	local titleColor =
		Settings.TitleColor
		or (theme and theme.TitleTextColor)
		or Color3.fromRGB(255, 255, 255)
	local confirmText = Settings.ConfirmText or "Confirm"
	local cancelText = Settings.CancelText or "Cancel"
	local onConfirm = Settings.OnConfirm or function() end
	local onCancel = Settings.OnCancel or function() end
	self.IsOpen = false
	self._resolved = false
	----------------------------------------------------------------
	-- SCRIM
	----------------------------------------------------------------
	local scrim = Instance.new("ImageButton")
	scrim.Name = "UINotification"
	scrim.Image = "rbxassetid://9313765853"
	scrim.ImageColor3 = Color3.fromRGB(0, 0, 0)
	scrim.BackgroundTransparency = 1
	scrim.ImageTransparency = 1
	scrim.BorderSizePixel = 0
	scrim.Size = UDim2.new(1, 0, 1, 0)
	scrim.Position = UDim2.new(0, 0, 0, 0)
	scrim.AutoButtonColor = false
	scrim.Visible = false
	scrim.ZIndex = 10
	scrim.Parent = parent
	----------------------------------------------------------------
	-- POPUP
	----------------------------------------------------------------
	local popup = Instance.new("Frame")
	popup.Name = "NotificationPopup"
	popup.BorderSizePixel = 0
	popup.BackgroundColor3 = (theme and theme.PopupBackgroundColor)
	popup.BackgroundTransparency = (theme and theme.PopupBackgroundTransparency) or 1
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.AutomaticSize = Enum.AutomaticSize.Y
	popup.Size = UDim2.new(0.611, 0, 0, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	popup.Visible = false
	popup.ZIndex = 11
	popup.Parent = scrim
	----------------------------------------------------------------
	-- SHADOW
	----------------------------------------------------------------
	local shadow = Instance.new("UIShadow")
	shadow.BlurRadius = UDim.new(0, 20)
	shadow.Transparency = 1
	shadow.Color = (theme and theme.PopupShadowColor)
	shadow.Parent = popup
	----------------------------------------------------------------
	-- CORNER
	----------------------------------------------------------------
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = popup
	----------------------------------------------------------------
	-- SIZE CONSTRAINT
	----------------------------------------------------------------
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(320, 277)
	sizeConstraint.MaxSize = Vector2.new(320, 336)
	sizeConstraint.Parent = popup
	----------------------------------------------------------------
	-- HEADER
	----------------------------------------------------------------
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.BorderSizePixel = 0
	header.TextSize = 16
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextTransparency = (theme and theme.PopupTextTransparency) or 0.4
	header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	header.BackgroundTransparency = 1
	header.FontFace = Font.new(
		"rbxassetid://12187365364",
		Enum.FontWeight.SemiBold,
		Enum.FontStyle.Normal
	)
	header.RichText = true
	header.AnchorPoint = Vector2.new(0.5, 0.5)
	header.Size = UDim2.new(0.26291, 0, 0.03775, 0)
	header.AutomaticSize = Enum.AutomaticSize.X
	header.Position = UDim2.new(0.5, 0, 0, 25)
	header.TextColor3 = (theme and theme.PopupTextColor)
	header.Parent = popup
	header.Text = string.format(
		'<font color="%s">%s</font>',
		colorToString(titleColor),
		title
	)
	----------------------------------------------------------------
	-- DESCRIPTION
	----------------------------------------------------------------
	local notifText = Instance.new("TextLabel")
	notifText.Name = "NotificationText"
	notifText.TextWrapped = true
	notifText.BorderSizePixel = 0
	notifText.TextSize = 14
	notifText.TextTransparency = (theme and theme.PopupTextTransparency) or 0.45
	notifText.BackgroundTransparency = 1
	notifText.FontFace = Font.new(
		"rbxassetid://12187365364",
		Enum.FontWeight.Medium,
		Enum.FontStyle.Normal
	)
	notifText.TextColor3 = (theme and theme.PopupTextColor)
	notifText.RichText = true
	notifText.AnchorPoint = Vector2.new(0.5, 0.5)
	notifText.Size = UDim2.new(0.91, 0, 0.1358, 0)
	notifText.AutomaticSize = Enum.AutomaticSize.Y
	notifText.Position = UDim2.new(0.5, 0, 0.4, 0)
	notifText.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	notifText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	notifText.Text = description
	notifText.ZIndex = 12
	notifText.Parent = popup
	local notifPadding = Instance.new("UIPadding")
	notifPadding.PaddingBottom = UDim.new(0, 15)
	notifPadding.Parent = notifText
	----------------------------------------------------------------
	-- DIVIDER
	----------------------------------------------------------------
	local divider = Instance.new("Frame")
	divider.Name = "ComponentDivider"
	divider.BorderSizePixel = 0
	divider.BackgroundColor3 = (theme and theme.AccentColor)
	divider.BackgroundTransparency = 0.9
	divider.AnchorPoint = Vector2.new(0.5, 0.5)
	divider.Size = UDim2.new(0.8, 0, 0, 1)
	divider.Position = UDim2.new(0.5, 0, 1.7, 0)
	divider.ZIndex = 12
	divider.Parent = notifText
	----------------------------------------------------------------
	-- INTERACTIONS
	----------------------------------------------------------------
	local interactions = Instance.new("Frame")
	interactions.Name = "Interactions"
	interactions.BorderSizePixel = 0
	interactions.BackgroundTransparency = 1
	interactions.AnchorPoint = Vector2.new(0.5, 0.5)
	interactions.Size = UDim2.new(0.9375, 0, 0.20291, 0)
	interactions.Position = UDim2.new(0.5, 0, 0.87569, 0)
	interactions.ZIndex = 12
	interactions.Parent = popup
	----------------------------------------------------------------
	-- CONFIRM BUTTON
	----------------------------------------------------------------
	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Name = "Confirm"
	confirmBtn.BorderSizePixel = 0
	confirmBtn.TextTransparency = (theme and theme.PopupTextTransparency) or 0.2
	confirmBtn.TextSize = 12
	confirmBtn.AutoButtonColor = false
	confirmBtn.TextColor3 = (theme and theme.PopupTextColor)
	confirmBtn.BackgroundColor3 = (theme and theme.PrimaryColor)
	confirmBtn.FontFace = Font.new(
		"rbxassetid://12187365364",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	confirmBtn.AnchorPoint = Vector2.new(0.5, 0)
	confirmBtn.Size = UDim2.new(1, 0, 0.43911, 0)
	confirmBtn.Text = confirmText
	confirmBtn.Position = UDim2.new(0.5, 0, 0, 0)
	confirmBtn.ZIndex = 13
	confirmBtn.Parent = interactions
	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 4)
	confirmCorner.Parent = confirmBtn
	local confirmShadow = Instance.new("UIShadow")
	confirmShadow.BlurRadius = UDim.new	(0, 20)
	confirmShadow.Color = (theme and theme.PrimaryColor)
	confirmShadow.Transparency = 1
	confirmShadow.Parent = confirmBtn
	----------------------------------------------------------------
	-- CANCEL BUTTON
	----------------------------------------------------------------
	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Name = "Cancel"
	cancelBtn.BorderSizePixel = 0
	cancelBtn.TextTransparency = (theme and theme.PopupTextTransparency) or 0.5
	cancelBtn.TextSize = 12
	cancelBtn.AutoButtonColor = false
	cancelBtn.TextColor3 = (theme and theme.PopupTextColor)
	cancelBtn.BackgroundColor3 = (theme and theme.PopupNeutralColor)
	cancelBtn.BackgroundTransparency = 0.5
	cancelBtn.FontFace = Font.new(
		"rbxassetid://12187365364",
		Enum.FontWeight.Regular,
		Enum.FontStyle.Normal
	)
	cancelBtn.AnchorPoint = Vector2.new(0.5, 1)
	cancelBtn.Size = UDim2.new(1, 0, 0.43882, 0)
	cancelBtn.Text = cancelText
	cancelBtn.Position = UDim2.new(0.5, 0, 1, 0)
	cancelBtn.ZIndex = 13
	cancelBtn.Parent = interactions
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 4)
	cancelCorner.Parent = cancelBtn
	local cancelShadow = Instance.new("UIShadow")
	cancelShadow.BlurRadius = UDim.new	(0, 20)
	cancelShadow.Color = (theme and theme.PopupNeutralColor)
	cancelShadow.Transparency = 1
	cancelShadow.Parent = cancelBtn
	----------------------------------------------------------------
	-- STORE REFERENCES
	----------------------------------------------------------------
	self.Scrim = scrim
	self.Popup = popup
	self.Shadow = shadow
	self.ConfirmShadow = confirmShadow
	self.CancelShadow = cancelShadow
	self.Header = header
	self.NotifText = notifText
	self.Divider = divider
	self.Interactions = interactions
	self.ConfirmBtn = confirmBtn
	self.CancelBtn = cancelBtn
	self.OnConfirm = onConfirm
	self.OnCancel = onCancel
	self.Settings = Settings -- store for later content updates
	----------------------------------------------------------------
	-- INTERNAL RESOLVE FUNCTIONS
	----------------------------------------------------------------
	function self:_Confirm()
		if self._resolved then
			return
		end
		self._resolved = true
		self:Close()
		task.spawn(function()
			self.OnConfirm()
		end)
	end
	function self:_Cancel()
		if self._resolved then
			return
		end
		self._resolved = true
		self:Close()
		task.spawn(function()
			self.OnCancel()
		end)
	end
	----------------------------------------------------------------
	-- BUTTON EVENTS
	----------------------------------------------------------------
	confirmBtn.MouseButton1Click:Connect(function()
		self:_Confirm()
	end)
	cancelBtn.MouseButton1Click:Connect(function()
		self:_Cancel()
	end)
	----------------------------------------------------------------
	-- SCRIM EVENT
	----------------------------------------------------------------
	scrim.MouseButton1Click:Connect(function()
		self:_Cancel()
	end)
	----------------------------------------------------------------
	-- HOVER EFFECTS
	----------------------------------------------------------------
	-- Confirm button shadow on hover
	confirmBtn.MouseEnter:Connect(function()
		Tween.Play(confirmShadow, "Smooth", {
			BlurRadius = UDim.new(0, 50),
			Transparency = 0
		})
	end)
	confirmBtn.MouseLeave:Connect(function()
		Tween.Play(confirmShadow, "Smooth", {
			BlurRadius = UDim.new(0, 20),
			Transparency = 1
		})
	end)
	-- Cancel button text transparency on hover. The resting value MUST match
	-- what Open() sets (0.5) so unhovering returns to the original state, not a
	-- different theme-derived value.
	local CANCEL_TEXT_REST = 0.5
	local CANCEL_TEXT_HOVER = 0.2
	cancelBtn.MouseEnter:Connect(function()
		Tween.Play(cancelBtn, "Smooth", { TextTransparency = CANCEL_TEXT_HOVER })
	end)
	cancelBtn.MouseLeave:Connect(function()
		Tween.Play(cancelBtn, "Smooth", { TextTransparency = CANCEL_TEXT_REST })
	end)
	----------------------------------------------------------------
	-- IMPORTANT
	----------------------------------------------------------------
	-- NotificationPopup is a Frame.
	-- Frames do NOT have MouseButton1Click.
	--
	-- No event should be connected to popup.MouseButton1Click.
	return self
end
----------------------------------------------------------------
-- OPEN
----------------------------------------------------------------
function UINotification:Open()
	if self.IsOpen then
		return
	end
	self.IsOpen = true
	self._resolved = false
	Sound.Play("Notification")
	-- Reset to transparent before showing
	self.Scrim.ImageTransparency = 1
	self.Popup.BackgroundTransparency = 1
	-- Internal elements: start fully transparent
	self.Header.TextTransparency = 1
	self.NotifText.TextTransparency = 1
	self.Divider.BackgroundTransparency = 1
	self.Interactions.BackgroundTransparency = 1
	self.ConfirmBtn.TextTransparency = 1
	self.CancelBtn.TextTransparency = 1
	self.Scrim.Visible = true
	self.Popup.Visible = true
	-- Fade in scrim
	--Tween.Play(self.Scrim, "Smooth", {
	--	ImageTransparency = 0
	--})
	-- Fade in popup background
	Tween.Play(self.Popup, "Smooth", {
		BackgroundTransparency = 0.07
	})
	-- Fade in shadow
	Tween.Play(self.Shadow, "Smooth", {
		Transparency = 0.5
	})
	-- Fade in internal elements
	Tween.Play(self.Header, "Smooth", {
		TextTransparency = 0.4
	})
	Tween.Play(self.NotifText, "Smooth", {
		TextTransparency = 0.45
	})
	Tween.Play(self.Divider, "Smooth", {
		BackgroundTransparency = 0.9
	})
	Tween.Play(self.Interactions, "Smooth", {
		BackgroundTransparency = 1
	})
	Tween.Play(self.ConfirmBtn, "Smooth", {
		TextTransparency = 0.2
	})
	Tween.Play(self.CancelBtn, "Smooth", {
		TextTransparency = 0.5
	})
end
----------------------------------------------------------------
-- CLOSE
----------------------------------------------------------------
function UINotification:Close()
	if not self.IsOpen then
		return
	end
	self.IsOpen = false
	-- Fade out internal elements
	Tween.Play(self.Header, "Smooth", {
		TextTransparency = 1
	})
	Tween.Play(self.NotifText, "Smooth", {
		TextTransparency = 1
	})
	Tween.Play(self.Divider, "Smooth", {
		BackgroundTransparency = 1
	})
	Tween.Play(self.Interactions, "Smooth", {
		BackgroundTransparency = 1
	})
	Tween.Play(self.ConfirmBtn, "Smooth", {
		TextTransparency = 1,
		BackgroundTransparency = 1
	})
	Tween.Play(self.CancelBtn, "Smooth", {
		TextTransparency = 1,
		BackgroundTransparency = 1
	})
	-- Fade out popup shadow
	Tween.Play(self.Shadow, "Smooth", {
		Transparency = 1
	})
	
	-- Reset confirm shadow to default (fade out)
	Tween.Play(self.ConfirmShadow, "Smooth", {
		BlurRadius = UDim.new(0, 20),
		Transparency = 1
	})
	
	-- Reset cancel shadow to default (fade out)
	Tween.Play(self.CancelShadow, "Smooth", {
		Transparency = 1
	})
	-- Fade out popup background
	Tween.Play(self.Popup, "Smooth", {
		BackgroundTransparency = 1
	})
	-- Fade out scrim
	--Tween.Play(self.Scrim, "Smooth", {
	--	ImageTransparency = 1
	--})
	task.delay(0.35, function()
		if not self.IsOpen then
			self.Popup.Visible = false
			self.Scrim.Visible = false
		end
	end)
end
-- Set content without rebuilding the UI (reuse instance)
function UINotification:SetContent(Settings)
	-- Safety: ensure Settings is a table
	if type(Settings) ~= "table" then
		warn("[UINotification:SetContent] Settings is not a table, defaulting to empty table")
		Settings = {}
	end
	local title = Settings.Title or "Notification"
	local description = Settings.Description or ""
	local titleColor = Settings.TitleColor or Color3.fromRGB(255, 255, 255)
	local confirmText = Settings.ConfirmText or "Confirm"
	local cancelText = Settings.CancelText or "Cancel"
	self.OnConfirm = Settings.OnConfirm or function() end
	self.OnCancel = Settings.OnCancel or function() end
	-- Update header
	local colorStr = colorToString(titleColor)
	self.Header.Text = string.format('<font color="%s">%s</font>', colorStr, title)
	-- Update description
	self.NotifText.Text = description
	-- Update button texts
	self.ConfirmBtn.Text = confirmText
	self.CancelBtn.Text = cancelText
	-- Reset resolved state
	self._resolved = false
end
----------------------------------------------------------------
-- SET TITLE
----------------------------------------------------------------
function UINotification:SetTitle(title, color)
	local colorStr
	if color then
		colorStr = colorToString(color)
	else
		-- RichText needs hex/named, NOT rgb(...). Use the shared converter so an
		-- uncolored title still renders instead of producing an invalid tag.
		colorStr = colorToString(Color3.fromRGB(255, 255, 255))
	end
	self.Header.Text = string.format(
		'<font color="%s">%s</font>',
		colorStr,
		title
	)
end
----------------------------------------------------------------
-- SET DESCRIPTION
----------------------------------------------------------------
function UINotification:SetDescription(desc)
	self.NotifText.Text = desc
end
----------------------------------------------------------------
-- DESTROY
----------------------------------------------------------------
function UINotification:Destroy()
	if self.Scrim then
		self.Scrim:Destroy()
	end
end
-- Hide the popup (keep it alive for reuse)
function UINotification:Hide()
	self.Popup.Visible = false
	self.Scrim.Visible = false
	self.IsOpen = false
end
return UINotification