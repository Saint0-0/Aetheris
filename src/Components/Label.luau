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
local Constants = require("../Constants")
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
	local textSize = Settings.TextSize or 14
	local customTextTransparency = Settings.TextTransparency
	local paddingOverride = Settings.Padding
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
	if paddingOverride then
		padding.PaddingTop = UDim.new(0, paddingOverride.Top or 0)
		padding.PaddingBottom = UDim.new(0, paddingOverride.Bottom or 0)
		padding.PaddingLeft = UDim.new(0, paddingOverride.Left or 0)
		padding.PaddingRight = UDim.new(0, paddingOverride.Right or 0)
	else
		padding.PaddingTop = UDim.new(0, 15)
		padding.PaddingBottom = UDim.new(0, 15)
		padding.PaddingLeft = UDim.new(0, 11)
		padding.PaddingRight = UDim.new(0, 11)
	end
	padding.Parent = container
	-- Label
	local label = Instance.new("TextLabel")
	label.Name = "ElementName"
	label.FontFace = Constants.Font(fontWeight)
	label.Text = text
	label.RichText = true
	label.TextColor3 = (theme and theme.PrimaryTextColor)
	label.TextSize = textSize
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.new(0, 0, 0.5, 0)
	label.TextTransparency = customTextTransparency or ((theme and theme.PrimaryTextTransparency) or 0.45)
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
	self._hasCustomTextTransparency = (customTextTransparency ~= nil)
	-- Declarative theming: every themed property is a BINDING. No ApplyTheme.
	local bgColorBinding = ThemeManager.BindColor(container, "BackgroundColor3", "ComponentBackgroundColor")
	local bgTransBinding = ThemeManager.BindTransparency(container, "BackgroundTransparency", "ComponentBackgroundTransparency")
	local textColorBinding = ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	local textTransBinding = ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	local strokeColorBinding = ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	local strokeTransBinding = ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	-- Conditional properties: a binding drives the value only while its
	-- condition holds; otherwise it is disabled and the value set directly.
	if not showContainer then
		bgTransBinding:SetEnabled(false)
		container.BackgroundTransparency = 1
	end
	if not showStroke then
		strokeTransBinding:SetEnabled(false)
		stroke.Transparency = 1
	end
	if customTextTransparency ~= nil then
		textTransBinding:SetEnabled(false)
	end
	-- Public API
	self.SetText = function(newText)
		label.Text = newText
	end
	self.SetTextTransparency = function(transparency)
		self._hasCustomTextTransparency = (transparency ~= nil)
		if transparency ~= nil then
			textTransBinding:SetEnabled(false)
			label.TextTransparency = transparency
		else
			textTransBinding:SetEnabled(true)
		end
	end
	self.SetFontWeight = function(weight)
		local newWeight = getFontWeight(weight)
		self._fontWeight = newWeight
		label.FontFace = Constants.Font(newWeight)
	end
	self.SetShowContainer = function(show)
		self._showContainer = show
		if show then
			bgTransBinding:SetEnabled(true)
		else
			bgTransBinding:SetEnabled(false)
			container.BackgroundTransparency = 1
		end
	end
	self.SetShowStroke = function(show)
		self._showStroke = show
		stroke:SetAttribute("HiddenStroke", not show)
		if show then
			strokeTransBinding:SetEnabled(true)
		else
			strokeTransBinding:SetEnabled(false)
			stroke.Transparency = 1
		end
	end
	-- Uniform component API (p2-4): visibility toggle + teardown.
	function self:SetVisibility(visible)
		container.Visible = visible
	end
	function self:Destroy()
		if container and container.Parent then container:Destroy() end
	end
	-- No ApplyTheme / Register: all themed properties are bindings above.
	return self
end
return Label