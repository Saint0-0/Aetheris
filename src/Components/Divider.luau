--[[
	Divider  ·  Aetheris UI Library

	A simple visual divider line for separating sections. Custom Color /
	Transparency set here win over the theme (marked with attributes so
	ThemeManager leaves them alone on a theme switch).

	Usage:
		local divider = section:Divider({
			Color = Color3.fromRGB(237, 243, 255),  -- optional
			Transparency = 0.9,                      -- optional
			Thickness = 1,                           -- optional (pixels)
		})
]]

local ThemeManager = require("../Themes/ThemeManager")
local Divider = {}
Divider.__index = Divider
function Divider.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Divider)
	local color = Settings.Color or theme.SectionDividerColor
	local transparency = Settings.Transparency or theme.SectionDividerTransparency
	local hasCustomColor = Settings.Color ~= nil
	local hasCustomTransparency = Settings.Transparency ~= nil
	local thickness = Settings.Thickness or 1
	-- Divider frame
	local frame = Instance.new("Frame")
	frame.Name = "Divider"
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency
	frame.Size = UDim2.new(0.90447, 0, 0, thickness)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame:SetAttribute("IsSectionDivider", true)
	frame:SetAttribute("HasCustomDividerColor", hasCustomColor)
	frame:SetAttribute("HasCustomDividerTransparency", hasCustomTransparency)
	frame.Parent = parent
	self.Frame = frame
	-- Public API
	self.SetVisibility = function(visible)
		frame.Visible = visible
	end
	function self:SetColor(newColor)
		frame.BackgroundColor3 = newColor
	end
	function self:SetTransparency(newTransparency)
		frame.BackgroundTransparency = newTransparency
	end
	-- Component-owned theming (see ThemeManager registry). A custom Color /
	-- Transparency set by the caller wins over the theme.
	function self:ApplyTheme(newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		self._theme = theme
		if not hasCustomColor then
			frame.BackgroundColor3 = theme.SectionDividerColor or frame.BackgroundColor3
		end
		if not hasCustomTransparency then
			frame.BackgroundTransparency = theme.SectionDividerTransparency or frame.BackgroundTransparency
		end
	end
	ThemeManager.Register(frame, self)
	return self
end
return Divider