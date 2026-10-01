--[[
	Divider  ·  Aetheris UI Library

	A visual divider line. The line itself is parented to a fully transparent
	'DividerHolder' frame of size (1, 0, 0, Padding) so a divider can create
	its own vertical breathing room. Padding is the holder's Y size in OFFSET
	pixels (space above + below the line); it defaults to 1px.

	A custom Color wins over the theme (declared as a ThemeManager colour
	override so it survives every theme pass). Custom Transparency disables the
	transparency binding so the theme stops driving it.

	Themed properties are declarative BINDINGS (ThemeManager.BindColor /
	BindTransparency) -- this component has no ApplyTheme.

	Usage:
		local divider = section:Divider({
			Color = Color3.fromRGB(237, 243, 255),  -- optional
			Transparency = 0.9,                      -- optional
			Thickness = 1,                           -- optional (pixels)
			Padding = 10,                            -- optional (holder Y offset, default 1)
		})
]]

local ThemeManager = require("../Themes/ThemeManager")
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
	-- Padding is the holder's vertical (offset) size: it gives equal space
	-- above and below the line. Defaults to 1px when not supplied.
	local padding = Settings.Padding or 1
	-- Holder: full width, fully transparent, Y size = the requested padding.
	local holder = Instance.new("Frame")
	holder.Name = "DividerHolder"
	holder.BorderSizePixel = 0
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, padding)
	holder.BorderColor3 = Color3.fromRGB(0, 0, 0)
	holder.Parent = parent
	-- Divider line, centred inside the holder.
	local frame = Instance.new("Frame")
	frame.Name = "Divider"
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency
	frame.Size = UDim2.new(0.90447, 0, 0, thickness)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame.Parent = holder
	-- Declarative theming: colour + transparency are BINDINGS. A theme switch
	-- re-resolves them automatically -- no ApplyTheme body to forget.
	ThemeManager.BindColor(frame, "BackgroundColor3", "SectionDividerColor")
	local transparencyBinding =
		ThemeManager.BindTransparency(frame, "BackgroundTransparency", "SectionDividerTransparency")
	-- A caller-supplied Color is a theme override: it always wins over the
	-- binding (applyEntry skips overridden props), so it survives theme passes.
	if hasCustomColor then
		ThemeManager.SetColorOverride(frame, "BackgroundColor3", color)
	end
	-- A caller-supplied Transparency DISABLES the transparency binding so the
	-- theme stops driving it. (Overrides cover colours; numbers use the
	-- binding's enable switch, then the value is set directly.)
	if hasCustomTransparency then
		transparencyBinding:SetEnabled(false)
		frame.BackgroundTransparency = transparency
	end
	self.Holder = holder
	self.Frame = frame
	-- Public API
	self.SetColor = function(_self, newColor)
		hasCustomColor = true
		ThemeManager.SetColorOverride(frame, "BackgroundColor3", newColor)
	end
	self.SetTransparency = function(_self, newTransparency)
		hasCustomTransparency = true
		transparencyBinding:SetEnabled(false)
		frame.BackgroundTransparency = newTransparency
	end
	-- Uniform component API (p2-4).
	self.SetVisibility = function(_self, visible)
		holder.Visible = visible
	end
	self.Destroy = function(_self)
		if holder and holder.Parent then
			holder:Destroy()
		end
	end
	return self
end
return Divider
