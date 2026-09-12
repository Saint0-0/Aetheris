--[[
	UISettings  ·  Aetheris UI Library

	Builds the "UI Settings" page: minimize keybind, spinning-animation toggle,
	confirm-on-close toggle, UI scale slider, UI volume slider, and reset layout.
	UISettings.Build(window, tab) is called by Settings/Init.BuildDefaultPages.
]]

local Tween = require("../../Utils/Tween")
local Toggle = require("../../Components/Toggle")
local Keybind = require("../../Components/Keybind")
local Slider = require("../../Components/Slider")
local Button = require("../../Components/Button")
local Sound = require("../../Utils/Sound")
local SettingsStore = require("./SettingsStore")
local ThemeManager = require("../../Themes/ThemeManager")

local UISettings = {}

function UISettings.Build(window, tab)
	local theme = window._theme or {}
	local page = tab.Page

	page.Name = "UISettings"
	page.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	page.BackgroundTransparency = 1
	page.AnchorPoint = Vector2.new(0.5, 0.5)
	page.Size = UDim2.new(1, 0, 0.87857, 0)
	page.Position = UDim2.new(0.5, 0, 0.56071, 0)
	page.LayoutOrder = 1

	local pageLayout = Instance.new("UIListLayout")
	pageLayout.Padding = UDim.new(0, 10)
	pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pageLayout.Parent = page

	local pagePadding = Instance.new("UIPadding")
	pagePadding.PaddingTop = UDim.new(0, 10)
	pagePadding.PaddingLeft = UDim.new(0, 5)
	pagePadding.Parent = page

	local settingsScroller = Instance.new("ScrollingFrame")
	settingsScroller.Name = "SettingsScroller"
	settingsScroller.Active = true
	settingsScroller.BorderSizePixel = 0
	settingsScroller.ScrollBarImageTransparency = 1 -- hidden until scrolling
	settingsScroller.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	settingsScroller.BackgroundTransparency = 1
	settingsScroller.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	settingsScroller.Size = UDim2.new(1, 0, 0.87, 0)
	settingsScroller.Position = UDim2.new(0.5, 0, 0.532, 0)
	settingsScroller.BorderColor3 = Color3.fromRGB(0, 0, 0)
	settingsScroller.ScrollBarThickness = 1
	settingsScroller.ScrollBarImageColor3 = theme.TertiaryColor or Color3.fromRGB(160, 160, 160)
	settingsScroller.LayoutOrder = 1
	settingsScroller.Parent = page

	-- Scrollbar: only visible while scrolling, matching the main sidebar.
	local scrollerScrollbarTimer
	settingsScroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		Tween.Play(settingsScroller, "Fast", { ScrollBarImageTransparency = 0.5 })
		if scrollerScrollbarTimer then
			task.cancel(scrollerScrollbarTimer)
		end
		scrollerScrollbarTimer = task.delay(1.5, function()
			Tween.Play(settingsScroller, "Fast", { ScrollBarImageTransparency = 1 })
			scrollerScrollbarTimer = nil
		end)
	end)

	local scrollerLayout = Instance.new("UIListLayout")
	scrollerLayout.Padding = UDim.new(0, 6)
	scrollerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollerLayout.Parent = settingsScroller

	local scrollerPadding = Instance.new("UIPadding")
	scrollerPadding.PaddingRight = UDim.new(0, 15)
	scrollerPadding.PaddingLeft = UDim.new(0, 5)
	scrollerPadding.Parent = settingsScroller

	local pageTitle = Instance.new("TextLabel")
	pageTitle.Name = "PageTitle"
	pageTitle.TextWrapped = true
	pageTitle.BorderSizePixel = 0
	pageTitle.TextSize = 15
	pageTitle.TextXAlignment = Enum.TextXAlignment.Left
	pageTitle.TextTransparency = 0.4
	pageTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	pageTitle.BackgroundTransparency = 1
	pageTitle.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	pageTitle.TextColor3 = theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
	pageTitle.RichText = true
	pageTitle.Size = UDim2.new(0.17008, 0, 0.06723, 0)
	pageTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
	pageTitle.Text = "UI Settings"
	pageTitle.AutomaticSize = Enum.AutomaticSize.X
	pageTitle.Parent = page

	local pageTitlePadding = Instance.new("UIPadding")
	pageTitlePadding.PaddingBottom = UDim.new(0, 10)
	pageTitlePadding.Parent = pageTitle

	-- Minimize keybind: pressing the bound key minimizes the UI, or restores it
	-- to whatever page was showing before (minimize never changes the page).
	-- A blank bind = no key. The default comes from CreateWindow's MinimizeKey.
	local boundKey = window._minimizeKey
	-- The Keybind dispatches gameplay presses itself: Callback fires when the
	-- bound key is PRESSED, OnRebind when the bind changes. No external registry
	-- or listener is needed; the row is destroyed with the window, so dispatch
	-- stops automatically on close (see Keybind.lua).
	Keybind.new(settingsScroller, {
		Name = "Minimize UI",
		Default = boundKey,
		Callback = function()
			if window.ToggleMinimize then window.ToggleMinimize() end
		end,
		OnRebind = function(key)
			-- Persist the chosen key; gameplay dispatch reads the live key itself.
			boundKey = key
		end,
	}, theme)

	-- Spinning gradients on/off (sidebar/settings tab backdrops, component sheens,
	-- slider/progress/radio spins). Toggle drives Tween.SetSpinsEnabled globally.
	Toggle.new(settingsScroller, {
		Name = "Spinning Animations",
		Default = SettingsStore.Get("SpinsEnabled"),
		Callback = function(state)
			Tween.SetSpinsEnabled(state)
			SettingsStore.Set("SpinsEnabled", state)
		end,
	}, nil, theme)

	-- Confirm before closing the UI (the red close prompt).
	Toggle.new(settingsScroller, {
		Name = "Confirm On Close",
		Default = SettingsStore.Get("ConfirmClose"),
		Callback = function(state)
			SettingsStore.Set("ConfirmClose", state)
		end,
	}, nil, theme)

	-- UI scale: drives a UIScale on the whole window.
	Slider.new(settingsScroller, {
		Name = "UI Scale",
		Min = 80,
		Max = 125,
		Default = math.floor((SettingsStore.Get("UIScale") or 1) * 100 + 0.5),
		Precision = 0,
		Callback = function(value)
			local scale = value / 100
			local us = window.MainFrame and window.MainFrame:FindFirstChild("WindowScale")
			if us then us.Scale = scale end
			SettingsStore.Set("UIScale", scale)
		end,
	}, theme)

	-- UI volume: drives the shared SoundGroup via Sound.SetVolume.
	Slider.new(settingsScroller, {
		Name = "UI Volume",
		Min = 0,
		Max = 100,
		Default = math.floor((SettingsStore.Get("Volume") or 1) * 100 + 0.5),
		Precision = 0,
		Callback = function(value)
			local vol = value / 100
			Sound.SetVolume(vol)
			SettingsStore.Set("Volume", vol)
		end,
	}, theme)

	-- Reset the window to its default position + size.
	Button.new(settingsScroller, {
		Name = "Reset Layout",
		Callback = function()
			if window.ResetLayout then window.ResetLayout() end
		end,
	}, theme)

	-- Component-owned theming for the page chrome (title + scroller scrollbar).
	-- The page is a settings page, not a regular component, so a small themable
	-- wrapper is registered on the page frame to keep the registry the single
	-- theming path. Individual settings are their own registered components.
	local uiSettingsPage = {}
	function uiSettingsPage:ApplyTheme(newTheme)
		local t = ThemeManager.GetTheme(newTheme)
		pageTitle.TextColor3 = t.PrimaryTextColor or pageTitle.TextColor3
		settingsScroller.ScrollBarImageColor3 = t.TertiaryColor or settingsScroller.ScrollBarImageColor3
	end
	ThemeManager.Register(page, uiSettingsPage)
end

return UISettings
