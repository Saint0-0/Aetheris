--[[
	Slider  ·  Aetheris UI Library

	Draggable value slider. Mechanics are a 1:1 port of Rayfield gen2's
	slider (src/components/slider.luau); the look, readout, reset button and
	spinning fill gradient are ours and are preserved.

	Rayfield mechanics copied verbatim:
		· The pill is a CHILD of the fill and is carried by it -- it has no
		  position of its own. Position = UDim2.fromScale(1, 0.5), centred on
		  the fill's leading edge, so half of it hangs past the track at each
		  end of the range.
		· Pointer travel is the WHOLE track (ratioFromPointer maps straight
		  across it).
		· snapTo() snaps onto an increment grid anchored at range[1], so both
		  endpoints stay reachable.
		· Press grows the pill (35x20 -> 41x22, 0.3 Exponential Out), ghosts
		  it (BackgroundTransparency 0.7) and fades its stroke in (0.6).
		· Drag is a RenderStepped follow that self-terminates, plus
		  InputEnded AND WindowFocusReleased both ending the drag.
		· The fill follows the value with a 0.3 Quint Out tween mid-drag.

	Kept from ours: the spinning gradient (Tween.StartSpin), the percentage
	/ value readout, the reset button and the theme bindings.

	Usage:
		local slider = section:Slider({
			Name = "Smoothness", Min = 0, Max = 100, Default = 50,
			Callback = function(value) end,
		})
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Tween = require("../Utils/Tween")
local Icons = require("../Assets/Icons")
local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local Constants = require("../Constants")
local ComponentRow = require("./ComponentRow")

local Slider = {}
Slider.__index = Slider

-- ---- Rayfield mechanics constants (copied from slider.luau) ----------------
local TWEEN_INFO  = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local HELD_INFO   = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local FOLLOW_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- The pill's two sizes: at rest, and while it's held.
local HANDLE_REST = Vector2.new(35, 15)
local HANDLE_HELD = Vector2.new(41, 17)

-- Decimal places implied by an increment (0.1 -> 1, 0.25 -> 2, 1 -> 0). Checks
-- against the nearest whole number at each scale so float error can't inflate
-- the count (0.07 * 10 is 0.7000000000000001, still 2 decimals).
local function decimalsOf(step)
	local decimals = 0
	while decimals < 6 do
		local scaled = step * 10 ^ decimals
		if math.abs(scaled - math.round(scaled)) < 1e-9 then
			break
		end
		decimals += 1
	end
	return decimals
end

-- snap onto the increment grid anchored at range[1], so both endpoints stay
-- reachable (a zero-anchored grid can't express range = {0.5, 2.5} with inc 1).
local function snapTo(range, increment, value)
	local snapped = range[1] + math.round((value - range[1]) / increment) * increment
	return math.clamp(snapped, range[1], range[2])
end

-- The fill is a plain ratio of the track; the pill rides its leading edge.
local function fillSize(ratio)
	return UDim2.fromScale(ratio, 1)
end

-- The pill sits centred on the fill's leading edge and lives inside the fill,
-- so it tracks the value without a position of its own.
local function handleOffset()
	return UDim2.fromScale(1, 0.5)
end

-- The pointer maps over the whole track, because the pill's centre does too.
local function ratioFromPointer(x, left, travel)
	return math.clamp((x - left) / travel, 0, 1)
end

function Slider.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local spinEnabled = (Settings.SpinningEnabled == nil) and true or Settings.SpinningEnabled
	local self = setmetatable({}, Slider)
	self._theme = theme

	local name = Settings.Name or "Slider"
	local min = Settings.Min or 0
	local max = Settings.Max or 100
	local increment = Settings.Increment or Settings.Step or 1
	local default = Settings.Default or 50
	local precision = Settings.Precision or decimalsOf(increment)

	-- keep range ascending and increment positive so the clamp/snap math is sane
	if min > max then
		min, max = max, min
	end
	if increment <= 0 then
		increment = 1
	end

	-- Main row frame (shared factory; height 52 preserved).
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "Slider",
		Theme = theme,
		Height = 52,
		LabelWidth = 0.59985,
		LabelHeight = 0.31745,
		LabelPosition = UDim2.fromScale(0, 0.05),
		LabelAnchorPoint = Vector2.new(0, 0),
	})

	-- ---- track (Rayfield's `track`) -----------------------------------------
	local holder = Instance.new("Frame")
	holder.Name = "SliderHolder"
	holder.BorderSizePixel = 0
	holder.BackgroundColor3 = theme.Undercolor
	holder.BackgroundTransparency = 0
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Size = UDim2.new(0.9, 0, 0, 4)
	holder.Position = UDim2.new(0.5, 0, 0.62, 5)
	holder.BorderColor3 = Color3.fromRGB(255, 255, 255)
	holder.Parent = row
	local holderCorner = Instance.new("UICorner")
	holderCorner.CornerRadius = UDim.new(0, 4)
	holderCorner.Parent = holder
	local holderShadow = Instance.new("UIShadow")
	holderShadow.Parent = holder

	-- ---- fill (Rayfield's `progress`) ---------------------------------------
	local visual = Instance.new("Frame")
	visual.Name = "SliderVisual"
	visual.BorderSizePixel = 0
	visual.BackgroundColor3 = (theme and theme.PrimaryColor)
	visual.Size = UDim2.fromScale(0, 1)
	visual.BorderColor3 = Color3.fromRGB(0, 0, 0)
	visual.Parent = holder
	local visualCorner = Instance.new("UICorner")
	visualCorner.CornerRadius = UDim.new(0, 4)
	visualCorner.Parent = visual

	-- spinning sheen inside the fill (ours)
	local backImage = Instance.new("ImageLabel")
	backImage.Name = "BackImage"
	backImage.BorderSizePixel = 0
	backImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	backImage.ImageTransparency = 0.5
	backImage.AnchorPoint = Vector2.new(0.5, 0.5)
	backImage.Image = theme.Wallpaper or "rbxassetid://11094025229"
	backImage:SetAttribute("IsThemeSheen", true)
	backImage.Size = UDim2.fromScale(1, 1)
	backImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	backImage.BackgroundTransparency = 1
	backImage.Position = UDim2.fromScale(0.5, 0.5)
	backImage.Parent = visual
	backImage.Visible = not (theme and theme.WallpaperEnabled == false)
	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 4)
	backCorner.Parent = backImage
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.000, 1),
		NumberSequenceKeypoint.new(0.324, 0.80625),
		NumberSequenceKeypoint.new(0.600, 0.6875),
		NumberSequenceKeypoint.new(0.726, 0.55),
		NumberSequenceKeypoint.new(0.844, 0.36875),
		NumberSequenceKeypoint.new(1.000, 0),
	})
	gradient.Parent = backImage

	-- ---- the pill (Rayfield's `handle`) -- a child of the FILL, carried by it -
	local thumb = Instance.new("ImageButton")
	thumb.Name = "SliderButton"
	thumb.BorderSizePixel = 0
	thumb.AutoButtonColor = false
	thumb.ImageTransparency = 1
	thumb.BackgroundTransparency = 0
	thumb.BackgroundColor3 = theme.AccentColor or Color3.fromRGB(255, 255, 255)
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Position = handleOffset() -- centred on the fill's leading edge
	thumb.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	thumb.Size = UDim2.fromOffset(HANDLE_REST.X, HANDLE_REST.Y)
	thumb.BorderColor3 = Color3.fromRGB(0, 0, 0)
	thumb.Parent = visual -- <- carried by the fill, not positioned on the track
	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0)
	thumbCorner.Parent = thumb
	local thumbStroke = Instance.new("UIStroke")
	thumbStroke.Color = theme.AccentColor or Color3.fromRGB(255, 255, 255)
	thumbStroke.Transparency = 1
	thumbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	thumbStroke.Parent = thumb

	-- ---- readout cluster (ours) ---------------------------------------------
	local controlHolder = Instance.new("Frame")
	controlHolder.Name = "ControlHolder"
	controlHolder.AnchorPoint = Vector2.new(1, 0)
	controlHolder.Position = UDim2.fromScale(1, 0.05)
	controlHolder.Size = UDim2.fromOffset(50, 10)
	controlHolder.BackgroundTransparency = 1
	controlHolder.Parent = row

	local controlLayout = Instance.new("UIListLayout")
	controlLayout.FillDirection = Enum.FillDirection.Horizontal
	controlLayout.Padding = UDim.new(0, 5)
	controlLayout.SortOrder = Enum.SortOrder.LayoutOrder
	controlLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	controlLayout.Parent = controlHolder

	-- value readout (Rayfield's odometer host; ours is a text box)
	local statBox = Instance.new("TextBox")
	statBox.Name = "SliderStat"
	statBox.LayoutOrder = 1
	statBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	statBox.BorderSizePixel = 0
	statBox.TextTransparency = theme.SecondaryTextTransparency
	statBox.TextSize = 10
	statBox.TextColor3 = theme.SecondaryTextColor
	statBox.BackgroundColor3 = theme.InputBackgroundColor
	statBox.FontFace = Constants.Font(Enum.FontWeight.Regular)
	statBox.AutomaticSize = Enum.AutomaticSize.X
	statBox.AnchorPoint = Vector2.new(1, 0)
	statBox.TextTruncate = Enum.TextTruncate.AtEnd
	statBox.PlaceholderText = "0"
	statBox.Size = UDim2.fromOffset(56, 16)
	statBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	statBox.Text = ""
	statBox.BackgroundTransparency = theme.InputBackgroundTransparency
	statBox.Parent = controlHolder
	local statStroke = Instance.new("UIStroke")
	statStroke.Transparency = theme.StrokeTransparency
	statStroke.Color = theme.StrokeColor
	statStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	statStroke.Parent = statBox
	local statCorner = Instance.new("UICorner")
	statCorner.CornerRadius = UDim.new(0, 4)
	statCorner.Parent = statBox
	local statConstraint = Instance.new("UISizeConstraint")
	statConstraint.MaxSize = Vector2.new(56, 20)
	statConstraint.Parent = statBox

	-- percentage readout
	local percentLabel = Instance.new("TextLabel")
	percentLabel.Name = "PercentageStat"
	percentLabel.LayoutOrder = 2
	percentLabel.TextWrapped = true
	percentLabel.TextTruncate = Enum.TextTruncate.AtEnd
	percentLabel.BorderSizePixel = 0
	percentLabel.Size = UDim2.fromOffset(0, 16)
	percentLabel.AutomaticSize = Enum.AutomaticSize.X
	percentLabel.TextSize = 11
	percentLabel.TextTransparency = theme.SecondaryTextTransparency
	percentLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	percentLabel.FontFace = Constants.Font(Enum.FontWeight.Bold)
	percentLabel.TextColor3 = theme.SecondaryTextColor
	percentLabel.BackgroundTransparency = 1
	percentLabel.Parent = controlHolder

	-- reset button
	local resetBtn = Instance.new("ImageButton")
	resetBtn.Name = "ResetButton"
	resetBtn.LayoutOrder = 3
	resetBtn.BorderSizePixel = 0
	resetBtn.AutoButtonColor = false
	resetBtn.BackgroundTransparency = 1
	resetBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	resetBtn.Image = Icons["rotate-ccw"] or "rbxassetid://110116685948665"
	resetBtn.ImageColor3 = theme.AccentColor
	resetBtn.Size = UDim2.fromOffset(13, 13)
	resetBtn.BorderColor3 = Color3.fromRGB(0, 0, 0)
	resetBtn.AnchorPoint = Vector2.new(1, 0.5)
	resetBtn.Parent = controlHolder
	local resetAspect = Instance.new("UIAspectRatioConstraint")
	resetAspect.Parent = resetBtn

	-- ---- state --------------------------------------------------------------
	local currentValue = snapTo({ min, max }, increment, default)
	local isDragging = false
	local isHovered = false
	local dragConnection = nil

	local function formatValue(val)
		return string.format("%." .. precision .. "f", val)
	end

	-- ---- rendering ----------------------------------------------------------
	-- The fill carries the pill, so a single Size write moves both. `info`
	-- chooses the tween (follow mid-drag, set on programmatic changes).
	local function renderProgress(info)
		local span = max - min
		local ratio = (span ~= 0) and math.clamp((currentValue - min) / span, 0, 1) or 0
		local size = fillSize(ratio)
		if info then
			TweenService:Create(visual, info, { Size = size }):Play()
		else
			visual.Size = size
		end
	end

	local function setHeld(held)
		local target = held and HANDLE_HELD or HANDLE_REST
		TweenService:Create(thumb, HELD_INFO, {
			Size = UDim2.fromOffset(target.X, target.Y),
			BackgroundTransparency = held and 0.7 or 0,
		}):Play()
		TweenService:Create(thumbStroke, HELD_INFO, { Transparency = held and 0.6 or 1 }):Play()
		renderProgress(HELD_INFO)
	end

	local function updateVisibility()
		local active = isHovered or isDragging
		local target = active and 0 or 0.5
		Tween.Play(percentLabel, "Fast", { TextTransparency = target })
		Tween.Play(backImage, "Fast", { ImageTransparency = target })
	end

	-- pointer -> value, mapped over the WHOLE track (Rayfield's _updateFromMouse)
	local function updateFromMouse()
		local travel = math.max(holder.AbsoluteSize.X, 0)
		if travel <= 0 then
			return
		end
		local ratio = ratioFromPointer(UserInputService:GetMouseLocation().X, holder.AbsolutePosition.X, travel)
		local value = snapTo({ min, max }, increment, min + ratio * (max - min))
		if value ~= currentValue then
			currentValue = value
			renderProgress(FOLLOW_INFO)
			statBox.Text = formatValue(value)
			statBox.PlaceholderText = formatValue(value)
			percentLabel.Text = math.round(ratio * 100) .. "%"
			if Settings.Callback then
				Settings.Callback(value)
			end
		end
	end

	-- ---- drag ---------------------------------------------------------------
	local function endDrag()
		if not isDragging then
			return
		end
		isDragging = false
		setHeld(false)
		if dragConnection then
			dragConnection:Disconnect()
			dragConnection = nil
		end
		updateVisibility()
	end

	local function beginDrag(_input)
		isDragging = true
		setHeld(true)
		updateFromMouse()
		if dragConnection then
			dragConnection:Disconnect()
			dragConnection = nil
		end
		-- per-frame follow while held; self-terminates when the drag ends
		dragConnection = RunService.RenderStepped:Connect(function()
			if not isDragging then
				if dragConnection then
					dragConnection:Disconnect()
					dragConnection = nil
				end
				return
			end
			updateFromMouse()
		end)
	end

	thumb.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)

	holder.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			endDrag()
		end
	end)

	-- releasing the button outside the Roblox window never fires InputEnded, so
	-- treat losing focus as letting go too - otherwise the slider sticks to the
	-- cursor forever.
	UserInputService.WindowFocusReleased:Connect(endDrag)

	-- ---- hover --------------------------------------------------------------
	thumb.MouseEnter:Connect(function()
		isHovered = true
		updateVisibility()
	end)
	thumb.MouseLeave:Connect(function()
		isHovered = false
		updateVisibility()
	end)

	-- ---- value setters ------------------------------------------------------
	local function updateSlider(value, snapSmooth)
		value = snapTo({ min, max }, increment, value)
		currentValue = value
		local span = max - min
		local ratio = (span ~= 0) and math.clamp((value - min) / span, 0, 1) or 0
		renderProgress(snapSmooth and TWEEN_INFO or nil)
		percentLabel.Text = math.round(ratio * 100) .. "%"
		statBox.Text = formatValue(value)
		statBox.PlaceholderText = formatValue(value)
		if Settings.Callback then
			Settings.Callback(value)
		end
	end

	statBox.FocusLost:Connect(function()
		local inputValue = tonumber(statBox.Text)
		if inputValue then
			updateSlider(inputValue, true)
		else
			statBox.Text = formatValue(currentValue)
		end
	end)

	resetBtn.MouseButton1Click:Connect(function()
		updateSlider(default, true)
		-- one full turn on click, settling with a Back ease
		TweenService:Create(
			resetBtn,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Rotation = resetBtn.Rotation + 360 }
		):Play()
		-- a quick squash-and-pop so the click reads even if you miss the spin
		TweenService:Create(
			resetBtn,
			TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.fromOffset(10, 10) }
		):Play()
		task.delay(0.12, function()
			if resetBtn.Parent then
				TweenService:Create(
					resetBtn,
					TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Size = UDim2.fromOffset(13, 13) }
				):Play()
			end
		end)
	end)
	resetBtn.MouseEnter:Connect(function()
		resetBtn.ImageColor3 = (ActiveTheme.theme or theme).AccentColor
		Tween.Play(resetBtn, "Fast", { ImageTransparency = 0.2 })
	end)
	resetBtn.MouseLeave:Connect(function()
		resetBtn.ImageColor3 = (ActiveTheme.theme or theme).AccentColor
		Tween.Play(resetBtn, "Fast", { ImageTransparency = 0 })
	end)

	-- ---- spin (ours, kept) --------------------------------------------------
	local function startSpin()
		if not spinEnabled then
			return
		end
		gradient.Rotation = 0
		Tween.StartSpin(gradient, { Rotation = 360 }, "SpinIdle")
	end
	local function stopSpin()
		Tween.StopSpin(gradient)
	end
	startSpin()

	local function disconnectAll()
		endDrag()
		stopSpin()
	end
	row.Destroying:Connect(disconnectAll)

	-- ---- init ---------------------------------------------------------------
	updateSlider(currentValue, false)
	updateVisibility()

	-- ---- public API ---------------------------------------------------------
	self.UpdateValue = function(newValue)
		updateSlider(newValue, true)
	end
	self.GetValue = function()
		return currentValue
	end
	self.SetVisibility = function(visible)
		row.Visible = visible
	end
	self.UpdateName = function(newName)
		label.Text = newName
	end
	self.EnableSpinning = function(enabled)
		if enabled then
			startSpin()
		else
			stopSpin()
		end
	end
	self.Destroy = function()
		disconnectAll()
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(holder)
		ThemeManager.UnbindInstance(visual)
		ThemeManager.UnbindInstance(resetBtn)
		ThemeManager.UnbindInstance(percentLabel)
		ThemeManager.UnbindInstance(statBox)
		ThemeManager.UnbindInstance(statStroke)
		ThemeManager.UnbindInstance(holderShadow)
		ThemeManager.UnbindInstance(thumb)
		ThemeManager.UnbindInstance(thumbStroke)
		if row.Parent then
			row:Destroy()
		end
	end

	-- ---- theme bindings -----------------------------------------------------
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(holder, "BackgroundColor3", "Undercolor")
	ThemeManager.BindColor(visual, "BackgroundColor3", "PrimaryColor")
	ThemeManager.BindColor(resetBtn, "ImageColor3", "AccentColor")
	ThemeManager.BindColor(percentLabel, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(percentLabel, "TextTransparency", "SecondaryTextTransparency")
	ThemeManager.BindColor(statBox, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(statBox, "TextTransparency", "SecondaryTextTransparency")
	ThemeManager.BindColor(statBox, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindTransparency(statBox, "BackgroundTransparency", "InputBackgroundTransparency")
	ThemeManager.BindColor(statStroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(statStroke, "Transparency", "StrokeTransparency")
	ThemeManager.BindColor(holderShadow, "Color", "ComponentShadowColor")
	ThemeManager.BindColor(thumb, "BackgroundColor3", "AccentColor")
	ThemeManager.BindColor(thumbStroke, "Color", "AccentColor")
	ThemeManager.Bind(backImage, "Image", "Wallpaper", {
		transform = function(v)
			return v or "rbxassetid://11094025229"
		end,
	})
	ThemeManager.Bind(backImage, "Visible", "WallpaperEnabled", {
		transform = function(v)
			return v ~= false
		end,
	})

	self.ApplyTheme = function(me, newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		me._theme = theme
		holder.BackgroundTransparency = 0
		visual.BackgroundTransparency = 0
		resetBtn.ImageTransparency = 0
		thumb.BackgroundTransparency = 0
		backImage.ImageTransparency = 0.5
		updateVisibility()
	end

	ThemeManager.Register(row, self)
	return self
end

return Slider
