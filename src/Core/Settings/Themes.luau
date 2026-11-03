--[[
	Aetheris/Core/Settings/Themes.luau

	Builds the "Themes" page as a grid of theme cards. Each card previews its
	theme's wallpaper, swatches and accent strokes, and reflects active/inactive
	state through transparency. THEME_ORDER sets the render order.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeDefinitions = require("../../Themes/ThemeDefinitions")
local ThemeManager = require("../../Themes/ThemeManager")
local FallbackImage = require("../../Constants").FallbackImage
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
}

local function makeCard(parent, name, theme, active, onActivate)
	local card = Instance.new("TextButton")
	card.Name = UUID.Generate("ThemeCard")
	card.BorderSizePixel = 0
	card.AutoButtonColor = false
	card.BackgroundColor3 = theme.WindowColor or Color3.fromRGB(16, 16, 17)
	card.BackgroundTransparency = 0
	card.Size = UDim2.fromScale(0.29, 0.266)
	card.Text = ""
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = card

	local shadow = Instance.new("UIShadow")
	shadow.BlurRadius = UDim.new(0, 18)
	shadow.Transparency = active and 0.45 or 1
	shadow.Enabled = active
	shadow.Color = theme.AccentColor or theme.PrimaryColor or Color3.fromRGB(120, 156, 210)
	shadow.Parent = card

	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.AccentColor or theme.PrimaryColor or Color3.fromRGB(120, 156, 210)
	stroke.Transparency = active and 0.55 or 1
	stroke.Enabled = active
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = card

	local divider = Instance.new("Frame")
	divider.Name = UUID.Static("Divider")
	divider.BorderSizePixel = 0
	divider.BackgroundColor3 = theme.TertiaryColor or Color3.fromRGB(150, 150, 150)
	divider.BackgroundTransparency = active and 0.72 or 0.9
	divider.AnchorPoint = Vector2.new(0.5, 0.5)
	divider.Size = UDim2.new(0, 1, 0.7, 0)
	divider.Position = UDim2.fromScale(0.5, 0.5)
	divider.Parent = card

	local colorHolder = Instance.new("Frame")
	colorHolder.Name = UUID.Static("ThemeColorHolder")
	colorHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	colorHolder.Size = UDim2.fromScale(0.35342, 0.56731)
	colorHolder.Position = UDim2.fromScale(0.73333, 0.5)
	colorHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	colorHolder.BackgroundTransparency = 1
	colorHolder.Parent = card

	local colorGrid = Instance.new("UIGridLayout")
	colorGrid.CellSize = UDim2.fromOffset(20, 20)
	colorGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	colorGrid.VerticalAlignment = Enum.VerticalAlignment.Center
	colorGrid.SortOrder = Enum.SortOrder.LayoutOrder
	colorGrid.Parent = colorHolder

	local swatches = {}
	local swatchScales = {}
	local swatchDefs = {
		{ "PrimaryColor", theme.PrimaryColor },
		{ "SecondaryColor", theme.SecondaryColor },
		{ "TertiaryColor", theme.TertiaryColor },
		{ "AccentColor", theme.AccentColor },
	}
	for i, def in ipairs(swatchDefs) do
		local swatch = Instance.new("Frame")
		swatch.Name = UUID.Generate("ThemeSwatch")
		swatch.LayoutOrder = i
		swatch.Size = UDim2.fromOffset(26, 18)
		swatch.BackgroundColor3 = def[2] or Color3.fromRGB(255, 255, 255)
		swatch.BackgroundTransparency = active and 0 or 0.5
		swatch.Parent = colorHolder

		local swCorner = Instance.new("UICorner")
		swCorner.CornerRadius = UDim.new(0, 4)
		swCorner.Parent = swatch

		local swScale = Instance.new("UIScale")
		swScale.Scale = 1
		swScale.Parent = swatch

		swatches[def[1]] = swatch
		swatchScales[def[1]] = swScale
	end

	local backImage = Instance.new("ImageLabel")
	backImage.Name = UUID.Static("BackImage")
	backImage.BorderSizePixel = 0
	backImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	backImage.BackgroundTransparency = 1
	backImage.Image = theme.Wallpaper or FallbackImage
	backImage.ImageTransparency = active and 0.5 or 0.7
	backImage.AnchorPoint = Vector2.new(0.5, 0.5)
	backImage.Position = UDim2.fromScale(0.5, 0.5)
	backImage.Size = UDim2.fromScale(1, 1)
	backImage.ScaleType = Enum.ScaleType.Stretch
	backImage.Parent = card

	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 6)
	backCorner.Parent = backImage

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 180
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.000, 0),
		NumberSequenceKeypoint.new(0.044, 0.1625),
		NumberSequenceKeypoint.new(0.087, 0.34375),
		NumberSequenceKeypoint.new(0.119, 0.475),
		NumberSequenceKeypoint.new(0.171, 0.625),
		NumberSequenceKeypoint.new(0.230, 0.73125),
		NumberSequenceKeypoint.new(0.286, 0.80625),
		NumberSequenceKeypoint.new(0.351, 0.875),
		NumberSequenceKeypoint.new(0.441, 0.93125),
		NumberSequenceKeypoint.new(0.533, 0.9625),
		NumberSequenceKeypoint.new(0.681, 0.975),
		NumberSequenceKeypoint.new(1.000, 1),
	})
	gradient.Parent = backImage

	local title = Instance.new("TextLabel")
	title.Name = UUID.Static("ThemeTitle")
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTransparency = active and 0.2 or 0.5
	title.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	title.TextColor3 = theme.TitleTextColor or theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.AnchorPoint = Vector2.new(0, 0.5)
	title.Size = UDim2.new(0.49333, -20, 0, 18)
	title.Position = UDim2.new(0, 7, 0.43269, 0)
	title.Text = name
	title.Parent = card

	local description = Instance.new("TextLabel")
	description.Name = UUID.Static("ThemeDescription")
	description.TextSize = 9
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.TextTransparency = 0.5
	description.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	description.TextColor3 = theme.TitleTextColor or theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
	description.BackgroundTransparency = 1
	description.AnchorPoint = Vector2.new(0, 0.5)
	description.Size = UDim2.new(0.49333, -20, -0.07212, 18)
	description.Position = UDim2.new(0, 7, 0.59856, 0)
	description.Text = THEME_DESCRIPTIONS[name] or "A cool theme"
	description.Parent = card

	local hovered = false

	local function hover(on)
		hovered = on
		Tween.Play(scale, on and "HoverIn" or "HoverOut", { Scale = on and 1.035 or 1 })
		if on then
			stroke.Enabled = true
			Tween.Play(stroke, "Fast", { Transparency = 0.3 })
		else
			Tween.Play(stroke, "Fast", { Transparency = active and 0.55 or 1 })
			if not active then
				task.delay(0.25, function()
					if stroke.Parent and not active and not hovered and stroke.Transparency > 0.99 then
						stroke.Enabled = false
					end
				end)
			end
		end
		Tween.Play(backImage, "Fast", {
			ImageTransparency = on and (active and 0.4 or 0.6) or (active and 0.5 or 0.7),
		})
		if on then
			shadow.Enabled = true
			Tween.Play(shadow, "Fast", { Transparency = 0.35 })
		else
			Tween.Play(shadow, "Fast", { Transparency = active and 0.45 or 1 })
			if not active then
				task.delay(0.25, function()
					if shadow.Parent and not active and not hovered and shadow.Transparency > 0.99 then
						shadow.Enabled = false
					end
				end)
			end
		end
		for i, def in ipairs(swatchDefs) do
			local sw = swatches[def[1]]
			if sw then
				Tween.Play(sw, TweenInfo.new(0.18 + i * 0.015, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = on and 0.15 or (active and 0 or 0.5),
				})
			end
			local swScale = swatchScales[def[1]]
			if swScale then
				Tween.Play(swScale, "HoverIn", { Scale = on and 1.12 or 1 })
			end
		end
	end

	local function refresh(instant)
		local function apply(inst, props)
			if instant then
				for prop, value in pairs(props) do
					inst[prop] = value
				end
			else
				Tween.Play(inst, "Fast", props)
			end
		end
		apply(title, { TextTransparency = active and 0.2 or 0.5 })
		apply(backImage, { ImageTransparency = active and 0.5 or 0.7 })
		apply(divider, { BackgroundTransparency = active and 0.72 or 0.9 })
		if instant then
			shadow.Transparency = active and 0.45 or 1
			shadow.Enabled = active
			stroke.Transparency = active and 0.55 or 1
			stroke.Enabled = active
		else
			shadow.Enabled = true
			Tween.Play(shadow, "Fast", { Transparency = active and 0.45 or 1 })
			stroke.Enabled = true
			Tween.Play(stroke, "Fast", { Transparency = active and 0.55 or 1 })
			if not active then
				task.delay(0.25, function()
					if not active and not hovered then
						if shadow.Parent and shadow.Transparency > 0.99 then
							shadow.Enabled = false
						end
						if stroke.Parent and stroke.Transparency > 0.99 then
							stroke.Enabled = false
						end
					end
				end)
			end
		end
		for _, sw in pairs(swatches) do
			apply(sw, { BackgroundTransparency = active and 0 or 0.5 })
		end
	end

	local function setActive(isActive)
		active = isActive
		refresh(false)
		if hovered then
			hover(true)
		end
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
		Tween.Play(scale, "Fast", { Scale = 0.97 })
	end)
	card.MouseButton1Up:Connect(function()
		Tween.Play(scale, "HoverIn", { Scale = hovered and 1.035 or 1 })
	end)

	-- ApplyTheme cancels every in-flight tween under the window, which could
	-- freeze a mid-fade stroke/shadow. Re-stamp the resting state afterwards.
	ThemeManager.OnThemeApplied(function()
		refresh(true)
		if hovered then
			hover(true)
		end
	end, card)

	refresh(true)

	return {
		card = card,
		title = title,
		backImage = backImage,
		divider = divider,
		swatches = swatches,
		stroke = stroke,
		shadow = shadow,
		scale = scale,
		setActive = setActive,
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
	pageTitle.TextSize = 15
	pageTitle.TextXAlignment = Enum.TextXAlignment.Left
	pageTitle.TextTransparency = 0.4
	pageTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	pageTitle.BackgroundTransparency = 1
	pageTitle.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	pageTitle.TextColor3 = pageTheme.TitleTextColor or Color3.fromRGB(255, 255, 255)
	pageTitle.RichText = true
	pageTitle.Size = UDim2.fromScale(0, 0.06849)
	pageTitle.AutomaticSize = Enum.AutomaticSize.X
	pageTitle.Text = "Native themes"
	pageTitle.Position = UDim2.fromScale(0, 0)
	pageTitle.Parent = page

	-- scrolling container for the cards; ThemeManager's ScrollingFrame pass
	-- re-colors its scrollbar on theme switch
	local pageHolder = Instance.new("ScrollingFrame")
	pageHolder.Name = UUID.Static("PageHolder")
	pageHolder.BorderSizePixel = 0
	pageHolder.BackgroundColor3 = pageTheme.SectionBackgroundColor
	pageHolder.BackgroundTransparency = 1
	pageHolder.Size = UDim2.fromScale(1, 0.89)
	pageHolder.Position = UDim2.fromScale(0, 0.11)
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
	grid.CellSize = UDim2.fromOffset(145, 75)
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

	local currentText = Instance.new("TextLabel")
	currentText.Name = UUID.Static("CurrentThemeText")
	currentText.TextWrapped = true
	currentText.TextTruncate = Enum.TextTruncate.AtEnd
	currentText.BorderSizePixel = 0
	currentText.TextSize = 10
	currentText.TextXAlignment = Enum.TextXAlignment.Left
	currentText.TextTransparency = 0.5
	currentText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	currentText.BackgroundTransparency = 1
	currentText.FontFace = Constants.Font(Enum.FontWeight.Regular)
	currentText.TextColor3 = pageTheme.TitleTextColor or Color3.fromRGB(255, 255, 255)
	currentText.RichText = true
	currentText.Size = UDim2.fromScale(0.32573, 0.03814)
	currentText.AutomaticSize = Enum.AutomaticSize.X
	currentText.Text = "<b>Current theme:</b> Light"
	currentText.Position = UDim2.fromScale(0, 0.06)
	currentText.Parent = page

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
		currentText.Text = "<b>Current theme:</b> " .. newName
		window:SetTheme(newName)
	end

	for _, name in ipairs(ordered) do
		local theme = ThemeManager.GetTheme(name)
		local active = (name == tab._activeThemeName)
		local state = makeCard(pageHolder, name, theme, active, setActive)
		tab._themeCards[name] = state
	end

	-- fallback when the active theme isn't in the ordered list
	currentText.Text = "<b>Current theme:</b> " .. tab._activeThemeName

	-- header texts and scrollbar follow the theme; the cards themselves are
	-- left alone, since each previews a specific theme's colors
	local themesPageComponent = {}
	function themesPageComponent:ApplyTheme(newTheme)
		local t = ThemeManager.GetTheme(newTheme)
		pageTitle.TextColor3 = t.TitleTextColor or pageTitle.TextColor3
		currentText.TextColor3 = t.TitleTextColor or currentText.TextColor3
		pageHolder.ScrollBarImageColor3 = t.TertiaryColor or pageHolder.ScrollBarImageColor3
	end
	ThemeManager.Register(page, themesPageComponent)

	return page
end

return Themes
