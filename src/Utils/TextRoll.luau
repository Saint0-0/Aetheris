--[[
	TextRoll  ·  Aetheris UI Library

	Per-glyph roll for arbitrary text: takes over a TextLabel and renders its
	string as a row of glyph cells, rolling only the characters that changed
	(the new glyph rises from below). The username-mask toggle uses it.
	Static glyphs are plain labels; rolled ones tween a two-glyph strip.
]]

local Tween = require("./Tween")
local UUID = require("./UUID")

local TextService = game:GetService("TextService")

local TextRoll = {}
TextRoll.__index = TextRoll

-- Same rationale as Odometer: clipped cells shave ~1px off glyph edges
-- (antialiasing / side bearings overshoot the layout bounds), so widen slightly.
local CELL_PAD = 2

local function measure(text, font, size)
	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = font
	params.Size = size
	params.Width = math.huge
	local ok, bounds = pcall(function()
		return TextService:GetTextBoundsAsync(params)
	end)
	return math.ceil((ok and bounds or Vector2.new(size * 0.6, size)).X)
end

-- Split a string into characters (multibyte-safe for unicode display names).
local function toChars(text)
	local chars = {}
	for ch in string.gmatch(text or "", utf8.charpattern) do
		table.insert(chars, ch)
	end
	return chars
end

-- Take over a TextLabel: its glyphs render as child rows (the label's own
-- Text is cleared). Style is captured from the label and mirrored live, so a
-- theme switch restamps every glyph. Call SetText to populate.
function TextRoll.new(label)
	local self = setmetatable({}, TextRoll)
	self.label = label
	self.font = label.FontFace
	self.size = label.TextSize
	self.color = label.TextColor3
	self.transparency = label.TextTransparency
	self.height = math.ceil(self.size)
	self.cells = {} -- [glyphIndex] = { frame, char, rolling }
	self.text = ""

	label.Text = ""
	local layout = Instance.new("UIListLayout")
	layout.Name = UUID.Static("TextRollLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 0)
	layout.Parent = label
	self.layout = layout

	self._connections = {
		label:GetPropertyChangedSignal("TextColor3"):Connect(function()
			self.color = label.TextColor3
			self:_restyle()
		end),
		label:GetPropertyChangedSignal("TextTransparency"):Connect(function()
			self.transparency = label.TextTransparency
			self:_restyle()
		end),
		label:GetPropertyChangedSignal("FontFace"):Connect(function()
			self.font = label.FontFace
			self:_restyle()
		end),
	}

	return self
end

function TextRoll:_makeLabel(char, width)
	local glyph = Instance.new("TextLabel")
	glyph.BackgroundTransparency = 1
	glyph.BorderSizePixel = 0
	glyph.FontFace = self.font
	glyph.TextSize = self.size
	glyph.TextColor3 = self.color
	glyph.TextTransparency = self.transparency
	glyph.TextXAlignment = Enum.TextXAlignment.Left
	glyph.Text = char
	glyph.Size = UDim2.fromOffset(width, self.height)
	return glyph
end

-- Replace a cell with a plain static label showing char.
function TextRoll:_setStatic(index, char)
	local old = self.cells[index]
	if old then
		old.frame:Destroy()
	end
	local width = measure(char, self.font, self.size) + CELL_PAD
	local glyph = self:_makeLabel(char, width)
	glyph.LayoutOrder = index
	glyph.Parent = self.label
	self.cells[index] = { frame = glyph, char = char, rolling = false }
end

-- Replace a cell with a clipped two-glyph strip and roll it up, so newChar
-- rises from below; settles into a static label when the tween completes.
function TextRoll:_setRolling(index, oldChar, newChar)
	local old = self.cells[index]
	if old then
		old.frame:Destroy()
	end
	local oldW = measure(oldChar, self.font, self.size)
	local newW = measure(newChar, self.font, self.size)
	local width = math.max(oldW, newW) + CELL_PAD

	local cell = Instance.new("Frame")
	cell.Name = UUID.Generate("TextRollCell")
	cell.Size = UDim2.fromOffset(width, self.height)
	cell.BackgroundTransparency = 1
	cell.BorderSizePixel = 0
	cell.ClipsDescendants = true
	cell.LayoutOrder = index
	cell.Parent = self.label

	local strip = Instance.new("Frame")
	strip.Name = UUID.Static("TextRollStrip")
	strip.Size = UDim2.fromOffset(width, self.height * 2)
	strip.BackgroundTransparency = 1
	strip.BorderSizePixel = 0
	strip.Parent = cell

	local outGlyph = self:_makeLabel(oldChar, oldW)
	outGlyph.Position = UDim2.fromOffset(0, 0)
	outGlyph.Parent = strip

	local inGlyph = self:_makeLabel(newChar, newW)
	inGlyph.Position = UDim2.fromOffset(0, self.height)
	inGlyph.Parent = strip

	self.cells[index] = { frame = cell, char = newChar, rolling = true }

	local handle = Tween.Play(strip, "Smooth", { Position = UDim2.fromOffset(0, -self.height) })
	handle.Tween.Completed:Once(function()
		-- Only settle if this cell wasn't replaced by a newer roll.
		if self.cells[index] and self.cells[index].frame == cell then
			self:_setStatic(index, newChar)
		end
	end)
end

-- Reconcile the rendered glyphs to text. Changed glyphs roll; instant = snap.
function TextRoll:SetText(text, instant)
	local chars = toChars(tostring(text or ""))
	self.text = text

	for i, ch in ipairs(chars) do
		local cell = self.cells[i]
		if instant then
			-- Snap: rebuild anything missing, mismatched, or mid-roll.
			if not cell or cell.char ~= ch or cell.rolling then
				self:_setStatic(i, ch)
			end
		elseif not cell then
			self:_setStatic(i, ch) -- newly added glyph: pop in
		elseif cell.char ~= ch then
			self:_setRolling(i, cell.char, ch)
		end
	end
	for i = #self.cells, #chars + 1, -1 do
		local removed = table.remove(self.cells, i)
		if removed then
			removed.frame:Destroy()
		end
	end

	return self
end

function TextRoll:GetText()
	return self.text
end

-- Mirror live style changes (theme switch / font change) onto every glyph.
-- Widths are not re-measured; color/transparency/font restamps cover theming.
function TextRoll:_restyle()
	for _, glyph in ipairs(self.label:GetDescendants()) do
		if glyph:IsA("TextLabel") then
			glyph.FontFace = self.font
			glyph.TextSize = self.size
			glyph.TextColor3 = self.color
			glyph.TextTransparency = self.transparency
		end
	end
end

function TextRoll:Destroy()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	self._connections = {}
	for _, cell in pairs(self.cells) do
		cell.frame:Destroy()
	end
	self.cells = {}
	self.layout:Destroy()
	self.label.Text = self.text
end

return TextRoll
