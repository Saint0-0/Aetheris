--[[
	Aetheris/Components/Dropdown.luau

	Button that opens a modal popup for single/multi item selection. The
	button row lives here; the popup itself is PopUps/DropdownPopUp, created
	lazily via the supplied ShowDropdownPopup factory.
	License: Saint0-0 Source License - use in your own scripts, no editing or
	redistribution without permission. (c) 2026 Saint0-0.
]]

local Icons = require("../Assets/Icons")
local ThemeManager = require("../Themes/ThemeManager")
local ComponentRow = require("./ComponentRow")
local ComponentAPI = require("../Utils/ComponentAPI")
local UUID = require("../Utils/UUID")
local Dropdown = {}
Dropdown.__index = Dropdown
local _counter = 0
function Dropdown.new(parent, Settings, ShowPopup, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Dropdown)
	self._theme = theme
	_counter = _counter + 1
	local name = Settings.Name or "Dropdown"
	self._id = name .. _counter
	local items = Settings.Items or {}
	local default = Settings.Default or {}
	local maxItems = Settings.MaxItemsChoosable or math.huge
	local callback = Settings.Callback or function() end
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "Dropdown",
		Theme = theme,
		Clickable = false,
		LabelWidth = 0.82748,
		LabelPosition = UDim2.new(0, 10, 0.5, 0),
		BackgroundColor = (theme and theme.ComponentBackgroundColor),
		BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985,
		ClipsDescendants = true,
		CornerRadius = 6,
		Stroke = true,
		ComponentContainer = true,
	})
	-- covers the whole row so clicks anywhere open the popup
	local interact = Instance.new("TextButton")
	interact.Name = UUID.Static("Interact")
	interact.BorderSizePixel = 0
	interact.TextSize = 14
	interact.TextColor3 = Color3.fromRGB(0, 0, 0)
	interact.BackgroundTransparency = 1
	interact.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	interact.Size = UDim2.fromScale(1, 1)
	interact.Text = ""
	interact.Parent = row
	local dropdownImage = Instance.new("ImageLabel")
	dropdownImage.Name = UUID.Static("DropdownImage")
	dropdownImage.BorderSizePixel = 0
	dropdownImage.BackgroundTransparency = 1
	dropdownImage.ImageTransparency = 0.5
	dropdownImage.AnchorPoint = Vector2.new(1, 0.5)
	dropdownImage.Image = Icons["list-tree"]
	dropdownImage.ImageColor3 = (theme and theme.AccentColor)
	dropdownImage.Size = UDim2.fromOffset(14, 14)
	dropdownImage.Position = UDim2.new(1, -20, 0.5, 0)
	dropdownImage.Parent = row
	local selectedItems = {} -- array of { name, value }
	for _, value in ipairs(default) do
		for _, item in ipairs(items) do
			if item.value == value then
				table.insert(selectedItems, { name = item.name, value = item.value })
				break
			end
		end
	end
	local popupInstance = nil
	local function openPopup()
		if popupInstance and popupInstance.IsOpen then
			return
		end
		if not ShowPopup then
			warn("[Dropdown] ShowPopup function not provided")
			return
		end
		local defaultValues = {}
		for _, item in ipairs(selectedItems) do
			table.insert(defaultValues, item.value)
		end
		popupInstance = ShowPopup(self._id, {
			Title = name,
			Items = items,
			Default = defaultValues,
			MaxItemsChoosable = maxItems,
			Theme = self._theme,
			OnConfirm = function(selected)
				selectedItems = selected
				if callback then
					callback(selectedItems)
				end
				popupInstance = nil
			end,
			OnCancel = function()
				-- cleared on cancel too, including click-outside
				popupInstance = nil
			end,
		})
		popupInstance:Open()
	end
	-- only the interact button, to avoid double-fire from row.InputBegan
	interact.MouseButton1Click:Connect(function()
		openPopup()
	end)
	self.SetItems = function(_, newItems)
		items = newItems
		selectedItems = {}
	end
	self.GetSelected = function()
		return selectedItems
	end
	-- Replace the item list. Selections whose values vanish are dropped when
	-- keepSelection is set; otherwise the selection clears (same as SetItems).
	self.SetValues = function(_, newItems, keepSelection)
		items = type(newItems) == "table" and newItems or {}
		if not keepSelection then
			selectedItems = {}
			return
		end
		local valid = {}
		for _, sel in ipairs(selectedItems) do
			for _, item in ipairs(items) do
				if item.value == sel.value then
					table.insert(valid, { name = item.name, value = item.value })
					break
				end
			end
		end
		selectedItems = valid
	end
	-- Set the selection by value (single value or array of values). Silent
	-- skips the callback - used by config load, where the value comes from disk.
	self.SetValue = function(_, value, silent)
		local wanted = type(value) == "table" and value or { value }
		selectedItems = {}
		for _, item in ipairs(items) do
			for _, w in ipairs(wanted) do
				if item.value == w then
					table.insert(selectedItems, { name = item.name, value = item.value })
					break
				end
			end
		end
		if not silent and callback then
			callback(selectedItems)
		end
	end
	self.UpdateName = function(_, newName)
		label.Text = newName
	end
	self.OpenPopup = openPopup
	ThemeManager.BindColor(row, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(row, "BackgroundTransparency", "ComponentBackgroundTransparency")
	-- the row's stroke is created and bound by ComponentRow (Stroke = true)
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(dropdownImage, "ImageColor3", "AccentColor")
	self.SetVisibility = function(_self, visible)
		row.Visible = visible
	end
	self.Destroy = function()
		-- close any open popup so it can't dangle
		if popupInstance and popupInstance.IsOpen then
			pcall(function()
				popupInstance:Close()
			end)
			popupInstance = nil
		end
		-- the row's own stroke binds die with its Destroying signal
		ThemeManager.UnbindInstance(row)
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(dropdownImage)
		if row and row.Parent then
			row:Destroy()
		end
	end
	ComponentAPI.Apply(self, { Root = row, Label = label, Name = name })
	return self
end
return Dropdown
