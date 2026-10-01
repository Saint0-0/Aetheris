--[[
	DropdownPopUp  ·  Aetheris UI Library

	Modal popup for dropdown selection: searchable item list, select-all,
	clear, and a max-selection cap. SetContent diffs the incoming item list
	and only rebuilds rows when it actually changed (rows are ~10 instances
	each). Created lazily by Components/Dropdown and cached per id by Window;

theme switches drop the cache so the next open rebuilds with current colors.
]]

local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local ThemeManager = require("../Themes/ThemeManager")
local SearchFilter = require("../Core/SearchFilter")
local Constants = require("../Constants")
local UserInputService = game:GetService("UserInputService")
local DropdownPopUp = {}
DropdownPopUp.__index = DropdownPopUp
local function sanitizeName(str)
	return str:gsub("[^%w_]", "_")
end
-- Compares two item lists by the fields that affect the rendered rows. Used to
-- skip rebuilding every row when the list is unchanged (the common case: a
-- dropdown re-sends the same items on each open).
local function itemsEqual(a, b)
	if #a ~= #b then
		return false
	end
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
	-- Click-outside is handled by a UserInputService.InputBegan connection that
	-- is created when the popup is shown and disconnected when it is hidden (see
	-- _connectOutsideClick / _disconnectOutsideClick below). No scrim instance is
	-- needed, so the popup is parented directly to its parent.
	local popup = Instance.new("Frame")
	popup.Name = sanitizeName(title) .. "DropdownPopup"
	popup.BorderSizePixel = 0
	popup.BackgroundColor3 = (theme and theme.PopupBackgroundColor)
	popup.BackgroundTransparency = (theme and theme.PopupBackgroundTransparency) or 1
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.Size = UDim2.fromScale(0.694, 1.02153)
	popup.Position = UDim2.fromScale(0.5, 0.5)
	popup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	popup.Visible = false
	popup.ZIndex = 11
	popup.Active = true
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
	header.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	header.TextColor3 = titleColor or (theme and theme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
	header.BackgroundTransparency = 1
	header.AnchorPoint = Vector2.new(0.5, 0.5)
	header.Size = UDim2.fromScale(0.26291, 0.03775)
	header.AutomaticSize = Enum.AutomaticSize.X
	header.Position = UDim2.new(0.5, 0, 0, 25)
	header.Parent = popup
	header.Text = title
	local interactions = Instance.new("Frame")
	interactions.Name = "Interactions"
	interactions.BorderSizePixel = 0
	interactions.BackgroundColor3 = (theme and theme.PopupShadowColor) or Color3.fromRGB(15, 15, 16)
	interactions.BackgroundTransparency = 0.8
	-- Anchored bottom-right (1, 0.5), pinned flush to the popup's bottom edge
	-- (center Y = 1 - height/2).
	interactions.AnchorPoint = Vector2.new(0.5, 1)
	interactions.Size = UDim2.new(1, 0, 0, 55)
	interactions.Position = UDim2.fromScale(0.5, 1)
	interactions.Parent = popup
	local interactionsCorner = Instance.new("UICorner")
	interactionsCorner.BottomLeftRadius = UDim.new(0, 6)
	interactionsCorner.BottomRightRadius = UDim.new(0, 6)
	interactionsCorner.TopLeftRadius = UDim.new(0, 0)
	interactionsCorner.TopRightRadius = UDim.new(0, 0)
	interactionsCorner.Parent = interactions
	local interactionsLayout = Instance.new("UIListLayout")
	interactionsLayout.FillDirection = Enum.FillDirection.Horizontal
	interactionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	interactionsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	interactionsLayout.Padding = UDim.new(0, 8)
	interactionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	interactionsLayout.Parent = interactions
	local interactionsPadding = Instance.new("UIPadding")
	interactionsPadding.PaddingLeft = UDim.new(0, 10)
	interactionsPadding.PaddingRight = UDim.new(0, 10)
	interactionsPadding.Parent = interactions
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
	confirmBtn.FontFace = Constants.Font(Enum.FontWeight.Bold)
	-- Side-by-side row: confirm on the LEFT half, cancel on the right.
	confirmBtn.AnchorPoint = Vector2.new(0, 0)
	confirmBtn.Size = UDim2.fromScale(0.47, 0.6)
	confirmBtn.Position = UDim2.fromScale(0, 0)
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
	cancelBtn.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	-- Right half, with a small gap from confirm.
	cancelBtn.AnchorPoint = Vector2.new(0, 0)
	cancelBtn.Size = UDim2.fromScale(0.47, 0.6)
	cancelBtn.Position = UDim2.fromScale(0.515, 0)
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
	list.Size = UDim2.fromScale(0.938, 0.43668)
	list.Position = UDim2.fromScale(0.5, 0.48976)
	list.ScrollBarThickness = 1
	list.ScrollBarImageColor3 = (theme and theme.TertiaryColor)
	list.Parent = popup
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 15)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list
	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 2)
	listPadding.PaddingRight = UDim.new(0, 3)
	listPadding.PaddingLeft = UDim.new(0, 14)
	listPadding.Parent = list
	local selectedText = Instance.new("TextLabel")
	selectedText.Name = "SelectedItemsText"
	selectedText.TextWrapped = true
	selectedText.BorderSizePixel = 0
	selectedText.TextSize = 13
	selectedText.TextXAlignment = Enum.TextXAlignment.Left
	selectedText.TextTransparency = 1
	selectedText.BackgroundTransparency = 1
	selectedText.FontFace = Constants.Font(Enum.FontWeight.Medium)
	selectedText.TextColor3 = (theme and theme.PopupTextColor)
	selectedText.RichText = true
	selectedText.AnchorPoint = Vector2.new(0.5, 0.5)
	selectedText.Size = UDim2.new(0.91, 0, 0, 26)
	selectedText.Position = UDim2.fromScale(0.5, 0.79)
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
	selectedDivider.Position = UDim2.new(0.5, 0, 1, 14)
	selectedDivider.Parent = selectedText
	local searchArea = Instance.new("Frame")
	searchArea.Name = "InteractionOrganizer"
	searchArea.BorderSizePixel = 0
	searchArea.BackgroundTransparency = 1
	searchArea.AnchorPoint = Vector2.new(0.5, 0.5)
	searchArea.Size = UDim2.fromScale(0.91879, 0.0779)
	searchArea.Position = UDim2.fromScale(0.5, 0.1868)
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
	searchBox.FontFace = Constants.Font(Enum.FontWeight.Medium)
	searchBox.AnchorPoint = Vector2.new(0.5, 0.5)
	searchBox.PlaceholderText = "Search..."
	searchBox.Size = UDim2.fromScale(0.38996, 1)
	searchBox.Position = UDim2.fromScale(0.26484, 0.5)
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
	searchDivider.Position = UDim2.new(0, 0, 1, 7)
	searchDivider.Parent = searchArea
	local searchIcon = Instance.new("ImageLabel")
	searchIcon.Name = "SearchImage"
	searchIcon.BorderSizePixel = 0
	searchIcon.BackgroundTransparency = 1
	searchIcon.ImageTransparency = 0.7
	searchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	searchIcon.Image = Icons.search
	searchIcon.ImageColor3 = (theme and theme.SecondaryColor) or Color3.fromRGB(200, 200, 200)
	searchIcon.Size = UDim2.fromOffset(17, 15)
	searchIcon.Position = UDim2.fromScale(0.01759, 0.5)
	searchIcon.Parent = searchArea
	local clearBtn = Instance.new("TextButton")
	clearBtn.Name = "ClearSelection"
	clearBtn.BorderSizePixel = 0
	clearBtn.TextTransparency = 1
	clearBtn.AutoButtonColor = false
	clearBtn.BackgroundColor3 = (theme and theme.TertiaryColor) or Color3.fromRGB(100, 116, 139)
	clearBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	clearBtn.Size = UDim2.fromScale(0.09462, 1)
	clearBtn.Position = UDim2.fromScale(0.96018, 0.5)
	clearBtn.Parent = searchArea
	local clearCorner = Instance.new("UICorner")
	clearCorner.CornerRadius = UDim.new(0, 6)
	clearCorner.Parent = clearBtn
	local clearIcon = Instance.new("ImageLabel")
	clearIcon.Name = "ButtonImage"
	clearIcon.ImageTransparency = 0.2
	clearIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	clearIcon.Position = UDim2.fromScale(0.5, 0.5)
	clearIcon.Image = Icons["eraser"]
	clearIcon.ImageColor3 = (theme and theme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
	clearIcon.Size = UDim2.fromOffset(17, 17)
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
	selectAllBtn.Size = UDim2.fromScale(0.09462, 1)
	selectAllBtn.Position = UDim2.fromScale(0.83689, 0.5)
	selectAllBtn.Parent = searchArea
	local selectAllCorner = Instance.new("UICorner")
	selectAllCorner.CornerRadius = UDim.new(0, 6)
	selectAllCorner.Parent = selectAllBtn
	local selectAllIcon = Instance.new("ImageLabel")
	selectAllIcon.Name = "ButtonImage"
	selectAllIcon.ImageTransparency = 0.2
	selectAllIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	selectAllIcon.Position = UDim2.fromScale(0.5, 0.5)
	selectAllIcon.Image = Icons["list-check"]
	selectAllIcon.ImageColor3 = (theme and theme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
	selectAllIcon.Size = UDim2.fromOffset(17, 17)
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
	self.Interactions = interactions
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
	self.ApplyTheme = function(me, theme)
		if not me.Popup then
			return
		end
		local t = ThemeManager.GetTheme(theme)
		me._theme = t
		me.Popup.BackgroundColor3 = t.PopupBackgroundColor or me.Popup.BackgroundColor3
		me.Shadow.Color = t.PopupShadowColor or me.Shadow.Color
		me.Header.TextColor3 = t.PopupTextColor or me.Header.TextColor3
		me.ConfirmBtn.TextColor3 = t.PopupTextColor or me.ConfirmBtn.TextColor3
		me.ConfirmBtn.BackgroundColor3 = t.PrimaryColor or me.ConfirmBtn.BackgroundColor3
		me.ConfirmShadow.Color = t.PrimaryColor or me.ConfirmShadow.Color
		me.CancelBtn.TextColor3 = t.PopupTextColor or me.CancelBtn.TextColor3
		me.CancelBtn.BackgroundColor3 = t.PopupNeutralColor or me.CancelBtn.BackgroundColor3
		me.CancelShadow.Color = t.PopupNeutralColor or me.CancelShadow.Color
		me.SelectedText.TextColor3 = t.PopupTextColor or me.SelectedText.TextColor3
		me.Divider.BackgroundColor3 = t.AccentColor or me.Divider.BackgroundColor3
		me.SearchBox.TextColor3 = t.PopupTextColor or me.SearchBox.TextColor3
		me.SearchDivider.BackgroundColor3 = t.TertiaryColor or me.SearchDivider.BackgroundColor3
		me.SearchIcon.ImageColor3 = t.SecondaryColor or me.SearchIcon.ImageColor3
		me.ClearBtn.BackgroundColor3 = t.TertiaryColor or me.ClearBtn.BackgroundColor3
		me.ClearShadow.Color = t.TertiaryColor or me.ClearShadow.Color
		me.ClearBtnIcon.ImageColor3 = t.PopupTextColor or me.ClearBtnIcon.ImageColor3
		me.SelectAllBtn.BackgroundColor3 = t.AccentColor or me.SelectAllBtn.BackgroundColor3
		me.SelectAllShadow.Color = t.AccentColor or me.SelectAllShadow.Color
		me.SelectAllIcon.ImageColor3 = t.PopupTextColor or me.SelectAllIcon.ImageColor3
		me.List.ScrollBarImageColor3 = t.TertiaryColor or me.List.ScrollBarImageColor3
		-- Re-tint every item row (bg accent, name + icon follow selection state).
		for _, obj in ipairs(me._itemObjects) do
			if obj.button then
				obj.button.BackgroundColor3 = t.AccentColor or obj.button.BackgroundColor3
			end
			if obj.nameLabel then
				obj.nameLabel.TextColor3 = t.PopupTextColor or obj.nameLabel.TextColor3
			end
			if obj.icon then
				obj.icon.ImageColor3 = obj.selected and (t.ActiveTabIconColor or obj.icon.ImageColor3)
					or (t.InactiveTabIconColor or obj.icon.ImageColor3)
			end
			if obj.stroke then
				obj.stroke.Color = t.StrokeColor or obj.stroke.Color
			end
			if obj.shadow then
				obj.shadow.Color = t.ComponentShadowColor or obj.shadow.Color
			end
			-- Item sheen follows the theme wallpaper (was previously handled by
			-- ThemeManager.updateThemeSheens; now owned here since rows are
			-- recolored in place rather than rebuilt).
			if obj.selectionStatus then
				obj.selectionStatus.BackgroundColor3 = t.SecondaryColor or obj.selectionStatus.BackgroundColor3
			end
		end
	end

	-- ============================================================
	-- Internal methods
	-- ============================================================
	self._flashDivider = function(_self)
		local divider = self.Divider
		if not divider then
			return
		end
		-- Token guards against overlapping flashes (e.g. Select-All selecting
		-- many items in one frame): only the newest flash owns the divider.
		self._dividerFlashToken = (self._dividerFlashToken or 0) + 1
		local token = self._dividerFlashToken
		-- Stage 1: Fast down to fully opaque.
		local down = Tween.Play(divider, "Fast", { BackgroundTransparency = 0 })
		if not (down and down.Tween) then
			return
		end
		down.Tween.Completed:Connect(function(state)
			if self._dividerFlashToken ~= token or state ~= Enum.PlaybackState.Completed then
				return
			end
			-- Stage 2: Fast back up to the resting 0.9 transparency.
			local up = Tween.Play(divider, "Fast", { BackgroundTransparency = 0.9 })
			if up and up.Tween then
				up.Tween.Completed:Connect(function(state2)
					if self._dividerFlashToken == token and state2 == Enum.PlaybackState.Completed then
						divider.BackgroundTransparency = 0.9
					end
				end)
			end
		end)
	end

	self._toggleItem = function(me, itemObj)
		local isSelected = itemObj.selected
		if me.MaxItems == 1 then
			if not isSelected then
				for _, obj in ipairs(me._itemObjects) do
					if obj.selected then
						me:_setItemSelected(obj, false)
					end
				end
				me._selectedValues = {}
				me:_setItemSelected(itemObj, true)
				table.insert(me._selectedValues, itemObj.value)
			else
				me:_setItemSelected(itemObj, false)
				for i, v in ipairs(me._selectedValues) do
					if v == itemObj.value then
						table.remove(me._selectedValues, i)
						break
					end
				end
			end
		else
			if not isSelected then
				if #me._selectedValues >= me.MaxItems then
					return
				end
				me:_setItemSelected(itemObj, true)
				table.insert(me._selectedValues, itemObj.value)
			else
				me:_setItemSelected(itemObj, false)
				for i, v in ipairs(me._selectedValues) do
					if v == itemObj.value then
						table.remove(me._selectedValues, i)
						break
					end
				end
			end
		end
		me:_updateSelectedText()
	end
	self._setItemSelected = function(me, itemObj, selected)
		itemObj.selected = selected
		if selected then
			me:_flashDivider()
			itemObj.button.Name = "SelectedItem"
			if itemObj.button then
				Tween.Play(itemObj.button, "Fast", { BackgroundTransparency = 0.5 })
			end
			if itemObj.nameLabel then
				Tween.Play(itemObj.nameLabel, "Fast", { TextTransparency = 0 })
			end
			if itemObj.icon then
				itemObj.icon.ImageColor3 = (theme and theme.ActiveTabIconColor) or itemObj.icon.ImageColor3
				Tween.Play(itemObj.icon, "Fast", { ImageTransparency = 0 })
			end
			if itemObj.stroke then
				Tween.Play(itemObj.stroke, "Fast", { Transparency = 1 })
			end
			if itemObj.shadow then
				Tween.Play(itemObj.shadow, "Fast", { Transparency = 0.5 })
			end
			-- Show the selection bar (same OnOff animation as sidebar tabs).
			if itemObj.selectionStatus then
				Tween.Play(
					itemObj.selectionStatus,
					"Fast",
					{ BackgroundTransparency = 0, Size = UDim2.new(0, 2, 0.7, 0) }
				)
			end
		else
			itemObj.button.Name = "DeselectedItem"
			if itemObj.button then
				Tween.Play(itemObj.button, "Fast", { BackgroundTransparency = 1 })
			end
			if itemObj.nameLabel then
				Tween.Play(itemObj.nameLabel, "Fast", { TextTransparency = 0.6 })
			end
			if itemObj.icon then
				itemObj.icon.ImageColor3 = (theme and theme.InactiveTabIconColor) or itemObj.icon.ImageColor3
				Tween.Play(itemObj.icon, "Fast", { ImageTransparency = 0.9 })
			end
			if itemObj.stroke then
				Tween.Play(itemObj.stroke, "Fast", { Transparency = 0.95 })
			end
			if itemObj.shadow then
				Tween.Play(itemObj.shadow, "Fast", { Transparency = 1 })
			end
			-- Collapse the selection bar.
			if itemObj.selectionStatus then
				Tween.Play(
					itemObj.selectionStatus,
					"Fast",
					{ BackgroundTransparency = 1, Size = UDim2.fromOffset(2, 0) }
				)
			end
		end
	end
	self.SetSelection = function(me, values)
		for _, obj in ipairs(me._itemObjects) do
			if obj.selected then
				me:_setItemSelected(obj, false)
			end
		end
		me._selectedValues = {}
		for _, value in ipairs(values) do
			for _, obj in ipairs(me._itemObjects) do
				if obj.value == value then
					me:_setItemSelected(obj, true)
					table.insert(me._selectedValues, value)
					break
				end
			end
		end
		me:_updateSelectedText()
	end
	self.ClearSelection = function(me)
		for _, obj in ipairs(me._itemObjects) do
			if obj.selected then
				me:_setItemSelected(obj, false)
			end
		end
		me._selectedValues = {}
		me:_updateSelectedText()
	end
	self.SelectAll = function(me)
		if me.MaxItems ~= math.huge then
			local limit = me.MaxItems
			local current = #me._selectedValues
			local remaining = limit - current
			if remaining <= 0 then
				return
			end
			local count = 0
			for _, obj in ipairs(me._itemObjects) do
				if not obj.selected and count < remaining then
					me:_setItemSelected(obj, true)
					table.insert(me._selectedValues, obj.value)
					count = count + 1
				end
			end
		else
			for _, obj in ipairs(me._itemObjects) do
				if not obj.selected then
					me:_setItemSelected(obj, true)
					table.insert(me._selectedValues, obj.value)
				end
			end
		end
		me:_updateSelectedText()
	end
	self._filterItems = function(me, query)
		local lower = string.lower(query or "")
		local accent = (me._theme and me._theme.AccentColor) or Color3.fromRGB(96, 165, 250)
		-- Plain-text search (find with plain=true) so query text is never treated
		-- as a Lua pattern, and so it matches faster than a pattern search.
		for _, obj in ipairs(me._itemObjects) do
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
	self._updateSelectedText = function(me)
		local names = {}
		for _, obj in ipairs(me._itemObjects) do
			if obj.selected then
				table.insert(names, obj.name)
			end
		end
		if #names > 0 then
			me.SelectedText.Text = string.format("{ %s }", table.concat(names, ", "))
		else
			me.SelectedText.Text = "None selected"
		end
	end
	self._Confirm = function(me)
		if me._resolved then
			return
		end
		me._resolved = true
		local selected = {}
		for _, obj in ipairs(me._itemObjects) do
			if obj.selected then
				table.insert(selected, { name = obj.name, value = obj.value })
			end
		end
		me:Close()
		me.OnConfirm(selected)
	end
	self._Cancel = function(me)
		if me._resolved then
			return
		end
		me._resolved = true
		me:Close()
		me.OnCancel()
	end
	-- ============================================================
	-- Build items from current Items table
	-- ============================================================
	self._buildItems = function(_self)
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
			local theme = Settings.Theme
			local button = Instance.new("TextButton")
			button.Name = "DeselectedItem"
			button.BorderSizePixel = 0
			button.TextTransparency = 1
			button.AutoButtonColor = false
			-- Item background: theme-driven (AccentColor), matching ApplyTheme so a
			-- live theme switch and a fresh build agree. Starts fully transparent
			-- (deselected); selected items get a very subtle fill (transparency
			-- 0.5) set in _setItemSelected.
			button.BackgroundColor3 = (theme and theme.AccentColor) or Color3.fromRGB(255, 255, 255)
			button.BackgroundTransparency = 1
			button.Size = UDim2.new(1, 0, 0, 40)
			button.Parent = self.List
			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 6)
			btnCorner.Parent = button
			-- Selection indicator: a thin left-edge bar, animated exactly like the
			-- sidebar tab SelectionStatus (OnOff tween). Color is a theme option
			-- (SecondaryColor), matching the other selection statuses in the UI.
			local selectionStatus = Instance.new("Frame")
			selectionStatus.Name = "SelectionStatus"
			selectionStatus.BorderSizePixel = 0
			selectionStatus.BackgroundColor3 = (theme and theme.SecondaryColor) or Color3.fromRGB(255, 255, 255)
			selectionStatus.BackgroundTransparency = 1 -- hidden until selected
			selectionStatus.AnchorPoint = Vector2.new(0, 0.5)
			selectionStatus.Size = UDim2.fromOffset(2, 0) -- start collapsed
			selectionStatus.Position = UDim2.new(0, -8, 0.5, 0)
			selectionStatus.BorderColor3 = Color3.fromRGB(0, 0, 0)
			selectionStatus.Parent = button
			local itemImage = Instance.new("ImageLabel")
			itemImage.Name = "ItemImage"
			itemImage.ImageTransparency = 0.9
			itemImage.AnchorPoint = Vector2.new(0.5, 0.5)
			itemImage.Image = icon
			-- Item icons use the same theme keys as sidebar tab icons (selected ->
			-- ActiveTabIconColor, deselected -> InactiveTabIconColor).
			itemImage.ImageColor3 = (theme and theme.InactiveTabIconColor) or Color3.fromRGB(255, 255, 255)
			itemImage.Size = UDim2.fromOffset(18, 18)
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
			itemName.TextSize = 14
			itemName.TextXAlignment = Enum.TextXAlignment.Left
			itemName.TextTransparency = 0.6
			itemName.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
			itemName.FontFace = Constants.Font(Enum.FontWeight.Medium)
			itemName.TextColor3 = (theme and theme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
			itemName.BackgroundTransparency = 1
			itemName.AnchorPoint = Vector2.new(0, 0.5)
			itemName.Size = UDim2.fromScale(0.48591, 0.71359)
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
				selectionStatus = selectionStatus,
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
					if obj.icon then
						Tween.Play(obj.icon, "HoverIn", { ImageTransparency = 0.2 })
					end
					if obj.shadow then
						Tween.Play(obj.shadow, "HoverIn", { Transparency = 0.35 })
					end
				else
					if obj.icon then
						Tween.Play(obj.icon, "HoverIn", { ImageTransparency = 0.7 })
					end
				end
			end)
			button.MouseLeave:Connect(function()
				local iconTrans = obj.selected and 0.4 or 0.9
				if obj.icon then
					Tween.Play(obj.icon, "HoverOut", { ImageTransparency = iconTrans })
				end
				if obj.shadow then
					Tween.Play(obj.shadow, "HoverOut", { Transparency = 1 })
				end
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
		Tween.Play(confirmShadow, "Fast", {
			BlurRadius = UDim.new(0, 50),
			Transparency = 0,
		})
	end)
	confirmBtn.MouseLeave:Connect(function()
		Tween.Play(confirmShadow, "Fast", {
			BlurRadius = UDim.new(0, 20),
			Transparency = 1,
		})
	end)
	-- Cancel button hover text (like UINotification)
	cancelBtn.MouseEnter:Connect(function()
		Tween.Play(cancelBtn, "Fast", {
			TextTransparency = 0.2,
		})
	end)
	cancelBtn.MouseLeave:Connect(function()
		Tween.Play(cancelBtn, "Fast", {
			TextTransparency = 0.5,
		})
	end)
	-- ============================================================
	-- Public API
	-- ============================================================
	self.SetContent = function(_self, Settings)
		if not self.Popup then
			return
		end
		Settings = Settings or {}
		local title = Settings.Title or "Select Items"
		-- Read the LIVE theme, not the construction-time `theme` upvalue: SetContent
		-- runs on every reopen and would otherwise overwrite the header color with
		-- a stale value after a theme switch.
		local liveTheme = ThemeManager.GetTheme(Settings.Theme or self._theme)
		local titleColor = Settings.TitleColor
			or (liveTheme and liveTheme.PopupTextColor)
			or Color3.fromRGB(255, 255, 255)
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
	self.Open = function(_self)
		if not self.Popup then
			return
		end
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
		if self.SearchBox then
			self.SearchBox.Text = ""
		end
		for _, obj in ipairs(self._itemObjects) do
			obj.button.Visible = true
		end
		-- Ensure the popup is visible immediately
		self.Popup.Visible = true
		-- Arm the click-outside listener for as long as the popup is open.
		self:_connectOutsideClick()
		-- Reset item visuals
		for _, obj in ipairs(self._itemObjects) do
			if obj.selected then
				if obj.button then
					obj.button.BackgroundTransparency = 0.5
				end
				if obj.nameLabel then
					obj.nameLabel.TextTransparency = 0.2
				end
				if obj.icon then
					obj.icon.ImageTransparency = 0.4
				end
				if obj.stroke then
					obj.stroke.Transparency = 0.95
				end
				if obj.shadow then
					obj.shadow.Transparency = 0.5
				end
				if obj.selectionStatus then
					obj.selectionStatus.BackgroundTransparency = 0
					obj.selectionStatus.Size = UDim2.new(0, 2, 0.7, 0)
				end
			else
				if obj.button then
					obj.button.BackgroundTransparency = 1
				end
				if obj.nameLabel then
					obj.nameLabel.TextTransparency = 0.6
				end
				if obj.icon then
					obj.icon.ImageTransparency = 0.9
				end
				if obj.stroke then
					obj.stroke.Transparency = 0.95
				end
				if obj.shadow then
					obj.shadow.Transparency = 1
				end
				if obj.selectionStatus then
					obj.selectionStatus.BackgroundTransparency = 1
					obj.selectionStatus.Size = UDim2.fromOffset(2, 0)
				end
			end
		end
		-- Reset UI elements to transparent
		self.Popup.BackgroundTransparency = 1
		self.Interactions.BackgroundTransparency = 1
		self.Shadow.Transparency = 1
		if self.ConfirmShadow then
			self.ConfirmShadow.Transparency = 1
		end
		if self.CancelShadow then
			self.CancelShadow.Transparency = 1
		end
		if self.SelectAllShadow then
			self.SelectAllShadow.Transparency = 1
		end
		if self.ClearShadow then
			self.ClearShadow.Transparency = 1
		end
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
		if self.SearchIcon then
			self.SearchIcon.ImageTransparency = 1
		end
		if self.SelectAllIcon then
			self.SelectAllIcon.ImageTransparency = 1
		end
		if self.ClearBtnIcon then
			self.ClearBtnIcon.ImageTransparency = 1
		end
		if self.Divider then
			self.Divider.BackgroundTransparency = 1
		end
		self.Popup.Visible = true
		-- Fade in
		if self.Popup then
			Tween.Play(self.Popup, "Fast", { BackgroundTransparency = 0.07 })
		end
		if self.Shadow then
			Tween.Play(self.Shadow, "Fast", { Transparency = 0.5 })
		end
		if self.Header then
			Tween.Play(self.Header, "Fast", { TextTransparency = 0.4 })
		end
		if self.SearchBox then
			Tween.Play(self.SearchBox, "Fast", { TextTransparency = 0.4 })
		end
		if self.SelectedText then
			Tween.Play(self.SelectedText, "Fast", { TextTransparency = 0.45 })
		end
		if self.ConfirmBtn then
			Tween.Play(self.ConfirmBtn, "Fast", { TextTransparency = 0.2, BackgroundTransparency = 0 })
		end
		if self.CancelBtn then
			Tween.Play(self.CancelBtn, "Fast", { TextTransparency = 0.5, BackgroundTransparency = 0.5 })
		end
		if self.Interactions then
			Tween.Play(self.Interactions, "Fast", { BackgroundTransparency = 0.8 })
		end
		if self.SelectAllBtn then
			Tween.Play(self.SelectAllBtn, "Fast", { TextTransparency = 1, BackgroundTransparency = 0 })
		end
		if self.ClearBtn then
			Tween.Play(self.ClearBtn, "Fast", { TextTransparency = 1, BackgroundTransparency = 0 })
		end
		if self.SelectAllShadow then
			Tween.Play(self.SelectAllShadow, "Fast", { Transparency = 0.5 })
		end
		if self.ClearShadow then
			Tween.Play(self.ClearShadow, "Fast", { Transparency = 0.5 })
		end
		-- Fade in icons and divider
		if self.SearchIcon then
			Tween.Play(self.SearchIcon, "Fast", { ImageTransparency = 0.7 })
		end
		if self.SelectAllIcon then
			Tween.Play(self.SelectAllIcon, "Fast", { ImageTransparency = 0.2 })
		end
		if self.ClearBtnIcon then
			Tween.Play(self.ClearBtnIcon, "Fast", { ImageTransparency = 0.2 })
		end
		if self.Divider then
			Tween.Play(self.Divider, "Fast", { BackgroundTransparency = 0.9 })
		end
		if self.SearchDivider then
			Tween.Play(self.SearchDivider, "Fast", { BackgroundTransparency = 0.9 })
		end
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
		-- Click-outside is handled by _connectOutsideClick() (called below on
		-- open) and torn down again on close, so there is nothing to do here.
	end
	self.Close = function(_self)
		if not self.Popup then
			return
		end
		if not self.IsOpen then
			return
		end
		self.IsOpen = false
		-- Disarm the click-outside listener immediately on close so a click
		-- during the fade-out cannot re-trigger it.
		self:_disconnectOutsideClick()
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
			if obj.button then
				Tween.Play(obj.button, "Fast", { BackgroundTransparency = 1 })
			end
			if obj.nameLabel then
				Tween.Play(obj.nameLabel, "Fast", { TextTransparency = 1 })
			end
			if obj.icon then
				Tween.Play(obj.icon, "Fast", { ImageTransparency = 1 })
			end
			if obj.stroke then
				Tween.Play(obj.stroke, "Fast", { Transparency = 1 })
			end
			if obj.shadow then
				Tween.Play(obj.shadow, "Fast", { Transparency = 1 })
			end
			if obj.selectionStatus then
				Tween.Play(obj.selectionStatus, "Fast", { BackgroundTransparency = 1 })
			end
		end
		-- Fade out UI
		if self.Header then
			Tween.Play(self.Header, "Fast", { TextTransparency = 1 })
		end
		if self.SearchBox then
			Tween.Play(self.SearchBox, "Fast", { TextTransparency = 1 })
		end
		if self.SelectedText then
			Tween.Play(self.SelectedText, "Fast", { TextTransparency = 1 })
		end
		if self.ConfirmBtn then
			Tween.Play(self.ConfirmBtn, "Fast", { TextTransparency = 1 })
			Tween.Play(self.ConfirmBtn, "Fast", { BackgroundTransparency = 1 })
		end
		if self.ConfirmShadow then
			Tween.Play(self.ConfirmShadow, "Fast", { Transparency = 1, BlurRadius = UDim.new(0, 20) })
		end
		if self.CancelBtn then
			Tween.Play(self.CancelBtn, "Fast", { TextTransparency = 1 })
			Tween.Play(self.CancelBtn, "Fast", { BackgroundTransparency = 1 })
		end
		if self.CancelShadow then
			Tween.Play(self.CancelShadow, "Fast", { Transparency = 1 })
		end
		if self.SelectAllBtn then
			Tween.Play(self.SelectAllBtn, "Fast", { TextTransparency = 1 })
			Tween.Play(self.SelectAllBtn, "Fast", { BackgroundTransparency = 1 })
		end
		if self.SelectAllShadow then
			Tween.Play(self.SelectAllShadow, "Fast", { Transparency = 1 })
		end
		if self.SelectAllIcon then
			Tween.Play(self.SelectAllIcon, "Fast", { ImageTransparency = 1 })
		end
		if self.ClearBtn then
			Tween.Play(self.ClearBtn, "Fast", { TextTransparency = 1 })
			Tween.Play(self.ClearBtn, "Fast", { BackgroundTransparency = 1 })
		end
		if self.ClearShadow then
			Tween.Play(self.ClearShadow, "Fast", { Transparency = 1 })
		end
		if self.ClearBtnIcon then
			Tween.Play(self.ClearBtnIcon, "Fast", { ImageTransparency = 1 })
		end
		if self.SearchIcon then
			Tween.Play(self.SearchIcon, "Fast", { ImageTransparency = 1 })
		end
		if self.Divider then
			Tween.Play(self.Divider, "Fast", { BackgroundTransparency = 1 })
		end
		if self.SearchDivider then
			Tween.Play(self.SearchDivider, "Fast", { BackgroundTransparency = 1 })
		end
		if self.List then
			Tween.Play(self.List, "Fast", { ScrollBarImageTransparency = 1 })
		end
		if self.Shadow then
			Tween.Play(self.Shadow, "Fast", { Transparency = 1 })
		end
		if self.Popup then
			Tween.Play(self.Popup, "Fast", { BackgroundTransparency = 1 })
		end
		if self.Interactions then
			Tween.Play(self.Interactions, "Fast", { BackgroundTransparency = 1 })
		end
		-- Hide after fade-out, but do NOT destroy (keep for reuse)
		if self._hideTimer then
			task.cancel(self._hideTimer)
			self._hideTimer = nil
		end
		self._hideTimer = task.delay(0.35, function()
			if not self.IsOpen then
				if self.Popup then
					self.Popup.Visible = false
				end
			end
			self._hideTimer = nil
		end)
	end
	-- Click-outside detection via UserInputService. The connection exists only
	-- while the popup is open: created in Open(), disconnected in
	-- Close()/Hide()/Destroy(). Replaces the old full-screen scrim button.
	self._connectOutsideClick = function(_self)
		if self._outsideConn then
			return
		end
		self._outsideConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			local inputType = input.UserInputType
			if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
				return
			end
			if not self.IsOpen or not self.Popup or not self.Popup.Visible then
				return
			end
			local p = input.Position
			-- Inside if the point is within the popup's rect OR lands on any of its
			-- descendants. The descendant check makes this robust when visually-
			-- belonging content (overlays, shadows, indicators) extends past the
			-- frame's own rect; a pure rect test would misread those as "outside".
			local pos = self.Popup.AbsolutePosition
			local size = self.Popup.AbsoluteSize
			local inside = p.X >= pos.X and p.X <= pos.X + size.X
				and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
			if not inside then
				local playerGui = self.Popup:FindFirstAncestorOfClass("PlayerGui")
				if playerGui then
					for _, obj in ipairs(playerGui:GetGuiObjectsAtPosition(p.X, p.Y)) do
						if obj == self.Popup or obj:IsDescendantOf(self.Popup) then
							inside = true
							break
						end
					end
				end
			end
			if not inside then
				self:_Confirm()
			end
		end)
	end
	self._disconnectOutsideClick = function(me)
		if me._outsideConn then
			me._outsideConn:Disconnect()
			me._outsideConn = nil
		end
	end
	self.Hide = function(me)
		if not me.Popup then
			return
		end
		me.Popup.Visible = false
		me.IsOpen = false
		me:_disconnectOutsideClick()
		if me._inputConnection then
			me._inputConnection:Disconnect()
			me._inputConnection = nil
		end
		-- Cancel any pending hide timer
		if me._hideTimer then
			task.cancel(me._hideTimer)
			me._hideTimer = nil
		end
		-- Cancel any pending scrollbar timer
		if me._scrollbarTimer then
			task.cancel(me._scrollbarTimer)
			me._scrollbarTimer = nil
		end
	end
	self.Destroy = function(me)
		-- Only call this when you truly want to remove the popup from memory
		if me._inputConnection then
			me._inputConnection:Disconnect()
			me._inputConnection = nil
		end
		if me._scrollConnection then
			me._scrollConnection:Disconnect()
			me._scrollConnection = nil
		end
		me:_disconnectOutsideClick()
		if me.Popup then
			me.Popup = nil
		end
		-- Call cleanup callback to notify Window that this popup is gone
		if me._cleanupCallback then
			me._cleanupCallback()
			me._cleanupCallback = nil
		end
	end
	-- Scrollbar visibility: show on scroll, auto-hide after 1.5s
	self._showScrollbar = function(_self)
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
