--[[
	Aetheris/Components/LiveStat.luau

	Animated numeric stat card with Full and Compact layouts. Values roll
	through the odometer and tint positive, negative or neutral using accents
	derived from the theme's own AccentColor.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
	Based on Rayfield Gen 2 code (MPL-2.0)
	https://github.com/SiriusSoftwareLtd/rayfield-gen2
]]

local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local Tween = require("../Utils/Tween")
local Odometer = require("../Utils/Odometer")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

local LiveStat = {}
LiveStat.__index = LiveStat

-- 12s / revolution, a shared preset in Utils/Tween
local SPIN_PRESET = "SpinStat"

local FULL_HEIGHT = 90
local COMPACT_HEIGHT = 41
local FULL_CORNER = 8
local COMPACT_CORNER = 6

-- rising uses the theme's AccentColor; falling is that hue rotated to red, so
-- the card belongs to the palette but "down" still reads as down
local POS_FALLBACK = Color3.fromRGB(0, 170, 127)

local function lighten(c, t)
	return Color3.new(c.R + (1 - c.R) * t, c.G + (1 - c.G) * t, c.B + (1 - c.B) * t)
end

-- preserves S and V, so a blue accent yields a blue-toned "down"
local function withHue(c, targetHue)
	local _, s, v = Color3.toHSV(c)
	return Color3.fromHSV(targetHue, math.max(s, 0.55), v)
end

-- memoized: _applyAccent runs every value tick, so the HSV round-trip only
-- happens when the theme reference actually changes
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

-- static default until the first :_applyAccent call swaps in the themed set
local ACCENT = accentsFor(nil)

-- comma-grouped integer, e.g. 1234567 -> "1,234,567"; a negative rounding to
-- zero shows plain "0"
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
	-- re-derives the accent on a live theme switch; owner = main frame, so it
	-- auto-unregisters on destroy
	ThemeManager.OnThemeApplied(function()
		self:_applyAccent(self._direction or 0)
	end, self._main)
	if self._spinningEnabled then
		self:_startSpin()
	end
	return self
end

-- title (+icon) top-left, value bottom-left, change bottom-right
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
	-- re-stamp AFTER the binding: it only writes on theme change, so without
	-- this the stroke stayed invisible until the first theme switch
	stroke.Transparency = theme.StrokeTransparency or 0.7
	self._stroke = stroke

	self:_buildAccent(main, FULL_CORNER, 13)

	local titleContainer = Instance.new("Frame")
	titleContainer.Name = UUID.Static("Title")
	titleContainer.Size = UDim2.new(1, -40, 0, 32)
	titleContainer.Position = UDim2.fromOffset(20, 15)
	titleContainer.BackgroundTransparency = 1
	titleContainer.BorderSizePixel = 0
	titleContainer.ZIndex = 3
	titleContainer.Parent = main
	self._titleContainer = titleContainer

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.HorizontalAlignment = Enum.HorizontalAlignment.Left
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = titleContainer

	if self._icon then
		local icon = Instance.new("ImageLabel")
		icon.Image = self._icon
		icon.Size = UDim2.fromOffset(32, 32)
		icon.BackgroundTransparency = 1
		icon.BorderSizePixel = 0
		icon.LayoutOrder = 0
		icon.ZIndex = 3
		icon.ImageColor3 = theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
		icon.Parent = titleContainer
		ThemeManager.BindColor(icon, "ImageColor3", "PrimaryTextColor")
		self._iconLabel = icon
	end

	local title = Instance.new("TextLabel")
	title.Text = self._name
	title.Size = UDim2.fromOffset(300, 19)
	title.BackgroundTransparency = 1
	title.BorderSizePixel = 0
	title.TextSize = 19
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextWrapped = true
	title.LayoutOrder = 1
	title.FontFace = Constants.Font(Enum.FontWeight.Medium)
	title.TextColor3 = theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
	title.ZIndex = 3
	title.Parent = titleContainer
	ThemeManager.BindColor(title, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(title, "TextTransparency", "PrimaryTextTransparency")
	self._title = title

	local valueHost = Instance.new("Frame")
	valueHost.Name = UUID.Static("Value")
	valueHost.AnchorPoint = Vector2.new(0, 1)
	valueHost.Position = UDim2.new(0, 20, 1, -15)
	valueHost.Size = UDim2.fromOffset(200, 20)
	valueHost.BackgroundTransparency = 1
	valueHost.BorderSizePixel = 0
	valueHost.ZIndex = 3
	valueHost.Parent = main
	self._valueOdo = Odometer.new(valueHost, {
		textSize = 20,
		weight = Enum.FontWeight.SemiBold,
		alignment = Enum.HorizontalAlignment.Left,
	})
	self._valueOdo:snap(self:_format(self._value))

	-- Change (bottom-right), right-aligned
	if self._showChange then
		local changeHost = Instance.new("Frame")
		changeHost.Name = UUID.Static("Change")
		changeHost.AnchorPoint = Vector2.new(1, 1)
		changeHost.Position = UDim2.new(1, -20, 1, -15)
		changeHost.Size = UDim2.fromOffset(200, 15)
		changeHost.BackgroundTransparency = 1
		changeHost.BorderSizePixel = 0
		changeHost.ZIndex = 3
		changeHost.Parent = main
		self._changeOdo = Odometer.new(changeHost, {
			textSize = 15,
			weight = Enum.FontWeight.SemiBold,
			alignment = Enum.HorizontalAlignment.Right,
		})
		self._changeOdo:snap(self:_formatChange(0))
	end
end

-- icon + title left, single value right
function LiveStat:_buildCompact()
	local theme = self._theme

	local main = Instance.new("Frame")
	main.Name = UUID.Generate("LiveStat")
	main.Size = UDim2.new(1, 0, 0, COMPACT_HEIGHT)
	main.BackgroundColor3 = theme.ComponentBackgroundColor or Color3.fromRGB(30, 30, 34)
	main.BackgroundTransparency = theme.ComponentBackgroundTransparency or 0
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
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
	-- re-stamp AFTER the binding: it only writes on theme change
	stroke.Transparency = theme.StrokeTransparency or 0.7
	self._stroke = stroke

	self:_buildAccent(main, COMPACT_CORNER, 10)

	local pad = 14
	if self._icon then
		local icon = Instance.new("ImageLabel")
		icon.Image = self._icon
		icon.Size = UDim2.fromOffset(20, 20)
		icon.Position = UDim2.new(0, pad, 0.5, -10)
		icon.BackgroundTransparency = 1
		icon.BorderSizePixel = 0
		icon.ZIndex = 3
		icon.ImageColor3 = theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
		icon.Parent = main
		ThemeManager.BindColor(icon, "ImageColor3", "PrimaryTextColor")
		self._iconLabel = icon
		pad = pad + 26
	end

	local title = Instance.new("TextLabel")
	title.Text = self._name
	title.AnchorPoint = Vector2.new(0, 0.5)
	title.Position = UDim2.new(0, pad, 0.5, 0)
	title.Size = UDim2.new(0.6, -pad, 0, 16)
	title.BackgroundTransparency = 1
	title.BorderSizePixel = 0
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.FontFace = Constants.Font(Enum.FontWeight.Medium)
	title.TextColor3 = theme.PrimaryTextColor or Color3.fromRGB(255, 255, 255)
	title.ZIndex = 3
	title.Parent = main
	ThemeManager.BindColor(title, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(title, "TextTransparency", "PrimaryTextTransparency")
	self._title = title

	local valueHost = Instance.new("Frame")
	valueHost.Name = UUID.Static("Value")
	valueHost.AnchorPoint = Vector2.new(1, 0.5)
	valueHost.Position = UDim2.new(1, -14, 0.5, 0)
	valueHost.Size = UDim2.new(0.5, -14, 1, 0)
	valueHost.BackgroundTransparency = 1
	valueHost.BorderSizePixel = 0
	valueHost.ZIndex = 3
	valueHost.Parent = main
	self._valueOdo = Odometer.new(valueHost, {
		textSize = 17,
		weight = Enum.FontWeight.SemiBold,
		alignment = Enum.HorizontalAlignment.Right,
	})
	self._valueOdo:snap(self:_format(self._value))
end

-- near-transparent white overlay carrying an accent gradient whose alpha ramps
-- in, spun for the "alive" sheen; a UIShadow glow sits behind the card
function LiveStat:_buildAccent(main, cornerRadius, blurSize)
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = self._accent.fill
	overlay.BackgroundTransparency = 0
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 2
	overlay.Parent = main
	self._overlay = overlay

	local oCorner = Instance.new("UICorner")
	oCorner.CornerRadius = UDim.new(0, cornerRadius)
	oCorner.Parent = overlay

	-- brightness-only ramp; the hue comes from the overlay's BackgroundColor3,
	-- so tweening that shifts the whole gradient together
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = -55
	gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 120, 120))
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.12),
	})
	gradient.Parent = overlay
	self._gradient = gradient

	local glow = Instance.new("UIShadow")
	glow.Color = self._accent.fill
	glow.Transparency = 0.6
	glow.BlurRadius = UDim.new(0, blurSize)
	glow.Spread = UDim2.fromOffset(1, 1)
	glow.Parent = main
	self._glow = glow
end

-- "+12.3%" / "-4.0%" / "0%" (percentage) or a signed grouped number (absolute)
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

	-- solid card base behind the overlay keeps the edges matched
	if self._main then
		ThemeManager.SetColorOverride(self._main, "BackgroundColor3", accent.fill)
		self._main.BackgroundTransparency = 0
	end
	-- tween the hue instead of snapping, so rising/falling crossfades smoothly
	if self._stroke then
		Tween.Play(self._stroke, "Fast", { Color = accent.stroke })
	end
	if self._overlay then
		Tween.Play(self._overlay, "Fast", { BackgroundColor3 = accent.fill })
	end
	if self._glow then
		Tween.Play(self._glow, "Fast", { Color = accent.fill })
	end
end

-- StartSpin auto-gates on visibility, so an off-screen card pauses and
-- resumes from the frozen angle when its page returns
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

function LiveStat:SetName(newName)
	self._name = newName
	if self._title then
		self._title.Text = newName
	end
end

function LiveStat:UpdateName(newName)
	self:SetName(newName)
end

function LiveStat:SetVisible(visible)
	if self._main then
		self._main.Visible = visible
	end
end

LiveStat.SetVisibility = LiveStat.SetVisible

function LiveStat:GetVisible()
	return self._main ~= nil and self._main.Visible or false
end

function LiveStat:Destroy()
	self:_stopSpin()
	if self._main then
		self._main:Destroy()
		self._main = nil
	end
end

return LiveStat
