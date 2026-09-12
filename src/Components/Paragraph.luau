--[[
	Paragraph  ·  Aetheris UI Library

	Container with a title and a wrapped description body. Accepts Title (or
	Name) and Description (or Text).

	Usage:
		local paragraph = section:Paragraph({
			Title = "My Title",
			Description = "Lorem ipsum...",
		})
]]

local ThemeManager = require("../Themes/ThemeManager")
local Paragraph = {}
Paragraph.__index = Paragraph
function Paragraph.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Paragraph)
	self._theme = theme
	local title = Settings.Title or Settings.Name or "Paragraph"
	local description = Settings.Description or Settings.Text or ""
	-- Main container (matches GUI style)
	local container = Instance.new("Frame")
	container.Name = title .. " [Paragraph]"
	container.BorderSizePixel = 0
	container.BackgroundColor3 = (theme and theme.ComponentBackgroundColor)
	container.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.Size = UDim2.new(1, 0, 0, 0)
	container:SetAttribute("IsComponentContainer", true)
	container.Parent = parent
	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container
	-- Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = container
	-- Title label (ElementName)
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "ElementName"
	titleLabel.TextWrapped = true
	titleLabel.BorderSizePixel = 0
	titleLabel.TextSize = 15
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTransparency = (theme and theme.PrimaryTextTransparency) or 0.3
	titleLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	titleLabel.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	titleLabel.TextColor3 = (theme and theme.PrimaryTextColor)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(0.909, 0, 0, 20)  -- height fixed for title
	titleLabel.Text = title
	titleLabel.Position = UDim2.new(0.043, 0, 0, 8)  -- left padding, top offset
	titleLabel.Parent = container
	-- Description label (LabelDescription)
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "LabelDescription"
	descLabel.TextWrapped = true
	descLabel.BorderSizePixel = 0
	descLabel.TextSize = 14
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextTransparency = (theme and theme.SecondaryTextTransparency) or 0.45
	descLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	descLabel.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	descLabel.TextColor3 = (theme and theme.SecondaryTextColor)
	descLabel.BackgroundTransparency = 1
	descLabel.Size = UDim2.new(0.91, 0, 0, 0)
	descLabel.AutomaticSize = Enum.AutomaticSize.Y
	descLabel.Text = description
	descLabel.Position = UDim2.new(0, 11, 0, 38)  -- left padding, below title
	descLabel.Parent = container
	-- Padding inside description for bottom spacing
	local descPadding = Instance.new("UIPadding")
	descPadding.PaddingBottom = UDim.new(0, 15)
	descPadding.Parent = descLabel
	-- Store references
	self.Container = container
	self.TitleLabel = titleLabel
	self.DescLabel = descLabel
	-- Public API
	self.SetVisibility = function(visible)
		container.Visible = visible
	end
	self.SetTitle = function(newTitle)
		titleLabel.Text = newTitle
		container.Name = newTitle .. " [Paragraph]"
	end
	self.SetDescription = function(newDesc)
		descLabel.Text = newDesc
	end
	-- Component-owned theming (see ThemeManager registry).
	function self:ApplyTheme(newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		self._theme = theme
		container.BackgroundColor3 = theme.ComponentBackgroundColor or container.BackgroundColor3
		container.BackgroundTransparency = theme.ComponentBackgroundTransparency or container.BackgroundTransparency
		stroke.Color = theme.StrokeColor or stroke.Color
		stroke.Transparency = theme.StrokeTransparency or stroke.Transparency
		titleLabel.TextColor3 = theme.PrimaryTextColor or titleLabel.TextColor3
		titleLabel.TextTransparency = theme.PrimaryTextTransparency or titleLabel.TextTransparency
		descLabel.TextColor3 = theme.SecondaryTextColor or descLabel.TextColor3
		descLabel.TextTransparency = theme.SecondaryTextTransparency or descLabel.TextTransparency
	end
	ThemeManager.Register(container, self)
	return self
end
return Paragraph