--[[
	Aetheris/Components/TextInput.luau

	The TextBox IS the field -- every visual (background, stroke, corner, glow)
	lives on the TextBox itself, flush to the row's right edge. The pill hugs
	its content: the shown string is measured once and cached, then Size.X is
	tweened, capped so the field's left edge always stays LABEL_GAP clear of
	the name label. Supports Numeric (strips non-numbers, parses "5^3" and
	"9e9") and ClearOnFocus.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
	Based on Rayfield Gen 2 code (MPL-2.0)
	https://github.com/SiriusSoftwareLtd/rayfield-gen2
]]

local TextService = game:GetService("TextService")

local Tween = require("../Utils/Tween")
local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local Constants = require("../Constants")
local ComponentRow = require("./ComponentRow")
local ComponentAPI = require("../Utils/ComponentAPI")
local UUID = require("../Utils/UUID")

local TextInput = {}
TextInput.__index = TextInput

local FIELD_HEIGHT = 29
local FIELD_MIN_W = 40
local FIELD_MAX_W = 220
local TEXT_SIZE = 11
local PAD_X = 15 -- clearance each side of the centred text
local LABEL_GAP = 20 -- the field always keeps this clear before the label

local RESIZE_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local FOCUS_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SETTLE_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local REST_TEXT_TRANSPARENCY = 0.6
local REST_FIELD_TRANSPARENCY = 0.9

-- "5^3" -> 125; falls back to tonumber for plain numbers and "9e9"
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

-- measured once per (family, size, string), then served from the cache so the
-- pill hugs text without re-measuring every keystroke
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

	-- LabelAutoSize gives the name a variable-width working space, so the
	-- field's cap keys off its real width
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "TextInput",
		Theme = theme,
		LabelAutoSize = true,
		LabelWidth = 0.48591,
	})

	local font = Constants.Font(Enum.FontWeight.Medium)

	local field = Instance.new("TextBox")
	field.Name = UUID.Static("Field")
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
	field:SetAttribute(UUID.Static("IsInputBackground"), true)
	field.Parent = row

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = field

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.StrokeColor or Color3.fromRGB(80, 80, 80)
	stroke.Transparency = theme.StrokeTransparency or 0.95
	stroke.Thickness = 0.7
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	-- snapshot the resting transparency so PageFade restores to the theme value,
	-- never a mid-fade one (same as Keybind's stroke)
	stroke:SetAttribute(UUID.Static("PageFadeBase"), theme.StrokeTransparency or 0.95)
	stroke.Parent = field

	local glow = Instance.new("UIShadow")
	glow.Name = UUID.Static("FieldGlow")
	glow.Color = theme.AccentColor or Color3.fromRGB(108, 140, 255)
	glow.Transparency = 1
	glow.BlurRadius = UDim.new(0, 20)
	glow.Spread = UDim2.fromOffset(1, 1)
	glow.Parent = field

	-- the field's left edge must stay at least LABEL_GAP right of the label
	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(FIELD_MIN_W, FIELD_HEIGHT)
	constraint.MaxSize = Vector2.new(FIELD_MAX_W, FIELD_HEIGHT)
	constraint.Parent = field

	local function activeTheme()
		return ActiveTheme.theme or theme
	end

	local hovered = false

	local function restFieldTransparency()
		local t = activeTheme()
		return (t and t.InputBackgroundTransparency) or REST_FIELD_TRANSPARENCY
	end

	-- the same resting base as Keybind, so the two read as one family
	local function restStrokeTransparency()
		local t = activeTheme()
		return (t and t.StrokeTransparency) or 0.95
	end

	-- bright stroke while hovered or focused, matching Keybind
	local function brightStroke(bright)
		local t = activeTheme()
		local rest = (t and t.StrokeTransparency) or 0.95
		Tween.Play(stroke, FOCUS_INFO, {
			Transparency = bright and 0.3 or rest,
			Color = (t and t.StrokeColor) or Color3.fromRGB(80, 80, 80),
		})
		-- keep PageFade's cached base at REST so a page fade never restores a
		-- transient brighten
		stroke:SetAttribute(UUID.Static("PageFadeBase"), rest)
	end

	local function maxWidth()
		local rowW = row.AbsoluteSize.X
		if rowW <= 0 then
			return FIELD_MAX_W
		end
		local cap = rowW - label.AbsoluteSize.X - LABEL_GAP
		return math.max(FIELD_MIN_W, math.min(FIELD_MAX_W, cap))
	end

	-- hug: measured shown text + PAD_X*2, clamped to [min, cap], tweened in
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
		-- bright while focused or hovered, resting otherwise
		brightStroke(lookFocused or hovered)
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
			-- settle to the bright stroke if the field was refocused during the
			-- flash, otherwise back to rest
			brightStroke(field:IsFocused() or hovered)
			Tween.Play(glow, SETTLE_INFO, { Transparency = 1 })
		end)
	end
	self._flash = flash

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

	-- bright while unfocused; focus owns the bright state while it's active
	field.MouseEnter:Connect(function()
		hovered = true
		brightStroke(true)
	end)
	field.MouseLeave:Connect(function()
		hovered = false
		if not field:IsFocused() then
			brightStroke(false)
		end
	end)

	-- recompute the cap (and re-hug) if the row or the label resizes
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		sizeBox(false)
	end)
	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		sizeBox(false)
	end)

	self.GetText = function()
		return field.Text
	end
	self.SetText = function(_, newText, silent)
		newText = tostring(newText or "")
		default = newText
		field.Text = newText
		if not silent then
			flash()
		end
	end
	self.UpdateName = function(_, newName)
		label.Text = newName
		sizeBox(false)
	end
	self.SetPlaceholder = function(_, newPlaceholder)
		placeholder = newPlaceholder
		field.PlaceholderText = newPlaceholder
		sizeBox(true)
	end
	self.Flash = flash

	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(field, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindTransparency(field, "BackgroundTransparency", "InputBackgroundTransparency")
	ThemeManager.BindColor(field, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindColor(field, "PlaceholderColor3", "PrimaryTextColor")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	-- theme-bound so PageFade reads the correct resting value and re-resolves
	-- it on a theme switch
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

	sizeBox(false) -- initial hug, no animation
	task.defer(function()
		sizeBox(false) -- after the first layout pass, once AbsoluteSize is real
	end)

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

	ComponentAPI.Apply(self, {
		Root = row,
		Label = label,
		Name = name,
		OnName = function(_, newName)
			label.Text = newName
			sizeBox(false)
		end,
	})
	return self
end

return TextInput
