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
local Constants = require("../Constants")
local UserInputService = game:GetService("UserInputService")
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
	local titleColor = Settings.TitleColor or (theme and theme.TitleTextColor) or Color3.fromRGB(255, 255, 255)
	local confirmText = Settings.ConfirmText or "Confirm"
	local cancelText = Settings.CancelText or "Cancel"
	local onConfirm = Settings.OnConfirm or function() end
	local onCancel = Settings.OnCancel or function() end
	self.IsOpen = false
	self._resolved = false
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
	popup.Size = UDim2.fromScale(0.611, 0)
	popup.Position = UDim2.fromScale(0.5, 0.5)
	popup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	popup.Visible = false
	popup.ZIndex = 11
	popup.Parent = parent
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
	header.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	header.RichText = true
	header.AnchorPoint = Vector2.new(0.5, 0.5)
	header.Size = UDim2.fromScale(0.26291, 0.03775)
	header.AutomaticSize = Enum.AutomaticSize.X
	header.Position = UDim2.new(0.5, 0, 0, 25)
	header.TextColor3 = (theme and theme.PopupTextColor)
	header.Parent = popup
	header.Text = string.format('<font color="%s">%s</font>', colorToString(titleColor), title)
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
	notifText.FontFace = Constants.Font(Enum.FontWeight.Medium)
	notifText.TextColor3 = (theme and theme.PopupTextColor)
	notifText.RichText = true
	notifText.AnchorPoint = Vector2.new(0.5, 0.5)
	notifText.Size = UDim2.fromScale(0.91, 0.1358)
	notifText.AutomaticSize = Enum.AutomaticSize.Y
	notifText.Position = UDim2.fromScale(0.5, 0.4)
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
	divider.Position = UDim2.fromScale(0.5, 1.7)
	divider.ZIndex = 12
	divider.Parent = notifText
	----------------------------------------------------------------
	-- INTERACTIONS
	----------------------------------------------------------------
	local interactions = Instance.new("Frame")
	interactions.Name = "Interactions"
	interactions.BorderSizePixel = 0
	interactions.BackgroundColor3 = (theme and theme.PopupShadowColor) or Color3.fromRGB(15, 15, 16)
	interactions.BackgroundTransparency = 0.8
	interactions.AnchorPoint = Vector2.new(0.5, 1)
	interactions.Size = UDim2.new(1, 0, 0, 55)
	interactions.Position = UDim2.fromScale(0.5, 1)
	interactions.ZIndex = 12
	interactions.Parent = popup
	local interactionsCorner = Instance.new("UICorner")
	interactionsCorner.BottomLeftRadius = UDim.new(0, 6)
	interactionsCorner.BottomRightRadius = UDim.new(0, 6)
	interactionsCorner.TopLeftRadius = UDim.new(0, 0)
	interactionsCorner.TopRightRadius = UDim.new(0, 0)
	interactionsCorner.Parent = interactions
	local interactionsLayout = Instance.new("UIListLayout")
	interactionsLayout.FillDirection = Enum.FillDirection.Horizontal
	interactionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	interactionsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	interactionsLayout.Padding = UDim.new(0, 8)
	interactionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	interactionsLayout.Parent = interactions
	local interactionsPadding = Instance.new("UIPadding")
	interactionsPadding.PaddingLeft = UDim.new(0, 10)
	interactionsPadding.PaddingRight = UDim.new(0, 10)
	interactionsPadding.Parent = interactions
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
	confirmBtn.FontFace = Constants.Font(Enum.FontWeight.Bold)
	-- Side-by-side row: confirm on the LEFT half, cancel on the right.
	confirmBtn.AnchorPoint = Vector2.new(0, 0)
	confirmBtn.Size = UDim2.fromScale(0.47, 0.6)
	confirmBtn.Text = confirmText
	confirmBtn.Position = UDim2.fromScale(0, 0)
	confirmBtn.ZIndex = 13
	confirmBtn.Parent = interactions
	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 4)
	confirmCorner.Parent = confirmBtn
	local confirmShadow = Instance.new("UIShadow")
	confirmShadow.BlurRadius = UDim.new(0, 20)
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
	cancelBtn.FontFace = Constants.Font(Enum.FontWeight.Regular)
	-- Right half, with a small gap from confirm.
	cancelBtn.AnchorPoint = Vector2.new(0, 0)
	cancelBtn.Size = UDim2.fromScale(0.47, 0.6)
	cancelBtn.Text = cancelText
	cancelBtn.Position = UDim2.fromScale(0.515, 0)
	cancelBtn.ZIndex = 13
	cancelBtn.Parent = interactions
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 4)
	cancelCorner.Parent = cancelBtn
	local cancelShadow = Instance.new("UIShadow")
	cancelShadow.BlurRadius = UDim.new(0, 20)
	cancelShadow.Color = (theme and theme.PopupNeutralColor)
	cancelShadow.Transparency = 1
	cancelShadow.Parent = cancelBtn
	----------------------------------------------------------------
	-- STORE REFERENCES
	----------------------------------------------------------------
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
	-- Remember the header's origin so ApplyTheme can rebuild its RichText colour
	-- without clobbering a caller-supplied custom TitleColor.
	self._title = title
	self._customTitleColor = Settings.TitleColor ~= nil
	----------------------------------------------------------------
	-- INTERNAL RESOLVE FUNCTIONS
	----------------------------------------------------------------
	self._Confirm = function(_self)
		if self._resolved then
			return
		end
		self._resolved = true
		self:Close()
		task.spawn(function()
			self.OnConfirm()
		end)
	end
	self._Cancel = function(_self)
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
	-- HOVER EFFECTS
	----------------------------------------------------------------
	-- Confirm button shadow on hover
	confirmBtn.MouseEnter:Connect(function()
		Tween.Play(confirmShadow, "Fast", {
			BlurRadius = UDim.new(0, 50),
			Transparency = 0,
		})
	end)
	confirmBtn.MouseLeave:Connect(function()
		Tween.Play(confirmShadow, "Fast", {
			BlurRadius = UDim.new(0, 20),
			Transparency = 1,
		})
	end)
	-- Cancel button text transparency on hover. The resting value MUST match
	-- what Open() sets (0.5) so unhovering returns to the original state, not a
	-- different theme-derived value.
	local CANCEL_TEXT_REST = 0.5
	local CANCEL_TEXT_HOVER = 0.2
	cancelBtn.MouseEnter:Connect(function()
		Tween.Play(cancelBtn, "Fast", { TextTransparency = CANCEL_TEXT_HOVER })
	end)
	cancelBtn.MouseLeave:Connect(function()
		Tween.Play(cancelBtn, "Fast", { TextTransparency = CANCEL_TEXT_REST })
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
-- CLICK-OUTSIDE (UserInputService)
----------------------------------------------------------------
-- The connection exists only while the popup is open: created in Open(),
-- disconnected in Close()/Hide()/Destroy(). Replaces the old scrim button.
function UINotification:_connectOutsideClick()
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
		-- Inside if the point is within the popup's rect OR lands on any of its
		-- descendants. The descendant check makes this robust when visually-
		-- belonging content (overlays, shadows, indicators) extends past the
		-- frame's own rect; a pure rect test would misread those as "outside".
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
			self:_Cancel()
		end
	end)
end
function UINotification:_disconnectOutsideClick()
	if self._outsideConn then
		self._outsideConn:Disconnect()
		self._outsideConn = nil
	end
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
	self.Popup.BackgroundTransparency = 1
	-- Internal elements: start fully transparent
	self.Header.TextTransparency = 1
	self.NotifText.TextTransparency = 1
	self.Divider.BackgroundTransparency = 1
	self.Interactions.BackgroundTransparency = 1
	self.ConfirmBtn.TextTransparency = 1
	self.CancelBtn.TextTransparency = 1
	self.Popup.Visible = true
	-- Arm the click-outside listener for as long as the popup is open.
	self:_connectOutsideClick()
	-- Fade in popup background
	Tween.Play(self.Popup, "Fast", {
		BackgroundTransparency = 0.07,
	})
	-- Fade in shadow
	Tween.Play(self.Shadow, "Fast", {
		Transparency = 0.5,
	})
	-- Fade in internal elements
	Tween.Play(self.Header, "Fast", {
		TextTransparency = 0.4,
	})
	Tween.Play(self.NotifText, "Fast", {
		TextTransparency = 0.45,
	})
	Tween.Play(self.Divider, "Fast", {
		BackgroundTransparency = 0.9,
	})
	Tween.Play(self.Interactions, "Fast", {
		BackgroundTransparency = 0.8,
	})
	Tween.Play(self.ConfirmBtn, "Fast", {
		TextTransparency = 0.2,
	})
	Tween.Play(self.CancelBtn, "Fast", {
		TextTransparency = 0.5,
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
	Tween.Play(self.Header, "Fast", {
		TextTransparency = 1,
	})
	Tween.Play(self.NotifText, "Fast", {
		TextTransparency = 1,
	})
	Tween.Play(self.Divider, "Fast", {
		BackgroundTransparency = 1,
	})
	Tween.Play(self.Interactions, "Fast", {
		BackgroundTransparency = 1,
	})
	Tween.Play(self.ConfirmBtn, "Fast", {
		TextTransparency = 1,
		BackgroundTransparency = 1,
	})
	Tween.Play(self.CancelBtn, "Fast", {
		TextTransparency = 1,
		BackgroundTransparency = 1,
	})
	-- Fade out popup shadow
	Tween.Play(self.Shadow, "Fast", {
		Transparency = 1,
	})

	-- Reset confirm shadow to default (fade out)
	Tween.Play(self.ConfirmShadow, "Fast", {
		BlurRadius = UDim.new(0, 20),
		Transparency = 1,
	})

	-- Reset cancel shadow to default (fade out)
	Tween.Play(self.CancelShadow, "Fast", {
		Transparency = 1,
	})
	-- Disarm the click-outside listener immediately on close.
	self:_disconnectOutsideClick()
	-- Fade out popup background
	Tween.Play(self.Popup, "Fast", {
		BackgroundTransparency = 1,
	})
	task.delay(0.35, function()
		if not self.IsOpen then
			self.Popup.Visible = false
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
	self.Header.Text = string.format('<font color="%s">%s</font>', colorStr, title)
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
	self:_disconnectOutsideClick()
	if self.Popup then
		self.Popup:Destroy()
	end
end
-- Hide the popup (keep it alive for reuse)
function UINotification:Hide()
	self.Popup.Visible = false
	self.IsOpen = false
	self:_disconnectOutsideClick()
end

-- Live theme switch: recolour every themed element in place so an already-open
-- dialog crossfades with the rest of the window instead of being destroyed and
-- rebuilt by Window:SetTheme.
function UINotification:ApplyTheme(themeInput)
	local t = ThemeManager.GetTheme(themeInput)
	if not t or not self.Popup then
		return
	end
	self.Popup.BackgroundColor3 = t.PopupBackgroundColor
	self.Popup.BackgroundTransparency = t.PopupBackgroundTransparency or 1
	self.Shadow.Color = t.PopupShadowColor
	self.Header.TextColor3 = t.PopupTextColor
	self.Header.TextTransparency = t.PopupTextTransparency or 0.4
	if not self._customTitleColor then
		local colorStr = colorToString(t.PopupTextColor or Color3.fromRGB(255, 255, 255))
		self.Header.Text = string.format('<font color="%s">%s</font>', colorStr, self._title or "Notification")
	end
	self.NotifText.TextColor3 = t.PopupTextColor
	self.NotifText.TextTransparency = t.PopupTextTransparency or 0.45
	self.Divider.BackgroundColor3 = t.AccentColor
	self.Interactions.BackgroundColor3 = t.PopupShadowColor or Color3.fromRGB(15, 15, 16)
	self.ConfirmBtn.BackgroundColor3 = t.PrimaryColor
	self.ConfirmBtn.TextColor3 = t.PopupTextColor
	self.ConfirmShadow.Color = t.PrimaryColor
	self.CancelBtn.BackgroundColor3 = t.PopupNeutralColor
	self.CancelBtn.TextColor3 = t.PopupTextColor
	self.CancelShadow.Color = t.PopupNeutralColor
end

return UINotification
