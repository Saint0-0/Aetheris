--[[
	Aetheris/Popups/ThemePreviewPopUp.luau

	Live miniature window preview. The miniature itself is the popup: no outer
	header, just a close control in the window chrome. All labels are bars so
	the mock reads as a theme card rather than readable text.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

--# selene: allow(undefined_variable)

local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local UUID = require("../Utils/UUID")
local WallpaperManager = require("../Utils/WallpaperManager")
local UserInputService = game:GetService("UserInputService")

local ThemePreviewPopUp = {}

local SIDEBAR_W = 138
local POPUP_W, POPUP_H = 548, 328
local WHITE = Color3.new(1, 1, 1)

-- Close button hover, matching the changelog's icon timing.
local ICON_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ICON_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_ICON = Icons["circle-x"] or "rbxassetid://76821953846248"
local SCRIPT_LOGO = "rbxassetid://92458734285074"

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
	local bars = {}
	el.bars = bars

	local function makeBar(host, name, position, size, tone, radius)
		local bar = makeFrame(host, name, position, size)
		addCorner(bar, radius or 3)
		table.insert(bars, { frame = bar, tone = tone or "text" })
		return bar
	end

	-- The miniature window is the popup itself.
	local shell = Instance.new("CanvasGroup")
	shell.Name = UUID.Generate("ThemePreviewShell")
	shell.BorderSizePixel = 0
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.5)
	shell.Size = UDim2.fromOffset(POPUP_W, POPUP_H)
	shell.ZIndex = 1201
	shell.Visible = false
	shell.GroupTransparency = 1
	-- Sink clicks on the chrome; only a click outside the rect dismisses.
	shell.Active = true
	shell.Parent = parent
	self._shell = shell
	el.shell = shell

	addCorner(shell, 12)
	local shellStroke = addStroke(shell, WHITE, 0.92)
	el.shellStroke = shellStroke

	local shellGlow = Instance.new("UIShadow")
	shellGlow.BlurRadius = UDim.new(0, 22)
	shellGlow.Color = WHITE
	shellGlow.Transparency = 0.68
	shellGlow.Parent = shell
	el.shellGlow = shellGlow

	-- Sidebar
	local sidebar = makeFrame(shell, "MiniSidebar", UDim2.fromOffset(0, 0), UDim2.new(0, SIDEBAR_W, 1, 0))
	sidebar.Active = true
	addCorner(sidebar, 12)
	el.sidebar = sidebar

	-- Brand mark: same asset and 40x32 footprint as Window.luau's ScriptLogo.
	local logo = Instance.new("ImageLabel")
	logo.Name = UUID.Static("MiniLogo")
	logo.BorderSizePixel = 0
	logo.BackgroundTransparency = 1
	logo.Image = SCRIPT_LOGO
	logo.Size = UDim2.fromOffset(40, 32)
	logo.Position = UDim2.fromOffset(12, 12)
	logo.Parent = sidebar
	addCorner(logo, 6)
	el.logo = logo

	makeBar(sidebar, "MiniAppTitle", UDim2.fromOffset(58, 16), UDim2.fromOffset(52, 8), "title", 4)

	local chips = {}
	local chipDefs = {
		{ key = "primary", width = 18 },
		{ key = "secondary", width = 18 },
		{ key = "accent", width = 18 },
	}
	local chipX = 58
	for i, def in ipairs(chipDefs) do
		local chip = makeFrame(sidebar, "MiniChip" .. i, UDim2.fromOffset(chipX, 30), UDim2.fromOffset(def.width, 8))
		addCorner(chip, 4)
		chips[i] = { frame = chip, key = def.key }
		chipX += def.width + 3
	end
	el.chips = chips

	local searchBox = makeFrame(sidebar, "MiniSearch", UDim2.fromOffset(12, 54), UDim2.new(1, -24, 0, 20))
	addCorner(searchBox, 6)
	el.searchBox = searchBox

	local searchIcon =
		makeIcon(searchBox, "MiniSearchIcon", Icons["search"], UDim2.fromOffset(7, 5), UDim2.fromOffset(10, 10))
	el.searchIcon = searchIcon

	makeBar(searchBox, "MiniSearchBar", UDim2.fromOffset(24, 7), UDim2.fromOffset(54, 5), "muted", 3)

	local navDefs = {
		{ icon = Icons["house"], active = true },
		{ icon = Icons["sliders-horizontal"], active = false },
		{ icon = Icons["text-cursor"], active = false },
		{ icon = Icons["bell"], active = false },
		{ icon = Icons["play"], active = false },
	}
	local navRows = {}
	for i, def in ipairs(navDefs) do
		local row =
			makeFrame(sidebar, "MiniNav" .. i, UDim2.fromOffset(12, 84 + (i - 1) * 25), UDim2.new(1, -24, 0, 22))
		addCorner(row, 6)
		local icon = makeIcon(row, "MiniNavIcon" .. i, def.icon, UDim2.fromOffset(7, 5), UDim2.fromOffset(12, 12))
		local bar = makeBar(
			row,
			"MiniNavBar" .. i,
			UDim2.fromOffset(25, 8),
			UDim2.fromOffset(54, 5),
			def.active and "active" or "muted",
			3
		)
		navRows[i] = { row = row, icon = icon, bar = bar, active = def.active }
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

	makeBar(sidebar, "MiniUserName", UDim2.new(0, 38, 1, -29), UDim2.fromOffset(46, 6), "text", 3)
	makeBar(sidebar, "MiniUserHandle", UDim2.new(0, 38, 1, -19), UDim2.fromOffset(34, 5), "muted", 3)
	makeBar(sidebar, "MiniUserNum1", UDim2.new(1, -24, 1, -29), UDim2.fromOffset(12, 5), "muted", 3)
	makeBar(sidebar, "MiniUserNum2", UDim2.new(1, -21, 1, -19), UDim2.fromOffset(9, 5), "muted", 3)

	-- Content pane
	local content = makeFrame(shell, "MiniContent", UDim2.fromOffset(SIDEBAR_W, 0), UDim2.new(1, -SIDEBAR_W, 1, 0))
	content.Active = true
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

	makeBar(content, "MiniPageTitle", UDim2.fromOffset(16, 14), UDim2.fromOffset(46, 8), "title", 4)
	makeBar(content, "MiniPageUnderline", UDim2.fromOffset(16, 28), UDim2.fromOffset(22, 2), "accent", 1)

	-- Window chrome: three decorative dots and a real close control.
	local controls = {}
	local controlIcons = { Icons["settings"], Icons["minus"], Icons["square"] }
	for i, image in ipairs(controlIcons) do
		local btn =
			makeFrame(content, "MiniControl" .. i, UDim2.fromOffset(324 + (i - 1) * 16, 15), UDim2.fromOffset(12, 12))
		addCorner(btn, 4)
		local icon = makeIcon(btn, "MiniControlIcon" .. i, image, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(8, 8))
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		controls[i] = { frame = btn, icon = icon }
	end
	el.controls = controls

	local closeBtn = Instance.new("ImageButton")
	closeBtn.Name = UUID.Static("PreviewClose")
	closeBtn.BorderSizePixel = 0
	closeBtn.BackgroundColor3 = WHITE
	closeBtn.BackgroundTransparency = 0.92
	closeBtn.AutoButtonColor = false
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -12, 0, 10)
	closeBtn.Size = UDim2.fromOffset(22, 22)
	closeBtn.Parent = content
	addCorner(closeBtn, 11)
	el.closeBtn = closeBtn

	local closeIcon =
		makeIcon(closeBtn, "PreviewCloseIcon", CLOSE_ICON, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(14, 14))
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.ImageTransparency = 0.3
	el.closeIcon = closeIcon

	closeBtn.MouseEnter:Connect(function()
		Tween.Play(closeBtn, ICON_IN, { BackgroundTransparency = 0.84 })
		Tween.Play(closeIcon, ICON_IN, { ImageTransparency = 0 })
	end)
	closeBtn.MouseLeave:Connect(function()
		Tween.Play(closeBtn, ICON_OUT, { BackgroundTransparency = 0.92 })
		Tween.Play(closeIcon, ICON_OUT, { ImageTransparency = 0.3 })
	end)

	-- Section shells
	local function makeSection(name, position, size)
		local section = makeFrame(content, name, position, size)
		addCorner(section, 8)
		local stroke = addStroke(section, WHITE, 0.92)
		return section, stroke
	end

	local function makeInnerCard(host, name, position, size)
		local card = makeFrame(host, name, position, size)
		addCorner(card, 6)
		local stroke = addStroke(card, WHITE, 0.94)
		return card, stroke
	end

	-- Welcome
	local welcome, welcomeStroke = makeSection("MiniWelcome", UDim2.fromOffset(16, 44), UDim2.fromOffset(208, 122))
	el.welcome = welcome
	el.welcomeStroke = welcomeStroke
	makeBar(welcome, "MiniWelcomeTitle", UDim2.fromOffset(10, 8), UDim2.fromOffset(44, 5), "muted", 3)
	makeBar(welcome, "MiniWelcomeHeading", UDim2.fromOffset(10, 22), UDim2.fromOffset(120, 7), "title", 3)
	makeBar(welcome, "MiniWelcomeBody", UDim2.fromOffset(10, 36), UDim2.fromOffset(150, 5), "sub", 3)
	makeBar(welcome, "MiniWelcomeBody2", UDim2.fromOffset(10, 44), UDim2.fromOffset(108, 5), "sub", 3)

	local welcomeCard, welcomeCardStroke =
		makeInnerCard(welcome, "MiniWelcomeCard", UDim2.fromOffset(10, 58), UDim2.new(1, -20, 0, 28))
	el.welcomeCard = welcomeCard
	el.welcomeCardStroke = welcomeCardStroke
	makeBar(welcomeCard, "MiniWelcomeCardBar", UDim2.fromOffset(8, 11), UDim2.fromOffset(92, 5), "text", 3)

	makeBar(welcome, "MiniWelcomePlain", UDim2.fromOffset(10, 94), UDim2.fromOffset(100, 5), "muted", 3)

	-- Actions
	local actions, actionsStroke = makeSection("MiniActions", UDim2.fromOffset(236, 44), UDim2.fromOffset(158, 122))
	el.actions = actions
	el.actionsStroke = actionsStroke
	makeBar(actions, "MiniActionsTitle", UDim2.fromOffset(10, 8), UDim2.fromOffset(40, 5), "muted", 3)

	local actionRows = {}
	for i = 1, 3 do
		local row, rowStroke =
			makeInnerCard(actions, "MiniAction" .. i, UDim2.fromOffset(10, 22 + (i - 1) * 32), UDim2.new(1, -20, 0, 26))
		makeBar(row, "MiniActionBar" .. i, UDim2.fromOffset(8, 10), UDim2.fromOffset(70, 5), "text", 3)
		local icon = makeIcon(
			row,
			"MiniActionIcon" .. i,
			Icons["mouse-pointer"],
			UDim2.new(1, -18, 0.5, 0),
			UDim2.fromOffset(10, 10)
		)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		actionRows[i] = { row = row, stroke = rowStroke, icon = icon }
	end
	el.actionRows = actionRows

	-- Palette
	local palette, paletteStroke = makeSection("MiniPalette", UDim2.fromOffset(16, 178), UDim2.fromOffset(208, 122))
	el.palette = palette
	el.paletteStroke = paletteStroke
	makeBar(palette, "MiniPaletteTitle", UDim2.fromOffset(10, 8), UDim2.fromOffset(38, 5), "muted", 3)

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

	makeBar(palette, "MiniPaletteCaption", UDim2.fromOffset(10, 78), UDim2.fromOffset(120, 5), "muted", 3)

	-- Secure Mode / API
	local secure, secureStroke = makeSection("MiniSecure", UDim2.fromOffset(236, 178), UDim2.fromOffset(158, 122))
	el.secure = secure
	el.secureStroke = secureStroke
	makeBar(secure, "MiniSecureTitle", UDim2.fromOffset(10, 8), UDim2.fromOffset(70, 5), "muted", 3)
	makeBar(secure, "MiniSecureBody", UDim2.fromOffset(10, 22), UDim2.fromOffset(110, 5), "sub", 3)

	local secureField, secureFieldStroke =
		makeInnerCard(secure, "MiniSecureField", UDim2.fromOffset(10, 38), UDim2.new(1, -20, 0, 26))
	el.secureField = secureField
	el.secureFieldStroke = secureFieldStroke
	makeBar(secureField, "MiniSecureLabel", UDim2.fromOffset(8, 10), UDim2.fromOffset(60, 5), "text", 3)

	local secureDot = makeFrame(secureField, "MiniSecureDot", UDim2.new(1, -15, 0.5, -3), UDim2.fromOffset(6, 6))
	addCorner(secureDot, 3)
	el.secureDot = secureDot

	makeBar(secure, "MiniSecureHint", UDim2.fromOffset(10, 74), UDim2.fromOffset(60, 5), "muted", 3)

	closeBtn.MouseButton1Click:Connect(function()
		self:Dismiss()
	end)

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

	el.shell.BackgroundColor3 = windowBg
	el.shell.BackgroundTransparency = math.clamp(t.WindowTransparency or 0, 0, 0.9)
	el.shellStroke.Color = sectionStrokeColor
	el.shellStroke.Transparency = sectionStrokeTrans
	el.shellGlow.Color = accent

	el.sidebar.BackgroundColor3 = sidebarBg
	el.sidebar.BackgroundTransparency = math.clamp(t.SidebarTransparency or 0, 0, 0.9)

	el.content.BackgroundColor3 = contentBg
	el.content.BackgroundTransparency = math.clamp(t.ContentBackgroundTransparency or 0, 0, 0.9)

	-- Async GitHub resolutions must not overwrite a newer theme's wallpaper.
	self._wallpaperToken = (self._wallpaperToken or 0) + 1
	local wallpaperToken = self._wallpaperToken
	local wp = t.Wallpaper or t.Name
	el.miniWallpaper.Image = WallpaperManager.GetAsset(wp, function(resolved)
		if wallpaperToken == self._wallpaperToken and el.miniWallpaper and el.miniWallpaper.Parent then
			el.miniWallpaper.Image = resolved
		end
	end)
	el.miniWallpaper.ImageTransparency = math.clamp(t.WallpaperTransparency or 0.82, 0, 1)

	local chipColors = { primary = primary, secondary = secondary, accent = accent }
	for _, chip in ipairs(el.chips) do
		chip.frame.BackgroundColor3 = chipColors[chip.key] or accent
	end

	el.searchBox.BackgroundColor3 = searchBg
	el.searchBox.BackgroundTransparency = searchTrans
	el.searchIcon.ImageColor3 = subText

	for _, nav in ipairs(el.navRows) do
		if nav.active then
			nav.row.BackgroundColor3 = activeTabBg
			nav.row.BackgroundTransparency = activeTabTrans
			nav.icon.ImageColor3 = activeTabText
			nav.icon.ImageTransparency = 0
		else
			nav.row.BackgroundColor3 = compBg
			nav.row.BackgroundTransparency = 1
			nav.icon.ImageColor3 = inactiveTabText
			nav.icon.ImageTransparency = 0.2
		end
	end

	el.divider.BackgroundColor3 = sectionStrokeColor
	el.divider.BackgroundTransparency = math.clamp(t.SectionDividerTransparency or 0.85, 0, 0.95)
	el.avatar.BackgroundColor3 = compBg
	el.avatar.BackgroundTransparency = compTrans
	el.avatarIcon.ImageColor3 = subText

	for _, control in ipairs(el.controls) do
		control.frame.BackgroundColor3 = compBg
		control.frame.BackgroundTransparency = math.clamp(compTrans + 0.05, 0, 0.95)
		control.icon.ImageColor3 = subText
	end

	el.closeBtn.BackgroundColor3 = WHITE
	el.closeIcon.ImageColor3 = popupText

	local sections = {
		{ el.welcome, el.welcomeStroke },
		{ el.actions, el.actionsStroke },
		{ el.palette, el.paletteStroke },
		{ el.secure, el.secureStroke },
	}
	for _, section in ipairs(sections) do
		section[1].BackgroundColor3 = sectionBg
		section[1].BackgroundTransparency = sectionTrans
		section[2].Color = sectionStrokeColor
		section[2].Transparency = sectionStrokeTrans
	end

	el.welcomeCard.BackgroundColor3 = compBg
	el.welcomeCard.BackgroundTransparency = compTrans
	el.welcomeCardStroke.Color = sectionStrokeColor
	el.welcomeCardStroke.Transparency = math.clamp(sectionStrokeTrans + 0.02, 0, 0.95)

	for _, row in ipairs(el.actionRows) do
		row.row.BackgroundColor3 = compBg
		row.row.BackgroundTransparency = compTrans
		row.stroke.Color = sectionStrokeColor
		row.stroke.Transparency = math.clamp(sectionStrokeTrans + 0.02, 0, 0.95)
		row.icon.ImageColor3 = subText
	end

	local swatchColors = { primary, secondary, tertiary, accent }
	for i, swatch in ipairs(el.swatches) do
		swatch.frame.BackgroundColor3 = swatchColors[i] or accent
		swatch.stroke.Color = sectionStrokeColor
		swatch.stroke.Transparency = math.clamp(sectionStrokeTrans + 0.02, 0, 0.95)
	end
	el.paletteGradient.Color = ColorSequence.new(primary, accent)

	el.secureField.BackgroundColor3 = inputBg
	el.secureField.BackgroundTransparency = inputTrans
	el.secureFieldStroke.Color = sectionStrokeColor
	el.secureFieldStroke.Transparency = math.clamp(sectionStrokeTrans + 0.02, 0, 0.95)
	el.secureDot.BackgroundColor3 = accent

	-- Bars replace every text label. Tones map to the live theme's text ramp.
	local toneMap = {
		title = { color = text, transparency = 0 },
		text = { color = text, transparency = 0.1 },
		sub = { color = subText, transparency = 0.2 },
		muted = { color = subText, transparency = 0.45 },
		active = { color = activeTabText, transparency = 0 },
		accent = { color = accent, transparency = 0 },
	}
	for _, bar in ipairs(el.bars) do
		local tone = toneMap[bar.tone] or toneMap.text
		bar.frame.BackgroundColor3 = tone.color
		bar.frame.BackgroundTransparency = tone.transparency
	end
end

-- Mirrors DropdownPopUp: clicks are hit-tested against the popup rect instead
-- of a full-screen backdrop, so the whole window stays interactive.
function ThemePreviewPopUp:_connectOutsideClick()
	if self._outsideConn then
		return
	end
	self._outsideConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		local inputType = input.UserInputType
		if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
			return
		end
		if not self._open or not self._shell or not self._shell.Visible then
			return
		end
		local p = input.Position
		local pos = self._shell.AbsolutePosition
		local size = self._shell.AbsoluteSize
		local inside = p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
		if not inside then
			local playerGui = self._shell:FindFirstAncestorOfClass("PlayerGui")
			if playerGui then
				for _, obj in ipairs(playerGui:GetGuiObjectsAtPosition(p.X, p.Y)) do
					if obj == self._shell or obj:IsDescendantOf(self._shell) then
						inside = true
						break
					end
				end
			end
		end
		if not inside then
			self:Close()
		end
	end)
end

function ThemePreviewPopUp:_disconnectOutsideClick()
	if self._outsideConn then
		self._outsideConn:Disconnect()
		self._outsideConn = nil
	end
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

	if self._hideTimer then
		task.cancel(self._hideTimer)
		self._hideTimer = nil
	end

	local shell = self._shell
	local glow = self._elements and self._elements.shellGlow
	-- The shell stroke and shadow are drawn by the CanvasGroup, not its
	-- children, so GroupTransparency does not touch them; fade both by hand.
	local stroke = self._elements and self._elements.shellStroke
	-- Resting opacity comes from the theme; snap transparent so the fade owns it.
	local restBackground = shell.BackgroundTransparency
	local restStroke = stroke and stroke.Transparency or 0
	shell.Visible = true
	shell.GroupTransparency = 1
	shell.BackgroundTransparency = 1
	if glow then
		glow.Transparency = 1
	end
	if stroke then
		stroke.Transparency = 1
	end
	self:_connectOutsideClick()

	Tween.Play(shell, "Fast", { BackgroundTransparency = restBackground, GroupTransparency = 0 })
	if glow then
		Tween.Play(glow, "Fast", { Transparency = 0.5 })
	end
	if stroke then
		Tween.Play(stroke, "Fast", { Transparency = restStroke })
	end
end

function ThemePreviewPopUp:Close()
	if not self._open then
		return
	end
	self._open = false
	if self._window and self._window._activePopUp == self then
		self._window._activePopUp = nil
	end
	self:_disconnectOutsideClick()

	local shell = self._shell
	local glow = self._elements and self._elements.shellGlow
	local stroke = self._elements and self._elements.shellStroke
	if shell then
		Tween.Play(shell, "Fast", { BackgroundTransparency = 1, GroupTransparency = 1 })
	end
	if glow then
		Tween.Play(glow, "Fast", { Transparency = 1 })
	end
	if stroke then
		Tween.Play(stroke, "Fast", { Transparency = 1 })
	end

	if self._hideTimer then
		task.cancel(self._hideTimer)
		self._hideTimer = nil
	end
	self._hideTimer = task.delay(0.35, function()
		if not self._open and self._shell then
			self._shell.Visible = false
		end
		self._hideTimer = nil
	end)
end

function ThemePreviewPopUp:Dismiss()
	self:Close()
end

function ThemePreviewPopUp:IsOpen()
	return self._open
end

function ThemePreviewPopUp:Destroy()
	self._open = false
	if self._window and self._window._activePopUp == self then
		self._window._activePopUp = nil
	end
	self:_disconnectOutsideClick()
	if self._hideTimer then
		task.cancel(self._hideTimer)
		self._hideTimer = nil
	end
	if self._shell then
		self._shell:Destroy()
		self._shell = nil
	end
	self._elements = nil
end

return ThemePreviewPopUp
