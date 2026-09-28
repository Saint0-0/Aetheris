--[[
	SettingsTabGroup  ·  Aetheris UI Library

	Horizontal settings tab bar inside SettingsPages. Mirrors Core/TabGroup
	mechanics: spinning-gradient back images, a SelectionStatus indicator,
	active/inactive theme keys, and a per-tab SINGLE-COLUMN content area.
	(Unlike Core/TabGroup, settings pages have no left/right split.)
]]

local Tween = require("../../Utils/Tween")
local Section = require("../Section")
local FallbackImage = require("../../Constants").FallbackImage
local ThemeManager = require("../../Themes/ThemeManager")
local PageFade = require("../../Utils/PageFade")
local Constants = require("../../Constants")

local SettingsTabGroup = {}
SettingsTabGroup.__index = SettingsTabGroup

local SettingsTabHandle = {}
SettingsTabHandle.__index = SettingsTabHandle

function SettingsTabHandle:Section(Settings)
	Settings = Settings or {}
	-- Sections go straight into the page (single vertical column). If a
	-- scroller has been set up via :Scroller(), they stack into that instead.
	return Section.new(self._contentParent or self.Page, Settings, self._theme, self.Window)
end

-- Optional single-column scroller for this page. Settings pages are ONE
-- column (no left/right split); call :Scroller() once to get an auto-sizing
-- scrolling area, then every :Section() stacks into it top-to-bottom. The
-- default pages (Themes/UISettings) build their own equivalent by hand.
function SettingsTabHandle:Scroller()
	if self._scroller then
		return self._scroller
	end
	local theme = self._theme or {}
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "SettingsScroller"
	scroller.Active = true
	scroller.BorderSizePixel = 0
	scroller.ScrollBarImageTransparency = 1 -- hidden until scrolling
	scroller.BackgroundTransparency = 1
	scroller.AnchorPoint = Vector2.new(0.5, 0.5)
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroller.Size = UDim2.new(1, 0, 0.879, 0)
	scroller.Position = UDim2.new(0.5, 0, 0.561, 0)
	scroller.BorderColor3 = Color3.fromRGB(0, 0, 0)
	scroller.ScrollBarThickness = 1
	scroller.ScrollBarImageColor3 = theme.TertiaryColor or Color3.fromRGB(160, 160, 160)
	scroller.LayoutOrder = 1
	scroller.Parent = self.Page

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroller

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 5)
	padding.PaddingRight = UDim.new(0, 15)
	padding.Parent = scroller

	-- Scrollbar: only visible while scrolling, matching the other settings pages.
	local scrollTimer
	scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		Tween.Play(scroller, "Fast", { ScrollBarImageTransparency = 0.5 })
		if scrollTimer then
			task.cancel(scrollTimer)
		end
		scrollTimer = task.delay(1.5, function()
			Tween.Play(scroller, "Fast", { ScrollBarImageTransparency = 1 })
			scrollTimer = nil
		end)
	end)

	self._scroller = scroller
	self._contentParent = scroller
	return scroller
end

function SettingsTabGroup.new(window, theme)
	theme = ThemeManager.GetTheme(theme)
	local self = setmetatable({}, SettingsTabGroup)
	self.Window = window
	self._theme = theme or {}
	self.Tabs = {}
	self.ActiveTab = nil
	self._transitioning = false
	self._spinHandles = {}

	-- Horizontal tab bar at the top of SettingsPages
	self.Bar = Instance.new("Frame")
	self.Bar.Name = "SettingsTabBar"
	self.Bar.BorderSizePixel = 0
	self.Bar.BackgroundTransparency = 1
	self.Bar.Size = UDim2.new(1, 0, 0.07969, 0)
	self.Bar.Position = UDim2.new(0, 0, 0, 6)
	self.Bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
	self.Bar.Parent = window.SettingsPages

	local BarLayout = Instance.new("UIListLayout")
	BarLayout.Padding = UDim.new(0, 12)
	BarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	BarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	BarLayout.FillDirection = Enum.FillDirection.Horizontal
	BarLayout.Parent = self.Bar

	local BarPadding = Instance.new("UIPadding")
	BarPadding.PaddingLeft = UDim.new(0, 7)
	BarPadding.Parent = self.Bar

	-- Content container below the tab bar
	self.Content = Instance.new("Frame")
	self.Content.Name = "SettingsContent"
	self.Content.BorderSizePixel = 0
	self.Content.BackgroundTransparency = 1
	self.Content.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Content.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.Content.Size = UDim2.new(0.983, 0, 1, 0)
	self.Content.BorderColor3 = Color3.fromRGB(0, 0, 0)
	self.Content.Parent = window.SettingsPages

	-- Register with ThemeManager (root = the tab bar) so this group's tab
	-- buttons, labels, icons, indicators and backdrops are themed without
	-- name-matching. The bar lives under window.Base.
	ThemeManager.Register(self.Bar, self)

	return self
end

-- Snapshot every element's base transparencies. This is only valid while
-- the page is in its NATURAL (un-faded) state, so it is captured fresh each
-- time the page is natural -- pages whose content is added after creation
-- (e.g. the Themes page) are then captured fully instead of as empty.
-- (Page transitions are handled entirely by Utils/PageFade now: one
-- CanvasGroup per settings page, faded via PageFade.Crossfade/Show/Snap. The
-- old per-element transparency cache functions were removed.)

-- Settings-tab backdrop spins route through the CENTRAL spin system so the
-- global Tween.SetSpinsEnabled toggle controls them. Inactive page backdrops
-- are PAUSED (angle preserved), not stopped.
function SettingsTabGroup:_pauseSpin(gradient)
	if not gradient then return end
	Tween.PauseSpin(gradient)
end

function SettingsTabGroup:_resumeSpin(gradient, reset)
	if not gradient then return end
	if not Tween.ResumeSpin(gradient) then
		Tween.StartSpin(gradient, { Rotation = 360 }, "SpinIdle")
	end
end

function SettingsTabGroup:Tab(Settings)
	Settings = Settings or {}
	local name = Settings.Name or "Settings"
	local isFirst = #self.Tabs == 0
	local theme = self._theme or {}

	-- Tab button
	local Button = Instance.new("TextButton")
	Button.Name = name .. "SettingsTab"
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.BackgroundColor3 = theme.InactiveTabButtonColor
	Button.BackgroundTransparency = theme.InactiveTabButtonTransparency
	Button.Size = UDim2.new(0.169, 0, 0.83, 0)
	Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Button.Text = ""
	Button.LayoutOrder = #self.Tabs + 1
	Button.Parent = self.Bar

	local ButtonCorner = Instance.new("UICorner")
	ButtonCorner.CornerRadius = UDim.new(0, 4)
	ButtonCorner.Parent = Button

	local TabName = Instance.new("TextLabel")
	TabName.Name = "TabName"
	TabName.BorderSizePixel = 0
	TabName.TextSize = 11
	TabName.TextXAlignment = Enum.TextXAlignment.Left
	TabName.TextTransparency = theme.InactiveTabTextTransparency
	TabName.FontFace = Constants.Font(Enum.FontWeight.Medium)
	TabName.TextColor3 = theme.InactiveTabTextColor
	TabName.BackgroundTransparency = 1
	TabName.AnchorPoint = Vector2.new(0.5, 0.5)
	TabName.Size = UDim2.new(0.73078, 0, 0.71359, 0)
	TabName.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabName.Text = name
	TabName.Position = UDim2.new(0.647, 0, 0.5, 0)
	TabName.Parent = Button

	local BackImage = Instance.new("ImageLabel")
	BackImage.Name = "BackImage"
	BackImage.BorderSizePixel = 0
	BackImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BackImage.ImageTransparency = 1
	BackImage.AnchorPoint = Vector2.new(0.5, 0.5)
	BackImage.Image = theme.Wallpaper or FallbackImage
	BackImage.Size = UDim2.new(1, 0, 1, 0)
	BackImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BackImage.BackgroundTransparency = 1
	BackImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	BackImage.Parent = Button
	BackImage:SetAttribute("IsTabBackdrop", true)
	-- Match SettingsTabGroup:ApplyTheme's `~= false` form so construction and a
	-- live theme switch agree on WallpaperEnabled (nil => shown).
	BackImage.Visible = theme.WallpaperEnabled ~= false

	local BackImageCorner = Instance.new("UICorner")
	BackImageCorner.CornerRadius = UDim.new(0, 4)
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
	TabImage.Size = UDim2.new(0, 12, 0, 12)
	TabImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabImage.BackgroundTransparency = 1
	TabImage.Position = UDim2.new(0, 6, 0.5, 0)
	TabImage.Parent = Button

	local SelectionStatus = Instance.new("Frame")
	SelectionStatus.Name = "SelectionStatus"
	SelectionStatus.BorderSizePixel = 0
	SelectionStatus.BackgroundColor3 = theme.SecondaryColor
	SelectionStatus.BackgroundTransparency = 1
	SelectionStatus.AnchorPoint = Vector2.new(0.5, 0.5)
	SelectionStatus.Size = UDim2.new(0, 2, 0, 0)
	SelectionStatus.Position = UDim2.new(0, -5, 0.5, 0)
	SelectionStatus.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SelectionStatus.Parent = Button

	-- Simple page frame for this settings page (no automatic scroller)
	local Page = Instance.new("Frame")
	Page.Name = name
	Page.BorderSizePixel = 0
	Page.BackgroundTransparency = 1
	Page.Size = UDim2.new(1, 0, 1, 0)
	Page.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Page.Visible = true
	-- Page transition layer: ONE CanvasGroup per settings page owns the fade
	-- (see Utils/PageFade). The Page itself is never transparency-faded, so
	-- component state encoded as transparency can never be stomped.
	local FadeLayer = PageFade.Layer(self.Content, name .. "SettingsPage")
	FadeLayer.Visible = false
	Page.Parent = FadeLayer

	local tab = setmetatable({
		Window = self.Window,
		Name = name,
		Button = Button,
		TabName = TabName,
		BackImage = BackImage,
		BackImageGradient = BackImageGradient,
		TabImage = TabImage,
		SelectionStatus = SelectionStatus,
		Page = Page,
		FadeLayer = FadeLayer,
		_theme = theme,
	}, SettingsTabHandle)
	-- Declarative STATE-AWARE theming for the settings tab button visuals.
	-- Same pattern as Core/TabGroup: each handle flips Active<->Inactive via
	-- SetState, so both a theme switch and a page switch resolve through the
	-- binding system. duration = 0.2 matches the old "Fast" preset.
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
	-- Static (state-independent) bind.
	ThemeManager.BindColor(SelectionStatus, "BackgroundColor3", "SecondaryColor")

	Button.MouseButton1Click:Connect(function()
		self:SetActiveTab(tab)
	end)

	table.insert(self.Tabs, tab)

	if Settings.Active or isFirst then
		self:SetActiveTab(tab)
	end

	return tab
end

function SettingsTabGroup:_applyActiveVisuals(t)
	-- STATE-AWARE theme properties resolve through the bindings.
	if t._bgHandle then t._bgHandle:SetState("Active") end
	if t._bgTransHandle then t._bgTransHandle:SetState("Active") end
	if t._nameColorHandle then t._nameColorHandle:SetState("Active") end
	if t._nameTransHandle then t._nameTransHandle:SetState("Active") end
	if t._iconColorHandle then t._iconColorHandle:SetState("Active") end
	if t._iconTransHandle then t._iconTransHandle:SetState("Active") end
	-- Non-theme / constant visuals stay imperative.
	local theme = self._theme or {}
	t.BackImage.Visible = theme.WallpaperEnabled ~= false
	Tween.Play(t.BackImage, "Fast", { ImageTransparency = 0 })
	Tween.Play(t.SelectionStatus, "OnOff", { BackgroundTransparency = 0, Size = UDim2.new(0, 2, 0.7, 0) })
	self:_resumeSpin(t.BackImageGradient)
end

function SettingsTabGroup:_applyInactiveVisuals(t)
	if t._bgHandle then t._bgHandle:SetState("Inactive") end
	if t._bgTransHandle then t._bgTransHandle:SetState("Inactive") end
	if t._nameColorHandle then t._nameColorHandle:SetState("Inactive") end
	if t._nameTransHandle then t._nameTransHandle:SetState("Inactive") end
	if t._iconColorHandle then t._iconColorHandle:SetState("Inactive") end
	if t._iconTransHandle then t._iconTransHandle:SetState("Inactive") end
	Tween.Play(t.BackImage, "Fast", { ImageTransparency = 1 })
	Tween.Play(t.SelectionStatus, "OnOff", { BackgroundTransparency = 1, Size = UDim2.new(0, 2, 0, 0) })
	self:_pauseSpin(t.BackImageGradient)
end

-- Update Window.PageTitle to "Settings | <page>" for the active page.
function SettingsTabGroup:RefreshTitle()
	local w = self.Window
	if not w or not w.PageTitle then return end
	local name = self.ActiveTab and self.ActiveTab.Name or "Settings"
	-- "Settings | " is Medium (weight 500); the page name stays Regular.
	w.PageTitle.Text = '<font weight="500">Settings | </font>' .. name
end

function SettingsTabGroup:SetActiveTab(tab)
	local previous = self.ActiveTab
	if previous == tab then
		return
	end
	self.ActiveTab = tab
	self:RefreshTitle()

	-- A page switch dismisses any open popup, same as the main TabGroup.
	if self.Window and self.Window.HidePopups then
		self.Window:HidePopups()
	end

	if previous == nil then
		-- First activation: reveal + fade in.
		tab.FadeLayer.Visible = true
		PageFade.Snap(tab.FadeLayer, 1)
		PageFade.Show(tab.FadeLayer, false)
		self:_applyActiveVisuals(tab)
		self:_resumeSpin(tab.BackImageGradient, true)
		return
	end

	-- Tab-button visuals swap immediately so selection feels responsive.
	self:_applyInactiveVisuals(previous)
	self:_applyActiveVisuals(tab)

	-- Standardized crossfade, IDENTICAL to the main TabGroup: incoming fades
	-- in while outgoing fades out, both over PageFade.TIME. Uses one
	-- CanvasGroup per page, so nothing inside a page is transparency-faded.
	tab.FadeLayer.Visible = true
	PageFade.Crossfade(previous.FadeLayer, tab.FadeLayer, function()
		if previous.FadeLayer then previous.FadeLayer.Visible = false end
	end)
end

-- Called by ThemeManager after a blanket CancelAll (theme switches cancel
-- every tween, including in-flight page fades). Restores the active page to
-- its natural state so nothing is left stuck transparent.
function SettingsTabGroup:RestoreActivePage()
	local tab = self.ActiveTab
	if not tab then return end
	for _, other in ipairs(self.Tabs) do
		if other.FadeLayer then
			other.FadeLayer.Visible = (other == tab)
		end
	end
	if tab.FadeLayer then
		PageFade.Snap(tab.FadeLayer, 0) -- fully visible, no tween
	end
	self:RefreshTitle()
end

function SettingsTabGroup:SetActiveTabByName(name)
	for _, tab in ipairs(self.Tabs) do
		if tab.Name == name then
			self:SetActiveTab(tab)
			return tab
		end
	end
	return nil
end

-- Component-owned theming. Called by ThemeManager via the component registry.
-- Applies the tab-bar colors directly (no animation) so the surrounding color
-- crossfade still produces the old -> new fade.
function SettingsTabGroup:ApplyTheme(newTheme)
	local theme = ThemeManager.GetTheme(newTheme)
	self._theme = theme
	for _, t in ipairs(self.Tabs) do
		t._theme = theme
		-- Tab button / label / icon colors + transparencies are BINDINGS now;
		-- re-apply SetState so the active page picks up the new theme's keys.
		local state = (t == self.ActiveTab) and "Active" or "Inactive"
		if t._bgHandle then t._bgHandle:SetState(state) end
		if t._bgTransHandle then t._bgTransHandle:SetState(state) end
		if t._nameColorHandle then t._nameColorHandle:SetState(state) end
		if t._nameTransHandle then t._nameTransHandle:SetState(state) end
		if t._iconColorHandle then t._iconColorHandle:SetState(state) end
		if t._iconTransHandle then t._iconTransHandle:SetState(state) end
		-- Wallpaper Image/Visible stay imperative (not Color3/number).
		t.BackImage.Image = theme.Wallpaper or FallbackImage
		t.BackImage.Visible = theme.WallpaperEnabled ~= false
	end
end

return SettingsTabGroup