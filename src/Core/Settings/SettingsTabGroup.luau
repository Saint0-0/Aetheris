--[[
	Aetheris/Core/Settings/SettingsTabGroup.luau

	Docked settings tab bar of circular icon-only buttons over one column per page.
	Owns tab creation, active/inactive bindings and page crossfades.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Tween = require("../../Utils/Tween")
local Section = require("../Section")
local FallbackImage = require("../../Constants").FallbackImage
local ThemeManager = require("../../Themes/ThemeManager")
local PageFade = require("../../Utils/PageFade")
local PageAwareness = require("../../Utils/PageAwareness")
local ScrollFade = require("../../Utils/ScrollFade")
local SearchFilter = require("../SearchFilter")
local Constants = require("../../Constants")
local Locale = require("../../Utils/Locale")
local UUID = require("../../Utils/UUID")

-- Circular icon button, matching the floating minimize strip.
local TAB_SIZE = 40
local TAB_HOVER_SCALE = 1.18 -- Hover grow factor.
local TAB_PRESS_SCALE = 0.94 -- Press factor.
local BAR_HEIGHT = 56 -- Pill height.
local BAR_BOTTOM = 2 -- Pill gap; BAR_HEIGHT plus this fits in SettingsBottomReserve.
local TOOLTIP_GAP = 11

-- Shell wash multiplies what it paints; dark themes take a stronger stop.
local function isDark(color)
	return (color.R * 0.299 + color.G * 0.587 + color.B * 0.114) < 0.5
end

local function stampWash(gradient, base)
	local top = if isDark(base) then 0.9 else 0.96
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(top, top, top)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
end

-- "Settings | " is Medium and the page name Regular; the wrap re-resolves both.
local function settingsTitleWrap(resolved)
	return '<font weight="500">' .. Locale.resolve("Settings") .. " | </font>" .. resolved
end

local SettingsTabGroup = {}
SettingsTabGroup.__index = SettingsTabGroup

local SettingsTabHandle = {}
SettingsTabHandle.__index = SettingsTabHandle

function SettingsTabHandle:Section(Settings)
	Settings = Settings or {}
	-- Settings-page controls store state in SettingsStore, not ConfigManager.
	return Section.new(self._contentParent or self.Page, Settings, self._theme, self.Window, true)
end

function SettingsTabHandle:Scroller()
	if self._scroller then
		return self._scroller
	end
	local theme = self._theme or {}
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = UUID.Static("SettingsScroller")
	scroller.Active = true
	scroller.BorderSizePixel = 0
	scroller.ScrollBarImageTransparency = 1
	scroller.BackgroundTransparency = 1
	scroller.AnchorPoint = Vector2.new(0.5, 0)
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.CanvasSize = UDim2.fromScale(0, 0)
	-- Hangs from the top, clear of the docked pill bar.
	scroller.Position = UDim2.fromScale(0.5, 0)
	scroller.Size = UDim2.new(1, 0, 1, -Constants.SettingsBottomReserve)
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

	-- Content melts into the page at both scroll edges.
	ScrollFade.AttachOverlay(scroller, "ContentBackgroundColor")

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

	-- Bottom-docked pill bar over the page content.
	self.Bar = Instance.new("Frame")
	self.Bar.Name = UUID.Static("SettingsTabBar")
	self.Bar.BorderSizePixel = 0
	self.Bar.BackgroundColor3 = theme.PopupBackgroundColor or Color3.fromRGB(15, 15, 16)
	self.Bar.BackgroundTransparency = 0
	self.Bar.AnchorPoint = Vector2.new(0.5, 1)
	self.Bar.Position = UDim2.new(0.5, 0, 1, -BAR_BOTTOM)
	self.Bar.Size = UDim2.fromOffset(0, BAR_HEIGHT)
	self.Bar.AutomaticSize = Enum.AutomaticSize.X
	self.Bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
	-- Paint above the content frame so the bar cannot hide.
	self.Bar.ZIndex = 2
	self.Bar.Parent = window.SettingsPages

	-- Shell wash on the bar itself, restamped in ApplyTheme.
	local barWash = Instance.new("UIGradient")
	stampWash(barWash, self.Bar.BackgroundColor3)
	barWash.Parent = self.Bar
	self._barWash = barWash

	local BarCorner = Instance.new("UICorner")
	BarCorner.CornerRadius = UDim.new(1, 0)
	BarCorner.Parent = self.Bar

	local BarStroke = Instance.new("UIStroke")
	BarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	BarStroke.Parent = self.Bar
	ThemeManager.BindColor(self.Bar, "BackgroundColor3", "PopupBackgroundColor")
	ThemeManager.BindColor(BarStroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(BarStroke, "Transparency", "StrokeTransparency")

	local BarLayout = Instance.new("UIListLayout")
	BarLayout.Padding = UDim.new(0, 8)
	BarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	BarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	BarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	BarLayout.FillDirection = Enum.FillDirection.Horizontal
	BarLayout.Parent = self.Bar

	local BarPadding = Instance.new("UIPadding")
	BarPadding.PaddingLeft = UDim.new(0, 6)
	BarPadding.PaddingRight = UDim.new(0, 6)
	BarPadding.Parent = self.Bar

	-- Content container above the tab bar.
	self.Content = Instance.new("Frame")
	self.Content.Name = UUID.Static("SettingsContent")
	self.Content.BorderSizePixel = 0
	self.Content.BackgroundTransparency = 1
	self.Content.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Content.Position = UDim2.fromScale(0.5, 0.5)
	self.Content.Size = UDim2.fromScale(0.983, 1)
	self.Content.BorderColor3 = Color3.fromRGB(0, 0, 0)
	self.Content.Parent = window.SettingsPages

	-- Register with ThemeManager so the bar's controls theme without name-matching.
	ThemeManager.Register(self.Bar, self)

	return self
end

-- Page transitions are owned by Utils/PageFade.

-- Pause a backdrop's spin; it resumes from the same angle.
function SettingsTabGroup:_pauseSpin(gradient)
	if not gradient then
		return
	end
	Tween.PauseSpin(gradient)
end

function SettingsTabGroup:_resumeSpin(gradient, _reset)
	if not gradient then
		return
	end
	if not Tween.ResumeSpin(gradient) then
		Tween.StartSpin(gradient, { Rotation = 360 }, "SpinIdle")
	end
end

function SettingsTabGroup:Tab(Settings)
	Settings = Settings or {}
	local name = Settings.Name or "Settings"
	local isFirst = #self.Tabs == 0
	local theme = self._theme or {}

	-- Fixed-size holder so the hover scale cannot reflow the bar.
	local Holder = Instance.new("Frame")
	Holder.Name = UUID.Generate()
	Holder.BorderSizePixel = 0
	Holder.BackgroundTransparency = 1
	Holder.Size = UDim2.fromOffset(TAB_SIZE, TAB_SIZE)
	Holder.LayoutOrder = #self.Tabs + 1
	Holder.Parent = self.Bar

	local Button = Instance.new("TextButton")
	Button.Name = UUID.Generate()
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.BackgroundColor3 = theme.InactiveTabButtonColor
	Button.BackgroundTransparency = theme.InactiveTabButtonTransparency
	Button.Size = UDim2.fromScale(1, 1)
	Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Button.Text = ""
	Button.Parent = Holder

	local ButtonCorner = Instance.new("UICorner")
	ButtonCorner.CornerRadius = UDim.new(1, 0)
	ButtonCorner.Parent = Button

	-- One UIScale grows the button; press dips from the hover scale.
	local buttonScale = Instance.new("UIScale")
	buttonScale.Scale = 1
	buttonScale.Parent = Button

	local BackImage = Instance.new("ImageLabel")
	BackImage.Name = UUID.Static("BackImage")
	BackImage.BorderSizePixel = 0
	BackImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BackImage.ImageTransparency = 1
	BackImage.AnchorPoint = Vector2.new(0.5, 0.5)
	BackImage.Image = theme.Wallpaper or FallbackImage
	BackImage.Size = UDim2.fromScale(1, 1)
	BackImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BackImage.BackgroundTransparency = 1
	BackImage.Position = UDim2.fromScale(0.5, 0.5)
	BackImage.Parent = Button
	BackImage:SetAttribute(UUID.Static("IsTabBackdrop"), true)
	-- Match ApplyTheme's ~= false so construction and live switches agree.
	BackImage.Visible = theme.WallpaperEnabled ~= false

	local BackImageCorner = Instance.new("UICorner")
	BackImageCorner.CornerRadius = UDim.new(1, 0)
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

	-- White hover lift between backdrop and icon.
	local Lift = Instance.new("Frame")
	Lift.Name = UUID.Static("TabLift")
	Lift.BorderSizePixel = 0
	Lift.BackgroundColor3 = Color3.new(1, 1, 1)
	Lift.BackgroundTransparency = 1
	Lift.Size = UDim2.fromScale(1, 1)
	Lift.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Lift.Parent = Button

	local LiftCorner = Instance.new("UICorner")
	LiftCorner.CornerRadius = UDim.new(1, 0)
	LiftCorner.Parent = Lift

	local TabImage = Instance.new("ImageLabel")
	TabImage.Name = UUID.Static("TabImage")
	TabImage.BorderSizePixel = 0
	TabImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabImage.ImageTransparency = theme.InactiveTabIconTransparency
	TabImage.AnchorPoint = Vector2.new(0.5, 0.5)
	TabImage.Image = Settings.Icon or "rbxassetid://8445470392"
	TabImage.ImageColor3 = theme.InactiveTabIconColor
	TabImage.Size = UDim2.fromOffset(18, 18)
	TabImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabImage.BackgroundTransparency = 1
	TabImage.Position = UDim2.fromScale(0.5, 0.5)
	TabImage.Parent = Button

	-- Page frame for this settings page, without an automatic scroller.
	local Page = Instance.new("Frame")
	Page.Name = UUID.Generate()
	Page.BorderSizePixel = 0
	Page.BackgroundTransparency = 1
	Page.Size = UDim2.fromScale(1, 1)
	Page.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Page.Visible = true
	-- One TreeFade layer per page owns the fade; the page itself is never faded.
	local FadeLayer = PageFade.Layer(self.Content, UUID.Generate())
	FadeLayer.Visible = false
	Page.Parent = FadeLayer

	local tab = setmetatable({
		Window = self.Window,
		Name = name,
		Holder = Holder,
		Button = Button,
		BackImage = BackImage,
		BackImageGradient = BackImageGradient,
		TabImage = TabImage,
		Page = Page,
		FadeLayer = FadeLayer,
		_theme = theme,
	}, SettingsTabHandle)
	-- State-aware bindings resolve theme and page switches through one path.
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

	Button.MouseButton1Click:Connect(function()
		self:SetActiveTab(tab)
	end)

	-- Pill-style hover grow, white lift and a tooltip naming the tab.
	Button.MouseEnter:Connect(function()
		tab._hovered = true
		Tween.Play(buttonScale, "HoverIn", { Scale = TAB_HOVER_SCALE })
		Tween.Play(Lift, "Lift", { BackgroundTransparency = 0.95 })
		local tip = self.Window and self.Window.Tooltip
		if tip then
			tip:ShowAt(Button, Locale.resolve(name), "Top", TOOLTIP_GAP)
		end
	end)
	Button.MouseLeave:Connect(function()
		tab._hovered = false
		Tween.Play(buttonScale, "HoverOut", { Scale = 1 })
		Tween.Play(Lift, "Lift", { BackgroundTransparency = 1 })
		local tip = self.Window and self.Window.Tooltip
		if tip then
			tip:Hide()
		end
	end)

	-- Press dips the grown scale and springs back.
	local function heldScale(factor)
		return (tab._hovered and TAB_HOVER_SCALE or 1) * factor
	end
	Button.MouseButton1Down:Connect(function()
		Tween.Play(buttonScale, "PressIn", { Scale = heldScale(TAB_PRESS_SCALE) })
	end)
	Button.MouseButton1Up:Connect(function()
		Tween.Play(buttonScale, "PressOut", { Scale = heldScale(1) })
	end)

	table.insert(self.Tabs, tab)

	if Settings.Active or isFirst then
		self:SetActiveTab(tab)
	end

	return tab
end

function SettingsTabGroup:_applyActiveVisuals(t)
	-- State-aware properties resolve through the bindings.
	if t._bgHandle then
		t._bgHandle:SetState("Active")
	end
	if t._bgTransHandle then
		t._bgTransHandle:SetState("Active")
	end
	if t._iconColorHandle then
		t._iconColorHandle:SetState("Active")
	end
	if t._iconTransHandle then
		t._iconTransHandle:SetState("Active")
	end
	-- Constant visuals stay imperative.
	local theme = self._theme or {}
	t.BackImage.Visible = theme.WallpaperEnabled ~= false
	Tween.Play(t.BackImage, "Fast", { ImageTransparency = 0 })
	self:_resumeSpin(t.BackImageGradient)
end

function SettingsTabGroup:_applyInactiveVisuals(t)
	if t._bgHandle then
		t._bgHandle:SetState("Inactive")
	end
	if t._bgTransHandle then
		t._bgTransHandle:SetState("Inactive")
	end
	if t._iconColorHandle then
		t._iconColorHandle:SetState("Inactive")
	end
	if t._iconTransHandle then
		t._iconTransHandle:SetState("Inactive")
	end
	Tween.Play(t.BackImage, "Fast", { ImageTransparency = 1 })
	self:_pauseSpin(t.BackImageGradient)
end

-- Name the active page in the window title.
function SettingsTabGroup:RefreshTitle()
	local w = self.Window
	if not w or not w.PageTitle then
		return
	end
	local name = self.ActiveTab and self.ActiveTab.Name or "Settings"
	-- The wrap lets a live locale change re-resolve both halves.
	Locale.set(w.PageTitle, "Text", name, settingsTitleWrap)
end

function SettingsTabGroup:SetActiveTab(tab)
	local previous = self.ActiveTab
	if previous == tab then
		return
	end
	self.ActiveTab = tab
	-- The page is now decided, so fire page-awareness handlers immediately.
	PageAwareness.Refresh()
	self:RefreshTitle()

	-- A page switch dismisses any open popup.
	if self.Window and self.Window.HidePopups then
		self.Window:HidePopups()
	end

	-- Keep an active query applied while moving between settings pages.
	local w = self.Window
	if w and w.SearchBox and w.SearchBox.Text ~= "" then
		if previous and previous.Page then
			SearchFilter.Clear(previous.Page)
		end
		if tab.Page then
			SearchFilter.Apply(tab.Page, w.SearchBox.Text, w._theme)
		end
	end

	if previous == nil then
		-- First activation reveals the page and fades it in.
		tab.FadeLayer.Visible = true
		PageFade.Snap(tab.FadeLayer, 1)
		PageFade.Show(tab.FadeLayer, false)
		self:_applyActiveVisuals(tab)
		self:_resumeSpin(tab.BackImageGradient, true)
		return
	end

	-- Tab visuals swap immediately so selection feels responsive.
	self:_applyInactiveVisuals(previous)
	self:_applyActiveVisuals(tab)

	-- Crossfade like the main TabGroup, one TreeFade layer per page.
	tab.FadeLayer.Visible = true
	PageFade.Crossfade(previous.FadeLayer, tab.FadeLayer, function()
		if previous.FadeLayer then
			previous.FadeLayer.Visible = false
		end
	end)
end

-- Restore the active page after a theme switch cancels its fades.
function SettingsTabGroup:RestoreActivePage()
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

-- Apply tab-bar colors directly; the surrounding crossfade supplies the fade.
function SettingsTabGroup:ApplyTheme(newTheme)
	local theme = ThemeManager.GetTheme(newTheme)
	self._theme = theme
	-- Restamp the bar wash against the new base.
	if self._barWash then
		stampWash(self._barWash, theme.PopupBackgroundColor or Color3.fromRGB(15, 15, 16))
	end
	for _, t in ipairs(self.Tabs) do
		t._theme = theme
		-- Re-apply SetState so the active page picks up the new theme's keys.
		local state = (t == self.ActiveTab) and "Active" or "Inactive"
		if t._bgHandle then
			t._bgHandle:SetState(state)
		end
		if t._bgTransHandle then
			t._bgTransHandle:SetState(state)
		end
		if t._iconColorHandle then
			t._iconColorHandle:SetState(state)
		end
		if t._iconTransHandle then
			t._iconTransHandle:SetState(state)
		end
		-- Wallpaper image and visibility stay imperative.
		t.BackImage.Image = theme.Wallpaper or FallbackImage
		t.BackImage.Visible = theme.WallpaperEnabled ~= false
	end
end

return SettingsTabGroup
