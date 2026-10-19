--[[
	ValueReadout  ·  Aetheris UI Library

	The numeric chip shared by Slider and Stepper: at rest it renders the value
	through an odometer on an accent card (the LiveStat look); focusing swaps
	the card for a themed text field. Focus loss commits the typed number
	through OnCommit(value), then the chip snaps back.
]]

local Tween = require("../Utils/Tween")
local Odometer = require("../Utils/Odometer")
local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

local ValueReadout = {}
ValueReadout.__index = ValueReadout

-- Accent-stroke alphas per interaction state; the resting value doubles as the
-- PageFade base so a page fade can never restore a transient hover brighten.
local REST_STROKE = 0.65
local HOVER_STROKE = 0.45
local FOCUS_STROKE = 0.3

-- lighten toward white by `t` (the LiveStat accent-stroke recipe)
local function lighten(c, t)
	return Color3.new(c.R + (1 - c.R) * t, c.G + (1 - c.G) * t, c.B + (1 - c.B) * t)
end

-- opts: Theme, Size or Width/Height, Position, AnchorPoint, LayoutOrder,
--       TextSize, OdometerHeight, CornerRadius, Weight, ClearTextOnFocus
function ValueReadout.new(parent, opts)
	opts = opts or {}
	local self = setmetatable({}, ValueReadout)
	local theme = ThemeManager.GetTheme(opts.Theme)

	local textSize = opts.TextSize or 12
	local weight = opts.Weight or Enum.FontWeight.Medium
	local cornerRadius = opts.CornerRadius or 4

	-- Root: the editable field. The chip is painted by child layers that sit
	-- above the text, so focusing/leaving crossfades the card over it.
	local box = Instance.new("TextBox")
	box.Name = UUID.Generate("ValueReadout")
	box.AnchorPoint = opts.AnchorPoint or Vector2.new(0, 0)
	box.Position = opts.Position or UDim2.fromScale(0, 0)
	box.Size = opts.Size or UDim2.fromOffset(opts.Width or 56, opts.Height or 17)
	box.LayoutOrder = opts.LayoutOrder or 0
	box.BorderSizePixel = 0
	box.BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(30, 30, 34)
	box.BackgroundTransparency = 1
	box.TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
	box.TextTransparency = 1
	box.TextSize = textSize
	box.TextXAlignment = Enum.TextXAlignment.Center
	box.TextYAlignment = Enum.TextYAlignment.Center
	box.TextTruncate = Enum.TextTruncate.AtEnd
	box.ClearTextOnFocus = (opts.ClearTextOnFocus == nil) and true or opts.ClearTextOnFocus
	box.PlaceholderText = ""
	box.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	box.FontFace = Constants.Font(weight)
	box:SetAttribute("IsInputBackground", true)
	box.Parent = parent
	self.Instance = box

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, cornerRadius)
	corner.Parent = box

	-- Chip: solid accent card + the LiveStat diagonal sheen, in miniature.
	local chip = Instance.new("Frame")
	chip.Name = UUID.Static("Chip")
	chip.BorderSizePixel = 0
	chip.BackgroundColor3 = theme.AccentColor or Color3.fromRGB(96, 165, 250)
	chip.BackgroundTransparency = 0
	chip.Size = UDim2.fromScale(1, 1)
	chip.ZIndex = box.ZIndex
	chip.Parent = box

	local chipCorner = Instance.new("UICorner")
	chipCorner.CornerRadius = UDim.new(0, cornerRadius)
	chipCorner.Parent = chip

	local sheen = Instance.new("Frame")
	sheen.Name = UUID.Static("Sheen")
	sheen.BorderSizePixel = 0
	sheen.BackgroundColor3 = theme.AccentColor or Color3.fromRGB(96, 165, 250)
	sheen.BackgroundTransparency = 0
	sheen.Size = UDim2.fromScale(1, 1)
	sheen.ZIndex = box.ZIndex
	sheen.Parent = chip

	local sheenCorner = Instance.new("UICorner")
	sheenCorner.CornerRadius = UDim.new(0, cornerRadius)
	sheenCorner.Parent = sheen

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = -55
	gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 120, 120))
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.12),
	})
	gradient.Parent = sheen

	-- Odometer reel: above the card, hidden while the text field is showing.
	local reel = Instance.new("Frame")
	reel.Name = UUID.Static("Reel")
	reel.BackgroundTransparency = 1
	reel.BorderSizePixel = 0
	reel.Size = UDim2.fromScale(1, 1)
	reel.ClipsDescendants = true
	reel.ZIndex = box.ZIndex + 1
	reel.Parent = box

	local odo = Odometer.new(reel, {
		textSize = textSize,
		height = opts.OdometerHeight or (textSize + 4),
		alignment = Enum.HorizontalAlignment.Center,
		weight = weight,
		duration = 0.28,
	})
	self.Odometer = odo

	local stroke = Instance.new("UIStroke")
	stroke.Color = lighten(theme.AccentColor or Color3.fromRGB(96, 165, 250), 0.22)
	stroke.Transparency = REST_STROKE
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = box
	-- Page fades restore the RESTING alpha, never a hover/focus brighten.
	stroke:SetAttribute("PageFadeBase", REST_STROKE)
	self.Stroke = stroke

	local focused = false
	local hovered = false
	self._text = ""

	-- Re-stamp the current interaction state. Glyph transparencies snap so the
	-- odometer and the typed text never overlap; card, field and stroke fade.
	local function sync(animate)
		local live = ActiveTheme.theme or theme
		local accent = live.AccentColor or Color3.fromRGB(96, 165, 250)
		local strokeColor = focused and (live.StrokeColor or Color3.fromRGB(80, 80, 80)) or lighten(accent, 0.22)
		local strokeAlpha = focused and FOCUS_STROKE or (hovered and HOVER_STROKE or REST_STROKE)
		local chipAlpha = focused and 1 or 0
		local boxAlpha = focused and (live.InputBackgroundTransparency or 0.5) or 1
		local textAlpha = focused and (live.SecondaryTextTransparency or 0.4) or 1

		box.TextTransparency = textAlpha
		odo:setTransparency(focused and 1 or 0)
		if animate then
			Tween.Play(chip, "Fast", { BackgroundTransparency = chipAlpha })
			Tween.Play(sheen, "Fast", { BackgroundTransparency = chipAlpha })
			Tween.Play(box, "Fast", { BackgroundTransparency = boxAlpha })
			Tween.Play(stroke, "Fast", { Color = strokeColor, Transparency = strokeAlpha })
		else
			chip.BackgroundTransparency = chipAlpha
			sheen.BackgroundTransparency = chipAlpha
			box.BackgroundTransparency = boxAlpha
			stroke.Color = strokeColor
			stroke.Transparency = strokeAlpha
		end
	end

	box.Focused:Connect(function()
		focused = true
		sync(true)
	end)

	box.FocusLost:Connect(function()
		local num = tonumber(box.Text)
		if num ~= nil and self.OnCommit then
			self.OnCommit(num)
		end
		-- Snap to the last committed text: an OnCommit that changed the value
		-- re-stamped it (normalising e.g. "007" -> "7").
		box.Text = self._text
		focused = false
		sync(true)
	end)

	box.MouseEnter:Connect(function()
		hovered = true
		if not focused then
			sync(true)
		end
	end)

	box.MouseLeave:Connect(function()
		hovered = false
		if not focused then
			sync(true)
		end
	end)

	-- Display `text`; `up` = nil snaps, otherwise the digits roll in that
	-- direction (true = up).
	self.SetValue = function(me, text, up)
		text = tostring(text)
		me._text = text
		box.Text = text
		if up == nil then
			odo:snap(text)
		else
			odo:to(text, up)
		end
	end

	self.GetText = function(me)
		return me._text
	end

	self.Destroy = function()
		Tween.CancelAllUnder(box)
		ThemeManager.UnbindInstance(box)
		ThemeManager.UnbindInstance(chip)
		ThemeManager.UnbindInstance(sheen)
		ThemeManager.UnbindInstance(stroke)
		ThemeManager.UnbindInstance(reel)
		for _, descendant in ipairs(reel:GetDescendants()) do
			ThemeManager.UnbindInstance(descendant)
		end
		if box.Parent then
			box:Destroy()
		end
	end

	-- Declarative colours; the accent-derived stroke and the state alphas are
	-- not theme keys, so they are re-stamped on every theme apply instead
	-- (owner = box auto-unregisters the callback on destroy).
	ThemeManager.BindColor(box, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindColor(box, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindColor(chip, "BackgroundColor3", "AccentColor")
	ThemeManager.BindColor(sheen, "BackgroundColor3", "AccentColor")
	ThemeManager.OnThemeApplied(function(liveTheme)
		theme = liveTheme or theme
		sync(true)
	end, box)

	sync(false)
	return self
end

return ValueReadout
