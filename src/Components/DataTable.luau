--[[
	Aetheris/Components/DataTable.luau

	A compact field card that opens a searchable, sortable table in a modal
	popup (Popups/DataTablePopUp). Keeping the rows out of the page avoids
	cramped inline tables while preserving the full row API.

	Rows are plain tables with an `id` (or `Id`) plus one field per column Key.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeManager = require("../Themes/ThemeManager")
local ComponentAPI = require("../Utils/ComponentAPI")
local Tween = require("../Utils/Tween")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")
local Sound = require("../Utils/Sound")
local Icons = require("../Assets/Icons")
local DataTablePopUp = require("../Popups/DataTablePopUp")

local DataTable = {}
DataTable.__index = DataTable

local CARD_HEIGHT = 58
local CARD_CORNER = 8
local MAX_MAX_ROWS = 200
local MAX_ACTIONS = 3

-- Actions is the multi-button form; Action stays as a one-item shorthand.
-- A present Actions table wins, even when empty, so callers can clear buttons
-- without removing the key.
local function compileActions(settings)
	local list = {}
	if type(settings.Actions) == "table" then
		for _, entry in ipairs(settings.Actions) do
			if type(entry) == "table" and #list < MAX_ACTIONS then
				list[#list + 1] = entry
			end
		end
		return list
	end
	if type(settings.Action) == "table" then
		list[1] = settings.Action
	end
	return list
end

local function clampActions(actions)
	local list = {}
	for _, entry in ipairs(actions or {}) do
		if type(entry) == "table" and #list < MAX_ACTIONS then
			list[#list + 1] = entry
		end
	end
	return list
end

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

local function resolvePopupParent(window, parent)
	if window and window.PopUpsFolder then
		return window.PopUpsFolder
	end
	local node = parent
	while node and not node:IsA("LayerCollector") do
		node = node.Parent
	end
	return node or parent
end

function DataTable.new(parent, Settings, theme, window)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, DataTable)
	self._theme = theme
	self._window = window

	local name = Settings.Name or "Data Table"
	self._columns = compileColumns(Settings.Columns)
	self._rows = {}
	self._rowsById = {}
	self._order = 0
	self._sortBy = Settings.SortBy
	self._sortDescending = Settings.SortDescending == true
	self._maxRows = math.clamp(tonumber(Settings.MaxRows) or 10, 1, MAX_MAX_ROWS)
	self._rowHeight = math.clamp(tonumber(Settings.RowHeight) or 32, 20, 60)
	self._rowGap = math.clamp(tonumber(Settings.RowGap) or 2, 0, 16)
	self._showHeader = Settings.ShowHeader ~= false
	self._striped = Settings.Striped ~= false
	self._emptyText = Settings.EmptyText or "No rows yet"
	self._rowColorTransparency = Settings.RowColorTransparency or 0.82
	self._actions = compileActions(Settings)
	self._selectable = Settings.Selectable == true
	self._onRowClick = Settings.OnRowClick
	self._onSelectionChanged = Settings.OnSelectionChanged
	self._selectedColor = typeof(Settings.SelectedColor) == "Color3" and Settings.SelectedColor or nil
	self._selectedId = nil
	self._popupParent = resolvePopupParent(window, parent)

	local root = Instance.new("TextButton")
	root.Name = UUID.Static("DataTable")
	root.BorderSizePixel = 0
	root.AutoButtonColor = false
	root.Text = ""
	root.TextTransparency = 1
	root.BackgroundColor3 = (theme and theme.ComponentBackgroundColor) or Color3.fromRGB(255, 255, 255)
	root.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	root.Size = UDim2.new(1, 0, 0, CARD_HEIGHT)
	root.BorderColor3 = Color3.fromRGB(0, 0, 0)
	root:SetAttribute(UUID.Static("IsComponentContainer"), true)
	root.Parent = parent
	self.Frame = root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CARD_CORNER)
	corner.Parent = root

	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = root

	ThemeManager.BindColor(root, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(root, "BackgroundTransparency", "ComponentBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")

	local tile = Instance.new("Frame")
	tile.Name = UUID.Static("IconTile")
	tile.BorderSizePixel = 0
	tile.BackgroundColor3 = (theme and theme.AccentColor) or Color3.fromRGB(96, 165, 250)
	tile.BackgroundTransparency = 0.8
	tile.Position = UDim2.fromOffset(12, 12)
	tile.Size = UDim2.fromOffset(34, 34)
	tile.Parent = root
	local tileCorner = Instance.new("UICorner")
	tileCorner.CornerRadius = UDim.new(0, 9)
	tileCorner.Parent = tile
	ThemeManager.BindColor(tile, "BackgroundColor3", "AccentColor")

	local glyph = Instance.new("ImageLabel")
	glyph.Name = UUID.Static("Icon")
	glyph.BorderSizePixel = 0
	glyph.BackgroundTransparency = 1
	glyph.AnchorPoint = Vector2.new(0.5, 0.5)
	glyph.Position = UDim2.fromScale(0.5, 0.5)
	glyph.Size = UDim2.fromOffset(17, 17)
	glyph.Image = Icons["table"] or Icons["table-2"]
	glyph.ImageColor3 = (theme and theme.PrimaryTextColor) or Color3.fromRGB(255, 255, 255)
	glyph.Parent = tile
	ThemeManager.BindColor(glyph, "ImageColor3", "PrimaryTextColor")

	local title = Instance.new("TextLabel")
	title.Name = UUID.Static("ElementName")
	title.BorderSizePixel = 0
	title.BackgroundTransparency = 1
	title.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	title.Text = name
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.TextColor3 = (theme and theme.PrimaryTextColor) or Color3.fromRGB(255, 255, 255)
	title.TextTransparency = (theme and theme.PrimaryTextTransparency) or 0.2
	title.Position = UDim2.fromOffset(58, 11)
	title.Size = UDim2.new(1, -58 - 44, 0, 18)
	title.Parent = root
	ThemeManager.BindColor(title, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(title, "TextTransparency", "PrimaryTextTransparency")

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = UUID.Static("Subtitle")
	subtitle.BorderSizePixel = 0
	subtitle.BackgroundTransparency = 1
	subtitle.FontFace = Constants.Font(Enum.FontWeight.Medium)
	subtitle.Text = ""
	subtitle.TextSize = 10
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.TextTruncate = Enum.TextTruncate.AtEnd
	subtitle.TextColor3 = (theme and theme.SecondaryTextColor) or Color3.fromRGB(200, 200, 200)
	subtitle.TextTransparency = (theme and theme.SecondaryTextTransparency) or 0.4
	subtitle.Position = UDim2.fromOffset(58, 29)
	subtitle.Size = UDim2.new(1, -58 - 44, 0, 14)
	subtitle.Parent = root
	ThemeManager.BindColor(subtitle, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(subtitle, "TextTransparency", "SecondaryTextTransparency")

	local chevron = Instance.new("ImageLabel")
	chevron.Name = UUID.Static("Chevron")
	chevron.BorderSizePixel = 0
	chevron.BackgroundTransparency = 1
	chevron.AnchorPoint = Vector2.new(1, 0.5)
	chevron.Position = UDim2.new(1, -14, 0.5, 0)
	chevron.Size = UDim2.fromOffset(14, 14)
	chevron.Image = Icons["chevron-right"]
	chevron.ImageTransparency = 0.35
	chevron.ImageColor3 = (theme and theme.AccentColor) or Color3.fromRGB(96, 165, 250)
	chevron.Parent = root
	ThemeManager.BindColor(chevron, "ImageColor3", "AccentColor")

	self.Title = title
	self.Subtitle = subtitle
	self._chevron = chevron

	local popup = nil

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

	local function popupContent()
		return {
			Title = name,
			Columns = self._columns,
			Rows = sortedRows(),
			SortBy = self._sortBy,
			SortDescending = self._sortDescending,
			Actions = self._actions,
			SelectedId = self._selectedId,
			SelectedColor = self._selectedColor,
			EmptyText = self._emptyText,
			RowColorTransparency = self._rowColorTransparency,
			Striped = self._striped,
			ShowHeader = self._showHeader,
			MaxRows = self._maxRows,
			RowHeight = self._rowHeight,
			RowGap = self._rowGap,
		}
	end

	local function refreshCard()
		local rows = #self._rows
		local rowsText = rows == 1 and "1 row" or tostring(rows) .. " rows"
		local columns = #self._columns
		local columnsText = columns == 1 and "1 column" or tostring(columns) .. " columns"
		subtitle.Text = rowsText .. " \u{00B7} " .. columnsText
	end

	local function refreshPopup()
		if popup and popup.IsOpen then
			popup:SetContent(popupContent())
		end
	end

	local function render()
		refreshCard()
		refreshPopup()
	end
	self._render = render

	local function setSelection(id, row)
		if self._selectedId == id then
			return false
		end
		self._selectedId = id
		if type(self._onSelectionChanged) == "function" then
			self._onSelectionChanged(id, row and copyRow(row) or nil)
		end
		return true
	end

	local function handleRowClick(row)
		if type(self._onRowClick) == "function" then
			self._onRowClick(row._id, copyRow(row))
		end
		-- The callback may have removed the row, so only select it when it is
		-- still the live entry for that id.
		if self._selectable and self._rowsById[row._id] == row and self._selectedId ~= row._id then
			setSelection(row._id, row)
			render()
		end
	end

	local function ensurePopup()
		if popup then
			return popup
		end
		-- Resolve at creation so a popup first opened after a theme switch is
		-- stamped with the live theme, not the one captured at build time.
		popup = DataTablePopUp.new(self._popupParent, { Theme = ThemeManager.GetCurrent(), Window = window })
		popup.OnSort = function(key)
			if self._sortBy == key then
				self._sortDescending = not self._sortDescending
			else
				self._sortBy = key
				self._sortDescending = false
			end
			render()
		end
		-- Only wire row clicks when a caller actually asked for them, so plain
		-- tables keep their previous non-interactive rows.
		if self._selectable or type(self._onRowClick) == "function" then
			popup.OnRowClick = function(id)
				local row = self._rowsById[id]
				if row then
					handleRowClick(row)
				end
			end
		end
		return popup
	end

	local function openPopup()
		local instance = ensurePopup()
		instance:SetContent(popupContent())
		if window and window._claimPopup then
			window:_claimPopup(instance)
		end
		instance:Open()
		-- Same open cue as the dropdown and colour picker popups.
		Sound.Play("Notification")
	end

	root.MouseButton1Click:Connect(openPopup)
	-- Hover derives from the live theme; the resting value must follow a
	-- switch, otherwise unhover jumps to the theme captured at build time.
	local function restingTransparency()
		return ThemeManager.Get("ComponentBackgroundTransparency") or 0.985
	end
	local function hoverTransparency()
		return math.max(0, restingTransparency() - 0.035)
	end
	root.MouseEnter:Connect(function()
		if popup and popup.IsOpen then
			return
		end
		Tween.Play(root, "Fast", { BackgroundTransparency = hoverTransparency() })
		Tween.Play(chevron, "Fast", { ImageTransparency = 0.1 })
	end)
	root.MouseLeave:Connect(function()
		Tween.Play(root, "Fast", { BackgroundTransparency = restingTransparency() })
		Tween.Play(chevron, "Fast", { ImageTransparency = 0.35 })
	end)

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
				-- Keep the selection only while its id survives the replacement.
				if me._selectedId ~= nil and not me._rowsById[me._selectedId] then
					setSelection(nil, nil)
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
				-- Removing the selected row leaves nothing selected.
				if me._selectedId == id then
					setSelection(nil, nil)
				end
				render()
				return true
			end,
			ClearRows = function(me)
				me._rows = {}
				me._rowsById = {}
				me._order = 0
				if me._selectedId ~= nil then
					setSelection(nil, nil)
				end
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
				render()
				return me
			end,
			SetColumns = function(me, columns)
				me._columns = compileColumns(columns)
				render()
				return me
			end,
			SetAction = function(me, action)
				me._actions = type(action) == "table" and { action } or {}
				render()
				return me
			end,
			SetActions = function(me, actions)
				me._actions = clampActions(actions)
				render()
				return me
			end,
			SetSelected = function(me, id)
				local row = me._rowsById[id]
				if not row then
					return false
				end
				if me._selectedId ~= id then
					setSelection(id, row)
					render()
				end
				return true
			end,
			GetSelected = function(me)
				local row = me._selectedId and me._rowsById[me._selectedId]
				return me._selectedId, row and copyRow(row) or nil
			end,
			ClearSelected = function(me)
				if me._selectedId ~= nil then
					setSelection(nil, nil)
					render()
				end
				return me
			end,
			SetHeaderVisible = function(me, visible)
				me._showHeader = visible == true
				render()
				return me
			end,
			Open = function(me)
				openPopup()
				return me
			end,
			Close = function(me)
				if popup then
					popup:Close()
				end
				return me
			end,
			Destroy = function(me)
				for _, descendant in ipairs(me.Frame:GetDescendants()) do
					ThemeManager.UnbindInstance(descendant)
				end
				ThemeManager.UnbindInstance(me.Frame)
				me.Frame:Destroy()
				me.Frame = nil
				if popup then
					if window and window._activePopUp == popup then
						window._activePopUp = nil
					end
					popup:Destroy()
					popup = nil
				end
			end,
		},
	})

	refreshCard()
	return self
end

return DataTable
