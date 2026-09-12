--[[
	Tooltip  ·  Aetheris UI Library

	Theme-matched floating tooltip. Created once and reused; position it
	relative to any instance via :ShowAt(anchor, text, side). Call :SetTheme()
	to keep it in sync after a theme switch, and :Hide() to dismiss it.
]]

local Tween = require("../Utils/Tween")
local ThemeManager = require("../Themes/ThemeManager")

local Tooltip = {}
Tooltip.__index = Tooltip

local FADE = 0.15

function Tooltip.new(container, theme)
	theme = ThemeManager.GetTheme(theme)
	local self = setmetatable({}, Tooltip)

	local root = Instance.new("Frame")
	root.Name = "Tooltip"
	root.BorderSizePixel = 0
	root.BackgroundColor3 = theme.PopupBackgroundColor or Color3.fromRGB(15, 15, 16)
	root.BackgroundTransparency = 1
	root.AutomaticSize = Enum.AutomaticSize.XY
	root.Size = UDim2.new(0, 0, 0, 0)
	root.ZIndex = 2000
	root.Visible = false
	root.Parent = container
	self.Root = root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = root

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.StrokeColor or Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.85
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = root

	local shadow = Instance.new("UIShadow")
	shadow.Color = theme.PopupShadowColor or Color3.fromRGB(0, 0, 0)
	shadow.BlurRadius = UDim.new(0, 12)
	shadow.Transparency = 1
	shadow.Parent = root
	self._stroke = stroke
	self._shadow = shadow

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)
	padding.PaddingLeft = UDim.new(0, 9)
	padding.PaddingRight = UDim.new(0, 9)
	padding.Parent = root

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BorderSizePixel = 0
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.new(0, 0, 0, 0)
	label.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	label.TextSize = 12
	label.TextColor3 = theme.PopupTextColor or Color3.fromRGB(255, 255, 255)
	label.TextTransparency = 1
	label.Text = ""
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = root
	self.Label = label

	self._shown = false
	self._theme = theme
	self._surface = theme.PopupBackgroundTransparency ~= nil and math.max(theme.PopupBackgroundTransparency, 0.05) or 0.05
	return self
end

function Tooltip:SetTheme(theme)
	theme = ThemeManager.GetTheme(theme)
	self._theme = theme
	self._surface = theme.PopupBackgroundTransparency ~= nil and math.max(theme.PopupBackgroundTransparency, 0.05) or 0.05
	self.Root.BackgroundColor3 = theme.PopupBackgroundColor or Color3.fromRGB(15, 15, 16)
	self.Label.TextColor3 = theme.PopupTextColor or Color3.fromRGB(255, 255, 255)
	local stroke = self.Root:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = theme.StrokeColor or Color3.fromRGB(255, 255, 255) end
	local shadow = self.Root:FindFirstChildOfClass("UIShadow")
	if shadow then shadow.Color = theme.PopupShadowColor or Color3.fromRGB(0, 0, 0) end
end

-- Place relative to an anchor instance. side = "Left"|"Right"|"Top"|"Bottom".
function Tooltip:ShowAt(anchor, text, side, gap)
	if not anchor or not anchor.Parent then return end
	gap = gap or 8
	side = side or "Left"
	self.Label.Text = text or ""

	local ap = anchor.AbsolutePosition
	local asz = anchor.AbsoluteSize
	local cx = ap.X + asz.X / 2
	local cy = ap.Y + asz.Y / 2

	local pos = UDim2.new(0, cx, 0, cy)
	local anchorPt = Vector2.new(0.5, 0.5)
	if side == "Left" then
		pos = UDim2.new(0, ap.X - gap, 0, cy)
		anchorPt = Vector2.new(1, 0.5)
	elseif side == "Right" then
		pos = UDim2.new(0, ap.X + asz.X + gap, 0, cy)
		anchorPt = Vector2.new(0, 0.5)
	elseif side == "Top" then
		pos = UDim2.new(0, cx, 0, ap.Y - gap)
		anchorPt = Vector2.new(0.5, 1)
	elseif side == "Bottom" then
		pos = UDim2.new(0, cx, 0, ap.Y + asz.Y + gap)
		anchorPt = Vector2.new(0.5, 0)
	end

	self.Root.AnchorPoint = anchorPt
	self.Root.Position = pos
	self.Root.Visible = true
	self._shown = true
	local info = TweenInfo.new(FADE)
	Tween.Play(self.Root, info, { BackgroundTransparency = self._surface or 0.05 })
	Tween.Play(self.Label, info, { TextTransparency = self._theme and (self._theme.PopupTextTransparency or 0) or 0 })
	if self._stroke then Tween.Play(self._stroke, info, { Transparency = 0.85 }) end
	if self._shadow then Tween.Play(self._shadow, info, { Transparency = 0.5 }) end
end

function Tooltip:Hide()
	if not self._shown then return end
	self._shown = false
	local info = TweenInfo.new(FADE)
	Tween.Play(self.Root, info, { BackgroundTransparency = 1 })
	Tween.Play(self.Label, info, { TextTransparency = 1 })
	if self._stroke then Tween.Play(self._stroke, info, { Transparency = 1 }) end
	if self._shadow then Tween.Play(self._shadow, info, { Transparency = 1 }) end
	task.delay(FADE, function()
		if not self._shown and self.Root then
			self.Root.Visible = false
		end
	end)
end

return Tooltip