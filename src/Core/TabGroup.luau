--[[
	Aetheris/Core/TabGroup.luau

	Owns sidebar tab buttons and their content containers, and keeps the page
	title in sync with the active tab.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Tween = require("../Utils/Tween")
local Section = require("./Section")
local FallbackImage = require("../Constants").FallbackImage
local ThemeManager = require("../Themes/ThemeManager")
local SearchFilter = require("./SearchFilter")
local PageFade = require("../Utils/PageFade")
local PageAwareness = require("../Utils/PageAwareness")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")
local TabGroup = {}
TabGroup.__index = TabGroup
local TabHandle = {}
TabHandle.__index = TabHandle
function TabHandle:Section(Settings)
	Settings = Settings or {}
	local side = Settings.Side or "Left"
	local column = side == "Left" and self.ColumnLeft or self.ColumnRight
	return Section.new(column, Settings, self._theme, self.Window)
end
function TabGroup.new(window, theme)
	theme = ThemeManager.GetTheme(theme)
	local self = setmetatable({}, TabGroup)
	self.Window = window
	self._theme = theme or {}
	self.Tabs = {}
	self.ActiveTab = nil
	self._transitioning = false
	self._spinHandles = {}
	-- Registered with ThemeManager so ApplyTheme reaches this group's tab
	-- buttons, dividers and scrollbars without name-matching.
	ThemeManager.Register(self.Window.TabList, self)
	return self
end
-- Pause a tab backdrop's spin so it resumes from the same angle later.
function TabGroup:_pauseSpin(gradient)
	if not gradient then
		return
	end
	Tween.PauseSpin(gradient)
end
-- Resume from the paused angle; start fresh only if this gradient was never registered.
function TabGroup:_resumeSpin(gradient, _reset)
	if not gradient then
		return
	end
	if not Tween.ResumeSpin(gradient) then
		Tween.StartSpin(gradient, { Rotation = 360 }, "SpinIdle")
	end
end
function TabGroup:Tab(Settings)
	Settings = Settings or {}
	local name = Settings.Name or "Tab"
	local isFirst = #self.Tabs == 0
	local theme = self._theme or {}
	if not next(theme) then
		theme = ThemeManager.GetTheme(nil)
		self._theme = theme
	end
	local Button = Instance.new("TextButton")
	Button.Name = UUID.Generate("Tab")
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.BackgroundColor3 = theme.InactiveTabButtonColor
	Button.BackgroundTransparency = theme.InactiveTabButtonTransparency
	Button.Size = UDim2.new(0.849, 0, 0, 40)
	Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Button.Text = ""
	Button.LayoutOrder = #self.Tabs + 1
	Button.Parent = self.Window.TabList
	local ButtonCorner = Instance.new("UICorner")
	ButtonCorner.Parent = Button
	local TabName = Instance.new("TextLabel")
	TabName.Name = UUID.Static("TabName")
	TabName.BorderSizePixel = 0
	TabName.TextSize = 13
	TabName.TextXAlignment = Enum.TextXAlignment.Left
	TabName.TextTransparency = theme.InactiveTabTextTransparency
	TabName.FontFace = Constants.Font(Enum.FontWeight.Medium)
	TabName.TextColor3 = theme.InactiveTabTextColor
	TabName.BackgroundTransparency = 1
	TabName.AnchorPoint = Vector2.new(0.5, 0.5)
	TabName.Size = UDim2.fromScale(0.636, 0.714)
	TabName.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabName.Text = name
	TabName.Position = UDim2.fromScale(0.647, 0.5)
	TabName.Parent = Button
	local BackImage = Instance.new("ImageLabel")
	BackImage.Name = UUID.Static("BackImage")
	BackImage.BorderSizePixel = 0
	BackImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BackImage.ImageTransparency = 1
	BackImage.AnchorPoint = Vector2.new(0.5, 0.5)
	local imageId = theme.Wallpaper or FallbackImage
	BackImage.Image = imageId
	BackImage.Size = UDim2.fromScale(1, 1)
	BackImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BackImage.BackgroundTransparency = 1
	BackImage.Position = UDim2.fromScale(0.5, 0.5)
	BackImage.Parent = Button
	-- Marked as a true backdrop so ThemeManager updates its image/visibility
	-- without touching the component sheens.
	BackImage:SetAttribute(UUID.Static("IsTabBackdrop"), true)
	-- `~= false` matches TabGroup:ApplyTheme so construction and a live theme
	-- switch agree on a nil value.
	BackImage.Visible = theme.WallpaperEnabled ~= false
	local BackImageCorner = Instance.new("UICorner")
	BackImageCorner.CornerRadius = UDim.new(0, 6)
	BackImageCorner.Parent = BackImage
	local BackImageGradient = Instance.new("UIGradient")
	BackImageGradient.Rotation = 0
	BackImageGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.000, 0),
		NumberSequenceKeypoint.new(0.134, 0.3),
		NumberSequenceKeypoint.new(0.242, 0.53125),
		NumberSequenceKeypoint.new(0.371, 0.69375),
		NumberSequenceKeypoint.new(0.484, 0.80625),
		NumberSequenceKeypoint.new(0.590, 0.91875),
		NumberSequenceKeypoint.new(0.681, 0.975),
		NumberSequenceKeypoint.new(1.000, 1),
	})
	BackImageGradient.Parent = BackImage
	local TabImage = Instance.new("ImageLabel")
	TabImage.Name = UUID.Static("TabImage")
	TabImage.BorderSizePixel = 0
	TabImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabImage.ImageTransparency = theme.InactiveTabIconTransparency
	TabImage.AnchorPoint = Vector2.new(0, 0.5)
	TabImage.Image = Settings.Icon or "rbxassetid://8445470392"
	TabImage.ImageColor3 = theme.InactiveTabIconColor
	TabImage.Size = UDim2.fromOffset(15, 15)
	TabImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabImage.BackgroundTransparency = 1
	TabImage.Position = UDim2.new(0, 15, 0.5, 0)
	TabImage.Parent = Button
	-- Always exists (even when inactive) so we tween its transparency instead
	-- of creating it on every switch.
	local SelectionStatus = Instance.new("Frame")
	SelectionStatus.Name = UUID.Static("SelectionStatus")
	SelectionStatus.BorderSizePixel = 0
	SelectionStatus.BackgroundColor3 = theme.SecondaryColor
	SelectionStatus.BackgroundTransparency = 1
	SelectionStatus.AnchorPoint = Vector2.new(0.5, 0.5)
	SelectionStatus.Size = UDim2.fromOffset(2, 0)
	SelectionStatus.Position = UDim2.new(0, -5, 0.5, 0)
	SelectionStatus.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SelectionStatus.Parent = Button
	local ContentScroller = Instance.new("ScrollingFrame")
	ContentScroller.Name = UUID.Generate("TabScroller")
	ContentScroller.BorderSizePixel = 0
	ContentScroller.CanvasSize = UDim2.fromScale(0, 0)
	ContentScroller.TopImage = ""
	ContentScroller.BottomImage = ""
	ContentScroller.ScrollBarImageTransparency = 1
	ContentScroller.BackgroundTransparency = 1
	ContentScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ContentScroller.ClipsDescendants = false
	ContentScroller.Size = UDim2.fromScale(1, 1)
	ContentScroller.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ContentScroller.ScrollBarThickness = 1
	ContentScroller.ScrollBarImageColor3 = theme.TertiaryColor
	-- The FadeLayer below owns visibility: the scroller stays Visible=true
	-- inside it and the layer is what fades in/out.
	ContentScroller.Visible = true
	-- One CanvasGroup per tab owns the page fade; nothing inside a page is
	-- transparency-faded, so radio/slider state can never be stomped.
	local FadeLayer = PageFade.Layer(self.Window.TabContent, UUID.Generate("TabFade"))
	FadeLayer.Visible = false
	ContentScroller.Parent = FadeLayer
	local scrollerScrollbarTimer
	ContentScroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		Tween.Play(ContentScroller, "Fast", { ScrollBarImageTransparency = 0.5 })
		if scrollerScrollbarTimer then
			task.cancel(scrollerScrollbarTimer)
		end
		scrollerScrollbarTimer = task.delay(1.5, function()
			Tween.Play(ContentScroller, "Fast", { ScrollBarImageTransparency = 1 })
			scrollerScrollbarTimer = nil
		end)
	end)
	local ContentScrollerPadding = Instance.new("UIPadding")
	ContentScrollerPadding.PaddingTop = UDim.new(0, 5)
	ContentScrollerPadding.PaddingRight = UDim.new(0, 3)
	ContentScrollerPadding.PaddingBottom = UDim.new(0, 5)
	ContentScrollerPadding.Parent = ContentScroller
	local ContentScrollerLayout = Instance.new("UIListLayout")
	ContentScrollerLayout.Padding = UDim.new(0, 12)
	ContentScrollerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ContentScrollerLayout.FillDirection = Enum.FillDirection.Horizontal
	ContentScrollerLayout.Parent = ContentScroller
	local ColumnLeft = Instance.new("Frame")
	ColumnLeft.Name = UUID.Static("Left")
	ColumnLeft.BorderSizePixel = 0
	ColumnLeft.BackgroundTransparency = 1
	ColumnLeft.AutomaticSize = Enum.AutomaticSize.Y
	ColumnLeft.Size = UDim2.new(0.5, -10, 0, 0)
	ColumnLeft.Position = UDim2.fromScale(0.512, 0)
	ColumnLeft.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ColumnLeft.Parent = ContentScroller
	local ColumnLeftLayout = Instance.new("UIListLayout")
	ColumnLeftLayout.Padding = UDim.new(0, 15)
	ColumnLeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ColumnLeftLayout.Parent = ColumnLeft
	local ColumnRight = Instance.new("Frame")
	ColumnRight.Name = UUID.Static("Right")
	ColumnRight.BorderSizePixel = 0
	ColumnRight.BackgroundTransparency = 1
	ColumnRight.AutomaticSize = Enum.AutomaticSize.Y
	ColumnRight.Size = UDim2.new(0.5, -10, 0, 0)
	ColumnRight.Position = UDim2.fromScale(0.512, 0)
	ColumnRight.LayoutOrder = 1
	ColumnRight.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ColumnRight.Parent = ContentScroller
	local ColumnRightLayout = Instance.new("UIListLayout")
	ColumnRightLayout.Padding = UDim.new(0, 15)
	ColumnRightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ColumnRightLayout.Parent = ColumnRight
	local tab = setmetatable({
		Window = self.Window,
		Name = name,
		Button = Button,
		TabName = TabName,
		BackImage = BackImage,
		BackImageGradient = BackImageGradient,
		TabImage = TabImage,
		SelectionStatus = SelectionStatus,
		ContentScroller = ContentScroller,
		FadeLayer = FadeLayer,
		ColumnLeft = ColumnLeft,
		ColumnRight = ColumnRight,
		_layout = ContentScrollerLayout,
		_scrollerPadding = ContentScrollerPadding,
		_theme = theme,
	}, TabHandle)
	-- Tab visuals use state-aware color bindings so theme and tab switches
	-- resolve through one path without color tween stomps.
	tab._bgHandle = ThemeManager.BindColor(
		Button,
		"BackgroundColor3",
		{ Active = "ActiveTabButtonColor", Inactive = "InactiveTabButtonColor" },
		{ state = "Inactive", duration = 0.2 }
	)
	tab._bgTransHandle = ThemeManager.BindTransparency(
		Button,
		"BackgroundTransparency",
		{ Active = "ActiveTabButtonTransparency", Inactive = "InactiveTabButtonTransparency" },
		{ state = "Inactive", duration = 0.2 }
	)
	tab._nameColorHandle = ThemeManager.BindColor(
		TabName,
		"TextColor3",
		{ Active = "ActiveTabTextColor", Inactive = "InactiveTabTextColor" },
		{ state = "Inactive", duration = 0.2 }
	)
	tab._nameTransHandle = ThemeManager.BindTransparency(
		TabName,
		"TextTransparency",
		{ Active = "ActiveTabTextTransparency", Inactive = "InactiveTabTextTransparency" },
		{ state = "Inactive", duration = 0.2 }
	)
	tab._iconColorHandle = ThemeManager.BindColor(
		TabImage,
		"ImageColor3",
		{ Active = "ActiveTabIconColor", Inactive = "InactiveTabIconColor" },
		{ state = "Inactive", duration = 0.2 }
	)
	tab._iconTransHandle = ThemeManager.BindTransparency(
		TabImage,
		"ImageTransparency",
		{ Active = "ActiveTabIconTransparency", Inactive = "InactiveTabIconTransparency" },
		{ state = "Inactive", duration = 0.2 }
	)
	ThemeManager.BindColor(SelectionStatus, "BackgroundColor3", "SecondaryColor")
	ThemeManager.BindColor(ContentScroller, "ScrollBarImageColor3", "TertiaryColor")
	Button.MouseButton1Click:Connect(function()
		self.Window.SettingsPages.Visible = false
		self.Window.TabContent.Visible = true
		self:SetActiveTab(tab)
		-- Refresh AFTER SetActiveTab so the early "same tab" return still picks
		-- up the SettingsPages flip above.
		PageAwareness.Refresh()
	end)
	table.insert(self.Tabs, tab)
	-- A tab created while the window is already compact must not start in the
	-- 2-column layout.
	if self._compact then
		self:_applyTabCompact(tab, true)
	end
	if Settings.Active or isFirst then
		self:SetActiveTab(tab)
	end
	return tab
end
local EXPANDED_COLUMN_SIZE = UDim2.new(0.5, -10, 0, 0)
-- Compact gives the single column more right padding so it isn't flush
-- against the scrollbar edge.
local EXPANDED_SCROLLER_PAD_RIGHT = UDim.new(0, 3)
local COMPACT_SCROLLER_PAD_RIGHT = UDim.new(0, 10)
function TabGroup:_applyTabCompact(tab, on)
	local layout = tab and tab._layout
	if not layout or not tab.ColumnLeft or not tab.ColumnRight then
		return
	end
	local padding = tab._scrollerPadding
	if on then
		layout.FillDirection = Enum.FillDirection.Vertical
		tab.ColumnLeft.Size = UDim2.fromScale(1, 0)
		tab.ColumnRight.Size = UDim2.fromScale(1, 0)
		tab.ColumnLeft.Position = UDim2.fromScale(0, 0)
		tab.ColumnRight.Position = UDim2.fromScale(0, 0)
		if padding then
			padding.PaddingRight = COMPACT_SCROLLER_PAD_RIGHT
		end
	else
		layout.FillDirection = Enum.FillDirection.Horizontal
		tab.ColumnLeft.Size = EXPANDED_COLUMN_SIZE
		tab.ColumnRight.Size = EXPANDED_COLUMN_SIZE
		tab.ColumnLeft.Position = UDim2.fromScale(0.512, 0)
		tab.ColumnRight.Position = UDim2.fromScale(0.512, 0)
		if padding then
			padding.PaddingRight = EXPANDED_SCROLLER_PAD_RIGHT
		end
	end
end
function TabGroup:SetCompact(on)
	on = on and true or false
	self._compact = on
	for _, tab in ipairs(self.Tabs) do
		self:_applyTabCompact(tab, on)
	end
end
function TabGroup:Divider()
	local theme = self._theme or {}
	local Divider = Instance.new("Frame")
	Divider.Name = UUID.Static("Divider")
	Divider.BorderSizePixel = 0
	-- Dividers share the Divider component's theme keys, so there is one notion
	-- of divider styling.
	Divider.BackgroundColor3 = theme.SectionDividerColor or theme.TertiaryColor
	Divider.BackgroundTransparency = theme.SectionDividerTransparency or 0.5
	Divider.Size = UDim2.new(0.85227, 0, 0, 1)
	Divider.LayoutOrder = #self.Tabs + 1
	Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Divider:SetAttribute(UUID.Static("IsDivider"), true)
	Divider.Parent = self.Window.TabList
	return Divider
end
-- Called by ThemeManager after a blanket CancelAll (a theme switch) cancels
-- in-flight page fades; restores the active tab to its natural state.
function TabGroup:RestoreActiveTab()
	local tab = self.ActiveTab
	if not tab then
		return
	end
	for _, other in ipairs(self.Tabs) do
		if other.FadeLayer then
			other.FadeLayer.Visible = (other == tab)
		end
	end
	if tab.FadeLayer then
		PageFade.Snap(tab.FadeLayer, 0)
	end
	if self.Window and self.Window.PageTitle then
		self.Window.PageTitle.TextTransparency = 0.4
	end
end

function TabGroup:_applyTabVisuals(t, active)
	local state = active and "Active" or "Inactive"
	if t._bgHandle then
		t._bgHandle:SetState(state)
	end
	if t._bgTransHandle then
		t._bgTransHandle:SetState(state)
	end
	if t._nameColorHandle then
		t._nameColorHandle:SetState(state)
	end
	if t._nameTransHandle then
		t._nameTransHandle:SetState(state)
	end
	if t._iconColorHandle then
		t._iconColorHandle:SetState(state)
	end
	if t._iconTransHandle then
		t._iconTransHandle:SetState(state)
	end
	-- The backdrop reveal and the indicator's size/spin are fixed constants,
	-- not theme keys, so they stay imperative.
	if active then
		Tween.Play(t.BackImage, "Fast", { ImageTransparency = 0 })
		Tween.Play(t.SelectionStatus, "OnOff", { BackgroundTransparency = 0, Size = UDim2.new(0, 2, 0.7, 0) })
		self:_resumeSpin(t.BackImageGradient, true)
	else
		Tween.Play(t.BackImage, "Fast", { ImageTransparency = 1 })
		Tween.Play(t.SelectionStatus, "OnOff", { BackgroundTransparency = 1, Size = UDim2.fromOffset(2, 0) })
		self:_pauseSpin(t.BackImageGradient)
	end
end

function TabGroup:SetActiveTab(tab)
	local previous = self.ActiveTab
	if previous == tab then
		-- Re-selecting the active tab still has to restore the page title:
		-- settings overwrites it with "Settings | ..." and nothing else does.
		local title = self.Window and self.Window.PageTitle
		if title then
			title.Text = self:_titleText(tab)
		end
		return
	end
	self.ActiveTab = tab
	-- Fire page-awareness handlers now; the crossfade below is purely visual
	-- and doesn't change which page is active.
	PageAwareness.Refresh()

	-- A page switch dismisses any open popup so it can never linger over the
	-- newly shown page.
	if self.Window and self.Window.HidePopups then
		self.Window:HidePopups()
	end

	-- Keep the sidebar search consistent across a tab switch: restore the page
	-- we leave, then re-apply the query to the page we enter.
	if previous and previous.ContentScroller then
		SearchFilter.Clear(previous.ContentScroller)
	end
	local w = self.Window
	if w and w.SearchBox and w.SearchBox.Text ~= "" then
		SearchFilter.Apply(tab.ContentScroller, w.SearchBox.Text, w._theme)
	end
	local title = self.Window and self.Window.PageTitle

	if previous then
		self:_applyTabVisuals(previous, false)
	end
	self:_applyTabVisuals(tab, true)

	if self.Window and self.Window._windowFaded then
		-- Visible alone does NOT reset GroupTransparency: snap each layer fully
		-- to its end state or a page left at 1 renders blank when shown.
		for _, other in ipairs(self.Tabs) do
			if other.FadeLayer then
				local isTarget = (other == tab)
				other.FadeLayer.Visible = isTarget
				PageFade.Snap(other.FadeLayer, isTarget and 0 or 1)
			end
		end
		if title then
			title.Text = self:_titleText(tab)
		end
		return
	end

	if previous == nil then
		tab.FadeLayer.Visible = true
		PageFade.Snap(tab.FadeLayer, 1)
		PageFade.Show(tab.FadeLayer, false)
		if title then
			title.Text = self:_titleText(tab)
			Tween.Play(title, "Fast", { TextTransparency = 0.4 })
		end
		return
	end

	tab.FadeLayer.Visible = true
	if title then
		title.Text = self:_titleText(tab)
	end
	PageFade.Crossfade(previous.FadeLayer, tab.FadeLayer, function()
		if previous.FadeLayer then
			previous.FadeLayer.Visible = false
		end
	end)
end

-- Medium via a rich-text weight span: <b> would force bold and ignore the
-- label's FontFace.
function TabGroup:_titleText(tab)
	return '<font weight="500">' .. tab.Name .. "</font>"
end

-- Rewrite the window title to the active sidebar tab's name; the settings
-- overlay owns it while open and hands it back on close.
function TabGroup:SyncTitle()
	local w = self.Window
	if w and w.PageTitle and self.ActiveTab then
		w.PageTitle.Text = self:_titleText(self.ActiveTab)
	end
end

-- Called by ThemeManager via the component registry; applies colors directly
-- (no animation) so the surrounding crossfade still produces the old -> new fade.
function TabGroup:ApplyTheme(newTheme)
	local theme = ThemeManager.GetTheme(newTheme)
	self._theme = theme
	for _, t in ipairs(self.Tabs) do
		t._theme = theme
		-- SetState re-resolves every state-aware binding, so the active tab
		-- picks up the new theme's key values at once.
		if t._bgHandle then
			t._bgHandle:SetState((t == self.ActiveTab) and "Active" or "Inactive")
		end
		if t._bgTransHandle then
			t._bgTransHandle:SetState((t == self.ActiveTab) and "Active" or "Inactive")
		end
		if t._nameColorHandle then
			t._nameColorHandle:SetState((t == self.ActiveTab) and "Active" or "Inactive")
		end
		if t._nameTransHandle then
			t._nameTransHandle:SetState((t == self.ActiveTab) and "Active" or "Inactive")
		end
		if t._iconColorHandle then
			t._iconColorHandle:SetState((t == self.ActiveTab) and "Active" or "Inactive")
		end
		if t._iconTransHandle then
			t._iconTransHandle:SetState((t == self.ActiveTab) and "Active" or "Inactive")
		end
		-- Wallpaper Image/Visible aren't Color3/number and use nil-safe
		-- fallbacks, so they stay imperative here.
		t.BackImage.Image = theme.Wallpaper or FallbackImage
		t.BackImage.Visible = theme.WallpaperEnabled ~= false
	end
	for _, child in ipairs(self.Window.TabList:GetChildren()) do
		if child:GetAttribute(UUID.Static("IsDivider")) then
			child.BackgroundColor3 = theme.SectionDividerColor or theme.TertiaryColor or child.BackgroundColor3
			child.BackgroundTransparency = theme.SectionDividerTransparency or child.BackgroundTransparency
		end
	end
end

return TabGroup
