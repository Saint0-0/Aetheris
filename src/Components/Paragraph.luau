--[[
	Aetheris/Components/Paragraph.luau

	Container with a title and a wrapped description body. Accepts Title (or
	Name) and Description (or Text); themed properties are declarative bindings
	so a theme switch re-resolves them with no ApplyTheme body to maintain.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeManager = require("../Themes/ThemeManager")
local Constants = require("../Constants")
local ComponentAPI = require("../Utils/ComponentAPI")
local UUID = require("../Utils/UUID")
local Paragraph = {}
Paragraph.__index = Paragraph
function Paragraph.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Paragraph)
	self._theme = theme
	local title = Settings.Title or Settings.Name or "Paragraph"
	local description = Settings.Description or Settings.Text or ""
	local container = Instance.new("Frame")
	container.Name = UUID.Generate("Paragraph")
	container.BorderSizePixel = 0
	container.BackgroundColor3 = (theme and theme.ComponentBackgroundColor)
	container.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.Size = UDim2.fromScale(1, 0)
	container:SetAttribute(UUID.Static("IsComponentContainer"), true)
	container.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = container
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = UUID.Static("ElementName")
	titleLabel.TextWrapped = true
	titleLabel.BorderSizePixel = 0
	titleLabel.TextSize = 15
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTransparency = (theme and theme.PrimaryTextTransparency) or 0.3
	titleLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	titleLabel.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	titleLabel.TextColor3 = (theme and theme.PrimaryTextColor)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(0.909, 0, 0, 20)
	titleLabel.AutomaticSize = Enum.AutomaticSize.Y
	titleLabel.Text = title
	titleLabel.AnchorPoint = Vector2.new(0, 0.5)
	titleLabel.Position = UDim2.fromOffset(11, 18)
	titleLabel.Parent = container
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = UUID.Static("LabelDescription")
	descLabel.TextWrapped = true
	descLabel.BorderSizePixel = 0
	descLabel.TextSize = 14
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextTransparency = (theme and theme.SecondaryTextTransparency) or 0.45
	descLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	descLabel.FontFace = Constants.Font(Enum.FontWeight.Medium)
	descLabel.TextColor3 = (theme and theme.SecondaryTextColor)
	descLabel.BackgroundTransparency = 1
	descLabel.Size = UDim2.fromScale(0.91, 0)
	descLabel.AutomaticSize = Enum.AutomaticSize.Y
	descLabel.Text = description
	descLabel.Position = UDim2.fromOffset(11, 38)
	descLabel.Parent = container
	local descPadding = Instance.new("UIPadding")
	descPadding.PaddingBottom = UDim.new(0, 15)
	descPadding.Parent = descLabel
	self.Container = container
	self.TitleLabel = titleLabel
	self.DescLabel = descLabel
	self.SetTitle = function(_, newTitle)
		titleLabel.Text = newTitle
	end
	self.SetDescription = function(_, newDesc)
		descLabel.Text = newDesc
	end
	ThemeManager.BindColor(container, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(container, "BackgroundTransparency", "ComponentBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	ThemeManager.BindColor(titleLabel, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(titleLabel, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(descLabel, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(descLabel, "TextTransparency", "SecondaryTextTransparency")
	self.Destroy = function(_self)
		if container and container.Parent then
			container:Destroy()
		end
	end
	ComponentAPI.Apply(self, { Root = container, Label = titleLabel, Name = title })
	return self
end
return Paragraph
