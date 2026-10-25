--[[
	CodeView  ·  Aetheris UI Library

	A syntax-highlighted code block with line numbers: view mode renders
	theme-tinted RichText and (when Editable) a click swaps in a multiline
	TextBox that re-highlights on blur. The header's copy button forwards the
	current content to Settings.OnCopy — wire setclipboard there.
]]

local ThemeManager = require("../Themes/ThemeManager")
local Constants = require("../Constants")
local SyntaxHighlight = require("../Utils/SyntaxHighlight")
local ComponentAPI = require("../Utils/ComponentAPI")
local UUID = require("../Utils/UUID")

-- Not a selene-known global; fetched here once rather than per relayout.
local TextService = game:GetService("TextService")

local CodeView = {}
CodeView.__index = CodeView

local defaultHeight = 140
local minHeight = 72
local titleHeight = 24 -- header row: optional title left, copy button right
local padding = 12 -- inset around the panel inside the element
local textPadding = 10 -- inside the panel
local textSize = 13
local lineHeight = 1 -- explicit: gutter measurement assumes natural line advance
local gutterWidth = 36 -- line-number column, same x band in view and edit modes
local relayoutDelay = 0.12 -- coalesce typing bursts into one re-measure
local copyButtonWidth = 52

-- Monospace for the code itself (and the numbers): the brand font would
-- shift columns around on every glyph.
local monoFont = Font.fromEnum(Enum.Font.Code)

local function blend(a: Color3, b: Color3, t: number): Color3
	return a:Lerp(b, t)
end

-- Theme-tinted syntax palette. Each class is a hue offset from the theme
-- accent so relationships between colours survive every theme, while the
-- panel's luminance picks bright or dark values so tokens stay readable.
local function buildPalette(theme)
	local panel = theme.InputBackgroundColor or theme.ComponentBackgroundColor or Color3.fromRGB(24, 24, 28)
	local luminance = 0.2126 * panel.R + 0.7152 * panel.G + 0.0722 * panel.B
	local dark = luminance < 0.5
	local accent = theme.AccentColor or Color3.fromRGB(120, 140, 255)
	local baseHue = select(1, Color3.toHSV(accent))
	local function hue(offset: number, sat: number, valueDark: number, valueLight: number): Color3
		return Color3.fromHSV((baseHue + offset) % 1, sat, if dark then valueDark else valueLight)
	end
	local secondary = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
	local towardPanel = if dark then 0.15 else 0.35
	return {
		keyword = hue(0.00, 0.55, 0.97, 0.45),
		constant = hue(0.08, 0.50, 0.92, 0.42),
		func = hue(0.16, 0.60, 1.00, 0.48),
		builtin = hue(0.24, 0.45, 0.92, 0.45),
		type = hue(0.34, 0.50, 0.95, 0.45),
		number = hue(0.44, 0.65, 0.97, 0.48),
		string = hue(0.58, 0.50, 0.92, 0.42),
		operator = blend(secondary, panel, towardPanel),
		punct = blend(secondary, panel, towardPanel + 0.2),
		comment = blend(secondary, panel, towardPanel + 0.4),
	}
end

local function normalizeLanguage(language: any?): string
	local lang = string.lower(tostring(language or "lua"))
	if lang == "luau" then
		return "lua"
	elseif lang == "js" then
		return "javascript"
	elseif lang == "py" then
		return "python"
	end
	return lang
end

local function splitLines(text: string): { string }
	return string.split(text, "\n")
end

function CodeView.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}

	local self = setmetatable({}, CodeView)
	self._theme = theme
	self._parent = parent
	self._name = Settings.Name
	self._text = if type(Settings.Text) == "string" then Settings.Text else tostring(Settings.Text or "")
	self._language = normalizeLanguage(Settings.Language)
	self._editable = Settings.Editable == true
	self._onCopy = Settings.OnCopy
	self._height = math.max(tonumber(Settings.Height) or defaultHeight, minHeight)
	self._editing = false
	self._destroyed = false
	self._relayoutVersion = 0
	self._rows = {}
	self._conns = {}
	self._palette = buildPalette(theme)

	self:_build()
	self:_buildRows()

	ComponentAPI.Apply(self, {
		Root = function(me)
			return me._main
		end,
		Name = Settings.Name,
		OnName = function(me, newName)
			me._title.Text = tostring(newName or "")
			me._title.Visible = newName ~= nil and newName ~= ""
		end,
	})

	return self
end

function CodeView:_build()
	local theme = self._theme

	local main = Instance.new("Frame")
	main.Name = UUID.Generate("CodeView")
	main.BorderSizePixel = 0
	main.BackgroundColor3 = theme.ComponentBackgroundColor or Color3.fromRGB(30, 30, 34)
	main.BackgroundTransparency = theme.ComponentBackgroundTransparency or 0
	main.Size = UDim2.new(1, 0, 0, self._height + titleHeight + padding * 2)
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
	-- Re-stamp after the bind: BindTransparency only writes on a theme CHANGE.
	stroke.Transparency = theme.StrokeTransparency or 0.9

	-- Header: optional name on the left, copy button pinned top-right.
	local title = Instance.new("TextLabel")
	title.Name = UUID.Static("Title")
	title.BorderSizePixel = 0
	title.BackgroundTransparency = 1
	title.Text = tostring(self._name or "")
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	title.TextColor3 = theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
	title.Position = UDim2.fromOffset(padding, 0)
	title.Size = UDim2.new(1, -(padding * 2 + copyButtonWidth + 8), 0, titleHeight)
	title.Visible = self._name ~= nil and self._name ~= ""
	title.Parent = main
	ThemeManager.BindColor(title, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(title, "TextTransparency", "PrimaryTextTransparency")
	self._title = title

	local copyBtn = Instance.new("TextButton")
	copyBtn.Name = UUID.Static("CopyButton")
	copyBtn.Text = "Copy"
	copyBtn.AutoButtonColor = false
	copyBtn.BorderSizePixel = 0
	copyBtn.BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(20, 20, 22)
	copyBtn.BackgroundTransparency = 1
	copyBtn.FontFace = Constants.Font(Enum.FontWeight.Medium)
	copyBtn.TextSize = 12
	copyBtn.TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
	copyBtn.AnchorPoint = Vector2.new(1, 0)
	copyBtn.Position = UDim2.new(1, -padding, 0, 2)
	copyBtn.Size = UDim2.fromOffset(copyButtonWidth, 20)
	copyBtn.Parent = main
	local copyCorner = Instance.new("UICorner")
	copyCorner.CornerRadius = UDim.new(0, 6)
	copyCorner.Parent = copyBtn
	ThemeManager.BindColor(copyBtn, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindColor(copyBtn, "TextColor3", "SecondaryTextColor")
	self._copyBtn = copyBtn

	copyBtn.MouseEnter:Connect(function()
		if self._destroyed then
			return
		end
		self._hoveringCopy = true
		copyBtn.BackgroundTransparency = 0.8
		copyBtn.TextColor3 = self._theme.AccentColor or copyBtn.TextColor3
	end)
	copyBtn.MouseLeave:Connect(function()
		if self._destroyed then
			return
		end
		self._hoveringCopy = false
		copyBtn.BackgroundTransparency = 1
		copyBtn.TextColor3 = self._theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
	end)
	-- The executor-side clipboard hook lives with the caller (setclipboard is
	-- executor-only), so the button is inert until OnCopy is provided.
	table.insert(
		self._conns,
		copyBtn.MouseButton1Click:Connect(function()
			if type(self._onCopy) == "function" then
				local ok, err = pcall(self._onCopy, self:GetContent(), self)
				if not ok then
					warn("[Aetheris] CodeView OnCopy error: " .. tostring(err))
				end
			end
		end)
	)

	-- Inner panel the code scrolls inside: darker than the card, terminal-like.
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
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
	scroll.ScrollBarImageTransparency = 0.4
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = panel
	self._scroll = scroll
	ThemeManager.BindColor(scroll, "ScrollBarImageColor3", "SecondaryTextColor")

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll
	self._layout = layout

	-- Edit stack: a layout child holding the TextBox offset past the number
	-- band, so edit-mode text lands in the same column as view-mode code.
	local editStack = Instance.new("Frame")
	editStack.Name = UUID.Static("EditStack")
	editStack.BackgroundTransparency = 1
	editStack.BorderSizePixel = 0
	editStack.Size = UDim2.fromScale(1, 0)
	editStack.LayoutOrder = 0
	editStack.Visible = false
	editStack.Parent = scroll
	self._editStack = editStack

	local box = Instance.new("TextBox")
	box.Name = UUID.Static("EditBox")
	box.MultiLine = true
	box.ClearTextOnFocus = false
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.FontFace = monoFont
	box.TextSize = textSize
	box.LineHeight = lineHeight
	box.TextWrapped = true
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Top
	box.RichText = false
	box.TextColor3 = theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
	box.Position = UDim2.fromOffset(gutterWidth, 0)
	box.Size = UDim2.new(1, -gutterWidth, 0, 0)
	box.Text = ""
	box.Visible = false
	box.Parent = editStack
	self._box = box
	ThemeManager.BindColor(box, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(box, "TextTransparency", "PrimaryTextTransparency")

	-- Static line-number column: only shown while editing (view mode keeps its
	-- numbers inline with each row, so both share the same x band).
	local gutterClip = Instance.new("Frame")
	gutterClip.Name = UUID.Static("GutterClip")
	gutterClip.Position = UDim2.fromOffset(textPadding, textPadding)
	gutterClip.Size = UDim2.new(0, gutterWidth, 1, -textPadding * 2)
	gutterClip.BackgroundTransparency = 1
	gutterClip.BorderSizePixel = 0
	gutterClip.ClipsDescendants = true
	gutterClip.Visible = false
	gutterClip.Parent = panel
	self._gutterClip = gutterClip

	local gutterInner = Instance.new("Frame")
	gutterInner.Name = UUID.Static("GutterInner")
	gutterInner.BackgroundTransparency = 1
	gutterInner.BorderSizePixel = 0
	gutterInner.Size = UDim2.fromScale(1, 0)
	gutterInner.Parent = gutterClip
	self._gutterInner = gutterInner

	local gutterLayout = Instance.new("UIListLayout")
	gutterLayout.FillDirection = Enum.FillDirection.Vertical
	gutterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	gutterLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	gutterLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gutterLayout.Parent = gutterInner
	self._gutterLayout = gutterLayout

	-- Wiring: focus swap, typing re-measure, gutter scroll sync, resize.
	table.insert(
		self._conns,
		box.FocusLost:Connect(function()
			self:_exitEdit(true)
		end)
	)
	table.insert(
		self._conns,
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if self._editing then
				self:_scheduleRelayout()
			end
		end)
	)
	table.insert(
		self._conns,
		scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			self:_syncGutterPosition()
		end)
	)
	table.insert(
		self._conns,
		scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if self._editing then
				self:_scheduleRelayout()
			end
		end)
	)

	self._unregisterTheme = ThemeManager.OnThemeApplied(function(liveTheme)
		self:_applyTheme(liveTheme)
	end, main)
end

-- One row per line: number label + highlighted code label, both mono. The row
-- auto-sizes to the wrapped code label, so numbers stay pinned to each line's
-- first row no matter how it wraps.
function CodeView:_buildRows()
	for _, row in ipairs(self._rows) do
		for _, descendant in ipairs(row:GetDescendants()) do
			ThemeManager.UnbindInstance(descendant)
		end
		row:Destroy()
	end
	table.clear(self._rows)
	if self._editing then
		return
	end

	local lines = splitLines(self._text)
	local rich = splitLines(SyntaxHighlight.Render(self._text, self._language, self._palette))

	for index in ipairs(lines) do
		local row = Instance.new("Frame")
		row.Name = UUID.Generate("CodeRow")
		row.BackgroundTransparency = 1
		row.BorderSizePixel = 0
		row.Size = UDim2.fromScale(1, 0)
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.LayoutOrder = index
		row.Parent = self._scroll

		local num = Instance.new("TextLabel")
		num.Name = UUID.Static("LineNumber")
		num.BackgroundTransparency = 1
		num.BorderSizePixel = 0
		num.FontFace = monoFont
		num.TextSize = textSize
		num.LineHeight = lineHeight
		num.TextXAlignment = Enum.TextXAlignment.Right
		num.TextYAlignment = Enum.TextYAlignment.Top
		num.TextColor3 = self._theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
		num.TextTransparency = 0.5
		num.Text = tostring(index)
		num.Position = UDim2.fromOffset(0, 0)
		num.Size = UDim2.fromOffset(gutterWidth - 8, 0)
		num.AutomaticSize = Enum.AutomaticSize.Y
		num.Parent = row
		ThemeManager.BindColor(num, "TextColor3", "SecondaryTextColor")

		local code = Instance.new("TextLabel")
		code.Name = UUID.Static("CodeLine")
		code.BackgroundTransparency = 1
		code.BorderSizePixel = 0
		code.FontFace = monoFont
		code.TextSize = textSize
		code.LineHeight = lineHeight
		code.TextWrapped = true
		code.RichText = true
		code.TextXAlignment = Enum.TextXAlignment.Left
		code.TextYAlignment = Enum.TextYAlignment.Top
		code.TextColor3 = self._theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
		-- An empty line collapses to nothing; one space keeps its row.
		code.Text = if rich[index] ~= nil and rich[index] ~= "" then rich[index] else " "
		code.Position = UDim2.fromOffset(gutterWidth, 0)
		code.Size = UDim2.new(1, -gutterWidth, 0, 0)
		code.AutomaticSize = Enum.AutomaticSize.Y
		code.Parent = row
		ThemeManager.BindColor(code, "TextColor3", "PrimaryTextColor")
		ThemeManager.BindTransparency(code, "TextTransparency", "PrimaryTextTransparency")

		if self._editable then
			row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					self:_enterEdit()
				end
			end)
		end

		table.insert(self._rows, row)
	end
end

function CodeView:_enterEdit()
	if not self._editable or self._editing or self._destroyed then
		return
	end
	self._editing = true
	for _, row in ipairs(self._rows) do
		row.Visible = false
	end
	self._editStack.Visible = true
	self._gutterClip.Visible = true
	self._box.Text = self._text
	self:_scheduleRelayout()
	task.defer(function()
		if not self._destroyed then
			self._box:CaptureFocus()
		end
	end)
end

-- commit = the focus loss came from a click elsewhere; take the box's text as
-- the new source and rebuild the highlighted view on top of it.
function CodeView:_exitEdit(commit: boolean)
	if not self._editing then
		return
	end
	self._editing = false
	if commit then
		self._text = self._box.Text
	end
	self._box.Visible = false
	self._editStack.Visible = false
	self._gutterClip.Visible = false
	self:_buildRows()
end

function CodeView:_scheduleRelayout()
	self._relayoutVersion += 1
	local version = self._relayoutVersion
	task.delay(relayoutDelay, function()
		if not self._destroyed and version == self._relayoutVersion then
			self:_relayout()
		end
	end)
end

-- Edit mode only: measure every (wrapped) line so the TextBox and the static
-- gutter agree on where each line starts. Width 0 means the first layout pass
-- hasn't run; the AbsoluteSize watcher re-schedules once it has.
function CodeView:_relayout()
	if not self._editing then
		return
	end
	local width = self._scroll.AbsoluteSize.X - gutterWidth
	if width <= 0 then
		return
	end

	local lines = splitLines(self._box.Text)
	local total = 0
	local heights = {}
	for index, line in ipairs(lines) do
		local probe = if line == "" then " " else line
		local bounds = TextService:GetTextSize(probe, textSize, monoFont, Vector2.new(width, 100000))
		local rowHeight = math.max(bounds.Y, textSize)
		heights[index] = rowHeight
		total += rowHeight
	end

	self._editStack.Size = UDim2.new(1, 0, 0, total)
	self._box.Size = UDim2.new(1, -gutterWidth, 0, total)
	self._gutterInner.Size = UDim2.new(1, 0, 0, total)

	for _, child in ipairs(self._gutterInner:GetChildren()) do
		if child:IsA("TextLabel") then
			ThemeManager.UnbindInstance(child)
			child:Destroy()
		end
	end
	for index, rowHeight in ipairs(heights) do
		local num = Instance.new("TextLabel")
		num.Name = UUID.Generate("GutterLine")
		num.BackgroundTransparency = 1
		num.BorderSizePixel = 0
		num.FontFace = monoFont
		num.TextSize = textSize
		num.LineHeight = lineHeight
		num.TextXAlignment = Enum.TextXAlignment.Right
		num.TextYAlignment = Enum.TextYAlignment.Top
		num.TextColor3 = self._theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
		num.TextTransparency = 0.5
		num.Text = tostring(index)
		num.Size = UDim2.new(1, -8, 0, rowHeight)
		num.LayoutOrder = index
		num.Parent = self._gutterInner
		ThemeManager.BindColor(num, "TextColor3", "SecondaryTextColor")
	end
	self:_syncGutterPosition()
end

function CodeView:_syncGutterPosition()
	self._gutterInner.Position = UDim2.fromOffset(0, -math.floor(self._scroll.CanvasPosition.Y))
end

function CodeView:_applyTheme(liveTheme)
	if self._destroyed then
		return
	end
	self._theme = ThemeManager.GetTheme(liveTheme)
	self._palette = buildPalette(self._theme)
	-- Colour sides ride the bindings; transparencies need a restamp.
	self._panel.BackgroundTransparency = 0.15
	self._panelStroke.Transparency = 0.9
	if not self._hoveringCopy then
		self._copyBtn.BackgroundTransparency = 1
		self._copyBtn.TextColor3 = self._theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
	end
	if self._editing then
		self:_scheduleRelayout()
	else
		self:_buildRows()
	end
end

function CodeView:SetText(text)
	self._text = if type(text) == "string" then text else tostring(text or "")
	if self._editing then
		self._box.Text = self._text
		self:_scheduleRelayout()
	else
		self:_buildRows()
	end
	return self
end

function CodeView:GetContent(): string
	if self._editing then
		return self._box.Text
	end
	return self._text
end

function CodeView:SetLanguage(language)
	self._language = normalizeLanguage(language)
	if not self._editing then
		self:_buildRows()
	end
	return self
end

function CodeView:SetOnCopy(callback)
	self._onCopy = callback
	return self
end

function CodeView:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	for _, conn in ipairs(self._conns) do
		conn:Disconnect()
	end
	table.clear(self._conns)
	if self._unregisterTheme then
		self._unregisterTheme()
		self._unregisterTheme = nil
	end
	if self._main then
		for _, descendant in ipairs(self._main:GetDescendants()) do
			ThemeManager.UnbindInstance(descendant)
		end
		ThemeManager.UnbindInstance(self._main)
		self._main:Destroy()
		self._main = nil
	end
end

return CodeView
