--[[
	ComponentRow  ·  Aetheris UI Library

	Shared factory for the standard settings row: a full-width container with a
	left-aligned themed name label. Returns (row, label); the caller parents its
	control straight into `row`.

	Every component used to hand-build this boilerplate. Centralising it means a
	row is defined in ONE place (sleek + consistent), with NO extra wrapper frame
	and NO UIShadow (both per-row costs we deliberately avoid).

	Usage:
		local row, label = ComponentRow.new(parent, {
			Name       = "Field Name",
			Theme      = theme,          -- optional; stamps + live-binds label colour
			RowName    = "Foo",          -- optional exact row name (else `Name`)
			Height     = 45,             -- optional, default 45
			Clickable  = false,          -- optional; TextButton row when true
			LabelWidth = 0.486,          -- optional fraction, default 0.486
			LabelHeight = 0.714,         -- optional fraction, default 0.714
			-- optional decorations (default: none / plain transparent row)
			BackgroundColor       = Color3,
			BackgroundTransparency= number,
			ClipsDescendants      = bool,
			CornerRadius          = number,   -- adds a UICorner
			Stroke                = bool,     -- adds a themed UIStroke
			ComponentContainer    = bool,     -- sets IsComponentContainer attr
			LabelPosition         = UDim2,    -- override label Position
			LabelTextSize         = number,   -- override label TextSize
		})
]]

local ThemeManager = require("../Themes/ThemeManager")
local Constants = require("../Constants")

local ComponentRow = {}

function ComponentRow.new(parent, Settings)
	Settings = Settings or {}
	local name = Settings.Name or "Element"
	local theme = Settings.Theme
	local height = Settings.Height or 45
	local clickable = Settings.Clickable == true
	local labelWidth = Settings.LabelWidth or 0.486
	local labelHeight = Settings.LabelHeight or 0.714

	local row
	if clickable then
		row = Instance.new("TextButton")
		row.Text = ""
		row.TextTransparency = 1
		row.AutoButtonColor = false
	else
		row = Instance.new("Frame")
	end
	row.Name = Settings.RowName or name
	row.BorderSizePixel = 0
	row.BackgroundColor3 = Settings.BackgroundColor or Color3.fromRGB(31, 32, 34)
	row.BackgroundTransparency = (Settings.BackgroundTransparency == nil) and 1 or Settings.BackgroundTransparency
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Size = UDim2.new(1, 0, 0, height)
	row.Position = UDim2.fromScale(0.5, 0.5)
	if Settings.ClipsDescendants then
		row.ClipsDescendants = true
	end
	if Settings.ComponentContainer then
		row:SetAttribute("IsComponentContainer", true)
	end
	row.Parent = parent

	if Settings.CornerRadius then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, Settings.CornerRadius)
		corner.Parent = row
	end
	if Settings.Stroke then
		local stroke = Instance.new("UIStroke")
		stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
		stroke.Color = (theme and theme.StrokeColor)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = row
		-- Bind the stroke so it re-themes on every switch (was stamped once
		-- from construction-time theme and never updated).
		ThemeManager.BindColor(stroke, "Color", "StrokeColor")
		ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	end

	local label = Instance.new("TextLabel")
	label.Name = "ElementName"
	label.BorderSizePixel = 0
	label.FontFace = Constants.Font(Enum.FontWeight.Regular)
	label.Text = name
	label.TextSize = Settings.LabelTextSize or 14
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.AnchorPoint = Settings.LabelAnchorPoint or Vector2.new(0, 0.5)
	label.BackgroundTransparency = 1
	if Settings.LabelAutoSize then
		-- Hug the name text: X size 0 + AutomaticSize.X. Callers that need a
		-- variable-width label (e.g. TextInput's field cap) opt in with this.
		label.TextWrapped = false
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.fromScale(0, labelHeight)
	else
		label.Size = UDim2.fromScale(labelWidth, labelHeight)
	end
	label.Position = Settings.LabelPosition or UDim2.fromScale(0, 0.5)
	label.Parent = row

	if theme then
		label.TextColor3 = theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
		label.TextTransparency = theme.PrimaryTextTransparency or 0.45
	else
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextTransparency = 0.45
	end
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")

	return row, label
end

return ComponentRow
