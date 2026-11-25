--[[
	Aetheris/Popups/ThemePreviewPopUp.luau

	Interactive live miniature window preview showing theme preferences on dummy UI components.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

--# selene: allow(undefined_variable)

local Tween = require("../Utils/Tween")
local Constants = require("../Constants")
local Icons = require("../Assets/Icons")
local UUID = require("../Utils/UUID")
local WallpaperManager = require("../Utils/WallpaperManager")

local ThemePreviewPopUp = {}
local TILE = 28
local CORNER = 12

local function ramp(points)
	local keypoints = {}
	for _, point in ipairs(points) do
		table.insert(keypoints, NumberSequenceKeypoint.new(point[1], point[2]))
	end
	return NumberSequence.new(keypoints)
end

function ThemePreviewPopUp.new(parent, window)
	local self = setmetatable({}, { __index = ThemePreviewPopUp })
	self._parent = parent
	self._window = window
	self._open = false
	self._theme = {}

	local outside = Instance.new("TextButton")
	outside.Name = UUID.Generate("ThemePreviewOutside")
	outside.Text = ""
	outside.BackgroundTransparency = 1
	outside.BorderSizePixel = 0
	outside.Size = UDim2.fromScale(1, 1)
	outside.ZIndex = 1200
	outside.Visible = false
	outside.Parent = parent
	self._outside = outside

	local shell = Instance.new("CanvasGroup")
	shell.Name = UUID.Generate("ThemePreviewShell")
	shell.BorderSizePixel = 0
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.5)
	shell.Size = UDim2.fromOffset(460, 310)
	shell.ZIndex = 1201
	shell.Visible = false
	shell.GroupTransparency = 1
	shell.Parent = parent
	self._shell = shell

	local shellCorner = Instance.new("UICorner")
	shellCorner.CornerRadius = UDim.new(0, CORNER)
	shellCorner.Parent = shell

	local shellShadow = Instance.new("UIShadow")
	shellShadow.BlurRadius = UDim.new(0, 24)
	shellShadow.Color = Color3.fromRGB(0, 0, 0)
	shellShadow.Transparency = 0.45
	shellShadow.Parent = shell

	-- Header bar
	local head = Instance.new("Frame")
	head.Name = UUID.Static("PreviewHead")
	head.BorderSizePixel = 0
	head.BackgroundTransparency = 1
	head.Size = UDim2.new(1, 0, 0, 42)
	head.Position = UDim2.fromOffset(0, 0)
	head.Parent = shell

	local headTile = Instance.new("Frame")
	headTile.Name = UUID.Static("HeadTile")
	headTile.BorderSizePixel = 0
	headTile.Size = UDim2.fromOffset(TILE, TILE)
	headTile.Position = UDim2.fromOffset(14, 7)
	headTile.Parent = head

	local headTileCorner = Instance.new("UICorner")
	headTileCorner.CornerRadius = UDim.new(0, 8)
	headTileCorner.Parent = headTile

	local headGlyph = Instance.new("ImageLabel")
	headGlyph.Name = UUID.Static("HeadGlyph")
	headGlyph.BorderSizePixel = 0
	headGlyph.BackgroundTransparency = 1
	headGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
	headGlyph.Position = UDim2.fromScale(0.5, 0.5)
	headGlyph.Size = UDim2.fromOffset(16, 16)
	headGlyph.Image = Icons["eye"] or "rbxassetid://8445470392"
	headGlyph.Parent = headTile

	local headTitle = Instance.new("TextLabel")
	headTitle.Name = UUID.Static("HeadTitle")
	headTitle.BorderSizePixel = 0
	headTitle.BackgroundTransparency = 1
	headTitle.FontFace = Constants.Font(Enum.FontWeight.Bold)
	headTitle.TextSize = 14
	headTitle.TextXAlignment = Enum.TextXAlignment.Left
	headTitle.Text = "Live Theme Preview"
	headTitle.Position = UDim2.fromOffset(50, 7)
	headTitle.Size = UDim2.new(1, -95, 0, TILE)
	headTitle.Parent = head

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = UUID.Static("CloseBtn")
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = ""
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -12, 0.5, 0)
	closeBtn.Size = UDim2.fromOffset(26, 26)
	closeBtn.Parent = head

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeBtn

	local closeIcon = Instance.new("ImageLabel")
	closeIcon.BorderSizePixel = 0
	closeIcon.BackgroundTransparency = 1
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.Position = UDim2.fromScale(0.5, 0.5)
	closeIcon.Size = UDim2.fromOffset(14, 14)
	closeIcon.Image = Icons["x"]
	closeIcon.Parent = closeBtn

	-- Mini window container
	local miniWindow = Instance.new("Frame")
	miniWindow.Name = UUID.Static("MiniWindow")
	miniWindow.BorderSizePixel = 0
	miniWindow.Position = UDim2.fromOffset(12, 44)
	miniWindow.Size = UDim2.new(1, -24, 1, -56)
	miniWindow.Parent = shell

	local miniCorner = Instance.new("UICorner")
	miniCorner.CornerRadius = UDim.new(0, 10)
	miniCorner.Parent = miniWindow

	-- Mini Sidebar
	local miniSidebar = Instance.new("Frame")
	miniSidebar.Name = UUID.Static("MiniSidebar")
	miniSidebar.BorderSizePixel = 0
	miniSidebar.Size = UDim2.new(0, 42, 1, 0)
	miniSidebar.Position = UDim2.fromOffset(0, 0)
	miniSidebar.Parent = miniWindow

	local sidebarCorner = Instance.new("UICorner")
	sidebarCorner.CornerRadius = UDim.new(0, 10)
	sidebarCorner.Parent = miniSidebar

	local miniTabs = {}
	for i = 1, 3 do
		local tab = Instance.new("Frame")
		tab.Name = UUID.Generate("MiniTab")
		tab.BorderSizePixel = 0
		tab.AnchorPoint = Vector2.new(0.5, 0)
		tab.Position = UDim2.new(0.5, 0, 0, 12 + (i - 1) * 32)
		tab.Size = UDim2.fromOffset(26, 26)
		tab.Parent = miniSidebar

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(1, 0)
		tabCorner.Parent = tab

		local tabDot = Instance.new("Frame")
		tabDot.BorderSizePixel = 0
		tabDot.AnchorPoint = Vector2.new(0.5, 0.5)
		tabDot.Position = UDim2.fromScale(0.5, 0.5)
		tabDot.Size = UDim2.fromOffset(10, 10)
		tabDot.Parent = tab

		local tabDotCorner = Instance.new("UICorner")
		tabDotCorner.CornerRadius = UDim.new(1, 0)
		tabDotCorner.Parent = tabDot

		table.insert(miniTabs, { tab = tab, dot = tabDot, active = (i == 1) })
	end

	-- Content Area
	local miniContent = Instance.new("Frame")
	miniContent.Name = UUID.Static("MiniContent")
	miniContent.BorderSizePixel = 0
	miniContent.Position = UDim2.fromOffset(44, 0)
	miniContent.Size = UDim2.new(1, -44, 1, 0)
	miniContent.Parent = miniWindow

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 10)
	contentCorner.Parent = miniContent

	-- Wallpaper layer
	local miniWallpaper = Instance.new("ImageLabel")
	miniWallpaper.Name = UUID.Static("MiniWallpaper")
	miniWallpaper.BorderSizePixel = 0
	miniWallpaper.BackgroundTransparency = 1
	miniWallpaper.Size = UDim2.fromScale(1, 1)
	miniWallpaper.ScaleType = Enum.ScaleType.Crop
	miniWallpaper.Parent = miniContent

	local wallpaperCorner = Instance.new("UICorner")
	wallpaperCorner.CornerRadius = UDim.new(0, 10)
	wallpaperCorner.Parent = miniWallpaper

	local melt = Instance.new("UIGradient")
	melt.Rotation = 90
	melt.Transparency = ramp({ { 0, 0.1 }, { 0.4, 0.4 }, { 0.7, 0.8 }, { 1, 1 } })
	melt.Parent = miniWallpaper

	-- Cards container
	local cardList = Instance.new("Frame")
	cardList.BorderSizePixel = 0
	cardList.BackgroundTransparency = 1
	cardList.Position = UDim2.fromOffset(10, 10)
	cardList.Size = UDim2.new(1, -20, 1, -20)
	cardList.Parent = miniContent

	local cardLayout = Instance.new("UIListLayout")
	cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardLayout.Padding = UDim.new(0, 8)
	cardLayout.Parent = cardList

	-- Mini Card 1: Stat Hero
	local card1 = Instance.new("Frame")
	card1.BorderSizePixel = 0
	card1.Size = UDim2.new(1, 0, 0, 50)
	card1.LayoutOrder = 1
	card1.Parent = cardList

	local c1Corner = Instance.new("UICorner")
	c1Corner.CornerRadius = UDim.new(0, 8)
	c1Corner.Parent = card1

	local c1AccentBar = Instance.new("Frame")
	c1AccentBar.BorderSizePixel = 0
	c1AccentBar.Position = UDim2.fromOffset(8, 10)
	c1AccentBar.Size = UDim2.fromOffset(3, 30)
	c1AccentBar.Parent = card1

	local c1BarCorner = Instance.new("UICorner")
	c1BarCorner.CornerRadius = UDim.new(1, 0)
	c1BarCorner.Parent = c1AccentBar

	local c1Line1 = Instance.new("Frame")
	c1Line1.BorderSizePixel = 0
	c1Line1.Position = UDim2.fromOffset(18, 14)
	c1Line1.Size = UDim2.fromOffset(110, 8)
	c1Line1.Parent = card1

	local c1L1Corner = Instance.new("UICorner")
	c1L1Corner.CornerRadius = UDim.new(0, 4)
	c1L1Corner.Parent = c1Line1

	local c1Line2 = Instance.new("Frame")
	c1Line2.BorderSizePixel = 0
	c1Line2.Position = UDim2.fromOffset(18, 28)
	c1Line2.Size = UDim2.fromOffset(70, 6)
	c1Line2.Parent = card1

	local c1L2Corner = Instance.new("UICorner")
	c1L2Corner.CornerRadius = UDim.new(0, 3)
	c1L2Corner.Parent = c1Line2

	local c1Chip = Instance.new("Frame")
	c1Chip.BorderSizePixel = 0
	c1Chip.AnchorPoint = Vector2.new(1, 0.5)
	c1Chip.Position = UDim2.new(1, -12, 0.5, 0)
	c1Chip.Size = UDim2.fromOffset(45, 18)
	c1Chip.Parent = card1

	local c1ChipCorner = Instance.new("UICorner")
	c1ChipCorner.CornerRadius = UDim.new(1, 0)
	c1ChipCorner.Parent = c1Chip

	local c1ChipDot = Instance.new("Frame")
	c1ChipDot.BorderSizePixel = 0
	c1ChipDot.AnchorPoint = Vector2.new(0.5, 0.5)
	c1ChipDot.Position = UDim2.fromScale(0.5, 0.5)
	c1ChipDot.Size = UDim2.fromOffset(20, 6)
	c1ChipDot.Parent = c1Chip

	local c1DotCorner = Instance.new("UICorner")
	c1DotCorner.CornerRadius = UDim.new(1, 0)
	c1DotCorner.Parent = c1ChipDot

	-- Mini Card 2: Interactive Controls
	local card2 = Instance.new("Frame")
	card2.BorderSizePixel = 0
	card2.Size = UDim2.new(1, 0, 0, 116)
	card2.LayoutOrder = 2
	card2.Parent = cardList

	local c2Corner = Instance.new("UICorner")
	c2Corner.CornerRadius = UDim.new(0, 8)
	c2Corner.Parent = card2

	-- Toggle row
	local tRow = Instance.new("Frame")
	tRow.BorderSizePixel = 0
	tRow.BackgroundTransparency = 1
	tRow.Position = UDim2.fromOffset(10, 8)
	tRow.Size = UDim2.new(1, -20, 0, 20)
	tRow.Parent = card2

	local tLine = Instance.new("Frame")
	tLine.BorderSizePixel = 0
	tLine.AnchorPoint = Vector2.new(0, 0.5)
	tLine.Position = UDim2.fromScale(0, 0.5)
	tLine.Size = UDim2.fromOffset(100, 6)
	tLine.Parent = tRow

	local tLineCorner = Instance.new("UICorner")
	tLineCorner.CornerRadius = UDim.new(0, 3)
	tLineCorner.Parent = tLine

	local tTrack = Instance.new("Frame")
	tTrack.BorderSizePixel = 0
	tTrack.AnchorPoint = Vector2.new(1, 0.5)
	tTrack.Position = UDim2.fromScale(1, 0.5)
	tTrack.Size = UDim2.fromOffset(28, 14)
	tTrack.Parent = tRow

	local tTrackCorner = Instance.new("UICorner")
	tTrackCorner.CornerRadius = UDim.new(1, 0)
	tTrackCorner.Parent = tTrack

	local tThumb = Instance.new("Frame")
	tThumb.BorderSizePixel = 0
	tThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	tThumb.AnchorPoint = Vector2.new(1, 0.5)
	tThumb.Position = UDim2.new(1, -2, 0.5, 0)
	tThumb.Size = UDim2.fromOffset(10, 10)
	tThumb.Parent = tTrack

	local tThumbCorner = Instance.new("UICorner")
	tThumbCorner.CornerRadius = UDim.new(1, 0)
	tThumbCorner.Parent = tThumb

	-- Slider row
	local sRow = Instance.new("Frame")
	sRow.BorderSizePixel = 0
	sRow.BackgroundTransparency = 1
	sRow.Position = UDim2.fromOffset(10, 36)
	sRow.Size = UDim2.new(1, -20, 0, 26)
	sRow.Parent = card2

	local sLine = Instance.new("Frame")
	sLine.BorderSizePixel = 0
	sLine.Position = UDim2.fromOffset(0, 0)
	sLine.Size = UDim2.fromOffset(80, 6)
	sLine.Parent = sRow

	local sLineCorner = Instance.new("UICorner")
	sLineCorner.CornerRadius = UDim.new(0, 3)
	sLineCorner.Parent = sLine

	local sRail = Instance.new("Frame")
	sRail.BorderSizePixel = 0
	sRail.Position = UDim2.fromOffset(0, 14)
	sRail.Size = UDim2.new(1, 0, 0, 5)
	sRail.Parent = sRow

	local sRailCorner = Instance.new("UICorner")
	sRailCorner.CornerRadius = UDim.new(1, 0)
	sRailCorner.Parent = sRail

	local sFill = Instance.new("Frame")
	sFill.BorderSizePixel = 0
	sFill.Size = UDim2.fromScale(0.65, 1)
	sFill.Parent = sRail

	local sFillCorner = Instance.new("UICorner")
	sFillCorner.CornerRadius = UDim.new(1, 0)
	sFillCorner.Parent = sFill

	local sKnob = Instance.new("Frame")
	sKnob.BorderSizePixel = 0
	sKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	sKnob.Position = UDim2.fromScale(1, 0.5)
	sKnob.Size = UDim2.fromOffset(10, 10)
	sKnob.Parent = sFill

	local sKnobCorner = Instance.new("UICorner")
	sKnobCorner.CornerRadius = UDim.new(1, 0)
	sKnobCorner.Parent = sKnob

	-- Button & Well row
	local bRow = Instance.new("Frame")
	bRow.BorderSizePixel = 0
	bRow.BackgroundTransparency = 1
	bRow.Position = UDim2.fromOffset(10, 72)
	bRow.Size = UDim2.new(1, -20, 0, 28)
	bRow.Parent = card2

	local mBtn = Instance.new("Frame")
	mBtn.BorderSizePixel = 0
	mBtn.Size = UDim2.fromOffset(80, 24)
	mBtn.Parent = bRow

	local mBtnCorner = Instance.new("UICorner")
	mBtnCorner.CornerRadius = UDim.new(0, 6)
	mBtnCorner.Parent = mBtn

	local mBtnPill = Instance.new("Frame")
	mBtnPill.BorderSizePixel = 0
	mBtnPill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	mBtnPill.AnchorPoint = Vector2.new(0.5, 0.5)
	mBtnPill.Position = UDim2.fromScale(0.5, 0.5)
	mBtnPill.Size = UDim2.fromOffset(40, 6)
	mBtnPill.Parent = mBtn

	local mPillCorner = Instance.new("UICorner")
	mPillCorner.CornerRadius = UDim.new(1, 0)
	mPillCorner.Parent = mBtnPill

	local mWell = Instance.new("Frame")
	mWell.BorderSizePixel = 0
	mWell.AnchorPoint = Vector2.new(1, 0)
	mWell.Position = UDim2.fromScale(1, 0)
	mWell.Size = UDim2.new(1, -95, 0, 24)
	mWell.Parent = bRow

	local mWellCorner = Instance.new("UICorner")
	mWellCorner.CornerRadius = UDim.new(0, 6)
	mWellCorner.Parent = mWell

	local mWellLine = Instance.new("Frame")
	mWellLine.BorderSizePixel = 0
	mWellLine.AnchorPoint = Vector2.new(0, 0.5)
	mWellLine.Position = UDim2.new(0, 8, 0.5, 0)
	mWellLine.Size = UDim2.fromOffset(60, 6)
	mWellLine.Parent = mWell

	local mWellLineCorner = Instance.new("UICorner")
	mWellLineCorner.CornerRadius = UDim.new(0, 3)
	mWellLineCorner.Parent = mWellLine

	self._elements = {
		shell = shell,
		head = head,
		headTile = headTile,
		headGlyph = headGlyph,
		headTitle = headTitle,
		closeBtn = closeBtn,
		closeIcon = closeIcon,
		miniWindow = miniWindow,
		miniSidebar = miniSidebar,
		miniTabs = miniTabs,
		miniContent = miniContent,
		miniWallpaper = miniWallpaper,
		card1 = card1,
		c1AccentBar = c1AccentBar,
		c1Line1 = c1Line1,
		c1Line2 = c1Line2,
		c1Chip = c1Chip,
		c1ChipDot = c1ChipDot,
		card2 = card2,
		tLine = tLine,
		tTrack = tTrack,
		tThumb = tThumb,
		sLine = sLine,
		sRail = sRail,
		sFill = sFill,
		mBtn = mBtn,
		mBtnPill = mBtnPill,
		mWell = mWell,
		mWellLine = mWellLine,
	}

	local function dismiss()
		self:Dismiss()
	end
	outside.MouseButton1Click:Connect(dismiss)
	closeBtn.MouseButton1Click:Connect(dismiss)

	return self
end

function ThemePreviewPopUp:UpdateTheme(t)
	self._theme = t or {}
	local el = self._elements
	if not el then
		return
	end

	local accent = t.AccentColor or Color3.fromRGB(120, 156, 210)
	local primary = t.PrimaryColor or accent
	local windowBg = t.WindowColor or Color3.fromRGB(18, 18, 20)
	local contentBg = t.ContentBackgroundColor or Color3.fromRGB(24, 24, 28)
	local compBg = t.ComponentBackgroundColor or Color3.fromRGB(32, 32, 38)
	local inputBg = t.InputBackgroundColor or Color3.fromRGB(40, 40, 46)
	local text = t.TitleTextColor or t.PrimaryTextColor or Color3.fromRGB(240, 240, 245)
	local subText = t.SecondaryTextColor or Color3.fromRGB(160, 160, 170)
	local popupBg = t.PopupBackgroundColor or Color3.fromRGB(22, 22, 26)

	el.shell.BackgroundColor3 = popupBg
	el.headTitle.TextColor3 = text
	el.headTile.BackgroundColor3 = accent
	el.headGlyph.ImageColor3 = Color3.fromRGB(255, 255, 255)

	el.closeBtn.BackgroundColor3 = inputBg
	el.closeIcon.ImageColor3 = subText

	el.miniWindow.BackgroundColor3 = windowBg
	el.miniSidebar.BackgroundColor3 = t.SidebarBackgroundColor or windowBg
	el.miniContent.BackgroundColor3 = contentBg

	for _, tabItem in ipairs(el.miniTabs) do
		if tabItem.active then
			tabItem.tab.BackgroundColor3 = t.ActiveTabButtonColor or primary
			tabItem.tab.BackgroundTransparency = 0
			tabItem.dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			tabItem.dot.BackgroundTransparency = 0
		else
			tabItem.tab.BackgroundColor3 = compBg
			tabItem.tab.BackgroundTransparency = 0.5
			tabItem.dot.BackgroundColor3 = subText
			tabItem.dot.BackgroundTransparency = 0.5
		end
	end

	local wp = t.Wallpaper or t.Name
	el.miniWallpaper.Image = WallpaperManager.GetAsset(wp, function(resolved)
		if el.miniWallpaper and el.miniWallpaper.Parent then
			el.miniWallpaper.Image = resolved
		end
	end)
	el.miniWallpaper.ImageTransparency = t.WallpaperTransparency or 0.82

	el.card1.BackgroundColor3 = compBg
	el.c1AccentBar.BackgroundColor3 = accent
	el.c1Line1.BackgroundColor3 = text
	el.c1Line2.BackgroundColor3 = subText
	el.c1Chip.BackgroundColor3 = accent
	el.c1Chip.BackgroundTransparency = 0.8
	el.c1ChipDot.BackgroundColor3 = accent

	el.card2.BackgroundColor3 = compBg
	el.tLine.BackgroundColor3 = text
	el.tTrack.BackgroundColor3 = accent
	el.sLine.BackgroundColor3 = text
	el.sRail.BackgroundColor3 = inputBg
	el.sFill.BackgroundColor3 = accent
	el.mBtn.BackgroundColor3 = primary
	el.mWell.BackgroundColor3 = inputBg
	el.mWellLine.BackgroundColor3 = subText
end

function ThemePreviewPopUp:Open(themeData)
	if self._open then
		if themeData then
			self:UpdateTheme(themeData)
		end
		return
	end
	self._open = true
	if self._window and self._window._claimPopup then
		self._window:_claimPopup(self)
	end
	self:UpdateTheme(themeData)

	self._outside.Visible = true
	self._shell.Visible = true
	self._shell.GroupTransparency = 1
	self._shell.Position = UDim2.new(0.5, 0, 0.5, 14)

	Tween.Play(self._shell, "Enter", {
		GroupTransparency = 0,
		Position = UDim2.fromScale(0.5, 0.5),
	})
end

function ThemePreviewPopUp:Close()
	if not self._open then
		return
	end
	self._open = false
	if self._window and self._window._activePopUp == self then
		self._window._activePopUp = nil
	end
	self._outside.Visible = false

	Tween.Play(self._shell, "Exit", {
		GroupTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 14),
	})
	task.delay(0.3, function()
		if not self._open and self._shell then
			self._shell.Visible = false
		end
	end)
end

function ThemePreviewPopUp:Dismiss()
	self:Close()
end

function ThemePreviewPopUp:IsOpen()
	return self._open
end

function ThemePreviewPopUp:Destroy()
	if self._shell then
		self._shell:Destroy()
		self._shell = nil
	end
	if self._outside then
		self._outside:Destroy()
		self._outside = nil
	end
	self._elements = nil
end

return ThemePreviewPopUp
