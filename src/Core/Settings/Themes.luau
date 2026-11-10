--[[
	Aetheris/Core/Settings/Themes.luau

	Builds the "Themes" page: a header row (page title, ghost chip naming the
	current theme) over a grid of image-blend preview cards — wallpaper melting
	out under a window-colour scrim, palette dots over the image, accent rim and
	glow when active. Cards re-prime and reveal in a cascade each time the page
	shows. THEME_ORDER sets the render order.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeDefinitions = require("../../Themes/ThemeDefinitions")
local ThemeManager = require("../../Themes/ThemeManager")
local FallbackImage = require("../../Constants").FallbackImage
local PageAwareness = require("../../Utils/PageAwareness")
local Tween = require("../../Utils/Tween")
local Constants = require("../../Constants")
local UUID = require("../../Utils/UUID")

local Themes = {}

local THEME_ORDER = {
	"Umbral",
	"Ember",
	"Vesper",
	"Duskfall",
	"Canopy",
	"Tidewater",
	"Nocturne",
	"Solace",
	"Cielo",
	"Honey",
	"Dawn",
	"Alpine",
	"Peony",
	"Sakura",
	"Blush",
	"Cinder",
	"Mauve",
	"Iris",
	"Sundown",
	"Twilight",
	"Nebula",
	"Monterey",
	"Sonoma",
	"Ventura",
	"Vermilion",
	"Grove",
	"Prism",
	"Sage",
	"Blossom",
	"Petal",
	"Frost",
	"Amber",
	"Rosa",
	"Gruvbox",
	"Graphite",
	"Crimson",
	"Umber",
	"Mint",
	"Lilac",
	"Linen",
	"Slate",
	"Onyx",
	"Ash",
	"Gunmetal",
	"Charcoal",
	"Void",
	"Volt",
	"Bone",
	"Merlot",
	"Khaki",
}

-- short enough to fit a card without wrapping
local THEME_DESCRIPTIONS = {
	Umbral = "Deep navy night",
	Ember = "Lava on slate",
	Vesper = "Violet twilight",
	Duskfall = "Plum & gold",
	Canopy = "Mint mist",
	Tidewater = "Teal coast",
	Nocturne = "Magenta aurora",
	Solace = "Pale ice",
	Cielo = "Cobalt & coral",
	Honey = "Golden hour",
	Dawn = "Orchid dawn",
	Alpine = "Slate peaks",
	Peony = "Coral bloom",
	Sakura = "Cherry blossom",
	Blush = "Fuchsia peaks",
	Cinder = "Ash & ember",
	Mauve = "Dusty mauve",
	Iris = "Deep iris",
	Sundown = "Coral sunset",
	Twilight = "Rose over navy",
	Nebula = "Magenta nebula",
	Monterey = "Grey-blue drift",
	Sonoma = "Sea glass",
	Ventura = "Burnt orange",
	Vermilion = "Warm scarlet",
	Grove = "Pine & lime",
	Prism = "Electric indigo",
	Sage = "Teal mist",
	Blossom = "Pink bloom",
	Petal = "Warm salmon",
	Frost = "Fire on ice",
	Amber = "Porcelain pop",
	Rosa = "Rose & periwinkle",
	Gruvbox = "Warm retro",
	Graphite = "Pure neutral",
	Crimson = "Deep red",
	Umber = "Warm bronze",
	Mint = "Light mint",
	Lilac = "Pale violet",
	Linen = "Warm grey",
	Slate = "Storm grey",
	Onyx = "Obsidian black",
	Ash = "Soft smoke",
	Gunmetal = "Dark steel",
	Charcoal = "Warm charcoal",
	Void = "Pure black",
	Volt = "Neon charge",
	Bone = "Warm cream",
	Merlot = "Wine cellar",
	Khaki = "Field olive",
}

-- Card geometry and the settle the reveal cascade rides (design-notes 4).
local CARD_W, CARD_H, CARD_RADIUS = 145, 84, 10
local SETTLE = TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- {time, value} pairs -> NumberSequence for the scrim, melt and rim ramps.
local function ramp(points)
	local keypoints = {}
	for _, point in ipairs(points) do
		table.insert(keypoints, NumberSequenceKeypoint.new(point[1], point[2]))
	end
	return NumberSequence.new(keypoints)
end

-- design-notes 10: dark grounds take the stronger wash multiplier, light the softer one.
local function isDark(color)
	return (color.R * 0.299 + color.G * 0.587 + color.B * 0.114) < 0.5
end

local function makeCard(parent, name, theme, active, order, onActivate)
	local white = Color3.new(1, 1, 1)
	local accent = theme.AccentColor or theme.PrimaryColor or Color3.fromRGB(120, 156, 210)
	local textColor = theme.TitleTextColor or theme.PrimaryTextColor or white
	local base = theme.WindowColor or Color3.fromRGB(16, 16, 17)

	local card = Instance.new("TextButton")
	card.Name = UUID.Generate("ThemeCard")
	card.BorderSizePixel = 0
	card.AutoButtonColor = false
	card.BackgroundColor3 = white
	card.BackgroundTransparency = 1
	card.Size = UDim2.fromOffset(CARD_W, CARD_H)
	card.LayoutOrder = order
	card.Text = ""
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CARD_RADIUS)
	corner.Parent = card

	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = card

	-- Fill: the card's own window colour, washed top-light to bottom-dark (design-notes 10).
	local fill = Instance.new("Frame")
	fill.Name = UUID.Static("CardFill")
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = base
	fill.BackgroundTransparency = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = card

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, CARD_RADIUS)
	fillCorner.Parent = fill

	local wash = Instance.new("UIGradient")
	wash.Rotation = 90
	wash.Color = ColorSequence.new(white, isDark(base) and Color3.new(0.72, 0.72, 0.72) or Color3.new(0.9, 0.9, 0.9))
	wash.Parent = fill

	-- Accent glow hangs off the fill so it rounds with the card; off until painted.
	local shadow = Instance.new("UIShadow")
	shadow.BlurRadius = UDim.new(0, 18)
	shadow.Color = accent
	shadow.Transparency = 1
	shadow.Enabled = false
	shadow.Parent = fill

	-- Wallpaper: full-bleed crop melting out toward the text zone.
	local image = Instance.new("ImageLabel")
	image.Name = UUID.Static("CardWallpaper")
	image.BorderSizePixel = 0
	image.BackgroundColor3 = white
	image.BackgroundTransparency = 1
	image.Image = theme.Wallpaper or FallbackImage
	image.Size = UDim2.fromScale(1, 1)
	image.ScaleType = Enum.ScaleType.Crop
	image.Parent = card

	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0, CARD_RADIUS)
	imageCorner.Parent = image

	local melt = Instance.new("UIGradient")
	melt.Rotation = 90
	melt.Transparency = ramp({ { 0, 0 }, { 0.3, 0 }, { 0.5, 0.4 }, { 0.7, 0.85 }, { 0.85, 1 }, { 1, 1 } })
	melt.Parent = image

	-- Scrim: window colour rising from the bottom so the text sits on solid ground.
	local scrim = Instance.new("Frame")
	scrim.Name = UUID.Static("CardScrim")
	scrim.BorderSizePixel = 0
	scrim.BackgroundColor3 = base
	scrim.BackgroundTransparency = 0
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.Parent = card

	local scrimCorner = Instance.new("UICorner")
	scrimCorner.CornerRadius = UDim.new(0, CARD_RADIUS)
	scrimCorner.Parent = scrim

	local scrimFade = Instance.new("UIGradient")
	scrimFade.Rotation = 90
	scrimFade.Transparency = ramp({ { 0, 1 }, { 0.45, 1 }, { 1, 0.25 } })
	scrimFade.Parent = scrim

	local title = Instance.new("TextLabel")
	title.Name = UUID.Static("ThemeTitle")
	title.BorderSizePixel = 0
	title.BackgroundTransparency = 1
	title.FontFace = Constants.Font(Enum.FontWeight.Bold)
	title.TextSize = 13
	title.TextColor3 = textColor
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.AnchorPoint = Vector2.new(0, 0.5)
	title.Size = UDim2.new(1, -28, 0, 18)
	title.Position = UDim2.fromOffset(14, 45)
	title.Text = name
	title.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Name = UUID.Static("ThemeDescription")
	desc.BorderSizePixel = 0
	desc.BackgroundTransparency = 1
	desc.FontFace = Constants.Font(Enum.FontWeight.Medium)
	desc.TextSize = 11
	desc.TextColor3 = textColor
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	desc.AnchorPoint = Vector2.new(0, 0.5)
	desc.Size = UDim2.new(1, -28, 0, 14)
	desc.Position = UDim2.fromOffset(14, 61)
	desc.Text = THEME_DESCRIPTIONS[name] or "A cool theme"
	desc.Parent = card

	-- Palette dots over the image, top-right; their rims ride along with the paint.
	local dotsHolder = Instance.new("Frame")
	dotsHolder.Name = UUID.Static("PaletteDots")
	dotsHolder.BorderSizePixel = 0
	dotsHolder.BackgroundColor3 = white
	dotsHolder.BackgroundTransparency = 1
	dotsHolder.AnchorPoint = Vector2.new(1, 0)
	dotsHolder.Position = UDim2.new(1, -14, 0, 14)
	dotsHolder.Size = UDim2.fromOffset(45, 9)
	dotsHolder.Parent = card

	local dotsLayout = Instance.new("UIListLayout")
	dotsLayout.FillDirection = Enum.FillDirection.Horizontal
	dotsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	dotsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	dotsLayout.Padding = UDim.new(0, 3)
	dotsLayout.Parent = dotsHolder

	local dots = {}
	local dotRims = {}
	local palette = {
		theme.PrimaryColor or white,
		theme.SecondaryColor or white,
		theme.TertiaryColor or white,
		accent,
	}
	for i, color in ipairs(palette) do
		local dot = Instance.new("Frame")
		dot.Name = UUID.Generate("ThemeDot")
		dot.BorderSizePixel = 0
		dot.BackgroundColor3 = color
		dot.Size = UDim2.fromOffset(9, 9)
		dot.LayoutOrder = i
		dot.Parent = dotsHolder

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(0.5, 0)
		dotCorner.Parent = dot

		local dotRim = Instance.new("UIStroke")
		dotRim.Color = white
		dotRim.Transparency = 0.75
		dotRim.Thickness = 1
		dotRim.Parent = dot

		table.insert(dots, dot)
		table.insert(dotRims, dotRim)
	end

	-- Hover lift: a white veil that only exists under the cursor.
	local lift = Instance.new("Frame")
	lift.Name = UUID.Static("CardLift")
	lift.BorderSizePixel = 0
	lift.BackgroundColor3 = white
	lift.BackgroundTransparency = 1
	lift.Size = UDim2.fromScale(1, 1)
	lift.Parent = card

	local liftCorner = Instance.new("UICorner")
	liftCorner.CornerRadius = UDim.new(0, CARD_RADIUS)
	liftCorner.Parent = lift

	-- Rim: inactive = white top-edge ramp, active = flat accent (design-notes 1).
	-- Border mode because the card itself is a TextButton (contextual = text outline).
	local stroke = Instance.new("UIStroke")
	stroke.Color = white
	stroke.Transparency = 1
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = card

	local rim = Instance.new("UIGradient")
	rim.Rotation = 90
	rim.Transparency = ramp({ { 0, 0.84 }, { 0.22, 0.95 }, { 0.4, 1 }, { 1, 1 } })
	rim.Parent = stroke

	local hovered = false
	local primed = false

	local function scaleTarget()
		return hovered and 1.035 or 1
	end

	-- The glow is the expensive layer, so it switches off once faded out.
	local function applyShadow(target, instant, info)
		if instant then
			shadow.Transparency = target
			shadow.Enabled = target < 1
			return
		end
		if target < 1 then
			shadow.Enabled = true
			Tween.Play(shadow, info, { Transparency = target })
		elseif shadow.Transparency < 1 then
			shadow.Enabled = true
			Tween.Play(shadow, info, { Transparency = 1 })
			task.delay(0.25, function()
				if shadow.Parent and shadow.Transparency > 0.99 then
					local resting = active and 0.45 or (hovered and 0.35 or 1)
					if resting >= 1 then
						shadow.Enabled = false
					end
				end
			end)
		end
	end

	-- Resting state for every layer. `instant` stamps (theme sweep); otherwise
	-- `info` paces the tween — the reveal passes SETTLE so it rides the cascade.
	local function paint(instant, info)
		info = info or "Fast"
		local function apply(inst, prop, value)
			if instant then
				inst[prop] = value
			else
				Tween.Play(inst, info, { [prop] = value })
			end
		end

		apply(title, "TextTransparency", math.max(0, (active and 0.15 or 0.5) - (hovered and 0.15 or 0)))
		apply(desc, "TextTransparency", math.max(0, (active and 0.35 or 0.55) - (hovered and 0.1 or 0)))
		apply(image, "ImageTransparency", math.max(0, (active and 0.2 or 0.4) - (hovered and 0.12 or 0)))
		local dotT = math.max(0, (active and 0.1 or 0.45) - (hovered and 0.1 or 0))
		for i, dot in ipairs(dots) do
			apply(dot, "BackgroundTransparency", dotT)
			apply(dotRims[i], "Transparency", 0.75)
		end
		apply(lift, "BackgroundTransparency", hovered and 0.95 or 1)

		-- The rim swap can't interpolate: colour + gradient land instantly, only
		-- the transparency joins the tween (fading up from prime's 1).
		if active then
			rim.Parent = nil
			stroke.Color = accent
		else
			stroke.Color = white
			rim.Parent = stroke
		end
		apply(stroke, "Transparency", active and 0.55 or 0)

		applyShadow(active and 0.45 or (hovered and 0.35 or 1), instant, info)
	end

	-- Prime hides everything the reveal brings back, so each page entry has
	-- distance to cascade over (design-notes 4). Input is off while primed so
	-- an invisible card can't be clicked mid-cascade.
	local function prime()
		primed = true
		Tween.CancelAllUnder(card)
		card.Active = false
		fill.BackgroundTransparency = 1
		scrim.BackgroundTransparency = 1
		image.ImageTransparency = 1
		title.TextTransparency = 1
		desc.TextTransparency = 1
		for _, dot in ipairs(dots) do
			dot.BackgroundTransparency = 1
		end
		for _, dotRim in ipairs(dotRims) do
			dotRim.Transparency = 1
		end
		lift.BackgroundTransparency = 1
		stroke.Transparency = 1
		shadow.Transparency = 1
		shadow.Enabled = false
		scale.Scale = 0.96
	end

	local function reveal()
		if not card.Parent then
			return
		end
		primed = false
		card.Active = true
		Tween.Play(fill, SETTLE, { BackgroundTransparency = 0 })
		Tween.Play(scrim, SETTLE, { BackgroundTransparency = 0 })
		paint(false, SETTLE)
		Tween.Play(scale, SETTLE, { Scale = scaleTarget() })
	end

	local function setActive(isActive)
		active = isActive
		if primed then
			return
		end
		paint(false)
	end

	local function hover(on)
		hovered = on
		if primed then
			return
		end
		Tween.Play(scale, on and "HoverIn" or "HoverOut", { Scale = scaleTarget() })
		paint(false)
	end

	card.MouseButton1Click:Connect(function()
		onActivate(name)
	end)
	card.MouseEnter:Connect(function()
		hover(true)
	end)
	card.MouseLeave:Connect(function()
		hover(false)
	end)
	card.MouseButton1Down:Connect(function()
		if primed then
			return
		end
		Tween.Play(scale, "Fast", { Scale = 0.97 })
	end)
	card.MouseButton1Up:Connect(function()
		if primed then
			return
		end
		Tween.Play(scale, "HoverIn", { Scale = scaleTarget() })
	end)

	-- A theme switch sweeps CancelAllUnder the window, which could freeze a
	-- mid-flight card half-faded; re-stamp the resting state afterwards.
	-- Primed cards stay hidden — their reveal owns the paint.
	ThemeManager.OnThemeApplied(function()
		if primed then
			return
		end
		fill.BackgroundTransparency = 0
		scrim.BackgroundTransparency = 0
		paint(true)
		scale.Scale = scaleTarget()
	end, card)

	paint(true)

	return {
		setActive = setActive,
		prime = prime,
		reveal = reveal,
	}
end

function Themes.Build(window, tab)
	local page = tab.Page
	local pageTheme = ThemeManager.GetTheme(tab._theme)

	-- fixed proportion the rest of the settings layout assumes
	page.Size = UDim2.fromScale(1, 0.87857)
	page.Position = UDim2.fromScale(0.5, 0.561)
	page.AnchorPoint = Vector2.new(0.5, 0.5)

	local pageTitle = Instance.new("TextLabel")
	pageTitle.Name = UUID.Static("ThemePageText")
	pageTitle.TextWrapped = true
	pageTitle.TextTruncate = Enum.TextTruncate.AtEnd
	pageTitle.BorderSizePixel = 0
	pageTitle.TextSize = 14
	pageTitle.TextXAlignment = Enum.TextXAlignment.Left
	pageTitle.TextTransparency = 0.3
	pageTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	pageTitle.BackgroundTransparency = 1
	pageTitle.FontFace = Constants.Font(Enum.FontWeight.Bold)
	pageTitle.TextColor3 = pageTheme.TitleTextColor or Color3.fromRGB(255, 255, 255)
	pageTitle.Size = UDim2.fromScale(0, 0.06849)
	pageTitle.AutomaticSize = Enum.AutomaticSize.X
	pageTitle.Text = "Native themes"
	pageTitle.Position = UDim2.fromScale(0, 0)
	pageTitle.Parent = page

	-- Ghost chip: names the current theme on the title line, right-aligned.
	local chip = Instance.new("Frame")
	chip.Name = UUID.Static("CurrentThemeChip")
	chip.BorderSizePixel = 0
	chip.AnchorPoint = Vector2.new(1, 0.5)
	chip.Position = UDim2.fromScale(1, 0.034245)
	chip.Size = UDim2.fromOffset(0, 20)
	chip.AutomaticSize = Enum.AutomaticSize.X
	chip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	chip.BackgroundTransparency = 1
	chip.Parent = page

	local chipCorner = Instance.new("UICorner")
	chipCorner.CornerRadius = UDim.new(0.5, 0)
	chipCorner.Parent = chip

	local chipStroke = Instance.new("UIStroke")
	chipStroke.Color = pageTheme.TitleTextColor or Color3.fromRGB(255, 255, 255)
	chipStroke.Transparency = 0.88
	chipStroke.Thickness = 1
	chipStroke.Parent = chip

	local chipPad = Instance.new("UIPadding")
	chipPad.PaddingLeft = UDim.new(0, 10)
	chipPad.PaddingRight = UDim.new(0, 12)
	chipPad.Parent = chip

	local chipLayout = Instance.new("UIListLayout")
	chipLayout.FillDirection = Enum.FillDirection.Horizontal
	chipLayout.SortOrder = Enum.SortOrder.LayoutOrder
	chipLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	chipLayout.Padding = UDim.new(0, 6)
	chipLayout.Parent = chip

	local chipDot = Instance.new("Frame")
	chipDot.Name = UUID.Static("CurrentThemeDot")
	chipDot.BorderSizePixel = 0
	chipDot.BackgroundColor3 = pageTheme.AccentColor or Color3.fromRGB(120, 156, 210)
	chipDot.Size = UDim2.fromOffset(8, 8)
	chipDot.LayoutOrder = 1
	chipDot.Parent = chip

	local chipDotCorner = Instance.new("UICorner")
	chipDotCorner.CornerRadius = UDim.new(0.5, 0)
	chipDotCorner.Parent = chipDot

	local chipName = Instance.new("TextLabel")
	chipName.Name = UUID.Static("CurrentThemeName")
	chipName.BorderSizePixel = 0
	chipName.BackgroundTransparency = 1
	chipName.FontFace = Constants.Font(Enum.FontWeight.Bold)
	chipName.TextSize = 11
	chipName.TextColor3 = pageTheme.TitleTextColor or Color3.fromRGB(255, 255, 255)
	chipName.TextXAlignment = Enum.TextXAlignment.Left
	chipName.Size = UDim2.fromOffset(0, 14)
	chipName.AutomaticSize = Enum.AutomaticSize.X
	chipName.Text = "Umbral"
	chipName.LayoutOrder = 2
	chipName.Parent = chip

	local function setChip(name)
		chipName.Text = name
		local t = ThemeManager.GetTheme(name)
		chipDot.BackgroundColor3 = t.AccentColor or t.PrimaryColor or Color3.fromRGB(120, 156, 210)
	end

	-- scrolling container for the cards; ThemeManager's ScrollingFrame pass
	-- re-colors its scrollbar on theme switch
	local pageHolder = Instance.new("ScrollingFrame")
	pageHolder.Name = UUID.Static("PageHolder")
	pageHolder.BorderSizePixel = 0
	pageHolder.BackgroundColor3 = pageTheme.SectionBackgroundColor
	pageHolder.BackgroundTransparency = 1
	pageHolder.Size = UDim2.fromScale(1, 0.91)
	pageHolder.Position = UDim2.fromScale(0, 0.09)
	pageHolder.CanvasSize = UDim2.fromScale(0, 0)
	pageHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pageHolder.ScrollingDirection = Enum.ScrollingDirection.Y
	pageHolder.ScrollBarThickness = 1
	pageHolder.ScrollBarImageColor3 = pageTheme.TertiaryColor
	pageHolder.ScrollBarImageTransparency = 1
	pageHolder.Parent = page

	local holderScrollbarTimer
	pageHolder:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		Tween.Play(pageHolder, "Fast", { ScrollBarImageTransparency = 0.5 })
		if holderScrollbarTimer then
			task.cancel(holderScrollbarTimer)
		end
		holderScrollbarTimer = task.delay(1.5, function()
			Tween.Play(pageHolder, "Fast", { ScrollBarImageTransparency = 1 })
			holderScrollbarTimer = nil
		end)
	end)

	local holderPadding = Instance.new("UIPadding")
	holderPadding.PaddingTop = UDim.new(0, 10)
	holderPadding.PaddingBottom = UDim.new(0, 20)
	-- side padding keeps hover-scaled cards and shadows from clipping
	holderPadding.PaddingLeft = UDim.new(0, 10)
	holderPadding.PaddingRight = UDim.new(0, 10)
	holderPadding.Parent = pageHolder

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(CARD_W, CARD_H)
	grid.CellPadding = UDim2.fromOffset(17, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.VerticalAlignment = Enum.VerticalAlignment.Top
	grid.Parent = pageHolder

	local ordered = {}
	local seen = {}
	for _, name in ipairs(THEME_ORDER) do
		if ThemeDefinitions[name] then
			table.insert(ordered, name)
			seen[name] = true
		end
	end
	for name in pairs(ThemeDefinitions) do
		if not seen[name] and name ~= "Base" then
			table.insert(ordered, name)
		end
	end

	tab._themeCards = {}
	tab._activeThemeName = window._themeName or ThemeManager.DefaultTheme

	local function setActive(newName)
		if tab._activeThemeName == newName then
			return
		end
		local oldName = tab._activeThemeName
		tab._activeThemeName = newName
		if oldName and tab._themeCards[oldName] then
			tab._themeCards[oldName].setActive(false)
		end
		if tab._themeCards[newName] then
			tab._themeCards[newName].setActive(true)
		end
		setChip(newName)
		window:SetTheme(newName)
	end

	local cardStates = {}
	for i, name in ipairs(ordered) do
		local theme = ThemeManager.GetTheme(name)
		local isActive = (name == tab._activeThemeName)
		local state = makeCard(pageHolder, name, theme, isActive, i, setActive)
		tab._themeCards[name] = state
		table.insert(cardStates, state)
	end

	-- follows the active theme even when it isn't in the ordered list
	setChip(tab._activeThemeName)

	-- Reveal cascade: each visit re-primes the grid and staggers the cards back
	-- in; leaving mid-cascade bumps the token so stale reveals can't fire.
	local cascadeToken = 0
	PageAwareness.Register(page, {
		OnActive = function()
			cascadeToken += 1
			local token = cascadeToken
			for i, state in ipairs(cardStates) do
				state.prime()
				task.delay(math.min(i * 0.035, 0.3), function()
					if token == cascadeToken then
						state.reveal()
					end
				end)
			end
		end,
		OnInactive = function(instant)
			cascadeToken += 1
			if instant then
				for _, state in ipairs(cardStates) do
					state.prime()
				end
			end
		end,
	})

	-- header texts and scrollbar follow the theme; the cards themselves are
	-- left alone, since each previews a specific theme's colors
	local themesPageComponent = {}
	function themesPageComponent:ApplyTheme(newTheme)
		local t = ThemeManager.GetTheme(newTheme)
		pageTitle.TextColor3 = t.TitleTextColor or pageTitle.TextColor3
		chipStroke.Color = t.TitleTextColor or chipStroke.Color
		chipName.TextColor3 = t.TitleTextColor or chipName.TextColor3
		pageHolder.ScrollBarImageColor3 = t.TertiaryColor or pageHolder.ScrollBarImageColor3

		-- External switches (API, config) skip the card click path, so re-sync
		-- the chip and highlight from the window's theme here.
		local name = window._themeName
		if type(name) == "string" and name ~= tab._activeThemeName then
			local oldName = tab._activeThemeName
			tab._activeThemeName = name
			if oldName and tab._themeCards[oldName] then
				tab._themeCards[oldName].setActive(false)
			end
			if tab._themeCards[name] then
				tab._themeCards[name].setActive(true)
			end
			setChip(name)
		end
	end
	ThemeManager.Register(page, themesPageComponent)

	return page
end

return Themes
