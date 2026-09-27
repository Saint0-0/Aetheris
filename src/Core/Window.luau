--[[
	Window  ·  Aetheris UI Library

	Builds the main Aetheris window shell: chrome, sidebar, content area,
	settings container, drag, resize, minimize/maximize/close, and notifications.
	Returns a window object; use Window.new({...}) via the library facade.

	Public API:
	  :Tab / :Divider              - sidebar tabs (delegated to TabGroup)
	  :SetTitle                    - script info title (tags below via Settings.Tags)
	  :SetTheme(name|table)        - live theme switch (crossfades)
	  :UINotification / :Alert / :Error / :Toast
	  :DropdownPopUp / :ColorPickerPopUp / :HidePopups
	  :ResetLayout                 - restore default size/position
	  :Destroy                     - fade out + full teardown

	Teardown: closing the UI calls _teardown(), which disconnects global
	input listeners, cancels tasks/tweens, drops cached popups, and marks the
	window destroyed so nothing animates a dead UI. See _teardown for details.
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Tween = require("../Utils/Tween")
local PageFade = require("../Utils/PageFade")
local Sound = require("../Utils/Sound")
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
local Constants = require("../Constants")

local Window = {}
Window.__index = Window

-- Swap this to "Snappy" to compare feel -- affects Minimize and Close.
-- (Utils/Tween.lua presets used: Minimize = smooth, MinimizeSnappy = snappy)
Window.AnimationStyle = "Smooth" -- "Smooth" | "Snappy"
Window.DragStyle = "Instant" -- "Instant" | "Smooth" (how the window follows the cursor while dragging)

function Window.new(Settings)
	Settings = Settings or {}

	-- Load persisted user settings and apply the ones that affect construction
	-- (theme, volume, spin toggle). CreateWindow's own Theme/MinimizeKey act as
	-- the fallback when the store has no saved value yet.
	SettingsStore.Load()
	local savedTheme = SettingsStore.Get("Theme")
	local savedKey = SettingsStore.Get("MinimizeKey")
	if savedTheme ~= nil then Settings.Theme = savedTheme end
	if savedKey ~= nil then Settings.MinimizeKey = savedKey end
	Sound.SetVolume(SettingsStore.Get("Volume"))
	Tween.SpinsEnabled = SettingsStore.Get("SpinsEnabled")

	-- Resolve theme early so UI creation uses actual theme table
	local resolvedTheme = ThemeManager.GetTheme(Settings.Theme)
	-- Keep Settings.Theme as the original input, but use resolvedTheme for values
	local theme = resolvedTheme

	local player = Players.LocalPlayer

	-- Forward declaration so early closures (e.g. the settings gear click)
	-- can reach the window object created near the end of this function.
	local self

	-- Per-window animation + drag style (were class-level Window.AnimationStyle
	-- / Window.DragStyle -- shared across every window). Hoisted above the
	-- closures that read them so the drag/resize/minimize/close handlers see
	-- THIS window's values. Defaults match the old class values.
	local animationStyle = Settings.AnimationStyle or "Smooth"
	local dragStyle = Settings.DragStyle or "Instant"

	-- Global UserInputService connections (drag + resize). These are NOT
	-- children of the ScreenGui, so they are tracked here and explicitly
	-- disconnected in _teardown when the UI is closed/destroyed.
	local dragInputConnection
	local resizeInputConnection
	local minimizeKeyConnection
	local inputEndedConnection -- shared, recreated per drag/resize gesture
	local clockStopped = false

	----------------------------------------------------------------
	-- Root
	----------------------------------------------------------------
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = Settings.ScreenGuiName or "Aetheris"
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.ResetOnSpawn = false
	-- Host control (p2-5): DisplayOrder + inset are caller-settable; Parent may
	-- be an explicit instance (an existing ScreenGui, PlayerGui, CoreGui, ...).
	if Settings.DisplayOrder ~= nil then
		ScreenGui.DisplayOrder = Settings.DisplayOrder
	end
	ScreenGui.IgnoreGuiInset = Settings.IgnoreGuiInset == true
	if Settings.Parent ~= nil then
		ScreenGui.Parent = Settings.Parent
	else
		-- Bounded wait: never hang a loadstring forever if LocalPlayer/PlayerGui
		-- is unavailable (some exploit/early contexts). Fall back to CoreGui.
		local playerGui = player and player:FindFirstChild("PlayerGui")
		if not playerGui and player then
			playerGui = player:WaitForChild("PlayerGui", 5)
		end
		ScreenGui.Parent = playerGui or game:GetService("CoreGui")
	end

	----------------------------------------------------------------
	-- Window (main frame)
	----------------------------------------------------------------
	-- Window chrome is themed at construction so it is correct on first paint
	-- (and on every later ApplyTheme). theme.X or <literal> is safe here: in Lua
	-- only nil/false are falsy, so a theme value of 0 (fully opaque) is kept.
	-- CanvasGroup (not Frame) so a SINGLE GroupTransparency can fade the whole
	-- window for minimize / restore / close / intro, instead of snapshotting and
	-- tweening every descendant's own transparency. That old approach stomped
	-- any component state encoded as transparency (radio selection, slider fill)
	-- and forced the old RefreshVisuals/RestoreActiveTab repair calls (RefreshVisuals
-- has since been deleted outright). See Utils/PageFade.
	local MainFrame = Instance.new("CanvasGroup")
	MainFrame.Name = "Window"
	MainFrame.GroupTransparency = 0
	MainFrame.BorderSizePixel = 0
	MainFrame.BackgroundColor3 = theme.WindowColor or Color3.fromRGB(15, 15, 15)
	MainFrame.BackgroundTransparency = theme.WindowTransparency or 0.1
	MainFrame.AnchorPoint = Vector2.new(0, 0)
	MainFrame.Size = UDim2.new(0.72026, 0, 0.96995, 0)
	MainFrame.Position = UDim2.new(0.013, 0, 0.015, 0)
	-- BorderSizePixel is 0 above, so BorderColor3 is cosmetic-only; keep it in
	-- sync with the theme's stroke colour rather than a stray literal.
	MainFrame.BorderColor3 = theme.StrokeColor or Color3.fromRGB(41, 41, 41)
	MainFrame.Parent = ScreenGui
	
	local DragFrame = Instance.new("Frame")
	DragFrame.AnchorPoint = Vector2.new(0.5, 0)
	DragFrame.Name = "DragFrame"
	DragFrame.Position = UDim2.new(0.5, 0, 0, 0)
	DragFrame.Size = UDim2.new(1, 0, 0, 60)
	DragFrame.BackgroundTransparency = 1
	DragFrame.Parent = MainFrame

	----------------------------------------------------------------
	-- Drag (drag the DragFrame to move the whole MainFrame)
	----------------------------------------------------------------
	do
		local dragging = false
		local dragStart
		local startPosition

		DragFrame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPosition = MainFrame.AbsolutePosition

				if inputEndedConnection then
					inputEndedConnection:Disconnect()
				end
				inputEndedConnection = UserInputService.InputEnded:Connect(function(endInput)
					if endInput.UserInputType == Enum.UserInputType.MouseButton1
					or endInput.UserInputType == Enum.UserInputType.Touch then
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
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				local newPosition = startPosition + Vector2.new(delta.X, delta.Y)
				local target = UDim2.new(0, newPosition.X, 0, newPosition.Y)

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

	-- Window UI scale (user-adjustable in UI Settings). Applied to the whole
	-- window so it resizes around its top-left anchor.
	local MainFrameScale = Instance.new("UIScale")
	MainFrameScale.Name = "WindowScale"
	MainFrameScale.Scale = SettingsStore.Get("UIScale") or 1
	MainFrameScale.Parent = MainFrame

	-- Window shadow: colour is themed at construction (was only being set by
	-- ApplyTheme, leaving the first frame unthemed). Blur stays a fixed literal.
	local MainFrameShadow = Instance.new("UIShadow")
	MainFrameShadow.Color = theme.MainframeShadowColor or MainFrameShadow.Color
	MainFrameShadow.Transparency = 0.5
	MainFrameShadow.BlurRadius = UDim.new(0,20)
	MainFrameShadow.Parent = MainFrame

	local MainFrameSizeConstraint = Instance.new("UISizeConstraint")
	MainFrameSizeConstraint.MinSize = Vector2.new(425, 360)
	MainFrameSizeConstraint.Parent = MainFrame

	----------------------------------------------------------------
	-- Content background (region right of the sidebar, full height)
	----------------------------------------------------------------
	-- A separate fill for the area to the right of the sidebar. Themes can make
	-- the window/sidebar translucent while keeping this opaque (or the reverse)
	-- so content stays readable over the game. Positioned at the sidebar's
	-- right edge and sized with scale so it tracks window resizes; rounded on
	-- the right to follow the window's corners.
	local ContentBackground = Instance.new("Frame")
	ContentBackground.Name = "ContentBackground"
	ContentBackground.BorderSizePixel = 0
	ContentBackground.BackgroundColor3 = theme.ContentBackgroundColor or theme.WindowColor
	-- NOTE: the old idiom (x ~= nil and x) collapsed to `false` when the theme
	-- value was nil, which coerced BackgroundTransparency to 0 (fully opaque).
	-- Fall back to the window transparency, then 0, instead.
	ContentBackground.BackgroundTransparency = theme.ContentBackgroundTransparency or theme.WindowTransparency or 0
	-- The sidebar is clamped to a fixed 186px by its UISizeConstraint, so the
	-- content area starts 186px from the left and runs to the window's right
	-- edge. AnchorPoint (1, 0.5) keeps the right edge pinned as the window
	-- resizes; the left edge stays glued to the sidebar.
	ContentBackground.AnchorPoint = Vector2.new(1, 0.5)
	ContentBackground.Position = UDim2.new(1, 0, 0.5, 0)
	ContentBackground.Size = UDim2.new(1, -186, 1, 0)
	ContentBackground.ZIndex = 0
	ContentBackground.Parent = MainFrame

	local ContentBackgroundCorner = Instance.new("UICorner")
	ContentBackgroundCorner.TopLeftRadius = UDim.new(0, 0)
	ContentBackgroundCorner.BottomLeftRadius = UDim.new(0, 0)
	ContentBackgroundCorner.TopRightRadius = UDim.new(0, 6)
	ContentBackgroundCorner.BottomRightRadius = UDim.new(0, 6)
	ContentBackgroundCorner.Parent = ContentBackground

	----------------------------------------------------------------
	-- Window controls (Close / Maximize / Minimize)
	----------------------------------------------------------------
	local WindowControls = Instance.new("Frame")
	WindowControls.Name = "WindowControls"
	WindowControls.BorderSizePixel = 0
	WindowControls.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	WindowControls.BackgroundTransparency = 1
	WindowControls.AnchorPoint = Vector2.new(1, 0)
	WindowControls.Size = UDim2.new(0.10926, 0, 0.04715, 0)
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

	-- Window control buttons use full icons from the Icons module (no ImageRect).
	-- Each gets a UIScale for a bouncy hover/press feel.
	local function makeControlButton(name, icon, layoutOrder, parent)
		local btn = Instance.new("ImageButton")
		btn.Name = name
		btn.BackgroundTransparency = 1
		btn.ImageTransparency = 0.5 -- idle transparency (dims toward 0 on hover)
		btn.ImageColor3 = theme.WindowControlColor or Color3.fromRGB(203, 213, 225)
		btn.Image = icon
		btn.Size = UDim2.new(0, 15, 0, 15)
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

	local MinimizeButton = makeControlButton("MinimizeButton", Icons["minimize"] or "rbxassetid://121304296213645", 1, WindowControls)
	local MaximizeButton = makeControlButton("MaximizeButton", Icons["maximize"] or "rbxassetid://76045941763188", 2, WindowControls)
	local CloseButton = makeControlButton("CloseButton", Icons["x"] or "rbxassetid://110786993356448", 3, WindowControls)
	-- Settings gear moved into the window-controls cluster (LayoutOrder 0 ->
	-- leftmost of the cluster, before Minimize). Its click handler is wired
	-- further down once TabContent/SettingsPages exist.
	local SettingsButton = makeControlButton("SettingsButton", Icons["settings"], 0, WindowControls)

	----------------------------------------------------------------
	-- Page title (drag handle lives here -- whole title bar draggable)
	----------------------------------------------------------------
	local PageTitle = Instance.new("TextLabel")
	PageTitle.Name = "PageTitle"
	PageTitle.TextWrapped = true
	PageTitle.BorderSizePixel = 0
	PageTitle.TextSize = 14
	PageTitle.TextXAlignment = Enum.TextXAlignment.Left
	PageTitle.TextTransparency = theme.PrimaryTextTransparency or 0.4 -- [THEME] title text transparency
	PageTitle.BackgroundTransparency = 1
	-- Base weight is Regular. The "Settings | " prefix and sidebar tab names are
	-- rendered Medium via <font weight="500"> rich-text spans (wrapping them in
	-- <b> forced bold and ignored the FontFace); the page name itself stays
	-- regular.
	PageTitle.FontFace = Constants.Font(Enum.FontWeight.Regular)
	PageTitle.TextColor3 = theme.TitleTextColor
	PageTitle.RichText = true
	PageTitle.AutomaticSize = Enum.AutomaticSize.X
	PageTitle.Size = UDim2.new(0, 0, 0.06849, 0)
	-- Offset-based X (not scale) so the title stays put as the window resizes;
	-- the sidebar is a fixed 186px, plus a 14px gap.
	PageTitle.Position = UDim2.new(0, 200, 0.045, 0)
	PageTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PageTitle.Text = '<font weight="500">Settings | </font>General'
	PageTitle.Parent = MainFrame

	local PageTitleDivider = Instance.new("Frame")
	PageTitleDivider.Name = "ComponentDivider"
	PageTitleDivider.BorderSizePixel = 0
	PageTitleDivider.BackgroundColor3 = theme.TertiaryColor -- [THEME] divider color
	PageTitleDivider.BackgroundTransparency = theme.SectionDividerTransparency or 0.9 -- [THEME] divider transparency
	PageTitleDivider.Size = UDim2.new(0.8, 0, 0, 1)
	PageTitleDivider.Position = UDim2.new(0, 0, 1.2, 0)
	PageTitleDivider.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PageTitleDivider.Parent = PageTitle

	----------------------------------------------------------------
	-- Content area (holds TabContent + SettingsPages)
	----------------------------------------------------------------
	local Content = Instance.new("Frame")
	Content.Name = "Content"
	Content.BorderSizePixel = 0
	Content.BackgroundTransparency = 1
	-- Left edge pinned 14px past the sidebar's fixed 186px width (offset, not
	-- scale), width fills to the window's right edge, so it stays put when resized.
	Content.Size = UDim2.new(1, -200, 0.83149, 0)
	Content.Position = UDim2.new(0, 200, 0.14851, 0)
	Content.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Content.Parent = MainFrame

	-- PopUps folder (for dropdown popups and other overlays)
	local PopUpsFolder = Instance.new("Folder")
	PopUpsFolder.Name = "PopUps"
	PopUpsFolder.Parent = Content

	-- Notifications container (direct child of the ScreenGui so toasts sit
	-- above the whole window and are not clipped). Toasts stack bottom-right.
	local Notifications = Instance.new("Frame")
	Notifications.Name = "Notifications"
	Notifications.BorderSizePixel = 0
	Notifications.BackgroundTransparency = 1
	Notifications.AnchorPoint = Vector2.new(1, 1)
	Notifications.Size = UDim2.new(0, 260, 1, 0)
	Notifications.Position = UDim2.new(1, 0, 1, 0)
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

	-- Container for opt-in settings pages (UISettings ships by default,
	-- any others are registered by the developer using Aetheris)
	local SettingsPages = Instance.new("Frame")
	SettingsPages.Name = "SettingsPages"
	SettingsPages.Visible = false
	SettingsPages.BorderSizePixel = 0
	SettingsPages.BackgroundTransparency = 1
	SettingsPages.AnchorPoint = Vector2.new(0.5, 0.5)
	SettingsPages.ClipsDescendants = true
	SettingsPages.Size = UDim2.new(0.983, 0, 1, 0)
	SettingsPages.Position = UDim2.new(0.5, 0, 0.5, 0)
	SettingsPages.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SettingsPages.Parent = Content

	local TabContent = Instance.new("Frame")
	TabContent.Name = "TabContent"
	TabContent.BorderSizePixel = 0
	TabContent.BackgroundTransparency = 1
	TabContent.AnchorPoint = Vector2.new(0.5, 0.5)
	TabContent.ClipsDescendants = true
	TabContent.Size = UDim2.new(1, 0, 1, 0)
	TabContent.Position = UDim2.new(0.5, 0, 0.5, 0)
	TabContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabContent.Parent = Content

	local TabContentPadding = Instance.new("UIPadding")
	TabContentPadding.PaddingTop = UDim.new(0, 10)
	TabContentPadding.PaddingRight = UDim.new(0, 5)
	TabContentPadding.PaddingLeft = UDim.new(0, 2)
	TabContentPadding.PaddingBottom = UDim.new(0, 10)
	TabContentPadding.Parent = TabContent

	----------------------------------------------------------------
	-- Sidebar
	----------------------------------------------------------------
	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.BorderSizePixel = 0
	Sidebar.BackgroundColor3 = Color3.fromRGB(21, 21, 21) -- [THEME] sidebar background
	Sidebar.BackgroundTransparency = 1
	Sidebar.AnchorPoint = Vector2.new(0, 0)
	Sidebar.Size = UDim2.new(0.41348, 0, 1, 0)
	Sidebar.Position = UDim2.new(0, 0, 0, 0)
	Sidebar.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Sidebar.Parent = MainFrame

	local SidebarPadding = Instance.new("UIPadding")
	SidebarPadding.PaddingTop = UDim.new(0, 10)
	SidebarPadding.PaddingRight = UDim.new(0, 5)
	SidebarPadding.PaddingLeft = UDim.new(0, 5)
	SidebarPadding.PaddingBottom = UDim.new(0, 15)
	SidebarPadding.Parent = Sidebar

	-- (Sidebar had a UIShadow here, but it was permanently Transparency=1 --
	-- an invisible blur pass costing GPU work every frame -- and was never
	-- referenced anywhere else. Removed for memory/GPU efficiency.)

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
	TabList.Name = "TabList"
	TabList.Active = true
	TabList.ScrollingDirection = Enum.ScrollingDirection.Y
	TabList.BorderSizePixel = 0
	TabList.ScrollBarImageTransparency = 1 -- hidden until scrolling
	TabList.BackgroundTransparency = 1
	TabList.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
	TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	-- Top-pinned offset + fill height (bottom offset leaves room for the divider
	-- and user info), so it stays put vertically instead of drifting on resize.
	TabList.Size = UDim2.new(1, 0, 1, -145)
	TabList.Position = UDim2.new(0, 0, 0, 94)
	TabList.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabList.ScrollBarThickness = 1
	TabList.ScrollBarImageColor3 = theme.TertiaryColor
	TabList.Parent = Sidebar

	-- Scrollbar: only visible while scrolling
	local tabListScrollbarTimer
	TabList:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		-- Compact mode hides the scrollbar entirely: skip the fade-in animation
		-- and keep it fully transparent instead of the usual 0.5 reveal.
		if TabList:GetAttribute("CompactNoScrollbar") then
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
	SearchBar.Name = "SearchBar"
	SearchBar.BorderSizePixel = 0
	SearchBar.BackgroundColor3 = theme.SearchBarBackgroundColor
	SearchBar.BackgroundTransparency = 1
	SearchBar:SetAttribute("IsSearchFocused", false)
	-- Fixed offset from the top (below the script info) so it never drifts.
	SearchBar.Size = UDim2.new(1, 0, 0, 26)
	SearchBar.Position = UDim2.new(0, 0, 0, 48)
	SearchBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SearchBar.Parent = Sidebar

	local SearchBoxCorner = Instance.new("UICorner")
	SearchBoxCorner.CornerRadius = UDim.new(0, 6)
	SearchBoxCorner.Parent = SearchBar

	local SearchBoxStroke = Instance.new("UIStroke") -- [THEME] search box stroke
	SearchBoxStroke.Transparency = 1
	SearchBoxStroke.Color = theme.StrokeColor
	SearchBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	SearchBoxStroke.Parent = SearchBar

	local SearchBox = Instance.new("TextBox")
	SearchBox.Name = "SearchBox"
	SearchBox.TextXAlignment = Enum.TextXAlignment.Left
	SearchBox.PlaceholderColor3 = theme.SecondaryTextColor or Color3.fromRGB(100, 100, 100) -- [THEME] placeholder color
	SearchBox.BorderSizePixel = 0
	SearchBox.TextTruncate = Enum.TextTruncate.AtEnd
	SearchBox.TextTransparency = theme.PrimaryTextTransparency
	SearchBox.TextSize = 12
	SearchBox.TextColor3 = theme.PrimaryTextColor
	SearchBox.BackgroundTransparency = 1
	SearchBox.FontFace = Constants.Font(Enum.FontWeight.Medium)
	SearchBox.PlaceholderText = "Search..."
	SearchBox.Size = UDim2.new(0.7921, 0, 1, 0)
	SearchBox.Position = UDim2.new(0.17991, 0, 0, 0)
	SearchBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SearchBox.Text = ""
	SearchBox.Parent = SearchBar

	local SearchIcon = Instance.new("ImageLabel")
	SearchIcon.Name = "SearchIcon"
	SearchIcon.BorderSizePixel = 0
	SearchIcon.BackgroundTransparency = 1
	SearchIcon.ImageTransparency = 0.5 -- [THEME] search icon transparency
	SearchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	SearchIcon.Image = Icons.search
	SearchIcon.ImageColor3 = theme.SecondaryColor
	SearchIcon.Size = UDim2.new(0, 12, 0, 12)
	SearchIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SearchIcon.Position = UDim2.new(0.09543, 0, 0.5, 0)
	SearchIcon.Parent = SearchBar

	local SearchBarBottomDivider = Instance.new("Frame")
	SearchBarBottomDivider.Name = "BottomDivider"
	SearchBarBottomDivider.BorderSizePixel = 0
	SearchBarBottomDivider.BackgroundColor3 = theme.TertiaryColor
	SearchBarBottomDivider.BackgroundTransparency = 0.9 -- [THEME] divider transparency
	SearchBarBottomDivider.AnchorPoint = Vector2.new(0.5, 0.5)
	SearchBarBottomDivider.Size = UDim2.new(0.8, 0, 0, 1)
	SearchBarBottomDivider.Position = UDim2.new(0.5, 0, 0, 35)
	SearchBarBottomDivider.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SearchBarBottomDivider.Parent = SearchBar

	-- Search bar focus transitions: background tweens to configured
	-- transparency, stroke tweens in, and the icon sharpens to 0.2 when the
	-- box is focused. Bottom divider also sharpens to 0.2 transparency.
	SearchBar.BackgroundTransparency = 1
	SearchBox.Focused:Connect(function()
		SearchBar:SetAttribute("IsSearchFocused", true)
		-- Read the LIVE theme so the focus transparency reflects the current
		-- theme, not the construction-time one.
		local liveTheme = self._theme or theme
		Tween.Play(SearchBar, "Fast", { BackgroundTransparency = liveTheme.SearchBarBackgroundTransparency or 0 })
		SearchBoxStroke.Color = liveTheme.StrokeColor or SearchBoxStroke.Color
		Tween.Play(SearchBoxStroke, "Fast", { Transparency = liveTheme.StrokeTransparency or 0.95 })
		Tween.Play(SearchIcon, "Fast", { ImageTransparency = 0.2 })
		Tween.Play(SearchBarBottomDivider, "Fast", { BackgroundTransparency = 0.2 })
	end)
	SearchBox.FocusLost:Connect(function()
		SearchBar:SetAttribute("IsSearchFocused", false)
		Tween.Play(SearchBar, "Fast", { BackgroundTransparency = 1 })
		Tween.Play(SearchBoxStroke, "Fast", { Transparency = 1 })
		Tween.Play(SearchIcon, "Fast", { ImageTransparency = 0.5 })
		Tween.Play(SearchBarBottomDivider, "Fast", { BackgroundTransparency = 0.9 })
	end)

	-- Live filter: as the user types, hide non-matching sections on the active
	-- page and highlight the matched substring in each component's label.
	-- DEBOUNCED: ApplySearch walks the whole page (GetDescendants), toggles every
	-- section's visibility and rewrites RichText on matching labels, so running it
	-- on every keystroke makes fast typing do N full-tree passes per second.
	-- Coalesce a burst of input into a single pass ~0.15s after the last key.
	-- The delay is imperceptible and the end result is identical.
	local searchDebounce
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if searchDebounce then
			task.cancel(searchDebounce)
		end
		searchDebounce = task.delay(0.15, function()
			searchDebounce = nil
			-- Guard against the window/search box being torn down while the
			-- debounce was still pending.
			if self and self.ApplySearch and SearchBox.Parent then
				self:ApplySearch()
			end
		end)
	end)

	local SidebarDivider = Instance.new("Frame")
	SidebarDivider.Name = "Divider"
	SidebarDivider.BorderSizePixel = 0
	SidebarDivider.BackgroundColor3 = theme.TertiaryColor
	SidebarDivider.BackgroundTransparency = 0.9 -- [THEME] divider transparency
	-- Bottom-anchored so it stays just above the user info on resize.
	SidebarDivider.AnchorPoint = Vector2.new(0.5, 1)
	SidebarDivider.Size = UDim2.new(0.8, 1, 0, 1)
	SidebarDivider.Position = UDim2.new(0.5, 0, 1, -48)
	SidebarDivider.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SidebarDivider.Parent = Sidebar

	----------------------------------------------------------------
	-- Sidebar: user info (bottom)
	----------------------------------------------------------------
	local UserInfo = Instance.new("Frame")
	UserInfo.Name = "UserInfo"
	UserInfo.BorderSizePixel = 0
	UserInfo.BackgroundTransparency = 1
	UserInfo.AnchorPoint = Vector2.new(0.5, 1)
	UserInfo.Size = UDim2.new(1, 0, 0, 50)
	UserInfo.Position = UDim2.new(0.5, 0, 1, 8) -- fixed bottom offset (was 1.02 scale, drifted on resize)
	UserInfo.BorderColor3 = Color3.fromRGB(0, 0, 0)
	UserInfo.Parent = Sidebar

	local UserInfoPadding = Instance.new("UIPadding")
	UserInfoPadding.PaddingRight = UDim.new(0, 10)
	UserInfoPadding.PaddingLeft = UDim.new(0, 10)
	UserInfoPadding.Parent = UserInfo

	local UserInfoGroup = Instance.new("Frame")
	UserInfoGroup.Name = "InformationGroup"
	UserInfoGroup.BorderSizePixel = 0
	UserInfoGroup.BackgroundTransparency = 1
	UserInfoGroup.Size = UDim2.new(1, 0, 0.85, 0)
	UserInfoGroup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	UserInfoGroup.Parent = UserInfo

	local UserInfoGroupLayout = Instance.new("UIListLayout")
	UserInfoGroupLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UserInfoGroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UserInfoGroupLayout.FillDirection = Enum.FillDirection.Horizontal
	UserInfoGroupLayout.Parent = UserInfoGroup

	local PlayerHeadshot = Instance.new("ImageLabel")
	PlayerHeadshot.Name = "PlayerHeadshot"
	PlayerHeadshot.BorderSizePixel = 0
	PlayerHeadshot.BackgroundTransparency = 1
	PlayerHeadshot.Image = "rbxthumb://type=AvatarBust&id=" .. (player and player.UserId or 1) .. "&w=48&h=48"
	PlayerHeadshot.Size = UDim2.new(0, 32, 0, 32)
	PlayerHeadshot.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PlayerHeadshot.LayoutOrder = 1
	PlayerHeadshot.Parent = UserInfoGroup

	local PlayerHeadshotCorner = Instance.new("UICorner")
	PlayerHeadshotCorner.CornerRadius = UDim.new(0, 10)
	PlayerHeadshotCorner.Parent = PlayerHeadshot

	-- The player headshot is a static avatar now: its old hover-swap (fade the
	-- avatar out, reveal a settings gear) was removed. The settings button now
	-- lives in the window-controls cluster (top-right); wire its click handler
	-- here, where TabContent/SettingsPages are in scope.
	-- Settings button toggles between the settings pages and whatever tab the
	-- user was last on. Clicking it while settings are open returns to that
	-- previous page instead of leaving the user stranded on settings.
	-- Toggle off the LIVE visibility of SettingsPages, not a separate local
	-- flag. Other paths (the pill/minimized tab handler) also hide SettingsPages
	-- without touching this closure; a stale flag there made the first settings
	-- click take the wrong branch, so it looked like the button needed two
	-- clicks to open/close after any tab interaction.
	SettingsButton.MouseButton1Click:Connect(function()
		if SettingsPages.Visible then
			SettingsPages.Visible = false
			TabContent.Visible = true
		else
			TabContent.Visible = false
			SettingsPages.Visible = true
			if self.SettingsTabGroup then
				self.SettingsTabGroup:RefreshTitle()
			end
		end
	end)

	local NameContainer = Instance.new("Frame")
	NameContainer.Name = "NameContainer"
	NameContainer.BorderSizePixel = 0
	NameContainer.BackgroundTransparency = 1
	NameContainer.Size = UDim2.new(0.95823, -42, 0, 32)
	NameContainer.Position = UDim2.new(0.22278, 0, 0.19619, 0)
	NameContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
	NameContainer.LayoutOrder = 2
	NameContainer.Parent = UserInfoGroup

	local NameContainerPadding = Instance.new("UIPadding")
	NameContainerPadding.Name = "UserAndDisplayFrameUIPadding"
	NameContainerPadding.PaddingTop = UDim.new(0, 3)
	NameContainerPadding.PaddingLeft = UDim.new(0, 8)
	NameContainerPadding.Parent = NameContainer

	local NameContainerLayout = Instance.new("UIListLayout")
	NameContainerLayout.Name = "UserAndDisplayFrameUIListLayout"
	NameContainerLayout.Padding = UDim.new(0, 4)
	NameContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	NameContainerLayout.Parent = NameContainer

	local Username = Instance.new("TextLabel")
	Username.Name = "Username"
	Username.TextTruncate = Enum.TextTruncate.SplitWord
	Username.BorderSizePixel = 0
	Username.TextSize = 12
	Username.TextXAlignment = Enum.TextXAlignment.Left
	Username.TextTransparency = 0.7 -- secondary text (slightly more transparent than DisplayName)
	Username.TextYAlignment = Enum.TextYAlignment.Top
	Username.BackgroundTransparency = 1
	Username.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	Username.TextColor3 = theme.TitleTextColor
	Username.Size = UDim2.new(1, 0, 0, 0)
	Username.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Username.Text = "@" .. (player and player.Name or "Guest")
	Username.LayoutOrder = 1
	Username.AutomaticSize = Enum.AutomaticSize.XY
	Username.Parent = NameContainer

	local DisplayName = Instance.new("TextButton")
	DisplayName.Name = "DisplayName"
	DisplayName.BorderSizePixel = 0
	DisplayName.TextXAlignment = Enum.TextXAlignment.Left
	DisplayName.TextTransparency = 0.3 -- matches ScriptName
	DisplayName.TextSize = 13
	DisplayName.TextColor3 = theme.TitleTextColor
	DisplayName.BackgroundTransparency = 1
	DisplayName.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	DisplayName.AutomaticSize = Enum.AutomaticSize.XY
	DisplayName.Size = UDim2.new(1, 0, 0, 0)
	DisplayName.BorderColor3 = Color3.fromRGB(0, 0, 0)
	DisplayName.Text = player and player.DisplayName or "Guest"
	DisplayName.Parent = NameContainer

	-- Clicking the display name toggles masking of both the display name and username.
	local originalDisplayName = DisplayName.Text
	local originalUsername = Username.Text
	local masked = false
	DisplayName.MouseButton1Click:Connect(function()
		masked = not masked
		DisplayName.Text = masked and "********" or originalDisplayName
		Username.Text = masked and "********" or originalUsername
	end)

	local TimeLabel = Instance.new("TextLabel")
	TimeLabel.Name = "TimeLabel"
	TimeLabel.TextWrapped = true
	TimeLabel.BorderSizePixel = 0
	TimeLabel.TextSize = 12
	TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
	TimeLabel.TextTransparency = 0.3 -- matches ScriptName
	TimeLabel.TextScaled = true
	TimeLabel.BackgroundTransparency = 1
	TimeLabel.FontFace = Constants.Font(Enum.FontWeight.Regular)
	TimeLabel.TextColor3 = theme.TitleTextColor
	TimeLabel.RichText = true
	TimeLabel.Size = UDim2.new(0.1, 0, 0.7, 0)
	TimeLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	local function clockText()
		local t = os.date("*t")
		return "<b>"..string.format("%02d", t.hour).."</b><br /><br />"..string.format("%02d", t.min)
	end
	TimeLabel.Text = clockText()
	TimeLabel.LayoutOrder = 3
	TimeLabel.AutomaticSize = Enum.AutomaticSize.XY
	TimeLabel.Position = UDim2.new(0.83, 0, 0.89262, 0)
	TimeLabel.Parent = UserInfoGroup

	-- Refresh the clock once a second so it doesn't freeze at whatever time the
	-- window was created. The loop exits on teardown (clockStopped) or once the
	-- label is gone.
	task.spawn(function()
		while not clockStopped do
			task.wait(1)
			if clockStopped or not TimeLabel.Parent then
				break
			end
			TimeLabel.Text = clockText()
		end
	end)

	----------------------------------------------------------------
	-- Sidebar: script info
	----------------------------------------------------------------
	local ScriptInfo = Instance.new("Frame")
	ScriptInfo.Name = "ScriptInfo"
	ScriptInfo.BorderSizePixel = 0
	ScriptInfo.BackgroundTransparency = 1
	ScriptInfo.Size = UDim2.new(0.84065, 0, 0, 42) -- fixed height; scale Y made it shrink on resize
	ScriptInfo.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScriptInfo.Parent = Sidebar

	local ScriptInfoGroup = Instance.new("Frame")
	ScriptInfoGroup.Name = "InformationGroup"
	ScriptInfoGroup.BorderSizePixel = 0
	ScriptInfoGroup.BackgroundTransparency = 1
	ScriptInfoGroup.Size = UDim2.new(1, 0, 1, 0)
	ScriptInfoGroup.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScriptInfoGroup.Parent = ScriptInfo

	local ScriptInfoGroupLayout = Instance.new("UIListLayout")
	ScriptInfoGroupLayout.Padding = UDim.new(0, 8)
	ScriptInfoGroupLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	ScriptInfoGroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ScriptInfoGroupLayout.FillDirection = Enum.FillDirection.Horizontal
	ScriptInfoGroupLayout.Parent = ScriptInfoGroup

	local ScriptLogo = Instance.new("ImageLabel")
	ScriptLogo.Name = "ScriptLogo"
	ScriptLogo.BorderSizePixel = 0
	ScriptLogo.BackgroundTransparency = 1
	ScriptLogo.Image = "rbxassetid://92458734285074"
	ScriptLogo.Size = UDim2.new(0, 40, 0, 32)
	ScriptLogo.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScriptLogo.LayoutOrder = 1
	ScriptLogo.Parent = ScriptInfoGroup
	
	local ScriptLogoUICorner = Instance.new("UICorner")
	ScriptLogoUICorner.CornerRadius = UDim.new(0, 6)
	ScriptLogoUICorner.Parent = ScriptLogo

	local ScriptInfoContainer = Instance.new("Frame")
	ScriptInfoContainer.Name = "ScriptInfoContainer"
	ScriptInfoContainer.BorderSizePixel = 0
	ScriptInfoContainer.BackgroundTransparency = 1
	ScriptInfoContainer.Size = UDim2.new(0.95823, -42, 0, 32)
	ScriptInfoContainer.Position = UDim2.new(0.22278, 0, 0.19619, 0)
	ScriptInfoContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScriptInfoContainer.LayoutOrder = 2
	ScriptInfoContainer.Parent = ScriptInfoGroup

	local ScriptInfoContainerLayout = Instance.new("UIListLayout")
	ScriptInfoContainerLayout.Name = "UserAndDisplayFrameUIListLayout"
	ScriptInfoContainerLayout.Padding = UDim.new(0, 4)
	ScriptInfoContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ScriptInfoContainerLayout.Parent = ScriptInfoContainer

	local ScriptName = Instance.new("TextLabel")
	ScriptName.Name = "ScriptName"
	ScriptName.TextTruncate = Enum.TextTruncate.SplitWord
	ScriptName.BorderSizePixel = 0
	ScriptName.TextSize = 13
	ScriptName.TextXAlignment = Enum.TextXAlignment.Left
	ScriptName.TextTransparency = 0.3 -- [THEME] primary text transparency
	ScriptName.TextYAlignment = Enum.TextYAlignment.Top
	ScriptName.BackgroundTransparency = 1
	ScriptName.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	ScriptName.TextColor3 = theme.TitleTextColor
	ScriptName.Size = UDim2.new(1.36294, 0, 0.44828, 0)
	ScriptName.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScriptName.Text = "Aetheris | Jailbreak"
	ScriptName.LayoutOrder = 1
	ScriptName.AutomaticSize = Enum.AutomaticSize.XY
	ScriptName.Position = UDim2.new(0, 0, 0, 0)
	ScriptName.Parent = ScriptInfoContainer

	-- Tag gradient base/accent tracking. Each gradient records any caller-pinned
	-- colours as attributes (TagBaseColor / TagAccentColor); a nil one follows the
	-- theme. Forward-declared so restampThemeGradients can reach it before the
	-- tags are built.
	local tagGradients = {}

	-- Rebuild every tag gradient. Called once at build and again on each theme
	-- switch from ApplyTheme. A pinned base/accent is preserved; only the
	-- theme-following side is re-resolved -- previously a pinned BackgroundColor
	-- was overwritten by TertiaryColor here, which is why tag colours were lost
	-- at startup and on every theme round-trip.
	local function restampThemeGradients(t)
		local base = t.TertiaryColor or Color3.fromRGB(30, 30, 34)
		local accent = t.AccentColor or Color3.fromRGB(108, 140, 255)
		for _, g in ipairs(tagGradients) do
			if g and g.Parent then
				local pinnedBase = g:GetAttribute("TagBaseColor")
				local pinnedAccent = g:GetAttribute("TagAccentColor")
				g.Color = ColorSequence.new(
					(typeof(pinnedBase) == "Color3") and pinnedBase or base,
					(typeof(pinnedAccent) == "Color3") and pinnedAccent or accent
				)
			end
		end
	end
	restampThemeGradients(theme)

	----------------------------------------------------------------
	-- Tags  (Settings.Tags: up to 3 pills under the title)
	----------------------------------------------------------------
	-- Each entry is either a plain string (Name only) or a table
	-- { Name=, BackgroundColor=, TextColor=, AccentColor= }. Any colour that is
	-- omitted falls back to the theme (background -> TertiaryColor, text ->
	-- TitleTextColor, accent -> AccentColor). A colour that IS supplied is pinned
	-- with ThemeManager.SetColorOverride so a theme switch never stomps it; the
	-- omitted ones stay as live theme bindings. Pills share the row width evenly
	-- (1 tag = full width, 2 = halves, 3 = thirds).
	local TagsContainer = Instance.new("Frame")
	TagsContainer.Name = "ScriptTags"
	TagsContainer.BorderSizePixel = 0
	TagsContainer.BackgroundTransparency = 1
	TagsContainer.Size = UDim2.new(1, 0, 0, 14)
	TagsContainer.LayoutOrder = 4
	TagsContainer.Parent = ScriptInfoContainer

	local TagsLayout = Instance.new("UIListLayout")
	TagsLayout.Name = "ScriptTagsLayout"
	TagsLayout.FillDirection = Enum.FillDirection.Horizontal
	TagsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TagsLayout.Padding = UDim.new(0, 4)
	TagsLayout.Parent = TagsContainer

	local TAG_GAP = 4
	local function buildTag(spec, index, total)
		local name, bgColor, txtColor, accColor
		if type(spec) == "table" then
			name = spec.Name or spec.Text or ""
			bgColor = spec.BackgroundColor
			txtColor = spec.TextColor
			accColor = spec.AccentColor
		else
			name = tostring(spec)
		end

		-- Even split: each pill gets 1/total of the row minus its share of the gaps.
		local widthOffset = -(TAG_GAP * (total - 1)) / total

		local pill = Instance.new("Frame")
		pill.Name = "Tag" .. tostring(index)
		pill.BorderSizePixel = 0
		pill.BackgroundColor3 = bgColor or theme.TertiaryColor
		pill.BackgroundTransparency = 0.5
		pill.Size = UDim2.new(1 / total, widthOffset, 0, 14)
		pill.BorderColor3 = Color3.fromRGB(0, 0, 0)
		pill.LayoutOrder = index
		pill.Parent = TagsContainer

		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(1, 0)
		pillCorner.Parent = pill

		local pillGradient = Instance.new("UIGradient")
		pillGradient.Rotation = 45
		if bgColor then
			pillGradient:SetAttribute("TagBaseColor", bgColor)
		end
		if accColor then
			pillGradient:SetAttribute("TagAccentColor", accColor)
		end
		pillGradient.Color = ColorSequence.new(
			bgColor or theme.TertiaryColor,
			accColor or theme.AccentColor or Color3.fromRGB(108, 140, 255)
		)
		pillGradient.Parent = pill
		table.insert(tagGradients, pillGradient)

		local label = Instance.new("TextLabel")
		label.Name = "TagText"
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
		label.Size = UDim2.new(1, 0, 1, 0)
		label.Parent = pill

		-- Theme bindings only where the caller did NOT pin a colour; a pinned
		-- colour goes through the override so theme switches leave it alone.
		if bgColor then
			ThemeManager.SetColorOverride(pill, "BackgroundColor3", bgColor)
		else
			ThemeManager.BindColor(pill, "BackgroundColor3", "TertiaryColor")
		end
		ThemeManager.BindTransparency(pill, "BackgroundTransparency", "ComponentBackgroundTransparency")
		if txtColor then
			ThemeManager.SetColorOverride(label, "TextColor3", txtColor)
		else
			ThemeManager.BindColor(label, "TextColor3", "TitleTextColor")
		end
	end

	local function buildTags(list)
		for _, c in ipairs(TagsContainer:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		for i = #tagGradients, 1, -1 do tagGradients[i] = nil end
		if type(list) ~= "table" then return end
		local total = math.min(#list, 3)
		for i = 1, total do
			buildTag(list[i], i, total)
		end
	end
	buildTags(Settings.Tags)

	----------------------------------------------------------------
	-- Resize handle
	----------------------------------------------------------------
	local ResizeButton = Instance.new("ImageButton")
	ResizeButton.Name = "ResizeButton"
	ResizeButton.BorderSizePixel = 0
	ResizeButton.AutoButtonColor = false
	ResizeButton.ImageTransparency = 1
	ResizeButton.BackgroundTransparency = 1
	ResizeButton.AnchorPoint = Vector2.new(1, 1)
	ResizeButton.Image = "rbxassetid://8445471173"
	ResizeButton.ImageRectSize = Vector2.new(96, 96)
	ResizeButton.ImageRectOffset = Vector2.new(704, 804)
	ResizeButton.Size = UDim2.new(0, 28, 0, 28)
	ResizeButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ResizeButton.Position = UDim2.new(0.99, 0, 0.99, 0)
	ResizeButton.Parent = MainFrame

	----------------------------------------------------------------
	-- Apply Settings
	----------------------------------------------------------------
	if Settings.Title then
		ScriptName.Text = Settings.Title
	end
	-- (AnimationStyle/DragStyle are applied to the local animationStyle/dragStyle
	-- hoisted above; no class-level write.)

	----------------------------------------------------------------
	-- Object
	----------------------------------------------------------------
	self = setmetatable({}, Window)
	self.AnimationStyle = animationStyle
	self.DragStyle = dragStyle
	self.MainFrameShadow = MainFrameShadow

	-- Store the resolved theme BEFORE any settings pages/scripts build,
	-- so components created there use the correct theme instead of Default.
	self._theme = theme

	-- Store the original theme name (when a named theme was passed) so the
	-- Themes settings page can mark the correct card as active on first build.
	if type(Settings.Theme) == "string" then
		self._themeName = Settings.Theme
	else
		self._themeName = "Default"
	end

	-- Default minimize keybind (settable via CreateWindow's MinimizeKey). Only a
	-- single letter is uppercased; multi-char names (e.g. "LeftControl") are kept
	-- as-is so they match Enum.KeyCode.Name for the keybind lookup.
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





	----------------------------------------------------------------
	-- Resize (drag from ResizeButton, clamped to MainFrame's UISizeConstraint)
	----------------------------------------------------------------
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
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				resizing = true
				updateResizeVisual()
				resizeStart = input.Position
				startSize = MainFrame.AbsoluteSize

				if inputEndedConnection then
					inputEndedConnection:Disconnect()
				end
				inputEndedConnection = UserInputService.InputEnded:Connect(function(endInput)
					if endInput.UserInputType == Enum.UserInputType.MouseButton1
					or endInput.UserInputType == Enum.UserInputType.Touch then
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
			if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - resizeStart
				local minSize = MainFrameSizeConstraint.MinSize
				local newWidth = math.max(minSize.X, startSize.X + delta.X)
				local newHeight = math.max(minSize.Y, startSize.Y + delta.Y)
				MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
			end
		end)
	end

	----------------------------------------------------------------
	-- Minimize / Maximize / Close
	----------------------------------------------------------------
	-- Shared theme-matched tooltip for the minimize pill buttons.
	local tooltip = Tooltip.new(ScreenGui, theme)
	self.Tooltip = tooltip

	local function minimizePreset()
		return animationStyle == "Snappy" and "MinimizeSnappy" or "Minimize"
	end

	----------------------------------------------------------------
	-- Minimize pill (right-center of screen, offset from the edge)
	----------------------------------------------------------------
	-- CanvasGroup so GroupTransparency can dim the WHOLE pill (background +
	-- buttons + stroke) at rest in one property, and clear on hover.
	local pill = Instance.new("CanvasGroup")
	pill.Name = "MinimizePill"
	pill.AutomaticSize = Enum.AutomaticSize.Y
	pill.Size = UDim2.new(0, 56, 0, 0)

	local pillLayout -- forward decl: the UIListLayout is created further down

	-- Pill position + tooltip side are data-driven from SettingsStore.PillPosition
	-- ("right" | "left" | "top" | "bottom"). The tooltip opens AWAY from the
	-- nearest screen edge so it never clips off-screen.
	local PILL_SIDES = {
		right  = { anchor = Vector2.new(1, 0.5), position = UDim2.new(1, -12, 0.5, 0),  tip = "Left" },
		left   = { anchor = Vector2.new(0, 0.5), position = UDim2.new(0, 12, 0.5, 0),   tip = "Right" },
		top    = { anchor = Vector2.new(0.5, 0), position = UDim2.new(0.5, 0, 0, 12),   tip = "Bottom" },
		bottom = { anchor = Vector2.new(0.5, 1), position = UDim2.new(0.5, 0, 1, -12),  tip = "Top" },
	}
	local function currentPillSide()
		local s = SettingsStore.Get("PillPosition")
		return PILL_SIDES[s] and s or "right"
	end
	local function applyPillPosition()
		local side = currentPillSide()
		local def = PILL_SIDES[side]
		pill.AnchorPoint = def.anchor
		pill.Position = def.position
		-- Top/bottom docks run HORIZONTALLY (wider than tall); left/right stay
		-- vertical strips. Flip size + layout direction so it lays out right.
		local horizontal = (side == "top" or side == "bottom")
		if pillLayout then
			pillLayout.FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
		end
		pill.AutomaticSize = horizontal and Enum.AutomaticSize.X or Enum.AutomaticSize.Y
		pill.Size = horizontal and UDim2.new(0, 0, 0, 56) or UDim2.new(0, 56, 0, 0)
	end
	local function pillTooltipSide()
		return PILL_SIDES[currentPillSide()].tip
	end
	function self:SetPillPosition(side)
		SettingsStore.Set("PillPosition", side)
		applyPillPosition()
	end

	----------------------------------------------------------------
	-- Compact mode (responsive). When the window gets narrow (or the user
	-- forces it), the side sidebar collapses, the tab pills reflow into a
	-- horizontal, horizontally-scrolling row under the title bar, search moves
	-- up next to the window controls, and the content area goes full-width.
	-- Trigger: AUTO by MainFrame absolute width (with hysteresis) unless
	-- SettingsStore.CompactMode is "always"/"never".
	----------------------------------------------------------------
	do
		local COMPACT_ENTER = 672  -- below this width -> compact (auto); 672 is the last expanded width
		local COMPACT_EXIT = 712   -- above this width -> expanded (hysteresis)
		local compact = false
		local saved = nil          -- captured expanded values for restore
		local initialized = false  -- set true after the first deferred resolve; gates AUTO mode

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

		-- Restyle one tab button + its inner label/icon for the given orientation.
		-- TabGroup builds buttons sized for the vertical sidebar (label at scale
		-- X 0.647); flipping just the button Size leaves those children hanging
		-- off a short/wide button, so the tabs look invisible. This fixes both the
		-- button AND its children.
		local function styleTabButton(btn, horizontal)
			if not btn or not btn:IsA("TextButton") then return end
			-- Raise the pill + its children above everything else in the window so
			-- they can't be hidden behind Content/ContentBackground/SettingsPages.
			btn.ZIndex = 60
			local tabName = btn:FindFirstChild("TabName")
			local tabImage = btn:FindFirstChild("TabImage")
			if tabName then tabName.ZIndex = 61 end
			if tabImage then tabImage.ZIndex = 61 end
			if horizontal then
				btn.Size = UDim2.new(0, 100, 0, 30)
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
					tabName.Position = UDim2.new(0.647, 0, 0.5, 0)
					tabName.Size = UDim2.new(0.636, 0, 0.714, 0)
				end
			end
		end

		local function restyleTabButtons(horizontal)
			for _, child in ipairs(TabList:GetChildren()) do
				styleTabButton(child, horizontal)
			end
		end

		local function applyCompact(on)
			if not saved then saved = captureExpanded() end
			if on then
				-- Reparent the tab row OUT of the sidebar FIRST, then hide the sidebar.
				-- Hiding the sidebar while the row is still its child trips the spin
				-- visibility gate and pauses every tab spin for good (reparenting
				-- afterwards doesn't resume them). Order matters here.
				TabList.LayoutOrder = -1
				TabList.ZIndex = 50 -- stay above SettingsPages/ContentBackground while compact
				TabList.ClipsDescendants = true -- clip pills to the row (they scroll horizontally)
				TabList.Parent = MainFrame
				Sidebar.Visible = false -- hide the sidebar AFTER the row has moved out
				TabList.ScrollingDirection = Enum.ScrollingDirection.X
				-- Hide the tab-row scrollbar completely (no fade-in animation).
				TabList:SetAttribute("CompactNoScrollbar", true)
				TabList.ScrollBarImageTransparency = 1
				TabList.AutomaticCanvasSize = Enum.AutomaticSize.X
				-- Pin the canvas HEIGHT to the row height. Otherwise the canvas keeps a
				-- large Y (leftover), and the layout's VerticalAlignment.Center centers
				-- the pills inside that huge canvas -> they render at the bottom.
				TabList.CanvasSize = UDim2.new(0, 0, 1, 0)
				TabList.CanvasPosition = Vector2.new(0, 0)
				TabList.AnchorPoint = Vector2.new(0.5, 0)
				TabList.Position = UDim2.new(0.5, 0, 0, 65)
				TabList.Size = UDim2.new(0.95, 0, 0, 40)
				-- 4px bottom padding + hide sidebar dividers (they add spacing
				-- between pills in the horizontal row).
				local compactPad = TabList:FindFirstChild("CompactPad")
				if not compactPad then
					compactPad = Instance.new("UIPadding")
					compactPad.Name = "CompactPad"
					compactPad.Parent = TabList
				end
				compactPad.PaddingBottom = UDim.new(0, 4)
				compactPad.PaddingLeft = UDim.new(0, 6)
				for _, child in ipairs(TabList:GetChildren()) do
					if child:GetAttribute("IsDivider") then
						child.Visible = false
					end
				end
				TabListLayout.FillDirection = Enum.FillDirection.Horizontal
				TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
				TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
				restyleTabButtons(true)
				-- Search -> docked INTO the window-controls cluster, leftmost (order 0,
				-- before the settings gear etc.). The cluster's UIListLayout lays it out.
				SearchBar.Parent = WindowControls
				SearchBar.AnchorPoint = Vector2.new(0, 0)
				SearchBar.LayoutOrder = -1 -- before the settings button (which is order 0)
				SearchBar.Size = UDim2.new(0, 120, 0, 20)
				SearchBar.Position = UDim2.new(0, 0, 0, 0)
				SearchBarBottomDivider.Position = UDim2.new(0.5, 0, 0, 30)
				SearchBarBottomDivider.Visible = false -- hidden while docked in the controls
				-- Content full width, below the tab row.
				Content.Size = UDim2.new(1, -16, 1, -124)
				Content.Position = UDim2.new(0, 8, 0, 90)
				Tween.Play(Content, "Smooth", { Position = UDim2.new(0, 8, 0, 100) })
				ContentBackground.AnchorPoint = Vector2.new(0, 0)
				ContentBackground.Size = UDim2.new(1, 0, 1, 0)
				ContentBackground.Position = UDim2.new(0, 0, 0, 0)
				-- Compact: square up every corner (full-bleed content background).
				ContentBackgroundCorner.TopLeftRadius = UDim.new(0, 6)
				ContentBackgroundCorner.BottomLeftRadius = UDim.new(0, 6)
				ContentBackgroundCorner.TopRightRadius = UDim.new(0, 6)
				ContentBackgroundCorner.BottomRightRadius = UDim.new(0, 6)
				-- Replace the page title with the script info (logo + name + desc)
				-- at the top-left of the compact title bar.
				PageTitle.Visible = false
				-- Push the settings pages down so they clear the compact title bar /
				-- docked search bar at the top.
				SettingsPages.Position = UDim2.new(0.5, 0, 0.5, 12)
				TabContent.Position = UDim2.new(0.5, 0, 0.55, 0)
				TabContentPadding.PaddingTop = UDim.new(0, 0)
				ScriptInfo.Parent = MainFrame
				ScriptInfo.Size = UDim2.new(0, 200, 0, 40)
				ScriptInfo.Position = UDim2.new(0, 5, 0, 5)
				-- Content goes 2-column -> 1-column: each tab's Left/Right column
				-- stack vertically instead of sitting side by side.
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
				local compactPad = TabList:FindFirstChild("CompactPad")
				if compactPad then compactPad:Destroy() end
				for _, child in ipairs(TabList:GetChildren()) do
					if child:GetAttribute("IsDivider") then
						child.Visible = true
					end
				end
				TabList.ScrollingDirection = saved.tabListScrollDir
				TabList:SetAttribute("CompactNoScrollbar", false)
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

		function self:SetCompact(on)
			compact = on and true or false
			applyCompact(compact)
		end

		local function resolveAndApply()
			local mode = SettingsStore.Get("CompactMode") or "auto"
			if mode == "always" then
				if not compact then compact = true; applyCompact(true) end
			elseif mode == "never" then
				if compact then compact = false; applyCompact(false) end
			else
				-- Auto mode only reacts to REAL resizes, never the initial build
				-- frame (the default window can legitimately start narrow in
				-- small viewports; compacting there would hide the sidebar).
				if not initialized then return end
				local w = MainFrame.AbsoluteSize.X
				if not compact and w < COMPACT_ENTER then
					compact = true; applyCompact(true)
				elseif compact and w > COMPACT_EXIT then
					compact = false; applyCompact(false)
				end
			end
		end
		self._ResolveCompact = resolveAndApply

		-- Tabs can be created AFTER we entered compact (e.g. a new group). Style
		-- any tab button added while compact so it isn't left in sidebar sizing.
		TabList.ChildAdded:Connect(function(child)
			if not compact then return end
			if child:GetAttribute("IsDivider") then
				child.Visible = false
			else
				styleTabButton(child, true)
			end
		end)

		MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(resolveAndApply)
		-- First pass only applies a FORCED mode (Always/Never); auto waits for
		-- an actual resize so the window always starts in its full layout.
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
	pillStroke.Transparency = 0.7
	pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pillStroke.Parent = pill
	local pillShadow = Instance.new("UIShadow")
	pillShadow.Color = theme.PopupShadowColor or Color3.fromRGB(0, 0, 0)
	pillShadow.BlurRadius = UDim.new(0, 16)
	pillShadow.Transparency = 1 -- rest: invisible; only shows on hover (0.5)
	pillShadow.Parent = pill
	local pillScale = Instance.new("UIScale")
	pillScale.Scale = 1
	pillScale.Parent = pill

	-- At rest the pill is dim + small so it doesn't block the game view; hovering
	-- the pill (or any of its buttons) makes it fully visible and grows it with a
	-- bounce. MouseLeave only fires once the cursor is fully off the pill area,
	-- so moving between buttons keeps it expanded.
	local PILL_REST_GROUP = 0.55 -- dim everything at rest so it doesn't block the game
	local PILL_HOVER_GROUP = 0
	local PILL_REST_SCALE = 0.85
	local PILL_HOVER_SCALE = 1
	pill.GroupTransparency = PILL_REST_GROUP
	pill.MouseEnter:Connect(function()
		Tween.Play(pill, "Fast", { GroupTransparency = PILL_HOVER_GROUP })
		Tween.Play(pillScale, "HoverIn", { Scale = PILL_HOVER_SCALE })
		Tween.Play(pillShadow, "Fast", { Transparency = 0.5 })
	end)
	pill.MouseLeave:Connect(function()
		Tween.Play(pill, "Fast", { GroupTransparency = PILL_REST_GROUP })
		Tween.Play(pillScale, "HoverOut", { Scale = PILL_REST_SCALE })
		Tween.Play(pillShadow, "Fast", { Transparency = 1 })
	end)
	local pillPad = Instance.new("UIPadding")
	pillPad.PaddingTop = UDim.new(0, 8)
	pillPad.PaddingBottom = UDim.new(0, 8)
	pillPad.PaddingLeft = UDim.new(0, 8)
	pillPad.PaddingRight = UDim.new(0, 8)
	pillPad.Parent = pill
	pillLayout = Instance.new("UIListLayout")
	pillLayout.Padding = UDim.new(0, 8)
	pillLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pillLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pillLayout.Parent = pill
	applyPillPosition() -- now that pillLayout exists, apply the saved side

	local minimizeWindow
	local restoreWindow
	-- Pill buttons are created ONCE per tab and REUSED across every minimize/
	-- restore cycle. They used to be destroyed + rebuilt on each minimize, which
	-- churned instances and made the back image / tab icons snap invisible
	-- instead of fading. Keyed by tab so we never duplicate.
	local pillButtonByTab = {}

	local function stylePillContainer(t)
		pill.BackgroundColor3 = t.PopupBackgroundColor or Color3.fromRGB(15, 15, 16)
		pill.BackgroundTransparency = 0.05
		pill.GroupTransparency = PILL_REST_GROUP
		pillStroke.Color = t.StrokeColor or Color3.fromRGB(255, 255, 255)
		pillStroke.Transparency = 0.7
		pillShadow.Color = t.PopupShadowColor or Color3.fromRGB(0, 0, 0)
		pillShadow.Transparency = 1 -- rest: hidden; hover sets 0.5
	end

	-- Restyle ONE existing pill button to match its tab's current active state.
	local function stylePillButton(btn, tab, t, isActive)
		btn.BackgroundColor3 = t.ActiveTabButtonColor or t.PrimaryColor or Color3.fromRGB(99, 102, 241)
		btn.BackgroundTransparency = isActive and 0.1 or 1
		local back = btn:FindFirstChild("BackImage")
		if back then
			back.Image = (tab.BackImage and tab.BackImage.Image) or "rbxassetid://11094025229"
			back.ImageTransparency = isActive and 0 or 1
			-- Only (re)start/stop the spin when the active state actually changed,
			-- so spamming minimize doesn't reset the active button's sweep.
			local wasActive = btn:GetAttribute("PillActive") == true
			if isActive ~= wasActive then
				btn:SetAttribute("PillActive", isActive)
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
		local icon = btn:FindFirstChild("PillIcon")
		if icon then
			icon.Image = (tab.TabImage and tab.TabImage.Image) or "rbxassetid://8445470392"
			icon.ImageColor3 = isActive and (t.ActiveTabIconColor or Color3.fromRGB(255, 255, 255)) or (t.InactiveTabIconColor or Color3.fromRGB(200, 200, 200))
			icon.ImageTransparency = isActive and (t.ActiveTabIconTransparency or 0.2) or (t.InactiveTabIconTransparency or 0.6)
		end
	end

	-- Build a pill button for one tab. Called at most ONCE per tab.
	local function createPillButton(tab, i, t)
		local isActive = (tab == (self.TabGroup and self.TabGroup.ActiveTab))
		local btn = Instance.new("TextButton")
			btn.Name = tab.Name .. "PillButton"
			btn.Size = UDim2.new(0, 40, 0, 40)
			-- Only the ACTIVE tab shows its filled background; the rest are plain.
			btn.BackgroundColor3 = t.ActiveTabButtonColor or t.PrimaryColor or Color3.fromRGB(99, 102, 241)
			btn.BackgroundTransparency = isActive and 0.1 or 1
			btn.AutoButtonColor = false
			btn.Text = ""
			btn.LayoutOrder = i
			btn.ZIndex = 1501
			btn.Parent = pill
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent = btn
			-- UIScale grows from the center -> bouncy hover feel.
			local btnScale = Instance.new("UIScale")
			btnScale.Scale = 1
			btnScale.Parent = btn
			-- Spinning-gradient backdrop, same look as the sidebar tab buttons.
			local back = Instance.new("ImageLabel")
			back.Name = "BackImage"
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
			icon.Name = "PillIcon"
			icon.BorderSizePixel = 0
			icon.BackgroundTransparency = 1
			icon.Image = (tab.TabImage and tab.TabImage.Image) or "rbxassetid://8445470392"
			icon.ImageColor3 = isActive and (t.ActiveTabIconColor or Color3.fromRGB(255, 255, 255)) or (t.InactiveTabIconColor or Color3.fromRGB(200, 200, 200))
			icon.ImageTransparency = isActive and (t.ActiveTabIconTransparency or 0.2) or (t.InactiveTabIconTransparency or 0.6)
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
				-- Mirror the sidebar tab click: leave the settings pages and show
				-- the normal tab content for the selected tab.
				if self.SettingsPages then self.SettingsPages.Visible = false end
				if self.TabContent then self.TabContent.Visible = true end
				if self.TabGroup then
					self.TabGroup:SetActiveTab(tab)
				end
				-- SetActiveTab early-returns when the clicked tab is ALREADY active,
				-- so it never re-snaps that page's FadeLayer. If the Settings page had
				-- hidden it, the page would restore blank. An explicit pill click is
				-- always an intent to SHOW this tab, so force its layer visible here.
				if tab and tab.FadeLayer then
					tab.FadeLayer.Visible = true
					PageFade.Snap(tab.FadeLayer, 0)
				end
				restoreWindow()
			end)
			pillButtonByTab[tab] = btn
			stylePillButton(btn, tab, t, isActive)
	end

	-- Ensure every tab has a reusable pill button, then restyle all to the live
	-- theme / active state. Idempotent -- never destroys live buttons. Call it on
	-- tab creation, on minimize, and on theme change.
	local function buildPill(themeOverride)
		local t = themeOverride or self._theme or theme
		tooltip:SetTheme(t)
		stylePillContainer(t)
		if not self.TabGroup then return end
		-- Drop buttons whose tab no longer exists.
		local live = {}
		for _, tab in ipairs(self.TabGroup.Tabs) do live[tab] = true end
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
	end

	-- Exposed so Window:Tab and ApplyTheme keep the pill in sync.
	self._refreshPill = buildPill

	-- Guard against overlapping minimize/restore. Without this, spamming the
	-- keybind starts a second fade while the first is mid-flight: the window fade
	-- cache gets captured from half-faded values and the completion callbacks
	-- fire out of order, leaving elements stuck transparent/invisible. Only the
	-- stable states ("shown" / "hidden") accept a toggle.
	local minimizeState = "shown"

	minimizeWindow = function()
		if minimizeState ~= "shown" then return end
		minimizeState = "minimizing"
		Sound.Play("UIClose")
		self._windowFaded = true
		-- Fade the sidebar tab scrollbar out instead of letting it snap away
		-- when the frame hides. The window fade is one GroupTransparency, which
		-- does NOT cover ScrollBarImageTransparency, so the scrollbar is faded
		-- explicitly here (and cancel its hide timer so it can't fight this tween).
		if tabListScrollbarTimer then
			task.cancel(tabListScrollbarTimer)
			tabListScrollbarTimer = nil
		end
		if TabList then
			Tween.Play(TabList, "Fast", { ScrollBarImageTransparency = 1 })
		end
		buildPill()
		-- Snap the control buttons to their IDLE look before capturing, so the
		-- fade cache stores 0.5 (not the hovered 0.1 / scaled-up state the
		-- minimize button is in right after being clicked).
		for _, ctrl in ipairs({ MinimizeButton, MaximizeButton, CloseButton }) do
			if ctrl then
				ctrl.ImageTransparency = 0.5
				local s = ctrl:FindFirstChildOfClass("UIScale")
				if s then s.Scale = 1 end
			end
		end
		-- Hide + reveal the pill only AFTER the fade completes (event-driven, no
		-- guessed delay), so bright elements like the video finish fading first.
		-- ONE GroupTransparency on the MainFrame CanvasGroup fades the whole
		-- window; no per-descendant snapshot, so nothing inside is touched.
		PageFade.Hide(MainFrame, false, function()
			MainFrame.Visible = false
			pill.Visible = true
			pill.BackgroundTransparency = 0.05
			pill.GroupTransparency = 1
			pillScale.Scale = 0.7
			-- The pill is its own CanvasGroup, but GroupTransparency does NOT cover
			-- its UIStroke/UIShadow -- snap those hidden, then fade them back in
			-- with the group so the pill's stroke/shadow fade instead of popping.
			PageFade.FadeDecorations(pill, true, true)
			-- Pop in, settling at the REST (dim, small) state since it isn't hovered.
			Tween.Play(pill, "Fast", { GroupTransparency = PILL_REST_GROUP })
			PageFade.FadeDecorations(pill, false, false)
			Tween.Play(pillScale, "HoverIn", { Scale = PILL_REST_SCALE })
			minimizeState = "hidden"
		end)
	end

	restoreWindow = function()
		if minimizeState ~= "hidden" then return end
		minimizeState = "restoring"
		Sound.Play("UIOpen")
		tooltip:Hide()
		-- Show + fade the window in immediately, in parallel with the pill fading
		-- out. The active page already rests at its base (invariant), so a single
		-- window fade reveals it correctly with no re-capture and no delay.
		MainFrame.Visible = true
		-- ONE GroupTransparency reveals the window. Because the fade never touches
		-- child transparencies, there is nothing to repair afterwards -- no
		-- RefreshVisuals / RestoreActiveTab / cache re-stamp needed. RefreshVisuals is
-- gone; RestoreActiveTab remains only until ThemeManager's repair block is removed.
		PageFade.Show(MainFrame, false, function()
			self._windowFaded = false
			minimizeState = "shown"
		end)
		-- Fade the pill out in parallel, then hide it. The pill is its own
		-- CanvasGroup, so this is a single GroupTransparency tween.
		PageFade.Hide(pill, false, function()
			pill.Visible = false
			pillScale.Scale = 1
		end)
		Tween.Play(pillScale, "Fast", { Scale = 0.85 })
		task.delay(0.3, function()
			pill.Visible = false
			pillScale.Scale = 1
		end)
	end

	-- Exposed so external callers (e.g. the Minimize keybind in UI Settings) can
	-- toggle minimize/restore. Only acts from a stable state, so rapid repeats
	-- are ignored rather than overlapping. Restore always returns to whatever
	-- was showing (the active tab / settings page), since minimize never
	-- changes tabs.
	self.ToggleMinimize = function()
		if self._destroyed then return end
		if minimizeState == "shown" then
			minimizeWindow()
		elseif minimizeState == "hidden" then
			restoreWindow()
		end
	end

	MinimizeButton.MouseButton1Click:Connect(function()
		self.ToggleMinimize()
	end)

	-- Global minimize keybind: pressing self._minimizeKey toggles minimize from
	-- anywhere in-game. Ignored while a TextBox has focus (processed == true) so
	-- typing the letter into an input never minimizes the window.
	minimizeKeyConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if input.KeyCode.Name == self._minimizeKey and self.ToggleMinimize then
			self.ToggleMinimize()
		end
	end)

	-- Restore the window to its default position + size (used by UI Settings).
	self.ResetLayout = function()
		Tween.Play(MainFrame, minimizePreset(), {
			Size = UDim2.new(0.72026, 0, 0.96995, 0),
			Position = UDim2.new(0.013, 0, 0.015, 0),
		})
	end

	----------------------------------------------------------------
	-- Maximize (full-screen toggle)
	----------------------------------------------------------------
	local maximized = false
	local preMaxSize = MainFrame.Size
	local preMaxPosition = MainFrame.Position
	MaximizeButton.MouseButton1Click:Connect(function()
		maximized = not maximized
		if maximized then
			preMaxSize = MainFrame.Size
			preMaxPosition = MainFrame.Position
			Tween.Play(MainFrame, minimizePreset(), {
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0, 0),
			})
		else
			Tween.Play(MainFrame, minimizePreset(), {
				Size = preMaxSize,
				Position = preMaxPosition,
			})
		end
	end)

	----------------------------------------------------------------
	-- Close (confirm -> fade out + sound -> destroy)
	----------------------------------------------------------------
	-- Teardown: unload EVERYTHING tied to this window when the UI closes.
	-- (Disconnects global UserInputService listeners, unbinds the minimize
	-- keybind, cancels pending tasks + all tweens, destroys cached popups.)
	self._teardown = function()
		if self._destroyed then return end
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

		-- Persist any debounced settings change before the window goes away.
		SettingsStore.Flush()

		if tabListScrollbarTimer then
			task.cancel(tabListScrollbarTimer)
			tabListScrollbarTimer = nil
		end

		-- One sparse sweep over the active-tween registry (O(active tweens))
		-- instead of a per-descendant hash probe (O(tree)).
		Tween.CancelAllUnder(ScreenGui)

		if self._notification then
			self._notification:Destroy()
			self._notification = nil
		end
		if self._dropdownPopups then
			for _, popup in pairs(self._dropdownPopups) do popup:Destroy() end
			self._dropdownPopups = nil
		end
		if self._colorPickerPopups then
			for _, popup in pairs(self._colorPickerPopups) do popup:Destroy() end
			self._colorPickerPopups = nil
		end
		self._toasts = nil
	end

	local function doClose()
		-- Single close pipeline. Previously this had its own PageFade.Hide +
		-- task.delay(0.4) path with a different sound and a different lifetime
		-- than Window:Destroy(); both now go through Destroy so the close
		-- behavior (sound, teardown order, destroy) is identical everywhere.
		self:Destroy()
	end

	CloseButton.MouseButton1Click:Connect(function()
		-- Confirm first unless the user turned confirmation off.
		if not SettingsStore.Get("ConfirmClose") then
			doClose()
			return
		end
		self:UINotification({
			Title = "Close Aetheris?",
			Description = "Are you sure you want to <font color=\"#FF0000\">close</font> the UI?",
			TitleColor = Color3.fromRGB(255, 0, 0),
			ConfirmText = "Yes, close it",
			CancelText = "No, keep it open",
			OnConfirm = doClose,
		})
	end)

	self.TabGroup = TabGroup.new(self, theme)
	self.SettingsTabGroup = SettingsTabGroup.new(self, theme)

	-- Build default settings pages (Themes + UI Settings) first.
	SettingsSystem.BuildDefaultPages(self)

	-- Developer-provided extra settings pages from CreateWindow options.
	-- Each entry may supply a Build(window, tab) callback; `tab` is the
	-- SettingsTabHandle returned by :Tab(), which exposes :Section(Settings).
	-- Sections are the component factories (Toggle/Slider/Keybind/Button/
	-- Dropdown/TextInput/ColorPicker/...). Settings pages are a SINGLE
	-- vertical column (no left/right split) -- sections stack top to bottom.
	-- Example:
	--
	--   SettingsPages = {
	--     { Name = "Keybinds", Icon = ico("keyboard"),
	--       Build = function(window, tab)
	--         local s = tab:Section({ Name = "Combat" })
	--         s:Keybind({ Name = "Aim", Default = "Q", Callback = function() end })
	--       end },
	--   }
	if type(Settings.SettingsPages) == "table" then
		for _, page in ipairs(Settings.SettingsPages) do
			local tab = self.SettingsTabGroup:Tab({
				Name = page.Name or "Settings",
				Icon = page.Icon,
				Active = page.Active,
			})
			if type(page.Build) == "function" then
				-- Custom pages are a single vertical column with an auto-sizing
				-- scroller, so long pages scroll instead of overflowing.
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

	-- Fade the whole UI in on creation: snapshot every transparency while the
	-- window is natural, snap it all invisible, then fade back to base.
	Sound.Play("UIStart")
	-- Fade the whole window in from hidden: snap the single GroupTransparency to
	-- fully transparent, then tween it back to 0. No per-descendant snapshot.
	PageFade.Snap(MainFrame, 1)
	PageFade.Show(MainFrame, false)

	-- Resolve the page the sidebar search should filter: the active settings
	-- page while settings are shown, otherwise the active tab's content.
	function self:GetActivePage()
		if self.SettingsPages and self.SettingsPages.Visible then
			local stab = self.SettingsTabGroup and self.SettingsTabGroup.ActiveTab
			return stab and stab.Page or nil
		end
		local tab = self.TabGroup and self.TabGroup.ActiveTab
		return tab and tab.ContentScroller or nil
	end

	-- Apply the current search text to the active page. Called on every
	-- keystroke and whenever the active page changes.
	function self:ApplySearch()
		local page = self:GetActivePage()
		if not page then return end
		SearchFilter.Apply(page, self.SearchBox.Text, self._theme)
	end

	-- Declarative theming for the WINDOW SHELL. Every state-independent themed
	-- property is a BINDING here (was: stamped imperatively in ApplyTheme, AND
	-- again by ThemeManager.ApplyTheme -> double stamp). SearchBar/SearchBoxStroke
	-- transparencies are focus-driven and stay imperative in ApplyTheme.
	ThemeManager.BindColor(MainFrame, "BackgroundColor3", "WindowColor")
	ThemeManager.BindTransparency(MainFrame, "BackgroundTransparency", "WindowTransparency")
	ThemeManager.BindColor(ContentBackground, "BackgroundColor3", "ContentBackgroundColor")
	ThemeManager.BindTransparency(ContentBackground, "BackgroundTransparency", "ContentBackgroundTransparency")
	ThemeManager.BindColor(Sidebar, "BackgroundColor3", "SidebarColor")
	ThemeManager.BindTransparency(Sidebar, "BackgroundTransparency", "SidebarTransparency")
	ThemeManager.BindColor(MainFrameShadow, "Color", "MainframeShadowColor")
	ThemeManager.BindColor(ResizeButton, "ImageColor3", "TitleTextColor")
	for _, ctrl in ipairs({ MinimizeButton, MaximizeButton, CloseButton }) do
		if ctrl then ThemeManager.BindColor(ctrl, "ImageColor3", "WindowControlColor") end
	end
	ThemeManager.BindColor(PageTitle, "TextColor3", "TitleTextColor")
	ThemeManager.BindTransparency(PageTitle, "TextTransparency", "PrimaryTextTransparency")
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

	-- Component-owned theming for the WINDOW SHELL. The window is the ROOT of
	-- the UI tree (self.Base = the ScreenGui), so it cannot self-register like
	-- components do - the registry iterates Base's DESCENDANTS, which excludes
	-- Base itself. ThemeManager therefore calls this explicitly for the root.
	-- Everything under Base still themes through the component registry.
	function self:ApplyTheme(newTheme)
		local t = ThemeManager.GetTheme(newTheme)
		self._theme = t
		restampThemeGradients(t)

		-- Shell colors/transparencies are BINDINGS now (see the Bind* block
		-- above); a theme switch re-resolves them automatically. Only the bits
		-- that CANNOT be bindings stay here.

		-- Search bar: the BACKGROUND TRANSPARENCIES are focus-driven (stateful),
		-- not theme keys -- stamp them from the current focus state. The bar /
		-- stroke colors are bound.
		local searchFocused = SearchBar:GetAttribute("IsSearchFocused")
		if searchFocused then
			SearchBar.BackgroundTransparency = t.SearchBarBackgroundTransparency or 0
			SearchBoxStroke.Transparency = t.StrokeTransparency or 0.95
		else
			SearchBar.BackgroundTransparency = 1
			SearchBoxStroke.Transparency = 1
		end

		-- Minimize pill colors are BINDINGS now (see the Bind* block above).
		-- Only the per-tab pill buttons need a refresh (they are created lazily).
		if self._refreshPill then self._refreshPill(t) end

		-- Tooltip follows the theme too
		if tooltip and tooltip.SetTheme then
			tooltip:SetTheme(t)
		end
	end

	return self
end

function Window:SetTitle(text)
	self.ScriptName.Text = text
end

-- Apply a theme by name or table
function Window:SetTheme(themeInput)
	local ThemeManager = require("../Themes/ThemeManager")
	if type(themeInput) == "string" then
		self._themeName = themeInput
		-- Persist the choice so the theme survives across sessions. Only named
		-- themes are persisted; a one-off custom table is a session-only look.
		SettingsStore.Set("Theme", themeInput)
	end
	-- ThemeManager.ApplyTheme crossfades colors old -> new.
	ThemeManager.UpdateTheme(self, themeInput)

	-- Recolor cached popups LIVE (they live outside the window tree, so
	-- ApplyTheme does not reach them). Popups that implement ApplyTheme are
	-- recolored in place - no destroy, no stale-color flash, and an already
	-- open popup updates instantly. Any popup without ApplyTheme is dropped so
	-- its create-on-open path rebuilds it with the new theme instead.
	local function refreshPopups(popups)
		if not popups then return end
		for id, popup in pairs(popups) do
			if popup.ApplyTheme then
				popup:ApplyTheme(self._theme)
			elseif popup.Destroy then
				popup:Destroy()
				popups[id] = nil
			end
		end
	end
	refreshPopups(self._dropdownPopups)
	refreshPopups(self._colorPickerPopups)

	-- Notification dialogs now implement ApplyTheme: recolor the cached one in
	-- place so an already-open dialog crossfades with the rest of the window
	-- instead of being destroyed and rebuilt (which caused a stale-color flash
	-- and dropped the user's open dialog). Fall back to dropping it for any
	-- future popup that lacks ApplyTheme.
	if self._notification then
		if self._notification.ApplyTheme then
			self._notification:ApplyTheme(self._theme)
		else
			self._notification:Destroy()
			self._notification = nil
		end
	end

	-- Live-recolor any toasts still on screen. Toasts live in the ScreenGui's
	-- Notifications frame (outside the window tree), so ThemeManager's own pass
	-- never reaches them. Prune entries whose Root has been torn down by
	-- Notification:Close().
	if self._toasts then
		for i = #self._toasts, 1, -1 do
			local toast = self._toasts[i]
			if toast and toast.Root then
				if toast.ApplyTheme then
					toast:ApplyTheme(self._theme)
				end
			else
				table.remove(self._toasts, i)
			end
		end
	end
end

function Window:Destroy()
	-- Re-entrancy guard: doClose funnels here now, and a confirm dialog or a
	-- second close must not double-play the sound or double-destroy the tree.
	if self._destroyed then return end

	local closePreset = self.AnimationStyle == "Snappy" and "FadeOut" or "Smooth"

	-- "WindowClose" was never in Sound.Assets (every play warned + played
	-- nothing). UIClose is the real close sound.
	Sound.Play("UIClose")

	if self._teardown then self._teardown() end

	-- Fade the WHOLE window out. MainFrame is a CanvasGroup, so a single
	-- GroupTransparency tween fades every child; tweening BackgroundTransparency
	-- would only fade the frame's own fill and leave children visible.
	local handle = Tween.Play(self.MainFrame, closePreset, { GroupTransparency = 1 })
	-- UIShadow is NOT covered by CanvasGroup GroupTransparency, so the window
	-- shadow popped out instead of fading with the frame. Fade it explicitly.
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
	if self._refreshPill then self._refreshPill() end
	return tab
end

function Window:Divider()
	return self.TabGroup:Divider()
end

-- Notification system (create and destroy each time)
function Window:UINotification(Settings)
	-- Safety: ensure Settings is a table
	if type(Settings) ~= "table" then
		warn("[Window:UINotification] Settings is not a table, defaulting to {}")
		Settings = {}
	end

	-- If a notification is already open, close and destroy it first
	if self._notification then
		self._notification:Close()
		self._notification:Destroy()
		self._notification = nil
	end

	-- Pass current theme to the notification, same as dropdown/color picker
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
	-- Track live toasts so Window:SetTheme can recolor them in place. Prune
	-- entries whose Root was cleared by Notification:Close() on EVERY spawn, so
	-- the table can't grow unbounded between theme switches.
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
	-- Safety: ensure Settings is a table
	if type(Settings) ~= "table" then
		warn("[Window:DropdownPopUp] Settings is not a table, defaulting to {}")
		Settings = {}
	end

	-- Pass current theme to the popup
	Settings.Theme = self._theme

	-- If we don't have a popup for this ID yet, create one
	if not self._dropdownPopups then
		self._dropdownPopups = {}
	end

	local popup = self._dropdownPopups[id]
	if not popup then
		-- Create a new popup with a cleanup callback
		popup = DropdownPopUp.new(self.PopUpsFolder, Settings, function()
			-- Remove this popup from the table when it's destroyed
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

	-- Hide any currently active popup
	if self._activePopupId and self._activePopupId ~= id then
		local activePopup = self._dropdownPopups[self._activePopupId]
		if activePopup then
			activePopup:Hide()
		end
	end

	-- Show this popup
	if popup then
		popup:Open()
		self._activePopupId = id
	end
	return popup
end

function Window:ColorPickerPopUp(id, Settings)
	-- Safety: ensure Settings is a table
	if type(Settings) ~= "table" then
		warn("[Window:ColorPickerPopUp] Settings is not a table, defaulting to {}")
		Settings = {}
	end

	-- Pass current theme
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
		popup:SetContent(Settings) -- Set initial content for new popup
	else
		popup:SetContent(Settings)
	end

	-- Hide any currently active popup
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

-- Hide all popups
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
