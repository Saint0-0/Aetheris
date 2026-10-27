--[[
	Aetheris/Components/Slider.luau

	Draggable value slider. The drag mechanics are a 1:1 port of Rayfield
	gen2's slider; the look, readout, reset button and spinning fill gradient
	are ours. The pill is a child of the fill and rides its leading edge.
	License: Saint0-0 Source License - use in your own scripts, no editing or
	redistribution without permission. (c) 2026 Saint0-0.
	Based on Rayfield Gen 2 code (MPL-2.0)
	https://github.com/SiriusSoftwareLtd/rayfield-gen2
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
local ValueReadout = require("./ValueReadout")
local ComponentAPI = require("../Utils/ComponentAPI")
local PageAwareness = require("../Utils/PageAwareness")
local UUID = require("../Utils/UUID")

local Slider = {}
Slider.__index = Slider

local TWEEN_INFO = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local HELD_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local FOLLOW_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local HANDLE_REST = Vector2.new(35, 15)
local HANDLE_HELD = Vector2.new(41, 17)

-- float error can't inflate the count (0.07 * 10 is 0.7000000000000001)
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

-- snap onto a grid anchored at range[1]; a zero-anchored grid can't express
-- range = {0.5, 2.5} with increment 1
local function snapTo(range, increment, value)
	local snapped = range[1] + math.round((value - range[1]) / increment) * increment
	return math.clamp(snapped, range[1], range[2])
end

local function fillSize(ratio)
	return UDim2.fromScale(ratio, 1)
end

-- the pill lives inside the fill, so it tracks the value with no position of its own
local function handleOffset()
	return UDim2.fromScale(1, 0.5)
end

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

	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "Slider",
		Theme = theme,
		Height = 52,
		LabelWidth = 0.5,
		LabelHeight = 0.4,
		LabelTextSize = 14,
		LabelPosition = UDim2.fromScale(0, 0.05),
		LabelAnchorPoint = Vector2.new(0, 0),
	})

	local holder = Instance.new("Frame")
	holder.Name = UUID.Static("SliderHolder")
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

	local visual = Instance.new("Frame")
	visual.Name = UUID.Static("SliderVisual")
	visual.BorderSizePixel = 0
	visual.BackgroundColor3 = (theme and theme.PrimaryColor)
	visual.Size = UDim2.fromScale(0, 1)
	visual.BorderColor3 = Color3.fromRGB(0, 0, 0)
	visual.Parent = holder
	local visualCorner = Instance.new("UICorner")
	visualCorner.CornerRadius = UDim.new(0, 4)
	visualCorner.Parent = visual

	local backImage = Instance.new("ImageLabel")
	backImage.Name = UUID.Static("BackImage")
	backImage.BorderSizePixel = 0
	backImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	backImage.ImageTransparency = 0.5
	backImage.AnchorPoint = Vector2.new(0.5, 0.5)
	backImage.Image = theme.Wallpaper or "rbxassetid://11094025229"
	backImage:SetAttribute(UUID.Static("IsThemeSheen"), true)
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

	local thumb = Instance.new("ImageButton")
	thumb.Name = UUID.Static("SliderButton")
	thumb.BorderSizePixel = 0
	thumb.AutoButtonColor = false
	thumb.ImageTransparency = 1
	thumb.BackgroundTransparency = 0
	thumb.BackgroundColor3 = theme.AccentColor or Color3.fromRGB(255, 255, 255)
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Position = handleOffset()
	thumb.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	thumb.Size = UDim2.fromOffset(HANDLE_REST.X, HANDLE_REST.Y)
	thumb.BorderColor3 = Color3.fromRGB(0, 0, 0)
	thumb.Parent = visual -- carried by the fill, not positioned on the track
	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0)
	thumbCorner.Parent = thumb
	local thumbStroke = Instance.new("UIStroke")
	thumbStroke.Color = theme.AccentColor or Color3.fromRGB(255, 255, 255)
	thumbStroke.Transparency = 1
	thumbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	thumbStroke.Parent = thumb

	local controlHolder = Instance.new("Frame")
	controlHolder.Name = UUID.Static("ControlHolder")
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

	local readout = ValueReadout.new(controlHolder, {
		Theme = theme,
		Width = 45,
		Height = 17,
		TextSize = 11,
		OdometerHeight = 16,
		CornerRadius = 4,
		LayoutOrder = 1,
	})

	local percentLabel = Instance.new("TextLabel")
	percentLabel.Name = UUID.Static("PercentageStat")
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

	local resetBtn = Instance.new("ImageButton")
	resetBtn.Name = UUID.Static("ResetButton")
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

	local currentValue = snapTo({ min, max }, increment, default)
	local isDragging = false
	local isHovered = false
	local dragConnection = nil

	local function formatValue(val)
		return string.format("%." .. precision .. "f", val)
	end

	-- the fill carries the pill, so one Size write moves both; runs through the
	-- Tween registry so a page-collapse and a value change replace, not race
	local function renderProgress(info)
		local span = max - min
		local ratio = (span ~= 0) and math.clamp((currentValue - min) / span, 0, 1) or 0
		local size = fillSize(ratio)
		if info then
			Tween.Play(visual, info, { Size = size })
		else
			Tween.CancelAll(visual)
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

	local function updateFromMouse()
		local travel = math.max(holder.AbsoluteSize.X, 0)
		if travel <= 0 then
			return
		end
		local ratio = ratioFromPointer(UserInputService:GetMouseLocation().X, holder.AbsolutePosition.X, travel)
		local value = snapTo({ min, max }, increment, min + ratio * (max - min))
		if value ~= currentValue then
			local up = value > currentValue
			currentValue = value
			renderProgress(FOLLOW_INFO)
			readout:SetValue(formatValue(value), up)
			percentLabel.Text = math.round(ratio * 100) .. "%"
			if Settings.Callback then
				Settings.Callback(value)
			end
		end
	end

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
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			beginDrag(input)
		end
	end)

	holder.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			beginDrag(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			endDrag()
		end
	end)

	-- releasing outside the Roblox window never fires InputEnded, so losing
	-- focus counts as letting go too - otherwise the slider sticks to the cursor
	UserInputService.WindowFocusReleased:Connect(endDrag)

	thumb.MouseEnter:Connect(function()
		isHovered = true
		updateVisibility()
	end)
	thumb.MouseLeave:Connect(function()
		isHovered = false
		updateVisibility()
	end)

	local function updateSlider(value, snapSmooth)
		value = snapTo({ min, max }, increment, value)
		local up = value >= currentValue
		currentValue = value
		local span = max - min
		local ratio = (span ~= 0) and math.clamp((value - min) / span, 0, 1) or 0
		renderProgress(snapSmooth and TWEEN_INFO or nil)
		percentLabel.Text = math.round(ratio * 100) .. "%"
		readout:SetValue(formatValue(value), up)
		if Settings.Callback then
			Settings.Callback(value)
		end
	end

	-- typed values take the same clamp/snap/format path as the drag
	readout.OnCommit = function(value)
		updateSlider(value, true)
	end

	resetBtn.MouseButton1Click:Connect(function()
		updateSlider(default, true)
		TweenService:Create(
			resetBtn,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Rotation = resetBtn.Rotation + 360 }
		):Play()
		-- squash-and-pop so the click reads even if the spin is missed
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

	updateSlider(currentValue, false)
	updateVisibility()

	-- off-page the fill collapses (carrying the pill); `instant` snaps the
	-- collapse at registration so the deferred restore tweens from zero
	PageAwareness.Register(row, {
		Gate = "PageAnimations",
		OnInactive = function(instant)
			if instant then
				visual.Size = fillSize(0)
			else
				Tween.Play(visual, "Fast", { Size = fillSize(0) })
			end
		end,
		OnActive = function()
			renderProgress(TWEEN_INFO)
		end,
	})

	self.UpdateValue = function(_, newValue)
		updateSlider(newValue, true)
	end
	self.GetValue = function()
		return currentValue
	end
	self.SetVisibility = function(_, visible)
		row.Visible = visible
	end
	self.UpdateName = function(_, newName)
		label.Text = newName
	end
	self.EnableSpinning = function(_, enabled)
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
		readout:Destroy()
		ThemeManager.UnbindInstance(holderShadow)
		ThemeManager.UnbindInstance(thumb)
		ThemeManager.UnbindInstance(thumbStroke)
		if row.Parent then
			row:Destroy()
		end
	end

	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(holder, "BackgroundColor3", "Undercolor")
	ThemeManager.BindColor(visual, "BackgroundColor3", "PrimaryColor")
	ThemeManager.BindColor(resetBtn, "ImageColor3", "AccentColor")
	ThemeManager.BindColor(percentLabel, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(percentLabel, "TextTransparency", "SecondaryTextTransparency")
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
	ComponentAPI.Apply(self, { Root = row, Label = label, Name = name })
	return self
end

return Slider
