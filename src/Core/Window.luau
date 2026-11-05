--[[
	Aetheris/Core/Window.luau

	Builds the main window shell and exposes tabs, themes, popups and
	notifications. Teardown disconnects listeners and cancels pending tweens.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Tween = require("../Utils/Tween")
local PageFade = require("../Utils/PageFade")
local Sound = require("../Utils/Sound")
local Aurora = require("../Utils/Aurora")
local Security = require("../Utils/Security")
local Icons = require("../Assets/Icons")
local TabGroup = require("./TabGroup")
local UINotification = require("../Popups/UINotification")
local DropdownPopUp = require("../Popups/DropdownPopUp")
local ColorPickerPopUp = require("../Popups/ColorPickerPopUp")
local Tooltip = require("../Popups/Tooltip")
local ThemeManager = require("../Themes/ThemeManager")
local SearchFilter = require("./SearchFilter")
local SettingsTabGroup = require("./Settings/SettingsTabGroup")
local SettingsSystem = require("./Settings/PageBuilder")
local SettingsStore = require("./Settings/SettingsStore")
local ConfigManager = require("./Settings/ConfigManager")
local PageAwareness = require("../Utils/PageAwareness")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

local Window = {}
Window.__index = Window

-- Per-window animation/drag styles: "Smooth" or "Snappy", and "Instant" or "Smooth" while dragging.
Window.AnimationStyle = "Smooth"
Window.DragStyle = "Instant"

function Window.new(Settings)
	Settings = Settings or {}

	-- Persisted user settings win; CreateWindow's own Theme/MinimizeKey are the fallback.
	SettingsStore.Load()
	local savedTheme = SettingsStore.Get("Theme")
	local savedKey = SettingsStore.Get("MinimizeKey")
	if savedTheme ~= nil then
		Settings.Theme = savedTheme
	end
	if savedKey ~= nil then
		Settings.MinimizeKey = savedKey
	end
	Sound.SetVolume(SettingsStore.Get("Volume"))
	Tween.SpinsEnabled = SettingsStore.Get("SpinsEnabled")
	-- Saved font family lands before anything builds, so components pick it up through Constants.Font().
	Constants.SetFontAsset(SettingsStore.Get("Font"))

	-- Resolve theme early so UI creation uses actual theme table
	local resolvedTheme = ThemeManager.GetTheme(Settings.Theme)
	-- Keep Settings.Theme as the original input, but use resolvedTheme for values
	local theme = resolvedTheme

	local player = Players.LocalPlayer
	local secureMode = Settings.AETHERIS_SECUREMODE == true
	-- Only secure mode hides semantics in Explorer; normal mode resolves UUID.Static to readable names.
	UUID.SetSecureMode(secureMode)

	-- Forward declaration so early closures (e.g. the settings gear) can reach the finished window.
	local self

	-- Per-window values, hoisted above the closures so every handler sees this window's style.
	local animationStyle = Settings.AnimationStyle or "Smooth"
	local dragStyle = Settings.DragStyle or "Instant"

	-- Global UserInputService connections: not ScreenGui children, so tracked here and dropped in _teardown.
	local dragInputConnection
	local resizeInputConnection
	local minimizeKeyConnection
	local inputEndedConnection -- shared, recreated per drag/resize gesture
	local clockStopped = false

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = Settings.ScreenGuiName or UUID.Static("Aetheris")
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.ResetOnSpawn = false
	-- DisplayOrder, inset and Parent are caller-settable; Parent may be an explicit instance.
	if Settings.DisplayOrder ~= nil then
		ScreenGui.DisplayOrder = Settings.DisplayOrder
	end
	ScreenGui.IgnoreGuiInset = Settings.IgnoreGuiInset == true
	if secureMode then
		-- Secure mode: prefer a hidden gethui container, then CoreGui, then PlayerGui; rename + protect when supported.
		Security.Apply(ScreenGui, { Parent = Settings.Parent, Player = player })
	elseif Settings.Parent ~= nil then
		ScreenGui.Parent = Settings.Parent
	else
		-- Bounded wait so a missing PlayerGui can't hang a loadstring forever; fall back to CoreGui.
		local playerGui = player and player:FindFirstChild("PlayerGui")
		if not playerGui and player then
			playerGui = player:WaitForChild("PlayerGui", 5)
		end
		ScreenGui.Parent = playerGui or game:GetService("CoreGui")
	end

	-- Theme at construction so the first paint matches; CanvasGroup lets PageFade fade the whole shell at once.
	local MainFrame = Instance.new("CanvasGroup")
	MainFrame.Name = UUID.Static("Window")
	MainFrame.GroupTransparency = 0
	MainFrame.BorderSizePixel = 0
	MainFrame.BackgroundColor3 = theme.WindowColor or Color3.fromRGB(15, 15, 15)
	MainFrame.BackgroundTransparency = theme.WindowTransparency or 0.1
	MainFrame.AnchorPoint = Vector2.new(0, 0)
	MainFrame.Size = UDim2.fromScale(0.72026, 0.96995)
	MainFrame.Position = UDim2.fromScale(0.013, 0.015)
	-- Cosmetic only (BorderSizePixel is 0), but kept in sync with the theme stroke.
	MainFrame.BorderColor3 = theme.StrokeColor or Color3.fromRGB(41, 41, 41)
	MainFrame.Parent = ScreenGui

	local DragFrame = Instance.new("Frame")
	DragFrame.AnchorPoint = Vector2.new(0.5, 0)
	DragFrame.Name = UUID.Static("DragFrame")
	DragFrame.Position = UDim2.fromScale(0.5, 0)
	DragFrame.Size = UDim2.new(1, 0, 0, 60)
	DragFrame.BackgroundTransparency = 1
	DragFrame.Parent = MainFrame

	do
		local dragging = false
		local dragStart
		local startPosition

		DragFrame.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = true
				dragStart = input.Position
				startPosition = MainFrame.AbsolutePosition

				if inputEndedConnection then
					inputEndedConnection:Disconnect()
				end
				inputEndedConnection = UserInputService.InputEnded:Connect(function(endInput)
					if
						endInput.UserInputType == Enum.UserInputType.MouseButton1
						or endInput.UserInputType == Enum.UserInputType.Touch
					then
						dragging = false
						if inputEndedConnection then
							inputEndedConnection:Disconnect()
							inputEndedConnection = nil
						end
					end
				end)
			end
		end)

		dragInputConnection = UserInputService.InputChanged:Connect(function(input)
			if
				dragging
				and (
					input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
				)
			then
				local delta = input.Position - dragStart
				local newPosition = startPosition + Vector2.new(delta.X, delta.Y)
				local target = UDim2.fromOffset(newPosition.X, newPosition.Y)

				if dragStyle == "Smooth" then
					Tween.Play(MainFrame, "Fast", { Position = target })
				else
					MainFrame.Position = target
				end
			end
		end)
	end

	local MainFrameCorner = Instance.new("UICorner")
	MainFrameCorner.Parent = MainFrame

	-- User-adjustable UI scale (UI Settings); the window resizes around its top-left anchor.
	local MainFrameScale = Instance.new("UIScale")
	MainFrameScale.Name = UUID.Static("WindowScale")
	MainFrameScale.Scale = SettingsStore.Get("UIScale") or 1
	MainFrameScale.Parent = MainFrame

	-- Shadow colour is themed at construction so the first frame isn't unthemed; blur stays fixed.
	local MainFrameShadow = Instance.new("UIShadow")
	MainFrameShadow.Color = theme.MainframeShadowColor or MainFrameShadow.Color
	MainFrameShadow.Transparency = 0.5
	MainFrameShadow.BlurRadius = UDim.new(0, 20)
	MainFrameShadow.Parent = MainFrame

	local MainFrameSizeConstraint = Instance.new("UISizeConstraint")
	MainFrameSizeConstraint.MinSize = Vector2.new(425, 360)
	MainFrameSizeConstraint.Parent = MainFrame

	-- Separate fill right of the sidebar so content can stay readable while the shell stays translucent.
	local ContentBackground = Instance.new("Frame")
	ContentBackground.Name = UUID.Static("ContentBackground")
	ContentBackground.BorderSizePixel = 0
	ContentBackground.BackgroundColor3 = theme.ContentBackgroundColor or theme.WindowColor
	ContentBackground.BackgroundTransparency = theme.ContentBackgroundTransparency or theme.WindowTransparency or 0
	-- Sidebar is clamped to 186px, so content starts there; AnchorPoint (1, 0.5) keeps the right edge pinned on resize.
	ContentBackground.AnchorPoint = Vector2.new(1, 0.5)
	ContentBackground.Position = UDim2.fromScale(1, 0.5)
	ContentBackground.Size = UDim2.new(1, -186, 1, 0)
	ContentBackground.ZIndex = 0
	ContentBackground.Parent = MainFrame

	local ContentBackgroundCorner = Instance.new("UICorner")
	ContentBackgroundCorner.TopLeftRadius = UDim.new(0, 0)
	ContentBackgroundCorner.BottomLeftRadius = UDim.new(0, 0)
	ContentBackgroundCorner.TopRightRadius = UDim.new(0, 6)
	ContentBackgroundCorner.BottomRightRadius = UDim.new(0, 6)
	ContentBackgroundCorner.Parent = ContentBackground

	-- Soft accent bloom behind the window, created above the content fill but below sidebar/content; transparency from UI Settings.
	local aurora = Aurora.new(MainFrame, {
		Theme = theme,
		Enabled = SettingsStore.Get("AuroraEnabled") ~= false,
		Transparency = SettingsStore.Get("AuroraTransparency"),
	})

	local WindowControls = Instance.new("Frame")
	WindowControls.Name = UUID.Static("WindowControls")
	WindowControls.BorderSizePixel = 0
	WindowControls.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	WindowControls.BackgroundTransparency = 1
	WindowControls.AnchorPoint = Vector2.new(1, 0)
	WindowControls.Size = UDim2.fromScale(0.10926, 0.04715)
	WindowControls.Position = UDim2.new(0.99, 0, 0, 12)
	WindowControls.BorderColor3 = Color3.fromRGB(0, 0, 0)
	WindowControls.Parent = MainFrame

	local WindowControlsLayout = Instance.new("UIListLayout")
	WindowControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	WindowControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	WindowControlsLayout.Padding = UDim.new(0, 6)
	WindowControlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	WindowControlsLayout.FillDirection = Enum.FillDirection.Horizontal
	WindowControlsLayout.Parent = WindowControls

	-- Full icons from the Icons module; each gets a UIScale for a bouncy hover/press feel.
	local function makeControlButton(name, icon, layoutOrder, parent)
		local btn = Instance.new("ImageButton")
		btn.Name = UUID.Static("WindowControl:" .. name)
		btn.BackgroundTransparency = 1
		btn.ImageTransparency = 0.5
		btn.ImageColor3 = theme.WindowControlColor or Color3.fromRGB(203, 213, 225)
		btn.Image = icon
		btn.Size = UDim2.fromOffset(15, 15)
		btn.LayoutOrder = layoutOrder
		btn.Parent = parent
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.DominantAxis = Enum.DominantAxis.Height
		aspect.Parent = btn
		local scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = btn
		btn.MouseEnter:Connect(function()
			Tween.Play(scale, "HoverIn", { Scale = 1.25 })
			Tween.Play(btn, "Fast", { ImageTransparency = 0.1 })
		end)
		btn.MouseLeave:Connect(function()
			Tween.Play(scale, "HoverOut", { Scale = 1 })
			Tween.Play(btn, "Fast", { ImageTransparency = 0.5 })
		end)
		btn.MouseButton1Down:Connect(function()
			Tween.Play(scale, "Fast", { Scale = 0.9 })
		end)
		btn.MouseButton1Up:Connect(function()
			Tween.Play(scale, "HoverIn", { Scale = 1.25 })
		end)
		return btn
	end

	local MinimizeButton =
		makeControlButton("MinimizeButton", Icons["minimize"] or "rbxassetid://121304296213645", 1, WindowControls)
	local MaximizeButton =
		makeControlButton("MaximizeButton", Icons["maximize"] or "rbxassetid://76045941763188", 2, WindowControls)
	local CloseButton =
		makeControlButton("CloseButton", Icons["x"] or "rbxassetid://110786993356448", 3, WindowControls)
	-- Settings gear moved into the window-controls cluster (LayoutOrder 0 ->
	-- leftmost of the cluster, before Minimize). Its click handler is wired
	-- further down once TabContent/SettingsPages exist.
	local SettingsButton = makeControlButton("SettingsButton", Icons["settings"], 0, WindowControls)

	-- Page title (the drag handle lives here, whole title bar draggable)
	local PageTitle = Instance.new("TextLabel")
	PageTitle.Name = UUID.Static("PageTitle")
	PageTitle.TextWrapped = true
	PageTitle.BorderSizePixel = 0
	PageTitle.TextSize = 14
	PageTitle.TextXAlignment = Enum.TextXAlignment.Left
	PageTitle.TextTransparency = 0.3
	PageTitle.BackgroundTransparency = 1
	-- Regular base weight; the "Settings | " prefix and tab names go Medium through <font weight="500"> spans, not <b>.
	PageTitle.FontFace = Constants.Font(Enum.FontWeight.Regular)
	PageTitle.TextColor3 = theme.TitleTextColor
	PageTitle.RichText = true
	PageTitle.AutomaticSize = Enum.AutomaticSize.X
	PageTitle.Size = UDim2.fromScale(0, 0.06849)
	-- Offset X (not scale): the sidebar's fixed 186px plus a 14px gap keeps the title put on resize.
	PageTitle.Position = UDim2.new(0, 200, 0.045, 0)
	PageTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PageTitle.Text = '<font weight="500">Settings | </font>General'
	PageTitle.Parent = MainFrame

	local PageTitleDivider = Instance.new("Frame")
	PageTitleDivider.Name = UUID.Static("ComponentDivider")
	PageTitleDivider.BorderSizePixel = 0
	PageTitleDivider.BackgroundColor3 = theme.TertiaryColor
	PageTitleDivider.BackgroundTransparency = theme.SectionDividerTransparency or 0.9
	PageTitleDivider.Size = UDim2.new(0.8, 0, 0, 1)
	PageTitleDivider.Position = UDim2.fromScale(0, 1.2)
	PageTitleDivider.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PageTitleDivider.Parent = PageTitle

	local Content = Instance.new("Frame")
	Content.Name = UUID.Static("Content")
	Content.BorderSizePixel = 0
	Content.BackgroundTransparency = 1
	-- Left edge offset 200px (sidebar 186 + 14 gap), right edge fills, so it stays put on resize.
	Content.Size = UDim2.new(1, -200, 0.83149, 0)
	Content.Position = UDim2.new(0, 200, 0.14851, 0)
	Content.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Content.Parent = MainFrame

	local PopUpsFolder = Instance.new("Folder")
	PopUpsFolder.Name = UUID.Static("PopUps")
	PopUpsFolder.Parent = Content

	-- Direct ScreenGui child so toasts sit above the window unclipped; stacks bottom-right.
	local Notifications = Instance.new("Frame")
	Notifications.Name = UUID.Static("Notifications")
	Notifications.BorderSizePixel = 0
	Notifications.BackgroundTransparency = 1
	Notifications.AnchorPoint = Vector2.new(1, 1)
	Notifications.Size = UDim2.new(0, 260, 1, 0)
	Notifications.Position = UDim2.fromScale(1, 1)
	Notifications.ZIndex = 999
	Notifications.Parent = ScreenGui

	local NotificationsLayout = Instance.new("UIListLayout")
	NotificationsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	NotificationsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	NotificationsLayout.Padding = UDim.new(0, 8)
	NotificationsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	NotificationsLayout.Parent = Notifications

	local NotificationsPadding = Instance.new("UIPadding")
	NotificationsPadding.PaddingBottom = UDim.new(0, 14)
	NotificationsPadding.PaddingRight = UDim.new(0, 4)
	NotificationsPadding.Parent = Notifications

	-- Opt-in settings pages: UISettings ships by default, others come from the developer.
	local SettingsPages = Instance.new("Frame")
	SettingsPages.Name = UUID.Static("SettingsPages")
	SettingsPages.Visible = false
	SettingsPages.BorderSizePixel = 0
	SettingsPages.BackgroundTransparency = 1
	SettingsPages.AnchorPoint = Vector2.new(0.5, 0.5)
	SettingsPages.ClipsDescendants = true
	SettingsPages.Size = UDim2.fromScale(0.983, 1)
	SettingsPages.Position = UDim2.fromScale(0.5, 0.5)
	SettingsPages.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SettingsPages.Parent = Content

	local TabContent = Instance.new("Frame")
	TabContent.Name = UUID.Static("TabContent")
	TabContent.BorderSizePixel = 0
	TabContent.BackgroundTransparency = 1
	TabContent.AnchorPoint = Vector2.new(0.5, 0.5)
	TabContent.ClipsDescendants = true
	TabContent.Size = UDim2.fromScale(1, 1)
	TabContent.Position = UDim2.fromScale(0.5, 0.5)
	TabContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabContent.Parent = Content

	local TabContentPadding = Instance.new("UIPadding")
	TabContentPadding.PaddingTop = UDim.new(0, 10)
	TabContentPadding.PaddingRight = UDim.new(0, 5)
	TabContentPadding.PaddingLeft = UDim.new(0, 2)
	TabContentPadding.PaddingBottom = UDim.new(0, 10)
	TabContentPadding.Parent = TabContent

	local Sidebar = Instance.new("Frame")
	Sidebar.Name = UUID.Static("Sidebar")
	Sidebar.BorderSizePixel = 0
	Sidebar.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
	Sidebar.BackgroundTransparency = 1
	Sidebar.AnchorPoint = Vector2.new(0, 0)
	Sidebar.Size = UDim2.fromScale(0.41348, 1)
	Sidebar.Position = UDim2.fromScale(0, 0)
	Sidebar.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Sidebar.Parent = MainFrame

	local SidebarPadding = Instance.new("UIPadding")
	SidebarPadding.PaddingTop = UDim.new(0, 10)
	SidebarPadding.PaddingRight = UDim.new(0, 5)
	SidebarPadding.PaddingLeft = UDim.new(0, 5)
	SidebarPadding.PaddingBottom = UDim.new(0, 15)
	SidebarPadding.Parent = Sidebar

	local SidebarCorner = Instance.new("UICorner")
	SidebarCorner.TopLeftRadius = UDim.new(0, 6)
	SidebarCorner.BottomLeftRadius = UDim.new(0, 6)
	SidebarCorner.TopRightRadius = UDim.new(0, 0)
	SidebarCorner.BottomRightRadius = UDim.new(0, 0)
	SidebarCorner.Parent = Sidebar

	local SidebarSizeConstraint = Instance.new("UISizeConstraint")
	SidebarSizeConstraint.MinSize = Vector2.new(178, 328)
	SidebarSizeConstraint.MaxSize = Vector2.new(186, 99999)
	SidebarSizeConstraint.Parent = Sidebar

	local TabList = Instance.new("ScrollingFrame")
	TabList.Name = UUID.Static("TabList")
	TabList.Active = true
	TabList.ScrollingDirection = Enum.ScrollingDirection.Y
	TabList.BorderSizePixel = 0
	TabList.ScrollBarImageTransparency = 1
	TabList.BackgroundTransparency = 1
	TabList.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
	TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	-- Top-pinned offset + fill height; the bottom offset leaves room for the divider and user info.
	TabList.Size = UDim2.new(1, 0, 1, -145)
	TabList.Position = UDim2.fromOffset(0, 94)
	TabList.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabList.ScrollBarThickness = 1
	TabList.ScrollBarImageColor3 = theme.TertiaryColor
	TabList.Parent = Sidebar

	local tabListScrollbarTimer
	TabList:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		-- Compact mode hides the scrollbar entirely instead of the usual 0.5 reveal.
		if TabList:GetAttribute(UUID.Static("CompactNoScrollbar")) then
			TabList.ScrollBarImageTransparency = 1
			return
		end
		Tween.Play(TabList, "Fast", { ScrollBarImageTransparency = 0.5 })
		if tabListScrollbarTimer then
			task.cancel(tabListScrollbarTimer)
		end
		tabListScrollbarTimer = task.delay(1.5, function()
			Tween.Play(TabList, "Fast", { ScrollBarImageTransparency = 1 })
			tabListScrollbarTimer = nil
		end)
	end)

	local TabListLayout = Instance.new("UIListLayout")
	TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	TabListLayout.Padding = UDim.new(0, 12)
	TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabListLayout.Parent = TabList

	local SearchBar = Instance.new("Frame")
	SearchBar.Name = UUID.Static("SearchBar")
	SearchBar.BorderSizePixel = 0
	SearchBar.BackgroundColor3 = theme.SearchBarBackgroundColor
	SearchBar.BackgroundTransparency = 1
	SearchBar:SetAttribute(UUID.Static("IsSearchFocused"), false)
	-- Fixed offset from the top (below the script info) so it never drifts.
	SearchBar.Size = UDim2.new(1, 0, 0, 26)
	SearchBar.Position = UDim2.fromOffset(0, 48)
	SearchBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SearchBar.Parent = Sidebar

	local SearchBoxCorner = Instance.new("UICorner")
	SearchBoxCorner.CornerRadius = UDim.new(0, 6)
	SearchBoxCorner.Parent = SearchBar

	local SearchBoxStroke = Instance.new("UIStroke")
	SearchBoxStroke.Transparency = 1
	SearchBoxStroke.Color = theme.StrokeColor
	SearchBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	SearchBoxStroke.Parent = SearchBar

	local SearchBox = Instance.new("TextBox")
	SearchBox.Name = UUID.Static("SearchBox")
	SearchBox.TextXAlignment = Enum.TextXAlignment.Left
	SearchBox.PlaceholderColor3 = theme.SecondaryTextColor or Color3.fromRGB(100, 100, 100)
	SearchBox.BorderSizePixel = 0
	SearchBox.TextTruncate = Enum.TextTruncate.AtEnd
	SearchBox.TextTransparency = theme.PrimaryTextTransparency
	SearchBox.TextSize = 12
	SearchBox.TextColor3 = theme.PrimaryTextColor
	SearchBox.BackgroundTransparency = 1
	SearchBox.FontFace = Constants.Font(Enum.FontWeight.Medium)
	SearchBox.PlaceholderText = "Search..."
	SearchBox.Size = UDim2.fromScale(0.7921, 1)
	SearchBox.Position = UDim2.fromScale(0.17991, 0)
	SearchBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SearchBox.Text = ""
	SearchBox.Parent = SearchBar

	local SearchIcon = Instance.new("ImageLabel")
	SearchIcon.Name = UUID.Static("SearchIcon")
	SearchIcon.BorderSizePixel = 0
	SearchIcon.BackgroundTransparency = 1
	SearchIcon.ImageTransparency = 0.5
	SearchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	SearchIcon.Image = Icons.search
	SearchIcon.ImageColor3 = theme.SecondaryColor
	SearchIcon.Size = UDim2.fromOffset(12, 12)
	SearchIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SearchIcon.Position = UDim2.fromScale(0.09543, 0.5)
	SearchIcon.Parent = SearchBar

	local SearchBarBottomDivider = Instance.new("Frame")
	SearchBarBottomDivider.Name = UUID.Static("BottomDivider")
	SearchBarBottomDivider.BorderSizePixel = 0
	SearchBarBottomDivider.BackgroundColor3 = theme.TertiaryColor
	SearchBarBottomDivider.BackgroundTransparency = 0.9
	SearchBarBottomDivider.AnchorPoint = Vector2.new(0.5, 0.5)
	SearchBarBottomDivider.Size = UDim2.new(0.8, 0, 0, 1)
	SearchBarBottomDivider.Position = UDim2.new(0.5, 0, 0, 35)
	SearchBarBottomDivider.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SearchBarBottomDivider.Parent = SearchBar

	-- Focus sharpens the bar, stroke, icon and divider; blur returns them to rest.
	SearchBar.BackgroundTransparency = 1
	SearchBox.Focused:Connect(function()
		SearchBar:SetAttribute(UUID.Static("IsSearchFocused"), true)
		-- Read the live theme so focus reflects the current theme, not the construction-time one.
		local liveTheme = self._theme or theme
		Tween.Play(SearchBar, "Fast", { BackgroundTransparency = liveTheme.SearchBarBackgroundTransparency or 0 })
		SearchBoxStroke.Color = liveTheme.StrokeColor or SearchBoxStroke.Color
		Tween.Play(SearchBoxStroke, "Fast", { Transparency = liveTheme.StrokeTransparency or 0.95 })
		Tween.Play(SearchIcon, "Fast", { ImageTransparency = 0.2 })
		Tween.Play(SearchBarBottomDivider, "Fast", { BackgroundTransparency = 0.2 })
	end)
	SearchBox.FocusLost:Connect(function()
		SearchBar:SetAttribute(UUID.Static("IsSearchFocused"), false)
		Tween.Play(SearchBar, "Fast", { BackgroundTransparency = 1 })
		Tween.Play(SearchBoxStroke, "Fast", { Transparency = 1 })
		Tween.Play(SearchIcon, "Fast", { ImageTransparency = 0.5 })
		Tween.Play(SearchBarBottomDivider, "Fast", { BackgroundTransparency = 0.9 })
	end)

	-- Debounce bursts of typing into one pass; the search walks the active page and rewrites labels.
	local searchDebounce
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if searchDebounce then
			task.cancel(searchDebounce)
		end
		searchDebounce = task.delay(0.15, function()
			searchDebounce = nil
			if self and self.ApplySearch and SearchBox.Parent then
				self:ApplySearch()
			end
		end)
	end)

	local SidebarDivider = Instance.new("Frame")
	SidebarDivider.Name = UUID.Static("Divider")
	SidebarDivider.BorderSizePixel = 0
	SidebarDivider.BackgroundColor3 = theme.TertiaryColor
	SidebarDivider.BackgroundTransparency = 0.9
	-- Bottom-anchored so it stays just above the user info on resize.
	SidebarDivider.AnchorPoint = Vector2.new(0.5, 1)
	SidebarDivider.Size = UDim2.new(0.8, 1, 0, 1)
	SidebarDivider.Position = UDim2.new(0.5, 0, 1, -48)
	SidebarDivider.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SidebarDivider.Parent = Sidebar

	local UserInfo = Instance.new("Frame")
	UserInfo.Name = UUID.Static("UserInfo")
	UserInfo.BorderSizePixel = 0
	UserInfo.BackgroundTransparency = 1
	UserInfo.AnchorPoint = Vector2.new(0.5, 1)
	UserInfo.Size = UDim2.new(1, 0, 0, 50)
	UserInfo.Position = UDim2.new(0.5, 0, 1, 8)
	UserInfo.BorderColor3 = Color3.fromRGB(0, 0, 0)
	UserInfo.Parent = Sidebar

	local UserInfoPadding = Instance.new("UIPadding")
	UserInfoPadding.PaddingRight = UDim.new(0, 10)
	UserInfoPadding.PaddingLeft = UDim.new(0, 10)
	UserInfoPadding.Parent = UserInfo

	local UserInfoGroup = Instance.new("Frame")
	UserInfoGroup.Name = UUID.Static("InformationGroup")
	UserInfoGroup.BorderSizePixel = 0
	UserInfoGroup.BackgroundTransparency = 1
	UserInfoGroup.Size = UDim2.fromScale(1, 0.85)
	UserInfoGroup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	UserInfoGroup.Parent = UserInfo

	local UserInfoGroupLayout = Instance.new("UIListLayout")
	UserInfoGroupLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UserInfoGroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UserInfoGroupLayout.FillDirection = Enum.FillDirection.Horizontal
	UserInfoGroupLayout.Parent = UserInfoGroup

	local PlayerHeadshot = Instance.new("ImageLabel")
	PlayerHeadshot.Name = UUID.Static("PlayerHeadshot")
	PlayerHeadshot.BorderSizePixel = 0
	PlayerHeadshot.BackgroundTransparency = 1
	PlayerHeadshot.Image = "rbxthumb://type=AvatarBust&id=" .. (player and player.UserId or 1) .. "&w=48&h=48"
	PlayerHeadshot.Size = UDim2.fromOffset(32, 32)
	PlayerHeadshot.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PlayerHeadshot.LayoutOrder = 1
	PlayerHeadshot.Parent = UserInfoGroup

	local PlayerHeadshotCorner = Instance.new("UICorner")
	PlayerHeadshotCorner.CornerRadius = UDim.new(0, 10)
	PlayerHeadshotCorner.Parent = PlayerHeadshot

	-- Toggles the settings overlay; reads the live SettingsPages.Visible state so other hide paths stay in sync.
	SettingsButton.MouseButton1Click:Connect(function()
		if SettingsPages.Visible then
			SettingsPages.Visible = false
			TabContent.Visible = true
			-- Hand the title back to whatever sidebar tab was underneath.
			if self.TabGroup then
				self.TabGroup:SyncTitle()
			end
		else
			TabContent.Visible = false
			SettingsPages.Visible = true
			if self.SettingsTabGroup then
				self.SettingsTabGroup:RefreshTitle()
			end
		end
		-- Opening/closing the settings overlay swaps which page is active.
		PageAwareness.Refresh()
	end)

	local NameContainer = Instance.new("Frame")
	NameContainer.Name = UUID.Static("NameContainer")
	NameContainer.BorderSizePixel = 0
	NameContainer.BackgroundTransparency = 1
	NameContainer.Size = UDim2.new(0.95823, -42, 0, 32)
	NameContainer.Position = UDim2.fromScale(0.22278, 0.19619)
	NameContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
	NameContainer.LayoutOrder = 2
	NameContainer.Parent = UserInfoGroup

	local NameContainerPadding = Instance.new("UIPadding")
	NameContainerPadding.Name = UUID.Static("UserAndDisplayFrameUIPadding")
	NameContainerPadding.PaddingTop = UDim.new(0, 3)
	NameContainerPadding.PaddingLeft = UDim.new(0, 8)
	NameContainerPadding.Parent = NameContainer

	local NameContainerLayout = Instance.new("UIListLayout")
	NameContainerLayout.Name = UUID.Static("UserAndDisplayFrameUIListLayout")
	NameContainerLayout.Padding = UDim.new(0, 4)
	NameContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	NameContainerLayout.Parent = NameContainer

	local Username = Instance.new("TextButton")
	Username.Name = UUID.Static("Username")
	Username.TextTruncate = Enum.TextTruncate.SplitWord
	Username.AutoButtonColor = false
	Username.BorderSizePixel = 0
	Username.TextSize = 12
	Username.TextXAlignment = Enum.TextXAlignment.Left
	Username.TextTransparency = 0.7
	Username.TextYAlignment = Enum.TextYAlignment.Top
	Username.BackgroundTransparency = 1
	Username.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	Username.TextColor3 = theme.TitleTextColor
	Username.Size = UDim2.fromScale(1, 0)
	Username.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Username.Text = "@" .. (player and player.Name or "Guest")
	Username.LayoutOrder = 1
	Username.AutomaticSize = Enum.AutomaticSize.XY
	Username.Parent = NameContainer

	local DisplayName = Instance.new("TextButton")
	DisplayName.Name = UUID.Static("DisplayName")
	DisplayName.AutoButtonColor = false
	DisplayName.BorderSizePixel = 0
	DisplayName.TextXAlignment = Enum.TextXAlignment.Left
	DisplayName.TextTransparency = 0.3
	DisplayName.TextSize = 13
	DisplayName.TextColor3 = theme.TitleTextColor
	DisplayName.BackgroundTransparency = 1
	DisplayName.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	DisplayName.AutomaticSize = Enum.AutomaticSize.XY
	DisplayName.Size = UDim2.fromScale(1, 0)
	DisplayName.BorderColor3 = Color3.fromRGB(0, 0, 0)
	DisplayName.Text = player and player.DisplayName or "Guest"
	DisplayName.Parent = NameContainer

	-- Mask Display Name drives both lines. Auto-mask (persisted) hides the
	-- names from startup and, while on, a click only explains itself with a
	-- toast and a quick action — it never unmasks directly. With auto-mask off
	-- the names are free to mask/unmask by clicking, as often as wanted, with
	-- no toast at all.
	local originalDisplayName = DisplayName.Text
	local originalUsername = Username.Text
	local function maskOf(text)
		return string.rep("*", utf8.len(text) or #text)
	end
	local autoMask = SettingsStore.Get("MaskDisplayName") == true
	-- Session-only fallback used while auto-mask is off; the store only ever
	-- holds auto-mask, so a fresh UI starts with the names visible when it's off.
	local manualMask = false
	local function isMasked()
		return autoMask or manualMask
	end
	local maskFading = false

	local function applyMask(animate)
		local showMask = isMasked()
		if animate then
			maskFading = true
			Tween.Play(DisplayName, "Fast", { TextTransparency = 1 })
			Tween.Play(Username, "Fast", { TextTransparency = 1 })
			task.delay(0.2, function()
				if not DisplayName.Parent then
					return
				end
				DisplayName.Text = showMask and maskOf(originalDisplayName) or originalDisplayName
				Username.Text = showMask and maskOf(originalUsername) or originalUsername
				Tween.Play(DisplayName, "Smooth", { TextTransparency = 0.3 })
				Tween.Play(Username, "Smooth", { TextTransparency = 0.7 })
				maskFading = false
			end)
		else
			DisplayName.Text = showMask and maskOf(originalDisplayName) or originalDisplayName
			Username.Text = showMask and maskOf(originalUsername) or originalUsername
		end
	end
	-- Startup paint: auto-mask on means both lines open already masked.
	applyMask(false)

	-- Single source of truth for auto-mask: writes the setting, syncs the UI
	-- Settings toggle, drops any leftover manual mask and repaints the name
	-- lines. Idempotent so a toggle callback that routes back here is a no-op,
	-- not a loop. Local here (self isn't built yet); attached right after
	-- setmetatable.
	local function setMaskEnabled(on, animate)
		on = on == true
		if autoMask == on and not manualMask then
			return
		end
		autoMask = on
		manualMask = false
		SettingsStore.Set("MaskDisplayName", on)
		if self and self._maskToggle and self._maskToggle.GetState and self._maskToggle:GetState() ~= on then
			-- UpdateState fires the toggle callback, which re-enters here and early-returns.
			self._maskToggle:UpdateState(on)
		end
		applyMask(animate ~= false)
	end

	local function onNameClick()
		if maskFading then
			return
		end
		if autoMask then
			-- Auto-mask owns the state, so ask instead of unmasking.
			self:Toast({
				Title = "Auto-mask is on",
				Description = "Turn auto-mask off to show your name?",
				Duration = 5,
				Actions = {
					{
						Text = "Turn off",
						Callback = function()
							self:SetMaskEnabled(false, true)
						end,
					},
					{
						Text = "Leave on",
						Callback = function() end,
					},
				},
			})
		else
			-- Auto-mask off: a plain mask/unmask toggle, no toast.
			manualMask = not manualMask
			applyMask(true)
		end
	end
	DisplayName.MouseButton1Click:Connect(onNameClick)
	Username.MouseButton1Click:Connect(onNameClick)

	local TimeLabel = Instance.new("TextLabel")
	TimeLabel.Name = UUID.Static("TimeLabel")
	TimeLabel.TextWrapped = true
	TimeLabel.BorderSizePixel = 0
	TimeLabel.TextSize = 12
	TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
	TimeLabel.TextTransparency = 0.3
	TimeLabel.TextScaled = true
	TimeLabel.BackgroundTransparency = 1
	TimeLabel.FontFace = Constants.Font(Enum.FontWeight.Regular)
	TimeLabel.TextColor3 = theme.TitleTextColor
	TimeLabel.RichText = true
	TimeLabel.Size = UDim2.fromScale(0.1, 0.7)
	TimeLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	local function clockText()
		local t = os.date("*t")
		return "<b>" .. string.format("%02d", t.hour) .. "</b><br /><br />" .. string.format("%02d", t.min)
	end
	TimeLabel.Text = clockText()
	TimeLabel.LayoutOrder = 3
	TimeLabel.AutomaticSize = Enum.AutomaticSize.XY
	TimeLabel.Position = UDim2.fromScale(0.83, 0.89262)
	TimeLabel.Parent = UserInfoGroup

	-- Refresh the clock once a second; the loop exits on teardown or once the label is gone.
	task.spawn(function()
		while not clockStopped do
			task.wait(1)
			if clockStopped or not TimeLabel.Parent then
				break
			end
			TimeLabel.Text = clockText()
		end
	end)

	local ScriptInfo = Instance.new("Frame")
	ScriptInfo.Name = UUID.Static("ScriptInfo")
	ScriptInfo.BorderSizePixel = 0
	ScriptInfo.BackgroundTransparency = 1
	ScriptInfo.Size = UDim2.new(0.84065, 0, 0, 42)
	ScriptInfo.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScriptInfo.Parent = Sidebar

	local ScriptInfoGroup = Instance.new("Frame")
	ScriptInfoGroup.Name = UUID.Static("InformationGroup")
	ScriptInfoGroup.BorderSizePixel = 0
	ScriptInfoGroup.BackgroundTransparency = 1
	ScriptInfoGroup.Size = UDim2.fromScale(1, 1)
	ScriptInfoGroup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScriptInfoGroup.Parent = ScriptInfo

	local ScriptInfoGroupLayout = Instance.new("UIListLayout")
	ScriptInfoGroupLayout.Padding = UDim.new(0, 8)
	ScriptInfoGroupLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	ScriptInfoGroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ScriptInfoGroupLayout.FillDirection = Enum.FillDirection.Horizontal
	ScriptInfoGroupLayout.Parent = ScriptInfoGroup

	local ScriptLogo = Instance.new("ImageLabel")
	ScriptLogo.Name = UUID.Static("ScriptLogo")
	ScriptLogo.BorderSizePixel = 0
	ScriptLogo.BackgroundTransparency = 1
	ScriptLogo.Image = "rbxassetid://92458734285074"
	ScriptLogo.Size = UDim2.fromOffset(40, 32)
	ScriptLogo.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScriptLogo.LayoutOrder = 1
	ScriptLogo.Parent = ScriptInfoGroup

	local ScriptLogoUICorner = Instance.new("UICorner")
	ScriptLogoUICorner.CornerRadius = UDim.new(0, 6)
	ScriptLogoUICorner.Parent = ScriptLogo

	local ScriptInfoContainer = Instance.new("Frame")
	ScriptInfoContainer.Name = UUID.Static("ScriptInfoContainer")
	ScriptInfoContainer.BorderSizePixel = 0
	ScriptInfoContainer.BackgroundTransparency = 1
	ScriptInfoContainer.Size = UDim2.new(0.95823, -42, 0, 32)
	ScriptInfoContainer.Position = UDim2.fromScale(0.22278, 0.19619)
	ScriptInfoContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScriptInfoContainer.LayoutOrder = 2
	ScriptInfoContainer.Parent = ScriptInfoGroup

	local ScriptInfoContainerLayout = Instance.new("UIListLayout")
	ScriptInfoContainerLayout.Name = UUID.Static("UserAndDisplayFrameUIListLayout")
	ScriptInfoContainerLayout.Padding = UDim.new(0, 4)
	ScriptInfoContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ScriptInfoContainerLayout.Parent = ScriptInfoContainer

	local ScriptName = Instance.new("TextLabel")
	ScriptName.Name = UUID.Static("ScriptName")
	ScriptName.TextTruncate = Enum.TextTruncate.SplitWord
	ScriptName.BorderSizePixel = 0
	ScriptName.TextSize = 13
	ScriptName.TextXAlignment = Enum.TextXAlignment.Left
	ScriptName.TextTransparency = 0.3
	ScriptName.TextYAlignment = Enum.TextYAlignment.Top
	ScriptName.BackgroundTransparency = 1
	ScriptName.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	ScriptName.TextColor3 = theme.TitleTextColor
	ScriptName.Size = UDim2.fromScale(1.36294, 0.44828)
	ScriptName.RichText = true
	ScriptName.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScriptName.Text = "Aetheris | Jailbreak"
	ScriptName.LayoutOrder = 1
	ScriptName.AutomaticSize = Enum.AutomaticSize.XY
	ScriptName.Position = UDim2.fromScale(0, 0)
	ScriptName.Parent = ScriptInfoContainer

	-- Caller-pinned colours live on TagBaseColor/TagAccentColor attributes; a nil one follows the theme. Forward-declared for restampThemeGradients.
	local tagGradients = {}

	-- Rebuild every tag gradient at build and on each theme switch; a pinned base/accent wins over the theme.
	local function restampThemeGradients(t)
		local accent = t.AccentColor or Color3.fromRGB(108, 140, 255)
		local base = t.PopupBackgroundColor or t.WindowColor or Color3.fromRGB(20, 20, 22)
		for _, g in ipairs(tagGradients) do
			local pill = g and g.Parent
			if pill then
				-- Two independent roles: the pill's background (fill) and the gradient's fade target (accent).
				local pinnedBase = g:GetAttribute(UUID.Static("TagBaseColor"))
				local pinnedAccent = g:GetAttribute(UUID.Static("TagAccentColor"))
				local fill = (typeof(pinnedBase) == "Color3") and pinnedBase or base
				local hue = (typeof(pinnedAccent) == "Color3") and pinnedAccent or accent
				pill.BackgroundColor3 = fill
				g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), hue)
				local glow = pill:FindFirstChildOfClass("UIShadow")
				if glow then
					glow.Color = fill
				end
			end
		end
	end
	restampThemeGradients(theme)

	-- Tags (Settings.Tags): up to 3 pills under the title; plain strings or { Name, BackgroundColor, TextColor, AccentColor } tables, supplied colours pinned.
	local TagsContainer = Instance.new("Frame")
	TagsContainer.Name = UUID.Static("ScriptTags")
	TagsContainer.BorderSizePixel = 0
	TagsContainer.BackgroundTransparency = 1
	TagsContainer.Size = UDim2.new(1, 0, 0, 14)
	TagsContainer.LayoutOrder = 4
	TagsContainer.Parent = ScriptInfoContainer

	local TagsLayout = Instance.new("UIListLayout")
	TagsLayout.Name = UUID.Static("ScriptTagsLayout")
	TagsLayout.FillDirection = Enum.FillDirection.Horizontal
	TagsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TagsLayout.Padding = UDim.new(0, 4)
	TagsLayout.Parent = TagsContainer

	local TAG_GAP = 4
	local function buildTag(spec, index, total)
		local name, txtColor, bgColor, accColor
		if type(spec) == "table" then
			name = spec.Name or spec.Text or ""
			txtColor = spec.TextColor
			bgColor = spec.BackgroundColor
			accColor = spec.AccentColor
		else
			name = tostring(spec)
		end

		-- Even split: each pill gets 1/total of the row minus its share of the gaps.
		local widthOffset = -(TAG_GAP * (total - 1)) / total

		local pill = Instance.new("Frame")
		pill.Name = UUID.Generate("TagPill")
		pill.BorderSizePixel = 0
		-- Caller-coloured fill; the gradient below fades it toward the accent.
		pill.BackgroundColor3 = bgColor or theme.PopupBackgroundColor or theme.WindowColor or Color3.fromRGB(20, 20, 22)
		pill.BackgroundTransparency = 0
		pill.Size = UDim2.new(1 / total, widthOffset, 0, 14)
		pill.BorderColor3 = Color3.fromRGB(0, 0, 0)
		pill.LayoutOrder = index
		pill.Parent = TagsContainer

		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(1, 0)
		pillCorner.Parent = pill

		local pillGradient = Instance.new("UIGradient")
		pillGradient.Rotation = -55
		-- Record the pinned base + accent so a theme switch preserves them.
		if bgColor then
			pillGradient:SetAttribute(UUID.Static("TagBaseColor"), bgColor)
		end
		if accColor then
			pillGradient:SetAttribute(UUID.Static("TagAccentColor"), accColor)
		end
		-- White to accent: the bright end shows the pill's own colour, the far end fades into the accent.
		pillGradient.Color = ColorSequence.new(
			Color3.fromRGB(255, 255, 255),
			accColor or theme.AccentColor or Color3.fromRGB(108, 140, 255)
		)
		pillGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0.12),
		})
		pillGradient.Parent = pill
		table.insert(tagGradients, pillGradient)

		-- Bloom behind the pill, matching the pill's background colour rather than the accent.
		local glow = Instance.new("UIShadow")
		glow.Color = bgColor or theme.PopupBackgroundColor or theme.WindowColor or Color3.fromRGB(20, 20, 22)
		glow.Transparency = 0.6
		glow.BlurRadius = UDim.new(0, 8)
		glow.Spread = UDim2.fromOffset(1, 1)
		glow.Parent = pill

		local label = Instance.new("TextLabel")
		label.Name = UUID.Static("TagText")
		label.BorderSizePixel = 0
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextSize = 8
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.TextTransparency = 0.1
		label.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
		label.TextColor3 = txtColor or theme.TitleTextColor
		label.RichText = true
		label.Size = UDim2.fromScale(1, 1)
		label.Parent = pill

		-- The solid BackgroundColor3 owns the fill; the gradient is only the white sheen. Tags stay fully opaque.
		if txtColor then
			ThemeManager.SetColorOverride(label, "TextColor3", txtColor)
		else
			ThemeManager.BindColor(label, "TextColor3", "TitleTextColor")
		end
	end

	local function buildTags(list)
		for _, c in ipairs(TagsContainer:GetChildren()) do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		for i = #tagGradients, 1, -1 do
			tagGradients[i] = nil
		end
		if type(list) ~= "table" then
			return
		end
		local total = math.min(#list, 3)
		for i = 1, total do
			buildTag(list[i], i, total)
		end
	end
	buildTags(Settings.Tags)

	local ResizeButton = Instance.new("ImageButton")
	ResizeButton.Name = UUID.Static("ResizeButton")
	ResizeButton.BorderSizePixel = 0
	ResizeButton.AutoButtonColor = false
	ResizeButton.ImageTransparency = 1
	ResizeButton.BackgroundTransparency = 1
	ResizeButton.AnchorPoint = Vector2.new(1, 1)
	ResizeButton.Image = "rbxassetid://8445471173"
	ResizeButton.ImageRectSize = Vector2.new(96, 96)
	ResizeButton.ImageRectOffset = Vector2.new(704, 804)
	ResizeButton.Size = UDim2.fromOffset(28, 28)
	ResizeButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ResizeButton.Position = UDim2.fromScale(0.99, 0.99)
	ResizeButton.Parent = MainFrame

	if Settings.Title then
		ScriptName.Text = Settings.Title
	end

	self = setmetatable({}, Window)
	self.AnimationStyle = animationStyle
	self.DragStyle = dragStyle
	self.MainFrameShadow = MainFrameShadow
	self.Aurora = aurora
	-- Attach as a real method: call sites use colon syntax, and the closure
	-- takes (on, animate) directly rather than (self, on, animate).
	self.SetMaskEnabled = function(_me, on, animate)
		setMaskEnabled(on, animate)
	end

	-- Stored before settings pages/scripts build so they don't fall back to Default.
	self._theme = theme

	-- Original theme name so the Themes page can mark the active card on first build.
	if type(Settings.Theme) == "string" then
		self._themeName = Settings.Theme
	else
		self._themeName = ThemeManager.DefaultTheme
	end

	-- Minimize keybind: only a single letter is uppercased; multi-char names stay as-is to match Enum.KeyCode.Name.
	local mk = Settings.MinimizeKey
	if type(mk) ~= "string" or mk == "" then
		self._minimizeKey = "M"
	else
		self._minimizeKey = (#mk == 1) and string.upper(mk) or mk
	end

	self.Base = ScreenGui
	self.MainFrame = MainFrame
	self.Notifications = Notifications
	self.ContentBackground = ContentBackground
	self.Content = Content
	self.PopUpsFolder = PopUpsFolder
	self.SettingsPages = SettingsPages
	self.TabContent = TabContent
	self.Sidebar = Sidebar
	self.TabList = TabList
	self.SearchBox = SearchBox
	self.PageTitle = PageTitle
	self.ScriptName = ScriptName
	self.WindowControls = WindowControls

	do
		local resizing = false
		local resizeHovered = false
		local resizeStart
		local startSize

		-- Resize handle feedback: faint on hover, fully visible while dragging.
		local function updateResizeVisual()
			local target = 1
			if resizing then
				target = 0
			elseif resizeHovered then
				target = 0.5
			end
			Tween.Play(ResizeButton, "Fast", { ImageTransparency = target })
		end
		ResizeButton.MouseEnter:Connect(function()
			resizeHovered = true
			updateResizeVisual()
		end)
		ResizeButton.MouseLeave:Connect(function()
			resizeHovered = false
			updateResizeVisual()
		end)

		ResizeButton.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				resizing = true
				updateResizeVisual()
				resizeStart = input.Position
				startSize = MainFrame.AbsoluteSize

				if inputEndedConnection then
					inputEndedConnection:Disconnect()
				end
				inputEndedConnection = UserInputService.InputEnded:Connect(function(endInput)
					if
						endInput.UserInputType == Enum.UserInputType.MouseButton1
						or endInput.UserInputType == Enum.UserInputType.Touch
					then
						resizing = false
						updateResizeVisual()
						if inputEndedConnection then
							inputEndedConnection:Disconnect()
							inputEndedConnection = nil
						end
					end
				end)
			end
		end)

		resizeInputConnection = UserInputService.InputChanged:Connect(function(input)
			if
				resizing
				and (
					input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
				)
			then
				local delta = input.Position - resizeStart
				local minSize = MainFrameSizeConstraint.MinSize
				local newWidth = math.max(minSize.X, startSize.X + delta.X)
				local newHeight = math.max(minSize.Y, startSize.Y + delta.Y)
				MainFrame.Size = UDim2.fromOffset(newWidth, newHeight)
			end
		end)
	end

	-- Shared theme-matched tooltip for the minimize pill buttons.
	local tooltip = Tooltip.new(ScreenGui, theme)
	self.Tooltip = tooltip

	local function minimizePreset()
		return animationStyle == "Snappy" and "WindowToggleSnappy" or "WindowToggle"
	end

	-- CanvasGroup: GroupTransparency dims the whole pill (background, buttons, stroke) at rest in one property.
	local pill = Instance.new("CanvasGroup")
	pill.Name = UUID.Generate("MinimizePill")
	pill.AutomaticSize = Enum.AutomaticSize.None
	pill.Size = UDim2.fromOffset(56, 56)

	local pillLayout -- forward decl: the UIListLayout is created further down
	local pillScroll -- forward decl: the scrolling strip inside the pill

	-- Position and tooltip side come from SettingsStore.PillPosition; the tip opens away from the nearest screen edge.
	local PILL_SIDES = {
		right = { anchor = Vector2.new(1, 0.5), position = UDim2.new(1, -12, 0.5, 0), tip = "Left" },
		left = { anchor = Vector2.new(0, 0.5), position = UDim2.new(0, 12, 0.5, 0), tip = "Right" },
		top = { anchor = Vector2.new(0.5, 0), position = UDim2.new(0.5, 0, 0, 12), tip = "Bottom" },
		bottom = { anchor = Vector2.new(0.5, 1), position = UDim2.new(0.5, 0, 1, -12), tip = "Top" },
	}
	local function currentPillSide()
		local s = SettingsStore.Get("PillPosition")
		return PILL_SIDES[s] and s or "right"
	end

	-- Size the pill to its buttons, capped to a viewport slice so a long tab list scrolls instead of running off-screen.
	local function updatePillSize()
		if not (pillScroll and pillLayout) then
			return
		end
		local side = currentPillSide()
		local horizontal = (side == "top" or side == "bottom")
		local count = (self.TabGroup and #self.TabGroup.Tabs) or 0
		local content = count > 0 and (count * 40 + (count - 1) * 8) or 40

		local viewport = ScreenGui.AbsoluteSize
		if viewport.X <= 0 or viewport.Y <= 0 then
			local cam = workspace.CurrentCamera
			viewport = (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
		end
		-- Seven tabs fit without a scrollbar; an eighth turns the pill into a scroller.
		local scrollable = count > 7
		local limit = horizontal and math.max(160, viewport.X * 0.8) or math.max(160, viewport.Y * 0.6)
		local visible = scrollable and math.min(content, limit) or content

		if horizontal then
			pill.Size = UDim2.fromOffset(visible + 16, 56)
		else
			pill.Size = UDim2.fromOffset(56, visible + 16)
		end
		pillScroll.ScrollingEnabled = scrollable
		pillScroll.ScrollBarThickness = scrollable and 1 or 0
		if not scrollable then
			pillScroll.ScrollBarImageTransparency = 1
			pillScroll.CanvasPosition = Vector2.new(0, 0)
		end
	end

	local function applyPillPosition()
		local side = currentPillSide()
		local def = PILL_SIDES[side]
		pill.AnchorPoint = def.anchor
		pill.Position = def.position
		-- Top/bottom docks run horizontally; left/right stay vertical, so flip layout direction too.
		local horizontal = (side == "top" or side == "bottom")
		if pillLayout then
			pillLayout.FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
		end
		if pillScroll then
			pillScroll.ScrollingDirection = horizontal and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y
			pillScroll.AutomaticCanvasSize = horizontal and Enum.AutomaticSize.X or Enum.AutomaticSize.Y
		end
		updatePillSize()
	end
	local function pillTooltipSide()
		return PILL_SIDES[currentPillSide()].tip
	end
	self.SetPillPosition = function(_self, side)
		SettingsStore.Set("PillPosition", side)
		applyPillPosition()
	end

	-- Compact mode collapses the sidebar and moves pills under the title bar.
	do
		local COMPACT_ENTER = 672 -- below this width -> compact (auto); 672 is the last expanded width
		local COMPACT_EXIT = 712 -- above this width -> expanded (hysteresis)
		local compact = false
		local saved = nil -- captured expanded values for restore
		local initialized = false -- set true after the first deferred resolve; gates AUTO mode

		local function captureExpanded()
			return {
				tabListSize = TabList.Size,
				tabListPos = TabList.Position,
				tabListAnchor = TabList.AnchorPoint,
				tabListFill = TabListLayout.FillDirection,
				tabListScrollDir = TabList.ScrollingDirection,
				tabListAutoSize = TabList.AutomaticCanvasSize,
				tabListVBarPos = TabList.VerticalScrollBarPosition,
				tabListParent = TabList.Parent,
				tabListZ = TabList.ZIndex,
				searchBarSize = SearchBar.Size,
				searchBarPos = SearchBar.Position,
				searchBarParent = SearchBar.Parent,
				searchBarAnchor = SearchBar.AnchorPoint,
				searchBarLayoutOrder = SearchBar.LayoutOrder,
				searchBarDividerPos = SearchBarBottomDivider.Position,
				contentSize = Content.Size,
				contentPos = Content.Position,
				contentBgSize = ContentBackground.Size,
				contentBgPos = ContentBackground.Position,
				contentBgAnchor = ContentBackground.AnchorPoint,
				pageTitlePos = PageTitle.Position,
				pageTitleVisible = PageTitle.Visible,
				settingsPagesPos = SettingsPages.Position,
				tabContentPos = TabContent.Position,
				tabContentPadTop = TabContentPadding.PaddingTop,
				scriptInfoParent = ScriptInfo.Parent,
				scriptInfoSize = ScriptInfo.Size,
				scriptInfoPos = ScriptInfo.Position,
				sidebarVisible = Sidebar.Visible,
				minSize = MainFrameSizeConstraint.MinSize,
			}
		end

		-- Restyle one tab button plus its inner label/icon; flipping only the button Size would leave the children hanging off a short/wide button.
		local function styleTabButton(btn, horizontal)
			if not btn or not btn:IsA("TextButton") then
				return
			end
			-- Raise the pill above Content/ContentBackground/SettingsPages so it can't hide behind them.
			btn.ZIndex = 60
			local tabName = btn:FindFirstChild(UUID.Static("TabName"))
			local tabImage = btn:FindFirstChild(UUID.Static("TabImage"))
			if tabName then
				tabName.ZIndex = 61
			end
			if tabImage then
				tabImage.ZIndex = 61
			end
			if horizontal then
				btn.Size = UDim2.fromOffset(100, 30)
				if tabImage then
					tabImage.AnchorPoint = Vector2.new(0, 0.5)
					tabImage.Position = UDim2.new(0, 12, 0.5, 0)
				end
				if tabName then
					tabName.AnchorPoint = Vector2.new(0, 0.5)
					tabName.Position = UDim2.new(0, 34, 0.5, 0)
					tabName.Size = UDim2.new(1, -44, 1, 0)
				end
			else
				btn.Size = UDim2.new(0.849, 0, 0, 40)
				if tabImage then
					tabImage.AnchorPoint = Vector2.new(0, 0.5)
					tabImage.Position = UDim2.new(0, 15, 0.5, 0)
				end
				if tabName then
					tabName.AnchorPoint = Vector2.new(0.5, 0.5)
					tabName.Position = UDim2.fromScale(0.647, 0.5)
					tabName.Size = UDim2.fromScale(0.636, 0.714)
				end
			end
		end

		local function restyleTabButtons(horizontal)
			for _, child in ipairs(TabList:GetChildren()) do
				styleTabButton(child, horizontal)
			end
		end

		local function applyCompact(on)
			if not saved then
				saved = captureExpanded()
			end
			if on then
				-- Reparent the row out of the sidebar BEFORE hiding it: hiding first trips the spin visibility gate and pauses every tab spin for good.
				TabList.LayoutOrder = -1
				TabList.ZIndex = 50 -- stay above SettingsPages/ContentBackground while compact
				TabList.ClipsDescendants = true -- clip pills to the row (they scroll horizontally)
				TabList.Parent = MainFrame
				Sidebar.Visible = false -- hide the sidebar AFTER the row has moved out
				TabList.ScrollingDirection = Enum.ScrollingDirection.X
				-- Hide the tab-row scrollbar entirely instead of the usual 0.5 reveal.
				TabList:SetAttribute(UUID.Static("CompactNoScrollbar"), true)
				TabList.ScrollBarImageTransparency = 1
				TabList.AutomaticCanvasSize = Enum.AutomaticSize.X
				-- Pin canvas height to the row, or VerticalAlignment.Center centers the pills inside the leftover canvas and they render at the bottom.
				TabList.CanvasSize = UDim2.fromScale(0, 1)
				TabList.CanvasPosition = Vector2.new(0, 0)
				TabList.AnchorPoint = Vector2.new(0.5, 0)
				TabList.Position = UDim2.new(0.5, 0, 0, 65)
				TabList.Size = UDim2.new(0.95, 0, 0, 40)
				-- Bottom padding, plus hide the sidebar dividers that spaced the pills.
				local compactPad = TabList:FindFirstChild(UUID.Static("CompactPad"))
				if not compactPad then
					compactPad = Instance.new("UIPadding")
					compactPad.Name = UUID.Static("CompactPad")
					compactPad.Parent = TabList
				end
				compactPad.PaddingBottom = UDim.new(0, 4)
				compactPad.PaddingLeft = UDim.new(0, 7)
				for _, child in ipairs(TabList:GetChildren()) do
					if child:GetAttribute(UUID.Static("IsDivider")) then
						child.Visible = false
					end
				end
				TabListLayout.FillDirection = Enum.FillDirection.Horizontal
				TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
				TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
				restyleTabButtons(true)
				-- Search docks into the window-controls cluster, laid out by its UIListLayout.
				SearchBar.Parent = WindowControls
				SearchBar.AnchorPoint = Vector2.new(0, 0)
				SearchBar.LayoutOrder = -1 -- before the settings button (which is order 0)
				SearchBar.Size = UDim2.fromOffset(120, 20)
				SearchBar.Position = UDim2.fromScale(0, 0)
				SearchBarBottomDivider.Position = UDim2.new(0.5, 0, 0, 30)
				SearchBarBottomDivider.Visible = false -- hidden while docked in the controls
				-- Content full width, below the tab row.
				Content.Size = UDim2.new(1, -16, 1, -124)
				Content.Position = UDim2.fromOffset(8, 90)
				Tween.Play(Content, "Smooth", { Position = UDim2.fromOffset(8, 100) })
				ContentBackground.AnchorPoint = Vector2.new(0, 0)
				ContentBackground.Size = UDim2.fromScale(1, 1)
				ContentBackground.Position = UDim2.fromScale(0, 0)
				-- Compact: square up every corner (full-bleed content background).
				ContentBackgroundCorner.TopLeftRadius = UDim.new(0, 6)
				ContentBackgroundCorner.BottomLeftRadius = UDim.new(0, 6)
				ContentBackgroundCorner.TopRightRadius = UDim.new(0, 6)
				ContentBackgroundCorner.BottomRightRadius = UDim.new(0, 6)
				-- Script info replaces the page title at the top-left of the compact title bar.
				PageTitle.Visible = false
				-- Push the settings pages down so they clear the compact title bar and docked search.
				SettingsPages.Position = UDim2.new(0.5, 0, 0.5, 12)
				TabContent.Position = UDim2.fromScale(0.5, 0.55)
				TabContentPadding.PaddingTop = UDim.new(0, 0)
				ScriptInfo.Parent = MainFrame
				ScriptInfo.Size = UDim2.fromOffset(200, 40)
				ScriptInfo.Position = UDim2.fromOffset(5, 5)
				-- Content goes 2-column -> 1-column.
				if self.TabGroup and self.TabGroup.SetCompact then
					self.TabGroup:SetCompact(true)
				end
				-- Smaller minimum so the window can actually shrink.
				MainFrameSizeConstraint.MinSize = Vector2.new(425, 380)
				-- Animate in: row slides down into place from slightly above.
				TabList.Position = UDim2.new(0.5, 0, 0, 60)
				Tween.Play(TabList, "Smooth", { Position = UDim2.new(0.5, 0, 0, 65) })
			else
				Sidebar.Visible = saved.sidebarVisible
				TabList.Parent = saved.tabListParent
				TabList.ZIndex = saved.tabListZ
				TabList.Size = saved.tabListSize
				TabList.Position = saved.tabListPos
				TabList.AnchorPoint = saved.tabListAnchor
				local compactPad = TabList:FindFirstChild(UUID.Static("CompactPad"))
				if compactPad then
					compactPad:Destroy()
				end
				for _, child in ipairs(TabList:GetChildren()) do
					if child:GetAttribute(UUID.Static("IsDivider")) then
						child.Visible = true
					end
				end
				TabList.ScrollingDirection = saved.tabListScrollDir
				TabList:SetAttribute(UUID.Static("CompactNoScrollbar"), false)
				TabList.AutomaticCanvasSize = saved.tabListAutoSize
				TabList.VerticalScrollBarPosition = saved.tabListVBarPos
				TabListLayout.FillDirection = saved.tabListFill
				TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
				TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
				restyleTabButtons(false)
				SearchBar.Parent = saved.searchBarParent
				SearchBar.AnchorPoint = saved.searchBarAnchor
				SearchBar.LayoutOrder = saved.searchBarLayoutOrder
				SearchBar.Size = saved.searchBarSize
				SearchBar.Position = saved.searchBarPos
				SearchBarBottomDivider.Position = saved.searchBarDividerPos
				SearchBarBottomDivider.Visible = true -- sidebar searchbar shows its divider again
				Content.Size = saved.contentSize
				Content.Position = saved.contentPos
				ContentBackground.AnchorPoint = saved.contentBgAnchor
				ContentBackground.Size = saved.contentBgSize
				ContentBackground.Position = saved.contentBgPos
				-- Restore the expanded corner treatment (rounded right edge only).
				ContentBackgroundCorner.TopLeftRadius = UDim.new(0, 0)
				ContentBackgroundCorner.BottomLeftRadius = UDim.new(0, 0)
				ContentBackgroundCorner.TopRightRadius = UDim.new(0, 6)
				ContentBackgroundCorner.BottomRightRadius = UDim.new(0, 6)
				PageTitle.Position = saved.pageTitlePos
				PageTitle.Visible = saved.pageTitleVisible
				SettingsPages.Position = saved.settingsPagesPos
				TabContent.Position = saved.tabContentPos
				TabContentPadding.PaddingTop = saved.tabContentPadTop
				ScriptInfo.Parent = saved.scriptInfoParent
				ScriptInfo.Size = saved.scriptInfoSize
				ScriptInfo.Position = saved.scriptInfoPos
				-- Restore 1-column -> 2-column.
				if self.TabGroup and self.TabGroup.SetCompact then
					self.TabGroup:SetCompact(false)
				end
				MainFrameSizeConstraint.MinSize = saved.minSize
			end
		end

		self.SetCompact = function(_self, on)
			compact = on and true or false
			applyCompact(compact)
		end

		local function resolveAndApply()
			local mode = SettingsStore.Get("CompactMode") or "auto"
			if mode == "always" then
				if not compact then
					compact = true
					applyCompact(true)
				end
			elseif mode == "never" then
				if compact then
					compact = false
					applyCompact(false)
				end
			else
				-- Auto only reacts to real resizes: the default window can legitimately start narrow in small viewports.
				if not initialized then
					return
				end
				local w = MainFrame.AbsoluteSize.X
				if not compact and w < COMPACT_ENTER then
					compact = true
					applyCompact(true)
				elseif compact and w > COMPACT_EXIT then
					compact = false
					applyCompact(false)
				end
			end
		end
		self._ResolveCompact = resolveAndApply

		-- Tabs added while compact get restyled so they aren't left in sidebar sizing.
		TabList.ChildAdded:Connect(function(child)
			if not compact then
				return
			end
			if child:GetAttribute(UUID.Static("IsDivider")) then
				child.Visible = false
			else
				styleTabButton(child, true)
			end
		end)

		MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(resolveAndApply)
		-- First pass applies only a forced mode; auto waits for a real resize so the window starts in its full layout.
		task.defer(function()
			local mode = SettingsStore.Get("CompactMode") or "auto"
			if mode == "always" or mode == "never" then
				resolveAndApply()
			end
			initialized = true
		end)
	end
	pill.BackgroundColor3 = theme.PopupBackgroundColor or Color3.fromRGB(15, 15, 16)
	pill.BackgroundTransparency = 1
	pill.BorderSizePixel = 0
	pill.Visible = false
	pill.ZIndex = 1500
	pill.Parent = ScreenGui
	self.MinimizePill = pill

	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(1, 0)
	pillCorner.Parent = pill
	local pillStroke = Instance.new("UIStroke")
	pillStroke.Color = theme.StrokeColor or Color3.fromRGB(255, 255, 255)
	-- Rest fully transparent: not bound to the theme (that would stamp ThemeLive_Transparency), so hover alone gates it and PageFade restores the hidden rest state.
	pillStroke.Transparency = 1
	pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pillStroke:SetAttribute(UUID.Static("PageFadeBase"), 1)
	pillStroke.Parent = pill
	local pillShadow = Instance.new("UIShadow")
	pillShadow.Color = theme.PopupShadowColor or Color3.fromRGB(0, 0, 0)
	pillShadow.BlurRadius = UDim.new(0, 16)
	pillShadow.Transparency = 1 -- rest: invisible; only shows on hover (0.5)
	pillShadow:SetAttribute(UUID.Static("PageFadeBase"), 1)
	pillShadow.Parent = pill
	local pillScale = Instance.new("UIScale")
	pillScale.Scale = 1
	pillScale.Parent = pill

	-- Dim + small at rest so the pill doesn't block the game view; hovering it or any of its buttons makes it fully visible with a bounce.
	local PILL_REST_GROUP = 0.55 -- dim everything at rest so it doesn't block the game
	local PILL_HOVER_GROUP = 0
	local PILL_REST_SCALE = 0.85
	local PILL_HOVER_SCALE = 1
	local pillHovered = false
	pill.GroupTransparency = PILL_REST_GROUP

	-- CanvasGroup transparency doesn't cover the shadow, so it's gated to hover separately.
	local function applyPillShadow()
		pillShadow.Transparency = (pillHovered and pill.Visible) and 0.5 or 1
	end

	-- Same for the stroke: gated to hover at rest, live theme colour on hover (color is a BindColor).
	local function applyPillStroke()
		local live = self._theme or theme
		pillStroke.Transparency = (pillHovered and pill.Visible) and (live.StrokeTransparency or 0.93) or 1
	end

	pill.MouseEnter:Connect(function()
		pillHovered = true
		Tween.Play(pill, "Fast", { GroupTransparency = PILL_HOVER_GROUP })
		Tween.Play(pillScale, "HoverIn", { Scale = PILL_HOVER_SCALE })
		applyPillShadow()
		applyPillStroke()
	end)
	pill.MouseLeave:Connect(function()
		pillHovered = false
		Tween.Play(pill, "Fast", { GroupTransparency = PILL_REST_GROUP })
		Tween.Play(pillScale, "HoverOut", { Scale = PILL_REST_SCALE })
		applyPillShadow()
		applyPillStroke()
	end)

	-- Buttons live in a scrolling strip so a long tab list can't run off-screen; the scrollbar reveals on scroll and fades after 1.5s.
	pillScroll = Instance.new("ScrollingFrame")
	pillScroll.Name = UUID.Static("MinimizePillScroll")
	pillScroll.Active = true
	pillScroll.BackgroundTransparency = 1
	pillScroll.BorderSizePixel = 0
	pillScroll.ClipsDescendants = true
	pillScroll.ScrollBarThickness = 1
	pillScroll.ScrollBarImageColor3 = theme.TertiaryColor or Color3.fromRGB(120, 132, 150)
	pillScroll.ScrollBarImageTransparency = 1
	pillScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
	pillScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	pillScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pillScroll.CanvasSize = UDim2.fromScale(0, 0)
	pillScroll.Size = UDim2.new(1, -8, 1, -8)
	pillScroll.Position = UDim2.fromOffset(4, 4)
	pillScroll.Parent = pill

	local pillScrollbarTimer
	pillScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if not pill.Visible or not pillScroll.ScrollingEnabled then
			pillScroll.ScrollBarImageTransparency = 1
			return
		end
		Tween.Play(pillScroll, "Fast", { ScrollBarImageTransparency = 0.5 })
		if pillScrollbarTimer then
			task.cancel(pillScrollbarTimer)
		end
		pillScrollbarTimer = task.delay(1.5, function()
			Tween.Play(pillScroll, "Fast", { ScrollBarImageTransparency = 1 })
			pillScrollbarTimer = nil
		end)
	end)

	local pillPad = Instance.new("UIPadding")
	pillPad.PaddingTop = UDim.new(0, 4)
	pillPad.PaddingBottom = UDim.new(0, 4)
	pillPad.PaddingLeft = UDim.new(0, 4)
	pillPad.PaddingRight = UDim.new(0, 4)
	pillPad.Parent = pillScroll
	pillLayout = Instance.new("UIListLayout")
	pillLayout.Padding = UDim.new(0, 8)
	pillLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pillLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	pillLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pillLayout.Parent = pillScroll
	applyPillPosition() -- now that the scroller/layout exist, apply the saved side

	local minimizeWindow
	local restoreWindow
	-- Pill buttons are built once per tab and reused across minimize/restore cycles; destroying them made icons snap invisible instead of fading.
	local pillButtonByTab = {}

	local function stylePillContainer(t)
		pill.BackgroundColor3 = t.PopupBackgroundColor or Color3.fromRGB(15, 15, 16)
		pill.BackgroundTransparency = 0.05
		pill.GroupTransparency = PILL_REST_GROUP
		pillStroke.Color = t.StrokeColor or Color3.fromRGB(255, 255, 255)
		-- Stroke transparency is hover-gated, never stamped here, so a theme switch can't leave it visible at rest.
		applyPillStroke()
		pillShadow.Color = t.PopupShadowColor or Color3.fromRGB(0, 0, 0)
		applyPillShadow()
		if pillScroll then
			pillScroll.ScrollBarImageColor3 = t.TertiaryColor or Color3.fromRGB(120, 132, 150)
		end
	end

	-- Restyle ONE existing pill button to match its tab's current active state.
	local function stylePillButton(btn, tab, t, isActive)
		btn.BackgroundColor3 = t.ActiveTabButtonColor or t.PrimaryColor or Color3.fromRGB(99, 102, 241)
		btn.BackgroundTransparency = isActive and 0.1 or 1
		local back = btn:FindFirstChild(UUID.Static("BackImage"))
		if back then
			back.Image = (tab.BackImage and tab.BackImage.Image) or "rbxassetid://11094025229"
			back.ImageTransparency = isActive and 0 or 1
			-- Restart or stop the spin only when the active state changed, so spamming minimize doesn't reset the sweep.
			local wasActive = btn:GetAttribute(UUID.Static("PillActive")) == true
			if isActive ~= wasActive then
				btn:SetAttribute(UUID.Static("PillActive"), isActive)
				local grad = back:FindFirstChildOfClass("UIGradient")
				if grad then
					if isActive then
						Tween.StartSpin(grad, { Rotation = 360 }, "SpinIdle")
					else
						Tween.StopSpin(grad)
					end
				end
			end
		end
		local icon = btn:FindFirstChild(UUID.Static("PillIcon"))
		if icon then
			icon.Image = (tab.TabImage and tab.TabImage.Image) or "rbxassetid://8445470392"
			icon.ImageColor3 = isActive and (t.ActiveTabIconColor or Color3.fromRGB(255, 255, 255))
				or (t.InactiveTabIconColor or Color3.fromRGB(200, 200, 200))
			icon.ImageTransparency = isActive and (t.ActiveTabIconTransparency or 0.2)
				or (t.InactiveTabIconTransparency or 0.6)
		end
	end

	-- Build a pill button for one tab. Called at most ONCE per tab.
	local function createPillButton(tab, i, t)
		local isActive = (tab == (self.TabGroup and self.TabGroup.ActiveTab))
		local btn = Instance.new("TextButton")
		btn.Name = UUID.Generate("PillTab")
		btn.Size = UDim2.fromOffset(40, 40)
		-- Only the ACTIVE tab shows its filled background; the rest are plain.
		btn.BackgroundColor3 = t.ActiveTabButtonColor or t.PrimaryColor or Color3.fromRGB(99, 102, 241)
		btn.BackgroundTransparency = isActive and 0.1 or 1
		btn.AutoButtonColor = false
		btn.Text = ""
		btn.LayoutOrder = i
		btn.ZIndex = 1501
		btn.Parent = pillScroll
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = btn
		-- UIScale grows from the center -> bouncy hover feel.
		local btnScale = Instance.new("UIScale")
		btnScale.Scale = 1
		btnScale.Parent = btn
		-- Spinning-gradient backdrop, same look as the sidebar tab buttons.
		local back = Instance.new("ImageLabel")
		back.Name = UUID.Static("BackImage")
		back.BorderSizePixel = 0
		back.BackgroundTransparency = 1
		back.Image = (tab.BackImage and tab.BackImage.Image) or "rbxassetid://11094025229"
		-- Backdrop + spin ONLY on the active tab.
		back.ImageTransparency = isActive and 0 or 1
		back.Size = UDim2.fromScale(1, 1)
		back.ZIndex = 1501
		back.Parent = btn
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(1, 0)
		bc.Parent = back
		local grad = Instance.new("UIGradient")
		grad.Rotation = 0
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.000, 0),
			NumberSequenceKeypoint.new(0.134, 0.3),
			NumberSequenceKeypoint.new(0.242, 0.53125),
			NumberSequenceKeypoint.new(0.371, 0.69375),
			NumberSequenceKeypoint.new(0.484, 0.80625),
			NumberSequenceKeypoint.new(0.590, 0.91875),
			NumberSequenceKeypoint.new(0.681, 0.975),
			NumberSequenceKeypoint.new(1.000, 1),
		})
		grad.Parent = back
		local icon = Instance.new("ImageLabel")
		icon.Name = UUID.Static("PillIcon")
		icon.BorderSizePixel = 0
		icon.BackgroundTransparency = 1
		icon.Image = (tab.TabImage and tab.TabImage.Image) or "rbxassetid://8445470392"
		icon.ImageColor3 = isActive and (t.ActiveTabIconColor or Color3.fromRGB(255, 255, 255))
			or (t.InactiveTabIconColor or Color3.fromRGB(200, 200, 200))
		icon.ImageTransparency = isActive and (t.ActiveTabIconTransparency or 0.2)
			or (t.InactiveTabIconTransparency or 0.6)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.Size = UDim2.fromOffset(18, 18)
		icon.ZIndex = 1502
		icon.Parent = btn
		btn.MouseEnter:Connect(function()
			Tween.Play(btnScale, "HoverIn", { Scale = 1.18 })
			tooltip:ShowAt(btn, tab.Name, pillTooltipSide(), 11)
		end)
		btn.MouseLeave:Connect(function()
			Tween.Play(btnScale, "HoverOut", { Scale = 1 })
			tooltip:Hide()
		end)
		btn.MouseButton1Click:Connect(function()
			-- Mirror the sidebar tab click: leave the settings pages, show the normal tab content.
			if self.SettingsPages then
				self.SettingsPages.Visible = false
			end
			if self.TabContent then
				self.TabContent.Visible = true
			end
			if self.TabGroup then
				self.TabGroup:SetActiveTab(tab)
			end
			-- SetActiveTab early-returns on the already-active tab, so a pill click forces its FadeLayer visible (Settings may have hidden it).
			if tab and tab.FadeLayer then
				tab.FadeLayer.Visible = true
				PageFade.Snap(tab.FadeLayer, 0)
			end
			restoreWindow()
		end)
		pillButtonByTab[tab] = btn
		stylePillButton(btn, tab, t, isActive)
	end

	-- Ensure every tab has a pill button and restyle them to the live theme/active state; idempotent, never destroys live buttons.
	local function buildPill(themeOverride)
		local t = themeOverride or self._theme or theme
		tooltip:SetTheme(t)
		stylePillContainer(t)
		if not self.TabGroup then
			return
		end
		-- Drop buttons whose tab no longer exists.
		local live = {}
		for _, tab in ipairs(self.TabGroup.Tabs) do
			live[tab] = true
		end
		for tab, btn in pairs(pillButtonByTab) do
			if not live[tab] then
				btn:Destroy()
				pillButtonByTab[tab] = nil
			end
		end
		-- Create missing buttons, restyle the rest.
		for i, tab in ipairs(self.TabGroup.Tabs) do
			local btn = pillButtonByTab[tab]
			if not btn then
				createPillButton(tab, i, t)
			else
				btn.LayoutOrder = i
				stylePillButton(btn, tab, t, tab == self.TabGroup.ActiveTab)
			end
		end
		updatePillSize()
	end

	-- Exposed so Window:Tab and ApplyTheme keep the pill in sync.
	self._refreshPill = buildPill

	-- Guard against overlapping minimize/restore: only the stable states ("shown"/"hidden") accept a toggle, so spamming the keybind can't capture a half-faded cache or fire callbacks out of order.
	local minimizeState = "shown"

	minimizeWindow = function()
		if minimizeState ~= "shown" then
			return
		end
		minimizeState = "minimizing"
		self._minimized = true
		PageAwareness.Refresh()
		Sound.Play("UIClose")
		self._windowFaded = true
		-- Fade the scrollbar out explicitly (GroupTransparency doesn't cover it) and cancel its hide timer so it can't fight this tween.
		if tabListScrollbarTimer then
			task.cancel(tabListScrollbarTimer)
			tabListScrollbarTimer = nil
		end
		if TabList then
			Tween.Play(TabList, "Fast", { ScrollBarImageTransparency = 1 })
		end
		buildPill()
		-- Snap the controls to their idle look before capturing, so the fade cache stores 0.5 rather than the hovered state.
		for _, ctrl in ipairs({ MinimizeButton, MaximizeButton, CloseButton }) do
			if ctrl then
				ctrl.ImageTransparency = 0.5
				local s = ctrl:FindFirstChildOfClass("UIScale")
				if s then
					s.Scale = 1
				end
			end
		end
		-- Reveal the pill only after the fade completes (event-driven), so bright elements like the video finish fading first.
		PageFade.Hide(MainFrame, false, function()
			MainFrame.Visible = false
			pillHovered = false
			pill.Visible = true
			pill.BackgroundTransparency = 0.05
			pill.GroupTransparency = 1
			pillScale.Scale = 0.7
			-- GroupTransparency doesn't cover the pill's stroke/shadow, so snap them hidden and fade them in with the group.
			PageFade.FadeDecorations(pill, true, true)
			-- Pop in, settling at the REST (dim, small) state since it isn't hovered.
			Tween.Play(pill, "Fast", { GroupTransparency = PILL_REST_GROUP })
			PageFade.FadeDecorations(pill, false, false)
			Tween.Play(pillScale, "HoverIn", { Scale = PILL_REST_SCALE })
			applyPillShadow()
			applyPillStroke()
			minimizeState = "hidden"
		end, PageFade.WINDOW_PRESET)
	end

	restoreWindow = function()
		if minimizeState ~= "hidden" then
			return
		end
		minimizeState = "restoring"
		self._minimized = false
		PageAwareness.Refresh()
		Sound.Play("UIOpen")
		tooltip:Hide()
		-- Reveal the window immediately, in parallel with the pill fading out; the active page already rests at its base, so no re-capture is needed.
		MainFrame.Visible = true
		PageFade.Show(MainFrame, false, function()
			self._windowFaded = false
			minimizeState = "shown"
		end, PageFade.WINDOW_PRESET)
		-- Fade the pill out in parallel with the window fading in, then hide it.
		pillHovered = false
		applyPillShadow()
		applyPillStroke()
		PageFade.Hide(pill, false, function()
			pill.Visible = false
			pillScale.Scale = 1
			pillHovered = false
			applyPillShadow()
			applyPillStroke()
		end)
		Tween.Play(pillScale, "Fast", { Scale = 0.85 })
		task.delay(0.3, function()
			pill.Visible = false
			pillScale.Scale = 1
			pillHovered = false
			applyPillShadow()
			applyPillStroke()
		end)
	end

	-- For external callers (e.g. the Minimize keybind in UI Settings); only acts from a stable state, and restore returns to whatever was showing.
	self.ToggleMinimize = function()
		if self._destroyed then
			return
		end
		if minimizeState == "shown" then
			minimizeWindow()
		elseif minimizeState == "hidden" then
			restoreWindow()
		end
	end

	MinimizeButton.MouseButton1Click:Connect(function()
		self.ToggleMinimize()
	end)

	-- Global minimize keybind; ignored while a TextBox has focus so typing the letter never minimizes.
	minimizeKeyConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if input.KeyCode.Name == self._minimizeKey and self.ToggleMinimize then
			self.ToggleMinimize()
		end
	end)

	-- Restore the window to its default position + size (used by UI Settings).
	self.ResetLayout = function()
		Tween.Play(MainFrame, minimizePreset(), {
			Size = UDim2.fromScale(0.72026, 0.96995),
			Position = UDim2.fromScale(0.013, 0.015),
		})
	end

	-- Maximize (full-screen toggle)
	local preMaxSize = MainFrame.Size
	local preMaxPosition = MainFrame.Position
	MaximizeButton.MouseButton1Click:Connect(function()
		-- Decide from the actual size, not a flag: a manual resize while maximized left the flag stale.
		local isFull = MainFrame.Size.X.Scale >= 0.999 and MainFrame.Size.Y.Scale >= 0.999
		if isFull then
			Tween.Play(MainFrame, minimizePreset(), {
				Size = preMaxSize,
				Position = preMaxPosition,
			})
		else
			preMaxSize = MainFrame.Size
			preMaxPosition = MainFrame.Position
			Tween.Play(MainFrame, minimizePreset(), {
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0, 0),
			})
		end
	end)

	-- Tear down listeners, tasks, tweens and cached popups on close.
	self._teardown = function()
		if self._destroyed then
			return
		end
		self._destroyed = true

		if dragInputConnection then
			dragInputConnection:Disconnect()
			dragInputConnection = nil
		end
		if resizeInputConnection then
			resizeInputConnection:Disconnect()
			resizeInputConnection = nil
		end
		if minimizeKeyConnection then
			minimizeKeyConnection:Disconnect()
			minimizeKeyConnection = nil
		end
		if inputEndedConnection then
			inputEndedConnection:Disconnect()
			inputEndedConnection = nil
		end
		clockStopped = true

		-- Stop tracking page state; component Destroying handlers become harmless no-ops.
		PageAwareness.Detach()

		-- Persist any debounced settings change before the window goes away.
		SettingsStore.Flush()
		-- Write any pending config auto-save while components still exist.
		if self.ConfigManager then
			self.ConfigManager:Flush()
		end

		if tabListScrollbarTimer then
			task.cancel(tabListScrollbarTimer)
			tabListScrollbarTimer = nil
		end
		if pillScrollbarTimer then
			task.cancel(pillScrollbarTimer)
			pillScrollbarTimer = nil
		end

		-- One sparse sweep over the active-tween registry instead of a per-descendant tree probe.
		Tween.CancelAllUnder(ScreenGui)

		if self.Aurora then
			self.Aurora:Destroy()
			self.Aurora = nil
		end

		if self._notification then
			self._notification:Destroy()
			self._notification = nil
		end
		if self._dropdownPopups then
			for _, popup in pairs(self._dropdownPopups) do
				popup:Destroy()
			end
			self._dropdownPopups = nil
		end
		if self._colorPickerPopups then
			for _, popup in pairs(self._colorPickerPopups) do
				popup:Destroy()
			end
			self._colorPickerPopups = nil
		end
		self._toasts = nil
	end

	local function doClose()
		-- Single close pipeline: confirm, then Destroy owns sound, teardown order and lifetime everywhere.
		self:Destroy()
	end

	CloseButton.MouseButton1Click:Connect(function()
		-- Confirm first unless the user turned confirmation off.
		if not SettingsStore.Get("ConfirmClose") then
			doClose()
			return
		end
		-- Name the prompt after the script (Settings.Title) so it reads "Close <name>?".
		local appName = (ScriptName.Text ~= "" and ScriptName.Text) or "the UI"
		self:UINotification({
			Title = "Close " .. appName .. "?",
			Description = 'Are you sure you want to <font color="#FF0000">close</font> ' .. appName .. "?",
			TitleColor = Color3.fromRGB(255, 0, 0),
			ConfirmText = "Yes, close it",
			CancelText = "No, keep it open",
			OnConfirm = doClose,
		})
	end)

	self.TabGroup = TabGroup.new(self, theme)
	self.SettingsTabGroup = SettingsTabGroup.new(self, theme)
	-- Page-awareness needs the window + tab groups before components register, so attach here.
	PageAwareness.Attach(self)

	-- Per-game config manager, created before the settings pages so the Configs page can talk to it.
	self.ConfigManager = ConfigManager.new(self)

	-- Build default settings pages (Themes + UI Settings + Configs) first.
	SettingsSystem.BuildDefaultPages(self)

	-- Extra settings pages: each entry gets Build(window, tab) and a single auto-scrolling column of sections.
	if type(Settings.SettingsPages) == "table" then
		for _, page in ipairs(Settings.SettingsPages) do
			local tab = self.SettingsTabGroup:Tab({
				Name = page.Name or "Settings",
				Icon = page.Icon,
				Active = page.Active,
			})
			if type(page.Build) == "function" then
				-- Custom pages are one auto-sizing column so long pages scroll instead of overflowing.
				tab:Scroller()
				page.Build(self, tab)
			end
		end
	end

	-- Optionally override the initially active settings page.
	if Settings.DefaultSettingsPage then
		self.SettingsTabGroup:SetActiveTabByName(Settings.DefaultSettingsPage)
	end

	-- Apply theme (pass resolved theme table)
	ThemeManager.ApplyTheme(self, theme)

	-- Fade the whole window in from hidden: snap the single GroupTransparency to fully transparent, then tween it back to 0.
	Sound.Play("UIStart")
	PageFade.Snap(MainFrame, 1)
	PageFade.Show(MainFrame, false, nil, PageFade.WINDOW_PRESET)

	-- The page the sidebar search should filter: the active settings page while settings are shown, else the active tab's content.
	self.GetActivePage = function(me)
		if me.SettingsPages and me.SettingsPages.Visible then
			local stab = me.SettingsTabGroup and me.SettingsTabGroup.ActiveTab
			return stab and stab.Page or nil
		end
		local tab = me.TabGroup and me.TabGroup.ActiveTab
		return tab and tab.ContentScroller or nil
	end

	-- Apply the current search text to the active page; called on every keystroke and whenever the active page changes.
	self.ApplySearch = function(me)
		local page = me:GetActivePage()
		if not page then
			return
		end
		SearchFilter.Apply(page, me.SearchBox.Text, me._theme)
	end

	-- Declarative theming for the shell: state-independent properties are bindings here; focus-driven ones stay imperative in ApplyTheme.
	ThemeManager.BindColor(MainFrame, "BackgroundColor3", "WindowColor")
	ThemeManager.BindTransparency(MainFrame, "BackgroundTransparency", "WindowTransparency")
	ThemeManager.BindColor(ContentBackground, "BackgroundColor3", "ContentBackgroundColor")
	ThemeManager.BindTransparency(ContentBackground, "BackgroundTransparency", "ContentBackgroundTransparency")
	ThemeManager.BindColor(Sidebar, "BackgroundColor3", "SidebarColor")
	ThemeManager.BindTransparency(Sidebar, "BackgroundTransparency", "SidebarTransparency")
	ThemeManager.BindColor(MainFrameShadow, "Color", "MainframeShadowColor")
	ThemeManager.BindColor(ResizeButton, "ImageColor3", "TitleTextColor")
	for _, ctrl in ipairs({ MinimizeButton, MaximizeButton, CloseButton }) do
		if ctrl then
			ThemeManager.BindColor(ctrl, "ImageColor3", "WindowControlColor")
		end
	end
	ThemeManager.BindColor(PageTitle, "TextColor3", "TitleTextColor")
	-- PageTitle transparency stays a literal 0.3 to match the rest of the title bar, not PrimaryTextTransparency (which diverged from ScriptName).
	ThemeManager.BindColor(PageTitleDivider, "BackgroundColor3", "TertiaryColor")
	ThemeManager.BindTransparency(PageTitleDivider, "BackgroundTransparency", "SectionDividerTransparency")
	ThemeManager.BindColor(SearchBar, "BackgroundColor3", "SearchBarBackgroundColor")
	ThemeManager.BindColor(SearchBox, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(SearchBox, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(SearchBox, "PlaceholderColor3", "SecondaryTextColor")
	ThemeManager.BindColor(SearchIcon, "ImageColor3", "SecondaryColor")
	ThemeManager.BindColor(SearchBoxStroke, "Color", "StrokeColor")
	ThemeManager.BindColor(SearchBarBottomDivider, "BackgroundColor3", "TertiaryColor")
	ThemeManager.BindColor(SidebarDivider, "BackgroundColor3", "TertiaryColor")
	ThemeManager.BindColor(SettingsButton, "ImageColor3", "AccentColor")
	ThemeManager.BindColor(ScriptName, "TextColor3", "TitleTextColor")
	ThemeManager.BindColor(Username, "TextColor3", "TitleTextColor")
	ThemeManager.BindColor(DisplayName, "TextColor3", "TitleTextColor")
	ThemeManager.BindColor(TimeLabel, "TextColor3", "TitleTextColor")
	ThemeManager.BindColor(TabList, "ScrollBarImageColor3", "TertiaryColor")
	ThemeManager.BindColor(pill, "BackgroundColor3", "PopupBackgroundColor")
	ThemeManager.BindColor(pillStroke, "Color", "StrokeColor")
	ThemeManager.BindColor(pillShadow, "Color", "PopupShadowColor")

	-- The window is the UI root (Base = the ScreenGui), so the descendant registry can't reach it; ThemeManager calls this explicitly for the root.
	self.ApplyTheme = function(me, newTheme)
		local t = ThemeManager.GetTheme(newTheme)
		me._theme = t
		restampThemeGradients(t)

		-- Shell colors/transparencies are bindings now; only the bits that can't be bindings stay here.

		-- Search bar background/stroke transparencies are focus-driven, so stamp them from the current focus state.
		local searchFocused = SearchBar:GetAttribute(UUID.Static("IsSearchFocused"))
		if searchFocused then
			SearchBar.BackgroundTransparency = t.SearchBarBackgroundTransparency or 0
			SearchBoxStroke.Transparency = t.StrokeTransparency or 0.95
		else
			SearchBar.BackgroundTransparency = 1
			SearchBoxStroke.Transparency = 1
		end

		-- Pill colors are bindings; only the lazily-created per-tab buttons need a refresh.
		if me._refreshPill then
			me._refreshPill(t)
		end

		-- Tooltip follows the theme too
		if tooltip and tooltip.SetTheme then
			tooltip:SetTheme(t)
		end

		-- Recolor cached popups live: they live outside the window tree, so ApplyTheme doesn't reach them.
		local function refreshPopups(popups)
			if not popups then
				return
			end
			for id, popup in pairs(popups) do
				if popup.ApplyTheme then
					popup:ApplyTheme(t)
				elseif popup.Destroy then
					popup:Destroy()
					popups[id] = nil
				end
			end
		end
		refreshPopups(me._dropdownPopups)
		refreshPopups(me._colorPickerPopups)

		-- Recolor the cached dialog in place (same ApplyTheme path); drop it if it ever lacks ApplyTheme.
		if me._notification then
			if me._notification.ApplyTheme then
				me._notification:ApplyTheme(t)
			else
				me._notification:Destroy()
				me._notification = nil
			end
		end

		-- Live-recolor toasts still on screen (they sit outside the window tree); prune ones whose Root is gone.
		if me._toasts then
			for i = #me._toasts, 1, -1 do
				local toast = me._toasts[i]
				if toast and toast.Root then
					if toast.ApplyTheme then
						toast:ApplyTheme(t)
					end
				else
					table.remove(me._toasts, i)
				end
			end
		end
	end

	-- Run the shell's own theme pass now that it exists (the earlier ApplyTheme call skipped it).
	self:ApplyTheme(theme)

	return self
end

function Window:SetTitle(text)
	self.ScriptName.Text = text
end

-- Apply a theme by name or table
function Window:SetTheme(themeInput)
	if type(themeInput) == "string" then
		self._themeName = themeInput
		-- Persist named themes so the choice survives sessions; a custom table is session-only.
		SettingsStore.Set("Theme", themeInput)
	end
	-- ThemeManager.UpdateTheme crossfades colors old -> new, invoking Window:ApplyTheme.
	ThemeManager.UpdateTheme(self, themeInput)
end

-- Swap the UI font family live: re-Font.new's every FontFace matching the current family, then persists the choice (nil = built-in).
function Window:SetFont(asset)
	local oldAsset = Constants.FontAsset
	local newAsset = Constants.SetFontAsset(asset)
	SettingsStore.Set("Font", asset)
	if newAsset == oldAsset then
		return
	end
	local base = self.Base
	if not base then
		return
	end
	for _, d in ipairs(base:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			local ff = d.FontFace
			if ff and ff.Family == oldAsset then
				d.FontFace = Font.new(newAsset, ff.Weight, ff.Style)
			end
		end
	end
end

-- Register cleanup that runs when the UI closes or is destroyed: disconnect script-side loops and connections that would otherwise outlive the UI.
-- Several callbacks may be registered; each is pcall-guarded so one bad hook cannot block teardown.
function Window:OnDestroy(callback)
	if type(callback) ~= "function" then
		warn("[Aetheris] Window:OnDestroy expects a function")
		return
	end
	self._destroyCallbacks = self._destroyCallbacks or {}
	table.insert(self._destroyCallbacks, callback)
end

function Window:Destroy()
	-- Re-entrancy guard: a confirm dialog or a second close must not double-play the sound or double-destroy the tree.
	if self._destroyed then
		return
	end

	local closePreset = self.AnimationStyle == "Snappy" and "FadeOut" or "WindowFade"

	-- UIClose is the real close sound ("WindowClose" was never in Sound.Assets).
	Sound.Play("UIClose")

	if self._teardown then
		self._teardown()
	end

	-- User teardown hooks (Window:OnDestroy): kill script-side loops or connections that would outlive the UI; each is pcall-guarded so one bad hook can't strand the rest or block the close animation.
	if self._destroyCallbacks then
		for _, callback in ipairs(self._destroyCallbacks) do
			local ok, err = pcall(callback)
			if not ok then
				warn("[Aetheris] OnDestroy callback errored: " .. tostring(err))
			end
		end
		table.clear(self._destroyCallbacks)
		self._destroyCallbacks = nil
	end

	-- Fade the whole window out: one GroupTransparency tween on the CanvasGroup covers every child.
	local handle = Tween.Play(self.MainFrame, closePreset, { GroupTransparency = 1 })
	-- GroupTransparency doesn't cover the UIShadow, so fade it explicitly.
	if self.MainFrameShadow then
		Tween.Play(self.MainFrameShadow, closePreset, { Transparency = 1 })
	end
	handle.Tween.Completed:Wait()

	Tween.CancelAll(self.MainFrame)
	self.Base:Destroy()
end

-- Tab management methods (delegated to TabGroup)
function Window:Tab(name, icon)
	local tab = self.TabGroup:Tab({ Name = name, Icon = icon })
	if self._refreshPill then
		self._refreshPill()
	end
	return tab
end

function Window:Divider()
	return self.TabGroup:Divider()
end

-- Notification system (create and destroy each time)
function Window:UINotification(Settings)
	if type(Settings) ~= "table" then
		warn("[Window:UINotification] Settings is not a table, defaulting to {}")
		Settings = {}
	end

	-- Only one dialog at a time; the old one is closed and destroyed first.
	if self._notification then
		self._notification:Close()
		self._notification:Destroy()
		self._notification = nil
	end

	Settings.Theme = self._theme
	self._notification = UINotification.new(self.PopUpsFolder, Settings)
	self._notification:Open()
	return self._notification
end

-- Toast notifications (self-destroying). window:Alert/Error/Toast.
local Notification = require("../Popups/Notification")

local function spawnNotification(self, ntype, Settings)
	if type(Settings) ~= "table" then
		Settings = {}
	end
	Settings.Type = ntype
	local notification = Notification.new(self.Notifications, Settings, self._theme)
	-- Track live toasts for SetTheme, pruning dead entries on every spawn so the table can't grow unbounded.
	if not self._toasts then
		self._toasts = {}
	end
	for i = #self._toasts, 1, -1 do
		local t = self._toasts[i]
		if not (t and t.Root) then
			table.remove(self._toasts, i)
		end
	end
	table.insert(self._toasts, notification)
	notification:Show()
	return notification
end

function Window:Alert(Settings)
	return spawnNotification(self, "Alert", Settings)
end

function Window:Error(Settings)
	return spawnNotification(self, "Error", Settings)
end

function Window:Toast(Settings)
	return spawnNotification(self, "Variable", Settings)
end

function Window:DropdownPopUp(id, Settings)
	if type(Settings) ~= "table" then
		warn("[Window:DropdownPopUp] Settings is not a table, defaulting to {}")
		Settings = {}
	end

	Settings.Theme = self._theme

	if not self._dropdownPopups then
		self._dropdownPopups = {}
	end

	local popup = self._dropdownPopups[id]
	if not popup then
		-- Built once per id; the cleanup callback drops it from the cache when destroyed.
		popup = DropdownPopUp.new(self.PopUpsFolder, Settings, function()
			if self._dropdownPopups then
				self._dropdownPopups[id] = nil
			end
			if self._activePopupId == id then
				self._activePopupId = nil
			end
		end)
		self._dropdownPopups[id] = popup
	else
		popup:SetContent(Settings)
	end

	-- One popup at a time: hide whichever else is open.
	if self._activePopupId and self._activePopupId ~= id then
		local activePopup = self._dropdownPopups[self._activePopupId]
		if activePopup then
			activePopup:Hide()
		end
	end

	if popup then
		popup:Open()
		self._activePopupId = id
	end
	return popup
end

function Window:ColorPickerPopUp(id, Settings)
	if type(Settings) ~= "table" then
		warn("[Window:ColorPickerPopUp] Settings is not a table, defaulting to {}")
		Settings = {}
	end

	Settings.Theme = self._theme

	if not self._colorPickerPopups then
		self._colorPickerPopups = {}
	end

	local popup = self._colorPickerPopups[id]
	if not popup then
		popup = ColorPickerPopUp.new(self.PopUpsFolder, Settings, function()
			if self._colorPickerPopups then
				self._colorPickerPopups[id] = nil
			end
			if self._activeColorPickerId == id then
				self._activeColorPickerId = nil
			end
		end)
		self._colorPickerPopups[id] = popup
		popup:SetContent(Settings)
	else
		popup:SetContent(Settings)
	end

	-- One popup at a time: hide whichever else is open.
	if self._activeColorPickerId and self._activeColorPickerId ~= id then
		local activePopup = self._colorPickerPopups[self._activeColorPickerId]
		if activePopup then
			activePopup:Hide()
		end
	end

	if popup then
		popup:Open()
		self._activeColorPickerId = id
	end
	return popup
end

function Window:HidePopups()
	if self._notification then
		self._notification:Hide()
	end
	if self._activePopupId then
		local popup = self._dropdownPopups and self._dropdownPopups[self._activePopupId]
		if popup then
			popup:Hide()
		end
		self._activePopupId = nil
	end
	if self._activeColorPickerId then
		local popup = self._colorPickerPopups and self._colorPickerPopups[self._activeColorPickerId]
		if popup then
			popup:Hide()
		end
		self._activeColorPickerId = nil
	end
end

return Window
