--[[
	Aetheris/Components/Dropdown.luau

	Button that opens a modal popup for single or multi item selection. The
	popup is PopUps/DropdownPopUp, created lazily via ShowDropdownPopup.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Icons = require("../Assets/Icons")
local Tween = require("../Utils/Tween")
local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local ComponentRow = require("./ComponentRow")
local ComponentAPI = require("../Utils/ComponentAPI")
local UUID = require("../Utils/UUID")
local Dropdown = {}
Dropdown.__index = Dropdown
local _counter = 0
-- Icon hover lifts in over 0.15s and settles back over 0.2s.
local ICON_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ICON_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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
	-- Covers the row so clicks anywhere open the popup.
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
	dropdownImage.Image = Icons["chevron-down"]
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
			Theme = ActiveTheme.theme or self._theme,
			OnConfirm = function(selected)
				selectedItems = selected
				if callback then
					callback(selectedItems)
				end
				popupInstance = nil
			end,
			OnCancel = function()
				-- Cleared on cancel too, including click-outside.
				popupInstance = nil
			end,
		})
		popupInstance:Open()
	end
	-- Only the interact button, to avoid double-fire from row.InputBegan.
	interact.MouseButton1Click:Connect(function()
		openPopup()
	end)
	interact.MouseEnter:Connect(function()
		Tween.Play(dropdownImage, ICON_IN, { ImageTransparency = 0 })
	end)
	interact.MouseLeave:Connect(function()
		Tween.Play(dropdownImage, ICON_OUT, { ImageTransparency = 0.5 })
	end)
	ThemeManager.BindColor(row, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(row, "BackgroundTransparency", "ComponentBackgroundTransparency")
	-- ComponentRow creates and binds the row stroke (Stroke = true).
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(dropdownImage, "ImageColor3", "AccentColor")
	self.Destroy = function()
		if popupInstance and popupInstance.IsOpen then
			pcall(function()
				popupInstance:Close()
			end)
			popupInstance = nil
		end
		-- Row stroke bindings end with its Destroying signal.
		ThemeManager.UnbindInstance(row)
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(dropdownImage)
		if row and row.Parent then
			row:Destroy()
		end
	end
	ComponentAPI.Apply(self, {
		Root = row,
		Label = label,
		Name = name,
		Methods = {
			GetSelected = function()
				return selectedItems
			end,
			SetValues = function(_, newItems, keepSelection)
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
			end,
			SetValue = function(_, value, silent)
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
			end,
			OpenPopup = openPopup,
		},
	})
	return self
end
return Dropdown
