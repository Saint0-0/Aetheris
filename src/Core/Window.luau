--[[
	Window  ·  Aetheris UI Library

	Builds the main Aetheris window shell: chrome, sidebar, content area,
	settings container, drag, resize, minimize/maximize/close, and notifications.
	Returns a window object; use Window.new({...}) via the library facade.

	Public API:
	  :Tab / :Divider              - sidebar tabs (delegated to TabGroup)
	  :SetTitle / :SetDescription  - script info text
	  :SetTheme(name|table)        - live theme switch (crossfades)
	  :UINotification / :Alert / :Error / :VariableNotification
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
local Sound = require("../Utils/Sound")
local Icons = require("../Assets/Icons")
local TabGroup = require("./TabGroup")
local UINotification = require("../Popups/UINotification")
local DropdownPopUp = require("../Popups/DropdownPopUp")
local ColorPickerPopUp = require("../Popups/ColorPickerPopUp")
local Tooltip = require("../Popups/Tooltip")
local VideoFade = require("../Utils/VideoFade")
local ThemeManager = require("../Themes/ThemeManager")
local SearchFilter = require("./SearchFilter")
local SettingsTabGroup = require("./Settings/SettingsTabGroup")
local SettingsSystem = require("./Settings/PageBuilder")
local SettingsStore = require("./Settings/SettingsStore")

local Time = os.date("*t")
local Hour = Time.hour
local Minute = Time.min

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

	-- Global UserInputService connections (drag + resize). These are NOT
	-- children of the ScreenGui, so they are tracked here and explicitly
	-- disconnected in _teardown when the UI is closed/destroyed.
	local dragInputConnection
	local resizeInputConnection

	----------------------------------------------------------------
	-- Root
	----------------------------------------------------------------
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "Aetheris"
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = (player and player:WaitForChild("PlayerGui")) or game:GetService("CoreGui")

	----------------------------------------------------------------
	-- Window (main frame)
	----------------------------------------------------------------
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "Window"
	MainFrame.BorderSizePixel = 0
	MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- [THEME] window background
	MainFrame.BackgroundTransparency = 0.1 -- [THEME] window background transparency
	MainFrame.AnchorPoint = Vector2.new(0, 0)
	MainFrame.Size = UDim2.new(0.72026, 0, 0.96995, 0)
	MainFrame.Position = UDim2.new(0.013, 0, 0.015, 0)
	MainFrame.BorderColor3 = Color3.fromRGB(41, 41, 41)
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

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
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

				if Window.DragStyle == "Smooth" then
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

	local MainFrameShadow = Instance.new("UIShadow") -- [THEME] window shadow color/transparency
	MainFrameShadow.Transparency = 0.5
	MainFrameShadow.BlurRadius = UDim.new(0,20)
	MainFrameShadow.Parent = MainFrame

	local MainFrameSizeConstraint = Instance.new("UISizeConstraint")
	MainFrameSizeConstraint.MinSize = Vector2.new(750, 415)
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
	ContentBackground.BackgroundTransparency = theme.ContentBackgroundTransparency ~= nil and theme.ContentBackgroundTransparency
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
	WindowControls.Position = UDim2.new(0.98301, 0, 0.01715, 0)
	WindowControls.BorderColor3 = Color3.fromRGB(0, 0, 0)
	WindowControls.Parent = MainFrame

	local WindowControlsLayout = Instance.new("UIListLayout")
	WindowControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	WindowControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	WindowControlsLayout.Padding = UDim.new(0, 3)
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

	----------------------------------------------------------------
	-- Page title (drag handle lives here -- whole title bar draggable)
	----------------------------------------------------------------
	local PageTitle = Instance.new("TextLabel")
	PageTitle.Name = "PageTitle"
	PageTitle.TextWrapped = true
	PageTitle.BorderSizePixel = 0
	PageTitle.TextSize = 14
	PageTitle.TextXAlignment = Enum.TextXAlignment.Left
	PageTitle.TextTransparency = 0.4 -- [THEME] title text transparency
	PageTitle.BackgroundTransparency = 1
	-- Base weight is Regular. The "Settings | " prefix and sidebar tab names are
	-- rendered Medium via <font weight="500"> rich-text spans (wrapping them in
	-- <b> forced bold and ignored the FontFace); the page name itself stays
	-- regular.
	PageTitle.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	PageTitle.TextColor3 = theme.TitleTextColor
	PageTitle.RichText = true
	PageTitle.AutomaticSize = Enum.AutomaticSize.X
	PageTitle.Size = UDim2.new(0, 0, 0.06849, 0)
	-- Offset-based X (not scale) so the title stays put as the window resizes;
	-- the sidebar is a fixed 186px, plus a 14px gap.
	PageTitle.Position = UDim2.new(0, 200, 0.055, 0)
	PageTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PageTitle.Text = '<font weight="500">Settings | </font>General'
	PageTitle.Parent = MainFrame

	local PageTitleDivider = Instance.new("Frame")
	PageTitleDivider.Name = "ComponentDivider"
	PageTitleDivider.BorderSizePixel = 0
	PageTitleDivider.BackgroundColor3 = theme.TertiaryColor -- [THEME] divider color
	PageTitleDivider.BackgroundTransparency = 0.9 -- [THEME] divider transparency
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
	SettingsPages.Position = UDim2.new(0.49148, 0, 0.5, 0)
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

	local SidebarShadow = Instance.new("UIShadow") -- [THEME] sidebar shadow
	SidebarShadow.BlurRadius = UDim.new(0,20)
	SidebarShadow.Transparency = 1
	SidebarShadow.Parent = Sidebar

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
	SearchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100) -- [THEME] placeholder color
	SearchBox.BorderSizePixel = 0
	SearchBox.TextTruncate = Enum.TextTruncate.AtEnd
	SearchBox.TextTransparency = theme.PrimaryTextTransparency
	SearchBox.TextSize = 12
	SearchBox.TextColor3 = theme.PrimaryTextColor
	SearchBox.BackgroundTransparency = 1
	SearchBox.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
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
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if self and self.ApplySearch then
			self:ApplySearch()
		end
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

	local UserSettingsButton = Instance.new("ImageButton")
	UserSettingsButton.Name = "Settings"
	UserSettingsButton.BorderSizePixel = 0
	UserSettingsButton.AutoButtonColor = false
	UserSettingsButton.ImageTransparency = 1
	UserSettingsButton.BackgroundTransparency = 1
	UserSettingsButton.AnchorPoint = Vector2.new(0.5, 0.5)
	UserSettingsButton.Image = Icons["settings"]
	UserSettingsButton.ImageColor3 = theme.AccentColor or Color3.fromRGB(96, 165, 250)
	UserSettingsButton.Size = UDim2.new(1, 0, 1, 0)
	UserSettingsButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	UserSettingsButton.Position = UDim2.new(0.5, 0, 0.5, 0)
	UserSettingsButton.Parent = PlayerHeadshot

	-- Headshot hover: fully fade the avatar out and reveal the settings gear.
	PlayerHeadshot.MouseEnter:Connect(function()
		Tween.Play(PlayerHeadshot, "Fast", { ImageTransparency = 1 })
		Tween.Play(UserSettingsButton, "Fast", { ImageTransparency = 0 })
	end)
	PlayerHeadshot.MouseLeave:Connect(function()
		Tween.Play(PlayerHeadshot, "Fast", { ImageTransparency = 0 })
		Tween.Play(UserSettingsButton, "Fast", { ImageTransparency = 1 })
	end)

	-- Clicking the gear opens the settings page.
	UserSettingsButton.MouseButton1Click:Connect(function()
		TabContent.Visible = false
		SettingsPages.Visible = true
		if self.SettingsTabGroup then
			self.SettingsTabGroup:RefreshTitle()
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
	Username.TextTransparency = 0.7 -- [THEME] secondary text transparency
	Username.TextYAlignment = Enum.TextYAlignment.Top
	Username.BackgroundTransparency = 1
	Username.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
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
	DisplayName.TextTransparency = 0.3 -- [THEME] primary text transparency
	DisplayName.TextSize = 13
	DisplayName.TextColor3 = theme.TitleTextColor
	DisplayName.BackgroundTransparency = 1
	DisplayName.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	DisplayName.AutomaticSize = Enum.AutomaticSize.XY
	DisplayName.Size = UDim2.new(1, 0, 0, 0)
	DisplayName.BorderColor3 = Color3.fromRGB(0, 0, 0)
	DisplayName.Text = player and player.DisplayName or "Guest"
	DisplayName.Parent = NameContainer

	local TimeLabel = Instance.new("TextLabel")
	TimeLabel.Name = "TimeLabel"
	TimeLabel.TextWrapped = true
	TimeLabel.BorderSizePixel = 0
	TimeLabel.TextSize = 12
	TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
	TimeLabel.TextTransparency = 0.3 -- [THEME] secondary text transparency
	TimeLabel.TextScaled = true
	TimeLabel.BackgroundTransparency = 1
	TimeLabel.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	TimeLabel.TextColor3 = theme.TitleTextColor
	TimeLabel.RichText = true
	TimeLabel.Size = UDim2.new(0.1, 0, 0.7, 0)
	TimeLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TimeLabel.Text = "<b>"..string.format("%02d", Hour).."</b><br /><br />"..string.format("%02d", Minute)
	TimeLabel.LayoutOrder = 3
	TimeLabel.AutomaticSize = Enum.AutomaticSize.XY
	TimeLabel.Position = UDim2.new(0.83, 0, 0.89262, 0)
	TimeLabel.Parent = UserInfoGroup

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
	ScriptInfoGroupLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	ScriptInfoGroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ScriptInfoGroupLayout.FillDirection = Enum.FillDirection.Horizontal
	ScriptInfoGroupLayout.Parent = ScriptInfoGroup

	local ScriptLogo = Instance.new("ImageLabel")
	ScriptLogo.Name = "ScriptLogo"
	ScriptLogo.BorderSizePixel = 0
	ScriptLogo.BackgroundTransparency = 1
	ScriptLogo.Image = "rbxassetid://140238815705552"
	ScriptLogo.Size = UDim2.new(0, 32, 0, 32)
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

	local ScriptInfoContainerPadding = Instance.new("UIPadding")
	ScriptInfoContainerPadding.Name = "UserAndDisplayFrameUIPadding"
	ScriptInfoContainerPadding.PaddingTop = UDim.new(0, 3)
	ScriptInfoContainerPadding.PaddingLeft = UDim.new(0, 8)
	ScriptInfoContainerPadding.Parent = ScriptInfoContainer

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
	ScriptName.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	ScriptName.TextColor3 = theme.TitleTextColor
	ScriptName.Size = UDim2.new(1.36294, 0, 0.44828, 0)
	ScriptName.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScriptName.Text = "Aetheris | Jailbreak"
	ScriptName.LayoutOrder = 1
	ScriptName.AutomaticSize = Enum.AutomaticSize.XY
	ScriptName.Position = UDim2.new(0, 0, 0, 0)
	ScriptName.Parent = ScriptInfoContainer

	local ScriptDescription = Instance.new("TextLabel")
	ScriptDescription.Name = "ScriptDescription"
	ScriptDescription.TextTruncate = Enum.TextTruncate.SplitWord
	ScriptDescription.BorderSizePixel = 0
	ScriptDescription.TextSize = 10
	ScriptDescription.TextXAlignment = Enum.TextXAlignment.Left
	ScriptDescription.TextTransparency = 0.7 -- [THEME] secondary text transparency
	ScriptDescription.TextYAlignment = Enum.TextYAlignment.Top
	ScriptDescription.BackgroundTransparency = 1
	ScriptDescription.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	ScriptDescription.TextColor3 = theme.TitleTextColor
	ScriptDescription.RichText = true
	ScriptDescription.Size = UDim2.new(1.36294, 0, 0.41379, 0)
	ScriptDescription.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ScriptDescription.Text = "build 0.0.1 ver 1.0"
	ScriptDescription.LayoutOrder = 2
	ScriptDescription.AutomaticSize = Enum.AutomaticSize.XY
	ScriptDescription.Position = UDim2.new(0, 0, 0.58621, 0)
	ScriptDescription.Parent = ScriptInfoContainer

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
	if Settings.Description then
		ScriptDescription.Text = Settings.Description
	end
	if Settings.AnimationStyle then
		Window.AnimationStyle = Settings.AnimationStyle
	end
	if Settings.DragStyle then
		Window.DragStyle = Settings.DragStyle
	end

	----------------------------------------------------------------
	-- Object
	----------------------------------------------------------------
	self = setmetatable({}, Window)

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
	self.ScriptDescription = ScriptDescription
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

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						resizing = false
						updateResizeVisual()
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
		return Window.AnimationStyle == "Snappy" and "MinimizeSnappy" or "Minimize"
	end

	-- Roblox has no single "fade all descendants" property, so capture every
	-- transparency under a root (while it is natural) and tween as a group.
	-- NOTE: includes the root itself (GetDescendants excludes it), so the root
	-- Frame's own background fades too.
	local function captureFade(root)
		local cache = {}
		local list = { root }
		for _, d in ipairs(root:GetDescendants()) do
			list[#list + 1] = d
		end
		for _, d in ipairs(list) do
			-- Video fade handle: the UIGradient tagged by the Video component. This
			-- is what actually fades a playing video (VideoFrame.Transparency does
			-- not render), so we capture it as a special entry.
			if d:IsA("UIGradient") and d:GetAttribute("IsVideoFade") then
				cache[#cache + 1] = { instance = d, isVideo = true, base = VideoFade.get(d) }
			else
				local props = {}
				if d:IsA("GuiObject") then
					props[#props + 1] = { "BackgroundTransparency", d.BackgroundTransparency }
					local okT, vt = pcall(function() return d.TextTransparency end)
					if okT and type(vt) == "number" then props[#props + 1] = { "TextTransparency", vt } end
					local okI, vi = pcall(function() return d.ImageTransparency end)
					if okI and type(vi) == "number" then props[#props + 1] = { "ImageTransparency", vi } end
				end
				if d:IsA("UIStroke") or d:IsA("UIShadow") then
					props[#props + 1] = { "Transparency", d.Transparency }
				end
				if #props > 0 then
					cache[#cache + 1] = { instance = d, props = props }
				end
			end
		end
		return cache
	end

	-- Fade every entry in a cache to `target` (nil = each element's base).
	-- `onComplete` fires once EVERY tween in the group has finished, so callers
	-- can sequence off the real fade instead of guessing a duration.
	local function fadeGroup(cache, target, duration, onComplete)
		duration = duration or 0.3
		local pending = 0
		local fired = false
		local function finished()
			pending = pending - 1
			if pending <= 0 and not fired then
				fired = true
				if onComplete then onComplete() end
			end
		end
		for _, entry in ipairs(cache) do
			local inst = entry.instance
			if inst.Parent then
				if entry.isVideo then
					-- Fade the video's UIGradient (VideoFrame.Transparency doesn't render).
					local t = target == nil and entry.base or target
					pending = pending + 1
					-- Match the "Smooth" (Quad InOut) preset used for the rest of the UI.
					VideoFade.fade(inst, t, duration, "InOut", finished)
				else
					for _, prop in ipairs(entry.props) do
						local name, base = prop[1], prop[2]
						local t = target == nil and base or target
						pending = pending + 1
						local handle = Tween.Play(inst, "Smooth", { [name] = t })
						handle.Tween.Completed:Connect(finished)
					end
				end
			end
		end
		if pending == 0 and onComplete then onComplete() end
	end

	----------------------------------------------------------------
	-- Minimize pill (right-center of screen, offset from the edge)
	----------------------------------------------------------------
	-- CanvasGroup so GroupTransparency can dim the WHOLE pill (background +
	-- buttons + stroke) at rest in one property, and clear on hover.
	local pill = Instance.new("CanvasGroup")
	pill.Name = "MinimizePill"
	pill.AnchorPoint = Vector2.new(1, 0.5)
	pill.Position = UDim2.new(1, -12, 0.5, 0)
	pill.AutomaticSize = Enum.AutomaticSize.Y
	pill.Size = UDim2.new(0, 56, 0, 0)
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
	local pillLayout = Instance.new("UIListLayout")
	pillLayout.Padding = UDim.new(0, 8)
	pillLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pillLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pillLayout.Parent = pill

	local buildPill
	local minimizeWindow
	local restoreWindow
	local windowFadeCache
	local pillFadeCache
	local pillButtons = {}

	buildPill = function()
		-- Read the LIVE theme so the pill updates after a theme switch, not the
		-- construction-time theme captured in this closure.
		local t = self._theme or theme
		-- Keep the tooltip in sync with the active theme too.
		tooltip:SetTheme(t)
		-- Restyle + RESET the pill container's base transparencies. The restore
		-- fade sets the container (background/stroke/shadow) to transparency 1,
		-- and only the buttons get rebuilt here -- without this reset the container
		-- would stay invisible (notably the shadow) after a few minimize cycles.
		pill.BackgroundColor3 = t.PopupBackgroundColor or Color3.fromRGB(15, 15, 16)
		pill.BackgroundTransparency = 0.05
		pill.GroupTransparency = PILL_REST_GROUP
		pillStroke.Color = t.StrokeColor or Color3.fromRGB(255, 255, 255)
		pillStroke.Transparency = 0.7
		pillShadow.Color = t.PopupShadowColor or Color3.fromRGB(0, 0, 0)
		pillShadow.Transparency = 1 -- rest: hidden; hover sets 0.5
		for _, b in ipairs(pillButtons) do
			b:Destroy()
		end
		pillButtons = {}
		if not self.TabGroup then return end
		for i, tab in ipairs(self.TabGroup.Tabs) do
			local isActive = (tab == self.TabGroup.ActiveTab)
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
			if isActive then
				Tween.StartSpin(grad, { Rotation = 360 }, "SpinIdle")
			end
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
				tooltip:ShowAt(btn, tab.Name, "Left", 11)
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
				restoreWindow()
			end)
			table.insert(pillButtons, btn)
		end
	end

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
		-- Snapshot every page's base transparencies NOW, while all content is
		-- natural. After this the window fade can reveal ANY tab correctly, even
		-- one switched to while minimized.
		if self.TabGroup and self.TabGroup.PrimeCaches then
			self.TabGroup:PrimeCaches()
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
		windowFadeCache = captureFade(MainFrame)
		-- Hide + reveal the pill only AFTER the fade completes (event-driven, no
		-- guessed delay), so bright elements like the video finish fading first.
		fadeGroup(windowFadeCache, 1, 0.3, function()
			MainFrame.Visible = false
			pill.Visible = true
			pill.BackgroundTransparency = 0.05
			pill.GroupTransparency = 1
			pillScale.Scale = 0.7
			-- Pop in, settling at the REST (dim, small) state since it isn't hovered.
			Tween.Play(pill, "Fast", { GroupTransparency = PILL_REST_GROUP })
			Tween.Play(pillScale, "HoverIn", { Scale = PILL_REST_SCALE })
			-- Capture the pill's natural transparencies once it is fully shown,
			-- so restore can fade the whole thing out.
			task.delay(0.25, function()
				pillFadeCache = captureFade(pill)
			end)
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
		fadeGroup(windowFadeCache, nil, 0.3, function()
			-- Fade finished: re-apply tab-button visuals (the fade overwrote them
			-- with the pre-minimize values) and release the minimized state.
			self._windowFaded = false
			if self.TabGroup and self.TabGroup.RefreshVisuals then
				self.TabGroup:RefreshVisuals()
			end
			minimizeState = "shown"
		end)
		-- Fade the pill out in parallel, then hide it.
		if pillFadeCache then
			fadeGroup(pillFadeCache, 1)
		else
			Tween.Play(pill, "Fast", { BackgroundTransparency = 1 })
		end
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

		if tabListScrollbarTimer then
			task.cancel(tabListScrollbarTimer)
			tabListScrollbarTimer = nil
		end

		Tween.CancelAll(ScreenGui)
		for _, d in ipairs(ScreenGui:GetDescendants()) do
			Tween.CancelAll(d)
		end

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
	end

	local function doClose()
		-- Fade the whole window out, THEN tear everything down + destroy it.
		local cache = captureFade(MainFrame)
		fadeGroup(cache, 1)
		Sound.Play("UIShutdown")
		-- Unload keybind + input listeners immediately, so nothing responds
		-- while the window fades out and nothing survives the destroy.
		task.delay(0.4, function()
			self._teardown()
			self.Base:Destroy()
		end)
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
	if type(Settings.SettingsPages) == "table" then
		for _, page in ipairs(Settings.SettingsPages) do
			self.SettingsTabGroup:Tab({
				Name = page.Name or "Settings",
				Icon = page.Icon,
			})
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
	local introCache = captureFade(MainFrame)
	for _, entry in ipairs(introCache) do
		if entry.isVideo then
			if entry.instance.Parent then VideoFade.set(entry.instance, 1) end
		elseif entry.instance.Parent then
			for _, prop in ipairs(entry.props) do
				entry.instance[prop[1]] = 1
			end
		end
	end
	fadeGroup(introCache, nil, 0.35)

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

	-- Component-owned theming for the WINDOW SHELL. The window is the ROOT of
	-- the UI tree (self.Base = the ScreenGui), so it cannot self-register like
	-- components do - the registry iterates Base's DESCENDANTS, which excludes
	-- Base itself. ThemeManager therefore calls this explicitly for the root.
	-- Everything under Base still themes through the component registry.
	function self:ApplyTheme(newTheme)
		local t = ThemeManager.GetTheme(newTheme)
		self._theme = t

		-- Shell
		MainFrame.BackgroundColor3 = t.WindowColor or MainFrame.BackgroundColor3
		if t.WindowTransparency ~= nil then
			MainFrame.BackgroundTransparency = t.WindowTransparency
		end
		ContentBackground.BackgroundColor3 = t.ContentBackgroundColor or t.WindowColor or ContentBackground.BackgroundColor3
		local ct = t.ContentBackgroundTransparency
		if ct == nil then ct = t.WindowTransparency end
		if ct ~= nil then
			ContentBackground.BackgroundTransparency = ct
		end
		Sidebar.BackgroundColor3 = t.SidebarColor or Sidebar.BackgroundColor3
		if t.SidebarTransparency ~= nil then
			Sidebar.BackgroundTransparency = t.SidebarTransparency
		end
		MainFrameShadow.Color = t.MainframeShadowColor or MainFrameShadow.Color

		-- Window controls (close / maximize / minimize)
		for _, ctrl in ipairs({ MinimizeButton, MaximizeButton, CloseButton }) do
			if ctrl then
				ctrl.ImageColor3 = t.WindowControlColor or ctrl.ImageColor3
			end
		end

		-- Page title + its divider
		PageTitle.TextColor3 = t.TitleTextColor or PageTitle.TextColor3
		PageTitleDivider.BackgroundColor3 = t.TertiaryColor or PageTitleDivider.BackgroundColor3

		-- Search bar (honour the focus state so an unfocused bar stays clean)
		SearchBar.BackgroundColor3 = t.SearchBarBackgroundColor or SearchBar.BackgroundColor3
		local searchFocused = SearchBar:GetAttribute("IsSearchFocused")
		if searchFocused then
			SearchBar.BackgroundTransparency = t.SearchBarBackgroundTransparency or 0
			SearchBoxStroke.Transparency = t.StrokeTransparency or 0.95
		else
			SearchBar.BackgroundTransparency = 1
			SearchBoxStroke.Transparency = 1
		end
		SearchBox.TextColor3 = t.PrimaryTextColor or SearchBox.TextColor3
		SearchBox.TextTransparency = t.PrimaryTextTransparency or SearchBox.TextTransparency
		SearchIcon.ImageColor3 = t.SecondaryColor or SearchIcon.ImageColor3
		SearchBoxStroke.Color = t.StrokeColor or SearchBoxStroke.Color
		SearchBarBottomDivider.BackgroundColor3 = t.TertiaryColor or SearchBarBottomDivider.BackgroundColor3

		-- Sidebar divider + settings gear
		SidebarDivider.BackgroundColor3 = t.TertiaryColor or SidebarDivider.BackgroundColor3
		UserSettingsButton.ImageColor3 = t.AccentColor or UserSettingsButton.ImageColor3

		-- Script info + user info text
		ScriptName.TextColor3 = t.TitleTextColor or ScriptName.TextColor3
		ScriptDescription.TextColor3 = t.TitleTextColor or ScriptDescription.TextColor3
		Username.TextColor3 = t.TitleTextColor or Username.TextColor3
		DisplayName.TextColor3 = t.TitleTextColor or DisplayName.TextColor3
		TimeLabel.TextColor3 = t.TitleTextColor or TimeLabel.TextColor3

		-- Sidebar scrollbar
		TabList.ScrollBarImageColor3 = t.TertiaryColor or TabList.ScrollBarImageColor3

		-- Minimize pill
		pill.BackgroundColor3 = t.PopupBackgroundColor or pill.BackgroundColor3
		pillStroke.Color = t.StrokeColor or pillStroke.Color
		pillShadow.Color = t.PopupShadowColor or pillShadow.Color

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

function Window:SetDescription(text)
	self.ScriptDescription.Text = text
end

-- Apply a theme by name or table
function Window:SetTheme(themeInput)
	local ThemeManager = require("../Themes/ThemeManager")
	if type(themeInput) == "string" then
		self._themeName = themeInput
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

	-- Notification dialogs have no ApplyTheme; drop the cached one so the next
	-- open rebuilds it with the current theme.
	if self._notification then
		self._notification:Destroy()
		self._notification = nil
	end
end

function Window:Destroy()
	local closePreset = Window.AnimationStyle == "Snappy" and "FadeOut" or "Smooth"

	Sound.Play("WindowClose")

	if self._teardown then self._teardown() end

	local handle = Tween.Play(self.MainFrame, closePreset, { BackgroundTransparency = 1 })
	handle.Tween.Completed:Wait()

	Tween.CancelAll(self.MainFrame)
	self.Base:Destroy()
end

-- Tab management methods (delegated to TabGroup)
function Window:Tab(name, icon)
	return self.TabGroup:Tab({ Name = name, Icon = icon })
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

-- Toast notifications (self-destroying). window:Alert/Error/VariableNotification.
local Notification = require("../Popups/Notification")

local function spawnNotification(self, ntype, Settings)
	if type(Settings) ~= "table" then
		Settings = {}
	end
	Settings.Type = ntype
	local notification = Notification.new(self.Notifications, Settings, self._theme)
	notification:Show()
	return notification
end

function Window:Alert(Settings)
	return spawnNotification(self, "Alert", Settings)
end

function Window:Error(Settings)
	return spawnNotification(self, "Error", Settings)
end

function Window:VariableNotification(Settings)
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
