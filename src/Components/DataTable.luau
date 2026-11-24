--[[
	Aetheris/Components/DataTable.luau

	A compact table for changing records: weighted columns, live cell updates,
	optional per-row action and live sorting. Columns share the row width by
	Weight (no pixel widths), so the table always fits its section.

	Rows are plain tables with an `id` (or `Id`) plus one field per column Key.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeManager = require("../Themes/ThemeManager")
local ComponentAPI = require("../Utils/ComponentAPI")
local Tween = require("../Utils/Tween")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

local DataTable = {}
DataTable.__index = DataTable

local DEFAULT_ROW_HEIGHT = 26
local DEFAULT_ROW_GAP = 4
local HEADER_HEIGHT = 18
local ACTION_WIDTH = 60
local MAX_MAX_ROWS = 200

local function copyRow(source)
	local row = table.clone(source)
	-- Internal insertion order; never part of the public row shape.
	row._seq = nil
	return row
end

local function rowId(row, index)
	local id = row.id
	if id == nil then
		id = row.Id
	end
	if id == nil then
		id = "row_" .. tostring(index)
	end
	return id
end

-- One comparable slot per value, so a column holding mixed types still sorts
-- consistently. Rank 1 is numeric, 2 is anything stringy, and 3 is empty
-- (nil or NaN) which always sorts last. Without this, comparing a number to a
-- string as text can make the comparator intransitive and table.sort raises
-- "invalid order function for sorting".
local function rankAndValue(value)
	local kind = typeof(value)
	if kind == "number" then
		if value ~= value then
			return 3, nil
		end
		return 1, value
	end
	if value == nil then
		return 3, nil
	end
	return 2, tostring(value)
end

local function formatNumber(value)
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

local function formatClock(value)
	local seconds = math.max(0, math.floor((tonumber(value) or 0) + 0.5))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function formatValue(column, value)
	if value == nil then
		return column.EmptyText or "—"
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
		return formatClock(value)
	elseif formatter == "number" then
		return formatNumber(value)
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

local function compileColumns(columns)
	local compiled = {}
	for _, column in ipairs(columns or {}) do
		if type(column) == "table" and column.Key ~= nil then
			compiled[#compiled + 1] = {
				Key = column.Key,
				Label = column.Label or tostring(column.Key),
				Weight = math.max(tonumber(column.Weight) or 1, 0.01),
				Align = column.Align or "left",
				Format = column.Format,
				Color = column.Color,
				EmptyText = column.EmptyText,
			}
		end
	end
	return compiled
end

local function textAlignment(align)
	if align == "center" then
		return Enum.TextXAlignment.Center
	elseif align == "right" then
		return Enum.TextXAlignment.Right
	end
	return Enum.TextXAlignment.Left
end

-- Weighted cells laid out at explicit scale offsets so the columns always fill
-- the row width, independent of window size.
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

function DataTable.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, DataTable)
	self._theme = theme

	local name = Settings.Name or "Data Table"
	self._columns = compileColumns(Settings.Columns)
	self._rows = {}
	self._rowsById = {}
	self._order = 0
	self._sortBy = Settings.SortBy
	self._sortDescending = Settings.SortDescending == true
	self._maxRows = math.clamp(tonumber(Settings.MaxRows) or 10, 1, MAX_MAX_ROWS)
	self._rowHeight = tonumber(Settings.RowHeight) or DEFAULT_ROW_HEIGHT
	self._rowGap = tonumber(Settings.RowGap) or DEFAULT_ROW_GAP
	self._showHeader = Settings.ShowHeader ~= false
	self._striped = Settings.Striped ~= false
	self._emptyText = Settings.EmptyText or "No rows yet"
	self._rowColorTransparency = Settings.RowColorTransparency or 0.82
	self._action = Settings.Action

	local root = Instance.new("Frame")
	root.Name = UUID.Static("DataTable")
	root.BorderSizePixel = 0
	root.BackgroundColor3 = theme.ComponentBackgroundColor
	root.BackgroundTransparency = theme.ComponentBackgroundTransparency or 0.985
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.Size = UDim2.fromScale(1, 0)
	root.BorderColor3 = Color3.fromRGB(0, 0, 0)
	root.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = root
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = theme.StrokeTransparency or 0.95
	stroke.Color = theme.StrokeColor
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = root
	local rootPadding = Instance.new("UIPadding")
	rootPadding.PaddingTop = UDim.new(0, 10)
	rootPadding.PaddingBottom = UDim.new(0, 10)
	rootPadding.PaddingLeft = UDim.new(0, 10)
	rootPadding.PaddingRight = UDim.new(0, 10)
	rootPadding.Parent = root
	local rootLayout = Instance.new("UIListLayout")
	rootLayout.Padding = UDim.new(0, 6)
	rootLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rootLayout.Parent = root

	ThemeManager.BindColor(root, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(root, "BackgroundTransparency", "ComponentBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")

	local title
	if name and name ~= "" then
		title = Instance.new("TextLabel")
		title.Name = UUID.Static("ElementName")
		title.BackgroundTransparency = 1
		title.BorderSizePixel = 0
		title.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
		title.Text = name
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = theme.PrimaryTextColor
		title.TextTransparency = theme.PrimaryTextTransparency or 0.3
		title.Size = UDim2.new(1, 0, 0, 18)
		title.LayoutOrder = 0
		title.Parent = root
		ThemeManager.BindColor(title, "TextColor3", "PrimaryTextColor")
		ThemeManager.BindTransparency(title, "TextTransparency", "PrimaryTextTransparency")
	end

	local header = Instance.new("Frame")
	header.Name = UUID.Static("DataTableHeader")
	header.BorderSizePixel = 0
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
	header.Visible = self._showHeader
	header.LayoutOrder = 1
	header.Parent = root

	local body = Instance.new("ScrollingFrame")
	body.Name = UUID.Static("DataTableBody")
	body.BorderSizePixel = 0
	body.BackgroundTransparency = 1
	body.Active = true
	body.CanvasSize = UDim2.fromScale(0, 0)
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.ScrollingDirection = Enum.ScrollingDirection.Y
	body.ScrollBarThickness = 2
	body.ScrollBarImageTransparency = 0.5
	body.ScrollBarImageColor3 = theme.TertiaryColor
	body.Size = UDim2.fromScale(1, 0)
	body.LayoutOrder = 2
	body.Parent = root
	local bodyPadding = Instance.new("UIPadding")
	bodyPadding.PaddingRight = UDim.new(0, 2)
	bodyPadding.Parent = body
	local bodyLayout = Instance.new("UIListLayout")
	bodyLayout.Padding = UDim.new(0, self._rowGap)
	bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bodyLayout.Parent = body
	ThemeManager.BindColor(body, "ScrollBarImageColor3", "TertiaryColor")

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Name = UUID.Static("DataTableEmpty")
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.BorderSizePixel = 0
	emptyLabel.FontFace = Constants.Font(Enum.FontWeight.Medium)
	emptyLabel.Text = self._emptyText
	emptyLabel.TextSize = 12
	emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
	emptyLabel.TextColor3 = theme.SecondaryTextColor
	emptyLabel.TextTransparency = theme.SecondaryTextTransparency or 0.45
	emptyLabel.Size = UDim2.new(1, 0, 0, 22)
	emptyLabel.LayoutOrder = 3
	emptyLabel.Visible = false
	emptyLabel.Parent = root
	ThemeManager.BindColor(emptyLabel, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(emptyLabel, "TextTransparency", "SecondaryTextTransparency")

	self.Frame = root
	self.Title = title
	self.Header = header
	self.Body = body
	self.EmptyLabel = emptyLabel
	self._bodyLayout = bodyLayout

	-- Header labels are rebuilt only when the columns change.
	local function buildHeader()
		for _, child in ipairs(header:GetChildren()) do
			if child:IsA("GuiObject") then
				for _, descendant in ipairs(child:GetDescendants()) do
					ThemeManager.UnbindInstance(descendant)
				end
				ThemeManager.UnbindInstance(child)
				child:Destroy()
			end
		end
		local actionSpace = self._action and ACTION_WIDTH or 0
		local holder = Instance.new("Frame")
		holder.Name = UUID.Static("DataTableHeaderCells")
		holder.BorderSizePixel = 0
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.new(1, -actionSpace, 1, 0)
		holder.Parent = header
		layoutCells(self._columns, function(column, position, fraction)
			local label = Instance.new("TextLabel")
			label.Name = UUID.Generate("DataTableHeaderCell")
			label.BackgroundTransparency = 1
			label.BorderSizePixel = 0
			label.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
			label.Text = tostring(column.Label)
			label.TextSize = 11
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.TextXAlignment = textAlignment(column.Align)
			label.TextColor3 = theme.SecondaryTextColor
			label.TextTransparency = 0.45
			label.Position = position
			label.Size = UDim2.new(fraction, -6, 1, 0)
			label.Parent = holder
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 3)
			pad.PaddingRight = UDim.new(0, 3)
			pad.Parent = label
			ThemeManager.BindColor(label, "TextColor3", "SecondaryTextColor")
			ThemeManager.BindTransparency(label, "TextTransparency", "SecondaryTextTransparency")
		end)
		if self._action then
			local actionLabel = Instance.new("TextLabel")
			actionLabel.Name = UUID.Generate("DataTableHeaderAction")
			actionLabel.BackgroundTransparency = 1
			actionLabel.BorderSizePixel = 0
			actionLabel.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
			actionLabel.Text = ""
			actionLabel.TextSize = 11
			actionLabel.TextXAlignment = Enum.TextXAlignment.Center
			actionLabel.TextColor3 = theme.SecondaryTextColor
			actionLabel.TextTransparency = 0.45
			actionLabel.AnchorPoint = Vector2.new(1, 0)
			actionLabel.Position = UDim2.fromScale(1, 0)
			actionLabel.Size = UDim2.new(0, ACTION_WIDTH, 1, 0)
			actionLabel.Parent = header
			ThemeManager.BindColor(actionLabel, "TextColor3", "SecondaryTextColor")
			ThemeManager.BindTransparency(actionLabel, "TextTransparency", "SecondaryTextTransparency")
		end
	end

	local renderedRows = {}

	local function clearRows()
		for _, row in ipairs(renderedRows) do
			for _, descendant in ipairs(row:GetDescendants()) do
				ThemeManager.UnbindInstance(descendant)
			end
			ThemeManager.UnbindInstance(row)
			row:Destroy()
		end
		table.clear(renderedRows)
	end

	local function sortedRows()
		local ordered = {}
		for _, row in ipairs(self._rows) do
			ordered[#ordered + 1] = row
		end
		local key = self._sortBy
		if key ~= nil then
			local descending = self._sortDescending
			table.sort(ordered, function(a, b)
				local rankA, valueA = rankAndValue(a[key])
				local rankB, valueB = rankAndValue(b[key])
				if rankA ~= rankB then
					return rankA < rankB
				end
				if rankA ~= 3 and valueA ~= valueB then
					-- Direction applies inside a rank only, so empty cells stay last.
					if descending then
						return valueA > valueB
					end
					return valueA < valueB
				end
				-- Stable tie-break on insertion order, which is always unique and
				-- numeric; comparing display ids could mix numbers and strings.
				return (a._seq or 0) < (b._seq or 0)
			end)
		end
		return ordered
	end

	local function makeRow(row, layoutOrder)
		local rowFrame = Instance.new("Frame")
		rowFrame.Name = UUID.Generate("DataTableRow")
		rowFrame.BorderSizePixel = 0
		rowFrame.BackgroundColor3 = theme.ComponentBackgroundColor
		rowFrame.BackgroundTransparency = self._striped and (layoutOrder % 2 == 0 and 0.94 or 0.985) or 1
		rowFrame.Size = UDim2.new(1, 0, 0, self._rowHeight)
		rowFrame.LayoutOrder = layoutOrder
		rowFrame.Parent = body
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 5)
		rowCorner.Parent = rowFrame

		local color = row._color
		if typeof(color) == "Color3" then
			rowFrame.BackgroundColor3 = color
			rowFrame.BackgroundTransparency = self._rowColorTransparency
		else
			ThemeManager.BindColor(rowFrame, "BackgroundColor3", "ComponentBackgroundColor")
		end

		local anchor = Instance.new("Frame")
		anchor.Name = UUID.Static("DataTableRowCells")
		anchor.BorderSizePixel = 0
		anchor.BackgroundTransparency = 1
		anchor.Size = UDim2.new(1, -(self._action and ACTION_WIDTH + 4 or 8), 1, 0)
		anchor.Position = UDim2.fromOffset(4, 0)
		anchor.Parent = rowFrame

		layoutCells(self._columns, function(column, position, fraction)
			local cell = Instance.new("TextLabel")
			cell.Name = UUID.Generate("DataTableCell")
			cell.BackgroundTransparency = 1
			cell.BorderSizePixel = 0
			cell.FontFace = Constants.Font(Enum.FontWeight.Medium)
			cell.Text = formatValue(column, row[column.Key])
			cell.TextSize = 12
			cell.TextTruncate = Enum.TextTruncate.AtEnd
			cell.TextXAlignment = textAlignment(column.Align)
			cell.TextColor3 = resolveColor(column, row[column.Key], row, theme.PrimaryTextColor)
			cell.TextTransparency = 0.2
			cell.Position = position
			cell.Size = UDim2.new(fraction, -6, 1, 0)
			cell.Parent = anchor
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 3)
			pad.PaddingRight = UDim.new(0, 3)
			pad.Parent = cell
			-- A column color is dynamic, so only theme the default text.
			if column.Color == nil then
				ThemeManager.BindColor(cell, "TextColor3", "PrimaryTextColor")
			end
		end)

		if self._action then
			local button = Instance.new("TextButton")
			button.Name = UUID.Generate("DataTableAction")
			button.BorderSizePixel = 0
			button.AutoButtonColor = false
			button.AnchorPoint = Vector2.new(1, 0.5)
			button.Position = UDim2.new(1, -4, 0.5, 0)
			button.Size = UDim2.fromOffset(ACTION_WIDTH - 6, self._rowHeight - 6)
			button.BackgroundColor3 = theme.AccentColor
			button.BackgroundTransparency = 0.82
			button.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
			button.Text = self._action.Label or "Action"
			button.TextSize = 11
			button.TextColor3 = theme.PrimaryTextColor
			button.TextTransparency = 0.1
			button.Parent = rowFrame
			local buttonCorner = Instance.new("UICorner")
			buttonCorner.CornerRadius = UDim.new(0, 5)
			buttonCorner.Parent = button
			ThemeManager.BindColor(button, "BackgroundColor3", "AccentColor")
			ThemeManager.BindColor(button, "TextColor3", "PrimaryTextColor")
			button.MouseEnter:Connect(function()
				Tween.Play(button, "Fast", { BackgroundTransparency = 0.7 })
			end)
			button.MouseLeave:Connect(function()
				Tween.Play(button, "Fast", { BackgroundTransparency = 0.82 })
			end)
			button.MouseButton1Click:Connect(function()
				if self._action and self._action.Callback then
					self._action.Callback(row._id, row)
				end
			end)
		end

		rowFrame.MouseEnter:Connect(function()
			if typeof(row._color) == "Color3" then
				return
			end
			Tween.Play(rowFrame, "Fast", { BackgroundTransparency = 0.9 })
		end)
		rowFrame.MouseLeave:Connect(function()
			if typeof(row._color) == "Color3" then
				return
			end
			local base = self._striped and (layoutOrder % 2 == 0 and 0.94 or 0.985) or 1
			Tween.Play(rowFrame, "Fast", { BackgroundTransparency = base })
		end)

		renderedRows[#renderedRows + 1] = rowFrame
		return rowFrame
	end

	local function render()
		clearRows()
		local ordered = sortedRows()
		local count = #ordered
		local visible = math.min(count, self._maxRows)
		if visible > 0 then
			local height = visible * self._rowHeight + math.max(visible - 1, 0) * self._rowGap
			body.Size = UDim2.new(1, 0, 0, height)
			body.Visible = true
		else
			body.Size = UDim2.fromScale(1, 0)
			body.Visible = false
		end
		emptyLabel.Visible = count == 0
		for index, row in ipairs(ordered) do
			makeRow(row, index)
		end
	end

	self._render = render

	ComponentAPI.Apply(self, {
		Root = function(me)
			return me.Frame
		end,
		Label = title,
		Name = name,
		Methods = {
			SetRows = function(me, rows)
				me._rows = {}
				me._rowsById = {}
				me._order = 0
				for _, source in ipairs(rows or {}) do
					local row = copyRow(source)
					me._order += 1
					row._id = rowId(row, me._order)
					row._seq = me._order
					me._rows[#me._rows + 1] = row
					me._rowsById[row._id] = row
				end
				render()
				return me
			end,
			GetRows = function(me)
				local copy = {}
				for index, row in ipairs(me._rows) do
					copy[index] = copyRow(row)
				end
				return copy
			end,
			GetRow = function(me, id)
				local row = me._rowsById[id]
				return row and copyRow(row) or nil
			end,
			AddRow = function(me, source)
				local row = copyRow(source)
				me._order += 1
				row._id = rowId(row, me._order)
				row._seq = me._order
				me._rows[#me._rows + 1] = row
				me._rowsById[row._id] = row
				render()
				return row._id
			end,
			UpdateRow = function(me, id, patch)
				local row = me._rowsById[id]
				if not row or type(patch) ~= "table" then
					return false
				end
				for key, value in pairs(patch) do
					if key ~= "id" and key ~= "Id" and key ~= "_id" and key ~= "_seq" then
						row[key] = value
					end
				end
				render()
				return true
			end,
			RemoveRow = function(me, id)
				local row = me._rowsById[id]
				if not row then
					return false
				end
				me._rowsById[id] = nil
				for index, candidate in ipairs(me._rows) do
					if candidate == row then
						table.remove(me._rows, index)
						break
					end
				end
				render()
				return true
			end,
			ClearRows = function(me)
				me._rows = {}
				me._rowsById = {}
				me._order = 0
				render()
				return me
			end,
			SetRowColor = function(me, id, color)
				local row = me._rowsById[id]
				if not row then
					return false
				end
				if color == nil then
					row._color = nil
				elseif typeof(color) == "Color3" then
					row._color = color
				else
					return false
				end
				render()
				return true
			end,
			GetRowColor = function(me, id)
				local row = me._rowsById[id]
				return row and row._color or nil
			end,
			SetSort = function(me, key, descending)
				me._sortBy = key
				if descending ~= nil then
					me._sortDescending = descending == true
				end
				render()
				return me
			end,
			GetSort = function(me)
				return me._sortBy, me._sortDescending
			end,
			SetMaxRows = function(me, value)
				me._maxRows = math.clamp(tonumber(value) or me._maxRows, 1, MAX_MAX_ROWS)
				render()
				return me
			end,
			SetEmptyText = function(me, text)
				me._emptyText = tostring(text or "")
				emptyLabel.Text = me._emptyText
				return me
			end,
			SetColumns = function(me, columns)
				me._columns = compileColumns(columns)
				buildHeader()
				render()
				return me
			end,
			SetAction = function(me, action)
				me._action = action
				buildHeader()
				render()
				return me
			end,
			SetHeaderVisible = function(me, visible)
				me._showHeader = visible == true
				header.Visible = me._showHeader
				return me
			end,
			Destroy = function(me)
				for _, descendant in ipairs(me.Frame:GetDescendants()) do
					ThemeManager.UnbindInstance(descendant)
				end
				ThemeManager.UnbindInstance(me.Frame)
				me.Frame:Destroy()
				me.Frame = nil
				renderedRows = {}
			end,
		},
	})

	buildHeader()
	render()
	return self
end

return DataTable
