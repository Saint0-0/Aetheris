--[[
	TextInput  ·  Aetheris UI Library

	Single-line text field, ported from Rayfield gen2's Input onto Aetheris's
	procedural (Instance.new + ThemeManager.Bind*) conventions.

	Look  : a right-anchored, fully-rounded pill that hugs its text. Muted text at
	        rest, opaque while focused (Rayfield's focusInfo fade).
	Behaviour: commits on FocusLost (enter or click away). When the committed
	        value actually changes, the field flashes the theme ACCENT colour --
	        the stroke and a soft glow bloom toward the accent, then settle back.
	Options: Numeric (strips non-number chars, supports "5^3" and "9e9"),
	        ClearOnFocus (blank the field on focus, restore if nothing typed).

	Usage:
		local textInput = section:TextInput({
			Name = "Input Label",
			Placeholder = "Enter text...",
			Default = "",
			Numeric = false,
			Callback = function(text) end,
		})
]]

local Tween = require("../Utils/Tween")
local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local Constants = require("../Constants")
local ComponentRow = require("./ComponentRow")

local TextInput = {}
TextInput.__index = TextInput

-- text is muted at rest, opaque while typing (Rayfield's focusInfo)
local REST_TRANSPARENCY = 0.6

-- Parse a simple exponent expression like "5^3" -> 125. Falls back to tonumber for
-- plain numbers and scientific notation ("9e9" -> 9000000000).
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

	-- Shared row factory (row name + label width preserved for layout parity).
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "TextInput",
		Theme = theme,
		LabelWidth = 0.48591,
	})

	-- The field: a right-anchored, fully-rounded pill that hugs its text.
	local inputBox = Instance.new("TextBox")
	inputBox.Name = "InputBox"
	inputBox.BorderSizePixel = 0
	inputBox.TextWrapped = false
	inputBox.TextSize = 15
	inputBox.TextXAlignment = Enum.TextXAlignment.Center
	inputBox.TextTruncate = Enum.TextTruncate.AtEnd
	inputBox.TextColor3 = theme.SecondaryTextColor
	inputBox.TextTransparency = REST_TRANSPARENCY
	inputBox.PlaceholderColor3 = theme.SecondaryTextColor
	inputBox.BackgroundColor3 = theme.InputBackgroundColor
	inputBox.BackgroundTransparency = theme.InputBackgroundTransparency
	inputBox:SetAttribute("IsInputBackground", true)
	inputBox.FontFace = Constants.Font(Enum.FontWeight.Medium)
	inputBox.ClearTextOnFocus = false
	inputBox.PlaceholderText = placeholder
	inputBox.AnchorPoint = Vector2.new(1, 0.5)
	inputBox.Position = UDim2.new(1, 0, 0.5, 0)
	inputBox.Size = UDim2.fromOffset(90, 30)
	inputBox.AutomaticSize = Enum.AutomaticSize.X
	inputBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	inputBox.Text = default
	inputBox.Parent = row

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0) -- full pill, like Rayfield's field
	corner.Parent = inputBox

	local stroke = Instance.new("UIStroke")
	stroke.Transparency = theme.StrokeTransparency or 0.85
	stroke.Thickness = 1
	stroke.Color = theme.StrokeColor
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = inputBox

	-- Soft bloom behind the field; invisible at rest, lit by the commit flash.
	local glow = Instance.new("UIShadow")
	glow.Color = theme.AccentColor or Color3.fromRGB(108, 140, 255)
	glow.Transparency = 1
	glow.BlurRadius = UDim.new(0, 12)
	glow.Spread = UDim2.fromOffset(1, 1)
	glow.Parent = inputBox

	local padding = Instance.new("UIPadding")
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.Parent = inputBox

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(70, 30)
	sizeConstraint.MaxSize = Vector2.new(200, 30)
	sizeConstraint.Parent = inputBox

	-- Resting stroke transparency, remembered so the flash can settle back to it.
	local restStrokeTrans = theme.StrokeTransparency or 0.85

	-- Hover/focus brighten -- same treatment as keybind. The PageFadeBase pin
	-- keeps a page fade from restoring a transient brighten (the "stroke stays
	-- bright/invisible until re-hover" bug).
	local function setStrokeBright(bright)
		local liveTheme = ActiveTheme.theme or theme
		local liveRest = liveTheme and liveTheme.StrokeTransparency or 0.95
		restStrokeTrans = liveRest
		local targetTrans = bright and 0.3 or liveRest
		local targetColor = liveTheme.StrokeColor
		Tween.Play(stroke, "Fast", { Transparency = targetTrans, Color = targetColor })
		stroke:SetAttribute("PageFadeBase", liveRest)
	end

	-- Accent flash: the stroke and glow bloom toward the theme accent, then
	-- settle back to rest. Cancel any in-flight flash first so rapid commits
	-- don't stack.
	local flashToken = 0
	local function flash()
		local liveTheme = ActiveTheme.theme or theme
		local accent = liveTheme.AccentColor or Color3.fromRGB(108, 140, 255)
		flashToken += 1
		local token = flashToken
		Tween.Play(stroke, "Fast", { Color = accent, Transparency = 0.15 })
		Tween.Play(glow, "Fast", { Color = accent, Transparency = 0.35 })
		task.delay(0.35, function()
			if token ~= flashToken then
				return -- a newer flash superseded this one
			end
			if not inputBox.Parent then
				return -- destroyed while flashing
			end
			local settled = ActiveTheme.theme or theme
			Tween.Play(stroke, "Release", {
				Color = settled.StrokeColor,
				Transparency = settled.StrokeTransparency or 0.85,
			})
			Tween.Play(glow, "Release", { Transparency = 1 })
		end)
	end
	self._flash = flash

	-- Hover / focus strokes
	inputBox.MouseEnter:Connect(function()
		setStrokeBright(true)
	end)
	inputBox.MouseLeave:Connect(function()
		if not inputBox:IsFocused() then
			setStrokeBright(false)
		end
	end)

	inputBox.Focused:Connect(function()
		setStrokeBright(true)
		Tween.Play(inputBox, "Fast", { TextTransparency = 0 })
	end)

	-- Commit on FocusLost (enter or click away), Rayfield-style.
	inputBox.FocusLost:Connect(function()
		Tween.Play(inputBox, "Fast", { TextTransparency = REST_TRANSPARENCY })
		setStrokeBright(false)

		-- clearOnFocus blanks the field on focus, so a click in and straight back
		-- out would commit "" over a good value. Nothing typed = nothing to commit.
		if clearOnFocus and inputBox.Text == "" and default ~= "" then
			inputBox.Text = default
			return
		end

		local text = inputBox.Text
		if numeric then
			local n = parseExp(text)
			if not n or n ~= n or n == math.huge or n == -math.huge then
				-- invalid or non-finite: revert to what we had
				if inputBox.Text ~= default then
					inputBox.Text = default
				end
				return
			end
			text = tostring(n)
		end

		local changed = text ~= default
		default = text
		if inputBox.Text ~= text then
			inputBox.Text = text
		end

		if Settings.Callback then
			Settings.Callback(text)
		end
		if changed then
			flash() -- green/accent confirmation, only when the value actually moved
		end
	end)

	-- Strip non-numeric characters as they're typed (Rayfield's numeric mode).
	inputBox:GetPropertyChangedSignal("Text"):Connect(function()
		if numeric then
			local cleaned = (inputBox.Text:gsub("[^%d%.%-eE%^]", ""))
			if cleaned ~= inputBox.Text then
				inputBox.Text = cleaned
			end
		end
	end)

	-- Public API
	self.GetText = function()
		return inputBox.Text
	end
	self.SetText = function(newText, silent)
		newText = tostring(newText or "")
		default = newText
		inputBox.Text = newText
		if not silent then
			flash()
		end
	end
	self.UpdateName = function(newName)
		label.Text = newName
	end
	self.SetPlaceholder = function(newPlaceholder)
		inputBox.PlaceholderText = newPlaceholder
	end
	self.Flash = flash

	-- Declarative theming: every themed property is a BINDING.
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(inputBox, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(inputBox, "TextTransparency", "SecondaryTextTransparency")
	ThemeManager.BindColor(inputBox, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindTransparency(inputBox, "BackgroundTransparency", "InputBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")

	-- Re-stamp AFTER the bind: BindTransparency only writes on a theme CHANGE, so
	-- without this the stroke keeps its default until the first switch.
	stroke.Transparency = theme.StrokeTransparency or 0.85

	-- Uniform component API.
	function self:SetVisibility(visible)
		row.Visible = visible
	end
	function self:Destroy()
		Tween.CancelAll(stroke)
		Tween.CancelAll(glow)
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(inputBox)
		ThemeManager.UnbindInstance(stroke)
		if row and row.Parent then
			row:Destroy()
		end
	end

	return self
end

return TextInput
