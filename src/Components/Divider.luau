--[[
	Aetheris/Components/Divider.luau

	Divider line parented to a transparent holder that supplies vertical room.
	Padding sets the holder height, and a caller Color or Transparency wins over
	the theme across switches.
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
	-- A caller Color is a theme override and wins over the binding.
	if hasCustomColor then
		ThemeManager.SetColorOverride(frame, "BackgroundColor3", color)
	end
	-- A caller Transparency disables the binding.
	if hasCustomTransparency then
		transparencyBinding:SetEnabled(false)
		frame.BackgroundTransparency = transparency
	end
	self.Holder = holder
	self.Frame = frame
	self.Destroy = function(_self)
		if holder and holder.Parent then
			holder:Destroy()
		end
	end
	ComponentAPI.Apply(self, {
		Root = holder,
		Name = Settings.Name,
		Methods = {
			SetColor = function(_self, newColor)
				hasCustomColor = true
				ThemeManager.SetColorOverride(frame, "BackgroundColor3", newColor)
			end,
			SetTransparency = function(_self, newTransparency)
				hasCustomTransparency = true
				transparencyBinding:SetEnabled(false)
				frame.BackgroundTransparency = newTransparency
			end,
		},
	})
	return self
end
return Divider
