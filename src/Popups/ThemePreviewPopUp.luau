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

local CORNER = 14
local SHELL_W, SHELL_H = 580, 400
local SIDEBAR_W = 138
local WHITE = Color3.new(1, 1, 1)

-- Close button hover, matching the changelog's icon timing.
local ICON_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ICON_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_ICON = Icons["circle-x"] or "rbxassetid://76821953846248"

local function ramp(points)
	local keypoints = {}
	for _, point in ipairs(points) do
		table.insert(keypoints, NumberSequenceKeypoint.new(point[1], point[2]))
	end
	return NumberSequence.new(keypoints)
end

local function addCorner(inst, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = inst
	return corner
end

local function addStroke(inst, color, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = inst
	return stroke
end

local function makeLabel(parent, name, text, position, size, textSize, weight, color)
	local label = Instance.new("TextLabel")
	label.Name = UUID.Static(name)
	label.BorderSizePixel = 0
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.FontFace = Constants.Font(weight or Enum.FontWeight.Medium)
	label.TextColor3 = color or WHITE
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Position = position
	label.Size = size
	label.Parent = parent
	return label
end

local function makeFrame(parent, name, position, size)
	local frame = Instance.new("Frame")
	frame.Name = UUID.Static(name)
	frame.BorderSizePixel = 0
	frame.Position = position
	frame.Size = size
	frame.Parent = parent
	return frame
end

local function makeIcon(parent, name, image, position, size)
	local icon = Instance.new("ImageLabel")
	icon.Name = UUID.Static(name)
	icon.BorderSizePixel = 0
	icon.BackgroundTransparency = 1
	icon.Image = image
	icon.ImageColor3 = WHITE
	icon.Position = position
	icon.Size = size
	icon.Parent = parent
	return icon
end

function ThemePreviewPopUp.new(parent, window)
	local self = setmetatable({}, { __index = ThemePreviewPopUp })
	self._parent = parent
	self._window = window
	self._open = false
	self._theme = {}

	local el = {}
	self._elements = el

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

	-- Shell
	local shell = Instance.new("CanvasGroup")
	shell.Name = UUID.Generate("ThemePreviewShell")
	shell.BorderSizePixel = 0
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.5)
	shell.Size = UDim2.fromOffset(SHELL_W, SHELL_H)
	shell.ZIndex = 1201
	shell.Visible = false
	shell.GroupTransparency = 1
	shell.Parent = parent
	self._shell = shell
	el.shell = shell

	addCorner(shell, CORNER)

	local shellShadow = Instance.new("UIShadow")
	shellShadow.BlurRadius = UDim.new(0, 28)
	shellShadow.Color = Color3.fromRGB(0, 0, 0)
	shellShadow.Transparency = 0.4
	shellShadow.Parent = shell

	-- Header row, styled like the other popup shells.
	local headTile = makeFrame(shell, "PreviewHeadTile", UDim2.fromOffset(16, 13), UDim2.fromOffset(30, 30))
	addCorner(headTile, 10)
	el.headTile = headTile

	local headGlyph = makeIcon(
		headTile,
		"PreviewHeadGlyph",
		Icons["palette"] or Icons["paintbrush"],
		UDim2.fromScale(0.5, 0.5),
		UDim2.fromOffset(16, 16)
	)
	headGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
	el.headGlyph = headGlyph

	local headTitle = makeLabel(
		shell,
		"PreviewHeadTitle",
		"Theme Preview",
		UDim2.fromOffset(56, 10),
		UDim2.new(1, -140, 0, 18),
		14,
		Enum.FontWeight.SemiBold,
		WHITE
	)
	el.headTitle = headTitle

	local headSubtitle = makeLabel(
		shell,
		"PreviewHeadSubtitle",
		"Live preview of the draft theme",
		UDim2.fromOffset(56, 28),
		UDim2.new(1, -140, 0, 14),
		10,
		Enum.FontWeight.Medium,
		WHITE
	)
	headSubtitle.TextTransparency = 0.25
	el.headSubtitle = headSubtitle

	local closeBtn = Instance.new("ImageButton")
	closeBtn.Name = UUID.Static("PreviewClose")
	closeBtn.BorderSizePixel = 0
	closeBtn.BackgroundColor3 = WHITE
	closeBtn.BackgroundTransparency = 0.92
	closeBtn.AutoButtonColor = false
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -16, 0, 14)
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.Parent = shell
	addCorner(closeBtn, 14)
	el.closeBtn = closeBtn

	local closeIcon =
		makeIcon(closeBtn, "PreviewCloseIcon", CLOSE_ICON, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(16, 16))
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.ImageTransparency = 0.35
	el.closeIcon = closeIcon

	closeBtn.MouseEnter:Connect(function()
		Tween.Play(closeBtn, ICON_IN, { BackgroundTransparency = 0.86 })
		Tween.Play(closeIcon, ICON_IN, { ImageTransparency = 0 })
	end)
	closeBtn.MouseLeave:Connect(function()
		Tween.Play(closeBtn, ICON_OUT, { BackgroundTransparency = 0.92 })
		Tween.Play(closeIcon, ICON_OUT, { ImageTransparency = 0.35 })
	end)

	-- Mini Aetheris window
	local miniWindow = makeFrame(shell, "MiniWindow", UDim2.fromOffset(16, 56), UDim2.new(1, -32, 1, -72))
	addCorner(miniWindow, 12)
	local miniStroke = addStroke(miniWindow, WHITE, 0.92)
	el.miniWindow = miniWindow
	el.miniStroke = miniStroke

	local miniGlow = Instance.new("UIShadow")
	miniGlow.BlurRadius = UDim.new(0, 18)
	miniGlow.Color = WHITE
	miniGlow.Transparency = 0.7
	miniGlow.Parent = miniWindow
	el.miniGlow = miniGlow

	-- Sidebar
	local sidebar = makeFrame(miniWindow, "MiniSidebar", UDim2.fromOffset(0, 0), UDim2.new(0, SIDEBAR_W, 1, 0))
	addCorner(sidebar, 12)
	el.sidebar = sidebar

	local logo = makeFrame(sidebar, "MiniLogo", UDim2.fromOffset(12, 12), UDim2.fromOffset(24, 24))
	addCorner(logo, 7)
	el.logo = logo

	local logoText = makeLabel(
		logo,
		"MiniLogoText",
		"A",
		UDim2.fromScale(0, 0),
		UDim2.fromScale(1, 1),
		13,
		Enum.FontWeight.Bold,
		WHITE
	)
	logoText.TextXAlignment = Enum.TextXAlignment.Center
	el.logoText = logoText

	local appTitle = makeLabel(
		sidebar,
		"MiniAppTitle",
		"Aetheris",
		UDim2.fromOffset(44, 11),
		UDim2.new(1, -56, 0, 14),
		12,
		Enum.FontWeight.Bold,
		WHITE
	)
	el.appTitle = appTitle

	local chips = {}
	local chipDefs = {
		{ text = "v1.7", key = "primary", width = 24 },
		{ text = "Build", key = "secondary", width = 26 },
		{ text = "DEMO", key = "accent", width = 28 },
	}
	local chipX = 44
	for i, def in ipairs(chipDefs) do
		local chip = makeFrame(sidebar, "MiniChip" .. i, UDim2.fromOffset(chipX, 29), UDim2.fromOffset(def.width, 11))
		addCorner(chip, 5)
		local chipText = makeLabel(
			chip,
			"MiniChipText" .. i,
			def.text,
			UDim2.fromScale(0, 0),
			UDim2.fromScale(1, 1),
			7,
			Enum.FontWeight.Bold,
			WHITE
		)
		chipText.TextXAlignment = Enum.TextXAlignment.Center
		chips[i] = { frame = chip, label = chipText, key = def.key }
		chipX += def.width + 3
	end
	el.chips = chips

	local searchBox = makeFrame(sidebar, "MiniSearch", UDim2.fromOffset(12, 50), UDim2.new(1, -24, 0, 20))
	addCorner(searchBox, 6)
	el.searchBox = searchBox

	local searchIcon =
		makeIcon(searchBox, "MiniSearchIcon", Icons["search"], UDim2.fromOffset(7, 5), UDim2.fromOffset(10, 10))
	el.searchIcon = searchIcon

	local searchText = makeLabel(
		searchBox,
		"MiniSearchText",
		"Search...",
		UDim2.fromOffset(21, 0),
		UDim2.new(1, -28, 1, 0),
		8,
		Enum.FontWeight.Medium,
		WHITE
	)
	searchText.TextTransparency = 0.35
	el.searchText = searchText

	local navDefs = {
		{ text = "Home", icon = Icons["house"], active = true },
		{ text = "Controls", icon = Icons["sliders-horizontal"], active = false },
		{ text = "Inputs", icon = Icons["text-cursor"], active = false },
		{ text = "Feedback", icon = Icons["bell"], active = false },
		{ text = "Media", icon = Icons["play"], active = false },
	}
	local navRows = {}
	for i, def in ipairs(navDefs) do
		local row =
			makeFrame(sidebar, "MiniNav" .. i, UDim2.fromOffset(12, 80 + (i - 1) * 25), UDim2.new(1, -24, 0, 22))
		addCorner(row, 6)
		local icon = makeIcon(row, "MiniNavIcon" .. i, def.icon, UDim2.fromOffset(7, 5), UDim2.fromOffset(12, 12))
		local label = makeLabel(
			row,
			"MiniNavText" .. i,
			def.text,
			UDim2.fromOffset(25, 0),
			UDim2.new(1, -33, 1, 0),
			9,
			Enum.FontWeight.Medium,
			WHITE
		)
		navRows[i] = { row = row, icon = icon, label = label, active = def.active }
	end
	el.navRows = navRows

	local divider = makeFrame(sidebar, "MiniDivider", UDim2.new(0, 12, 1, -38), UDim2.new(1, -24, 0, 1))
	el.divider = divider

	local avatar = makeFrame(sidebar, "MiniAvatar", UDim2.new(0, 12, 1, -28), UDim2.fromOffset(20, 20))
	addCorner(avatar, 6)
	el.avatar = avatar

	local avatarIcon =
		makeIcon(avatar, "MiniAvatarIcon", Icons["user"], UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(11, 11))
	avatarIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	el.avatarIcon = avatarIcon

	local userName = makeLabel(
		sidebar,
		"MiniUserName",
		"Rosenstein",
		UDim2.new(0, 38, 1, -29),
		UDim2.new(1, -62, 0, 11),
		8,
		Enum.FontWeight.Bold,
		WHITE
	)
	el.userName = userName

	local userHandle = makeLabel(
		sidebar,
		"MiniUserHandle",
		"@B1EVA",
		UDim2.new(0, 38, 1, -18),
		UDim2.new(1, -62, 0, 10),
		7,
		Enum.FontWeight.Medium,
		WHITE
	)
	userHandle.TextTransparency = 0.25
	el.userHandle = userHandle

	local userNum1 = makeLabel(
		sidebar,
		"MiniUserNum1",
		"09",
		UDim2.new(1, -22, 1, -29),
		UDim2.fromOffset(12, 11),
		7,
		Enum.FontWeight.SemiBold,
		WHITE
	)
	userNum1.TextXAlignment = Enum.TextXAlignment.Right
	el.userNum1 = userNum1

	local userNum2 = makeLabel(
		sidebar,
		"MiniUserNum2",
		"28",
		UDim2.new(1, -22, 1, -18),
		UDim2.fromOffset(12, 10),
		7,
		Enum.FontWeight.SemiBold,
		WHITE
	)
	userNum2.TextXAlignment = Enum.TextXAlignment.Right
	el.userNum2 = userNum2

	-- Content pane
	local content = makeFrame(miniWindow, "MiniContent", UDim2.fromOffset(SIDEBAR_W, 0), UDim2.new(1, -SIDEBAR_W, 1, 0))
	addCorner(content, 12)
	el.content = content

	local miniWallpaper = Instance.new("ImageLabel")
	miniWallpaper.Name = UUID.Static("MiniWallpaper")
	miniWallpaper.BorderSizePixel = 0
	miniWallpaper.BackgroundTransparency = 1
	miniWallpaper.Size = UDim2.fromScale(1, 1)
	miniWallpaper.ScaleType = Enum.ScaleType.Crop
	miniWallpaper.Parent = content
	addCorner(miniWallpaper, 12)
	el.miniWallpaper = miniWallpaper

	local melt = Instance.new("UIGradient")
	melt.Rotation = 90
	melt.Transparency = ramp({ { 0, 0.05 }, { 0.35, 0.25 }, { 0.7, 0.7 }, { 1, 1 } })
	melt.Parent = miniWallpaper

	local pageTitle = makeLabel(
		content,
		"MiniPageTitle",
		"Home",
		UDim2.fromOffset(16, 12),
		UDim2.fromOffset(120, 16),
		13,
		Enum.FontWeight.Bold,
		WHITE
	)
	el.pageTitle = pageTitle

	local pageUnderline = makeFrame(content, "MiniPageUnderline", UDim2.fromOffset(16, 31), UDim2.fromOffset(22, 2))
	addCorner(pageUnderline, 1)
	el.pageUnderline = pageUnderline

	local controls = {}
	local controlIcons = { Icons["settings"], Icons["minus"], Icons["square"], Icons["x"] }
	local controlX = 410 - 16 - (4 * 12 + 3 * 4)
	for i, image in ipairs(controlIcons) do
		local btn = makeFrame(
			content,
			"MiniControl" .. i,
			UDim2.fromOffset(controlX + (i - 1) * 16, 13),
			UDim2.fromOffset(12, 12)
		)
		addCorner(btn, 4)
		local icon = makeIcon(btn, "MiniControlIcon" .. i, image, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(8, 8))
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		controls[i] = { frame = btn, icon = icon }
	end
	el.controls = controls

	-- Section shells
	local function makeSection(name, position, size, titleText)
		local section = makeFrame(content, name, position, size)
		addCorner(section, 8)
		local stroke = addStroke(section, WHITE, 0.92)
		local title = makeLabel(
			section,
			name .. "Title",
			titleText,
			UDim2.fromOffset(10, 6),
			UDim2.new(1, -20, 0, 10),
			8,
			Enum.FontWeight.SemiBold,
			WHITE
		)
		title.TextTransparency = 0.15
		return section, stroke, title
	end

	local function makeInnerCard(host, name, position, size)
		local card = makeFrame(host, name, position, size)
		addCorner(card, 6)
		local stroke = addStroke(card, WHITE, 0.94)
		return card, stroke
	end

	-- Welcome
	local welcome, welcomeStroke, welcomeTitle =
		makeSection("MiniWelcome", UDim2.fromOffset(16, 44), UDim2.fromOffset(208, 122), "Welcome")
	el.welcome = welcome
	el.welcomeStroke = welcomeStroke
	el.welcomeTitle = welcomeTitle

	local welcomeHeading = makeLabel(
		welcome,
		"MiniWelcomeHeading",
		"Aetheris Component Showcase",
		UDim2.fromOffset(10, 20),
		UDim2.new(1, -20, 0, 12),
		9,
		Enum.FontWeight.Bold,
		WHITE
	)
	el.welcomeHeading = welcomeHeading

	local welcomeBody = makeLabel(
		welcome,
		"MiniWelcomeBody",
		"Every element the library offers, on one screen.",
		UDim2.fromOffset(10, 34),
		UDim2.new(1, -20, 0, 10),
		7,
		Enum.FontWeight.Medium,
		WHITE
	)
	welcomeBody.TextTransparency = 0.2
	el.welcomeBody = welcomeBody

	local welcomeCard, welcomeCardStroke =
		makeInnerCard(welcome, "MiniWelcomeCard", UDim2.fromOffset(10, 50), UDim2.new(1, -20, 0, 30))
	el.welcomeCard = welcomeCard
	el.welcomeCardStroke = welcomeCardStroke

	local welcomeCardLabel = makeLabel(
		welcomeCard,
		"MiniWelcomeCardLabel",
		"Bold label with container",
		UDim2.fromOffset(8, 0),
		UDim2.new(1, -16, 1, 0),
		7,
		Enum.FontWeight.SemiBold,
		WHITE
	)
	el.welcomeCardLabel = welcomeCardLabel

	local welcomePlain = makeLabel(
		welcome,
		"MiniWelcomePlain",
		"Plain label - no container",
		UDim2.fromOffset(10, 88),
		UDim2.new(1, -20, 0, 10),
		7,
		Enum.FontWeight.Medium,
		WHITE
	)
	welcomePlain.TextTransparency = 0.3
	el.welcomePlain = welcomePlain

	-- Actions
	local actions, actionsStroke, actionsTitle =
		makeSection("MiniActions", UDim2.fromOffset(236, 44), UDim2.fromOffset(158, 122), "Actions")
	el.actions = actions
	el.actionsStroke = actionsStroke
	el.actionsTitle = actionsTitle

	local actionRows = {}
	local actionDefs = { "Do The Thing", "Open UINotification", "Send a toast" }
	for i, text in ipairs(actionDefs) do
		local row, rowStroke =
			makeInnerCard(actions, "MiniAction" .. i, UDim2.fromOffset(10, 22 + (i - 1) * 32), UDim2.new(1, -20, 0, 26))
		local label = makeLabel(
			row,
			"MiniActionText" .. i,
			text,
			UDim2.fromOffset(8, 0),
			UDim2.new(1, -28, 1, 0),
			7,
			Enum.FontWeight.Medium,
			WHITE
		)
		local icon = makeIcon(
			row,
			"MiniActionIcon" .. i,
			Icons["mouse-pointer"],
			UDim2.new(1, -18, 0.5, 0),
			UDim2.fromOffset(10, 10)
		)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		actionRows[i] = { row = row, stroke = rowStroke, label = label, icon = icon }
	end
	el.actionRows = actionRows

	-- Palette
	local palette, paletteStroke, paletteTitle =
		makeSection("MiniPalette", UDim2.fromOffset(16, 178), UDim2.fromOffset(208, 122), "Palette")
	el.palette = palette
	el.paletteStroke = paletteStroke
	el.paletteTitle = paletteTitle

	local swatches = {}
	for i = 1, 4 do
		local swatch =
			makeFrame(palette, "MiniSwatch" .. i, UDim2.fromOffset(10 + (i - 1) * 32, 24), UDim2.fromOffset(26, 26))
		addCorner(swatch, 6)
		local stroke = addStroke(swatch, WHITE, 0.9)
		swatches[i] = { frame = swatch, stroke = stroke }
	end
	el.swatches = swatches

	local paletteBar = makeFrame(palette, "MiniPaletteBar", UDim2.fromOffset(10, 58), UDim2.new(1, -20, 0, 10))
	addCorner(paletteBar, 5)
	local paletteGradient = Instance.new("UIGradient")
	paletteGradient.Rotation = 0
	paletteGradient.Parent = paletteBar
	el.paletteBar = paletteBar
	el.paletteGradient = paletteGradient

	local paletteCaption = makeLabel(
		palette,
		"MiniPaletteCaption",
		"Primary / Secondary / Tertiary / Accent",
		UDim2.fromOffset(10, 76),
		UDim2.new(1, -20, 0, 10),
		7,
		Enum.FontWeight.Medium,
		WHITE
	)
	paletteCaption.TextTransparency = 0.3
	el.paletteCaption = paletteCaption

	-- Secure Mode / API
	local secure, secureStroke, secureTitle =
		makeSection("MiniSecure", UDim2.fromOffset(236, 178), UDim2.fromOffset(158, 122), "Secure Mode / API")
	el.secure = secure
	el.secureStroke = secureStroke
	el.secureTitle = secureTitle

	local secureBody = makeLabel(
		secure,
		"MiniSecureBody",
		"Drive the window from your script.",
		UDim2.fromOffset(10, 20),
		UDim2.new(1, -20, 0, 10),
		7,
		Enum.FontWeight.Medium,
		WHITE
	)
	secureBody.TextTransparency = 0.2
	el.secureBody = secureBody

	local secureField, secureFieldStroke =
		makeInnerCard(secure, "MiniSecureField", UDim2.fromOffset(10, 36), UDim2.new(1, -20, 0, 26))
	el.secureField = secureField
	el.secureFieldStroke = secureFieldStroke

	local secureLabel = makeLabel(
		secureField,
		"MiniSecureLabel",
		"Live status",
		UDim2.fromOffset(8, 0),
		UDim2.new(1, -30, 1, 0),
		7,
		Enum.FontWeight.SemiBold,
		WHITE
	)
	el.secureLabel = secureLabel

	local secureDot = makeFrame(secureField, "MiniSecureDot", UDim2.new(1, -15, 0.5, -3), UDim2.fromOffset(6, 6))
	addCorner(secureDot, 3)
	el.secureDot = secureDot

	local secureHint = makeLabel(
		secure,
		"MiniSecureHint",
		"API target",
		UDim2.fromOffset(10, 72),
		UDim2.new(1, -20, 0, 10),
		7,
		Enum.FontWeight.Medium,
		WHITE
	)
	secureHint.TextTransparency = 0.35
	el.secureHint = secureHint

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

	t = t or {}
	local accent = t.AccentColor or t.PrimaryColor or Color3.fromRGB(120, 156, 210)
	local primary = t.PrimaryColor or accent
	local secondary = t.SecondaryColor or primary
	local tertiary = t.TertiaryColor or Color3.fromRGB(150, 150, 150)
	local windowBg = t.WindowColor or Color3.fromRGB(18, 18, 20)
	local sidebarBg = t.SidebarColor or windowBg
	local contentBg = t.ContentBackgroundColor or windowBg
	local compBg = t.ComponentBackgroundColor or Color3.fromRGB(32, 32, 38)
	local inputBg = t.InputBackgroundColor or Color3.fromRGB(40, 40, 46)
	local text = t.TitleTextColor or t.PrimaryTextColor or Color3.fromRGB(240, 240, 245)
	local subText = t.SecondaryTextColor or Color3.fromRGB(160, 160, 170)
	local popupBg = t.PopupBackgroundColor or Color3.fromRGB(22, 22, 26)
	local popupText = t.PopupTextColor or text

	local sectionBg = t.SectionBackgroundColor or compBg
	local sectionTrans = math.clamp(t.SectionBackgroundTransparency or 0.9, 0, 0.9)
	local sectionStrokeColor = t.SectionStrokeColor or WHITE
	local sectionStrokeTrans = math.clamp(t.SectionStrokeTransparency or 0.92, 0, 0.92)
	local compTrans = math.clamp(t.ComponentBackgroundTransparency or 0.7, 0, 0.88)
	local inputTrans = math.clamp(t.InputBackgroundTransparency or 0.4, 0, 0.6)
	local activeTabBg = t.ActiveTabButtonColor or WHITE
	local activeTabTrans = math.clamp(t.ActiveTabButtonTransparency or 0.85, 0, 0.85)
	local activeTabText = t.ActiveTabTextColor or text
	local inactiveTabText = t.InactiveTabTextColor or subText
	local searchBg = t.SearchBarBackgroundColor or inputBg
	local searchTrans = math.clamp(t.SearchBarBackgroundTransparency or 0.5, 0, 0.6)

	el.shell.BackgroundColor3 = popupBg
	el.headTile.BackgroundColor3 = accent
	el.headGlyph.ImageColor3 = WHITE
	el.headTitle.TextColor3 = popupText
	el.headSubtitle.TextColor3 = subText
	el.closeBtn.BackgroundColor3 = WHITE
	el.closeIcon.ImageColor3 = popupText

	el.miniWindow.BackgroundColor3 = windowBg
	el.miniWindow.BackgroundTransparency = math.clamp(t.WindowTransparency or 0, 0, 0.9)
	el.miniStroke.Color = sectionStrokeColor
	el.miniStroke.Transparency = sectionStrokeTrans
	el.miniGlow.Color = accent

	el.sidebar.BackgroundColor3 = sidebarBg
	el.sidebar.BackgroundTransparency = math.clamp(t.SidebarTransparency or 0, 0, 0.9)

	el.logo.BackgroundColor3 = accent
	el.logoText.TextColor3 = WHITE
	el.appTitle.TextColor3 = text

	local chipColors = { primary = primary, secondary = secondary, accent = accent }
	for _, chip in ipairs(el.chips) do
		chip.frame.BackgroundColor3 = chipColors[chip.key] or accent
		chip.label.TextColor3 = WHITE
	end

	el.searchBox.BackgroundColor3 = searchBg
	el.searchBox.BackgroundTransparency = searchTrans
	el.searchIcon.ImageColor3 = subText
	el.searchText.TextColor3 = subText

	for _, nav in ipairs(el.navRows) do
		if nav.active then
			nav.row.BackgroundColor3 = activeTabBg
			nav.row.BackgroundTransparency = activeTabTrans
			nav.icon.ImageColor3 = activeTabText
			nav.icon.ImageTransparency = 0
			nav.label.TextColor3 = activeTabText
			nav.label.TextTransparency = 0
		else
			nav.row.BackgroundColor3 = compBg
			nav.row.BackgroundTransparency = 1
			nav.icon.ImageColor3 = inactiveTabText
			nav.icon.ImageTransparency = 0.2
			nav.label.TextColor3 = inactiveTabText
			nav.label.TextTransparency = 0.15
		end
	end

	el.divider.BackgroundColor3 = sectionStrokeColor
	el.divider.BackgroundTransparency = math.clamp(t.SectionDividerTransparency or 0.85, 0, 0.95)
	el.avatar.BackgroundColor3 = compBg
	el.avatar.BackgroundTransparency = compTrans
	el.avatarIcon.ImageColor3 = subText
	el.userName.TextColor3 = text
	el.userHandle.TextColor3 = subText
	el.userNum1.TextColor3 = subText
	el.userNum2.TextColor3 = subText

	el.content.BackgroundColor3 = contentBg
	el.content.BackgroundTransparency = math.clamp(t.ContentBackgroundTransparency or 0, 0, 0.9)

	local wp = t.Wallpaper or t.Name
	el.miniWallpaper.Image = WallpaperManager.GetAsset(wp, function(resolved)
		if el.miniWallpaper and el.miniWallpaper.Parent then
			el.miniWallpaper.Image = resolved
		end
	end)
	el.miniWallpaper.ImageTransparency = math.clamp(t.WallpaperTransparency or 0.82, 0, 1)

	el.pageTitle.TextColor3 = text
	el.pageUnderline.BackgroundColor3 = accent

	for _, control in ipairs(el.controls) do
		control.frame.BackgroundColor3 = compBg
		control.frame.BackgroundTransparency = math.clamp(compTrans + 0.05, 0, 0.95)
		control.icon.ImageColor3 = subText
	end

	local sections = {
		{ el.welcome, el.welcomeStroke, el.welcomeTitle },
		{ el.actions, el.actionsStroke, el.actionsTitle },
		{ el.palette, el.paletteStroke, el.paletteTitle },
		{ el.secure, el.secureStroke, el.secureTitle },
	}
	for _, section in ipairs(sections) do
		section[1].BackgroundColor3 = sectionBg
		section[1].BackgroundTransparency = sectionTrans
		section[2].Color = sectionStrokeColor
		section[2].Transparency = sectionStrokeTrans
		section[3].TextColor3 = subText
	end

	el.welcomeHeading.TextColor3 = text
	el.welcomeBody.TextColor3 = subText
	el.welcomeCard.BackgroundColor3 = compBg
	el.welcomeCard.BackgroundTransparency = compTrans
	el.welcomeCardStroke.Color = sectionStrokeColor
	el.welcomeCardStroke.Transparency = math.clamp(sectionStrokeTrans + 0.02, 0, 0.95)
	el.welcomeCardLabel.TextColor3 = text
	el.welcomePlain.TextColor3 = subText

	for _, row in ipairs(el.actionRows) do
		row.row.BackgroundColor3 = compBg
		row.row.BackgroundTransparency = compTrans
		row.stroke.Color = sectionStrokeColor
		row.stroke.Transparency = math.clamp(sectionStrokeTrans + 0.02, 0, 0.95)
		row.label.TextColor3 = text
		row.icon.ImageColor3 = subText
	end

	local swatchColors = { primary, secondary, tertiary, accent }
	for i, swatch in ipairs(el.swatches) do
		swatch.frame.BackgroundColor3 = swatchColors[i] or accent
		swatch.stroke.Color = sectionStrokeColor
		swatch.stroke.Transparency = math.clamp(sectionStrokeTrans + 0.02, 0, 0.95)
	end
	el.paletteGradient.Color = ColorSequence.new(primary, accent)
	el.paletteCaption.TextColor3 = subText

	el.secureBody.TextColor3 = subText
	el.secureField.BackgroundColor3 = inputBg
	el.secureField.BackgroundTransparency = inputTrans
	el.secureFieldStroke.Color = sectionStrokeColor
	el.secureFieldStroke.Transparency = math.clamp(sectionStrokeTrans + 0.02, 0, 0.95)
	el.secureLabel.TextColor3 = text
	el.secureDot.BackgroundColor3 = accent
	el.secureHint.TextColor3 = subText
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
