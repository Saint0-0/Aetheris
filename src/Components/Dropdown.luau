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
	local placeholder = Settings.Placeholder or "Select..."
	local callback = Settings.Callback or function() end
	-- Build the dropdown button UI from the export
	local row = Instance.new("Frame")
	row.Name = name .. "Dropdown"
	row.BorderSizePixel = 0
	row.BackgroundColor3 = (theme and theme.ComponentBackgroundColor)
	row.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.ClipsDescendants = true
	row.Size = UDim2.new(1, 0, 0, 45)
	row:SetAttribute("IsComponentContainer", true)
	row.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = row
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = row
	-- Interact button (covers the whole row to capture clicks)
	local interact = Instance.new("TextButton")
	interact.Name = "Interact"
	interact.BorderSizePixel = 0
	interact.TextSize = 14
	interact.TextColor3 = Color3.fromRGB(0, 0, 0)
	interact.BackgroundTransparency = 1
	interact.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	interact.Size = UDim2.new(1, 0, 1, 0)
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
	dropdownImage.Size = UDim2.new(0, 14, 0, 14)
	dropdownImage.Position = UDim2.new(0.9, 0, 0.5, 0)
	dropdownImage.Parent = row
	-- Label (always displays the dropdown name)
	local label = Instance.new("TextLabel")
	label.Name = "ElementName"
	label.TextWrapped = true
	label.BorderSizePixel = 0
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTransparency = (theme and theme.PrimaryTextTransparency) or 0.45
	label.BackgroundTransparency = 1
	label.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	label.TextColor3 = (theme and theme.PrimaryTextColor)
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Size = UDim2.new(0.82748, 0, 0.71359, 0)
	label.Position = UDim2.new(0, 10, 0.5, 0)
	label.BorderColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = name
	label.Parent = row
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
	-- Click handler (only the interact button opens the popup)
	interact.MouseButton1Click:Connect(function()
		openPopup()
	end)
	-- Also allow clicking on the row if it's a Frame (it's a Frame now, but we keep this for safety)
	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			openPopup()
		end
	end)
	-- Public API
	self.SetItems = function(newItems)
		items = newItems
		selectedItems = {}
	end
	self.GetSelected = function()
		return selectedItems
	end
	self.SetVisibility = function(visible)
		row.Visible = visible
	end
	self.UpdateName = function(newName)
		label.Text = newName
		-- Also update the ID to reflect the new name? We'll keep the original ID based on the initial name.
	end
	self.OpenPopup = openPopup
	-- Component-owned theming (see ThemeManager registry).
	function self:ApplyTheme(newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		self._theme = theme
		row.BackgroundColor3 = theme.ComponentBackgroundColor or row.BackgroundColor3
		row.BackgroundTransparency = theme.ComponentBackgroundTransparency or row.BackgroundTransparency
		stroke.Color = theme.StrokeColor or stroke.Color
		stroke.Transparency = theme.StrokeTransparency or stroke.Transparency
		label.TextColor3 = theme.PrimaryTextColor or label.TextColor3
		label.TextTransparency = theme.PrimaryTextTransparency or label.TextTransparency
		dropdownImage.ImageColor3 = theme.AccentColor or dropdownImage.ImageColor3
	end
	ThemeManager.Register(row, self)
	return self
end
return Dropdown