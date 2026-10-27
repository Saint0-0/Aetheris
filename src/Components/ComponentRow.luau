--[[
	Aetheris/Components/ComponentRow.luau

	Shared factory for the standard settings row: a full-width container with a
	left-aligned themed name label. Returns (row, label) so the caller can parent
	its control straight into the row; centralising the boilerplate keeps every
	component's row consistent with no extra wrapper frame or shadow.
	License: Saint0-0 Source License - use in your own scripts, no editing or
	redistribution without permission. (c) 2026 Saint0-0.
]]

local ThemeManager = require("../Themes/ThemeManager")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

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
	row.Name = UUID.Generate(Settings.RowName or "ComponentRow")
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
		row:SetAttribute(UUID.Static("IsComponentContainer"), true)
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
		-- Bind the stroke so it re-themes on every switch.
		ThemeManager.BindColor(stroke, "Color", "StrokeColor")
		ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	end

	local label = Instance.new("TextLabel")
	label.Name = UUID.Static("ElementName")
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
		-- Hug the name text (X size 0 + AutomaticSize.X) for callers that need a
		-- variable-width label, like TextInput's field cap.
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
