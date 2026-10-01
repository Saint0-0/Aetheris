--[[
	Odometer  ·  Aetheris UI Library

	Ported faithfully from Rayfield's odometer. Renders a numeric string as a row
	of per-digit REELS: each digit is a clipped cell holding a vertical strip of
	the glyphs 0-9 (twice = 20 high). Changing a digit tweens the strip's Y
	position so the new digit rolls up from below (value increased) or down from
	above (value decreased), easing out (Quint) into place -- the slot-machine
	"casino" roll.

	Non-digit characters (separators, %, prefixes/suffixes) are plain static
	labels. Cells are variable width (each digit's natural advance) so it reads
	like text, and the string reconciles from the RIGHT so decimals / suffixes
	stay put as digits grow on the left. Cells are pooled and reused.

	  local odo = Odometer.new(container, { textSize = 22 })
	  odo:snap("1,000")        -- set instantly
	  odo:to("2,500", true)   -- roll up toward the new value
	  odo:setTransparency(1)  -- fade every glyph
]]

local Constants = require("../Constants")
local Tween = require("./Tween")
local ThemeManager = require("../Themes/ThemeManager")

local TextService = game:GetService("TextService")

local Odometer = {}
Odometer.__index = Odometer

-- Two stacked copies of 0-9. A reel on digit d rests at strip Y = -d*H. Rolling
-- up moves to higher indices; rolling down first jumps to the second copy (same
-- glyph) so it can travel down without running past index 0.
local STRIP_LENGTH = 20

-- Digit advances are the same for every odometer of a given font+size, but
-- GetTextBoundsAsync yields, so measure the ten digits once per (font, size,
-- style) and cache. Later odometers reuse the result.
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

-- parent : Frame the row lives in; the odometer lays its cells out inside it
-- opts   : { textSize, alignment (Enum.HorizontalAlignment), transparency, duration, weight }
function Odometer.new(parent, opts)
	opts = opts or {}
	local self = setmetatable({
		parent = parent,
		textSize = opts.textSize or 16,
		transparency = opts.transparency or 0,
		duration = opts.duration or 0.55,
		weight = opts.weight or Enum.FontWeight.SemiBold,
		slots = {}, -- [indexFromRight] = { reel = reelData?, static = label? }
		length = 0,
		_lastText = nil,
	}, Odometer)

	self.font = Constants.Font(self.weight)
	self.height = math.ceil(self.textSize)

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

-- Lazily build (or fetch) the reel for a slot: a clipped cell + a fixed-width
-- strip of 20 themed digit labels, centred so the visible glyph sits in the
-- middle of the (variable-width) cell.
function Odometer:_reel(index)
	local slot = self.slots[index]
	if slot.reel then
		return slot.reel
	end

	local zIndex = self.parent.ZIndex + 1

	local cell = Instance.new("Frame")
	cell.Name = "Reel"
	cell.Size = UDim2.fromOffset(self.maxWidth, self.height)
	cell.BackgroundTransparency = 1
	cell.BorderSizePixel = 0
	cell.ClipsDescendants = true
	cell.ZIndex = zIndex
	cell.Parent = self.parent

	local strip = Instance.new("Frame")
	strip.Size = UDim2.fromOffset(self.maxWidth, self.height)
	strip.AnchorPoint = Vector2.new(0.5, 0) -- centred horizontally in the cell
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
		ThemeManager.BindColor(lbl, "TextColor3", "PrimaryTextColor")
	end

	local reel = { cell = cell, strip = strip, digit = 0, target = 0 }
	slot.reel = reel
	return reel
end

-- Fetch/build the static (separator/letter) label for a slot. Statics hug their
-- own glyph width so separators/suffixes space naturally.
function Odometer:_static(index)
	local slot = self.slots[index]
	if slot.static then
		return slot.static
	end

	local label = Instance.new("TextLabel")
	label.Name = "Static"
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
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")

	slot.static = label
	return label
end

function Odometer:_reelSnap(reel, digit)
	Tween.CancelAll(reel.strip)
	Tween.CancelAll(reel.cell)
	reel.cell.Size = UDim2.fromOffset(self.advance[digit], self.height)
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
		targetIndex = a + (digit - a) % 10 -- 1..9 above, glyph at target = digit
	else
		startIndex = a + 10 -- jump to 2nd copy (same glyph) to travel downward
		targetIndex = startIndex - (a - digit) % 10
	end

	reel.strip.Position = UDim2.new(0.5, 0, 0, -startIndex * self.height)
	reel.target = digit

	-- Roll the strip vertically and reflow the cell to the new digit's width together.
	local info = TweenInfo.new(self.duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	Tween.Play(reel.strip, info, { Position = UDim2.new(0.5, 0, 0, -targetIndex * self.height) })
	Tween.Play(reel.cell, info, { Size = UDim2.fromOffset(self.advance[digit], self.height) })
	reel.digit = digit
end

-- Show a slot as a digit; hide its static twin. A cell coming back from hidden
-- (the number grew past this column earlier) snaps rather than rolling from a
-- stale digit it last held.
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

-- Show a slot as a static char; hide its reel twin.
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

-- Core: render `text`, animating digit changes when `animate` and rolling in the
-- direction implied by `up` (value increased vs decreased).
function Odometer:_render(text, animate, up)
	text = tostring(text)

	if text == self._lastText then
		return
	end
	self._lastText = text

	-- Split into whole UTF-8 characters, not bytes: a suffix like "°" is two
	-- bytes and string.sub would tear it into invalid halves (rendered as tofu).
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

-- Roll to `text` (digits animate, direction from `up`).
function Odometer:to(text, up)
	self:_render(text, true, up)
end

-- Set `text` instantly (no roll).
function Odometer:snap(text)
	self:_render(text, false, true)
end

-- Set the base transparency for every glyph (visible = 0, hidden = 1).
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
