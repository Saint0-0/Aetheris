--[[
	TextInput  ·  Aetheris UI Library

	The TextBox IS the field -- there is no wrapper Frame. Every visual
	(background, stroke, corner, glow, padding) lives on the TextBox itself.

	Layout:
		AnchorPoint    (1, 0.5)
		Position       (1, 0, 0.5, 0)   -- flush to the row's right edge
		Size           (0, w, 0, 29)    -- w is measured + tweened, see below
		TextXAlignment Center

	Width hug (kept from Rayfield): the pill is resized by MEASURING its
	shown string (typed text, or the placeholder when empty) and TWEENING
	Size.X with pillResizeInfo (0.4 Exponential Out). Width = measured text +
	2*PAD_X, so the centred text keeps PAD_X (15px) clearance each side. No
	UIPadding: on a centred TextBox it would consume the very slack the
	+2*PAD_X provides and force an ellipsis.

	Cap: the field's left edge must stay at least LABEL_GAP (20px) clear of
	the auto-sized name label, so a long value can never run over it.
	Overflow ellipsises (TextTruncate.AtEnd).

	Animations: focus fade (0.15 Quint Out, text 0.6 -> 0) and the commit
	accent flash (stroke + glow bloom, then settle).

	Options : Numeric (strips non-number chars, supports "5^3" and "9e9"),
	          ClearOnFocus (blank on focus, restore if nothing typed).

	Usage:
		local textInput = section:TextInput({
			Name = "Input Label",
			Placeholder = "Enter text...",
			Default = "",
			Numeric = false,
			Callback = function(text) end,
		})
]]

local TextService = game:GetService("TextService")

local Tween = require("../Utils/Tween")
local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local Constants = require("../Constants")
local ComponentRow = require("./ComponentRow")

local TextInput = {}
TextInput.__index = TextInput

-- ---- constants --------------------------------------------------------------
local FIELD_HEIGHT = 29
local FIELD_MIN_W = 40 -- floor width; the default still hugs the placeholder
local FIELD_MAX_W = 220 -- absolute ceiling regardless of row width
local TEXT_SIZE = 15
local PAD_X = 15 -- clearance each side of the text (centred)
local LABEL_GAP = 20 -- px the field always keeps clear before the label

-- Rayfield's pillResizeInfo (the width-hug animation)
local RESIZE_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local FOCUS_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SETTLE_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local REST_TEXT_TRANSPARENCY = 0.6
local REST_FIELD_TRANSPARENCY = 0.9

-- Parse a simple exponent expression like "5^3" -> 125. Falls back to tonumber
-- for plain numbers and scientific notation ("9e9" -> 9000000000).
local function parseExp(text)
	local a, b = text:match("^([%d%.%-]+)%^([%d%.%-]+)$")
	if a and b then
		local na, nb = tonumber(a), tonumber(b)
		if na and nb then
			return na ^ nb
		end
	end
	return tonumber(text)
end

-- Text width, cached per (family, size, string). Measures once via
-- GetTextBoundsAsync, then serves from the cache -- mirrors Rayfield's
-- textMetrics module so the pill hugs text without re-measuring every keystroke.
local widthCache = {}
local function measure(font, size, text)
	text = tostring(text)
	if text == "" then
		return 0
	end
	local key = tostring(font.Family) .. "|" .. tostring(size) .. "|" .. text
	local hit = widthCache[key]
	if hit then
		return hit
	end
	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = font
	params.Size = size
	params.Width = math.huge
	local ok, bounds = pcall(function()
		return TextService:GetTextBoundsAsync(params)
	end)
	local w = (ok and bounds and bounds.X) or (#text * size * 0.55)
	w = math.ceil(w)
	widthCache[key] = w
	return w
end

function TextInput.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, TextInput)
	self._theme = theme

	local name = Settings.Name or "Text Input"
	local placeholder = Settings.Placeholder or "[...]"
	local default = Settings.Default or ""
	local numeric = Settings.Numeric == true
	local clearOnFocus = Settings.ClearOnFocus == true

	-- Row + label. LabelAutoSize gives the name a variable-width working space
	-- (X size 0 + AutomaticSize.X), so the field's cap keys off its real width.
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "TextInput",
		Theme = theme,
		LabelAutoSize = true,
		LabelWidth = 0.48591,
	})

	local font = Constants.Font(Enum.FontWeight.Medium)

	-- ---- the field (the TextBox itself) -------------------------------------
	local field = Instance.new("TextBox")
	field.Name = "Field"
	field.AnchorPoint = Vector2.new(1, 0.5)
	field.Position = UDim2.fromScale(1, 0.5)
	field.Size = UDim2.fromOffset(FIELD_MIN_W, FIELD_HEIGHT) -- replaced by sizeBox below
	field.BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(255, 255, 255)
	field.BackgroundTransparency = theme.InputBackgroundTransparency or REST_FIELD_TRANSPARENCY
	field.BorderSizePixel = 0
	field.TextSize = TEXT_SIZE
	field.TextXAlignment = Enum.TextXAlignment.Center
	field.TextYAlignment = Enum.TextYAlignment.Center
	field.TextTruncate = Enum.TextTruncate.AtEnd
	field.TextWrapped = false
	field.TextColor3 = theme.PrimaryTextColor or Color3.fromRGB(240, 240, 240)
	field.PlaceholderColor3 = theme.PrimaryTextColor or Color3.fromRGB(240, 240, 240)
	field.PlaceholderText = placeholder
	field.TextTransparency = REST_TEXT_TRANSPARENCY
	field.ClearTextOnFocus = false
	field.FontFace = font
	field.Text = default
	field:SetAttribute("IsInputBackground", true)
	field.Parent = row

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = field

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.StrokeColor or Color3.fromRGB(80, 80, 80)
	stroke.Transparency = theme.StrokeTransparency or 0.4
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	-- Snapshot the resting transparency so PageFade restores to the theme value
	-- instead of capturing a mid-fade one. Mirrors RadioButton's holderStroke.
	stroke:SetAttribute("PageFadeBase", theme.StrokeTransparency or 0.4)
	stroke.Parent = field

	local glow = Instance.new("UIShadow")
	glow.Name = "FieldGlow"
	glow.Color = theme.AccentColor or Color3.fromRGB(108, 140, 255)
	glow.Transparency = 1
	glow.BlurRadius = UDim.new(0, 20)
	glow.Spread = UDim2.fromOffset(1, 1)
	glow.Parent = field

	-- Cap: the field's left edge (rowW - width) must stay at least LABEL_GAP px
	-- right of the auto-sized label.
	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(FIELD_MIN_W, FIELD_HEIGHT)
	constraint.MaxSize = Vector2.new(FIELD_MAX_W, FIELD_HEIGHT)
	constraint.Parent = field

	-- ---- helpers ------------------------------------------------------------
	local function activeTheme()
		return ActiveTheme.theme or theme
	end

	local function restFieldTransparency()
		local t = activeTheme()
		return (t and t.InputBackgroundTransparency) or REST_FIELD_TRANSPARENCY
	end

	-- Same resting stroke transparency as RadioButton (theme.StrokeTransparency
	-- or 0.4), so the two components read as one family.
	local function restStrokeTransparency()
		local t = activeTheme()
		return (t and t.StrokeTransparency) or 0.4
	end

	local function maxWidth()
		local rowW = row.AbsoluteSize.X
		if rowW <= 0 then
			return FIELD_MAX_W
		end
		local cap = rowW - label.AbsoluteSize.X - LABEL_GAP
		return math.max(FIELD_MIN_W, math.min(FIELD_MAX_W, cap))
	end

	-- Hug: shown = typed text, or the placeholder when empty. The pill's width
	-- is measured text + PAD_X*2, clamped to [min, cap], and tweened in.
	local function sizeBox(animate)
		local shown = (field.Text ~= "" and field.Text) or placeholder
		local w = math.clamp(measure(font, TEXT_SIZE, shown) + PAD_X * 2, FIELD_MIN_W, maxWidth())
		if animate then
			Tween.Play(field, RESIZE_INFO, { Size = UDim2.fromOffset(w, FIELD_HEIGHT) })
		else
			field.Size = UDim2.fromOffset(w, FIELD_HEIGHT)
		end
	end
	self._sizeBox = sizeBox

	local function setFocused(lookFocused)
		Tween.Play(field, FOCUS_INFO, {
			TextTransparency = lookFocused and 0 or REST_TEXT_TRANSPARENCY,
		})
	end

	local flashToken = 0
	local function flash()
		local t = activeTheme()
		local accent = t.AccentColor or Color3.fromRGB(108, 140, 255)
		flashToken += 1
		local token = flashToken
		Tween.Play(stroke, FOCUS_INFO, { Color = accent, Transparency = 0.1 })
		Tween.Play(glow, FOCUS_INFO, { Color = accent, Transparency = 0.55 })
		task.delay(0.28, function()
			if token ~= flashToken then
				return
			end
			if not field.Parent then
				return
			end
			local settled = activeTheme()
			Tween.Play(stroke, SETTLE_INFO, {
				Color = settled.StrokeColor or Color3.fromRGB(80, 80, 80),
				Transparency = restStrokeTransparency(),
			})
			Tween.Play(glow, SETTLE_INFO, { Transparency = 1 })
		end)
	end
	self._flash = flash

	-- ---- interaction --------------------------------------------------------
	field:GetPropertyChangedSignal("Text"):Connect(function()
		if numeric then
			local cleaned = (field.Text:gsub("[^%d%.%-eE%^]", ""))
			if cleaned ~= field.Text then
				field.Text = cleaned
				return -- reassignment re-fires this; we resize on that pass
			end
		end
		sizeBox(true)
	end)

	field.Focused:Connect(function()
		setFocused(true)
	end)

	field.FocusLost:Connect(function()
		setFocused(false)

		if clearOnFocus and field.Text == "" and default ~= "" then
			field.Text = default
			return
		end

		local text = field.Text
		if numeric then
			local n = parseExp(text)
			if not n or n ~= n or n == math.huge or n == -math.huge then
				if field.Text ~= default then
					field.Text = default
				end
				return
			end
			text = tostring(n)
		end

		local changed = text ~= default
		default = text
		if field.Text ~= text then
			field.Text = text
		end

		if Settings.Callback then
			Settings.Callback(text)
		end
		if changed then
			flash()
		end
	end)

	-- Hover: brighten the stroke on mouse-over, restore on leave -- same feel as
	-- RadioButton (hover = resting transparency * 0.5).
	field.MouseEnter:Connect(function()
		Tween.Play(stroke, "HoverIn", { Transparency = restStrokeTransparency() * 0.5 })
	end)
	field.MouseLeave:Connect(function()
		Tween.Play(stroke, "HoverOut", { Transparency = restStrokeTransparency() })
	end)

	-- Recompute the cap (and re-hug) if the row or the auto-sized label resizes.
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		sizeBox(false)
	end)
	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		sizeBox(false)
	end)

	-- ---- public API ---------------------------------------------------------
	self.GetText = function()
		return field.Text
	end
	self.SetText = function(newText, silent)
		newText = tostring(newText or "")
		default = newText
		field.Text = newText
		if not silent then
			flash()
		end
	end
	self.UpdateName = function(newName)
		label.Text = newName
		sizeBox(false)
	end
	self.SetPlaceholder = function(newPlaceholder)
		placeholder = newPlaceholder
		field.PlaceholderText = newPlaceholder
		sizeBox(true)
	end
	self.Flash = flash

	-- ---- theme bindings -----------------------------------------------------
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(field, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindTransparency(field, "BackgroundTransparency", "InputBackgroundTransparency")
	ThemeManager.BindColor(field, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindColor(field, "PlaceholderColor3", "PrimaryTextColor")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	-- Theme-bound stroke transparency: matches RadioButton, publishes
	-- ThemeLive_Transparency so PageFade reads the correct resting value and a
	-- theme switch re-resolves it (previously set once, never re-themed).
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	ThemeManager.BindColor(glow, "Color", "AccentColor")

	field.TextColor3 = theme.PrimaryTextColor or Color3.fromRGB(240, 240, 240)
	field.PlaceholderColor3 = theme.PrimaryTextColor or Color3.fromRGB(240, 240, 240)
	field.BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(255, 255, 255)
	field.BackgroundTransparency = restFieldTransparency()
	stroke.Color = theme.StrokeColor or Color3.fromRGB(80, 80, 80)
	stroke.Transparency = restStrokeTransparency()
	glow.Color = theme.AccentColor or Color3.fromRGB(108, 140, 255)
	glow.Transparency = 1

	sizeBox(false) -- initial hug: placeholder width + 30, no animation
	task.defer(function()
		sizeBox(false) -- after the first layout pass, once AbsoluteSize is real
	end)

	-- ---- uniform component API ----------------------------------------------
	self.SetVisibility = function(_self, visible)
		row.Visible = visible
	end
	self.Destroy = function(_self)
		Tween.CancelAll(field)
		Tween.CancelAll(stroke)
		Tween.CancelAll(glow)
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(field)
		ThemeManager.UnbindInstance(stroke)
		ThemeManager.UnbindInstance(glow)
		if row and row.Parent then
			row:Destroy()
		end
	end

	return self
end

return TextInput
