--[[
	Dropdown  ·  Aetheris UI Library

	Button that opens a modal popup for single/multi item selection. The
	button row lives here; the popup itself is PopUps/DropdownPopUp, created
	lazily via the supplied ShowDropdownPopup factory.

	Usage (via Section):
		local dropdown = section:Dropdown({
			Name = "Select Option",
			Items = {
				{ name = "Option A", icon = Icons.circle, value = "a" },
				{ name = "Option B", icon = Icons.circle, value = "b" },
			},
			Default = { "a" },
			MaxItemsChoosable = 2,
			Placeholder = "Choose...",
			Callback = function(selected) print(selected) end,
		}, ShowDropdownPopup)
]]

local Icons = require("../Assets/Icons")
local ThemeManager = require("../Themes/ThemeManager")
local ComponentRow = require("./ComponentRow")
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
	-- Generate a unique ID from the name and a counter
	self._id = name .. _counter
	local items = Settings.Items or {}
	local default = Settings.Default or {}
	local maxItems = Settings.MaxItemsChoosable or math.huge
	local callback = Settings.Callback or function() end
	-- Build the dropdown button UI from the export (shared row factory).
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
	-- Interact button (covers the whole row to capture clicks)
	local interact = Instance.new("TextButton")
	interact.Name = "Interact"
	interact.BorderSizePixel = 0
	interact.TextSize = 14
	interact.TextColor3 = Color3.fromRGB(0, 0, 0)
	interact.BackgroundTransparency = 1
	interact.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	interact.Size = UDim2.fromScale(1, 1)
	interact.Text = ""
	interact.Parent = row
	-- Dropdown chevron image
	local dropdownImage = Instance.new("ImageLabel")
	dropdownImage.Name = "DropdownImage"
	dropdownImage.BorderSizePixel = 0
	dropdownImage.BackgroundTransparency = 1
	dropdownImage.ImageTransparency = 0.5
	dropdownImage.AnchorPoint = Vector2.new(1, 0.5)
	dropdownImage.Image = Icons["chevron-down"] or "rbxassetid://134243273101015"
	dropdownImage.ImageColor3 = (theme and theme.AccentColor)
	dropdownImage.Size = UDim2.fromOffset(14, 14)
	dropdownImage.Position = UDim2.new(1, -20, 0.5, 0)
	dropdownImage.Parent = row
	-- State
	local selectedItems = {} -- array of { name, value }
	-- Initialize from Default values
	for _, value in ipairs(default) do
		for _, item in ipairs(items) do
			if item.value == value then
				table.insert(selectedItems, { name = item.name, value = item.value })
				break
			end
		end
	end
	local popupInstance = nil
	-- Function to open the popup
	local function openPopup()
		if popupInstance and popupInstance.IsOpen then
			-- If a popup is already open, do nothing
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
			Theme = self._theme, -- Pass theme to popup
			OnConfirm = function(selected)
				selectedItems = selected
				if callback then
					callback(selectedItems)
				end
				popupInstance = nil
			end,
			OnCancel = function()
				-- Clear the instance when cancelled (including click-outside)
				popupInstance = nil
			end,
		})
		popupInstance:Open()
	end
	-- Click handler: ONLY the interact button (avoid double-fire from row.InputBegan)
	interact.MouseButton1Click:Connect(function()
		openPopup()
	end)
	-- Public API
	self.SetItems = function(newItems)
		items = newItems
		selectedItems = {}
	end
	self.GetSelected = function()
		return selectedItems
	end
	self.UpdateName = function(newName)
		label.Text = newName
	end
	self.OpenPopup = openPopup
	-- Declarative theming: every themed property is a BINDING.
	ThemeManager.BindColor(row, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(row, "BackgroundTransparency", "ComponentBackgroundTransparency")
	-- The row's UIStroke is created AND bound by ComponentRow (Stroke = true),
	-- so it needs no binding here.
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(dropdownImage, "ImageColor3", "AccentColor")
	-- Uniform component API (p2-4).
	self.SetVisibility = function(_self, visible)
		row.Visible = visible
	end
	self.Destroy = function()
		-- Close any open popup first to avoid it dangling.
		if popupInstance and popupInstance.IsOpen then
			pcall(function()
				popupInstance:Close()
			end)
			popupInstance = nil
		end
		-- Drop all ThemeManager bindings. (The row's stroke binds die with the
		-- row's own Destroying signal, so it needs no unbind here.)
		ThemeManager.UnbindInstance(row)
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(dropdownImage)
		-- Destroy the root instance.
		if row and row.Parent then
			row:Destroy()
		end
	end
	return self
end
return Dropdown
