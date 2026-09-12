--[[
	Status  ·  Aetheris UI Library

	A status readout: a header label plus up to MAX_ENTRIES coloured lines.
	Entry = { key, text, color } where color is a named string ("green" /
	"orange" / "red" / "info") or a Color3. Rich-text colours are emitted as
	hex (see colorToString) because Roblox RichText rejects rgb().

	Usage:
		local status = section:Status({
			Name = "System Status",
			Entries = {
				{ "info", "All systems nominal", "green" },
				{ "alert", "CPU usage high", "orange" },
				{ "custom", "Custom colour", Color3.fromRGB(255, 200, 100) },
			},
		})
]]

local Tween = require("../Utils/Tween")
local ThemeManager = require("../Themes/ThemeManager")

local Status = {}
Status.__index = Status
Status.MAX_ENTRIES = 8
-- Default color mapping
local DEFAULT_COLORS = {
	green = Color3.fromRGB(0, 255, 0),
	orange = Color3.fromRGB(255, 165, 0),
	red = Color3.fromRGB(255, 0, 0),
}
-- Convert a color value to a string suitable for <font color="...">.
-- Roblox RichText accepts hex (#RRGGBB) or named colors, NOT rgb(...).
local function colorToString(color)
	if typeof(color) == "string" then
		local lower = string.lower(color)
		if DEFAULT_COLORS[lower] then
			local c = DEFAULT_COLORS[lower]
			return string.format("#%02X%02X%02X", math.round(c.R*255), math.round(c.G*255), math.round(c.B*255))
		else
			-- Assume it's already a valid color string like "#FF0000"
			return color
		end
	elseif typeof(color) == "Color3" then
		return string.format("#%02X%02X%02X", math.round(color.R*255), math.round(color.G*255), math.round(color.B*255))
	else
		return "#FFFFFF" -- fallback white
	end
end
function Status.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Status)
	self._theme = theme
	local name = Settings.Name or "Status"
	local entries = Settings.Entries or {}
	-- Trim entries to max 8
	if #entries > Status.MAX_ENTRIES then
		for i = Status.MAX_ENTRIES + 1, #entries do
			table.remove(entries, i)
		end
	end
	-- Main container
	local frame = Instance.new("Frame")
	frame.Name = "Status"
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = (theme and theme.ComponentBackgroundColor)
	frame.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.Position = UDim2.new(0, 0, 0, 0)
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame:SetAttribute("IsComponentContainer", true)
	frame.Parent = parent
	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame
	-- Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	-- ElementName label
	local label = Instance.new("TextLabel")
	label.Name = "ElementName"
	label.TextWrapped = true
	label.BorderSizePixel = 0
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTransparency = (theme and theme.PrimaryTextTransparency) or 0.3
	label.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	label.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	label.TextColor3 = (theme and theme.PrimaryTextColor)
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.90908, 0, 0, 20)
	label.Position = UDim2.new(0.043, 0, 0, 8)
	label.BorderColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = name
	label.Parent = frame
	-- StatusTextHolder
	local holder = Instance.new("Frame")
	holder.Name = "StatusTextHolder"
	holder.BorderSizePixel = 0
	holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	holder.BackgroundTransparency = 1
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Size = UDim2.new(0.90756, 0, 0, 0)
	holder.Position = UDim2.new(0.043, 0, 0, 38)
	holder.BorderColor3 = Color3.fromRGB(0, 0, 0)
	holder.Parent = frame
	-- Layout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = holder
	-- Padding
	local padding = Instance.new("UIPadding")
	padding.PaddingBottom = UDim.new(0, 15)
	padding.Parent = holder
	-- Create status entries
	local statusLabels = {}
	for i, entry in ipairs(entries) do
		local title = entry[1] or ""
		local description = entry[2] or ""
		local color = entry[3]
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "StatusText"
		textLabel.TextWrapped = true
		textLabel.TextTruncate = Enum.TextTruncate.AtEnd
		textLabel.BorderSizePixel = 0
		textLabel.TextSize = 13
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextTransparency = (theme and theme.SecondaryTextTransparency) or 0.45
		textLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		textLabel.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
		textLabel.TextColor3 = (theme and theme.SecondaryTextColor)
		textLabel.BackgroundTransparency = 1
		textLabel.RichText = true
		textLabel.Size = UDim2.new(1, 0, 0, 20)
		textLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
		textLabel.Position = UDim2.new(0, 0, -0.4, 8)
		textLabel.Parent = holder
		-- Build rich text
		local colorString = colorToString(color)
		textLabel.Text = string.format('<font weight="SemiBold">%s: </font><font color="%s">%s</font>', title, colorString, description)
		table.insert(statusLabels, textLabel)
	end
	self.Frame = frame
	self.Label = label
	self.Holder = holder
	self.StatusLabels = statusLabels
	self.Entries = entries
	-- Public API
	self.SetVisibility = function(visible)
		frame.Visible = visible
	end
	self.UpdateName = function(newName)
		label.Text = newName
	end
	self.SetEntries = function(newEntries)
		-- Clear existing status labels
		for _, lbl in ipairs(statusLabels) do
			lbl:Destroy()
		end
		statusLabels = {}
		-- Trim to max
		if #newEntries > Status.MAX_ENTRIES then
			for i = Status.MAX_ENTRIES + 1, #newEntries do
				table.remove(newEntries, i)
			end
		end
		self.Entries = newEntries
		-- Rebuild
		for i, entry in ipairs(newEntries) do
			local title = entry[1] or ""
			local description = entry[2] or ""
			local color = entry[3]
			local textLabel = Instance.new("TextLabel")
			textLabel.Name = "StatusText"
			textLabel.TextWrapped = true
			textLabel.TextTruncate = Enum.TextTruncate.AtEnd
			textLabel.BorderSizePixel = 0
			textLabel.TextSize = 13
			textLabel.TextXAlignment = Enum.TextXAlignment.Left
			textLabel.TextTransparency = 0.45
			textLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
			textLabel.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			textLabel.BackgroundTransparency = 1
			textLabel.RichText = true
			textLabel.Size = UDim2.new(1, 0, 0, 20)
			textLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
			textLabel.Position = UDim2.new(0, 0, -0.4, 8)
			textLabel.Parent = self.Holder
			local colorString = colorToString(color)
			textLabel.Text = string.format('<font weight="SemiBold">%s: </font><font color="%s">%s</font>', title, colorString, description)
			table.insert(statusLabels, textLabel)
		end
		self.StatusLabels = statusLabels
	end
	-- Component-owned theming (see ThemeManager registry).
	function self:ApplyTheme(newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		self._theme = theme
		frame.BackgroundColor3 = theme.ComponentBackgroundColor or frame.BackgroundColor3
		frame.BackgroundTransparency = theme.ComponentBackgroundTransparency or frame.BackgroundTransparency
		label.TextColor3 = theme.PrimaryTextColor or label.TextColor3
		if stroke then stroke.Color = theme.StrokeColor or stroke.Color end
		for _, lbl in ipairs(self.StatusLabels or {}) do
			lbl.TextColor3 = theme.SecondaryTextColor or lbl.TextColor3
			lbl.TextTransparency = theme.SecondaryTextTransparency or lbl.TextTransparency
		end
	end
	ThemeManager.Register(frame, self)
	return self
end
return Status