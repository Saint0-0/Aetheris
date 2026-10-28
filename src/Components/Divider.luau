--[[
	Aetheris/Components/Divider.luau

	A visual divider line parented to a fully transparent holder frame so it can
	create its own vertical breathing room; Padding sets the holder's Y size in
	offset pixels (default 1px). A caller-supplied Color or Transparency
	overrides the theme value and survives every theme pass.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeManager = require("../Themes/ThemeManager")
local ComponentAPI = require("../Utils/ComponentAPI")
local UUID = require("../Utils/UUID")
local Divider = {}
Divider.__index = Divider
function Divider.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Divider)
	self._theme = theme
	local hasCustomTransparency = Settings.Transparency ~= nil
	local hasCustomColor = Settings.Color ~= nil
	local color = Settings.Color or theme.SectionDividerColor
	local transparency = Settings.Transparency or theme.SectionDividerTransparency
	local thickness = Settings.Thickness or 1
	-- Padding gives equal breathing room above and below the line.
	local padding = Settings.Padding or 1
	local holder = Instance.new("Frame")
	holder.Name = UUID.Static("DividerHolder")
	holder.BorderSizePixel = 0
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, padding)
	holder.BorderColor3 = Color3.fromRGB(0, 0, 0)
	holder.Parent = parent
	local frame = Instance.new("Frame")
	frame.Name = UUID.Static("Divider")
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency
	frame.Size = UDim2.new(0.90447, 0, 0, thickness)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame.Parent = holder
	ThemeManager.BindColor(frame, "BackgroundColor3", "SectionDividerColor")
	local transparencyBinding =
		ThemeManager.BindTransparency(frame, "BackgroundTransparency", "SectionDividerTransparency")
	-- A caller-supplied Color is a theme override, so it wins over the binding.
	if hasCustomColor then
		ThemeManager.SetColorOverride(frame, "BackgroundColor3", color)
	end
	-- A caller-supplied Transparency disables the binding so the theme stops driving it.
	if hasCustomTransparency then
		transparencyBinding:SetEnabled(false)
		frame.BackgroundTransparency = transparency
	end
	self.Holder = holder
	self.Frame = frame
	self.SetColor = function(_self, newColor)
		hasCustomColor = true
		ThemeManager.SetColorOverride(frame, "BackgroundColor3", newColor)
	end
	self.SetTransparency = function(_self, newTransparency)
		hasCustomTransparency = true
		transparencyBinding:SetEnabled(false)
		frame.BackgroundTransparency = newTransparency
	end
	self.SetVisibility = function(_self, visible)
		holder.Visible = visible
	end
	self.Destroy = function(_self)
		if holder and holder.Parent then
			holder:Destroy()
		end
	end
	ComponentAPI.Apply(self, { Root = holder, Name = Settings.Name })
	return self
end
return Divider
