--[[
	Aetheris/Components/Graph.luau

	Animated line graph with straight segments. Points are mapped into a fixed
	plot area and every segment is a thin rotated frame, so there is no asset
	dependency or bar-graph look. SetPoints/Push tween the line between the old
	and new values.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local RunService = game:GetService("RunService")

local ThemeManager = require("../Themes/ThemeManager")
local ComponentAPI = require("../Utils/ComponentAPI")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

local Graph = {}
Graph.__index = Graph

local TITLE_HEIGHT = 18
local DEFAULT_HEIGHT = 120
local DEFAULT_MAX_POINTS = 60
local LINE_THICKNESS = 2
local DOT_SIZE = 5

local function copyPoints(points)
	local copy = {}
	for index, value in ipairs(points or {}) do
		copy[index] = tonumber(value)
	end
	return copy
end

local function formatClock(seconds)
	local value = math.max(0, math.floor((tonumber(seconds) or 0) + 0.5))
	return string.format("%d:%02d", value // 60, value % 60)
end

local function formatNumber(value)
	local n = tonumber(value) or 0
	local rounded = math.floor(n + 0.5)
	local text = tostring(math.abs(rounded))
	text = text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return rounded < 0 and ("-" .. text) or text
end

local function defaultFormat(value)
	local n = tonumber(value)
	if not n then
		return "—"
	end
	if math.abs(n) >= 100 then
		return formatNumber(n)
	end
	return (string.format("%.1f", n):gsub("%.0$", ""))
end

local function resolveFormat(formatter, value)
	if type(formatter) == "function" then
		local ok, text = pcall(formatter, value)
		return ok and tostring(text) or tostring(value)
	end
	if formatter == "percent" then
		local n = tonumber(value) or 0
		if math.abs(n) <= 1 then
			n *= 100
		end
		return string.format("%d%%", math.floor(n + 0.5))
	elseif formatter == "studs" then
		return string.format("%d studs", math.floor((tonumber(value) or 0) + 0.5))
	elseif formatter == "time" then
		return formatClock(value)
	elseif formatter == "number" then
		return formatNumber(value)
	end
	return defaultFormat(value)
end

function Graph.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Graph)
	self._theme = theme

	local name = Settings.Name or "Graph"
	local maxPoints = math.clamp(tonumber(Settings.MaxPoints) or DEFAULT_MAX_POINTS, 2, 240)
	local height = math.max(tonumber(Settings.Height) or DEFAULT_HEIGHT, 40)
	self._maxPoints = maxPoints
	self._height = height
	self._showGrid = Settings.ShowGrid ~= false
	self._showPoints = Settings.ShowPoints ~= false
	self._animate = Settings.Animate ~= false
	self._duration = math.max(tonumber(Settings.Duration) or 0.35, 0.05)
	self._format = Settings.Format
	self._rangeMin = Settings.MinValue
	self._rangeMax = Settings.MaxValue
	self._lineColor = Settings.LineColor
	self._thickness = math.max(tonumber(Settings.Thickness) or LINE_THICKNESS, 1)

	local root = Instance.new("Frame")
	root.Name = UUID.Static("Graph")
	root.BorderSizePixel = 0
	root.BackgroundColor3 = theme.ComponentBackgroundColor
	root.BackgroundTransparency = theme.ComponentBackgroundTransparency or 0.985
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.Size = UDim2.fromScale(1, 0)
	root.BorderColor3 = Color3.fromRGB(0, 0, 0)
	root.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = root
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = theme.StrokeTransparency or 0.95
	stroke.Color = theme.StrokeColor
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = root
	local rootPadding = Instance.new("UIPadding")
	rootPadding.PaddingTop = UDim.new(0, 10)
	rootPadding.PaddingBottom = UDim.new(0, 10)
	rootPadding.PaddingLeft = UDim.new(0, 10)
	rootPadding.PaddingRight = UDim.new(0, 10)
	rootPadding.Parent = root
	local rootLayout = Instance.new("UIListLayout")
	rootLayout.Padding = UDim.new(0, 5)
	rootLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rootLayout.Parent = root

	ThemeManager.BindColor(root, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(root, "BackgroundTransparency", "ComponentBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")

	local titleRow = Instance.new("Frame")
	titleRow.Name = UUID.Static("GraphTitleRow")
	titleRow.BorderSizePixel = 0
	titleRow.BackgroundTransparency = 1
	titleRow.Size = UDim2.new(1, 0, 0, TITLE_HEIGHT)
	titleRow.LayoutOrder = 0
	titleRow.Parent = root

	local title = Instance.new("TextLabel")
	title.Name = UUID.Static("ElementName")
	title.BackgroundTransparency = 1
	title.BorderSizePixel = 0
	title.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	title.Text = name
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = theme.PrimaryTextColor
	title.TextTransparency = theme.PrimaryTextTransparency or 0.3
	title.Size = UDim2.new(1, -70, 1, 0)
	title.Parent = titleRow
	ThemeManager.BindColor(title, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(title, "TextTransparency", "PrimaryTextTransparency")

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = UUID.Static("GraphValue")
	valueLabel.BackgroundTransparency = 1
	valueLabel.BorderSizePixel = 0
	valueLabel.FontFace = Constants.Font(Enum.FontWeight.SemiBold)
	valueLabel.Text = "—"
	valueLabel.TextSize = 12
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.AnchorPoint = Vector2.new(1, 0)
	valueLabel.Position = UDim2.fromScale(1, 0)
	valueLabel.Size = UDim2.fromOffset(70, TITLE_HEIGHT)
	valueLabel.TextColor3 = theme.AccentColor
	valueLabel.Parent = titleRow
	ThemeManager.BindColor(valueLabel, "TextColor3", "AccentColor")

	local plot = Instance.new("Frame")
	plot.Name = UUID.Static("GraphPlot")
	plot.BorderSizePixel = 0
	plot.ClipsDescendants = true
	plot.BackgroundColor3 = theme.InputBackgroundColor or theme.ComponentBackgroundColor
	plot.BackgroundTransparency = 0.88
	plot.Size = UDim2.new(1, 0, 0, height)
	plot.LayoutOrder = 1
	plot.Parent = root
	local plotCorner = Instance.new("UICorner")
	plotCorner.CornerRadius = UDim.new(0, 6)
	plotCorner.Parent = plot
	ThemeManager.BindColor(plot, "BackgroundColor3", "InputBackgroundColor")

	local grid = Instance.new("Frame")
	grid.Name = UUID.Static("GraphGrid")
	grid.BorderSizePixel = 0
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.fromScale(1, 1)
	grid.ZIndex = 1
	grid.Visible = self._showGrid
	grid.Parent = plot
	local gridColor = Settings.GridColor or theme.TertiaryColor or Color3.fromRGB(120, 130, 150)
	local gridLines = {}
	for index = 0, 4 do
		local line = Instance.new("Frame")
		line.Name = UUID.Generate("GraphGridLine")
		line.BorderSizePixel = 0
		line.BackgroundColor3 = gridColor
		line.AnchorPoint = Vector2.new(0, 0.5)
		line.Position = UDim2.fromScale(0, index / 4)
		line.Size = UDim2.new(1, 0, 0, 1)
		line.ZIndex = 1
		if index == 0 or index == 4 then
			line.BackgroundTransparency = 0.78
		else
			line.BackgroundTransparency = 0.9
		end
		line.Parent = grid
		gridLines[#gridLines + 1] = line
	end

	self._displayed = {}
	self._target = {}
	self._start = {}
	self._frames = {} -- Reused segment frames.
	self._dots = {} -- Reused point dots.

	local renderStepped
	local animationStart

	local function lineColor(applied)
		return self._lineColor or applied.AccentColor or Color3.fromRGB(96, 165, 250)
	end

	local function bounds()
		local min = tonumber(self._rangeMin)
		local max = tonumber(self._rangeMax)
		if min ~= nil and max ~= nil and max > min then
			return min, max
		end
		local lowest, highest = math.huge, -math.huge
		for _, value in ipairs(self._displayed) do
			if value < lowest then
				lowest = value
			end
			if value > highest then
				highest = value
			end
		end
		if lowest == math.huge then
			return 0, 1
		end
		if highest - lowest < 0.0001 then
			return lowest - 1, highest + 1
		end
		local pad = (highest - lowest) * 0.08
		return lowest - pad, highest + pad
	end

	local function redraw()
		local size = plot.AbsoluteSize
		local width, plotHeight = size.X, size.Y
		if width <= 0 or plotHeight <= 0 then
			return
		end
		local applied = ThemeManager.GetCurrent()
		local color = lineColor(applied)
		local min, max = bounds()
		local span = max - min
		if span <= 0 then
			span = 1
		end
		local count = #self._displayed
		local margin = self._showPoints and (DOT_SIZE / 2 + 1) or 1
		local usableWidth = math.max(width - margin * 2, 1)
		local usableHeight = math.max(plotHeight - margin * 2, 1)

		local function pointAt(index)
			local value = self._displayed[index]
			local fraction = count <= 1 and 0.5 or (index - 1) / (count - 1)
			local x = margin + fraction * usableWidth
			local y = margin + (1 - math.clamp((value - min) / span, 0, 1)) * usableHeight
			return x, y
		end

		-- Segments.
		local segments = math.max(count - 1, 0)
		for index = 1, segments do
			local frame = self._frames[index]
			if not frame then
				frame = Instance.new("Frame")
				frame.Name = UUID.Generate("GraphSegment")
				frame.BorderSizePixel = 0
				frame.AnchorPoint = Vector2.new(0.5, 0.5)
				frame.ZIndex = 2
				frame.Parent = plot
				self._frames[index] = frame
			end
			local ax, ay = pointAt(index)
			local bx, by = pointAt(index + 1)
			local dx, dy = bx - ax, by - ay
			local length = math.sqrt(dx * dx + dy * dy)
			frame.BackgroundColor3 = color
			frame.Size = UDim2.fromOffset(math.max(length, 0.1), self._thickness)
			frame.Position = UDim2.fromOffset((ax + bx) / 2, (ay + by) / 2)
			frame.Rotation = math.deg(math.atan2(dy, dx))
			frame.Visible = true
		end
		for index = segments + 1, #self._frames do
			self._frames[index].Visible = false
		end

		-- Point dots.
		if self._showPoints then
			for index = 1, count do
				local dot = self._dots[index]
				if not dot then
					dot = Instance.new("Frame")
					dot.Name = UUID.Generate("GraphDot")
					dot.BorderSizePixel = 0
					dot.AnchorPoint = Vector2.new(0.5, 0.5)
					dot.Size = UDim2.fromOffset(DOT_SIZE, DOT_SIZE)
					dot.ZIndex = 3
					dot.Parent = plot
					local dotCorner = Instance.new("UICorner")
					dotCorner.CornerRadius = UDim.new(1, 0)
					dotCorner.Parent = dot
					self._dots[index] = dot
				end
				local x, y = pointAt(index)
				dot.BackgroundColor3 = color
				dot.Position = UDim2.fromOffset(x, y)
				dot.Visible = true
			end
			for index = count + 1, #self._dots do
				self._dots[index].Visible = false
			end
		else
			for _, dot in ipairs(self._dots) do
				dot.Visible = false
			end
		end

		if count > 0 then
			valueLabel.Text = resolveFormat(self._format, self._displayed[count])
		else
			valueLabel.Text = "—"
		end
	end

	self._redraw = redraw

	local function stopAnimation()
		if renderStepped then
			renderStepped:Disconnect()
			renderStepped = nil
		end
		animationStart = nil
	end

	local function tick()
		local now = os.clock()
		local progress = math.clamp((now - animationStart) / self._duration, 0, 1)
		local eased = 1 - (1 - progress) * (1 - progress)
		for index, target in ipairs(self._target) do
			local start = self._start[index]
			if start == nil then
				self._displayed[index] = target
			else
				self._displayed[index] = start + (target - start) * eased
			end
		end
		redraw()
		if progress >= 1 then
			self._displayed = copyPoints(self._target)
			redraw()
			stopAnimation()
		end
	end

	local function animateTo(points)
		self._target = copyPoints(points)
		if not self._animate or #self._displayed == 0 then
			self._displayed = copyPoints(self._target)
			stopAnimation()
			redraw()
			return
		end
		-- Drop any tail the new target no longer has, or redraw would keep
		-- painting stale points while the interpolation runs.
		for index = #self._target + 1, #self._displayed do
			self._displayed[index] = nil
		end
		local previous = self._displayed
		self._start = {}
		for index = 1, #self._target do
			-- A point appended by Push grows out of the previous last value.
			self._start[index] = previous[index] or previous[#previous] or self._target[index]
		end
		animationStart = os.clock()
		if not renderStepped then
			renderStepped = RunService.RenderStepped:Connect(tick)
		end
	end

	self._animateTo = animateTo

	plot:GetPropertyChangedSignal("AbsoluteSize"):Connect(redraw)
	plot:GetPropertyChangedSignal("Visible"):Connect(function()
		if plot.Visible then
			redraw()
		end
	end)

	ThemeManager.OnThemeApplied(function(applied)
		local color = lineColor(applied)
		for _, frame in ipairs(self._frames) do
			frame.BackgroundColor3 = color
		end
		for _, dot in ipairs(self._dots) do
			dot.BackgroundColor3 = color
		end
		if self._showGrid then
			for _, line in ipairs(gridLines) do
				line.BackgroundColor3 = applied.TertiaryColor or gridColor
			end
		end
		redraw()
	end, root)

	self.Frame = root
	self.Title = title
	self.ValueLabel = valueLabel
	self.Plot = plot
	self.Grid = grid

	local initial = copyPoints(Settings.Points or {})
	if #initial > maxPoints then
		local trimmed = {}
		for index = #initial - maxPoints + 1, #initial do
			trimmed[#trimmed + 1] = initial[index]
		end
		initial = trimmed
	end
	self._displayed = copyPoints(initial)
	self._target = copyPoints(initial)
	task.defer(redraw)

	ComponentAPI.Apply(self, {
		Root = function(me)
			return me.Frame
		end,
		Label = title,
		Name = name,
		Methods = {
			SetPoints = function(me, points)
				local nextPoints = copyPoints(points)
				if #nextPoints > me._maxPoints then
					-- Keep the newest values when a stream overflows.
					local trimmed = {}
					for index = #nextPoints - me._maxPoints + 1, #nextPoints do
						trimmed[#trimmed + 1] = nextPoints[index]
					end
					nextPoints = trimmed
				end
				me._animateTo(nextPoints)
				return me
			end,
			Push = function(me, value)
				local nextPoints = copyPoints(me._target or {})
				nextPoints[#nextPoints + 1] = tonumber(value) or 0
				while #nextPoints > me._maxPoints do
					table.remove(nextPoints, 1)
				end
				me._animateTo(nextPoints)
				return me
			end,
			SetValue = function(me, index, value)
				index = tonumber(index)
				if not index then
					return false
				end
				local nextPoints = copyPoints(me._target or {})
				if index < 1 or index > #nextPoints then
					return false
				end
				nextPoints[index] = tonumber(value) or 0
				me._animateTo(nextPoints)
				return true
			end,
			GetPoints = function(me)
				return copyPoints(me._target or {})
			end,
			SetRange = function(me, minValue, maxValue)
				me._rangeMin = tonumber(minValue)
				me._rangeMax = tonumber(maxValue)
				redraw()
				return me
			end,
			SetLineColor = function(me, color)
				me._lineColor = typeof(color) == "Color3" and color or nil
				redraw()
				return me
			end,
			SetAnimated = function(me, enabled)
				me._animate = enabled == true
				return me
			end,
			SetFormat = function(me, formatter)
				me._format = formatter
				redraw()
				return me
			end,
			SetGridVisible = function(me, visible)
				me._showGrid = visible == true
				grid.Visible = me._showGrid
				return me
			end,
			Clear = function(me)
				me._animateTo({})
				return me
			end,
			Destroy = function(me)
				stopAnimation()
				for _, descendant in ipairs(me.Frame:GetDescendants()) do
					ThemeManager.UnbindInstance(descendant)
				end
				ThemeManager.UnbindInstance(me.Frame)
				me.Frame:Destroy()
				me.Frame = nil
			end,
		},
	})

	return self
end

return Graph
