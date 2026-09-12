--[[
	Label  ·  Aetheris UI Library

	Styled text label with an optional container (background + corner +
	stroke). A label built with ShowStroke = false tags its stroke
	HiddenStroke so ThemeManager keeps it invisible on theme switches.

	Usage:
		local label = section:Label({
			Text = "Hello World",
			ShowContainer = true,   -- default true
			ShowStroke = true,      -- default true
			FontWeight = "Bold",    -- optional, default "Regular"
		})
]]

local ThemeManager = require("../Themes/ThemeManager")
local Label = {}
Label.__index = Label
-- Map string to Enum.FontWeight
local function getFontWeight(weight)
	if typeof(weight) == "EnumItem" then return weight end
	local weightMap = {
		Regular = Enum.FontWeight.Regular,
		Medium = Enum.FontWeight.Medium,
		SemiBold = Enum.FontWeight.SemiBold,
		Bold = Enum.FontWeight.Bold,
		Heavy = Enum.FontWeight.Heavy,
		ExtraBold = Enum.FontWeight.ExtraBold,
	}
	return weightMap[weight] or Enum.FontWeight.Regular
end
function Label.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Label)
	self._theme = theme
	local text = Settings.Text or Settings.Name or "Label"
	local showContainer = (Settings.ShowContainer == nil) and true or Settings.ShowContainer
	local showStroke = (Settings.ShowStroke == nil) and true or Settings.ShowStroke
	local fontWeight = getFontWeight(Settings.FontWeight or "Regular")
	-- Container (matches Paragraph's style)
	local container = Instance.new("Frame")
	container.Name = text .. " [Label]"
	container.BorderSizePixel = 0
	container.BackgroundColor3 = (theme and theme.ComponentBackgroundColor)
	container.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or (showContainer and 0.985 or 1)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.Size = UDim2.new(1, 0, 0, 0)
	container:SetAttribute("IsComponentContainer", true)
	container.Parent = parent
	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container
	-- Stroke. When ShowStroke is false the stroke is fully transparent and
	-- tagged so ThemeManager leaves it alone on theme switches.
	local stroke = Instance.new("UIStroke")
	if showStroke then
		stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	else
		stroke.Transparency = 1
		stroke:SetAttribute("HiddenStroke", true)
	end
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = container
	-- Padding inside container
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 15)
	padding.PaddingBottom = UDim.new(0, 15)
	padding.PaddingLeft = UDim.new(0, 11)
	padding.PaddingRight = UDim.new(0, 11)
	padding.Parent = container
	-- Label
	local label = Instance.new("TextLabel")
	label.Name = "ElementName"
	label.FontFace = Font.new("rbxassetid://12187365364", fontWeight, Enum.FontStyle.Normal)
	label.Text = text
	label.RichText = true
	label.TextColor3 = (theme and theme.PrimaryTextColor)
	label.TextSize = 14
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.new(0, 0, 0.5, 0)
	label.TextTransparency = (theme and theme.PrimaryTextTransparency) or 0.45
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 0)  -- fill width, height auto
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Parent = container
	-- Store references
	self.Container = container
	self.Corner = corner
	self.Stroke = stroke
	self.Padding = padding
	self.Label = label
	self._showContainer = showContainer
	self._showStroke = showStroke
	self._fontWeight = fontWeight
	-- Public API
	self.SetVisibility = function(visible)
		container.Visible = visible
	end
	self.SetText = function(newText)
		label.Text = newText
	end
	self.SetTextTransparency = function(transparency)
		label.TextTransparency = transparency
	end
	self.SetFontWeight = function(weight)
		local newWeight = getFontWeight(weight)
		self._fontWeight = newWeight
		label.FontFace = Font.new("rbxassetid://12187365364", newWeight, Enum.FontStyle.Normal)
	end
	self.SetShowContainer = function(show)
		self._showContainer = show
		container.BackgroundTransparency = show and 0.985 or 1
		-- Also hide/show corner? Corner is always there but doesn't matter if background transparent.
		-- We keep corner and padding always, just toggle background.
	end
	self.SetShowStroke = function(show)
		self._showStroke = show
		stroke:SetAttribute("HiddenStroke", not show)
		stroke.Transparency = show and ((self._theme and self._theme.StrokeTransparency) or 0.95) or 1
	end
	-- Component-owned theming (see ThemeManager registry).
	function self:ApplyTheme(newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		self._theme = theme
		container.BackgroundColor3 = theme.ComponentBackgroundColor or container.BackgroundColor3
		if self._showContainer then
			container.BackgroundTransparency = theme.ComponentBackgroundTransparency or container.BackgroundTransparency
		else
			container.BackgroundTransparency = 1
		end
		label.TextColor3 = theme.PrimaryTextColor or label.TextColor3
		label.TextTransparency = theme.PrimaryTextTransparency or label.TextTransparency
		stroke.Color = theme.StrokeColor or stroke.Color
		if self._showStroke then
			stroke.Transparency = theme.StrokeTransparency or 0.95
		else
			stroke.Transparency = 1
		end
	end
	ThemeManager.Register(container, self)
	return self
end
return Label