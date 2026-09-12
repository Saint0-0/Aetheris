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
local VideoFade = require("../Utils/VideoFade")
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
	self._fadeCaches = {}
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
function TabGroup:_captureCache(tab)
	local cache = {}
	local function scan(instance)
		-- Video fade handle (UIGradient tagged by the Video component).
		if instance:IsA("UIGradient") and instance:GetAttribute("IsVideoFade") then
			table.insert(cache, {instance = instance, isVideo = true, base = VideoFade.get(instance)})
			return
		end
		local props = {}
		local function addProp(propName)
			local success, value = pcall(function() return instance[propName] end)
			if success and value ~= nil then
				table.insert(props, {propName, value})
			end
		end
		if instance:IsA("GuiObject") then
			addProp("BackgroundTransparency")
			addProp("TextTransparency")
			addProp("ImageTransparency")
		end
		if instance:IsA("UIStroke") or instance:IsA("UIShadow") then
			addProp("Transparency")
		end
		if #props > 0 then
			table.insert(cache, {instance = instance, props = props})
		end
		for _, child in ipairs(instance:GetChildren()) do
			scan(child)
		end
	end
	scan(tab.ContentScroller)
	return cache
end
-- A tab's base transparencies are captured ONCE, then reused forever.
-- INVARIANT: tab content always rests at its base (hidden tabs are just
-- Visible=false, NOT faded to 1). That makes a single capture permanently
-- valid, so the window fade can snapshot/restore any tab without guards.
function TabGroup:_getFadeCache(tab)
	if tab._cache then
		return tab._cache
	end
	-- Don't snapshot while the window is faded out (everything reads 1 then).
	if self.Window and not self.Window.MainFrame.Visible then
		return {}
	end
	tab._cache = self:_captureCache(tab)
	return tab._cache
end

-- Capture every tab's base now, while all content is still natural. Called
-- before the window fades out so the window fade always has valid bases.
function TabGroup:PrimeCaches()
	for _, t in ipairs(self.Tabs) do
		if not t._cache then
			t._cache = self:_captureCache(t)
		end
	end
end
-- Fade all elements in a cache to a target transparency or back to base.
-- targetTransparency: number or nil (revert to base). instant: set immediately.
function TabGroup:_fadeElements(cache, targetTransparency, callback, instant)
	if not cache or #cache == 0 then
		if callback then callback() end
		return
	end
	local total = 0
	local completed = 0
	local function onComplete()
		completed = completed + 1
		if completed >= total and callback then
			callback()
		end
	end
	for _, entry in ipairs(cache) do
		local instance = entry.instance
		if entry.isVideo then
			if instance.Parent then
				local target = targetTransparency
				if target == nil then target = entry.base end
				if instant then
					VideoFade.set(instance, target)
				else
					total = total + 1
					VideoFade.fade(instance, target, 0.2, "Out", onComplete)
				end
			end
		elseif instance.Parent then
			for _, propInfo in ipairs(entry.props) do
				local prop = propInfo[1]
				local base = propInfo[2]
				local target = targetTransparency
				if target == nil then
					target = base
				end
				if instant then
					instance[prop] = target
				elseif instance[prop] ~= target then
					total = total + 1
					local handle = Tween.Play(instance, "Fast", {[prop] = target})
					handle.Tween.Completed:Connect(onComplete)
				end
			end
		end
	end
	if total == 0 and callback then
		callback()
	end
end
-- Tab backdrop spins route through the CENTRAL spin system (Tween.StartSpin)
-- so the global Tween.SetSpinsEnabled toggle controls them too. Only the active
-- tab is registered (pausing on switch unregisters it), so a global restart
-- only resumes the visible tab.
function TabGroup:_pauseSpin(gradient)
	Tween.StopSpin(gradient)
end
-- If reset is true, set rotation to 0 before starting (first activation).
-- StartSpin handles the disabled case (registers + resets but does not tween),
-- so re-enabling via Tween.SetSpinsEnabled(true) restarts the active tab too.
function TabGroup:_resumeSpin(gradient, reset)
	Tween.StartSpin(gradient, { Rotation = 360 }, "SpinIdle")
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
	TabName.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
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
	-- Set visibility based on current theme's WallpaperEnabled
	BackImage.Visible = theme.WallpaperEnabled
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
	ContentScroller.Visible = false -- SetActive() below shows the initial one
	ContentScroller.Parent = self.Window.TabContent
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
		ColumnLeft = ColumnLeft,
		ColumnRight = ColumnRight,
		_theme = theme,
	}, TabHandle)
	Button.MouseButton1Click:Connect(function()
		-- Close the settings page and return to normal tab content.
		self.Window.SettingsPages.Visible = false
		self.Window.TabContent.Visible = true
		self:SetActiveTab(tab)
	end)
	table.insert(self.Tabs, tab)
	if Settings.Active or isFirst then
		self:SetActiveTab(tab)
	end
	return tab
end
-- A plain visual separator between groups of tabs in the sidebar.
function TabGroup:Divider()
	local theme = self._theme or {}
	local Divider = Instance.new("Frame")
	Divider.Name = "Divider"
	Divider.BorderSizePixel = 0
	Divider.BackgroundColor3 = theme.TertiaryColor
	Divider.BackgroundTransparency = 0.5 -- fixed; not theme-driven
	Divider.Size = UDim2.new(0.85227, 0, 0, 1)
	Divider.LayoutOrder = #self.Tabs + 1
	Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Divider:SetAttribute("IsDivider", true)
	Divider.Parent = self.Window.TabList
	return Divider
end
-- Instantly re-apply every tab button's active/inactive visuals. Used after a
-- minimize/restore, where the window fade overwrote the tab button transparencies.
function TabGroup:RefreshVisuals()
	local theme = self._theme or {}
	for _, t in ipairs(self.Tabs) do
		local isActive = (t == self.ActiveTab)
		if isActive then
			Tween.Play(t.Button, "Fast", { BackgroundColor3 = theme.ActiveTabButtonColor, BackgroundTransparency = theme.ActiveTabButtonTransparency })
			Tween.Play(t.TabName, "Fast", { TextTransparency = theme.ActiveTabTextTransparency or 0.2, TextColor3 = theme.ActiveTabTextColor or Color3.fromRGB(255, 255, 255) })
			Tween.Play(t.BackImage, "Fast", { ImageTransparency = 0 })
			Tween.Play(t.TabImage, "Fast", { ImageTransparency = theme.ActiveTabIconTransparency or 0.2, ImageColor3 = theme.ActiveTabIconColor or Color3.fromRGB(255, 255, 255) })
			Tween.Play(t.SelectionStatus, "OnOff", { BackgroundTransparency = 0, Size = UDim2.new(0, 2, 0.7, 0) })
			self:_resumeSpin(t.BackImageGradient, true)
		else
			Tween.Play(t.Button, "Fast", { BackgroundColor3 = theme.InactiveTabButtonColor, BackgroundTransparency = theme.InactiveTabButtonTransparency })
			Tween.Play(t.TabName, "Fast", { TextTransparency = theme.InactiveTabTextTransparency or 0.6, TextColor3 = theme.InactiveTabTextColor or Color3.fromRGB(200, 200, 200) })
			Tween.Play(t.BackImage, "Fast", { ImageTransparency = 1 })
			Tween.Play(t.TabImage, "Fast", { ImageTransparency = theme.InactiveTabIconTransparency or 0.6, ImageColor3 = theme.InactiveTabIconColor or Color3.fromRGB(200, 200, 200) })
			Tween.Play(t.SelectionStatus, "OnOff", { BackgroundTransparency = 1, Size = UDim2.new(0, 2, 0, 0) })
			self:_pauseSpin(t.BackImageGradient)
		end
	end
end

-- Switches the active tab with fade transitions for content and title.
-- First activation fades in; subsequent switches fade out current, swap, fade in new.
-- Called by ThemeManager after a blanket CancelAll (theme switch), which
-- cancels in-flight page fades. Restores the active tab to its natural state.
function TabGroup:RestoreActiveTab()
	local tab = self.ActiveTab
	if not tab then return end
	for _, other in ipairs(self.Tabs) do
		if other ~= tab then
			other.ContentScroller.Visible = false
		end
	end
	local cache = self:_getFadeCache(tab)
	tab.ContentScroller.Visible = true
	self:_fadeElements(cache, nil, nil, true)
	tab._faded = false
	if self.Window and self.Window.PageTitle then
		self.Window.PageTitle.TextTransparency = 0.4
	end
end

-- Apply the active/inactive tab-button visuals (bg, text, icon, indicator).
function TabGroup:_applyTabVisuals(t, active)
	local theme = self._theme or {}
	if active then
		Tween.Play(t.Button, "Fast", { BackgroundColor3 = theme.ActiveTabButtonColor, BackgroundTransparency = theme.ActiveTabButtonTransparency })
		Tween.Play(t.TabName, "Fast", { TextTransparency = theme.ActiveTabTextTransparency or 0.2, TextColor3 = theme.ActiveTabTextColor or Color3.fromRGB(255, 255, 255) })
		Tween.Play(t.BackImage, "Fast", { ImageTransparency = 0 })
		Tween.Play(t.TabImage, "Fast", { ImageTransparency = theme.ActiveTabIconTransparency or 0.2, ImageColor3 = theme.ActiveTabIconColor or Color3.fromRGB(255, 255, 255) })
		Tween.Play(t.SelectionStatus, "OnOff", { BackgroundTransparency = 0, Size = UDim2.new(0, 2, 0.7, 0) })
		self:_resumeSpin(t.BackImageGradient, true)
	else
		Tween.Play(t.Button, "Fast", { BackgroundColor3 = theme.InactiveTabButtonColor, BackgroundTransparency = theme.InactiveTabButtonTransparency })
		Tween.Play(t.TabName, "Fast", { TextTransparency = theme.InactiveTabTextTransparency or 0.6, TextColor3 = theme.InactiveTabTextColor or Color3.fromRGB(200, 200, 200) })
		Tween.Play(t.BackImage, "Fast", { ImageTransparency = 1 })
		Tween.Play(t.TabImage, "Fast", { ImageTransparency = theme.InactiveTabIconTransparency or 0.6, ImageColor3 = theme.InactiveTabIconColor or Color3.fromRGB(200, 200, 200) })
		Tween.Play(t.SelectionStatus, "OnOff", { BackgroundTransparency = 1, Size = UDim2.new(0, 2, 0, 0) })
		self:_pauseSpin(t.BackImageGradient)
	end
end

function TabGroup:SetActiveTab(tab)
	local previous = self.ActiveTab
	if previous == tab then return end
	self.ActiveTab = tab

	-- Keep the sidebar search consistent across a tab switch: restore the page
	-- we are leaving, then re-apply the current query to the page we enter.
	if previous and previous.ContentScroller then
		SearchFilter.Clear(previous.ContentScroller)
	end
	local w = self.Window
	if w and w.SearchBox and w.SearchBox.Text ~= "" then
		SearchFilter.Apply(tab.ContentScroller, w.SearchBox.Text, w._theme)
	end
	local theme = self._theme or {}
	if not next(theme) then
		theme = ThemeManager.GetTheme(nil)
		self._theme = theme
	end
	local title = self.Window and self.Window.PageTitle

	if previous then self:_applyTabVisuals(previous, false) end
	self:_applyTabVisuals(tab, true)

	-- While the window is faded out, don't animate page content: the window fade
	-- owns the reveal. Just swap which page is shown and update the title. Every
	-- page rests at its base transparency (see _getFadeCache invariant), so the
	-- window restore will bring the chosen page in correctly.
	if self.Window and self.Window._windowFaded then
		for _, other in ipairs(self.Tabs) do
			other.ContentScroller.Visible = (other == tab)
		end
		if title then title.Text = self:_titleText(tab) end
		return
	end

	local newCache = self:_getFadeCache(tab)

	if previous == nil then
		-- First activation: reveal hidden, fade in.
		tab.ContentScroller.Visible = true
		self:_fadeElements(newCache, 1, nil, true)
		if title then title.TextTransparency = 1 end
		self:_fadeElements(newCache, nil, nil, false)
		if title then
			title.Text = self:_titleText(tab)
			Tween.Play(title, "Fast", { TextTransparency = 0.4 })
		end
		return
	end

	-- Crossfade: fade the outgoing page out, swap, fade the incoming page in.
	-- The outgoing page is snapped back to its base after hiding, keeping the
	-- "every page rests at base" invariant intact.
	local prevCache = self:_getFadeCache(previous)
	self:_fadeElements(newCache, 1, nil, true)
	tab.ContentScroller.Visible = false
	if title then Tween.Play(title, "Fast", { TextTransparency = 1 }) end
	self:_fadeElements(prevCache, 1, function()
		previous.ContentScroller.Visible = false
		self:_fadeElements(prevCache, nil, nil, true) -- restore base while hidden
		tab.ContentScroller.Visible = true
		if title then title.Text = self:_titleText(tab) end
		self:_fadeElements(newCache, nil, nil, false)
		if title then Tween.Play(title, "Fast", { TextTransparency = 0.4 }) end
	end, false)
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
		local isActive = (t == self.ActiveTab)
		if isActive then
			t.Button.BackgroundColor3 = theme.ActiveTabButtonColor or t.Button.BackgroundColor3
			if theme.ActiveTabButtonTransparency ~= nil then
				t.Button.BackgroundTransparency = theme.ActiveTabButtonTransparency
			end
			t.TabName.TextColor3 = theme.ActiveTabTextColor or t.TabName.TextColor3
			if theme.ActiveTabTextTransparency ~= nil then
				t.TabName.TextTransparency = theme.ActiveTabTextTransparency
			end
			t.TabImage.ImageColor3 = theme.ActiveTabIconColor or t.TabImage.ImageColor3
			if theme.ActiveTabIconTransparency ~= nil then
				t.TabImage.ImageTransparency = theme.ActiveTabIconTransparency
			end
		else
			t.Button.BackgroundColor3 = theme.InactiveTabButtonColor or t.Button.BackgroundColor3
			if theme.InactiveTabButtonTransparency ~= nil then
				t.Button.BackgroundTransparency = theme.InactiveTabButtonTransparency
			end
			t.TabName.TextColor3 = theme.InactiveTabTextColor or t.TabName.TextColor3
			if theme.InactiveTabTextTransparency ~= nil then
				t.TabName.TextTransparency = theme.InactiveTabTextTransparency
			end
			t.TabImage.ImageColor3 = theme.InactiveTabIconColor or t.TabImage.ImageColor3
			if theme.InactiveTabIconTransparency ~= nil then
				t.TabImage.ImageTransparency = theme.InactiveTabIconTransparency
			end
		end
		t.SelectionStatus.BackgroundColor3 = theme.SecondaryColor or t.SelectionStatus.BackgroundColor3
		t.BackImage.Image = theme.Wallpaper or FallbackImage
		t.BackImage.Visible = theme.WallpaperEnabled ~= false
		t.ContentScroller.ScrollBarImageColor3 = theme.TertiaryColor or t.ContentScroller.ScrollBarImageColor3
	end
	-- Tab dividers created via TabGroup:Divider()
	for _, child in ipairs(self.Window.TabList:GetChildren()) do
		if child:GetAttribute("IsDivider") then
			child.BackgroundColor3 = theme.TertiaryColor or child.BackgroundColor3
		end
	end
end

return TabGroup