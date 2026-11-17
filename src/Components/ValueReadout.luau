--[[
	Aetheris/Components/ValueReadout.luau

	The numeric readout shared by Slider and Stepper: at rest the value renders
	through an odometer, and focusing swaps in a themed text field.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Tween = require("../Utils/Tween")
local Odometer = require("../Utils/Odometer")
local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

local ValueReadout = {}
ValueReadout.__index = ValueReadout

-- Bare at rest; the resting alpha doubles as the PageFade base.
local REST_STROKE = 1
local HOVER_STROKE = 0.45
local FOCUS_STROKE = 0.3

local STROKE_THICKNESS = 0.7
local STROKE_COLOR = Color3.fromRGB(80, 80, 80)

-- Accepted options: theme, size, position, text and layout settings.
function ValueReadout.new(parent, opts)
	opts = opts or {}
	local self = setmetatable({}, ValueReadout)
	local theme = ThemeManager.GetTheme(opts.Theme)

	local textSize = opts.TextSize or 12
	local weight = opts.Weight or Enum.FontWeight.Medium
	local cornerRadius = opts.CornerRadius or 4

	-- Child layers paint above the box text, so the reel wins at rest.
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
	box:SetAttribute(UUID.Static("IsInputBackground"), true)
	box.Parent = parent
	self.Instance = box

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, cornerRadius)
	corner.Parent = box

	-- Above the text; hidden while the field is showing.
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
	stroke.Color = theme.StrokeColor or STROKE_COLOR
	stroke.Transparency = REST_STROKE
	stroke.Thickness = STROKE_THICKNESS
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = box
	-- Page fades restore the resting alpha, never a brighten.
	stroke:SetAttribute(UUID.Static("PageFadeBase"), REST_STROKE)
	self.Stroke = stroke

	local focused = false
	local hovered = false
	-- Off-page the glyphs are transparent, so the value reads as zeroed.
	local dimmed = false
	self._text = ""

	-- Glyphs snap so reel and text never overlap; field and stroke fade.
	local function sync(animate)
		local live = ActiveTheme.theme or theme
		local strokeColor = live.StrokeColor or STROKE_COLOR
		local strokeAlpha = focused and FOCUS_STROKE or (hovered and HOVER_STROKE or REST_STROKE)
		local boxAlpha = focused and (live.InputBackgroundTransparency or 0.5) or 1
		local textAlpha = focused and (live.SecondaryTextTransparency or 0.4) or 1

		box.TextTransparency = textAlpha
		odo:setTransparency((focused or dimmed) and 1 or 0)
		if animate then
			Tween.Play(box, "Fast", { BackgroundTransparency = boxAlpha })
			Tween.Play(stroke, "Fast", { Color = strokeColor, Transparency = strokeAlpha })
		else
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
		-- Snap to the last committed text, which OnCommit may have normalised.
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

	-- A nil direction snaps; otherwise the digits roll the given way.
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

	-- The instant flag skips the tween so the first restore has distance.
	self.SetDimmed = function(_, on, instant)
		local target = on == true
		if target == dimmed then
			return
		end
		dimmed = target
		sync(instant ~= true)
	end

	self.Destroy = function()
		Tween.CancelAllUnder(box)
		ThemeManager.UnbindInstance(box)
		ThemeManager.UnbindInstance(stroke)
		ThemeManager.UnbindInstance(reel)
		for _, descendant in ipairs(reel:GetDescendants()) do
			ThemeManager.UnbindInstance(descendant)
		end
		if box.Parent then
			box:Destroy()
		end
	end

	-- Stroke colour and alphas are re-stamped on every theme apply.
	ThemeManager.BindColor(box, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindColor(box, "TextColor3", "SecondaryTextColor")
	ThemeManager.OnThemeApplied(function(liveTheme)
		theme = liveTheme or theme
		stroke:SetAttribute(UUID.Static("PageFadeBase"), REST_STROKE)
		sync(true)
	end, box)

	sync(false)
	return self
end

return ValueReadout
