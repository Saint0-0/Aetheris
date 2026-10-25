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

	Per-entry API (entries are keyed by their first field):
		status:SetEntry("cpu", "CPU normal", "green")  -- update text + colour
		status:SetEntry("newKey", "Fresh line")        -- appends (up to MAX)
		status:AddEntry("event", "New line")           -- always appends (up to MAX)
		status:AddEntry("", "Unkeyed line")            -- no "key:" prefix
		status:GetEntry("cpu")                         -- current text or nil
		status:SetEntries({ ... })                     -- replace all entries
]]

local ThemeManager = require("../Themes/ThemeManager")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

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
			return string.format("#%02X%02X%02X", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
		else
			-- Assume it's already a valid color string like "#FF0000"
			return color
		end
	elseif typeof(color) == "Color3" then
		return string.format(
			"#%02X%02X%02X",
			math.round(color.R * 255),
			math.round(color.G * 255),
			math.round(color.B * 255)
		)
	else
		return "#FFFFFF" -- fallback white
	end
end

-- Copy the triplets so callers can keep reusing their own table.
local function copyEntries(source)
	local copy = {}
	for i = 1, math.min(#source, Status.MAX_ENTRIES) do
		local entry = source[i]
		if type(entry) == "table" then
			copy[i] = { entry[1], entry[2], entry[3] }
		end
	end
	return copy
end

function Status.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Status)
	self._theme = theme
	local name = Settings.Name or "Status"
	local entries = copyEntries(Settings.Entries or {})
	-- Main container
	local frame = Instance.new("Frame")
	frame.Name = UUID.Static("Status")
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = (theme and theme.ComponentBackgroundColor)
	frame.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Size = UDim2.fromScale(1, 0)
	frame.Position = UDim2.fromScale(0, 0)
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
	label.Name = UUID.Static("ElementName")
	label.TextWrapped = true
	label.BorderSizePixel = 0
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTransparency = (theme and theme.PrimaryTextTransparency) or 0.3
	label.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	label.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	label.TextColor3 = (theme and theme.PrimaryTextColor)
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.90908, 0, 0, 20)
	label.Position = UDim2.fromOffset(11, 18)
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.BorderColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = name
	label.Parent = frame
	-- Declarative theming: every themed property is a BINDING -- no ApplyTheme
	-- body to forget. Bind applies immediately and re-resolves each switch.
	ThemeManager.BindColor(frame, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(frame, "BackgroundTransparency", "ComponentBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	-- StatusTextHolder
	local holder = Instance.new("Frame")
	holder.Name = UUID.Static("StatusTextHolder")
	holder.BorderSizePixel = 0
	holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	holder.BackgroundTransparency = 1
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Size = UDim2.fromScale(0.90756, 0)
	holder.Position = UDim2.fromOffset(11, 38)
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
	-- Reusable label factory: initial build and SetEntries share it so both
	-- paths pick up the same rich-text + theme bindings. An empty key renders
	-- just the coloured text (no dangling "key:" prefix).
	local function applyEntryText(textLabel, entry)
		local key = entry[1]
		if key and key ~= "" then
			textLabel.Text = string.format(
				'<font weight="SemiBold">%s: </font><font color="%s">%s</font>',
				key,
				colorToString(entry[3]),
				entry[2] or ""
			)
		else
			textLabel.Text = string.format('<font color="%s">%s</font>', colorToString(entry[3]), entry[2] or "")
		end
	end

	local function makeLabel(parentHolder, entry)
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = UUID.Generate("StatusEntry")
		textLabel.TextWrapped = true
		textLabel.TextTruncate = Enum.TextTruncate.AtEnd
		textLabel.BorderSizePixel = 0
		textLabel.TextSize = 13
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextTransparency = (theme and theme.SecondaryTextTransparency) or 0.45
		textLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		textLabel.FontFace = Constants.Font(Enum.FontWeight.Medium)
		textLabel.TextColor3 = (theme and theme.SecondaryTextColor)
		textLabel.BackgroundTransparency = 1
		textLabel.RichText = true
		textLabel.Size = UDim2.new(1, 0, 0, 20)
		textLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
		textLabel.Position = UDim2.fromOffset(11, 0)
		textLabel.Parent = parentHolder
		ThemeManager.BindColor(textLabel, "TextColor3", "SecondaryTextColor")
		ThemeManager.BindTransparency(textLabel, "TextTransparency", "SecondaryTextTransparency")
		applyEntryText(textLabel, entry)
		return textLabel
	end

	local statusLabels = {}
	local entryByKey = {}
	for _, entry in ipairs(entries) do
		local textLabel = makeLabel(holder, entry)
		table.insert(statusLabels, textLabel)
		local key = tostring(entry[1] or "")
		if key ~= "" then
			entryByKey[key] = { label = textLabel, entry = entry }
		end
	end
	self.Frame = frame
	self.Label = label
	self.Holder = holder
	self.StatusLabels = statusLabels
	self.Entries = entries
	-- Public API
	self._name = name
	self.SetName = function(me, newName)
		me._name = newName
		label.Text = newName
	end
	self.UpdateName = self.SetName
	self.SetEntries = function(me, newEntries)
		for _, lbl in ipairs(statusLabels) do
			ThemeManager.UnbindInstance(lbl)
			lbl:Destroy()
		end
		statusLabels = {}
		entryByKey = {}
		local copy = copyEntries(newEntries or {})
		me.Entries = copy
		for _, entry in ipairs(copy) do
			local textLabel = makeLabel(me.Holder, entry)
			table.insert(statusLabels, textLabel)
			local key = tostring(entry[1] or "")
			if key ~= "" then
				entryByKey[key] = { label = textLabel, entry = entry }
			end
		end
		me.StatusLabels = statusLabels
		return me
	end
	self.SetEntry = function(me, key, text, color)
		key = tostring(key)
		local record = entryByKey[key]
		if record then
			record.entry[2] = text
			if color ~= nil then
				record.entry[3] = color
			end
			applyEntryText(record.label, record.entry)
			return record.label
		end
		if #me.Entries >= Status.MAX_ENTRIES then
			return nil
		end
		local entry = { key, text or "", color }
		table.insert(me.Entries, entry)
		local textLabel = makeLabel(me.Holder, entry)
		table.insert(statusLabels, textLabel)
		entryByKey[key] = { label = textLabel, entry = entry }
		me.StatusLabels = statusLabels
		return textLabel
	end
	-- Append-only: never updates an existing line, unlike SetEntry. key = ""
	-- (or nil) for an unkeyed line; returns nil once MAX_ENTRIES is reached.
	self.AddEntry = function(me, key, text, color)
		key = tostring(key or "")
		if #me.Entries >= Status.MAX_ENTRIES then
			return nil
		end
		local entry = { key, text or "", color }
		table.insert(me.Entries, entry)
		local textLabel = makeLabel(me.Holder, entry)
		table.insert(statusLabels, textLabel)
		if key ~= "" then
			entryByKey[key] = { label = textLabel, entry = entry }
		end
		me.StatusLabels = statusLabels
		return textLabel
	end
	self.GetEntry = function(_, key)
		local record = entryByKey[tostring(key)]
		return record and record.entry[2] or nil
	end
	self.GetEntries = function(me)
		return copyEntries(me.Entries)
	end
	self.SetVisible = function(me, visible)
		me.Frame.Visible = visible
	end
	self.SetVisibility = self.SetVisible
	self.GetVisible = function(me)
		return me.Frame.Visible
	end
	self.Destroy = function(me)
		for _, lbl in ipairs(statusLabels) do
			ThemeManager.UnbindInstance(lbl)
		end
		if me.Frame then
			for _, descendant in ipairs(me.Frame:GetDescendants()) do
				ThemeManager.UnbindInstance(descendant)
			end
			ThemeManager.UnbindInstance(me.Frame)
			me.Frame:Destroy()
			me.Frame = nil
		end
		statusLabels = {}
		entryByKey = {}
	end
	return self
end
return Status
