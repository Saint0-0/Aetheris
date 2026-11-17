--[[
	Aetheris/Components/Console.luau

	A monospaced block for code or log output. It holds the given height and
	scrolls internally, so a filling console never pushes the page down.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
	Based on Rayfield Gen 2 code (MPL-2.0)
	https://github.com/SiriusSoftwareLtd/rayfield-gen2
]]

local ThemeManager = require("../Themes/ThemeManager")
local ComponentAPI = require("../Utils/ComponentAPI")
local Locale = require("../Utils/Locale")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

local Console = {}
Console.__index = Console

local defaultHeight = 120
local minHeight = 48
local titleHeight = 24
local padding = 12
local textPadding = 10
local textSize = 12
local lineHeight = 1.25 -- Dense line spacing.
local defaultMaxLines = 200

-- Monospace so columns line up; this is output, not brand copy.
local monoFont = Font.fromEnum(Enum.Font.Code)

function Console.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}

	local self = setmetatable({}, Console)
	self._theme = theme
	self._parent = parent
	self._name = Settings.Name
	self._height = math.max(tonumber(Settings.Height) or defaultHeight, minHeight)
	self._follow = Settings.Follow == true
	self._maxLines = math.max(tonumber(Settings.MaxLines) or defaultMaxLines, 1)

	self._lines = {}
	-- Ring pool: appends rewrite one label, so cost stays constant.
	self._lineLabels = {}
	self._head = 1 -- the pooled label holding the oldest line
	self._nextOrder = 1
	self._dirty = true
	self._textTransparency = theme.PrimaryTextTransparency or 0.15
	-- Opt-in; when off, output is literal text.
	self._richText = Settings.RichText == true

	self:_build()
	self:Set(Settings.Text or "")

	ComponentAPI.Apply(self, {
		Root = function(me)
			return me._main
		end,
		OnName = function(me, newName)
			if me._title then
				Locale.set(me._title, "Text", newName)
				me._title.Visible = newName ~= nil and newName ~= ""
			end
		end,
	})

	return self
end

-- Created once then recycled; the pool never exceeds maxLines.
function Console:_makeLabel()
	local label = Instance.new("TextLabel")
	label.Name = UUID.Generate("ConsoleLine")
	label.Size = UDim2.fromScale(1, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.FontFace = monoFont
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.LineHeight = lineHeight
	label.RichText = self._richText
	label.TextColor3 = self._theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
	label.TextTransparency = self._textTransparency
	label.Parent = self._scroll
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	return label
end

function Console:_build()
	local theme = self._theme
	local top = if self._name then titleHeight else 0

	local main = Instance.new("Frame")
	main.Name = UUID.Generate("Console")
	main.BorderSizePixel = 0
	main.BackgroundColor3 = theme.ComponentBackgroundColor or Color3.fromRGB(30, 30, 34)
	main.BackgroundTransparency = theme.ComponentBackgroundTransparency or 0
	main.Size = UDim2.new(1, 0, 0, self._height + top + padding * 2)
	main.Parent = self._parent
	self._main = main

	ThemeManager.BindColor(main, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(main, "BackgroundTransparency", "ComponentBackgroundTransparency")

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = main

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.StrokeColor or Color3.fromRGB(255, 255, 255)
	stroke.Transparency = theme.StrokeTransparency or 0.9
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = main
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	-- Re-stamp after the bind, which only writes on a theme change.
	stroke.Transparency = theme.StrokeTransparency or 0.9
	self._stroke = stroke

	if self._name then
		local title = Instance.new("TextLabel")
		title.Name = UUID.Static("Title")
		title.BorderSizePixel = 0
		title.BackgroundTransparency = 1
		Locale.set(title, "Text", self._name)
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
		title.TextColor3 = theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
		title.Position = UDim2.fromOffset(padding, 8)
		title.Size = UDim2.new(1, -padding * 2, 0, titleHeight - 8)
		title.Parent = main
		ThemeManager.BindColor(title, "TextColor3", "PrimaryTextColor")
		ThemeManager.BindTransparency(title, "TextTransparency", "PrimaryTextTransparency")
		self._title = title
	end

	-- Darker than the element it sits on.
	local panel = Instance.new("Frame")
	panel.Name = UUID.Static("Panel")
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -padding)
	panel.Size = UDim2.new(1, -padding * 2, 0, self._height)
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	panel.BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(20, 20, 22)
	panel.BackgroundTransparency = 0.15
	panel.Parent = main
	self._panel = panel
	ThemeManager.BindColor(panel, "BackgroundColor3", "InputBackgroundColor")

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 6)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	panelStroke.Color = theme.StrokeColor or Color3.fromRGB(255, 255, 255)
	panelStroke.Transparency = 0.9
	panelStroke.Parent = panel
	ThemeManager.BindColor(panelStroke, "Color", "StrokeColor")
	self._panelStroke = panelStroke

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = UUID.Static("Scroll")
	scroll.Size = UDim2.new(1, -textPadding * 2, 1, -textPadding * 2)
	scroll.Position = UDim2.fromScale(0.5, 0.5)
	scroll.AnchorPoint = Vector2.new(0.5, 0.5)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.fromScale(0, 0)
	scroll.ScrollBarThickness = 0
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = panel
	self._scroll = scroll
	-- No scroll edge fade; the panel rim already frames the logs.

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.FillDirection = Enum.FillDirection.Vertical
	scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	scrollLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Parent = scroll
	self._scrollLayout = scrollLayout

	self:_watchCanvas()
end

-- A blank line still needs a row; an empty label collapses.
local function rowText(line)
	return if line == "" then " " else line
end

-- Roblox clamps past-the-end positions, so no viewport maths is needed.
function Console:_pin()
	local scroll = self._scroll
	if not scroll or not scroll.Parent then
		return
	end
	scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
end

function Console:_followBottom()
	if not self._follow then
		return
	end
	self:_pin()
	task.defer(function()
		self:_pin()
	end)
end

-- Pin on content size; the canvas settles a frame after rows change.
function Console:_watchCanvas()
	self._canvasConn = self._scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if self._follow then
			self:_pin()
		end
	end)
end

-- Built on demand; joining per append would cost O(n).
function Console:Get()
	if self._dirty then
		self._text = table.concat(self._lines, "\n")
		self._dirty = false
	end
	return self._text or ""
end

-- Whole-body replacements only; Append takes its own O(1) route.
function Console:_flush()
	self._dirty = true

	for index, line in ipairs(self._lines) do
		local label = self._lineLabels[index]
		if not label then
			label = self:_makeLabel()
			self._lineLabels[index] = label
		end
		label.LayoutOrder = index
		label.Text = rowText(line)
		label.Visible = true
	end

	for index = #self._lines + 1, #self._lineLabels do
		self._lineLabels[index].Visible = false
	end

	self._head = 1
	self._nextOrder = #self._lines + 1
	self:_followBottom()
end

-- Uses table.move instead of repeated table.remove.
function Console:_trim()
	local excess = #self._lines - self._maxLines
	if excess <= 0 then
		return
	end
	table.move(self._lines, excess + 1, #self._lines, 1)
	for index = #self._lines, #self._lines - excess + 1, -1 do
		self._lines[index] = nil
	end
end

function Console:_setLines(text)
	text = if type(text) == "string" then text else tostring(text)

	table.clear(self._lines)
	if text ~= "" then
		for line in string.gmatch(text .. "\n", "([^\n]*)\n") do
			table.insert(self._lines, line)
		end
	end
	self:_trim()
	self:_flush()
end

-- At capacity the oldest row is recycled, so cost stays constant.
function Console:_pushLine(line)
	self._dirty = true

	if #self._lines < self._maxLines then
		table.insert(self._lines, line)
		local index = #self._lines
		local label = self._lineLabels[index]
		if not label then
			label = self:_makeLabel()
			self._lineLabels[index] = label
		end
		label.LayoutOrder = self._nextOrder
		label.Text = rowText(line)
		label.Visible = true
		self._nextOrder += 1
		return
	end

	-- Full: hand the oldest row to the newest line in one bulk copy.
	table.move(self._lines, 2, #self._lines, 1)
	self._lines[#self._lines] = line

	local label = self._lineLabels[self._head]
	label.LayoutOrder = self._nextOrder
	label.Text = rowText(line)
	label.Visible = true

	self._nextOrder += 1
	self._head = (self._head % #self._lineLabels) + 1
end

function Console:Set(text)
	self:_setLines(text)
end

-- Appends to the end; the oldest line rolls off once full.
function Console:Append(line)
	line = if type(line) == "string" then line else tostring(line)
	for part in string.gmatch(line .. "\n", "([^\n]*)\n") do
		self:_pushLine(part)
	end
	self:_followBottom()
end

function Console:Clear()
	table.clear(self._lines)
	self:_flush()
end

-- The panel takes the height; the element grows around it.
function Console:SetHeight(height)
	self._height = math.max(tonumber(height) or defaultHeight, minHeight)
	local top = if self._name then titleHeight else 0
	self._panel.Size = UDim2.new(1, -padding * 2, 0, self._height)
	self._main.Size = UDim2.new(1, 0, 0, self._height + top + padding * 2)
end

-- Restamp transparencies after a theme switch; colours ride the binds.
function Console:ApplyTheme(newTheme)
	self._theme = ThemeManager.GetTheme(newTheme)
	self._panel.BackgroundTransparency = 0.15
	self._panelStroke.Transparency = 0.9
end

function Console:Destroy()
	if self._canvasConn then
		self._canvasConn:Disconnect()
		self._canvasConn = nil
	end
	if self._main then
		self._main:Destroy()
		self._main = nil
	end
end

return Console
