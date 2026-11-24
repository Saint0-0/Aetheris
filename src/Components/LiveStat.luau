--[[
	Aetheris/Components/LiveStat.luau

	Animated numeric stat card with Full and Compact layouts. Values roll through
	the odometer and tint positive, negative or neutral from the theme accent.
	The surface stays neutral with a soft accent wash, so the card reads as part
	of the page instead of a solid coloured block.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
	Based on Rayfield Gen 2 code (MPL-2.0)
	https://github.com/SiriusSoftwareLtd/rayfield-gen2
]]

local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local ComponentAPI = require("../Utils/ComponentAPI")
local Locale = require("../Utils/Locale")
local Tween = require("../Utils/Tween")
local Odometer = require("../Utils/Odometer")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

local LiveStat = {}
LiveStat.__index = LiveStat

-- 12s per revolution; a shared preset in Utils/Tween.
local SPIN_PRESET = "SpinStat"

local FULL_HEIGHT = 92
local COMPACT_HEIGHT = 42
local FULL_CORNER = 9
local COMPACT_CORNER = 7
local ACCENT_BAR = 3

-- Rising uses the accent; falling rotates that hue to red.
local POS_FALLBACK = Color3.fromRGB(0, 170, 127)

local function lighten(c, t)
	return Color3.new(c.R + (1 - c.R) * t, c.G + (1 - c.G) * t, c.B + (1 - c.B) * t)
end

-- Preserves saturation and value, so a blue accent stays blue-toned.
local function withHue(c, targetHue)
	local _, s, v = Color3.toHSV(c)
	return Color3.fromHSV(targetHue, math.max(s, 0.55), v)
end

-- Memoized: the HSV round trip runs only when the theme changes.
local cachedTheme, cachedAccents
local function accentsFor(theme)
	if theme == cachedTheme and cachedAccents then
		return cachedAccents
	end
	local base = (theme and theme.AccentColor) or POS_FALLBACK
	local pos = { fill = base, stroke = lighten(base, 0.22) }
	local negBase = withHue(base, 0.0) -- hue 0 == red
	local neg = { fill = negBase, stroke = lighten(negBase, 0.22) }
	cachedTheme, cachedAccents = theme, { positive = pos, negative = neg, neutral = pos }
	return cachedAccents
end

-- Static default until _applyAccent swaps in the themed set.
local ACCENT = accentsFor(nil)

-- Comma-grouped integer; a negative rounding to zero shows "0".
local function formatNumber(value)
	if type(value) ~= "number" then
		return tostring(value)
	end
	local rounded = math.round(math.abs(value))
	local s = string.format("%.0f", rounded)
	local grouped = s:reverse():gsub("%d%d%d", "%0,"):reverse()
	if grouped:sub(1, 1) == "," then
		grouped = grouped:sub(2)
	end
	if value < 0 and rounded ~= 0 then
		return "-" .. grouped
	end
	return grouped
end

function LiveStat.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}

	local self = setmetatable({}, LiveStat)
	self._theme = theme
	self._parent = parent
	self._name = Settings.Name or "Stat"
	self._size = (Settings.Size == "Compact") and "Compact" or "Full"
	self._icon = Settings.Icon
	self._prefix = Settings.Prefix or ""
	self._suffix = Settings.Suffix or ""
	self._spinningEnabled = (Settings.SpinningEnabled == nil) and true or Settings.SpinningEnabled
	self._value = tonumber(Settings.Value) or 0
	self._hasValue = Settings.Value ~= nil

	self._changeMode = (Settings.ChangeMode == "absolute") and "absolute" or "percentage"
	self._changeBaseline = (Settings.ChangeBaseline == "initial") and "initial" or "previous"
	self._showChange = (Settings.ShowChange == nil) and true or Settings.ShowChange
	self._initialValue = self._hasValue and self._value or nil
	self._lastChange = 0

	self._accent = ACCENT.neutral

	if self._size == "Compact" then
		self:_buildCompact()
	else
		self:_buildFull()
	end

	self:_applyAccent(0)
	-- Re-derives the accent on a theme switch; owner unregisters on destroy.
	ThemeManager.OnThemeApplied(function()
		self:_applyAccent(self._direction or 0)
	end, self._main)
	if self._spinningEnabled then
		self:_startSpin()
	end

	ComponentAPI.Apply(self, {
		Root = function(me)
			return me._main
		end,
		OnName = function(me, newName)
			if me._title then
				Locale.set(me._title, "Text", newName)
			end
		end,
	})

	return self
end

function LiveStat:_buildFull()
	local theme = self._theme

	local main = Instance.new("Frame")
	main.Name = UUID.Generate("LiveStat")
	main.Size = UDim2.new(1, 0, 0, FULL_HEIGHT)
	main.BackgroundColor3 = theme.ComponentBackgroundColor or Color3.fromRGB(30, 30, 34)
	main.BackgroundTransparency = theme.ComponentBackgroundTransparency or 0
	main.BorderSizePixel = 0
	main.ZIndex = 1
	main.Parent = self._parent
	self._main = main

	ThemeManager.BindColor(main, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(main, "BackgroundTransparency", "ComponentBackgroundTransparency")

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, FULL_CORNER)
	corner.Parent = main

	local stroke = Instance.new("UIStroke")
	stroke.Color = self._accent.stroke
	stroke.Transparency = theme.StrokeTransparency or 0.7
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = main
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	-- Re-stamp after the binding, which only writes on theme change.
	stroke.Transparency = theme.StrokeTransparency or 0.7
	self._stroke = stroke

	self:_buildAccent(main, FULL_CORNER, 14)

	local bar = Instance.new("Frame")
	bar.Name = UUID.Static("AccentBar")
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = self._accent.fill
	bar.BackgroundTransparency = 0.15
	bar.Size = UDim2.new(0, ACCENT_BAR, 1, 0)
	bar.ZIndex = 4
	bar.Parent = main
	local barCorner = Instance.new("UICorner")
	barCorner.TopLeftRadius = UDim.new(0, FULL_CORNER)
	barCorner.BottomLeftRadius = UDim.new(0, FULL_CORNER)
	barCorner.Parent = bar
	self._accentBar = bar

	local iconX = 16
	if self._icon then
		local tile = Instance.new("Frame")
		tile.Name = UUID.Static("IconTile")
		tile.BorderSizePixel = 0
		tile.BackgroundColor3 = self._accent.fill
		tile.BackgroundTransparency = 0.74
		tile.Position = UDim2.fromOffset(iconX, 14)
		tile.Size = UDim2.fromOffset(34, 34)
		tile.ZIndex = 3
		tile.Parent = main
		local tileCorner = Instance.new("UICorner")
		tileCorner.CornerRadius = UDim.new(0, 9)
		tileCorner.Parent = tile
		self._iconTile = tile

		local icon = Instance.new("ImageLabel")
		icon.Image = self._icon
		icon.Size = UDim2.fromOffset(17, 17)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.BorderSizePixel = 0
		icon.ImageColor3 = theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
		icon.Parent = tile
		ThemeManager.BindColor(icon, "ImageColor3", "PrimaryTextColor")
		self._iconLabel = icon

		iconX = 60
	end

	local title = Instance.new("TextLabel")
	Locale.set(title, "Text", self._name)
	title.Position = UDim2.fromOffset(iconX, 14)
	title.Size = UDim2.new(1, -iconX - 94, 0, 18)
	title.BackgroundTransparency = 1
	title.BorderSizePixel = 0
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	title.TextColor3 = theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
	title.ZIndex = 3
	title.Parent = main
	ThemeManager.BindColor(title, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(title, "TextTransparency", "PrimaryTextTransparency")
	self._title = title

	local valueHost = Instance.new("Frame")
	valueHost.Name = UUID.Static("Value")
	valueHost.AnchorPoint = Vector2.new(0, 1)
	valueHost.Position = UDim2.new(0, iconX, 1, -12)
	valueHost.Size = UDim2.new(0.65, -iconX, 0, 32)
	valueHost.BackgroundTransparency = 1
	valueHost.BorderSizePixel = 0
	valueHost.ZIndex = 3
	valueHost.Parent = main
	self._valueOdo = Odometer.new(valueHost, {
		textSize = 25,
		height = 30,
		weight = Enum.FontWeight.SemiBold,
		alignment = Enum.HorizontalAlignment.Left,
		textColor = theme.PrimaryTextColor,
	})
	self._valueOdo:snap(self:_format(self._value))

	if self._showChange then
		local chip = Instance.new("Frame")
		chip.Name = UUID.Static("ChangeChip")
		chip.BorderSizePixel = 0
		chip.BackgroundColor3 = self._accent.fill
		chip.BackgroundTransparency = 0.84
		chip.AnchorPoint = Vector2.new(1, 1)
		chip.Position = UDim2.new(1, -16, 1, -14)
		chip.Size = UDim2.fromOffset(78, 22)
		chip.ZIndex = 3
		chip.Parent = main
		local chipCorner = Instance.new("UICorner")
		chipCorner.CornerRadius = UDim.new(0, 7)
		chipCorner.Parent = chip
		self._changeChip = chip

		local changeHost = Instance.new("Frame")
		changeHost.Name = UUID.Static("Change")
		changeHost.AnchorPoint = Vector2.new(1, 0.5)
		changeHost.Position = UDim2.new(1, -8, 0.5, 0)
		changeHost.Size = UDim2.new(1, -16, 1, 0)
		changeHost.BackgroundTransparency = 1
		changeHost.BorderSizePixel = 0
		changeHost.ZIndex = 4
		changeHost.Parent = chip
		self._changeOdo = Odometer.new(changeHost, {
			textSize = 12,
			height = 14,
			weight = Enum.FontWeight.SemiBold,
			alignment = Enum.HorizontalAlignment.Right,
			textColor = theme.PrimaryTextColor,
		})
		self._changeOdo:snap(self:_formatChange(0))
	end
end

function LiveStat:_buildCompact()
	local theme = self._theme

	local main = Instance.new("Frame")
	main.Name = UUID.Generate("LiveStat")
	main.Size = UDim2.new(1, 0, 0, COMPACT_HEIGHT)
	main.BackgroundColor3 = theme.ComponentBackgroundColor or Color3.fromRGB(30, 30, 34)
	main.BackgroundTransparency = theme.ComponentBackgroundTransparency or 0
	main.BorderSizePixel = 0
	main.ZIndex = 1
	main.Parent = self._parent
	self._main = main

	ThemeManager.BindColor(main, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(main, "BackgroundTransparency", "ComponentBackgroundTransparency")

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, COMPACT_CORNER)
	corner.Parent = main

	local stroke = Instance.new("UIStroke")
	stroke.Color = self._accent.stroke
	stroke.Transparency = theme.StrokeTransparency or 0.7
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = main
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	-- Re-stamp after the binding, which only writes on theme change.
	stroke.Transparency = theme.StrokeTransparency or 0.7
	self._stroke = stroke

	self:_buildAccent(main, COMPACT_CORNER, 10)

	local bar = Instance.new("Frame")
	bar.Name = UUID.Static("AccentBar")
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = self._accent.fill
	bar.BackgroundTransparency = 0.15
	bar.Size = UDim2.new(0, ACCENT_BAR, 1, 0)
	bar.ZIndex = 4
	bar.Parent = main
	local barCorner = Instance.new("UICorner")
	barCorner.TopLeftRadius = UDim.new(0, COMPACT_CORNER)
	barCorner.BottomLeftRadius = UDim.new(0, COMPACT_CORNER)
	barCorner.Parent = bar
	self._accentBar = bar

	local textX = 14
	if self._icon then
		local tile = Instance.new("Frame")
		tile.Name = UUID.Static("IconTile")
		tile.BorderSizePixel = 0
		tile.BackgroundColor3 = self._accent.fill
		tile.BackgroundTransparency = 0.76
		tile.AnchorPoint = Vector2.new(0, 0.5)
		tile.Position = UDim2.new(0, 11, 0.5, 0)
		tile.Size = UDim2.fromOffset(26, 26)
		tile.ZIndex = 3
		tile.Parent = main
		local tileCorner = Instance.new("UICorner")
		tileCorner.CornerRadius = UDim.new(0, 7)
		tileCorner.Parent = tile
		self._iconTile = tile

		local icon = Instance.new("ImageLabel")
		icon.Image = self._icon
		icon.Size = UDim2.fromOffset(14, 14)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.BorderSizePixel = 0
		icon.ImageColor3 = theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
		icon.Parent = tile
		ThemeManager.BindColor(icon, "ImageColor3", "PrimaryTextColor")
		self._iconLabel = icon

		textX = 45
	end

	local title = Instance.new("TextLabel")
	Locale.set(title, "Text", self._name)
	title.AnchorPoint = Vector2.new(0, 0.5)
	title.Position = UDim2.new(0, textX, 0.5, 0)
	title.Size = UDim2.new(0.55, -textX - 6, 0, 16)
	title.BackgroundTransparency = 1
	title.BorderSizePixel = 0
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	title.TextColor3 = theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
	title.ZIndex = 3
	title.Parent = main
	ThemeManager.BindColor(title, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(title, "TextTransparency", "PrimaryTextTransparency")
	self._title = title

	local valueHost = Instance.new("Frame")
	valueHost.Name = UUID.Static("Value")
	valueHost.AnchorPoint = Vector2.new(1, 0.5)
	valueHost.Position = UDim2.new(1, -12, 0.5, 0)
	valueHost.Size = UDim2.new(0.45, -12, 1, 0)
	valueHost.BackgroundTransparency = 1
	valueHost.BorderSizePixel = 0
	valueHost.ZIndex = 3
	valueHost.Parent = main
	self._valueOdo = Odometer.new(valueHost, {
		textSize = 17,
		height = 20,
		weight = Enum.FontWeight.SemiBold,
		alignment = Enum.HorizontalAlignment.Right,
		textColor = theme.PrimaryTextColor,
	})
	self._valueOdo:snap(self:_format(self._value))
end

-- Neutral wash plus a slow sheen sweep; the accent bar, tile and chip carry
-- the direction colour without flooding the whole card.
function LiveStat:_buildAccent(main, cornerRadius, blurSize)
	local wash = Instance.new("Frame")
	wash.Name = UUID.Static("AccentWash")
	wash.Size = UDim2.fromScale(1, 1)
	wash.BackgroundColor3 = self._accent.fill
	wash.BackgroundTransparency = 0.9
	wash.BorderSizePixel = 0
	wash.ZIndex = 1
	wash.Parent = main
	local washCorner = Instance.new("UICorner")
	washCorner.CornerRadius = UDim.new(0, cornerRadius)
	washCorner.Parent = wash
	self._wash = wash

	local sheen = Instance.new("Frame")
	sheen.Name = UUID.Static("Sheen")
	sheen.Size = UDim2.fromScale(1, 1)
	sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sheen.BackgroundTransparency = 0.94
	sheen.BorderSizePixel = 0
	sheen.ZIndex = 2
	sheen.Parent = main
	local sheenCorner = Instance.new("UICorner")
	sheenCorner.CornerRadius = UDim.new(0, cornerRadius)
	sheenCorner.Parent = sheen
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 25
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(0.5, 0.05),
		NumberSequenceKeypoint.new(1, 0.45),
	})
	gradient.Parent = sheen
	self._gradient = gradient

	local glow = Instance.new("UIShadow")
	glow.Color = self._accent.fill
	glow.Transparency = 0.72
	glow.BlurRadius = UDim.new(0, blurSize)
	glow.Spread = UDim2.fromOffset(1, 1)
	glow.Parent = main
	self._glow = glow
end

-- Signed percentage, or a signed grouped number in absolute mode.
function LiveStat:_formatChange(delta)
	if self._changeMode == "absolute" then
		if delta > 0 then
			return "+" .. formatNumber(delta)
		end
		return formatNumber(delta)
	end
	if delta > 0 then
		return string.format("+%.1f%%", delta)
	elseif delta < 0 then
		return string.format("%.1f%%", delta)
	end
	return "0%"
end

function LiveStat:_format(value)
	return self._prefix .. formatNumber(value) .. self._suffix
end

function LiveStat:_applyAccent(direction)
	self._direction = direction -- remembered so a theme switch can re-apply it
	local themed = accentsFor(ActiveTheme.theme or self._theme)
	local accent
	if direction > 0 then
		accent = themed.positive
	elseif direction < 0 then
		accent = themed.negative
	else
		accent = themed.neutral
	end
	self._accent = accent

	-- The card base stays neutral; only the wash and small marks recolour.
	if self._stroke then
		Tween.Play(self._stroke, "Fast", { Color = accent.stroke })
	end
	if self._wash then
		Tween.Play(self._wash, "Fast", { BackgroundColor3 = accent.fill })
	end
	if self._accentBar then
		Tween.Play(self._accentBar, "Fast", { BackgroundColor3 = accent.fill })
	end
	if self._iconTile then
		Tween.Play(self._iconTile, "Fast", { BackgroundColor3 = accent.fill })
	end
	if self._changeChip then
		Tween.Play(self._changeChip, "Fast", { BackgroundColor3 = accent.fill })
	end
	if self._glow then
		Tween.Play(self._glow, "Fast", { Color = accent.fill })
	end
end

-- StartSpin gates on visibility, so an off-screen card resumes in place.
function LiveStat:_startSpin()
	if not self._gradient then
		return
	end
	self._gradient.Rotation = 0
	Tween.StartSpin(self._gradient, { Rotation = 360 }, SPIN_PRESET)
end

function LiveStat:_stopSpin()
	if self._gradient then
		Tween.StopSpin(self._gradient)
	end
end

function LiveStat:Set(value)
	value = tonumber(value) or 0
	local previous = self._value
	local hasNoHistory = not self._hasValue
	local direction = 0
	if not hasNoHistory then
		if value > previous then
			direction = 1
		elseif value < previous then
			direction = -1
		end
	end
	self._value = value
	self._hasValue = true
	if self._initialValue == nil then
		self._initialValue = value
	end

	self:_applyAccent(direction)

	if self._valueOdo then
		self._valueOdo:to(self:_format(value), direction >= 0)
	end

	if self._changeOdo then
		local refValue = (self._changeBaseline == "initial") and self._initialValue or previous
		if hasNoHistory or refValue == value then
			self._changeOdo:snap(self:_formatChange(0))
			self._lastChange = 0
		elseif refValue == 0 then
			local sign = (value > 0) and "+" or "-"
			local tail = (self._changeMode == "percentage") and "∞%" or "∞"
			self._changeOdo:snap(sign .. tail)
			self._lastChange = 0
		else
			local targetChange
			if self._changeMode == "percentage" then
				targetChange = ((value - refValue) / math.abs(refValue)) * 100
			else
				targetChange = value - refValue
			end
			self._changeOdo:to(self:_formatChange(targetChange), targetChange >= self._lastChange)
			self._lastChange = targetChange
		end
	end
	return self
end

function LiveStat:Get()
	return self._value
end

function LiveStat:Destroy()
	self:_stopSpin()
	if self._main then
		self._main:Destroy()
		self._main = nil
	end
end

return LiveStat
