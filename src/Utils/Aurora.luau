--[[
	Aurora  ·  Aetheris UI Library

	Soft, low-opacity accent bloom built from layered circles (no UIShadow, so
	it stays cheap). Animated blooms drift on long TweenService loops; the
	static Wash variant is used inside notifications.
]]

local Tween = require("./Tween")
local ThemeManager = require("../Themes/ThemeManager")
local UUID = require("./UUID")

local Aurora = {}
Aurora.__index = Aurora

-- Nested circles fake a radial falloff without a blur pass. Transparency is
-- scaled by each bloom's intensity so secondary blooms can sit further back.
local LAYERS = {
	{ scale = 1.0, transparency = 0.988 },
	{ scale = 0.76, transparency = 0.978 },
	{ scale = 0.54, transparency = 0.966 },
	{ scale = 0.34, transparency = 0.95 },
}

local function makeRoot(parent, opts)
	local root = Instance.new("Frame")
	root.Name = UUID.Static("Aurora")
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.Size = opts.Size or UDim2.fromScale(1, 1)
	root.Position = opts.Position or UDim2.fromScale(0, 0)
	root.AnchorPoint = opts.AnchorPoint or Vector2.new(0, 0)
	root.ZIndex = opts.ZIndex or 0
	root.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = opts.CornerRadius or UDim.new(0, 6)
	corner.Parent = root
	return root
end

local function makeCircle(parent, color, x, y, width, height, transparency)
	local circle = Instance.new("Frame")
	circle.Name = UUID.Generate("AuroraLayer")
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.fromScale(x, y)
	circle.Size = UDim2.fromScale(width, height)
	circle.BackgroundColor3 = color
	circle.BackgroundTransparency = transparency
	circle.BorderSizePixel = 0
	circle.ZIndex = 0
	circle.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = circle
	return circle
end

-- Build a static bloom. Caller can recolor it when the theme changes.
function Aurora.Wash(parent, opts)
	opts = opts or {}
	local root = makeRoot(parent, opts)
	local color = opts.Color or Color3.fromRGB(122, 156, 210)
	local intensity = opts.Intensity or 1
	local blobs = opts.Blobs
		or {
			{ x = 0.02, y = 0.18, size = 0.95, intensity = 1 },
			{ x = 1.0, y = 0.94, size = 0.8, intensity = 0.8 },
		}
	local frames = {}
	for _, blob in ipairs(blobs) do
		local power = intensity * (blob.intensity or 1)
		for _, layer in ipairs(LAYERS) do
			local transparency = 1 - (1 - layer.transparency) * power
			local size = blob.size * layer.scale
			table.insert(frames, makeCircle(root, color, blob.x, blob.y, size, size, transparency))
		end
	end

	local wash = { Root = root, _frames = frames, _color = color }
	function wash:SetColor(newColor)
		self._color = newColor
		for _, frame in ipairs(self._frames) do
			frame.BackgroundColor3 = newColor
		end
	end
	function wash:Destroy()
		if self.Root then
			self.Root:Destroy()
			self.Root = nil
			self._frames = {}
		end
	end
	return wash
end

local BLOBS = {
	{
		colorKey = "AccentColor",
		x = 0.03,
		y = 0.92,
		toX = 0.18,
		toY = 0.76,
		size = 0.95,
		toSize = 1.02,
		duration = 28,
		intensity = 1,
	},
	{
		colorKey = "PrimaryColor",
		x = 0.97,
		y = 0.04,
		toX = 0.8,
		toY = 0.2,
		size = 0.78,
		toSize = 0.84,
		duration = 33,
		intensity = 0.72,
	},
	{
		colorKey = "AccentColor",
		x = 1.02,
		y = 0.94,
		toX = 0.82,
		toY = 0.74,
		size = 0.6,
		toSize = 0.66,
		duration = 24,
		intensity = 0.62,
	},
}

local function makeBlob(root, theme, def)
	local color = theme[def.colorKey] or theme.AccentColor or Color3.fromRGB(122, 156, 210)

	local holder = Instance.new("Frame")
	holder.Name = UUID.Generate("AuroraBlob")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(def.x, def.y)
	holder.Size = UDim2.fromScale(def.size, def.size)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ZIndex = 0
	holder.Parent = root

	for _, layer in ipairs(LAYERS) do
		local transparency = 1 - (1 - layer.transparency) * def.intensity
		local circle = makeCircle(holder, color, 0.5, 0.5, layer.scale, layer.scale, transparency)
		ThemeManager.BindColor(circle, "BackgroundColor3", def.colorKey)
	end

	return {
		holder = holder,
		x = def.x,
		y = def.y,
		toX = def.toX,
		toY = def.toY,
		size = def.size,
		toSize = def.toSize,
		duration = def.duration,
		handle = nil,
		flip = false,
	}
end

function Aurora.new(parent, opts)
	opts = opts or {}
	local self = setmetatable({}, Aurora)
	self._enabled = opts.Enabled ~= false
	self._animated = opts.Animated ~= false
	self._theme = ThemeManager.GetTheme(opts.Theme)

	self.Root = makeRoot(parent, opts)
	self._blobs = {}
	for _, def in ipairs(BLOBS) do
		table.insert(self._blobs, makeBlob(self.Root, self._theme, def))
	end

	self._unbind = ThemeManager.OnThemeApplied(function(theme)
		self._theme = theme
		if self._enabled and self._animated then
			self:_stop()
			self:_play()
		end
	end, self.Root)

	self.Root.Visible = self._enabled
	if self._enabled and self._animated then
		self:_play()
	end
	return self
end

function Aurora:_stop()
	for _, blob in ipairs(self._blobs) do
		if blob.handle then
			Tween.Cancel(blob.handle)
			blob.handle = nil
		end
	end
end

function Aurora:_play()
	for _, blob in ipairs(self._blobs) do
		local targetX = blob.flip and blob.x or blob.toX
		local targetY = blob.flip and blob.y or blob.toY
		local targetSize = blob.flip and blob.size or blob.toSize
		blob.flip = not blob.flip
		local info = TweenInfo.new(blob.duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		blob.handle = Tween.Play(blob.holder, info, {
			Position = UDim2.fromScale(targetX, targetY),
			Size = UDim2.fromScale(targetSize, targetSize),
		})
	end
end

function Aurora:SetEnabled(on)
	self._enabled = on ~= false
	self.Root.Visible = self._enabled
	if self._enabled and self._animated then
		self:_play()
	else
		self:_stop()
	end
end

function Aurora:SetTheme(theme)
	self._theme = ThemeManager.GetTheme(theme)
end

function Aurora:Destroy()
	self:_stop()
	if self._unbind then
		self._unbind()
		self._unbind = nil
	end
	if self.Root then
		self.Root:Destroy()
		self.Root = nil
	end
end

return Aurora
