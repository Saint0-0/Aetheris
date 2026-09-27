--[[
	TabGroup  ·  Aetheris UI Library

	Owns the sidebar tab buttons, their per-tab content containers, switching
	between them, and keeping Window.PageTitle in sync with the active tab.

	Usage:
		local tabs = TabGroup.new(window)  -- window = Window.new() result
		local aimbotTab = tabs:Tab({ Name = "Aimbot", Icon = "rbxassetid://..." })
		tabs:Divider()
		local settingsTab = tabs:Tab({ Name = "Settings", Icon = "rbxassetid://..." })

		aimbotTab.ContentScroller  -- this tab's own scroller
		aimbotTab.ColumnLeft / aimbotTab.ColumnRight  -- the two layout columns
]]

local Tween = require("../Utils/Tween")
local Section = require("./Section")
local FallbackImage = require("../Constants").FallbackImage
local ThemeManager = require("../Themes/ThemeManager")
local SearchFilter = require("./SearchFilter")
local PageFade = require("../Utils/PageFade")
local Constants = require("../Constants")
local TabGroup = {}
TabGroup.__index = TabGroup
-- Tab handle metatable for methods like :Section()
local TabHandle = {}
TabHandle.__index = TabHandle
function TabHandle:Section(Settings)
	Settings = Settings or {}
	local side = Settings.Side or "Left"
	local column = side == "Left" and self.ColumnLeft or self.ColumnRight
	return Section.new(column, Settings, self._theme)
end
function TabGroup.new(window, theme)
	theme = ThemeManager.GetTheme(theme)
	local self = setmetatable({}, TabGroup)
	self.Window = window
	self._theme = theme or {}  -- store resolved theme
	self.Tabs = {} -- ordered list of tab handles
	self.ActiveTab = nil
	self._transitioning = false
	self._spinHandles = {}
	-- Register with ThemeManager so ApplyTheme reaches this group's tab
	-- buttons, dividers and content scrollbars without name-matching. The
	-- TabList is the group's root under window.Base (the registry iterates
	-- Base's descendants and looks components up by their root instance).
	ThemeManager.Register(self.Window.TabList, self)
	return self
end
-- Helper: build fade cache for a tab's ContentScroller.
-- Recursively scans all descendants for properties:
-- BackgroundTransparency, TextTransparency, ImageTransparency, Transparency (for UIStroke etc.)
-- Returns an array of {instance, props = {{prop, base}, ...}}
-- Snapshot a tab's base transparencies. Only valid while the page is
-- natural (not faded); re-captured whenever the tab is natural so pages whose
-- content is added after creation are captured fully.
-- NOTE: the old per-element transparency cache system was REMOVED in the
-- PageFade rework. Page transitions are now driven by ONE CanvasGroup per tab
-- (tab.FadeLayer, see Utils/PageFade), so nothing inside a page is ever
-- transparency-faded and no base state can be stomped.
-- A tab's base transparencies are captured ONCE, then reused forever.
-- INVARIANT: tab content always rests at its base (hidden tabs are just
-- Visible=false, NOT faded to 1). That makes a single capture permanently
-- valid, so the window fade can snapshot/restore any tab without guards.
-- (Page transitions are handled entirely by Utils/PageFade now: one
-- CanvasGroup per tab, faded via PageFade.Crossfade/Show/Snap. The old
-- per-element transparency cache functions were removed.)
-- Tab backdrop spins route through the CENTRAL spin system so the global
-- Tween.SetSpinsEnabled toggle controls them too. Inactive tab backdrops are
-- PAUSED (angle preserved) rather than stopped, so switching back resumes the
-- sweep where it left off instead of snapping to 0.
function TabGroup:_pauseSpin(gradient)
	if not gradient then return end
	Tween.PauseSpin(gradient)
end
-- Resume from the paused angle; only start fresh if this gradient has never
-- been registered (the first time a tab is shown).
function TabGroup:_resumeSpin(gradient, reset)
	if not gradient then return end
	if not Tween.ResumeSpin(gradient) then
		Tween.StartSpin(gradient, { Rotation = 360 }, "SpinIdle")
	end
end
--[[
	Tab(Settings)
	Settings:
		Name (string, required) -- shown as the tab's label and reflected
			into Window.PageTitle when this tab is active
		Icon (string, optional) -- rbxassetid:// for TabImage
		Active (bool, optional) -- true to make this the initially-selected
			tab. If no tab in the group is ever marked Active, the first
			one created becomes active by default.
	Returns a tab handle: { Button, ContentScroller, ColumnLeft, ColumnRight,
	Name, SetActive(self) }
]]
function TabGroup:Tab(Settings)
	Settings = Settings or {}
	local name = Settings.Name or "Tab"
	local isFirst = #self.Tabs == 0
	-- Use the stored theme (already resolved)
	local theme = self._theme or {}
	-- Fallback: if theme is empty, resolve it
	if not next(theme) then
		local ThemeManager = require("../Themes/ThemeManager")
		theme = ThemeManager.GetTheme(nil)
		self._theme = theme
	end
	----------------------------------------------------------------
	-- Tab button
	----------------------------------------------------------------
	local Button = Instance.new("TextButton")
	Button.Name = name .. "Tab"
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
	TabName.Name = "TabName"
	TabName.BorderSizePixel = 0
	TabName.TextSize = 13
	TabName.TextXAlignment = Enum.TextXAlignment.Left
	TabName.TextTransparency = theme.InactiveTabTextTransparency
	TabName.FontFace = Constants.Font(Enum.FontWeight.Medium)
	TabName.TextColor3 = theme.InactiveTabTextColor
	TabName.BackgroundTransparency = 1
	TabName.AnchorPoint = Vector2.new(0.5, 0.5)
	TabName.Size = UDim2.new(0.636, 0, 0.714, 0)
	TabName.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabName.Text = name
	TabName.Position = UDim2.new(0.647, 0, 0.5, 0)
	TabName.Parent = Button
	local BackImage = Instance.new("ImageLabel")
	BackImage.Name = "BackImage"
	BackImage.BorderSizePixel = 0
	BackImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BackImage.ImageTransparency = 1 -- deactivated: spinning gradient logo hidden
	BackImage.AnchorPoint = Vector2.new(0.5, 0.5)
	-- Use theme's Wallpaper or fallback
	local imageId = theme.Wallpaper or FallbackImage
	BackImage.Image = imageId
	BackImage.Size = UDim2.new(1, 0, 1, 0)
	BackImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BackImage.BackgroundTransparency = 1
	BackImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	BackImage.Parent = Button
	-- Mark as a true backdrop so ThemeManager updates its image/visibility
	-- without touching the component sheens (which also use the brand asset).
	BackImage:SetAttribute("IsTabBackdrop", true)
	-- Set visibility based on current theme's WallpaperEnabled. Use the same
	-- `~= false` form as TabGroup:ApplyTheme so construction and a live theme
	-- switch agree (a plain truthy test treats a nil value as hidden, whereas
	-- `~= false` treats it as shown).
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
	TabImage.Name = "TabImage"
	TabImage.BorderSizePixel = 0
	TabImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabImage.ImageTransparency = theme.InactiveTabIconTransparency
	TabImage.AnchorPoint = Vector2.new(0, 0.5)
	TabImage.Image = Settings.Icon or "rbxassetid://8445470392"
	TabImage.ImageColor3 = theme.InactiveTabIconColor
	TabImage.Size = UDim2.new(0, 15, 0, 15)
	TabImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabImage.BackgroundTransparency = 1
	TabImage.Position = UDim2.new(0, 15, 0.5, 0)
	TabImage.Parent = Button
	-- Active-state indicator bar -- only meaningfully visible when active,
	-- but always exists so we can tween its transparency rather than
	-- creating/destroying it on every switch.
	local SelectionStatus = Instance.new("Frame")
	SelectionStatus.Name = "SelectionStatus"
	SelectionStatus.BorderSizePixel = 0
	SelectionStatus.BackgroundColor3 = theme.SecondaryColor
	SelectionStatus.BackgroundTransparency = 1 -- hidden until active
	SelectionStatus.AnchorPoint = Vector2.new(0.5, 0.5)
	SelectionStatus.Size = UDim2.new(0, 2, 0, 0) -- start collapsed
	SelectionStatus.Position = UDim2.new(0, -5, 0.5, 0)
	SelectionStatus.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SelectionStatus.Parent = Button
	----------------------------------------------------------------
	-- This tab's own content container (per Settings: NOT shared between
	-- tabs -- each tab gets a dedicated ContentScroller)
	----------------------------------------------------------------
	local ContentScroller = Instance.new("ScrollingFrame")
	ContentScroller.Name = name .. "Scroller"
	ContentScroller.BorderSizePixel = 0
	ContentScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	ContentScroller.TopImage = ""
	ContentScroller.BottomImage = ""
	ContentScroller.ScrollBarImageTransparency = 1 -- hidden until scrolling
	ContentScroller.BackgroundTransparency = 1
	ContentScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ContentScroller.ClipsDescendants = false
	ContentScroller.Size = UDim2.new(1, 0, 1, 0)
	ContentScroller.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ContentScroller.ScrollBarThickness = 1
	ContentScroller.ScrollBarImageColor3 = theme.TertiaryColor
	-- Visibility is now owned by the FadeLayer (CanvasGroup) below, NOT by the
	-- scroller: the scroller stays Visible=true inside the layer, and the layer
	-- is what fades in/out. (Previously the scroller itself was toggled.)
	ContentScroller.Visible = true
	-- Page transition layer: ONE CanvasGroup per tab owns the page fade.
	-- The scroller (and everything inside it) is never transparency-faded,
	-- so component state encoded as transparency (radio selection, slider
	-- fill, etc.) can never be stomped by a page switch. See Utils/PageFade.
	local FadeLayer = PageFade.Layer(self.Window.TabContent, name .. "Page")
	FadeLayer.Visible = false
	ContentScroller.Parent = FadeLayer
	-- Scrollbar: only visible while scrolling
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
	ColumnLeft.Name = "Left"
	ColumnLeft.BorderSizePixel = 0
	ColumnLeft.BackgroundTransparency = 1
	ColumnLeft.AutomaticSize = Enum.AutomaticSize.Y
	ColumnLeft.Size = UDim2.new(0.5, -10, 0, 0)
	ColumnLeft.Position = UDim2.new(0.512, 0, 0, 0)
	ColumnLeft.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ColumnLeft.Parent = ContentScroller
	local ColumnLeftLayout = Instance.new("UIListLayout")
	ColumnLeftLayout.Padding = UDim.new(0, 15)
	ColumnLeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ColumnLeftLayout.Parent = ColumnLeft
	local ColumnRight = Instance.new("Frame")
	ColumnRight.Name = "Right"
	ColumnRight.BorderSizePixel = 0
	ColumnRight.BackgroundTransparency = 1
	ColumnRight.AutomaticSize = Enum.AutomaticSize.Y
	ColumnRight.Size = UDim2.new(0.5, -10, 0, 0)
	ColumnRight.Position = UDim2.new(0.512, 0, 0, 0)
	ColumnRight.LayoutOrder = 1
	ColumnRight.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ColumnRight.Parent = ContentScroller
	local ColumnRightLayout = Instance.new("UIListLayout")
	ColumnRightLayout.Padding = UDim.new(0, 15)
	ColumnRightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ColumnRightLayout.Parent = ColumnRight
	----------------------------------------------------------------
	-- Tab handle
	----------------------------------------------------------------
	local tab = setmetatable({
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
	-- Declarative STATE-AWARE theming for the tab button visuals. Each handle
	-- flips between the Active/Inactive theme keys via SetState (called from
	-- _applyTabVisuals), so a THEME switch and a TAB switch both resolve through
	-- the binding system -- no Tween.Play color stomps, no registry ApplyTheme
	-- for these properties. duration = 0.2 matches the old "Fast" preset so the
	-- tab-switch highlight animates at the same speed.
	tab._bgHandle = ThemeManager.BindColor(Button, "BackgroundColor3",
		{ Active = "ActiveTabButtonColor", Inactive = "InactiveTabButtonColor" },
		{ state = "Inactive", duration = 0.2 })
	tab._bgTransHandle = ThemeManager.BindTransparency(Button, "BackgroundTransparency",
		{ Active = "ActiveTabButtonTransparency", Inactive = "InactiveTabButtonTransparency" },
		{ state = "Inactive", duration = 0.2 })
	tab._nameColorHandle = ThemeManager.BindColor(TabName, "TextColor3",
		{ Active = "ActiveTabTextColor", Inactive = "InactiveTabTextColor" },
		{ state = "Inactive", duration = 0.2 })
	tab._nameTransHandle = ThemeManager.BindTransparency(TabName, "TextTransparency",
		{ Active = "ActiveTabTextTransparency", Inactive = "InactiveTabTextTransparency" },
		{ state = "Inactive", duration = 0.2 })
	tab._iconColorHandle = ThemeManager.BindColor(TabImage, "ImageColor3",
		{ Active = "ActiveTabIconColor", Inactive = "InactiveTabIconColor" },
		{ state = "Inactive", duration = 0.2 })
	tab._iconTransHandle = ThemeManager.BindTransparency(TabImage, "ImageTransparency",
		{ Active = "ActiveTabIconTransparency", Inactive = "InactiveTabIconTransparency" },
		{ state = "Inactive", duration = 0.2 })
	-- Static (state-independent) binds.
	ThemeManager.BindColor(SelectionStatus, "BackgroundColor3", "SecondaryColor")
	ThemeManager.BindColor(ContentScroller, "ScrollBarImageColor3", "TertiaryColor")
	Button.MouseButton1Click:Connect(function()
		-- Close the settings page and return to normal tab content.
		self.Window.SettingsPages.Visible = false
		self.Window.TabContent.Visible = true
		self:SetActiveTab(tab)
	end)
	table.insert(self.Tabs, tab)
	-- A tab created while the window is already compact must not start out in
	-- the 2-column layout, or it would render side-by-side until the next
	-- compact toggle.
	if self._compact then
		self:_applyTabCompact(tab, true)
	end
	if Settings.Active or isFirst then
		self:SetActiveTab(tab)
	end
	return tab
end
-- Flip one tab between the 2-column (expanded) and 1-column (compact)
-- layout. In compact the UIListLayout that holds ColumnLeft/ColumnRight goes
-- Vertical and each column spans the full width, so ColumnLeft's sections
-- stack directly above ColumnRight's -- one scrolling column of content.
-- Nothing is reparented: Sections keep their parent column, so search
-- filtering, layout orders and fade caches are all untouched, and the change
-- is a pure property swap that reverses exactly.
local EXPANDED_COLUMN_SIZE = UDim2.new(0.5, -10, 0, 0)
-- Per-tab scroller right padding. Compact gets a little more breathing room so
-- the single column doesn't sit flush against the scrollbar edge.
local EXPANDED_SCROLLER_PAD_RIGHT = UDim.new(0, 3)
local COMPACT_SCROLLER_PAD_RIGHT = UDim.new(0, 10)
function TabGroup:_applyTabCompact(tab, on)
	local layout = tab and tab._layout
	if not layout or not tab.ColumnLeft or not tab.ColumnRight then return end
	local padding = tab._scrollerPadding
	if on then
		layout.FillDirection = Enum.FillDirection.Vertical
		tab.ColumnLeft.Size = UDim2.new(1, 0, 0, 0)
		tab.ColumnRight.Size = UDim2.new(1, 0, 0, 0)
		tab.ColumnLeft.Position = UDim2.new(0, 0, 0, 0)
		tab.ColumnRight.Position = UDim2.new(0, 0, 0, 0)
		if padding then padding.PaddingRight = COMPACT_SCROLLER_PAD_RIGHT end
	else
		layout.FillDirection = Enum.FillDirection.Horizontal
		tab.ColumnLeft.Size = EXPANDED_COLUMN_SIZE
		tab.ColumnRight.Size = EXPANDED_COLUMN_SIZE
		tab.ColumnLeft.Position = UDim2.new(0.512, 0, 0, 0)
		tab.ColumnRight.Position = UDim2.new(0.512, 0, 0, 0)
		if padding then padding.PaddingRight = EXPANDED_SCROLLER_PAD_RIGHT end
	end
end
-- Public: called by Window's compact mode. 
function TabGroup:SetCompact(on)
	on = on and true or false
	self._compact = on
	for _, tab in ipairs(self.Tabs) do
		self:_applyTabCompact(tab, on)
	end
end
-- A plain visual separator between groups of tabs in the sidebar.
function TabGroup:Divider()
	local theme = self._theme or {}
	local Divider = Instance.new("Frame")
	Divider.Name = "Divider"
	Divider.BorderSizePixel = 0
	-- Dividers now share the same theme keys as the Divider component
	-- (SectionDividerColor / SectionDividerTransparency) so there is ONE notion
	-- of divider styling. Falls back to the old TertiaryColor/0.5 defaults.
	Divider.BackgroundColor3 = theme.SectionDividerColor or theme.TertiaryColor
	Divider.BackgroundTransparency = theme.SectionDividerTransparency or 0.5
	Divider.Size = UDim2.new(0.85227, 0, 0, 1)
	Divider.LayoutOrder = #self.Tabs + 1
	Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Divider:SetAttribute("IsDivider", true)
	Divider.Parent = self.Window.TabList
	return Divider
end
-- Switches the active tab with fade transitions for content and title.
-- First activation fades in; subsequent switches fade out current, swap, fade in new.
-- Called by ThemeManager after a blanket CancelAll (theme switch), which
-- cancels in-flight page fades. Restores the active tab to its natural state.
function TabGroup:RestoreActiveTab()
	local tab = self.ActiveTab
	if not tab then return end
	-- Show only the active tab's fade layer; hide the rest.
	for _, other in ipairs(self.Tabs) do
		if other.FadeLayer then
			other.FadeLayer.Visible = (other == tab)
		end
	end
	if tab.FadeLayer then
		PageFade.Snap(tab.FadeLayer, 0) -- fully visible, no tween
	end
	if self.Window and self.Window.PageTitle then
		self.Window.PageTitle.TextTransparency = 0.4
	end
end

-- Apply the active/inactive tab-button visuals (bg, text, icon, indicator).
function TabGroup:_applyTabVisuals(t, active)
	-- STATE-AWARE theme properties resolve through the bindings (flip the key
	-- Active<->Inactive; the binding crossfades at its own 0.2s duration).
	local state = active and "Active" or "Inactive"
	if t._bgHandle then t._bgHandle:SetState(state) end
	if t._bgTransHandle then t._bgTransHandle:SetState(state) end
	if t._nameColorHandle then t._nameColorHandle:SetState(state) end
	if t._nameTransHandle then t._nameTransHandle:SetState(state) end
	if t._iconColorHandle then t._iconColorHandle:SetState(state) end
	if t._iconTransHandle then t._iconTransHandle:SetState(state) end
	-- Literal-constant / non-theme visuals stay imperative (their values are
	-- fixed constants, not theme keys): the backdrop reveal and the selection
	-- indicator's size + spin state.
	if active then
		Tween.Play(t.BackImage, "Fast", { ImageTransparency = 0 })
		Tween.Play(t.SelectionStatus, "OnOff", { BackgroundTransparency = 0, Size = UDim2.new(0, 2, 0.7, 0) })
		self:_resumeSpin(t.BackImageGradient, true)
	else
		Tween.Play(t.BackImage, "Fast", { ImageTransparency = 1 })
		Tween.Play(t.SelectionStatus, "OnOff", { BackgroundTransparency = 1, Size = UDim2.new(0, 2, 0, 0) })
		self:_pauseSpin(t.BackImageGradient)
	end
end

function TabGroup:SetActiveTab(tab)
	local previous = self.ActiveTab
	if previous == tab then return end
	self.ActiveTab = tab

	-- A page switch dismisses any open popup (dropdown / color picker /
	-- notification) so it can never linger over the newly shown page.
	if self.Window and self.Window.HidePopups then
		self.Window:HidePopups()
	end

	-- Keep the sidebar search consistent across a tab switch: restore the page
	-- we are leaving, then re-apply the current query to the page we enter.
	if previous and previous.ContentScroller then
		SearchFilter.Clear(previous.ContentScroller)
	end
	local w = self.Window
	if w and w.SearchBox and w.SearchBox.Text ~= "" then
		SearchFilter.Apply(tab.ContentScroller, w.SearchBox.Text, w._theme)
	end
	local title = self.Window and self.Window.PageTitle

	if previous then self:_applyTabVisuals(previous, false) end
	self:_applyTabVisuals(tab, true)

	-- While the window is faded out, don't animate page content: the window
	-- fade owns the reveal. Just swap which page is shown.
	if self.Window and self.Window._windowFaded then
		-- Window fade owns the reveal while faded. Still SNAP each layer fully
		-- to its end state: Visible alone does NOT reset GroupTransparency, so a
		-- page whose layer was left at 1 by an earlier crossfade would render
		-- blank when shown. Snapping keeps the shown page opaque and the rest
		-- hidden regardless of where their fades were interrupted.
		for _, other in ipairs(self.Tabs) do
			if other.FadeLayer then
				local isTarget = (other == tab)
				other.FadeLayer.Visible = isTarget
				PageFade.Snap(other.FadeLayer, isTarget and 0 or 1)
			end
		end
		if title then title.Text = self:_titleText(tab) end
		return
	end

	-- PAGE TRANSITION via PageFade: one CanvasGroup per tab. Nothing inside a
	-- page is transparency-faded, so component state (radio selection, slider
	-- fill, etc.) can never be stomped by a page switch.
	if previous == nil then
		-- First activation: reveal + fade in.
		tab.FadeLayer.Visible = true
		PageFade.Snap(tab.FadeLayer, 1)
		PageFade.Show(tab.FadeLayer, false)
		if title then
			title.Text = self:_titleText(tab)
			Tween.Play(title, "Fast", { TextTransparency = 0.4 })
		end
		return
	end

	-- Standardized overlapped crossfade: incoming fades in while outgoing
	-- fades out, both at PageFade.TIME so every page transition matches.
	tab.FadeLayer.Visible = true
	if title then title.Text = self:_titleText(tab) end
	PageFade.Crossfade(previous.FadeLayer, tab.FadeLayer, function()
		if previous.FadeLayer then previous.FadeLayer.Visible = false end
	end)
end

-- Title text for a tab. The tab name is rendered Medium via a rich-text
-- weight span (NOT <b>, which forces bold and ignores the label's FontFace);
-- the PageTitle base weight is Regular.
function TabGroup:_titleText(tab)
	return '<font weight="500">' .. tab.Name .. "</font>"
end

-- Component-owned theming. Called by ThemeManager via the component registry.
-- Applies tab-button, label, icon, indicator, divider, backdrop and scrollbar
-- colors directly (no animation) so the surrounding color crossfade still
-- produces the old -> new fade.
function TabGroup:ApplyTheme(newTheme)
	local theme = ThemeManager.GetTheme(newTheme)
	self._theme = theme
	for _, t in ipairs(self.Tabs) do
		t._theme = theme
		-- Tab button / label / icon colors + transparencies are now BINDINGS
		-- (see TabGroup:Tab). Their state-aware handles re-resolve on a theme
		-- switch automatically; nothing to stamp here. SetState is re-applied so
		-- the active tab picks up the new theme's key values at once.
		if t._bgHandle then t._bgHandle:SetState((t == self.ActiveTab) and "Active" or "Inactive") end
		if t._bgTransHandle then t._bgTransHandle:SetState((t == self.ActiveTab) and "Active" or "Inactive") end
		if t._nameColorHandle then t._nameColorHandle:SetState((t == self.ActiveTab) and "Active" or "Inactive") end
		if t._nameTransHandle then t._nameTransHandle:SetState((t == self.ActiveTab) and "Active" or "Inactive") end
		if t._iconColorHandle then t._iconColorHandle:SetState((t == self.ActiveTab) and "Active" or "Inactive") end
		if t._iconTransHandle then t._iconTransHandle:SetState((t == self.ActiveTab) and "Active" or "Inactive") end
		-- Wallpaper Image/Visible are NOT Color3/number and use nil-safe fallback
		-- semantics, so they stay imperative here.
		t.BackImage.Image = theme.Wallpaper or FallbackImage
		t.BackImage.Visible = theme.WallpaperEnabled ~= false
	end
	-- Tab dividers created via TabGroup:Divider()
	for _, child in ipairs(self.Window.TabList:GetChildren()) do
		if child:GetAttribute("IsDivider") then
			child.BackgroundColor3 = theme.SectionDividerColor or theme.TertiaryColor or child.BackgroundColor3
			child.BackgroundTransparency = theme.SectionDividerTransparency or child.BackgroundTransparency
		end
	end
end

return TabGroup