--[[
	DropdownPopUp  ·  Aetheris UI Library

	Modal popup for dropdown selection: searchable item list, select-all,
	clear, and a max-selection cap. SetContent diffs the incoming item list
	and only rebuilds rows when it actually changed (rows are ~10 instances
	each). Created lazily by Components/Dropdown and cached per id by Window;

theme switches drop the cache so the next open rebuilds with current colors.
]]

local Tween = require("../Utils/Tween")
local Sound = require("../Utils/Sound")
local Icons = require("../Assets/Icons")
local FallbackImage = require("../Constants").FallbackImage
local ThemeManager = require("../Themes/ThemeManager")
local SearchFilter = require("../Core/SearchFilter")
local DropdownPopUp = {}
DropdownPopUp.__index = DropdownPopUp
local function sanitizeName(str)
	return str:gsub("[^%w_]", "_")
end
-- Compares two item lists by the fields that affect the rendered rows. Used to
-- skip rebuilding every row when the list is unchanged (the common case: a
-- dropdown re-sends the same items on each open).
local function itemsEqual(a, b)
	if #a ~= #b then return false end
	for i = 1, #a do
		local x, y = a[i], b[i]
		if x.name ~= y.name or x.value ~= y.value or x.icon ~= y.icon then
			return false
		end
	end
	return true
end
function DropdownPopUp.new(parent, Settings, cleanupCallback)
	Settings = Settings or {}
	local self = setmetatable({}, DropdownPopUp)
	local theme = Settings.Theme
	self._theme = theme
	local title = Settings.Title or "Select Items"
	local titleColor = Settings.TitleColor or (theme and theme.TitleTextColor)
	local items = Settings.Items or {}
	local default = Settings.Default or {}
	local maxItems = Settings.MaxItemsChoosable or math.huge
	local onConfirm = Settings.OnConfirm or function() end
	local onCancel = Settings.OnCancel or function() end
	-- ============================================================
	-- Build UI from the existing export
	-- ============================================================
	local popup = Instance.new("Frame")
	popup.Name = sanitizeName(title) .. "DropdownPopup"
	popup.BorderSizePixel = 0
	popup.BackgroundColor3 = (theme and theme.PopupBackgroundColor)
	popup.BackgroundTransparency = (theme and theme.PopupBackgroundTransparency) or 1
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Size = UDim2.new(0.694, 0, 1.02153, 0)
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	popup.Visible = false
	popup.ZIndex = 11
	popup.Parent = parent
	local shadow = Instance.new("UIShadow")
	shadow.Color = (theme and theme.PopupShadowColor)
	shadow.BlurRadius = UDim.new(0, 20)
	shadow.Transparency = 1
	shadow.Parent = popup
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = popup
	local scale = Instance.new("UIScale")
	scale.Scale = 0.9
	scale.Parent = popup
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.BorderSizePixel = 0
	header.TextSize = 16
	header.TextXAlignment = Enum.TextXAlignment.Center
	header.TextTransparency = 1
	header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	header.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	header.TextColor3 = titleColor or (theme and theme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
	header.BackgroundTransparency = 1
	header.AnchorPoint = Vector2.new(0.5, 0.5)
	header.Size = UDim2.new(0.26291, 0, 0.03775, 0)
	header.AutomaticSize = Enum.AutomaticSize.X
	header.Position = UDim2.new(0.5, 0, 0, 25)
	header.Parent = popup
	header.Text = title
	local interactions = Instance.new("Frame")
	interactions.Name = "Interactions"
	interactions.BorderSizePixel = 0
	interactions.BackgroundTransparency = 1
	interactions.AnchorPoint = Vector2.new(0.5, 0.5)
	interactions.Size = UDim2.new(0.9375, 0, 0.16328, 0)
	interactions.Position = UDim2.new(0.5, 0, 0.89551, 0)
	interactions.Parent = popup
	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Name = "Confirm"
	confirmBtn.BorderSizePixel = 0
	confirmBtn.TextTransparency = 1
	confirmBtn.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.TextSize = 12
	confirmBtn.Text = "Confirm"
	confirmBtn.AutoButtonColor = false
	confirmBtn.TextColor3 = (theme and theme.PopupTextColor)
	confirmBtn.BackgroundColor3 = (theme and theme.PrimaryColor)
	confirmBtn.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	confirmBtn.AnchorPoint = Vector2.new(0.5, 0)
	confirmBtn.Size = UDim2.new(1, 0, 0.43911, 0)
	confirmBtn.Position = UDim2.new(0.5, 0, 0, 0)
	confirmBtn.Parent = interactions
	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 4)
	confirmCorner.Parent = confirmBtn
	local confirmShadow = Instance.new("UIShadow")
	confirmShadow.BlurRadius = UDim.new(0, 20)
	confirmShadow.Color = (theme and theme.PrimaryColor)
	confirmShadow.Transparency = 1
	confirmShadow.Parent = confirmBtn
	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Name = "Cancel"
	cancelBtn.BorderSizePixel = 0
	cancelBtn.TextTransparency = 1
	cancelBtn.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.TextSize = 12
	cancelBtn.Text = "Cancel"
	cancelBtn.AutoButtonColor = false
	cancelBtn.TextColor3 = (theme and theme.PopupTextColor)
	cancelBtn.BackgroundColor3 = (theme and theme.PopupNeutralColor)
	cancelBtn.BackgroundTransparency = 0.5
	cancelBtn.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	cancelBtn.AnchorPoint = Vector2.new(0.5, 1)
	cancelBtn.Size = UDim2.new(1, 0, 0.43882, 0)
	cancelBtn.Position = UDim2.new(0.5, 0, 1, 0)
	cancelBtn.Parent = interactions
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 4)
	cancelCorner.Parent = cancelBtn
	local cancelShadow = Instance.new("UIShadow")
	cancelShadow.BlurRadius = UDim.new(0, 20)
	cancelShadow.Color = (theme and theme.PopupNeutralColor)
	cancelShadow.Transparency = 1
	cancelShadow.Parent = cancelBtn
	local list = Instance.new("ScrollingFrame")
	list.Name = "DropdownList"
	list.Active = true
	list.BorderSizePixel = 0
	list.ScrollBarImageTransparency = 0.5
	list.BackgroundTransparency = 1
	list.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
	list.AnchorPoint = Vector2.new(0.5, 0.5)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Size = UDim2.new(0.938, 0, 0.43668, 0)
	list.Position = UDim2.new(0.5, 0, 0.48976, 0)
	list.ScrollBarThickness = 1
	list.ScrollBarImageColor3 = (theme and theme.TertiaryColor)
	list.Parent = popup
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 15)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list
	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 2)
	listPadding.PaddingRight = UDim.new(0, 8)
	listPadding.PaddingLeft = UDim.new(0, 8)
	listPadding.Parent = list
	local selectedText = Instance.new("TextLabel")
	selectedText.Name = "SelectedItemsText"
	selectedText.TextWrapped = true
	selectedText.BorderSizePixel = 0
	selectedText.TextSize = 13
	selectedText.TextXAlignment = Enum.TextXAlignment.Left
	selectedText.TextTransparency = 1
	selectedText.BackgroundTransparency = 1
	selectedText.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	selectedText.TextColor3 = (theme and theme.PopupTextColor)
	selectedText.RichText = true
	selectedText.AnchorPoint = Vector2.new(0.5, 0.5)
	selectedText.Size = UDim2.new(0.91, 0, 0, 26)
	selectedText.Position = UDim2.new(0.5, 0, 0.76384, 0)
	selectedText.Parent = popup
	selectedText.Text = "None selected"
	local selectedPadding = Instance.new("UIPadding")
	selectedPadding.PaddingTop = UDim.new(0, 3)
	selectedPadding.PaddingLeft = UDim.new(0, 5)
	selectedPadding.PaddingBottom = UDim.new(0, 15)
	selectedPadding.Parent = selectedText
	local selectedDivider = Instance.new("Frame")
	selectedDivider.Name = "ComponentDivider"
	selectedDivider.BorderSizePixel = 0
	selectedDivider.BackgroundColor3 = (theme and theme.AccentColor)
	selectedDivider.BackgroundTransparency = 0.9
	selectedDivider.AnchorPoint = Vector2.new(0.5, 0.5)
	selectedDivider.Size = UDim2.new(0.8, 0, 0, 2)
	selectedDivider.Position = UDim2.new(0.5, 0, 2.6, 0)
	selectedDivider.Parent = selectedText
	local searchArea = Instance.new("Frame")
	searchArea.Name = "InteractionOrganizer"
	searchArea.BorderSizePixel = 0
	searchArea.BackgroundTransparency = 1
	searchArea.AnchorPoint = Vector2.new(0.5, 0.5)
	searchArea.Size = UDim2.new(0.91879, 0, 0.0779, 0)
	searchArea.Position = UDim2.new(0.5, 0, 0.1868, 0)
	searchArea.Parent = popup
	local searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchBox"
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	searchBox.BorderSizePixel = 0
	searchBox.TextTruncate = Enum.TextTruncate.AtEnd
	searchBox.TextTransparency = 1
	searchBox.TextSize = 14
	searchBox.TextColor3 = (theme and theme.PopupTextColor)
	searchBox.BackgroundTransparency = 1
	searchBox.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	searchBox.AnchorPoint = Vector2.new(0.5, 0.5)
	searchBox.PlaceholderText = "Search..."
	searchBox.Size = UDim2.new(0.38996, 0, 1, 0)
	searchBox.Position = UDim2.new(0.26484, 0, 0.5, 0)
	searchBox.Parent = searchArea
	-- Mirrors the sidebar search bar's BottomDivider: an inset 80%-wide line
	-- centered under the whole search area (NOT the box, which is narrower).
	local searchDivider = Instance.new("Frame")
	searchDivider.Name = "SearchDividerBottom"
	searchDivider.BorderSizePixel = 0
	searchDivider.BackgroundColor3 = (theme and theme.TertiaryColor) or Color3.fromRGB(160, 160, 160)
	searchDivider.BackgroundTransparency = 0.9
	searchDivider.AnchorPoint = Vector2.new(0, 0.5)
	searchDivider.Size = UDim2.new(0.6, 0, 0, 1)
	searchDivider.Position = UDim2.new(0, 0, 1, 0)
	searchDivider.Parent = searchArea
	local searchIcon = Instance.new("ImageLabel")
	searchIcon.Name = "SearchImage"
	searchIcon.BorderSizePixel = 0
	searchIcon.BackgroundTransparency = 1
	searchIcon.ImageTransparency = 0.7
	searchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	searchIcon.Image = Icons.search
	searchIcon.ImageColor3 = (theme and theme.SecondaryColor) or Color3.fromRGB(200, 200, 200)
	searchIcon.Size = UDim2.new(0, 17, 0, 15)
	searchIcon.Position = UDim2.new(0.01759, 0, 0.5, 0)
	searchIcon.Parent = searchArea
	local clearBtn = Instance.new("TextButton")
	clearBtn.Name = "ClearSelection"
	clearBtn.BorderSizePixel = 0
	clearBtn.TextTransparency = 1
	clearBtn.AutoButtonColor = false
	clearBtn.BackgroundColor3 = (theme and theme.TertiaryColor) or Color3.fromRGB(100, 116, 139)
	clearBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	clearBtn.Size = UDim2.new(0.09462, 0, 1, 0)
	clearBtn.Position = UDim2.new(0.96018, 0, 0.5, 0)
	clearBtn.Parent = searchArea
	local clearCorner = Instance.new("UICorner")
	clearCorner.CornerRadius = UDim.new(0, 6)
	clearCorner.Parent = clearBtn
	local clearIcon = Instance.new("ImageLabel")
	clearIcon.Name = "ButtonImage"
	clearIcon.ImageTransparency = 0.2
	clearIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	clearIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	clearIcon.Image = Icons["eraser"]
	clearIcon.ImageColor3 = (theme and theme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
	clearIcon.Size = UDim2.new(0, 17, 0, 17)
	clearIcon.BackgroundTransparency = 1
	clearIcon.Parent = clearBtn
	local clearAspect = Instance.new("UIAspectRatioConstraint")
	clearAspect.DominantAxis = Enum.DominantAxis.Height
	clearAspect.Parent = clearIcon
	local clearShadow = Instance.new("UIShadow")
	clearShadow.BlurRadius = UDim.new(0, 20)
	clearShadow.Color = (theme and theme.TertiaryColor) or Color3.fromRGB(100, 116, 139)
	clearShadow.Transparency = 1
	clearShadow.Parent = clearBtn
	local selectAllBtn = Instance.new("TextButton")
	selectAllBtn.Name = "SelectAll"
	selectAllBtn.BorderSizePixel = 0
	selectAllBtn.TextTransparency = 1
	selectAllBtn.AutoButtonColor = false
	selectAllBtn.BackgroundColor3 = (theme and theme.AccentColor) or Color3.fromRGB(96, 165, 250)
	selectAllBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	selectAllBtn.Size = UDim2.new(0.09462, 0, 1, 0)
	selectAllBtn.Position = UDim2.new(0.83689, 0, 0.5, 0)
	selectAllBtn.Parent = searchArea
	local selectAllCorner = Instance.new("UICorner")
	selectAllCorner.CornerRadius = UDim.new(0, 6)
	selectAllCorner.Parent = selectAllBtn
	local selectAllIcon = Instance.new("ImageLabel")
	selectAllIcon.Name = "ButtonImage"
	selectAllIcon.ImageTransparency = 0.2
	selectAllIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	selectAllIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	selectAllIcon.Image = Icons["list-check"]
	selectAllIcon.ImageColor3 = (theme and theme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
	selectAllIcon.Size = UDim2.new(0, 17, 0, 17)
	selectAllIcon.BackgroundTransparency = 1
	selectAllIcon.Parent = selectAllBtn
	local selectAllAspect = Instance.new("UIAspectRatioConstraint")
	selectAllAspect.DominantAxis = Enum.DominantAxis.Height
	selectAllAspect.Parent = selectAllIcon
	local selectAllShadow = Instance.new("UIShadow")
	selectAllShadow.BlurRadius = UDim.new(0, 20)
	selectAllShadow.Color = (theme and theme.AccentColor) or Color3.fromRGB(96, 165, 250)
	selectAllShadow.Transparency = 1
	selectAllShadow.Parent = selectAllBtn
	-- Hide SelectAll if cap is finite
	if maxItems ~= math.huge then
		selectAllBtn.Visible = false
	end
	-- ============================================================
	-- Store references
	-- ============================================================
	self.Popup = popup
	self.Shadow = shadow
	self.Header = header
	self.ConfirmBtn = confirmBtn
	self.ConfirmShadow = confirmShadow
	self.CancelBtn = cancelBtn
	self.CancelShadow = cancelShadow
	self.List = list
	self.ListLayout = listLayout
	self.SelectedText = selectedText
	self.SearchBox = searchBox
	self.SelectAllBtn = selectAllBtn
	self.SelectAllShadow = selectAllShadow
	self.ClearBtn = clearBtn
	self.ClearShadow = clearShadow
	self.SearchIcon = searchIcon
	self.SearchDivider = searchDivider
	self.SelectAllIcon = selectAllIcon
	self.ClearBtnIcon = clearIcon
	self.Divider = selectedDivider
	self.Items = items
	self.MaxItems = maxItems
	self.OnConfirm = onConfirm
	self.OnCancel = onCancel
	self._cleanupCallback = cleanupCallback
	self.IsOpen = false
	self._resolved = false
	self._itemObjects = {}
	self._selectedValues = {}
	self._inputConnection = nil
	self._scrollbarTimer = nil
	self._hideTimer = nil

	-- Search box focus animation, mirroring the sidebar search bar: the bottom
	-- divider and search icon sharpen while the box is focused and relax at rest.
	searchBox.Focused:Connect(function()
		Tween.Play(searchDivider, "Fast", { BackgroundTransparency = 0.2 })
		Tween.Play(searchIcon, "Fast", { ImageTransparency = 0.2 })
	end)
	searchBox.FocusLost:Connect(function()
		Tween.Play(searchDivider, "Fast", { BackgroundTransparency = 0.9 })
		Tween.Play(searchIcon, "Fast", { ImageTransparency = 0.7 })
	end)

	-- ============================================================
	-- ApplyTheme(theme): re-apply every theme-driven color WITHOUT
	-- rebuilding. Called by Window:SetTheme so a cached/open dropdown recolors
	-- live instead of being destroyed and recreated.
	-- ============================================================
	function self:ApplyTheme(theme)
		if not self.Popup then return end
		local t = ThemeManager.GetTheme(theme)
		self._theme = t
		self.Popup.BackgroundColor3 = t.PopupBackgroundColor or self.Popup.BackgroundColor3
		self.Shadow.Color = t.PopupShadowColor or self.Shadow.Color
		self.Header.TextColor3 = t.PopupTextColor or self.Header.TextColor3
		self.ConfirmBtn.TextColor3 = t.PopupTextColor or self.ConfirmBtn.TextColor3
		self.ConfirmBtn.BackgroundColor3 = t.PrimaryColor or self.ConfirmBtn.BackgroundColor3
		self.ConfirmShadow.Color = t.PrimaryColor or self.ConfirmShadow.Color
		self.CancelBtn.TextColor3 = t.PopupTextColor or self.CancelBtn.TextColor3
		self.CancelBtn.BackgroundColor3 = t.PopupNeutralColor or self.CancelBtn.BackgroundColor3
		self.CancelShadow.Color = t.PopupNeutralColor or self.CancelShadow.Color
		self.SelectedText.TextColor3 = t.PopupTextColor or self.SelectedText.TextColor3
		self.Divider.BackgroundColor3 = t.AccentColor or self.Divider.BackgroundColor3
		self.SearchBox.TextColor3 = t.PopupTextColor or self.SearchBox.TextColor3
		self.SearchDivider.BackgroundColor3 = t.TertiaryColor or self.SearchDivider.BackgroundColor3
		self.SearchIcon.ImageColor3 = t.SecondaryColor or self.SearchIcon.ImageColor3
		self.ClearBtn.BackgroundColor3 = t.TertiaryColor or self.ClearBtn.BackgroundColor3
		self.ClearShadow.Color = t.TertiaryColor or self.ClearShadow.Color
		self.ClearBtnIcon.ImageColor3 = t.PopupTextColor or self.ClearBtnIcon.ImageColor3
		self.SelectAllBtn.BackgroundColor3 = t.AccentColor or self.SelectAllBtn.BackgroundColor3
		self.SelectAllShadow.Color = t.AccentColor or self.SelectAllShadow.Color
		self.SelectAllIcon.ImageColor3 = t.PopupTextColor or self.SelectAllIcon.ImageColor3
		self.List.ScrollBarImageColor3 = t.TertiaryColor or self.List.ScrollBarImageColor3
		-- Re-tint every item row (bg accent, name + icon follow selection state).
		for _, obj in ipairs(self._itemObjects) do
			if obj.button then obj.button.BackgroundColor3 = t.AccentColor or obj.button.BackgroundColor3 end
			if obj.nameLabel then obj.nameLabel.TextColor3 = t.PopupTextColor or obj.nameLabel.TextColor3 end
			if obj.icon then
				obj.icon.ImageColor3 = obj.selected and (t.ActiveTabIconColor or obj.icon.ImageColor3)
					or (t.InactiveTabIconColor or obj.icon.ImageColor3)
			end
			if obj.stroke then obj.stroke.Color = t.StrokeColor or obj.stroke.Color end
			if obj.shadow then obj.shadow.Color = t.ComponentShadowColor or obj.shadow.Color end
			-- Item sheen follows the theme wallpaper (was previously handled by
			-- ThemeManager.updateThemeSheens; now owned here since rows are
			-- recolored in place rather than rebuilt).
			if obj.backImage then
				obj.backImage.Image = t.Wallpaper or FallbackImage
				obj.backImage.Visible = not (t.WallpaperEnabled == false)
			end
		end
	end

	-- ============================================================
	-- Internal methods
	-- ============================================================
	function self:_toggleItem(itemObj)
		local isSelected = itemObj.selected
		if self.MaxItems == 1 then
			if not isSelected then
				for _, obj in ipairs(self._itemObjects) do
					if obj.selected then
						self:_setItemSelected(obj, false)
					end
				end
				self._selectedValues = {}
				self:_setItemSelected(itemObj, true)
				table.insert(self._selectedValues, itemObj.value)
			else
				self:_setItemSelected(itemObj, false)
				for i, v in ipairs(self._selectedValues) do
					if v == itemObj.value then
						table.remove(self._selectedValues, i)
						break
					end
				end
			end
		else
			if not isSelected then
				if #self._selectedValues >= self.MaxItems then
					return
				end
				self:_setItemSelected(itemObj, true)
				table.insert(self._selectedValues, itemObj.value)
			else
				self:_setItemSelected(itemObj, false)
				for i, v in ipairs(self._selectedValues) do
					if v == itemObj.value then
						table.remove(self._selectedValues, i)
						break
					end
				end
			end
		end
		self:_updateSelectedText()
	end
	function self:_setItemSelected(itemObj, selected)
		itemObj.selected = selected
		if selected then
			itemObj.button.Name = "SelectedItem"
			if itemObj.button then Tween.Play(itemObj.button, "Smooth", { BackgroundTransparency = 0 }) end
			if itemObj.nameLabel then Tween.Play(itemObj.nameLabel, "Smooth", { TextTransparency = 0 }) end
			if itemObj.backImage then Tween.Play(itemObj.backImage, "Smooth", { ImageTransparency = 0.5 }) end
			if itemObj.icon then
				itemObj.icon.ImageColor3 = (theme and theme.ActiveTabIconColor) or itemObj.icon.ImageColor3
				Tween.Play(itemObj.icon, "Smooth", { ImageTransparency = 0 })
			end
			if itemObj.stroke then Tween.Play(itemObj.stroke, "Smooth", { Transparency = 0.95 }) end
			if itemObj.shadow then Tween.Play(itemObj.shadow, "Smooth", { Transparency = 0.5 }) end
			if itemObj.gradient then Tween.StartSpin(itemObj.gradient, { Rotation = 360 }, "SpinIdle") end
		else
			itemObj.button.Name = "DeselectedItem"
			if itemObj.button then Tween.Play(itemObj.button, "Smooth", { BackgroundTransparency = 1 }) end
			if itemObj.nameLabel then Tween.Play(itemObj.nameLabel, "Smooth", { TextTransparency = 0.6 }) end
			if itemObj.backImage then Tween.Play(itemObj.backImage, "Smooth", { ImageTransparency = 1 }) end
			if itemObj.icon then
				itemObj.icon.ImageColor3 = (theme and theme.InactiveTabIconColor) or itemObj.icon.ImageColor3
				Tween.Play(itemObj.icon, "Smooth", { ImageTransparency = 0.9 })
			end
			if itemObj.stroke then Tween.Play(itemObj.stroke, "Smooth", { Transparency = 0.95 }) end
			if itemObj.shadow then Tween.Play(itemObj.shadow, "Smooth", { Transparency = 1 }) end
			if itemObj.gradient then Tween.StopSpin(itemObj.gradient) end
		end
	end
	function self:SetSelection(values)
		for _, obj in ipairs(self._itemObjects) do
			if obj.selected then
				self:_setItemSelected(obj, false)
			end
		end
		self._selectedValues = {}
		for _, value in ipairs(values) do
			for _, obj in ipairs(self._itemObjects) do
				if obj.value == value then
					self:_setItemSelected(obj, true)
					table.insert(self._selectedValues, value)
					break
				end
			end
		end
		self:_updateSelectedText()
	end
	function self:ClearSelection()
		for _, obj in ipairs(self._itemObjects) do
			if obj.selected then
				self:_setItemSelected(obj, false)
			end
		end
		self._selectedValues = {}
		self:_updateSelectedText()
	end
	function self:SelectAll()
		if self.MaxItems ~= math.huge then
			local limit = self.MaxItems
			local current = #self._selectedValues
			local remaining = limit - current
			if remaining <= 0 then return end
			local count = 0
			for _, obj in ipairs(self._itemObjects) do
				if not obj.selected and count < remaining then
					self:_setItemSelected(obj, true)
					table.insert(self._selectedValues, obj.value)
					count = count + 1
				end
			end
		else
			for _, obj in ipairs(self._itemObjects) do
				if not obj.selected then
					self:_setItemSelected(obj, true)
					table.insert(self._selectedValues, obj.value)
				end
			end
		end
		self:_updateSelectedText()
	end
	function self:_filterItems(query)
		local lower = string.lower(query or "")
		local accent = (self._theme and self._theme.AccentColor) or Color3.fromRGB(96, 165, 250)
		-- Plain-text search (find with plain=true) so query text is never treated
		-- as a Lua pattern, and so it matches faster than a pattern search.
		for _, obj in ipairs(self._itemObjects) do
			local matched = (lower == "") or (string.find(string.lower(obj.name), lower, 1, true) ~= nil)
			obj.button.Visible = matched
			-- Highlight the matched substring in the row label with the accent
			-- color (RichText). Restore the plain name when there is no query.
			if obj.nameLabel then
				local hl = matched and lower ~= "" and SearchFilter.Highlight(obj.name, lower, accent) or nil
				if hl then
					obj.nameLabel.RichText = true
					obj.nameLabel.Text = hl
				else
					obj.nameLabel.Text = obj.name
				end
			end
		end
	end
	function self:_updateSelectedText()
		local names = {}
		for _, obj in ipairs(self._itemObjects) do
			if obj.selected then
				table.insert(names, obj.name)
			end
		end
		if #names > 0 then
			self.SelectedText.Text = string.format("{ %s }", table.concat(names, ", "))
		else
			self.SelectedText.Text = "None selected"
		end
	end
	function self:_Confirm()
		if self._resolved then return end
		self._resolved = true
		Sound.Play("Click")
		local selected = {}
		for _, obj in ipairs(self._itemObjects) do
			if obj.selected then
				table.insert(selected, { name = obj.name, value = obj.value })
			end
		end
		self:Close()
		self.OnConfirm(selected)
	end
	function self:_Cancel()
		if self._resolved then return end
		self._resolved = true
		Sound.Play("Click")
		self:Close()
		self.OnCancel()
	end
	-- ============================================================
	-- Build items from current Items table
	-- ============================================================
	function self:_buildItems()
		-- Clear old
		for _, obj in ipairs(self._itemObjects) do
			obj.button:Destroy()
		end
		self._itemObjects = {}
		self._selectedValues = {}
		for _, itemData in ipairs(self.Items) do
			local name = itemData.name or "Item"
			local icon = itemData.icon or Icons["circle"] or "rbxassetid://130359823580534"
			local value = itemData.value or name
			local button = Instance.new("TextButton")
			button.Name = "DeselectedItem"
			button.BorderSizePixel = 0
			button.TextTransparency = 1
			button.AutoButtonColor = false
			button.BackgroundColor3 = (theme and theme.AccentColor) or Color3.fromRGB(96, 165, 250)
			button.BackgroundTransparency = 1
			button.Size = UDim2.new(1, 0, 0, 40)
			button.Parent = self.List
			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 6)
			btnCorner.Parent = button
			local backImage = Instance.new("ImageLabel")
			backImage.Name = "BackImage"
			backImage.BorderSizePixel = 0
			backImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			backImage.ImageTransparency = 1
			backImage.AnchorPoint = Vector2.new(0.5, 0.5)
			local theme = Settings.Theme
			local imageId = (theme and theme.Wallpaper) or FallbackImage
			backImage.Image = imageId
			backImage:SetAttribute("IsThemeSheen", true)
			backImage.Size = UDim2.new(1, 0, 1, 0)
			backImage.BackgroundTransparency = 1
			backImage.Position = UDim2.new(0.5, 0, 0.5, 0)
			backImage.Parent = button
			-- Set visibility based on theme's WallpaperEnabled
			backImage.Visible = not (theme and theme.WallpaperEnabled == false)
			local backCorner = Instance.new("UICorner")
			backCorner.CornerRadius = UDim.new(0, 6)
			backCorner.Parent = backImage
			local gradient = Instance.new("UIGradient")
			gradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0.000, 0.72131),
				NumberSequenceKeypoint.new(0.110, 0.68306),
				NumberSequenceKeypoint.new(0.240, 0.63388),
				NumberSequenceKeypoint.new(0.349, 0.57923),
				NumberSequenceKeypoint.new(0.461, 0.48087),
				NumberSequenceKeypoint.new(0.583, 0.37158),
				NumberSequenceKeypoint.new(0.676, 0.2459),
				NumberSequenceKeypoint.new(0.770, 0.0929),
				NumberSequenceKeypoint.new(0.867, 0),
				NumberSequenceKeypoint.new(1.000, 0)
			}
			gradient.Parent = backImage
			local itemImage = Instance.new("ImageLabel")
			itemImage.Name = "ItemImage"
			itemImage.ImageTransparency = 0.9
			itemImage.AnchorPoint = Vector2.new(0.5, 0.5)
			itemImage.Image = icon
			-- Item icons use the same theme keys as sidebar tab icons (selected ->
			-- ActiveTabIconColor, deselected -> InactiveTabIconColor).
			itemImage.ImageColor3 = (theme and theme.InactiveTabIconColor) or Color3.fromRGB(255, 255, 255)
			itemImage.Size = UDim2.new(0, 24, 0, 24)
			itemImage.BackgroundTransparency = 1
			itemImage.Position = UDim2.new(0, 20, 0.5, 0)
			itemImage.Parent = button
			local itemAspect = Instance.new("UIAspectRatioConstraint")
			itemAspect.DominantAxis = Enum.DominantAxis.Height
			itemAspect.Parent = itemImage
			local itemName = Instance.new("TextLabel")
			itemName.Name = "ItemName"
			itemName.TextWrapped = true
			itemName.BorderSizePixel = 0
			itemName.TextSize = 16
			itemName.TextXAlignment = Enum.TextXAlignment.Left
			itemName.TextTransparency = 0.6
			itemName.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
			itemName.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
			itemName.TextColor3 = (theme and theme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
			itemName.BackgroundTransparency = 1
			itemName.AnchorPoint = Vector2.new(0, 0.5)
			itemName.Size = UDim2.new(0.48591, 0, 0.71359, 0)
			itemName.BorderColor3 = Color3.fromRGB(0, 0, 0)
			itemName.Text = name
			itemName.Position = UDim2.new(0, 40, 0.5, 0)
			itemName.Parent = button
			local stroke = Instance.new("UIStroke")
			stroke.Transparency = 0.95
			stroke.Thickness = 0.7
			stroke.Color = (theme and theme.StrokeColor) or Color3.fromRGB(255, 255, 255)
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = button
			local itemShadow = Instance.new("UIShadow")
			itemShadow.Color = (theme and theme.ComponentShadowColor) or Color3.fromRGB(0, 0, 0)
			itemShadow.Transparency = 1
			itemShadow.BlurRadius = UDim.new(0, 20)
			itemShadow.Parent = button
			local obj = {
				button = button,
				nameLabel = itemName,
				backImage = backImage,
				gradient = gradient,
				icon = itemImage,
				stroke = stroke,
				shadow = itemShadow,
				value = value,
				name = name,
				selected = false,
			}
			table.insert(self._itemObjects, obj)
			-- Click
			button.MouseButton1Click:Connect(function()
				self:_toggleItem(obj)
			end)
			-- Hover: icon and shadow
			button.MouseEnter:Connect(function()
				if obj.selected then
					if obj.icon then Tween.Play(obj.icon, "HoverIn", { ImageTransparency = 0.2 }) end
					if obj.shadow then Tween.Play(obj.shadow, "HoverIn", { Transparency = 0.35 }) end
				else
					if obj.icon then Tween.Play(obj.icon, "HoverIn", { ImageTransparency = 0.7 }) end
				end
			end)
			button.MouseLeave:Connect(function()
				local iconTrans = obj.selected and 0.4 or 0.9
				if obj.icon then Tween.Play(obj.icon, "HoverOut", { ImageTransparency = iconTrans }) end
				if obj.shadow then Tween.Play(obj.shadow, "HoverOut", { Transparency = 1 }) end
			end)
		end
	end
	-- Build initial items
	self:_buildItems()
	if #default > 0 then
		self:SetSelection(default)
	end
	self:_updateSelectedText()
	-- ============================================================
	-- Event connections
	-- ============================================================
	confirmBtn.MouseButton1Click:Connect(function()
		self:_Confirm()
	end)
	cancelBtn.MouseButton1Click:Connect(function()
		self:_Cancel()
	end)
	selectAllBtn.MouseButton1Click:Connect(function()
		self:SelectAll()
	end)
	clearBtn.MouseButton1Click:Connect(function()
		self:ClearSelection()
	end)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		self:_filterItems(searchBox.Text)
	end)
	-- Confirm button hover shadow (like UINotification)
	confirmBtn.MouseEnter:Connect(function()
		Tween.Play(confirmShadow, "Smooth", {
			BlurRadius = UDim.new(0, 50),
			Transparency = 0
		})
	end)
	confirmBtn.MouseLeave:Connect(function()
		Tween.Play(confirmShadow, "Smooth", {
			BlurRadius = UDim.new(0, 20),
			Transparency = 1
		})
	end)
	-- Cancel button hover text (like UINotification)
	cancelBtn.MouseEnter:Connect(function()
		Tween.Play(cancelBtn, "Smooth", {
			TextTransparency = 0.2
		})
	end)
	cancelBtn.MouseLeave:Connect(function()
		Tween.Play(cancelBtn, "Smooth", {
			TextTransparency = 0.5
		})
	end)
	-- ============================================================
	-- Public API
	-- ============================================================
	function self:SetContent(Settings)
		if not self.Popup then return end
		Settings = Settings or {}
		local title = Settings.Title or "Select Items"
		-- Read the LIVE theme, not the construction-time `theme` upvalue: SetContent
		-- runs on every reopen and would otherwise overwrite the header color with
		-- a stale value after a theme switch.
		local liveTheme = ThemeManager.GetTheme(Settings.Theme or self._theme)
		local titleColor = Settings.TitleColor or (liveTheme and liveTheme.PopupTextColor) or Color3.fromRGB(255,255,255)
		local items = Settings.Items or {}
		local default = Settings.Default or {}
		local maxItems = Settings.MaxItemsChoosable or math.huge
		local oldItems = self.Items or {}
		self.MaxItems = maxItems
		self.Items = items
		self.OnConfirm = Settings.OnConfirm or function() end
		self.OnCancel = Settings.OnCancel or function() end
		self.Title = title
		-- Update header (color via TextColor3, no RichText tag needed)
		self.Header.Text = title
		self.Header.TextColor3 = titleColor or Color3.fromRGB(255, 255, 255)
		-- Update popup name
		self.Popup.Name = sanitizeName(title) .. "DropdownPopup"
		-- Only rebuild the rows when the item list actually changed. Rebuilding
		-- destroys and recreates every row (~10 instances + 3 connections each)
		-- and previously ran on EVERY open -- the main source of churn.
		if not itemsEqual(oldItems, items) then
			self:_buildItems()
		end
		self:SetSelection(default)
		self:_updateSelectedText()
		-- Reset resolved
		self._resolved = false
		-- SelectAll visibility
		if maxItems ~= math.huge then
			self.SelectAllBtn.Visible = false
		else
			self.SelectAllBtn.Visible = true
		end
	end
	function self:Open()
		if not self.Popup then return end
		-- Cancel any pending hide timer
		if self._hideTimer then
			task.cancel(self._hideTimer)
			self._hideTimer = nil
		end
		-- If already open, we still want to ensure it's visible (e.g., after being hidden)
		-- So we don't return early; we just make sure it's visible and reset state.
		self.IsOpen = true
		self._resolved = false
		-- Clear search and reset item visibility
		if self.SearchBox then self.SearchBox.Text = "" end
		for _, obj in ipairs(self._itemObjects) do
			obj.button.Visible = true
		end
		-- Ensure the popup is visible immediately
		self.Popup.Visible = true
		-- Reset item visuals
		for _, obj in ipairs(self._itemObjects) do
			if obj.selected then
				if obj.button then obj.button.BackgroundTransparency = 0 end
				if obj.nameLabel then obj.nameLabel.TextTransparency = 0.2 end
				if obj.backImage then obj.backImage.ImageTransparency = 0.5 end
				if obj.icon then obj.icon.ImageTransparency = 0.4 end
				if obj.stroke then obj.stroke.Transparency = 0.95 end
				if obj.shadow then obj.shadow.Transparency = 0.5 end
				if obj.gradient then Tween.StartSpin(obj.gradient, { Rotation = 360 }, "SpinIdle") end
			else
				if obj.button then obj.button.BackgroundTransparency = 1 end
				if obj.nameLabel then obj.nameLabel.TextTransparency = 0.6 end
				if obj.backImage then obj.backImage.ImageTransparency = 1 end
				if obj.icon then obj.icon.ImageTransparency = 0.9 end
				if obj.stroke then obj.stroke.Transparency = 0.95 end
				if obj.shadow then obj.shadow.Transparency = 1 end
				if obj.gradient then Tween.StopSpin(obj.gradient) end
			end
		end
		-- Reset UI elements to transparent
		self.Popup.BackgroundTransparency = 1
		self.Shadow.Transparency = 1
		if self.ConfirmShadow then self.ConfirmShadow.Transparency = 1 end
		if self.CancelShadow then self.CancelShadow.Transparency = 1 end
		if self.SelectAllShadow then self.SelectAllShadow.Transparency = 1 end
		if self.ClearShadow then self.ClearShadow.Transparency = 1 end
		self.Header.TextTransparency = 1
		self.SearchBox.TextTransparency = 1
		self.SelectedText.TextTransparency = 1
		self.ConfirmBtn.TextTransparency = 1
		self.ConfirmBtn.BackgroundTransparency = 1
		self.CancelBtn.TextTransparency = 1
		self.CancelBtn.BackgroundTransparency = 1
		self.SelectAllBtn.TextTransparency = 1
		self.SelectAllBtn.BackgroundTransparency = 1
		self.ClearBtn.TextTransparency = 1
		self.ClearBtn.BackgroundTransparency = 1
		-- Reset icons and divider to hidden
		if self.SearchIcon then self.SearchIcon.ImageTransparency = 1 end
		if self.SelectAllIcon then self.SelectAllIcon.ImageTransparency = 1 end
		if self.ClearBtnIcon then self.ClearBtnIcon.ImageTransparency = 1 end
		if self.Divider then self.Divider.BackgroundTransparency = 1 end
		self.Popup.Visible = true
		-- Fade in
		if self.Popup then Tween.Play(self.Popup, "Smooth", { BackgroundTransparency = 0.07 }) end
		if self.Shadow then Tween.Play(self.Shadow, "Smooth", { Transparency = 0.5 }) end
		if self.Header then Tween.Play(self.Header, "Smooth", { TextTransparency = 0.4 }) end
		if self.SearchBox then Tween.Play(self.SearchBox, "Smooth", { TextTransparency = 0.4 }) end
		if self.SelectedText then Tween.Play(self.SelectedText, "Smooth", { TextTransparency = 0.45 }) end
		if self.ConfirmBtn then Tween.Play(self.ConfirmBtn, "Smooth", { TextTransparency = 0.2, BackgroundTransparency = 0 }) end
		if self.CancelBtn then Tween.Play(self.CancelBtn, "Smooth", { TextTransparency = 0.5, BackgroundTransparency = 0.5 }) end
		if self.SelectAllBtn then Tween.Play(self.SelectAllBtn, "Smooth", { TextTransparency = 1, BackgroundTransparency = 0 }) end
		if self.ClearBtn then Tween.Play(self.ClearBtn, "Smooth", { TextTransparency = 1, BackgroundTransparency = 0 }) end
		if self.SelectAllShadow then Tween.Play(self.SelectAllShadow, "Smooth", { Transparency = 0.5 }) end
		if self.ClearShadow then Tween.Play(self.ClearShadow, "Smooth", { Transparency = 0.5 }) end
		-- Fade in icons and divider
		if self.SearchIcon then Tween.Play(self.SearchIcon, "Smooth", { ImageTransparency = 0.7 }) end
		if self.SelectAllIcon then Tween.Play(self.SelectAllIcon, "Smooth", { ImageTransparency = 0.2 }) end
		if self.ClearBtnIcon then Tween.Play(self.ClearBtnIcon, "Smooth", { ImageTransparency = 0.2 }) end
		if self.Divider then Tween.Play(self.Divider, "Smooth", { BackgroundTransparency = 0.9 }) end
		-- Show scrollbar initially hidden, will appear on scroll
		if self.List then
			Tween.Play(self.List, "Fast", { ScrollBarImageTransparency = 1 })
			self.List.ScrollBarImageTransparency = 1
			-- Setup scroll detection if not already connected
			if not self._scrollConnection then
				self._scrollConnection = self.List:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
					self:_showScrollbar()
				end)
			end
		end
		-- Click-outside detection
		local UserInputService = game:GetService("UserInputService")
		local function onInputBegan(input, processed)
			if processed then return end
			if not self.Popup then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local pos = input.Position
				local popupPos = self.Popup.AbsolutePosition
				local popupSize = self.Popup.AbsoluteSize
				local inside = pos.X >= popupPos.X and pos.X <= popupPos.X + popupSize.X
					and pos.Y >= popupPos.Y and pos.Y <= popupPos.Y + popupSize.Y
				if not inside then
					self:_Confirm()
				end
			end
		end
		-- Disconnect any previous outside-click listener before making a new one,
		-- otherwise reopening while already open leaks the old connection.
		if self._inputConnection then
			self._inputConnection:Disconnect()
		end
		self._inputConnection = UserInputService.InputBegan:Connect(onInputBegan)
	end
	function self:Close()
		if not self.Popup then return end
		if not self.IsOpen then return end
		self.IsOpen = false
		-- Disconnect input
		if self._inputConnection then
			self._inputConnection:Disconnect()
			self._inputConnection = nil
		end
		-- Cancel scrollbar timer
		if self._scrollbarTimer then
			task.cancel(self._scrollbarTimer)
			self._scrollbarTimer = nil
		end
		-- Fade out items
		for _, obj in ipairs(self._itemObjects) do
			if obj.button then Tween.Play(obj.button, "Smooth", { BackgroundTransparency = 1 }) end
			if obj.nameLabel then Tween.Play(obj.nameLabel, "Smooth", { TextTransparency = 1 }) end
			if obj.backImage then Tween.Play(obj.backImage, "Smooth", { ImageTransparency = 1 }) end
			if obj.icon then Tween.Play(obj.icon, "Smooth", { ImageTransparency = 1 }) end
			if obj.stroke then Tween.Play(obj.stroke, "Smooth", { Transparency = 1 }) end
			if obj.shadow then Tween.Play(obj.shadow, "Smooth", { Transparency = 1 }) end
			if obj.gradient then Tween.StopSpin(obj.gradient) end
		end
		-- Fade out UI
		if self.Header then Tween.Play(self.Header, "Smooth", { TextTransparency = 1 }) end
		if self.SearchBox then Tween.Play(self.SearchBox, "Smooth", { TextTransparency = 1 }) end
		if self.SelectedText then Tween.Play(self.SelectedText, "Smooth", { TextTransparency = 1 }) end
		if self.ConfirmBtn then 
			Tween.Play(self.ConfirmBtn, "Smooth", { TextTransparency = 1 })
			Tween.Play(self.ConfirmBtn, "Smooth", { BackgroundTransparency = 1 })
		end
		if self.ConfirmShadow then Tween.Play(self.ConfirmShadow, "Smooth", { Transparency = 1, BlurRadius = UDim.new(0, 20) }) end
		if self.CancelBtn then
			Tween.Play(self.CancelBtn, "Smooth", { TextTransparency = 1 })
			Tween.Play(self.CancelBtn, "Smooth", { BackgroundTransparency = 1 })
		end
		if self.CancelShadow then Tween.Play(self.CancelShadow, "Smooth", { Transparency = 1 }) end
		if self.SelectAllBtn then
			Tween.Play(self.SelectAllBtn, "Smooth", { TextTransparency = 1 })
			Tween.Play(self.SelectAllBtn, "Smooth", { BackgroundTransparency = 1 })
		end
		if self.SelectAllShadow then Tween.Play(self.SelectAllShadow, "Smooth", { Transparency = 1 }) end
		if self.SelectAllIcon then Tween.Play(self.SelectAllIcon, "Smooth", { ImageTransparency = 1 }) end
		if self.ClearBtn then
			Tween.Play(self.ClearBtn, "Smooth", { TextTransparency = 1 })
			Tween.Play(self.ClearBtn, "Smooth", { BackgroundTransparency = 1 })
		end
		if self.ClearShadow then Tween.Play(self.ClearShadow, "Smooth", { Transparency = 1 }) end
		if self.ClearBtnIcon then Tween.Play(self.ClearBtnIcon, "Smooth", { ImageTransparency = 1 }) end
		if self.SearchIcon then Tween.Play(self.SearchIcon, "Smooth", { ImageTransparency = 1 }) end
		if self.Divider then Tween.Play(self.Divider, "Smooth", { BackgroundTransparency = 1 }) end
		if self.List then Tween.Play(self.List, "Smooth", { ScrollBarImageTransparency = 1 }) end
		if self.Shadow then Tween.Play(self.Shadow, "Smooth", { Transparency = 1 }) end
		if self.Popup then Tween.Play(self.Popup, "Smooth", { BackgroundTransparency = 1 }) end
		-- Hide after fade-out, but do NOT destroy (keep for reuse)
		if self._hideTimer then
			task.cancel(self._hideTimer)
			self._hideTimer = nil
		end
		self._hideTimer = task.delay(0.35, function()
			if not self.IsOpen and self.Popup then
				self.Popup.Visible = false
			end
			self._hideTimer = nil
		end)
	end
	function self:Hide()
		if not self.Popup then return end
		self.Popup.Visible = false
		self.IsOpen = false
		if self._inputConnection then
			self._inputConnection:Disconnect()
			self._inputConnection = nil
		end
		-- Cancel any pending hide timer
		if self._hideTimer then
			task.cancel(self._hideTimer)
			self._hideTimer = nil
		end
		-- Cancel any pending scrollbar timer
		if self._scrollbarTimer then
			task.cancel(self._scrollbarTimer)
			self._scrollbarTimer = nil
		end
	end
	function self:Destroy()
		-- Only call this when you truly want to remove the popup from memory
		if self._inputConnection then
			self._inputConnection:Disconnect()
			self._inputConnection = nil
		end
		if self._scrollConnection then
			self._scrollConnection:Disconnect()
			self._scrollConnection = nil
		end
		if self.Popup then
			self.Popup:Destroy()
			self.Popup = nil
		end
		-- Call cleanup callback to notify Window that this popup is gone
		if self._cleanupCallback then
			self._cleanupCallback()
			self._cleanupCallback = nil
		end
	end
	-- Scrollbar visibility: show on scroll, auto-hide after 1.5s
	function self:_showScrollbar()
		if self.List then
			Tween.Play(self.List, "Fast", { ScrollBarImageTransparency = 0.5 })
			-- Cancel any pending hide timer
			if self._scrollbarTimer then
				task.cancel(self._scrollbarTimer)
				self._scrollbarTimer = nil
			end
			-- Schedule hide after 1.5s of inactivity
			self._scrollbarTimer = task.delay(1.5, function()
				if self.List then
					Tween.Play(self.List, "Fast", { ScrollBarImageTransparency = 1 })
				end
				self._scrollbarTimer = nil
			end)
		end
	end
	return self
end
return DropdownPopUp