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
local Changelog = require("../Popups/Changelog")
local UIChangelog = require("./UIChangelog")
local Locale = require("../Utils/Locale")
local DropdownPopUp = require("../Popups/DropdownPopUp")
local ColorPickerPopUp = require("../Popups/ColorPickerPopUp")
local Tooltip = require("../Components/Tooltip")
local ThemeManager = require("../Themes/ThemeManager")
local SearchFilter = require("./SearchFilter")
local SettingsTabGroup = require("./Settings/SettingsTabGroup")
local SettingsSystem = require("./Settings/PageBuilder")
local SettingsStore = require("./Settings/SettingsStore")
local ConfigManager = require("./Settings/ConfigManager")
local PageAwareness = require("../Utils/PageAwareness")
local ScrollFade = require("../Utils/ScrollFade")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

local Window = {}
Window.__index = Window

-- Per-window animation and drag style defaults.
Window.AnimationStyle = "Smooth"
Window.DragStyle = "Instant"

-- Shell wash gradients multiply what they paint; dark themes take a stronger stop.
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

function Window.new(Settings)
	Settings = Settings or {}

	-- Persisted settings win over CreateWindow's Theme and MinimizeKey.
	SettingsStore.Load()
	-- The locale must be active before any page or popup builds.
	Locale.setActive(SettingsStore.Get("Locale"))
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
	-- Apply the saved font before components read Constants.Font().
	Constants.SetFontAsset(SettingsStore.Get("Font"))

	local resolvedTheme = ThemeManager.GetTheme(Settings.Theme)
	local theme = resolvedTheme

	local player = Players.LocalPlayer
	local secureMode = Settings.AETHERIS_SECUREMODE == true
	-- Secure mode hides UUID semantics in the Explorer.
	UUID.SetSecureMode(secureMode)

	-- Forward-declared so early closures can reach the finished window.
	local self

	-- Hoisted so every handler sees this window's styles.
	local animationStyle = Settings.AnimationStyle or "Smooth"
	local dragStyle = Settings.DragStyle or "Instant"

	-- Tracked here because they are not ScreenGui children.
	local dragInputConnection
	local resizeInputConnection
	local minimizeKeyConnection
	local inputEndedConnection -- Recreated per drag or resize gesture.
	local clockStopped = false

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = Settings.ScreenGuiName or UUID.Static("Aetheris")
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.ResetOnSpawn = false
	-- DisplayOrder, inset and Parent are caller-settable.
	if Settings.DisplayOrder ~= nil then
		ScreenGui.DisplayOrder = Settings.DisplayOrder
	end
	ScreenGui.IgnoreGuiInset = Settings.IgnoreGuiInset == true
	if secureMode then
		-- Secure mode prefers a hidden gethui, then CoreGui.
		Security.Apply(ScreenGui, { Parent = Settings.Parent, Player = player })
	elseif Settings.Parent ~= nil then
		ScreenGui.Parent = Settings.Parent
	else
		-- Bounded wait so a missing PlayerGui cannot hang the load.
		local playerGui = player and player:FindFirstChild("PlayerGui")
		if not playerGui and player then
			playerGui = player:WaitForChild("PlayerGui", 5)
		end
		ScreenGui.Parent = playerGui or game:GetService("CoreGui")
	end

	-- Theme at construction; the CanvasGroup lets PageFade fade the whole shell.
	local MainFrame = Instance.new("CanvasGroup")
	MainFrame.Name = UUID.Static("Window")
	MainFrame.GroupTransparency = 0
	MainFrame.BorderSizePixel = 0
	MainFrame.BackgroundColor3 = theme.WindowColor or Color3.fromRGB(15, 15, 15)
	MainFrame.BackgroundTransparency = theme.WindowTransparency or 0.1
	MainFrame.AnchorPoint = Vector2.new(0, 0)
	MainFrame.Size = UDim2.fromScale(0.72026, 0.96995)
	MainFrame.Position = UDim2.fromScale(0.013, 0.015)
	-- Cosmetic only, but kept in sync with the theme stroke.
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
	MainFrameCorner.CornerRadius = UDim.new(0, 12)
	MainFrameCorner.Parent = MainFrame

	-- Shell wash: a static multiplier over the theme fill.
	local shellWash = Instance.new("UIGradient")
	shellWash.Name = UUID.Static("WindowWash")
	shellWash.Rotation = 90
	shellWash.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.9, 0.9, 0.9)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
	shellWash.Parent = MainFrame

	-- UI scale; the window resizes around its top-left anchor.
	local MainFrameScale = Instance.new("UIScale")
	MainFrameScale.Name = UUID.Static("WindowScale")
	MainFrameScale.Scale = SettingsStore.Get("UIScale") or 1
	MainFrameScale.Parent = MainFrame

	-- Shadow colour is themed at construction; its geometry is fixed.
	local MainFrameShadow = Instance.new("UIShadow")
	MainFrameShadow.Color = theme.MainframeShadowColor or MainFrameShadow.Color
	MainFrameShadow.Transparency = 0.45
	MainFrameShadow.BlurRadius = UDim.new(0, 26)
	MainFrameShadow.Offset = UDim2.fromOffset(0, 10)
	MainFrameShadow.Parent = MainFrame

	local MainFrameSizeConstraint = Instance.new("UISizeConstraint")
	MainFrameSizeConstraint.MinSize = Vector2.new(425, 360)
	MainFrameSizeConstraint.Parent = MainFrame

	-- Wallpaper art melts downward into the fill below it.
	local function newWallpaper(parent, name)
		local image = Instance.new("ImageLabel")
		image.Name = UUID.Static(name)
		image.BorderSizePixel = 0
		image.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		image.BackgroundTransparency = 1
		image.Image = theme.Wallpaper or Constants.FallbackImage
		image.Size = UDim2.fromScale(1, 1)
		image.ScaleType = Enum.ScaleType.Crop
		image.Parent = parent

		-- The art eases into the fill rather than holding a hard band.
		local melt = Instance.new("UIGradient")
		melt.Rotation = 90
		melt.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.18, 0),
			NumberSequenceKeypoint.new(0.4, 0.45),
			NumberSequenceKeypoint.new(0.6, 0.85),
			NumberSequenceKeypoint.new(0.78, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		melt.Parent = image

		return image
	end

	-- Created before the content fill so it shows through translucent surfaces.
	local windowWallpaperOn = SettingsStore.Get("WindowWallpaperEnabled") == true
	local windowWallpaper = newWallpaper(MainFrame, "WindowWallpaper")
	local windowWallpaperCorner = Instance.new("UICorner")
	windowWallpaperCorner.CornerRadius = MainFrameCorner.CornerRadius
	windowWallpaperCorner.Parent = windowWallpaper
	windowWallpaper.Visible = windowWallpaperOn

	-- Separate fill right of the sidebar keeps content readable.
	local ContentBackground = Instance.new("Frame")
	ContentBackground.Name = UUID.Static("ContentBackground")
	ContentBackground.BorderSizePixel = 0
	ContentBackground.BackgroundColor3 = theme.ContentBackgroundColor or theme.WindowColor
	ContentBackground.BackgroundTransparency = theme.ContentBackgroundTransparency or theme.WindowTransparency or 0
	-- Sidebar is clamped to 186px; anchor (1, 0.5) pins the right edge.
	ContentBackground.AnchorPoint = Vector2.new(1, 0.5)
	ContentBackground.Position = UDim2.fromScale(1, 0.5)
	ContentBackground.Size = UDim2.new(1, -186, 1, 0)
	ContentBackground.ZIndex = 0
	ContentBackground.Parent = MainFrame

	local ContentBackgroundCorner = Instance.new("UICorner")
	ContentBackgroundCorner.TopLeftRadius = UDim.new(0, 0)
	ContentBackgroundCorner.BottomLeftRadius = UDim.new(0, 0)
	ContentBackgroundCorner.TopRightRadius = UDim.new(0, 12)
	ContentBackgroundCorner.BottomRightRadius = UDim.new(0, 12)
	ContentBackgroundCorner.Parent = ContentBackground

	-- Content layer sits on the content fill and mirrors its corners.
	local contentWallpaperOn = SettingsStore.Get("ContentWallpaperEnabled") == true
	-- With both layers on, content wins, matching the UISettings default.
	if contentWallpaperOn and windowWallpaperOn then
		windowWallpaperOn = false
	end
	local contentWallpaper = newWallpaper(ContentBackground, "ContentWallpaper")
	local contentWallpaperCorner = Instance.new("UICorner")
	contentWallpaperCorner.TopLeftRadius = ContentBackgroundCorner.TopLeftRadius
	contentWallpaperCorner.BottomLeftRadius = ContentBackgroundCorner.BottomLeftRadius
	contentWallpaperCorner.TopRightRadius = ContentBackgroundCorner.TopRightRadius
	contentWallpaperCorner.BottomRightRadius = ContentBackgroundCorner.BottomRightRadius
	contentWallpaperCorner.Parent = contentWallpaper
	contentWallpaper.Visible = contentWallpaperOn

	-- Art follows the active theme; transparency comes from UI Settings.
	local function refreshWallpapers(t)
		local image = t.Wallpaper or Constants.FallbackImage
		local trans = math.clamp(SettingsStore.Get("WallpaperTransparency") or 0.85, 0, 1)
		windowWallpaper.Image = image
		windowWallpaper.ImageTransparency = trans
		windowWallpaper.Visible = windowWallpaperOn and t.WallpaperEnabled ~= false
		contentWallpaper.Image = image
		contentWallpaper.ImageTransparency = trans
		contentWallpaper.Visible = contentWallpaperOn and t.WallpaperEnabled ~= false
	end
	refreshWallpapers(theme)

	-- Accent bloom behind the window, above the content fill.
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

	-- Each control gets a UIScale for hover and press feedback.
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
	-- Settings gear sits first in the cluster; its handler is wired below.
	local SettingsButton = makeControlButton("SettingsButton", Icons["settings"], 0, WindowControls)

	local PageTitle = Instance.new("TextLabel")
	PageTitle.Name = UUID.Static("PageTitle")
	PageTitle.TextWrapped = true
	PageTitle.BorderSizePixel = 0
	PageTitle.TextSize = 14
	PageTitle.TextXAlignment = Enum.TextXAlignment.Left
	PageTitle.TextTransparency = 0.3
	PageTitle.BackgroundTransparency = 1
	-- Regular base weight; Medium comes from weight spans, not <b>.
	PageTitle.FontFace = Constants.Font(Enum.FontWeight.Regular)
	PageTitle.TextColor3 = theme.TitleTextColor
	PageTitle.RichText = true
	PageTitle.AutomaticSize = Enum.AutomaticSize.X
	PageTitle.Size = UDim2.fromScale(0, 0.06849)
	-- Offset X keeps the title put on resize (186px sidebar plus 14 gap).
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
	-- Offset X of 200px keeps the content put on resize.
	Content.Size = UDim2.new(1, -200, 0.83149, 0)
	Content.Position = UDim2.new(0, 200, 0.14851, 0)
	Content.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Content.Parent = MainFrame

	-- Popups sit at window level so the ZIndex 50 tab row cannot cover them.
	local PopUpsLayer = Instance.new("Frame")
	PopUpsLayer.Name = UUID.Static("PopUps")
	PopUpsLayer.BorderSizePixel = 0
	PopUpsLayer.BackgroundTransparency = 1
	PopUpsLayer.Active = false
	PopUpsLayer.ZIndex = 52
	PopUpsLayer.AnchorPoint = Content.AnchorPoint
	PopUpsLayer.Size = Content.Size
	PopUpsLayer.Position = Content.Position
	PopUpsLayer.Parent = MainFrame
	local function mirrorPopupsRect()
		PopUpsLayer.AnchorPoint = Content.AnchorPoint
		PopUpsLayer.Size = Content.Size
		PopUpsLayer.Position = Content.Position
	end
	Content:GetPropertyChangedSignal("Size"):Connect(mirrorPopupsRect)
	Content:GetPropertyChangedSignal("Position"):Connect(mirrorPopupsRect)
	Content:GetPropertyChangedSignal("AnchorPoint"):Connect(mirrorPopupsRect)

	-- Toasts sit above the window, stacked bottom-centre, unclipped.
	local Notifications = Instance.new("Frame")
	Notifications.Name = UUID.Static("Notifications")
	Notifications.BorderSizePixel = 0
	Notifications.BackgroundTransparency = 1
	Notifications.Active = false
	Notifications.AnchorPoint = Vector2.new(0.5, 0.5)
	Notifications.Size = UDim2.fromScale(1, 1)
	Notifications.Position = UDim2.fromScale(0.5, 0.5)
	Notifications.ZIndex = 999
	Notifications.Parent = ScreenGui

	local NotificationsLayout = Instance.new("UIListLayout")
	NotificationsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	NotificationsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	NotificationsLayout.Padding = UDim.new(0, 8)
	NotificationsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	NotificationsLayout.Parent = Notifications

	local NotificationsPadding = Instance.new("UIPadding")
	NotificationsPadding.PaddingBottom = UDim.new(0, 14)
	NotificationsPadding.Parent = Notifications

	-- Settings pages overlay; the default pages are built later.
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
	SidebarCorner.TopLeftRadius = UDim.new(0, 12)
	SidebarCorner.BottomLeftRadius = UDim.new(0, 12)
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
	-- The bottom offset leaves room for the divider and user info.
	TabList.Size = UDim2.new(1, 0, 1, -145)
	TabList.Position = UDim2.fromOffset(0, 94)
	TabList.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabList.ScrollBarThickness = 1
	TabList.ScrollBarImageColor3 = theme.TertiaryColor
	TabList.Parent = Sidebar
	-- Labels melt into the sidebar at both scroll edges.
	ScrollFade.Attach(TabList)

	local tabListScrollbarTimer
	TabList:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		-- Compact hides the scrollbar entirely.
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
	-- Fixed offset below the script info.
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
	Locale.set(SearchBox, "PlaceholderText", "Search...")
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

	-- Focus sharpens the bar, stroke, icon and divider.
	SearchBar.BackgroundTransparency = 1
	SearchBox.Focused:Connect(function()
		SearchBar:SetAttribute(UUID.Static("IsSearchFocused"), true)
		-- Read the live theme so focus follows later theme switches.
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

	-- Debounce typing into one search pass over the active page.
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
	-- Bottom-anchored above the user info.
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

	-- Toggles the overlay from its live visibility state.
	SettingsButton.MouseButton1Click:Connect(function()
		if SettingsPages.Visible then
			SettingsPages.Visible = false
			TabContent.Visible = true
			-- Hand the title back to the sidebar tab underneath.
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
		-- The active page changes with the overlay.
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

	-- Auto-mask hides the names at startup; a click then only offers to disable it.
	local originalDisplayName = DisplayName.Text
	local originalUsername = Username.Text
	local function maskOf(text)
		return string.rep("*", utf8.len(text) or #text)
	end
	local autoMask = SettingsStore.Get("MaskDisplayName") == true
	-- Session-only mask state, used while auto-mask is off.
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
	-- Startup paint applies auto-mask immediately.
	applyMask(false)

	-- Single source of truth for auto-mask; idempotent so callbacks cannot loop.
	local function setMaskEnabled(on, animate)
		on = on == true
		if autoMask == on and not manualMask then
			return
		end
		autoMask = on
		manualMask = false
		SettingsStore.Set("MaskDisplayName", on)
		if self and self._maskToggle and self._maskToggle.GetState and self._maskToggle:GetState() ~= on then
			-- UpdateState re-enters here, where the guard returns early.
			self._maskToggle:UpdateState(on)
		end
		applyMask(animate ~= false)
	end

	local function onNameClick()
		if maskFading then
			return
		end
		if autoMask then
			-- Auto-mask owns the state, so ask before unmasking.
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
			-- With auto-mask off, a click toggles the mask silently.
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

	-- The loop exits on teardown or when the label is gone.
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
	-- Secure mode ships no default title, which would fingerprint the UI.
	ScriptName.Text = if secureMode then "" else "Aetheris | Jailbreak"
	ScriptName.LayoutOrder = 1
	ScriptName.AutomaticSize = Enum.AutomaticSize.XY
	ScriptName.Position = UDim2.fromScale(0, 0)
	ScriptName.Parent = ScriptInfoContainer

	-- Pinned tag colours live on attributes; nil follows the theme.
	local tagGradients = {}

	-- Restamp tag gradients; a pinned base or accent wins over the theme.
	local function restampThemeGradients(t)
		local accent = t.AccentColor or Color3.fromRGB(108, 140, 255)
		local base = t.PopupBackgroundColor or t.WindowColor or Color3.fromRGB(20, 20, 22)
		for _, g in ipairs(tagGradients) do
			local pill = g and g.Parent
			if pill then
				-- The fill and the gradient target are independent.
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

	-- Up to 3 tag pills; table entries may pin their colours.
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

		-- Each pill gets 1/total of the row minus its share of the gaps.
		local widthOffset = -(TAG_GAP * (total - 1)) / total

		local pill = Instance.new("Frame")
		pill.Name = UUID.Generate("TagPill")
		pill.BorderSizePixel = 0
		-- The gradient below fades the fill toward the accent.
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
		-- Record pinned colours so a theme switch preserves them.
		if bgColor then
			pillGradient:SetAttribute(UUID.Static("TagBaseColor"), bgColor)
		end
		if accColor then
			pillGradient:SetAttribute(UUID.Static("TagAccentColor"), accColor)
		end
		-- White to accent sheen across the pill.
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

		-- Bloom matches the pill fill, not the accent.
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

		-- The solid fill owns the colour; the gradient is only a sheen.
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
	-- Attach as a method; call sites use colon syntax.
	self.SetMaskEnabled = function(_me, on, animate)
		setMaskEnabled(on, animate)
	end

	-- Stored before settings pages and scripts build.
	self._theme = theme

	-- Wallpaper toggles; ApplyTheme re-asserts the theme gate.
	self.SetWindowWallpaper = function(_me, on)
		windowWallpaperOn = on
		refreshWallpapers(_me._theme)
	end
	self.SetContentWallpaper = function(_me, on)
		contentWallpaperOn = on
		refreshWallpapers(_me._theme)
	end
	self.SetWallpaperTransparency = function(_me, value)
		SettingsStore.Set("WallpaperTransparency", math.clamp(value, 0, 1))
		refreshWallpapers(_me._theme)
	end

	-- Original theme name, used to mark the active card.
	if type(Settings.Theme) == "string" then
		self._themeName = Settings.Theme
	else
		self._themeName = ThemeManager.DefaultTheme
	end

	-- Only a single letter is uppercased; key names match Enum.KeyCode.Name.
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
	self.PopUpsFolder = PopUpsLayer -- Kept for API stability.
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

		-- Faint on hover, fully visible while dragging.
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

	-- Shared tooltip for the pill buttons.
	local tooltip = Tooltip.new(ScreenGui, theme)
	self.Tooltip = tooltip

	local function minimizePreset()
		return animationStyle == "Snappy" and "WindowToggleSnappy" or "WindowToggle"
	end

	-- GroupTransparency dims the whole pill at rest in one property.
	local pill = Instance.new("CanvasGroup")
	pill.Name = UUID.Generate("MinimizePill")
	pill.AutomaticSize = Enum.AutomaticSize.None
	pill.Size = UDim2.fromOffset(56, 56)

	local pillLayout -- Forward declaration; created below.
	local pillScroll -- Forward declaration; created below.

	-- Pill position and tooltip side come from the stored side.
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

	-- Size the pill to its buttons, capped so long tab lists scroll.
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
		-- Seven tabs fit; an eighth turns the pill into a scroller.
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
		-- Top and bottom docks run horizontally.
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

	-- Compact mode collapses the sidebar and moves the tabs under the title bar.
	do
		local COMPACT_ENTER = 672 -- Below this width the layout compacts.
		local COMPACT_EXIT = 712 -- Above this width it expands again.
		local compact = false
		local saved = nil -- Captured expanded values for restore.
		local initialized = false -- Gates auto mode after the first resolve.

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

		-- Restyle the button and its children together.
		local function styleTabButton(btn, horizontal)
			if not btn or not btn:IsA("TextButton") then
				return
			end
			-- Raise the button above the content layers.
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
				-- Reparent before hiding the sidebar, or tab spins pause permanently.
				TabList.LayoutOrder = -1
				TabList.ZIndex = 50
				TabList.ClipsDescendants = true
				TabList.Parent = MainFrame
				Sidebar.Visible = false
				TabList.ScrollingDirection = Enum.ScrollingDirection.X
				TabList:SetAttribute(UUID.Static("CompactNoScrollbar"), true)
				TabList.ScrollBarImageTransparency = 1
				TabList.AutomaticCanvasSize = Enum.AutomaticSize.X
				-- Pin canvas height, or centred pills render at the canvas bottom.
				TabList.CanvasSize = UDim2.fromScale(0, 1)
				TabList.CanvasPosition = Vector2.new(0, 0)
				TabList.AnchorPoint = Vector2.new(0.5, 0)
				TabList.Position = UDim2.new(0.5, 0, 0, 65)
				TabList.Size = UDim2.new(0.95, 0, 0, 40)
				-- Compact padding; sidebar dividers are hidden below.
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
				-- Search docks into the window-controls cluster.
				SearchBar.Parent = WindowControls
				SearchBar.AnchorPoint = Vector2.new(0, 0)
				SearchBar.LayoutOrder = -1
				SearchBar.Size = UDim2.fromOffset(120, 20)
				SearchBar.Position = UDim2.fromScale(0, 0)
				SearchBarBottomDivider.Position = UDim2.new(0.5, 0, 0, 30)
				SearchBarBottomDivider.Visible = false
				-- Content spans the full width below the tab row.
				Content.Size = UDim2.new(1, -16, 1, -124)
				Content.Position = UDim2.fromOffset(8, 90)
				Tween.Play(Content, "Smooth", { Position = UDim2.fromOffset(8, 100) })
				ContentBackground.AnchorPoint = Vector2.new(0, 0)
				ContentBackground.Size = UDim2.fromScale(1, 1)
				ContentBackground.Position = UDim2.fromScale(0, 0)
				-- Compact content is full-bleed, so every corner rounds.
				ContentBackgroundCorner.TopLeftRadius = UDim.new(0, 12)
				ContentBackgroundCorner.BottomLeftRadius = UDim.new(0, 12)
				ContentBackgroundCorner.TopRightRadius = UDim.new(0, 12)
				ContentBackgroundCorner.BottomRightRadius = UDim.new(0, 12)
				contentWallpaperCorner.TopLeftRadius = ContentBackgroundCorner.TopLeftRadius
				contentWallpaperCorner.BottomLeftRadius = ContentBackgroundCorner.BottomLeftRadius
				contentWallpaperCorner.TopRightRadius = ContentBackgroundCorner.TopRightRadius
				contentWallpaperCorner.BottomRightRadius = ContentBackgroundCorner.BottomRightRadius
				-- Script info replaces the page title in compact mode.
				PageTitle.Visible = false
				-- Push settings pages clear of the compact title bar.
				SettingsPages.Position = UDim2.new(0.5, 0, 0.5, 12)
				TabContent.Position = UDim2.fromScale(0.5, 0.55)
				TabContentPadding.PaddingTop = UDim.new(0, 0)
				ScriptInfo.Parent = MainFrame
				ScriptInfo.Size = UDim2.fromOffset(200, 40)
				ScriptInfo.Position = UDim2.fromOffset(5, 5)
				-- Content drops to one column.
				if self.TabGroup and self.TabGroup.SetCompact then
					self.TabGroup:SetCompact(true)
				end
				-- Lower minimum size so the window can shrink.
				MainFrameSizeConstraint.MinSize = Vector2.new(425, 380)
				-- The row slides down into place.
				TabList.Position = UDim2.new(0.5, 0, 0, 60)
				Tween.Play(TabList, "Smooth", { Position = UDim2.new(0.5, 0, 0, 65) })
			else
				-- Cancel entry tweens first, or a rapid flip leaves them running and misplaces the layout.
				Tween.CancelProperty(Content, "Position")
				Tween.CancelProperty(TabList, "Position")
				if not saved then
					return
				end
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
				SearchBarBottomDivider.Visible = true
				Content.Size = saved.contentSize
				Content.Position = saved.contentPos
				ContentBackground.AnchorPoint = saved.contentBgAnchor
				ContentBackground.Size = saved.contentBgSize
				ContentBackground.Position = saved.contentBgPos
				-- Restore the expanded corner treatment.
				ContentBackgroundCorner.TopLeftRadius = UDim.new(0, 0)
				ContentBackgroundCorner.BottomLeftRadius = UDim.new(0, 0)
				ContentBackgroundCorner.TopRightRadius = UDim.new(0, 12)
				ContentBackgroundCorner.BottomRightRadius = UDim.new(0, 12)
				contentWallpaperCorner.TopLeftRadius = ContentBackgroundCorner.TopLeftRadius
				contentWallpaperCorner.BottomLeftRadius = ContentBackgroundCorner.BottomLeftRadius
				contentWallpaperCorner.TopRightRadius = ContentBackgroundCorner.TopRightRadius
				contentWallpaperCorner.BottomRightRadius = ContentBackgroundCorner.BottomRightRadius
				PageTitle.Position = saved.pageTitlePos
				PageTitle.Visible = saved.pageTitleVisible
				SettingsPages.Position = saved.settingsPagesPos
				TabContent.Position = saved.tabContentPos
				TabContentPadding.PaddingTop = saved.tabContentPadTop
				ScriptInfo.Parent = saved.scriptInfoParent
				ScriptInfo.Size = saved.scriptInfoSize
				ScriptInfo.Position = saved.scriptInfoPos
				-- Restore two columns.
				if self.TabGroup and self.TabGroup.SetCompact then
					self.TabGroup:SetCompact(false)
				end
				MainFrameSizeConstraint.MinSize = saved.minSize
				-- Re-capture on the next enter so restores use the current layout.
				saved = nil
			end
		end

		self.SetCompact = function(_self, on)
			local want = on and true or false
			-- Same-state calls are no-ops.
			if want == compact then
				return
			end
			compact = want
			applyCompact(want)
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
				-- Auto reacts only to real resizes; the window may start narrow.
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

		-- Tabs added while compact get the compact styling.
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
		-- The first pass applies only a forced mode; auto waits for a resize.
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
	-- Hover alone gates the stroke, so it is not theme-bound.
	pillStroke.Transparency = 1
	pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pillStroke:SetAttribute(UUID.Static("PageFadeBase"), 1)
	pillStroke.Parent = pill
	local pillShadow = Instance.new("UIShadow")
	pillShadow.Color = theme.PopupShadowColor or Color3.fromRGB(0, 0, 0)
	pillShadow.BlurRadius = UDim.new(0, 16)
	pillShadow.Transparency = 1
	pillShadow:SetAttribute(UUID.Static("PageFadeBase"), 1)
	pillShadow.Parent = pill
	local pillScale = Instance.new("UIScale")
	pillScale.Scale = 1
	pillScale.Parent = pill

	-- The pill is a CanvasGroup, so the shade lives on a plain child frame.
	local pillWash = Instance.new("Frame")
	pillWash.Name = UUID.Static("PillWash")
	pillWash.BorderSizePixel = 0
	pillWash.BackgroundColor3 = theme.PopupBackgroundColor or Color3.fromRGB(15, 15, 16)
	pillWash.BackgroundTransparency = 0
	pillWash.Size = UDim2.fromScale(1, 1)
	pillWash.BorderColor3 = Color3.fromRGB(0, 0, 0)
	pillWash.Parent = pill
	local pillWashCorner = Instance.new("UICorner")
	pillWashCorner.CornerRadius = UDim.new(1, 0)
	pillWashCorner.Parent = pillWash
	local pillWashGradient = Instance.new("UIGradient")
	stampWash(pillWashGradient, pillWash.BackgroundColor3)
	pillWashGradient.Parent = pillWash

	-- Dim and small at rest so the pill does not block the view.
	local PILL_REST_GROUP = 0.55
	local PILL_HOVER_GROUP = 0
	local PILL_REST_SCALE = 0.85
	local PILL_HOVER_SCALE = 1
	local pillHovered = false
	pill.GroupTransparency = PILL_REST_GROUP

	-- Group transparency does not cover the shadow, so it is gated separately.
	local function applyPillShadow()
		pillShadow.Transparency = (pillHovered and pill.Visible) and 0.5 or 1
	end

	-- The stroke is gated the same way, with the live theme colour on hover.
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

	-- The strip scrolls so long tab lists stay on screen.
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
	applyPillPosition()

	local minimizeWindow
	local restoreWindow
	-- Built once per tab and reused across minimize cycles.
	local pillButtonByTab = {}

	local function stylePillContainer(t)
		pill.BackgroundColor3 = t.PopupBackgroundColor or Color3.fromRGB(15, 15, 16)
		pill.BackgroundTransparency = 0.05
		pill.GroupTransparency = PILL_REST_GROUP
		pillWash.BackgroundColor3 = t.PopupBackgroundColor or Color3.fromRGB(15, 15, 16)
		stampWash(pillWashGradient, pillWash.BackgroundColor3)
		pillStroke.Color = t.StrokeColor or Color3.fromRGB(255, 255, 255)
		-- Stroke transparency stays hover-gated, never stamped here.
		applyPillStroke()
		pillShadow.Color = t.PopupShadowColor or Color3.fromRGB(0, 0, 0)
		applyPillShadow()
		if pillScroll then
			pillScroll.ScrollBarImageColor3 = t.TertiaryColor or Color3.fromRGB(120, 132, 150)
		end
	end

	-- Restyle one existing pill button for its tab's active state.
	local function stylePillButton(btn, tab, t, isActive)
		btn.BackgroundColor3 = t.ActiveTabButtonColor or t.PrimaryColor or Color3.fromRGB(99, 102, 241)
		btn.BackgroundTransparency = isActive and 0.1 or 1
		local back = btn:FindFirstChild(UUID.Static("BackImage"))
		if back then
			back.Image = (tab.BackImage and tab.BackImage.Image) or "rbxassetid://11094025229"
			back.ImageTransparency = isActive and 0 or 1
			-- Restart the spin only when the active state changes.
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

	-- Build a pill button; called once per tab.
	local function createPillButton(tab, i, t)
		local isActive = (tab == (self.TabGroup and self.TabGroup.ActiveTab))
		local btn = Instance.new("TextButton")
		btn.Name = UUID.Generate("PillTab")
		btn.Size = UDim2.fromOffset(40, 40)
		-- Only the active tab shows a filled background.
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
		-- UIScale grows from the center for the hover bounce.
		local btnScale = Instance.new("UIScale")
		btnScale.Scale = 1
		btnScale.Parent = btn
		-- Spinning-gradient backdrop, matching the sidebar tab buttons.
		local back = Instance.new("ImageLabel")
		back.Name = UUID.Static("BackImage")
		back.BorderSizePixel = 0
		back.BackgroundTransparency = 1
		back.Image = (tab.BackImage and tab.BackImage.Image) or "rbxassetid://11094025229"
		-- Backdrop and spin only on the active tab.
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
		-- White hover lift between backdrop and icon.
		local lift = Instance.new("Frame")
		lift.Name = UUID.Static("PillLift")
		lift.BorderSizePixel = 0
		lift.BackgroundColor3 = Color3.new(1, 1, 1)
		lift.BackgroundTransparency = 1
		lift.Size = UDim2.fromScale(1, 1)
		lift.ZIndex = 1501
		lift.Parent = btn
		local liftCorner = Instance.new("UICorner")
		liftCorner.CornerRadius = UDim.new(1, 0)
		liftCorner.Parent = lift
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
		local hovered = false
		btn.MouseEnter:Connect(function()
			hovered = true
			Tween.Play(btnScale, "HoverIn", { Scale = 1.18 })
			Tween.Play(lift, "Lift", { BackgroundTransparency = 0.95 })
			tooltip:ShowAt(btn, tab.Name, pillTooltipSide(), 11)
		end)
		btn.MouseLeave:Connect(function()
			hovered = false
			Tween.Play(btnScale, "HoverOut", { Scale = 1 })
			Tween.Play(lift, "Lift", { BackgroundTransparency = 1 })
			tooltip:Hide()
		end)
		-- Press dips the grown scale and springs back.
		btn.MouseButton1Down:Connect(function()
			Tween.Play(btnScale, "PressIn", { Scale = (hovered and 1.18 or 1) * 0.94 })
		end)
		btn.MouseButton1Up:Connect(function()
			Tween.Play(btnScale, "PressOut", { Scale = hovered and 1.18 or 1 })
		end)
		btn.MouseButton1Click:Connect(function()
			-- Mirror a sidebar tab click.
			if self.SettingsPages then
				self.SettingsPages.Visible = false
			end
			if self.TabContent then
				self.TabContent.Visible = true
			end
			if self.TabGroup then
				self.TabGroup:SetActiveTab(tab)
			end
			-- SetActiveTab early-returns on the active tab, so force the fade layer visible.
			if tab and tab.FadeLayer then
				tab.FadeLayer.Visible = true
				PageFade.Snap(tab.FadeLayer, 0)
			end
			restoreWindow()
		end)
		pillButtonByTab[tab] = btn
		stylePillButton(btn, tab, t, isActive)
	end

	-- Ensure each tab has a pill button and restyle them all.
	local function buildPill(themeOverride)
		local t = themeOverride or self._theme or theme
		tooltip:SetTheme(t)
		stylePillContainer(t)
		if not self.TabGroup then
			return
		end
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

	-- Only stable states accept a toggle, so spamming the keybind is safe.
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
		-- Cancel the hide timer, then fade the scrollbar out explicitly.
		if tabListScrollbarTimer then
			task.cancel(tabListScrollbarTimer)
			tabListScrollbarTimer = nil
		end
		if TabList then
			Tween.Play(TabList, "Fast", { ScrollBarImageTransparency = 1 })
		end
		buildPill()
		-- Snap the controls to their idle look before the fade capture.
		for _, ctrl in ipairs({ MinimizeButton, MaximizeButton, CloseButton }) do
			if ctrl then
				ctrl.ImageTransparency = 0.5
				local s = ctrl:FindFirstChildOfClass("UIScale")
				if s then
					s.Scale = 1
				end
			end
		end
		-- Reveal the pill only after the window fade completes.
		PageFade.Hide(MainFrame, false, function()
			MainFrame.Visible = false
			pillHovered = false
			pill.Visible = true
			pill.BackgroundTransparency = 0.05
			pill.GroupTransparency = 1
			pillScale.Scale = 0.7
			-- Group transparency skips stroke and shadow; snap them hidden first.
			PageFade.FadeDecorations(pill, true, true)
			-- Pop in to the dim resting state.
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
		-- Reveal the window in parallel with the pill fading out.
		MainFrame.Visible = true
		PageFade.Show(MainFrame, false, function()
			self._windowFaded = false
			minimizeState = "shown"
		end, PageFade.WINDOW_PRESET)
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

	-- External entry point; only acts from a stable state.
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

	-- Ignored while a TextBox has focus.
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

	-- Restore the default position and size.
	self.ResetLayout = function()
		Tween.Play(MainFrame, minimizePreset(), {
			Size = UDim2.fromScale(0.72026, 0.96995),
			Position = UDim2.fromScale(0.013, 0.015),
		})
	end

	local preMaxSize = MainFrame.Size
	local preMaxPosition = MainFrame.Position
	MaximizeButton.MouseButton1Click:Connect(function()
		-- Decide from the actual size, since a manual resize leaves a flag stale.
		local isFull = MainFrame.Size.X.Scale >= 0.999 and MainFrame.Size.Y.Scale >= 0.999
		-- Expand quickly; the window toggle preset is too slow here.
		if isFull then
			Tween.Play(MainFrame, "Fast", {
				Size = preMaxSize,
				Position = preMaxPosition,
			})
		else
			preMaxSize = MainFrame.Size
			preMaxPosition = MainFrame.Position
			Tween.Play(MainFrame, "Fast", {
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

		-- Stop tracking page state before the tree goes away.
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

		-- One sweep over the active-tween registry.
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
		-- Single close pipeline; Destroy owns sound and teardown.
		self:Destroy()
	end

	CloseButton.MouseButton1Click:Connect(function()
		-- Confirm unless confirmation is disabled.
		if not SettingsStore.Get("ConfirmClose") then
			doClose()
			return
		end
		-- Name the prompt after the script title.
		local appName = (ScriptName.Text ~= "" and ScriptName.Text) or Locale.resolve("the UI")
		self:UINotification({
			Title = string.format(Locale.resolve("Close %s?"), appName),
			Description = string.format(
				Locale.resolve('Are you sure you want to <font color="#FF0000">close</font> %s?'),
				appName
			),
			TitleColor = Color3.fromRGB(255, 0, 0),
			ConfirmText = Locale.resolve("Yes, close it"),
			CancelText = Locale.resolve("No, keep it open"),
			OnConfirm = doClose,
		})
	end)

	self.TabGroup = TabGroup.new(self, theme)
	self.SettingsTabGroup = SettingsTabGroup.new(self, theme)
	-- Attach before components register.
	PageAwareness.Attach(self)

	-- Created before the settings pages that use it.
	self.ConfigManager = ConfigManager.new(self)

	-- Default settings pages come first.
	SettingsSystem.BuildDefaultPages(self)

	-- Extra pages get Build(window, tab) and a scrolling column.
	if type(Settings.SettingsPages) == "table" then
		for _, page in ipairs(Settings.SettingsPages) do
			local tab = self.SettingsTabGroup:Tab({
				Name = page.Name or "Settings",
				Icon = page.Icon,
				Active = page.Active,
			})
			if type(page.Build) == "function" then
				tab:Scroller()
				page.Build(self, tab)
			end
		end
	end

	-- Optionally override the initially active settings page.
	if Settings.DefaultSettingsPage then
		self.SettingsTabGroup:SetActiveTabByName(Settings.DefaultSettingsPage)
	end

	ThemeManager.ApplyTheme(self, theme)

	-- Fade the window in from hidden.
	Sound.Play("UIStart")
	PageFade.Snap(MainFrame, 1)
	PageFade.Show(MainFrame, false, nil, PageFade.WINDOW_PRESET)

	-- The page the sidebar search filters.
	self.GetActivePage = function(me)
		if me.SettingsPages and me.SettingsPages.Visible then
			local stab = me.SettingsTabGroup and me.SettingsTabGroup.ActiveTab
			return stab and stab.Page or nil
		end
		local tab = me.TabGroup and me.TabGroup.ActiveTab
		return tab and tab.ContentScroller or nil
	end

	-- Apply the search text to the active page.
	self.ApplySearch = function(me)
		local page = me:GetActivePage()
		if not page then
			return
		end
		SearchFilter.Apply(page, me.SearchBox.Text, me._theme)
	end

	-- State-independent shell properties are bindings; focus ones stay imperative.
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
	-- PageTitle transparency stays a literal 0.3, matching the title bar.
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

	-- The window is the UI root, so ThemeManager calls this explicitly.
	self.ApplyTheme = function(me, newTheme)
		local t = ThemeManager.GetTheme(newTheme)
		me._theme = t
		restampThemeGradients(t)

		-- Wallpaper art and its visibility gate follow the theme.
		refreshWallpapers(t)

		-- Focus-driven transparencies are stamped from the current focus state.
		local searchFocused = SearchBar:GetAttribute(UUID.Static("IsSearchFocused"))
		if searchFocused then
			SearchBar.BackgroundTransparency = t.SearchBarBackgroundTransparency or 0
			SearchBoxStroke.Transparency = t.StrokeTransparency or 0.95
		else
			SearchBar.BackgroundTransparency = 1
			SearchBoxStroke.Transparency = 1
		end

		-- Only the lazily created per-tab buttons need a refresh.
		if me._refreshPill then
			me._refreshPill(t)
		end

		if tooltip and tooltip.SetTheme then
			tooltip:SetTheme(t)
		end

		-- Cached popups live outside the window tree, so recolor them here.
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

		-- Recolor the cached dialog; drop it if it cannot re-theme.
		if me._notification then
			if me._notification.ApplyTheme then
				me._notification:ApplyTheme(t)
			else
				me._notification:Destroy()
				me._notification = nil
			end
		end

		-- Recolor live toasts and prune ones whose root is gone.
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

	-- Run the shell theme pass now that it exists.
	self:ApplyTheme(theme)

	-- Two changelogs share the popup: the library's own list and the script's.
	do
		local win = self

		local function makeChangelog(entries, version, title, storeKey)
			local changelog = Changelog.new(PopUpsLayer, {
				Theme = theme,
				Version = version,
				Title = title,
				Entries = entries,
			})
			-- The changelog arrives as `me`; `self` is the window here.
			function changelog.Show(me)
				if me.IsOpen or not me.Popup or not me.Popup.Parent then
					return
				end
				-- Opening a changelog resolves whatever else is open.
				win:_claimPopup(me)
				if version ~= "" then
					-- Stamp the version on open, so a dismissed popup is not burned.
					SettingsStore.Set(storeKey, version)
				end
				me:Open()
			end
			return changelog
		end

		local uiVersion = UIChangelog.Version or ""
		local uiChangelog
		local uiDue = false
		if type(UIChangelog.Entries) == "table" and UIChangelog.Entries[1] ~= nil then
			uiChangelog = makeChangelog(UIChangelog.Entries, uiVersion, "Aetheris Changelog", "UIChangeLogVersion")
			self._uiChangelog = uiChangelog
			self.AetherisChangelog = uiChangelog
			uiDue = uiVersion ~= "" and SettingsStore.Get("UIChangeLogVersion") ~= uiVersion
		end

		local entries = Settings.Changelog
		local scriptVersion = Settings.Version
		if type(scriptVersion) ~= "string" then
			scriptVersion = ""
		end
		local scriptChangelog
		local scriptDue = false
		if type(entries) == "table" and entries[1] ~= nil then
			scriptChangelog = makeChangelog(entries, scriptVersion, "Changelog", "ChangelogVersion")
			self._changelog = scriptChangelog
			self.Changelog = scriptChangelog
			scriptDue = scriptVersion ~= "" and SettingsStore.Get("ChangelogVersion") ~= scriptVersion
		end

		if uiDue then
			-- A user close hands over to the script's list; a replacement skips it.
			uiChangelog.OnClose = function(reason)
				uiChangelog.OnClose = nil
				if reason == "user" and scriptDue and win._changelog == scriptChangelog then
					scriptChangelog:Show()
				end
			end
			task.delay(1, function()
				if win._uiChangelog == uiChangelog then
					uiChangelog:Show()
				end
			end)
		elseif scriptDue then
			-- Show once per new version, after the window settles.
			task.delay(1, function()
				if win._changelog == scriptChangelog then
					scriptChangelog:Show()
				end
			end)
		end
	end

	return self
end

function Window:SetTitle(text)
	self.ScriptName.Text = text
end

function Window:SetTheme(themeInput)
	-- Only user-triggered switches play a sound; boot applies its theme silently.
	Sound.Play("ThemeChange")
	if type(themeInput) == "string" then
		self._themeName = themeInput
		-- Named themes persist; custom tables are session-only.
		SettingsStore.Set("Theme", themeInput)
	end
	-- Crossfades colors and invokes Window:ApplyTheme.
	ThemeManager.UpdateTheme(self, themeInput)
	-- A theme switch joins the debounced auto-save.
	if self.ConfigManager then
		self.ConfigManager:NotifyChanged()
	end
end

-- Swap the font family live, then persist the choice (nil = built-in).
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

-- Register teardown cleanup; callbacks are pcall-guarded against failure.
function Window:OnDestroy(callback)
	if type(callback) ~= "function" then
		warn("[Aetheris] Window:OnDestroy expects a function")
		return
	end
	self._destroyCallbacks = self._destroyCallbacks or {}
	table.insert(self._destroyCallbacks, callback)
end

function Window:Destroy()
	-- Re-entrancy guard against a second close.
	if self._destroyed then
		return
	end

	local closePreset = self.AnimationStyle == "Snappy" and "FadeOut" or "WindowFade"

	-- UIClose is the close sound.
	Sound.Play("UIClose")

	-- Drop the changelogs first so their outside-click connections end with the tree.
	if self._changelog then
		self._changelog:Destroy()
		self._changelog = nil
		self.Changelog = nil
	end
	if self._uiChangelog then
		self._uiChangelog:Destroy()
		self._uiChangelog = nil
		self.AetherisChangelog = nil
	end

	if self._teardown then
		self._teardown()
	end

	-- User teardown hooks, each pcall-guarded so one failure cannot strand the rest.
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

	-- One GroupTransparency tween covers every child.
	local handle = Tween.Play(self.MainFrame, closePreset, { GroupTransparency = 1 })
	-- The UIShadow needs its own fade.
	if self.MainFrameShadow then
		Tween.Play(self.MainFrameShadow, closePreset, { Transparency = 1 })
	end
	handle.Tween.Completed:Wait()

	Tween.CancelAll(self.MainFrame)
	self.Base:Destroy()
end

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

-- Dialogs are created and destroyed per call.
function Window:UINotification(Settings)
	if type(Settings) ~= "table" then
		warn("[Window:UINotification] Settings is not a table, defaulting to {}")
		Settings = {}
	end

	-- Only one dialog at a time; the old one is destroyed first.
	if self._notification then
		if self._activePopUp == self._notification then
			self._activePopUp = nil
		end
		self._notification:Close()
		self._notification:Destroy()
		self._notification = nil
	end

	Settings.Theme = self._theme
	local notification = UINotification.new(self.PopUpsFolder, Settings)
	self._notification = notification
	-- A dialog resolves whatever popup was open before it.
	self:_claimPopup(notification)
	notification:Open()
	return notification
end

-- Toasts self-destroy; window:Alert/Error/Toast.
local Notification = require("../Popups/Notification")

local function spawnNotification(self, ntype, Settings)
	if type(Settings) ~= "table" then
		Settings = {}
	end
	Settings.Type = ntype
	local notification = Notification.new(self.Notifications, Settings, self._theme)
	-- Track live toasts, pruning stale entries on every spawn.
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

-- One popup at a time; claiming dismisses the previous one.
function Window:_claimPopup(popup)
	local active = self._activePopUp
	if active and active ~= popup and active.Dismiss then
		active:Dismiss()
	end
	self._activePopUp = popup
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
		-- Built once per id; cleanup drops it from the cache.
		popup = DropdownPopUp.new(self.PopUpsFolder, Settings, function()
			if self._dropdownPopups then
				self._dropdownPopups[id] = nil
			end
			if self._activePopUp == popup then
				self._activePopUp = nil
			end
		end)
		self._dropdownPopups[id] = popup
	else
		popup:SetContent(Settings)
	end

	if popup then
		self:_claimPopup(popup)
		popup:Open()
		Sound.Play("Notification")
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
			if self._activePopUp == popup then
				self._activePopUp = nil
			end
		end)
		self._colorPickerPopups[id] = popup
		popup:SetContent(Settings)
	else
		popup:SetContent(Settings)
	end

	if popup then
		self:_claimPopup(popup)
		popup:Open()
		Sound.Play("Notification")
	end
	return popup
end

-- Put every popup away without firing callbacks.
function Window:HidePopups()
	if self._notification then
		self._notification:Hide()
	end
	local active = self._activePopUp
	if active then
		if active.Hide then
			active:Hide()
		elseif active.Close then
			active:Close()
		end
	end
	self._activePopUp = nil
end

return Window
