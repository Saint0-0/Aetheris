--[[
	Aetheris/Popups/DropdownPopUp.luau

	Searchable multi-select popup with select-all and clear. Rows rebuild only
	when the item list changes.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local SearchFilter = require("../Core/SearchFilter")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")
local UserInputService = game:GetService("UserInputService")
local DropdownPopUp = {}
DropdownPopUp.__index = DropdownPopUp
-- Compares two item lists by the fields that affect rendered rows, to skip rebuilds.
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
	-- Click-outside is a UserInputService connection armed while the popup is open.
	local popup = Instance.new("CanvasGroup")
	popup.Name = UUID.Generate("DropdownPopup")
	popup.BorderSizePixel = 0
	popup.GroupTransparency = 1
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
	header.Name = UUID.Static("Header")
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
	interactions.Name = UUID.Static("Interactions")
	interactions.BorderSizePixel = 0
	interactions.BackgroundColor3 = (theme and theme.PopupShadowColor) or Color3.fromRGB(15, 15, 16)
	interactions.BackgroundTransparency = 0.8
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
	confirmBtn.Name = UUID.Static("Confirm")
	confirmBtn.BorderSizePixel = 0
	confirmBtn.TextTransparency = 1
	confirmBtn.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.TextSize = 12
	confirmBtn.Text = "Confirm"
	confirmBtn.AutoButtonColor = false
	confirmBtn.TextColor3 = (theme and theme.PopupTextColor)
	confirmBtn.BackgroundColor3 = (theme and theme.PrimaryColor)
	confirmBtn.FontFace = Constants.Font(Enum.FontWeight.Bold)
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
	cancelBtn.Name = UUID.Static("Cancel")
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
	list.Name = UUID.Static("DropdownList")
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
	selectedText.Name = UUID.Static("SelectedItemsText")
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
	selectedDivider.Name = UUID.Static("ComponentDivider")
	selectedDivider.BorderSizePixel = 0
	selectedDivider.BackgroundColor3 = (theme and theme.AccentColor)
	selectedDivider.BackgroundTransparency = 0.9
	selectedDivider.AnchorPoint = Vector2.new(0.5, 0.5)
	selectedDivider.Size = UDim2.new(0.8, 0, 0, 2)
	selectedDivider.Position = UDim2.new(0.5, 0, 1, 14)
	selectedDivider.Parent = selectedText
	local searchArea = Instance.new("Frame")
	searchArea.Name = UUID.Static("InteractionOrganizer")
	searchArea.BorderSizePixel = 0
	searchArea.BackgroundTransparency = 1
	searchArea.AnchorPoint = Vector2.new(0.5, 0.5)
	searchArea.Size = UDim2.fromScale(0.91879, 0.0779)
	searchArea.Position = UDim2.fromScale(0.5, 0.1868)
	searchArea.Parent = popup
	local searchBox = Instance.new("TextBox")
	searchBox.Name = UUID.Static("SearchBox")
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
	-- Inset line centered under the whole search area, not the narrower box.
	local searchDivider = Instance.new("Frame")
	searchDivider.Name = UUID.Static("SearchDividerBottom")
	searchDivider.BorderSizePixel = 0
	searchDivider.BackgroundColor3 = (theme and theme.TertiaryColor) or Color3.fromRGB(160, 160, 160)
	searchDivider.BackgroundTransparency = 0.9
	searchDivider.AnchorPoint = Vector2.new(0, 0.5)
	searchDivider.Size = UDim2.new(0.6, 0, 0, 1)
	searchDivider.Position = UDim2.new(0, 0, 1, 7)
	searchDivider.Parent = searchArea
	local searchIcon = Instance.new("ImageLabel")
	searchIcon.Name = UUID.Static("SearchImage")
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
	clearBtn.Name = UUID.Static("ClearSelection")
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
	clearIcon.Name = UUID.Static("ButtonImage")
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
	selectAllBtn.Name = UUID.Static("SelectAll")
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
	selectAllIcon.Name = UUID.Static("ButtonImage")
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
	if maxItems ~= math.huge then
		selectAllBtn.Visible = false
	end

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

	-- The divider and search icon sharpen on focus, matching the sidebar search.
	searchBox.Focused:Connect(function()
		Tween.Play(searchDivider, "Fast", { BackgroundTransparency = 0.2 })
		Tween.Play(searchIcon, "Fast", { ImageTransparency = 0.2 })
	end)
	searchBox.FocusLost:Connect(function()
		Tween.Play(searchDivider, "Fast", { BackgroundTransparency = 0.9 })
		Tween.Play(searchIcon, "Fast", { ImageTransparency = 0.7 })
	end)

	-- Re-apply every theme color without rebuilding, so a cached/open dropdown recolors live.
	self.ApplyTheme = function(me, newTheme)
		if not me.Popup then
			return
		end
		local t = ThemeManager.GetTheme(newTheme)
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
			-- Item sheen follows the theme; rows recolor in place rather than rebuild.
			if obj.selectionStatus then
				obj.selectionStatus.BackgroundColor3 = t.SecondaryColor or obj.selectionStatus.BackgroundColor3
			end
		end
	end

	self._flashDivider = function(_self)
		local divider = self.Divider
		if not divider then
			return
		end
		-- Token guards overlapping flashes; only the newest flash owns the divider.
		self._dividerFlashToken = (self._dividerFlashToken or 0) + 1
		local token = self._dividerFlashToken
		local down = Tween.Play(divider, "Fast", { BackgroundTransparency = 0 })
		if not (down and down.Tween) then
			return
		end
		down.Tween.Completed:Connect(function(state)
			if self._dividerFlashToken ~= token or state ~= Enum.PlaybackState.Completed then
				return
			end
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
			itemObj.button.Name = UUID.Generate("DropdownItem")
			if itemObj.button then
				Tween.Play(itemObj.button, "Fast", { BackgroundTransparency = 0.5 })
			end
			if itemObj.nameLabel then
				Tween.Play(itemObj.nameLabel, "Fast", { TextTransparency = 0 })
			end
			if itemObj.icon then
				-- me._theme is updated live by ApplyTheme; the closure `theme` goes stale on a theme switch.
				local live = me._theme or theme
				itemObj.icon.ImageColor3 = (live and live.ActiveTabIconColor) or itemObj.icon.ImageColor3
				Tween.Play(itemObj.icon, "Fast", { ImageTransparency = 0 })
			end
			if itemObj.stroke then
				Tween.Play(itemObj.stroke, "Fast", { Transparency = 1 })
			end
			if itemObj.shadow then
				Tween.Play(itemObj.shadow, "Fast", { Transparency = 0.5 })
			end
			if itemObj.selectionStatus then
				Tween.Play(
					itemObj.selectionStatus,
					"Fast",
					{ BackgroundTransparency = 0, Size = UDim2.new(0, 2, 0.7, 0) }
				)
			end
		else
			itemObj.button.Name = UUID.Generate("DropdownItem")
			if itemObj.button then
				Tween.Play(itemObj.button, "Fast", { BackgroundTransparency = 1 })
			end
			if itemObj.nameLabel then
				Tween.Play(itemObj.nameLabel, "Fast", { TextTransparency = 0.6 })
			end
			if itemObj.icon then
				local live = me._theme or theme
				itemObj.icon.ImageColor3 = (live and live.InactiveTabIconColor) or itemObj.icon.ImageColor3
				Tween.Play(itemObj.icon, "Fast", { ImageTransparency = 0.9 })
			end
			if itemObj.stroke then
				Tween.Play(itemObj.stroke, "Fast", { Transparency = 0.95 })
			end
			if itemObj.shadow then
				Tween.Play(itemObj.shadow, "Fast", { Transparency = 1 })
			end
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
		-- Plain-text search (plain=true) so the query is never treated as a pattern.
		for _, obj in ipairs(me._itemObjects) do
			local matched = (lower == "") or (string.find(string.lower(obj.name), lower, 1, true) ~= nil)
			obj.button.Visible = matched
			-- Highlight the match with accent RichText; plain name when no query.
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
	self._buildItems = function(_self)
		for _, obj in ipairs(self._itemObjects) do
			obj.button:Destroy()
		end
		self._itemObjects = {}
		self._selectedValues = {}
		local liveTheme = self._theme or ActiveTheme.theme or theme
		for _, itemData in ipairs(self.Items) do
			local name = itemData.name or "Item"
			local icon = itemData.icon or Icons["circle"] or "rbxassetid://130359823580534"
			local value = itemData.value or name
			local button = Instance.new("TextButton")
			button.Name = UUID.Generate("DropdownSearch")
			button.BorderSizePixel = 0
			button.TextTransparency = 1
			button.AutoButtonColor = false
			-- Theme-driven background; starts transparent, selected items get a subtle fill in _setItemSelected.
			button.BackgroundColor3 = (liveTheme and liveTheme.AccentColor) or Color3.fromRGB(255, 255, 255)
			button.BackgroundTransparency = 1
			button.Size = UDim2.new(1, 0, 0, 40)
			button.Parent = self.List
			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 6)
			btnCorner.Parent = button
			-- Thin left-edge bar animated like the sidebar tab selection status.
			local selectionStatus = Instance.new("Frame")
			selectionStatus.Name = UUID.Static("SelectionStatus")
			selectionStatus.BorderSizePixel = 0
			selectionStatus.BackgroundColor3 = (liveTheme and liveTheme.SecondaryColor) or Color3.fromRGB(255, 255, 255)
			selectionStatus.BackgroundTransparency = 1
			selectionStatus.AnchorPoint = Vector2.new(0, 0.5)
			selectionStatus.Size = UDim2.fromOffset(2, 0)
			selectionStatus.Position = UDim2.new(0, -8, 0.5, 0)
			selectionStatus.BorderColor3 = Color3.fromRGB(0, 0, 0)
			selectionStatus.Parent = button
			local itemImage = Instance.new("ImageLabel")
			itemImage.Name = UUID.Static("ItemImage")
			itemImage.ImageTransparency = 0.9
			itemImage.AnchorPoint = Vector2.new(0.5, 0.5)
			itemImage.Image = icon
			-- Icons use the sidebar tab icon theme keys for selected/deselected.
			itemImage.ImageColor3 = (liveTheme and liveTheme.InactiveTabIconColor) or Color3.fromRGB(255, 255, 255)
			itemImage.Size = UDim2.fromOffset(18, 18)
			itemImage.BackgroundTransparency = 1
			itemImage.Position = UDim2.new(0, 20, 0.5, 0)
			itemImage.Parent = button
			local itemAspect = Instance.new("UIAspectRatioConstraint")
			itemAspect.DominantAxis = Enum.DominantAxis.Height
			itemAspect.Parent = itemImage
			local itemName = Instance.new("TextLabel")
			itemName.Name = UUID.Static("ItemName")
			itemName.TextWrapped = true
			itemName.BorderSizePixel = 0
			itemName.TextSize = 14
			itemName.TextXAlignment = Enum.TextXAlignment.Left
			itemName.TextTransparency = 0.6
			itemName.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
			itemName.FontFace = Constants.Font(Enum.FontWeight.Medium)
			itemName.TextColor3 = (liveTheme and liveTheme.PopupTextColor) or Color3.fromRGB(255, 255, 255)
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
			stroke.Color = (liveTheme and liveTheme.StrokeColor) or Color3.fromRGB(255, 255, 255)
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = button
			local itemShadow = Instance.new("UIShadow")
			itemShadow.Color = (liveTheme and liveTheme.ComponentShadowColor) or Color3.fromRGB(0, 0, 0)
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
			button.MouseButton1Click:Connect(function()
				self:_toggleItem(obj)
			end)
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
	self.SetContent = function(_self, contentSettings)
		if not self.Popup then
			return
		end
		contentSettings = contentSettings or {}
		local newTitle = contentSettings.Title or "Select Items"
		-- Read the LIVE theme; SetContent runs on every reopen, so a construction-time theme would be stale.
		local liveTheme = ThemeManager.GetTheme(contentSettings.Theme or self._theme)
		local newTitleColor = contentSettings.TitleColor
			or (liveTheme and liveTheme.PopupTextColor)
			or Color3.fromRGB(255, 255, 255)
		local newItems = contentSettings.Items or {}
		local newDefault = contentSettings.Default or {}
		local newMaxItems = contentSettings.MaxItemsChoosable or math.huge
		local oldItems = self.Items or {}
		self.MaxItems = newMaxItems
		self.Items = newItems
		self.OnConfirm = contentSettings.OnConfirm or function() end
		self.OnCancel = contentSettings.OnCancel or function() end
		self.Title = newTitle
		self.Header.Text = newTitle
		self.Header.TextColor3 = newTitleColor or Color3.fromRGB(255, 255, 255)
		-- Only rebuild the rows when the item list actually changed.
		if not itemsEqual(oldItems, newItems) then
			self:_buildItems()
		end
		self:SetSelection(newDefault)
		self:_updateSelectedText()
		self._resolved = false
		if newMaxItems ~= math.huge then
			self.SelectAllBtn.Visible = false
		else
			self.SelectAllBtn.Visible = true
		end
	end
	self.Open = function(_self)
		if not self.Popup then
			return
		end
		if self._hideTimer then
			task.cancel(self._hideTimer)
			self._hideTimer = nil
		end
		self.IsOpen = true
		self._resolved = false
		if self.SearchBox then
			self.SearchBox.Text = ""
		end
		for _, obj in ipairs(self._itemObjects) do
			obj.button.Visible = true
		end
		self.Popup.Visible = true
		self.Popup.GroupTransparency = 1
		self:_connectOutsideClick()
		-- Snap item visuals to their resting selection state before the fade-in.
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
		-- Snap every chrome element transparent so the fade-in owns all of it.
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
		if self.Popup then
			Tween.Play(self.Popup, "Fast", { BackgroundTransparency = 0.07, GroupTransparency = 0 })
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
		if self.List then
			Tween.Play(self.List, "Fast", { ScrollBarImageTransparency = 1 })
			self.List.ScrollBarImageTransparency = 1
			if not self._scrollConnection then
				self._scrollConnection = self.List:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
					self:_showScrollbar()
				end)
			end
		end
	end
	self.Close = function(_self)
		if not self.Popup then
			return
		end
		if not self.IsOpen then
			return
		end
		self.IsOpen = false
		-- Disarm click-outside immediately so a click during the fade-out can't re-trigger it.
		self:_disconnectOutsideClick()
		if self._inputConnection then
			self._inputConnection:Disconnect()
			self._inputConnection = nil
		end
		if self._scrollbarTimer then
			task.cancel(self._scrollbarTimer)
			self._scrollbarTimer = nil
		end
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
			Tween.Play(self.Popup, "Fast", { BackgroundTransparency = 1, GroupTransparency = 1 })
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
	-- Click-outside via UserInputService, connected only while the popup is open.
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
			-- Inside if the point hits the popup's rect or any descendant, so overhanging content isn't misread as outside.
			local pos = self.Popup.AbsolutePosition
			local size = self.Popup.AbsoluteSize
			local inside = p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
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
		me.Popup.GroupTransparency = 1
		me.Popup.Visible = false
		me.IsOpen = false
		me:_disconnectOutsideClick()
		if me._inputConnection then
			me._inputConnection:Disconnect()
			me._inputConnection = nil
		end
		if me._hideTimer then
			task.cancel(me._hideTimer)
			me._hideTimer = nil
		end
		if me._scrollbarTimer then
			task.cancel(me._scrollbarTimer)
			me._scrollbarTimer = nil
		end
	end
	self.Destroy = function(me)
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
		-- Notify Window that this popup is gone.
		if me._cleanupCallback then
			me._cleanupCallback()
			me._cleanupCallback = nil
		end
	end
	-- Scrollbar visibility: show on scroll, auto-hide after 1.5s
	self._showScrollbar = function(_self)
		if self.List then
			Tween.Play(self.List, "Fast", { ScrollBarImageTransparency = 0.5 })
			if self._scrollbarTimer then
				task.cancel(self._scrollbarTimer)
				self._scrollbarTimer = nil
			end
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
