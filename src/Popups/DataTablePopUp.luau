--[[
	Aetheris/Popups/DataTablePopUp.luau

	Modal data table used by Components/DataTable. The inline component is a
	compact field card; this popup carries the searchable, sortable rows and
	the optional per-row action. Styling follows the colour picker shell.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

local UserInputService = game:GetService("UserInputService")

local DataTablePopUp = {}
DataTablePopUp.__index = DataTablePopUp

local CORNER_SHELL = 12
local CORNER_CARD = 8
local FALLBACK_POPUP = Color3.fromRGB(15, 15, 16)

-- Close button hover, matching the changelog's icon timing.
local ICON_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ICON_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_ICON = Icons["circle-x"] or "rbxassetid://76821953846248"

-- Authored at this geometry, then scaled to fit the window by computeFit.
local POPUP_WIDTH = 520
local POPUP_HEIGHT = 432
local SIDE_PAD = 16
local BASE_SCALE = 1.15
local SEARCH_WIDTH = 176
local CLOSE_SIZE = 28
local CLOSE_GAP = 8
-- The search field sits left of the close button in the header.
local SEARCH_INSET = SIDE_PAD + CLOSE_SIZE + CLOSE_GAP
local HEADER_INSET = SEARCH_INSET + SEARCH_WIDTH + 8
local HEADER_TOP = 62
local HEADER_H = 24
local BODY_TOP = HEADER_TOP + HEADER_H + 6
local BODY_BOTTOM = 16
local ROW_H = 34
local ROW_GAP = 2
local ACTION_W = 64

local function clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

local function isDark(color)
	return (color.R * 0.299 + color.G * 0.587 + color.B * 0.114) < 0.5
end

-- UIGradient.Color multiplies, so the ramp is a grey multiplier pair.
local function stampShellGradient(gradient, t)
	local base = (t and t.PopupBackgroundColor) or FALLBACK_POPUP
	local top = if isDark(base) then 0.9 else 0.96
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(top, top, top)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
end

local function accentText(color, onDark)
	if onDark then
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, math.min(s, 0.75), math.max(v, 0.92))
	end
	return color:Lerp(Color3.new(0, 0, 0), 0.3)
end

local function tileFill(tint, base)
	if isDark(base) then
		return base:Lerp(tint, 0.4):Lerp(Color3.new(0, 0, 0), 0.35)
	end
	return base:Lerp(tint, 0.3)
end

local function stampHeaderTile(tile, glyph, t)
	local tint = (t and t.AccentColor) or Color3.fromRGB(96, 165, 250)
	local base = (t and t.PopupBackgroundColor) or FALLBACK_POPUP
	tile.BackgroundColor3 = tileFill(tint, base)
	glyph.ImageColor3 = accentText(tint, isDark(base))
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = parent
	return corner
end

local function textAlignment(align)
	if align == "center" then
		return Enum.TextXAlignment.Center
	elseif align == "right" then
		return Enum.TextXAlignment.Right
	end
	return Enum.TextXAlignment.Left
end

local function formatValue(column, value)
	if value == nil then
		return column.EmptyText or "\u{2014}"
	end
	local formatter = column.Format
	if type(formatter) == "function" then
		local ok, text = pcall(formatter, value)
		return ok and tostring(text) or tostring(value)
	end
	if formatter == "percent" then
		local n = tonumber(value) or 0
		if math.abs(n) <= 1 then
			n *= 100
		end
		return string.format("%d%%", math.floor(n + 0.5))
	elseif formatter == "studs" then
		return string.format("%d studs", math.floor((tonumber(value) or 0) + 0.5))
	elseif formatter == "time" then
		local seconds = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
		return string.format("%d:%02d", seconds // 60, seconds % 60)
	elseif formatter == "number" then
		local n = tonumber(value)
		if not n then
			return tostring(value)
		end
		local rounded = math.floor(n + 0.5)
		local text = tostring(math.abs(rounded))
		text = text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
		if rounded < 0 then
			return "-" .. text
		end
		return text
	end
	return tostring(value)
end

local function resolveColor(column, value, row, fallback)
	local color = column.Color
	if type(color) == "function" then
		local ok, resolved = pcall(color, value, row)
		if ok and typeof(resolved) == "Color3" then
			return resolved
		end
	elseif typeof(color) == "Color3" then
		return color
	elseif type(color) == "string" then
		local ok, resolved = pcall(Color3.fromHex, color)
		if ok then
			return resolved
		end
	end
	return fallback
end

-- Weighted cells laid out at explicit scale offsets, same as the old inline
-- table so behaviour is unchanged.
local function layoutCells(columns, makeCell)
	local total = 0
	for _, column in ipairs(columns) do
		total += column.Weight
	end
	local offset = 0
	for _, column in ipairs(columns) do
		local fraction = column.Weight / total
		makeCell(column, UDim2.fromScale(offset, 0), fraction)
		offset += fraction
	end
end

local function unbindTree(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		ThemeManager.UnbindInstance(descendant)
	end
	ThemeManager.UnbindInstance(root)
end

function DataTablePopUp.new(parent, Settings, _cleanupCallback)
	Settings = Settings or {}
	local theme = ThemeManager.GetTheme(Settings.Theme)
	local self = setmetatable({}, DataTablePopUp)
	self._theme = theme
	self._parent = parent
	self._window = Settings.Window
	self._query = ""
	self._columns = {}
	self._rows = {}
	self._renderedRows = {}

	local popup = Instance.new("CanvasGroup")
	popup.Name = UUID.Generate("DataTablePopup")
	popup.BorderSizePixel = 0
	popup.GroupTransparency = 1
	popup.BackgroundColor3 = (theme and theme.PopupBackgroundColor) or FALLBACK_POPUP
	popup.BackgroundTransparency = (theme and theme.PopupBackgroundTransparency) or 0.07
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Size = UDim2.fromOffset(POPUP_WIDTH, POPUP_HEIGHT)
	popup.Position = UDim2.fromScale(0.5, 0.5)
	popup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	popup.Visible = false
	popup.Active = true
	popup.ZIndex = 12
	popup.Parent = parent
	self.Popup = popup

	ThemeManager.BindColor(popup, "BackgroundColor3", "PopupBackgroundColor")
	ThemeManager.BindTransparency(popup, "BackgroundTransparency", "PopupBackgroundTransparency")

	local shellGradient = Instance.new("UIGradient")
	stampShellGradient(shellGradient, theme)
	shellGradient.Parent = popup
	self._shellGradient = shellGradient

	local shadow = Instance.new("UIShadow")
	shadow.Color = (theme and theme.PopupShadowColor)
	shadow.BlurRadius = UDim.new(0, 20)
	shadow.Transparency = 1
	shadow.Parent = popup
	self._shadow = shadow

	addCorner(popup, UDim.new(0, CORNER_SHELL))
	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = popup
	self._scale = scale

	local headTile = Instance.new("Frame")
	headTile.Name = UUID.Static("HeaderTile")
	headTile.BorderSizePixel = 0
	headTile.Size = UDim2.fromOffset(30, 30)
	headTile.Position = UDim2.fromOffset(SIDE_PAD, 14)
	headTile.Parent = popup
	addCorner(headTile, UDim.new(0, 10))
	local headGlyph = Instance.new("ImageLabel")
	headGlyph.Name = UUID.Static("HeaderGlyph")
	headGlyph.BorderSizePixel = 0
	headGlyph.BackgroundTransparency = 1
	headGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
	headGlyph.Position = UDim2.fromScale(0.5, 0.5)
	headGlyph.Size = UDim2.fromOffset(16, 16)
	headGlyph.Image = Icons["table"] or Icons["table-2"]
	headGlyph.Parent = headTile
	stampHeaderTile(headTile, headGlyph, theme)
	self._headTile = headTile
	self._headGlyph = headGlyph

	local header = Instance.new("TextLabel")
	header.Name = UUID.Static("Header")
	header.BorderSizePixel = 0
	header.TextSize = 14
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextYAlignment = Enum.TextYAlignment.Center
	header.TextTruncate = Enum.TextTruncate.AtEnd
	header.BackgroundTransparency = 1
	header.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	header.TextColor3 = (theme and theme.PopupTextColor)
	header.Size = UDim2.new(1, -(56 + HEADER_INSET), 0, 18)
	header.Position = UDim2.fromOffset(56, 10)
	header.Parent = popup
	header.Text = "Data"
	ThemeManager.BindColor(header, "TextColor3", "PopupTextColor")
	self.Header = header

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = UUID.Static("Subtitle")
	subtitle.BorderSizePixel = 0
	subtitle.BackgroundTransparency = 1
	subtitle.TextSize = 10
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.TextYAlignment = Enum.TextYAlignment.Center
	subtitle.TextTruncate = Enum.TextTruncate.AtEnd
	subtitle.FontFace = Constants.Font(Enum.FontWeight.Medium)
	subtitle.TextColor3 = (theme and theme.SecondaryTextColor)
	subtitle.TextTransparency = 0.35
	subtitle.Size = UDim2.new(1, -(56 + HEADER_INSET), 0, 14)
	subtitle.Position = UDim2.fromOffset(56, 28)
	subtitle.Parent = popup
	ThemeManager.BindColor(subtitle, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(subtitle, "TextTransparency", "SecondaryTextTransparency")
	self._subtitle = subtitle

	-- Search field, pinned to the right of the header.
	local searchBox = Instance.new("Frame")
	searchBox.Name = UUID.Static("SearchBox")
	searchBox.BorderSizePixel = 0
	searchBox.BackgroundColor3 = (theme and theme.PopupNeutralColor) or Color3.fromRGB(46, 46, 46)
	searchBox.BackgroundTransparency = 0.55
	searchBox.AnchorPoint = Vector2.new(1, 0)
	searchBox.Position = UDim2.new(1, -SEARCH_INSET, 0, 16)
	searchBox.Size = UDim2.fromOffset(SEARCH_WIDTH, 28)
	searchBox.Parent = popup
	addCorner(searchBox, UDim.new(0, 8))
	ThemeManager.BindColor(searchBox, "BackgroundColor3", "PopupNeutralColor")

	local searchIcon = Instance.new("ImageLabel")
	searchIcon.Name = UUID.Static("SearchIcon")
	searchIcon.BorderSizePixel = 0
	searchIcon.BackgroundTransparency = 1
	searchIcon.AnchorPoint = Vector2.new(0, 0.5)
	searchIcon.Position = UDim2.new(0, 9, 0.5, 0)
	searchIcon.Size = UDim2.fromOffset(12, 12)
	searchIcon.Image = Icons["search"]
	searchIcon.ImageColor3 = (theme and theme.TertiaryColor)
	searchIcon.Parent = searchBox
	ThemeManager.BindColor(searchIcon, "ImageColor3", "TertiaryColor")

	local searchField = Instance.new("TextBox")
	searchField.Name = UUID.Static("SearchField")
	searchField.BorderSizePixel = 0
	searchField.BackgroundTransparency = 1
	searchField.ClearTextOnFocus = false
	searchField.Text = ""
	searchField.PlaceholderText = "Search rows"
	searchField.PlaceholderColor3 = (theme and theme.TertiaryColor) or Color3.fromRGB(150, 150, 150)
	searchField.TextColor3 = (theme and theme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
	searchField.TextSize = 11
	searchField.TextXAlignment = Enum.TextXAlignment.Left
	searchField.FontFace = Constants.Font(Enum.FontWeight.Medium)
	searchField.Position = UDim2.fromOffset(25, 0)
	searchField.Size = UDim2.new(1, -33, 1, 0)
	searchField.Parent = searchBox
	ThemeManager.BindColor(searchField, "TextColor3", "PopupTextColor")
	ThemeManager.BindColor(searchField, "PlaceholderColor3", "TertiaryColor")
	self._searchField = searchField

	-- Close button mirrors the changelog's: a soft white circle with no stroke,
	-- so every popup's dismiss control reads the same.
	local closeBtn = Instance.new("ImageButton")
	closeBtn.Name = UUID.Static("Close")
	closeBtn.BorderSizePixel = 0
	closeBtn.BackgroundColor3 = Color3.new(1, 1, 1)
	closeBtn.BackgroundTransparency = 0.92
	closeBtn.AutoButtonColor = false
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -SIDE_PAD, 0, 16)
	closeBtn.Size = UDim2.fromOffset(CLOSE_SIZE, CLOSE_SIZE)
	closeBtn.Parent = popup
	addCorner(closeBtn, UDim.new(1, 0))

	local closeIcon = Instance.new("ImageLabel")
	closeIcon.Name = UUID.Static("CloseIcon")
	closeIcon.BorderSizePixel = 0
	closeIcon.BackgroundTransparency = 1
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.Position = UDim2.fromScale(0.5, 0.5)
	closeIcon.Size = UDim2.fromOffset(16, 16)
	closeIcon.Image = CLOSE_ICON
	closeIcon.ImageColor3 = (theme and theme.PopupTextColor)
	closeIcon.ImageTransparency = 0.35
	closeIcon.Parent = closeBtn
	ThemeManager.BindColor(closeIcon, "ImageColor3", "PopupTextColor")

	closeBtn.MouseEnter:Connect(function()
		Tween.Play(closeBtn, ICON_IN, { BackgroundTransparency = 0.86 })
		Tween.Play(closeIcon, ICON_IN, { ImageTransparency = 0 })
	end)
	closeBtn.MouseLeave:Connect(function()
		Tween.Play(closeBtn, ICON_OUT, { BackgroundTransparency = 0.92 })
		Tween.Play(closeIcon, ICON_OUT, { ImageTransparency = 0.35 })
	end)
	closeBtn.MouseButton1Click:Connect(function()
		self:Close()
	end)

	-- Column header bar; rebuilt whenever the column set changes.
	local columnBar = Instance.new("Frame")
	columnBar.Name = UUID.Static("ColumnBar")
	columnBar.BorderSizePixel = 0
	columnBar.BackgroundColor3 = (theme and theme.PopupNeutralColor) or Color3.fromRGB(46, 46, 46)
	columnBar.BackgroundTransparency = 0.7
	columnBar.Position = UDim2.fromOffset(SIDE_PAD, HEADER_TOP)
	columnBar.Size = UDim2.new(1, -SIDE_PAD * 2, 0, HEADER_H)
	columnBar.Parent = popup
	addCorner(columnBar, UDim.new(0, 7))
	ThemeManager.BindColor(columnBar, "BackgroundColor3", "PopupNeutralColor")
	self._columnBar = columnBar

	local bodyHeight = POPUP_HEIGHT - BODY_TOP - BODY_BOTTOM
	local body = Instance.new("ScrollingFrame")
	body.Name = UUID.Static("Body")
	body.BorderSizePixel = 0
	body.BackgroundTransparency = 1
	body.Active = true
	body.CanvasSize = UDim2.fromScale(0, 0)
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.ScrollingDirection = Enum.ScrollingDirection.Y
	-- Thin library scrollbar: hidden at rest, revealed while scrolling.
	body.ScrollBarThickness = 1
	body.ScrollBarImageTransparency = 1
	body.ScrollBarImageColor3 = (theme and theme.TertiaryColor) or Color3.fromRGB(150, 150, 150)
	body.Position = UDim2.fromOffset(SIDE_PAD, BODY_TOP)
	body.Size = UDim2.new(1, -SIDE_PAD * 2, 0, bodyHeight)
	body.Parent = popup
	ThemeManager.BindColor(body, "ScrollBarImageColor3", "TertiaryColor")
	self._body = body
	local bodyLayout = Instance.new("UIListLayout")
	bodyLayout.Padding = UDim.new(0, ROW_GAP)
	bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bodyLayout.Parent = body
	self._bodyLayout = bodyLayout

	self._scrollConn = body:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		Tween.Play(body, "Fast", { ScrollBarImageTransparency = 0.5 })
		if self._scrollbarTimer then
			task.cancel(self._scrollbarTimer)
		end
		self._scrollbarTimer = task.delay(1.5, function()
			Tween.Play(body, "Fast", { ScrollBarImageTransparency = 1 })
			self._scrollbarTimer = nil
		end)
	end)

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Name = UUID.Static("Empty")
	emptyLabel.BorderSizePixel = 0
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Text = "No rows yet"
	emptyLabel.TextSize = 12
	emptyLabel.FontFace = Constants.Font(Enum.FontWeight.Medium)
	emptyLabel.TextColor3 = (theme and theme.SecondaryTextColor)
	emptyLabel.TextTransparency = 0.4
	emptyLabel.Position = UDim2.fromOffset(SIDE_PAD, BODY_TOP + bodyHeight / 2 - 10)
	emptyLabel.Size = UDim2.new(1, -SIDE_PAD * 2, 0, 20)
	emptyLabel.Visible = false
	emptyLabel.Parent = popup
	ThemeManager.BindColor(emptyLabel, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(emptyLabel, "TextTransparency", "SecondaryTextTransparency")
	self._emptyLabel = emptyLabel

	-- Derived values follow theme switches without rebuilding the popup; the
	-- bindings only cover plain properties, these are computed from the theme.
	local function applyTheme(newTheme)
		local t = ThemeManager.GetTheme(newTheme)
		self._theme = t
		stampShellGradient(shellGradient, t)
		stampHeaderTile(headTile, headGlyph, t)
		shadow.Color = t.PopupShadowColor or shadow.Color
	end
	self.ApplyTheme = function(_me, newTheme)
		applyTheme(newTheme)
	end
	ThemeManager.OnThemeApplied(applyTheme, popup)

	local function clearChildren(container)
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("GuiObject") then
				unbindTree(child)
				child:Destroy()
			end
		end
	end

	local function filteredRows()
		local query = self._query
		if query == "" then
			return self._rows
		end
		local needle = string.lower(query)
		local matches = {}
		for _, row in ipairs(self._rows) do
			local hit = false
			for _, column in ipairs(self._columns) do
				local text = formatValue(column, row[column.Key])
				if string.find(string.lower(text), needle, 1, true) then
					hit = true
					break
				end
			end
			if hit then
				matches[#matches + 1] = row
			end
		end
		return matches
	end

	local function updateSubtitle(visibleCount)
		local total = #self._rows
		local rowsText = total == 1 and "1 row" or tostring(total) .. " rows"
		local columns = #self._columns
		local columnsText = columns == 1 and "1 column" or tostring(columns) .. " columns"
		if visibleCount ~= nil and visibleCount ~= total then
			self._subtitle.Text = string.format("%d of %d rows \u{00B7} %s", visibleCount, total, columnsText)
		else
			self._subtitle.Text = rowsText .. " \u{00B7} " .. columnsText
		end
	end

	self._renderRows = function()
		for _, row in ipairs(self._renderedRows) do
			unbindTree(row)
			row:Destroy()
		end
		table.clear(self._renderedRows)

		local rows = filteredRows()
		local themeNow = self._theme or ThemeManager.GetTheme(nil)
		local fallbackText = (themeNow and themeNow.PopupTextColor) or Color3.fromRGB(255, 255, 255)
		local action = self._action
		local rowHeight = self._rowHeight or ROW_H

		for index, row in ipairs(rows) do
			local rowFrame = Instance.new("Frame")
			rowFrame.Name = UUID.Generate("DataTablePopupRow")
			rowFrame.BorderSizePixel = 0
			rowFrame.BackgroundColor3 = (themeNow and themeNow.PopupNeutralColor) or Color3.fromRGB(46, 46, 46)
			local stripedBase = (self._striped and index % 2 == 0) and 0.93 or 1
			rowFrame.BackgroundTransparency = stripedBase
			rowFrame.Size = UDim2.new(1, 0, 0, rowHeight)
			rowFrame.LayoutOrder = index
			rowFrame.Parent = body
			addCorner(rowFrame, UDim.new(0, CORNER_CARD))

			local cells = Instance.new("Frame")
			cells.Name = UUID.Static("RowCells")
			cells.BorderSizePixel = 0
			cells.BackgroundTransparency = 1
			cells.Position = UDim2.fromOffset(8, 0)
			cells.Size = UDim2.new(1, -(action and ACTION_W + 18 or 16), 1, 0)
			cells.Parent = rowFrame

			layoutCells(self._columns, function(column, position, fraction)
				local cell = Instance.new("TextLabel")
				cell.Name = UUID.Generate("DataTablePopupCell")
				cell.BackgroundTransparency = 1
				cell.BorderSizePixel = 0
				cell.FontFace = Constants.Font(Enum.FontWeight.Medium)
				cell.Text = formatValue(column, row[column.Key])
				cell.TextSize = 12
				cell.TextTruncate = Enum.TextTruncate.AtEnd
				cell.TextXAlignment = textAlignment(column.Align)
				cell.TextColor3 = resolveColor(column, row[column.Key], row, fallbackText)
				cell.TextTransparency = 0.15
				cell.Position = position
				cell.Size = UDim2.new(fraction, -6, 1, 0)
				cell.Parent = cells
				local pad = Instance.new("UIPadding")
				pad.PaddingLeft = UDim.new(0, 3)
				pad.PaddingRight = UDim.new(0, 3)
				pad.Parent = cell
				if column.Color == nil then
					ThemeManager.BindColor(cell, "TextColor3", "PopupTextColor")
				end
			end)

			local color = row._color
			if typeof(color) == "Color3" then
				rowFrame.BackgroundColor3 = color
				rowFrame.BackgroundTransparency = self._rowColorTransparency
			else
				ThemeManager.BindColor(rowFrame, "BackgroundColor3", "PopupNeutralColor")
			end

			if action then
				local button = Instance.new("TextButton")
				button.Name = UUID.Generate("DataTablePopupAction")
				button.BorderSizePixel = 0
				button.AutoButtonColor = false
				button.AnchorPoint = Vector2.new(1, 0.5)
				button.Position = UDim2.new(1, -6, 0.5, 0)
				button.Size = UDim2.fromOffset(ACTION_W - 8, rowHeight - 10)
				button.BackgroundColor3 = (themeNow and themeNow.AccentColor) or Color3.fromRGB(96, 165, 250)
				button.BackgroundTransparency = 0.8
				button.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
				button.Text = action.Label or "Action"
				button.TextSize = 11
				button.TextColor3 = (themeNow and themeNow.PopupTextColor) or Color3.fromRGB(255, 255, 255)
				button.TextTransparency = 0.05
				button.Parent = rowFrame
				addCorner(button, UDim.new(0, 7))
				ThemeManager.BindColor(button, "BackgroundColor3", "AccentColor")
				ThemeManager.BindColor(button, "TextColor3", "PopupTextColor")
				button.MouseEnter:Connect(function()
					Tween.Play(button, "Fast", { BackgroundTransparency = 0.68 })
				end)
				button.MouseLeave:Connect(function()
					Tween.Play(button, "Fast", { BackgroundTransparency = 0.8 })
				end)
				button.MouseButton1Click:Connect(function()
					if self.OnAction then
						self.OnAction(row._id, row)
					end
				end)
			end

			if typeof(color) ~= "Color3" then
				rowFrame.MouseEnter:Connect(function()
					Tween.Play(rowFrame, "Fast", { BackgroundTransparency = 0.86 })
				end)
				rowFrame.MouseLeave:Connect(function()
					Tween.Play(rowFrame, "Fast", { BackgroundTransparency = stripedBase })
				end)
			end

			self._renderedRows[#self._renderedRows + 1] = rowFrame
		end

		emptyLabel.Text = if self._query ~= "" then "No matches" else self._emptyText
		emptyLabel.Visible = #rows == 0
		updateSubtitle(#rows)
	end

	local function buildColumnBar()
		clearChildren(columnBar)
		local action = self._action
		local cells = Instance.new("Frame")
		cells.Name = UUID.Static("ColumnCells")
		cells.BorderSizePixel = 0
		cells.BackgroundTransparency = 1
		cells.Position = UDim2.fromOffset(8, 0)
		cells.Size = UDim2.new(1, -(action and ACTION_W + 18 or 16), 1, 0)
		cells.Parent = columnBar
		layoutCells(self._columns, function(column, position, fraction)
			local button = Instance.new("TextButton")
			button.Name = UUID.Generate("DataTableSortHeader")
			button.BorderSizePixel = 0
			button.AutoButtonColor = false
			button.BackgroundTransparency = 1
			button.Text = ""
			button.Position = position
			button.Size = UDim2.new(fraction, -2, 1, 0)
			button.Parent = cells

			local label = Instance.new("TextLabel")
			label.Name = UUID.Static("Label")
			label.BorderSizePixel = 0
			label.BackgroundTransparency = 1
			label.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
			label.Text = string.upper(tostring(column.Label))
			label.TextSize = 10
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.TextXAlignment = textAlignment(column.Align)
			label.TextColor3 = (self._theme and self._theme.SecondaryTextColor)
			label.TextTransparency = 0.3
			label.Size = UDim2.new(1, -14, 1, 0)
			label.Parent = button
			ThemeManager.BindColor(label, "TextColor3", "SecondaryTextColor")
			ThemeManager.BindTransparency(label, "TextTransparency", "SecondaryTextTransparency")

			if self._sortBy == column.Key then
				local arrow = Instance.new("ImageLabel")
				arrow.Name = UUID.Static("SortArrow")
				arrow.BorderSizePixel = 0
				arrow.BackgroundTransparency = 1
				arrow.AnchorPoint = Vector2.new(1, 0.5)
				arrow.Position = UDim2.new(1, -2, 0.5, 0)
				arrow.Size = UDim2.fromOffset(10, 10)
				arrow.Image = if self._sortDescending then Icons["arrow-down"] else Icons["arrow-up"]
				arrow.ImageColor3 = (self._theme and self._theme.AccentColor) or Color3.fromRGB(96, 165, 250)
				arrow.Parent = button
				ThemeManager.BindColor(arrow, "ImageColor3", "AccentColor")
			end

			button.MouseEnter:Connect(function()
				Tween.Play(button, "Fast", { BackgroundTransparency = 0.9 })
			end)
			button.MouseLeave:Connect(function()
				Tween.Play(button, "Fast", { BackgroundTransparency = 1 })
			end)
			button.MouseButton1Click:Connect(function()
				if self.OnSort then
					self.OnSort(column.Key)
				end
			end)
		end)
	end

	searchField:GetPropertyChangedSignal("Text"):Connect(function()
		self._query = searchField.Text
		self:_renderRows()
	end)

	self.SetContent = function(me, content)
		content = content or {}
		me._title = content.Title or "Data"
		me._columns = content.Columns or {}
		me._rows = content.Rows or {}
		me._sortBy = content.SortBy
		me._sortDescending = content.SortDescending == true
		me._action = content.Action
		me._emptyText = content.EmptyText or "No rows yet"
		me._rowColorTransparency = content.RowColorTransparency or 0.82
		me._striped = content.Striped ~= false
		me._rowHeight = clamp(tonumber(content.RowHeight) or ROW_H, 20, 60)
		me._rowGap = clamp(tonumber(content.RowGap) or ROW_GAP, 0, 16)
		me.Header.Text = me._title
		me._columnBar.Visible = content.ShowHeader ~= false
		me._bodyLayout.Padding = UDim.new(0, me._rowGap)
		buildColumnBar()
		me:_renderRows()

		-- The card grows with the row count up to the caller's MaxRows, then
		-- the body scrolls. The window height caps it too, so a long table
		-- never shrinks the whole popup to unreadable text.
		local step = me._rowHeight + me._rowGap
		local chrome = BODY_TOP + BODY_BOTTOM
		local areaHeight = parent.AbsoluteSize.Y
		local authoredBudget = if areaHeight > 0 then (areaHeight - 40) / BASE_SCALE else POPUP_HEIGHT
		local fitRows = math.max(1, math.floor((authoredBudget - chrome) / step))
		local maxRows = tonumber(content.MaxRows) or 10
		local visibleRows = clamp(math.min(#me._rows, maxRows), 1, fitRows)
		local height = chrome + visibleRows * step
		local cardBodyHeight = height - chrome
		me.Popup.Size = UDim2.fromOffset(POPUP_WIDTH, height)
		me._body.Size = UDim2.new(1, -SIDE_PAD * 2, 0, cardBodyHeight)
		me._emptyLabel.Position = UDim2.fromOffset(SIDE_PAD, BODY_TOP + cardBodyHeight / 2 - 10)
	end

	self._connectOutsideClick = function(me)
		if me._outsideConn then
			return
		end
		me._outsideConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			local inputType = input.UserInputType
			if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
				return
			end
			if not me.IsOpen or not me.Popup or not me.Popup.Visible then
				return
			end
			local p = input.Position
			local pos = me.Popup.AbsolutePosition
			local size = me.Popup.AbsoluteSize
			local inside = p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
			if not inside then
				me:Close()
			end
		end)
	end

	self._disconnectOutsideClick = function(me)
		if me._outsideConn then
			me._outsideConn:Disconnect()
			me._outsideConn = nil
		end
	end

	self.Open = function(me)
		if not me.Popup then
			return
		end
		-- Claiming here covers direct popup use as well as the DataTable card
		-- path, so two tables can never stack on screen.
		if me._window and me._window._claimPopup then
			me._window:_claimPopup(me)
		end
		if me._hideTimer then
			task.cancel(me._hideTimer)
			me._hideTimer = nil
		end
		me.IsOpen = true
		-- Each open starts from an unfiltered list, since the query only lives
		-- inside the popup.
		if me._query ~= "" then
			me._query = ""
			me._searchField.Text = ""
		end
		local area = parent.AbsoluteSize
		local fit = BASE_SCALE
		if area.X > 0 and area.Y > 0 then
			local cardHeight = me.Popup.Size.Y.Offset
			fit = clamp(
				math.min((area.X - 24) / (POPUP_WIDTH * BASE_SCALE), (area.Y - 24) / (cardHeight * BASE_SCALE)),
				0.35,
				1
			) * BASE_SCALE
		end
		-- The scale is applied while the popup is still hidden. Animating it
		-- re-rasterises the labels, which reads as text snapping to a new size.
		me._scale.Scale = fit
		me.Popup.Visible = true
		me.Popup.GroupTransparency = 1
		Tween.Play(me.Popup, "Fast", { GroupTransparency = 0 })
		Tween.Play(me._shadow, "Fast", { Transparency = 0.5 })
		me:_connectOutsideClick()
	end

	self.Close = function(me)
		if not me.Popup or not me.IsOpen then
			return
		end
		me.IsOpen = false
		if me._window and me._window._activePopUp == me then
			me._window._activePopUp = nil
		end
		me:_disconnectOutsideClick()
		if me._searchField then
			me._searchField:ReleaseFocus()
		end
		if me._hideTimer then
			task.cancel(me._hideTimer)
		end
		Tween.Play(me.Popup, "Fast", { GroupTransparency = 1 })
		Tween.Play(me._shadow, "Fast", { Transparency = 1 })
		me._hideTimer = task.delay(0.35, function()
			if not me.IsOpen and me.Popup then
				me.Popup.Visible = false
			end
			me._hideTimer = nil
		end)
	end

	self.Hide = function(me)
		me:Close()
	end

	self.Dismiss = function(me)
		me:Close()
	end

	self.Destroy = function(me)
		me:_disconnectOutsideClick()
		if me._scrollConn then
			me._scrollConn:Disconnect()
			me._scrollConn = nil
		end
		if me._scrollbarTimer then
			task.cancel(me._scrollbarTimer)
			me._scrollbarTimer = nil
		end
		if me._hideTimer then
			task.cancel(me._hideTimer)
			me._hideTimer = nil
		end
		if me.Popup then
			unbindTree(me.Popup)
			me.Popup:Destroy()
			me.Popup = nil
		end
	end

	return self
end

return DataTablePopUp
