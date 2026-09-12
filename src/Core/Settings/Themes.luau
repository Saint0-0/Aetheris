--[[
	Themes (settings page)  ·  Aetheris UI Library

	Builds the "Themes" page as a grid of theme cards. Each card uses the
	theme's WindowColor background, shows Primary/Secondary/Tertiary/Accent
	swatches plus a wallpaper backdrop, and reflects the active/inactive state
	through BackImage / ThemeTitle / Divider transparencies. THEME_ORDER sets
	the render order; the active card is marked from window._themeName.
]]

local ThemeDefinitions = require("../../Themes/ThemeDefinitions")
local ThemeManager = require("../../Themes/ThemeManager")
local FallbackImage = require("../../Constants").FallbackImage
local Tween = require("../../Utils/Tween")

local Themes = {}

local THEME_ORDER = {
	"Default",
	"Black",
	"Light",
	"Midnight",
	"Graphite",
	"Pearl",
	"Slate",
	"Ocean",
	"Nord",
	"Forest",
	"Amethyst",
	"Rose",
	"Retro",
	"Glass",
	"Porcelain",
	"Mist",
	"Sandstone",
	"Dusk",
	"Frost",
	"Azure",
	"Fjord",
	"Summit",
	"Blossom",
}

-- Short (card-sized) descriptions, one per theme.
local THEME_DESCRIPTIONS = {
	Default = "Balanced slate",
	Black = "OLED black",
	Light = "Clean & bright",
	Midnight = "Deep indigo",
	Graphite = "Cool gray teal",
	Pearl = "Warm and soft",
	Slate = "Cool blue-gray",
	Ocean = "Deep navy blue",
	Nord = "Arctic frost",
	Forest = "Deep forest",
	Amethyst = "Royal purple",
	Rose = "Soft plum pink",
	Retro = "Warm vintage",
	Glass = "Frosted glass",
	Porcelain = "Crisp and clean",
	Mist = "Frosted light",
	Sandstone = "Warm neutral",
	Dusk = "Plum twilight",
	Frost = "Icy blue-gray",
	Azure = "Deep mountain blue",
	Fjord = "Muted blue-grey",
	Summit = "Crisp alpine",
	Blossom = "Soft pink",
}

local function makeCard(parent, name, theme, active, onActivate)
	local card = Instance.new("TextButton")
	card.Name = name
	card.BorderSizePixel = 0
	card.AutoButtonColor = false
	card.BackgroundColor3 = theme.WindowColor or Color3.fromRGB(16, 16, 17)
	card.BackgroundTransparency = 0
	card.Size = UDim2.new(0.29, 0 ,0.266, 0)
	card.Text = ""
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = card

	local shadow = Instance.new("UIShadow")
	shadow.Parent = card

	-- Vertical divider reflects TertiaryColor (used for scrollbars etc.)
	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.BorderSizePixel = 0
	divider.BackgroundColor3 = theme.TertiaryColor or Color3.fromRGB(150, 150, 150)
	divider.BackgroundTransparency = active and 0.72 or 0.9
	divider.AnchorPoint = Vector2.new(0.5, 0.5)
	divider.Size = UDim2.new(0, 1, 0.7, 0)
	divider.Position = UDim2.new(0.5, 0, 0.5, 0)
	divider.Parent = card

	-- 2x2 color swatch holder
	local colorHolder = Instance.new("Frame")
	colorHolder.Name = "ThemeColorHolder"
	colorHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	colorHolder.Size = UDim2.new(0.35342, 0, 0.56731, 0)
	colorHolder.Position = UDim2.new(0.73333, 0, 0.5, 0)
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
	local swatchDefs = {
		{ "PrimaryColor", theme.PrimaryColor },
		{ "SecondaryColor", theme.SecondaryColor },
		{ "TertiaryColor", theme.TertiaryColor },
		{ "AccentColor", theme.AccentColor },
	}
	for i, def in ipairs(swatchDefs) do
		local swatch = Instance.new("Frame")
		swatch.Name = def[1]
		swatch.LayoutOrder = i
		swatch.Size = UDim2.fromOffset(26, 18)
		swatch.BackgroundColor3 = def[2] or Color3.fromRGB(255, 255, 255)
		swatch.BackgroundTransparency = active and 0 or 0.5
		swatch.Parent = colorHolder

		local swCorner = Instance.new("UICorner")
		swCorner.CornerRadius = UDim.new(0, 4)
		swCorner.Parent = swatch

		local swShadow = Instance.new("UIShadow")
		swShadow.Parent = swatch

		swatches[def[1]] = swatch
	end

	-- Wallpaper backdrop
	local backImage = Instance.new("ImageLabel")
	backImage.Name = "BackImage"
	backImage.BorderSizePixel = 0
	backImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	backImage.BackgroundTransparency = 1
	backImage.Image = theme.Wallpaper or FallbackImage
	backImage.ImageTransparency = active and 0.5 or 0.7
	backImage.AnchorPoint = Vector2.new(0.5, 0.5)
	backImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	backImage.Size = UDim2.fromScale(1, 1)
	backImage.ScaleType = Enum.ScaleType.Stretch
	backImage.Parent = card

	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 6)
	backCorner.Parent = backImage

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 180
	gradient.Transparency = NumberSequence.new{
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
	}
	gradient.Parent = backImage

	-- Theme title (active cards use lower transparency)
	local title = Instance.new("TextLabel")
	title.Name = "ThemeTitle"
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTransparency = active and 0.2 or 0.5
	title.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	title.TextColor3 = theme.TitleTextColor or theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.AnchorPoint = Vector2.new(0, 0.5)
	title.Size = UDim2.new(0.49333, -20, 0, 18)
	title.Position = UDim2.new(0, 7, 0.43269, 0)
	title.Text = name
	title.Parent = card

	-- Theme description
	local description = Instance.new("TextLabel")
	description.Name = "ThemeDescription"
	description.TextSize = 9
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.TextTransparency = 0.5
	description.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	description.TextColor3 = theme.TitleTextColor or theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
	description.BackgroundTransparency = 1
	description.AnchorPoint = Vector2.new(0, 0.5)
	description.Size = UDim2.new(0.49333, -20, -0.07212, 18)
	description.Position = UDim2.new(0, 7, 0.59856, 0)
	description.Text = THEME_DESCRIPTIONS[name] or "A cool theme"
	description.Parent = card

	card.MouseButton1Click:Connect(function()
		onActivate(name)
	end)

	return {
		card = card,
		title = title,
		backImage = backImage,
		divider = divider,
		swatches = swatches,
	}
end

function Themes.Build(window, tab)
	local page = tab.Page
	local pageTheme = ThemeManager.GetTheme(tab._theme)

	-- The Themes page uses the template's proportion: {1,0},{0.879,0}.
	page.Size = UDim2.new(1, 0, 0.87857, 0)
	page.Position = UDim2.new(0.5, 0, 0.561, 0)
	page.AnchorPoint = Vector2.new(0.5, 0.5)
	
	--ui constraint for page
	--local pageUIConstraint = Instance.new("UISizeConstraint")
	--pageUIConstraint.MinSize = Vector2.new(535, 340)
	--pageUIConstraint.Parent = page

	-- Page title
	local pageTitle = Instance.new("TextLabel")
	pageTitle.Name = "ThemePageText"
	pageTitle.TextWrapped = true
	pageTitle.TextTruncate = Enum.TextTruncate.AtEnd
	pageTitle.BorderSizePixel = 0
	pageTitle.TextSize = 15
	pageTitle.TextXAlignment = Enum.TextXAlignment.Left
	pageTitle.TextTransparency = 0.4
	pageTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	pageTitle.BackgroundTransparency = 1
	pageTitle.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	pageTitle.TextColor3 = pageTheme.TitleTextColor or Color3.fromRGB(255, 255, 255)
	pageTitle.RichText = true
	pageTitle.Size = UDim2.new(0, 0, 0.06849, 0)
	pageTitle.AutomaticSize = Enum.AutomaticSize.X
	pageTitle.Text = "Native themes"
	pageTitle.Position = UDim2.new(0, 0, 0, 0)
	pageTitle.Parent = page

	-- PageHolder: a scrolling container for the theme cards, sitting below
	-- the fixed header. It matches the rest of the UI (thin scrollbar in the
	-- theme's tertiary color, hidden until the user scrolls) and is
	-- re-colored on theme switch by ThemeManager's ScrollingFrame pass.
	local pageHolder = Instance.new("ScrollingFrame")
	pageHolder.Name = "PageHolder"
	pageHolder.BorderSizePixel = 0
	pageHolder.BackgroundColor3 = pageTheme.SectionBackgroundColor
	pageHolder.BackgroundTransparency = 1
	pageHolder.Size = UDim2.new(1, 0, 0.89, 0)
	pageHolder.Position = UDim2.new(0, 0, 0.11, 0)
	pageHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	pageHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pageHolder.ScrollingDirection = Enum.ScrollingDirection.Y
	pageHolder.ScrollBarThickness = 1
	pageHolder.ScrollBarImageColor3 = pageTheme.TertiaryColor
	pageHolder.ScrollBarImageTransparency = 1
	pageHolder.Parent = page

	-- Hide the scrollbar until scrolling, mirroring TabList's behaviour.
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
	holderPadding.Parent = pageHolder

	-- Grid lays the theme cards out directly on the scrolling PageHolder.
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(155, 75)
	grid.CellPadding = UDim2.fromOffset(17, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.VerticalAlignment = Enum.VerticalAlignment.Top
	grid.Parent = pageHolder

	-- Build ordered theme list (THEME_ORDER first, then any extras)
	local ordered = {}
	local seen = {}
	for _, name in ipairs(THEME_ORDER) do
		if ThemeDefinitions[name] then
			table.insert(ordered, name)
			seen[name] = true
		end
	end
	for name in pairs(ThemeDefinitions) do
		if not seen[name] then
			table.insert(ordered, name)
		end
	end

	-- Current theme label
	local currentText = Instance.new("TextLabel")
	currentText.Name = "CurrentThemeText"
	currentText.TextWrapped = true
	currentText.TextTruncate = Enum.TextTruncate.AtEnd
	currentText.BorderSizePixel = 0
	currentText.TextSize = 10
	currentText.TextXAlignment = Enum.TextXAlignment.Left
	currentText.TextTransparency = 0.5
	currentText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	currentText.BackgroundTransparency = 1
	currentText.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	currentText.TextColor3 = pageTheme.TitleTextColor or Color3.fromRGB(255, 255, 255)
	currentText.RichText = true
	currentText.Size = UDim2.new(0.32573, 0, 0.03814, 0)
	currentText.AutomaticSize = Enum.AutomaticSize.X
	currentText.Text = "<b>Current theme:</b> Light"
	currentText.Position = UDim2.new(0, 0, 0.06, 0)
	currentText.Parent = page

	-- Store card states and active theme name
	tab._themeCards = {}
	tab._activeThemeName = window._themeName or "Default"

	local function setActive(newName)
		if tab._activeThemeName == newName then
			return
		end
		tab._activeThemeName = newName
		for name, state in pairs(tab._themeCards) do
			local active = (name == newName)
			state.title.TextTransparency = active and 0.2 or 0.5
			state.backImage.ImageTransparency = active and 0.5 or 0.7
			state.divider.BackgroundTransparency = active and 0.72 or 0.9
			for _, sw in pairs(state.swatches) do
				sw.BackgroundTransparency = active and 0 or 0.5
			end
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

	-- Initial current-theme text (in case the active name isn't in the list)
	currentText.Text = "<b>Current theme:</b> " .. tab._activeThemeName

	-- Component-owned theming. The Themes page is a settings page (not a
	-- regular component), but its header texts and card-grid scrollbar must
	-- follow the active theme. Register a small themable wrapper on the page
	-- frame so the registry reaches it without a name-matching pass.
	-- NOTE: the theme CARDS themselves are intentionally left alone - each
	-- card previews a specific theme's colors and must NOT be re-tinted.
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