--[[
	LiveStat  ·  Aetheris UI Library

	A live numeric stat card, laid out to match Rayfield's Statistic:

	  FULL (90px)   : title (+ optional icon) top-left, big value bottom-left,
	                  % / absolute change bottom-right, accent fill + glow.
	  COMPACT (41px): icon + title left, single value right.

	The caller pushes a NUMBER in with :Set(); the card renders it with the
	odometer slot-reel roll and tints itself toward the value's direction --
	rising = positive accent (green), falling = negative (red), idle = neutral.

	Accent colours are Rayfield's exact statAccents (the bright stop of each
	fill); the card's UIStroke uses the brighter stroke edge. The accent
	gradient SPINS slowly (12s / revolution) through the shared Tween spin
	system, which gates on visibility -- an off-screen card pauses and resumes
	from the frozen angle, like Slider / Toggle / RadioButton.

	Usage:
		local stat = section:LiveStat({
			Name   = "Score",
			Value  = 100,
			Size   = "Full",          -- "Full" | "Compact"
			Icon   = ico("trophy"),
		})
		stat:Set(250)                 -- rolls up, flips green
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local Odometer = require("../Utils/Odometer")
local Constants = require("../Constants")

local LiveStat = {}
LiveStat.__index = LiveStat

-- 12s / revolution, defined as a shared preset in Utils/Tween.
local SPIN_PRESET = "SpinStat"

-- Rayfield Statistic geometry.
local FULL_HEIGHT = 90
local COMPACT_HEIGHT = 41
local FULL_CORNER = 8
local COMPACT_CORNER = 6

-- Rayfield statAccents. Each entry is a fill GRADIENT (bright -> dark) plus a
-- brighter stroke edge; LiveStat's surface is solid, so we use the lead
-- (bright) stop of the fill, and the lead of the stroke for the UIStroke.
local ACCENT = {
	positive = { fill = Color3.fromRGB(0, 170, 127), stroke = Color3.fromRGB(0, 213, 156) },
	negative = { fill = Color3.fromRGB(172, 47, 47), stroke = Color3.fromRGB(255, 75, 75) },
	-- Rayfield neutral == positive (RF2's default green stat exactly).
	neutral = { fill = Color3.fromRGB(0, 170, 127), stroke = Color3.fromRGB(0, 213, 156) },
}

-- Comma-grouped integer, e.g. 1234567 -> "1,234,567". Negatives keep the sign,
-- and a negative that rounds to zero shows plain "0".
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

	-- Change readout (mirrors Rayfield's Statistic).
	self._changeMode = (Settings.ChangeMode == "absolute") and "absolute" or "percentage"
	self._changeBaseline = (Settings.ChangeBaseline == "initial") and "initial" or "previous"
	self._showChange = (Settings.ShowChange == nil) and true or Settings.ShowChange
	self._initialValue = self._hasValue and self._value or nil
	self._lastChange = 0

	self._accent = ACCENT.neutral
	self._accentColor = ACCENT.neutral.fill

	if self._size == "Compact" then
		self:_buildCompact()
	else
		self:_buildFull()
	end

	self:_applyAccent(0)
	if self._spinningEnabled then
		self:_startSpin()
	end
	return self
end

-- Full 90px card, Rayfield layout: title (+icon) top-left, value bottom-left,
-- change bottom-right.
function LiveStat:_buildFull()
	local theme = self._theme

	local main = Instance.new("Frame")
	main.Name = self._name
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

	-- Accent stroke edge (Rayfield's AcrylicBorder / stat stroke).
	local stroke = Instance.new("UIStroke")
	stroke.Color = self._accent.stroke
	stroke.Transparency = theme.StrokeTransparency or 0.7
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = main
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	-- Re-stamp AFTER the binding. BindTransparency only writes the theme value
	-- when the theme changes, so with the assignment before it the stroke kept
	-- its invisible default until the first theme switch -- which is exactly the
	-- reported "stroke only shows up after a theme switch".
	stroke.Transparency = theme.StrokeTransparency or 0.7
	self._stroke = stroke

	self:_buildAccent(main, FULL_CORNER, 13)

	-- Title row: Rayfield uses a 1,-40 x 32 container at (20,15) with an 8px
	-- horizontal, vertically-centred list layout (icon then title).
	local titleContainer = Instance.new("Frame")
	titleContainer.Name = "Title"
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

	-- Value (bottom-left): Rayfield puts a 200x20 host at (0,20,1,-15).
	local valueHost = Instance.new("Frame")
	valueHost.Name = "Value"
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

	-- Change (bottom-right): 200x15 host at (1,-20,1,-15), right-aligned.
	if self._showChange then
		local changeHost = Instance.new("Frame")
		changeHost.Name = "Change"
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

-- Compact 41px row, Rayfield layout: icon + title left, single value right.
function LiveStat:_buildCompact()
	local theme = self._theme

	local main = Instance.new("Frame")
	main.Name = self._name
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
	-- Re-stamp AFTER the binding. BindTransparency only writes the theme value
	-- when the theme changes, so with the assignment before it the stroke kept
	-- its invisible default until the first theme switch -- which is exactly the
	-- reported "stroke only shows up after a theme switch".
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
	valueHost.Name = "Value"
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

-- Accent layer: a nearly-transparent white overlay carrying an accent gradient
-- whose alpha ramps in; the gradient multiplies against the white so it shows
-- the true accent. Spun continuously for the "alive" sheen. A UIShadow glow
-- sits behind the card.
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

	-- Bright -> dark DIAGONAL ramp (Rayfield's look). The HUE comes from the
	-- overlay's own BackgroundColor3, which _applyAccent tweens; this ramp only
	-- carries the brightness, so the whole gradient shifts colour together.
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

-- Signed change string: "+12.3%" / "-4.0%" / "0%" (percentage) or a signed
-- grouped number (absolute). Zero shows plain "0%" / "0".
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
	local accent
	if direction > 0 then
		accent = ACCENT.positive
	elseif direction < 0 then
		accent = ACCENT.negative
	else
		accent = ACCENT.neutral
	end
	self._accent = accent
	self._accentColor = accent.fill

	-- SOLID card base (sits behind the overlay; keeps the edges matched).
	if self._main then
		ThemeManager.SetColorOverride(self._main, "BackgroundColor3", accent.fill)
		self._main.BackgroundTransparency = 0
	end
	-- TWEEN the hue (stroke + overlay + glow) instead of snapping, so rising /
	-- falling crossfades red <-> green. The overlay carries the gradient, so
	-- the whole diagonal ramp shifts colour together.
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

-- Spin the accent gradient. StartSpin auto-gates on visibility, so an
-- off-screen card pauses its spin and resumes from the frozen angle when its
-- page returns.
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
