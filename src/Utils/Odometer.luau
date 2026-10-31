--[[
	Aetheris/Utils/Odometer.luau

	Renders a numeric string as a row of per-digit reels: each digit is a
	clipped cell holding a vertical strip of the glyphs 0-9, and changing a
	digit rolls the strip into place with an eased slot-machine motion.
	Non-digit characters stay as plain static labels, cells are variable
	width, and the string reconciles from the right so decimals and suffixes
	stay put as digits grow. Cells are pooled and reused.

	Based on Rayfield Gen 2 code (MPL-2.0)
	https://github.com/SiriusSoftwareLtd/rayfield-gen2

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = require("../Constants")
local Tween = require("./Tween")
local ThemeManager = require("../Themes/ThemeManager")
local UUID = require("./UUID")

local TextService = game:GetService("TextService")

local Odometer = {}
Odometer.__index = Odometer

-- Two stacked copies of 0-9: rolling down jumps to the second copy so it can travel past index 0.
local STRIP_LENGTH = 20

-- Extra cell width so ClipsDescendants never shaves a glyph's edge off.
local CELL_PAD = 2

-- Digit advances are the same per font+size; measure once and cache (GetTextBoundsAsync yields).
local metricsCache = {}
local function digitMetrics(font, size)
	local key = tostring(font.Family)
		.. "|"
		.. tostring(font.Weight)
		.. "|"
		.. tostring(font.Style)
		.. "|"
		.. tostring(size)
	local cached = metricsCache[key]
	if cached then
		return cached
	end

	local advance, maxWidth = {}, 0
	for d = 0, 9 do
		local params = Instance.new("GetTextBoundsParams")
		params.Text = tostring(d)
		params.Font = font
		params.Size = size
		params.Width = math.huge
		local ok, bounds = pcall(function()
			return TextService:GetTextBoundsAsync(params)
		end)
		local w = math.ceil((ok and bounds or Vector2.new(size * 0.6, size)).X)
		advance[d] = w
		if w > maxWidth then
			maxWidth = w
		end
	end
	cached = { advance = advance, maxWidth = maxWidth }
	metricsCache[key] = cached
	return cached
end

-- opts: { textSize, height, alignment, transparency, duration, weight, textColor }
-- textColor seeds the glyphs before any theme binding has applied (e.g. the pre-window key screen).
function Odometer.new(parent, opts)
	opts = opts or {}
	local self = setmetatable({
		parent = parent,
		textSize = opts.textSize or 16,
		transparency = opts.transparency or 0,
		duration = opts.duration or 0.55,
		weight = opts.weight or Enum.FontWeight.SemiBold,
		textColor = opts.textColor,
		slots = {}, -- [indexFromRight] = { reel = reelData?, static = label? }
		length = 0,
		_lastText = nil,
	}, Odometer)

	self.font = Constants.Font(self.weight)
	-- A taller cell can be passed so ascenders/descenders don't clip.
	self.height = opts.height or math.ceil(self.textSize)

	local metrics = digitMetrics(self.font, self.textSize)
	self.advance = metrics.advance
	self.maxWidth = metrics.maxWidth

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = opts.alignment or Enum.HorizontalAlignment.Left
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 0)
	layout.Parent = parent
	self.layout = layout

	return self
end

-- Lazily build the reel: a clipped cell + a strip of 20 themed digit labels.
function Odometer:_reel(index)
	local slot = self.slots[index]
	if slot.reel then
		return slot.reel
	end

	local zIndex = self.parent.ZIndex + 1

	local cell = Instance.new("Frame")
	cell.Name = UUID.Generate("OdometerCell")
	cell.Size = UDim2.fromOffset(self.maxWidth + CELL_PAD, self.height)
	cell.BackgroundTransparency = 1
	cell.BorderSizePixel = 0
	cell.ClipsDescendants = true
	cell.ZIndex = zIndex
	cell.Parent = self.parent

	local strip = Instance.new("Frame")
	strip.Size = UDim2.fromOffset(self.maxWidth, self.height)
	strip.AnchorPoint = Vector2.new(0.5, 0)
	strip.Position = UDim2.fromScale(0.5, 0)
	strip.BackgroundTransparency = 1
	strip.BorderSizePixel = 0
	strip.ZIndex = zIndex
	strip.Parent = cell

	for i = 0, STRIP_LENGTH - 1 do
		local lbl = Instance.new("TextLabel")
		lbl.Text = tostring(i % 10)
		lbl.Position = UDim2.fromOffset(0, i * self.height)
		lbl.Size = UDim2.fromOffset(self.maxWidth, self.height)
		lbl.BackgroundTransparency = 1
		lbl.BorderSizePixel = 0
		lbl.TextSize = self.textSize
		lbl.FontFace = self.font
		lbl.TextXAlignment = Enum.TextXAlignment.Center
		lbl.TextYAlignment = Enum.TextYAlignment.Center
		lbl.TextTransparency = self.transparency
		lbl.ZIndex = zIndex
		lbl.Parent = strip
		if self.textColor then
			lbl.TextColor3 = self.textColor
		end
		ThemeManager.BindColor(lbl, "TextColor3", "PrimaryTextColor")
	end

	local reel = { cell = cell, strip = strip, digit = 0, target = 0 }
	slot.reel = reel
	return reel
end

-- Statics hug their own glyph width so separators and suffixes space naturally.
function Odometer:_static(index)
	local slot = self.slots[index]
	if slot.static then
		return slot.static
	end

	local label = Instance.new("TextLabel")
	label.Name = UUID.Generate("OdometerLabel")
	label.Size = UDim2.fromOffset(0, self.height)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.TextSize = self.textSize
	label.FontFace = self.font
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTransparency = self.transparency
	label.ZIndex = self.parent.ZIndex + 1
	label.Parent = self.parent
	if self.textColor then
		label.TextColor3 = self.textColor
	end
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")

	slot.static = label
	return label
end

function Odometer:_reelSnap(reel, digit)
	Tween.CancelAll(reel.strip)
	Tween.CancelAll(reel.cell)
	reel.cell.Size = UDim2.fromOffset(self.advance[digit] + CELL_PAD, self.height)
	reel.strip.Position = UDim2.new(0.5, 0, 0, -digit * self.height)
	reel.digit = digit
	reel.target = digit
end

function Odometer:_reelRoll(reel, digit, up)
	-- Finalise any in-flight roll so we start from a clean resting digit.
	if reel.target ~= reel.digit then
		self:_reelSnap(reel, reel.target)
	end

	local a = reel.digit
	if a == digit then
		return
	end

	local startIndex, targetIndex
	if up then
		startIndex = a
		targetIndex = a + (digit - a) % 10
	else
		startIndex = a + 10 -- jump to 2nd copy (same glyph) to travel downward
		targetIndex = startIndex - (a - digit) % 10
	end

	reel.strip.Position = UDim2.new(0.5, 0, 0, -startIndex * self.height)
	reel.target = digit

	local info = TweenInfo.new(self.duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	Tween.Play(reel.strip, info, { Position = UDim2.new(0.5, 0, 0, -targetIndex * self.height) })
	Tween.Play(reel.cell, info, { Size = UDim2.fromOffset(self.advance[digit] + CELL_PAD, self.height) })
	reel.digit = digit
end

-- A cell coming back from hidden snaps rather than rolling from a stale digit.
function Odometer:_putDigit(index, digit, up, animate)
	local reel = self:_reel(index)
	local wasHidden = not reel.cell.Visible
	reel.cell.Visible = true
	reel.cell.LayoutOrder = -index
	if self.slots[index].static then
		self.slots[index].static.Visible = false
	end
	if animate and not wasHidden then
		self:_reelRoll(reel, digit, up)
	else
		self:_reelSnap(reel, digit)
	end
end

function Odometer:_putStatic(index, char)
	local label = self:_static(index)
	if not label.Visible then
		label.TextTransparency = self.transparency
	end
	label.Text = char
	label.Visible = true
	label.LayoutOrder = -index
	if self.slots[index].reel then
		self.slots[index].reel.cell.Visible = false
	end
end

function Odometer:_hide(index)
	local slot = self.slots[index]
	if not slot then
		return
	end
	if slot.reel then
		slot.reel.cell.Visible = false
	end
	if slot.static then
		slot.static.Visible = false
	end
end

-- Render text, animating digit changes in the direction implied by `up`.
function Odometer:_render(text, animate, up)
	text = tostring(text)

	if text == self._lastText then
		return
	end
	self._lastText = text

	-- Whole UTF-8 characters, not bytes, so suffixes like "°" survive.
	local chars = {}
	for _, code in utf8.codes(text) do
		table.insert(chars, utf8.char(code))
	end

	local n = #chars
	for i = 0, math.max(n, self.length) - 1 do
		self.slots[i] = self.slots[i] or {}
		if i < n then
			local char = chars[n - i] -- reconcile from the right
			if char:match("%d") then
				self:_putDigit(i, tonumber(char), up, animate)
			else
				self:_putStatic(i, char)
			end
		else
			self:_hide(i)
		end
	end
	self.length = n
end

function Odometer:to(text, up)
	self:_render(text, true, up)
end

function Odometer:snap(text)
	self:_render(text, false, true)
end

function Odometer:setTransparency(target)
	self.transparency = target
	for _, slot in pairs(self.slots) do
		if slot.static then
			slot.static.TextTransparency = target
		end
		if slot.reel then
			for _, lbl in ipairs(slot.reel.strip:GetChildren()) do
				if lbl:IsA("TextLabel") then
					lbl.TextTransparency = target
				end
			end
		end
	end
end

return Odometer
