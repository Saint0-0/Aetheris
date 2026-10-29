--[[
	Aetheris/Utils/Aurora.luau

	Soft accent bloom behind the window. Prefers a single uploaded glow
	texture (Constants.AuroraGlow or Aurora.SetTexture), which makes every
	bloom one tinted ImageLabel; without a texture it falls back to layered
	circles that fake a radial falloff. Blooms drift on long TweenService
	loops and the static Wash variant is used inside notifications.
	Disabling the aurora tears its instances and tweens down completely;
	re-enabling rebuilds them.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Tween = require("./Tween")
local Constants = require("../Constants")
local ThemeManager = require("../Themes/ThemeManager")
local UUID = require("./UUID")

local Aurora = {}
Aurora.__index = Aurora

-- Procedural fallback: nested circles fake a radial falloff without a blur pass.
local LAYERS = {
	{ scale = 1.0, transparency = 0.988 },
	{ scale = 0.76, transparency = 0.978 },
	{ scale = 0.54, transparency = 0.966 },
	{ scale = 0.34, transparency = 0.95 },
}

-- Shared transparency for textured blooms; the baked falloff carries the depth.
local GLOW_TRANSPARENCY = 0.5

-- Runtime override via SetTexture; nil falls back to Constants.AuroraGlow.
Aurora.Texture = nil

-- Resolve to an rbxassetid:// string, or nil when nothing is configured.
function Aurora.GetTexture()
	local id = Aurora.Texture or Constants.AuroraGlow
	if type(id) == "number" then
		return id > 0 and string.format("rbxassetid://%d", id) or nil
	end
	if type(id) == "string" and id ~= "" then
		return id
	end
	return nil
end

-- Pass nil or "" to go back to the procedural fallback.
function Aurora.SetTexture(id)
	Aurora.Texture = id
end

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

-- One tinted image, optionally bound to a theme color.
local function makeGlow(parent, texture, color, x, y, width, height, transparency, colorKey)
	local glow = Instance.new("ImageLabel")
	glow.Name = UUID.Generate("AuroraGlow")
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(x, y)
	glow.Size = UDim2.fromScale(width, height)
	glow.BackgroundTransparency = 1
	glow.BorderSizePixel = 0
	glow.Image = texture
	glow.ImageColor3 = color
	glow.ImageTransparency = transparency
	glow.ScaleType = Enum.ScaleType.Stretch
	glow.ZIndex = 0
	glow.Parent = parent
	if colorKey then
		ThemeManager.BindColor(glow, "ImageColor3", colorKey)
	end
	return glow
end

-- One tinted image when a texture is set, layered circles otherwise; pieces
-- come back as { inst, prop } so callers can recolor without knowing the path.
local function makeBloom(parent, texture, color, x, y, width, height, intensity, colorKey, transparency)
	local t = transparency or GLOW_TRANSPARENCY
	if texture then
		local glow = makeGlow(parent, texture, color, x, y, width, height, t, colorKey)
		return { { inst = glow, prop = "ImageColor3", image = true } }
	end

	local scale = (1 - t) / math.max(1 - GLOW_TRANSPARENCY, 1e-3)
	local pieces = {}
	for _, layer in ipairs(LAYERS) do
		local weight = (1 - layer.transparency) * intensity
		local alpha = math.clamp(weight * scale, 0, 1)
		local circle = makeCircle(parent, color, x, y, width * layer.scale, height * layer.scale, 1 - alpha)
		if colorKey then
			ThemeManager.BindColor(circle, "BackgroundColor3", colorKey)
		end
		table.insert(pieces, { inst = circle, prop = "BackgroundColor3", weight = weight })
	end
	return pieces
end

function Aurora.Wash(parent, opts)
	opts = opts or {}
	local root = makeRoot(parent, opts)
	local texture = Aurora.GetTexture()
	local color = opts.Color or Color3.fromRGB(122, 156, 210)
	local intensity = opts.Intensity or 1
	-- When set, every bloom binds to this theme key so the wash repaints live.
	local colorKey = opts.ColorKey
	-- Blooms stay inside the parent's bottom edge; an overhang would stretch an AutomaticSize parent.
	local blobs = opts.Blobs
		or {
			{ x = 0.02, y = 0.18, size = 0.95, intensity = 1 },
			{ x = 1.0, y = 0.79, size = 0.4, intensity = 0.8 },
		}
	local pieces = {}
	for _, blob in ipairs(blobs) do
		local power = intensity * (blob.intensity or 1)
		for _, piece in ipairs(makeBloom(root, texture, color, blob.x, blob.y, blob.size, blob.size, power, colorKey)) do
			table.insert(pieces, piece)
		end
	end

	local wash = { Root = root, _pieces = pieces, _color = color }
	function wash:SetColor(newColor)
		self._color = newColor
		for _, piece in ipairs(self._pieces) do
			piece.inst[piece.prop] = newColor
		end
	end
	function wash:Destroy()
		if self.Root then
			self.Root:Destroy()
			self.Root = nil
			self._pieces = {}
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

local function makeBlob(root, theme, def, texture, transparency)
	local color = theme[def.colorKey] or theme.AccentColor or Color3.fromRGB(122, 156, 210)

	-- The holder carries the drift tweens; the bloom inside is image or circles.
	local holder = Instance.new("Frame")
	holder.Name = UUID.Generate("AuroraBlob")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(def.x, def.y)
	holder.Size = UDim2.fromScale(def.size, def.size)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ZIndex = 0
	holder.Parent = root

	return {
		holder = holder,
		pieces = makeBloom(holder, texture, color, 0.5, 0.5, 1, 1, def.intensity, def.colorKey, transparency),
		x = def.x,
		y = def.y,
		toX = def.toX,
		toY = def.toY,
		size = def.size,
		toSize = def.toSize,
		duration = def.duration,
		handle = nil,
	}
end

function Aurora.new(parent, opts)
	opts = opts or {}
	local self = setmetatable({}, Aurora)
	self._parent = parent
	self._opts = opts
	self._animated = opts.Animated ~= false
	self._theme = ThemeManager.GetTheme(opts.Theme)
	self._blobs = {}

	local transparency = tonumber(opts.Transparency)
	self._transparency = math.clamp(transparency or GLOW_TRANSPARENCY, 0, 1)

	self._enabled = false
	if opts.Enabled ~= false then
		self:SetEnabled(true)
	end
	return self
end

function Aurora:_build()
	self.Root = makeRoot(self._parent, self._opts)
	local texture = Aurora.GetTexture()
	self._blobs = {}
	for _, def in ipairs(BLOBS) do
		table.insert(self._blobs, makeBlob(self.Root, self._theme, def, texture, self._transparency))
	end

	self._unbind = ThemeManager.OnThemeApplied(function(theme)
		self._theme = theme
		if self._enabled and self._animated then
			self:_stop()
			self:_play()
		end
	end, self.Root)

	if self._animated then
		self:_play()
	end
end

-- Full teardown so an "off" aurora costs nothing at all.
function Aurora:_teardown()
	self:_stop()
	self._blobs = {}
	if self._unbind then
		self._unbind()
		self._unbind = nil
	end
	if self.Root then
		self.Root:Destroy()
		self.Root = nil
	end
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
		-- Target by distance from the current position, not a flip flag: a theme
		-- re-apply mid-drift could otherwise collapse the pendulum range to zero.
		local pos = blob.holder.Position
		local px, py = pos.X.Scale, pos.Y.Scale
		local dStart = (px - blob.x) ^ 2 + (py - blob.y) ^ 2
		local dEnd = (px - blob.toX) ^ 2 + (py - blob.toY) ^ 2
		local toEnd = dEnd >= dStart
		local targetX = toEnd and blob.toX or blob.x
		local targetY = toEnd and blob.toY or blob.y
		local targetSize = toEnd and blob.toSize or blob.size
		local info = TweenInfo.new(blob.duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		blob.handle = Tween.Play(blob.holder, info, {
			Position = UDim2.fromScale(targetX, targetY),
			Size = UDim2.fromScale(targetSize, targetSize),
		})
	end
end

function Aurora:SetEnabled(on)
	if self._destroyed then
		return
	end
	on = on ~= false
	if on == self._enabled then
		return
	end
	self._enabled = on
	if on then
		-- Refresh colors in case the theme switched while torn down.
		self._theme = ThemeManager.GetTheme(self._opts.Theme)
		self:_build()
	else
		self:_teardown()
	end
end

-- Live-update every bloom's transparency without rebuilding.
function Aurora:SetTransparency(value)
	local t = tonumber(value)
	if t == nil then
		return
	end
	self._transparency = math.clamp(t, 0, 1)
	local scale = (1 - self._transparency) / math.max(1 - GLOW_TRANSPARENCY, 1e-3)
	for _, blob in ipairs(self._blobs) do
		for _, piece in ipairs(blob.pieces) do
			if piece.image then
				piece.inst.ImageTransparency = self._transparency
			else
				piece.inst.BackgroundTransparency = 1 - math.clamp(piece.weight * scale, 0, 1)
			end
		end
	end
end

function Aurora:SetTheme(theme)
	self._theme = ThemeManager.GetTheme(theme)
end

function Aurora:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._enabled = false
	self:_teardown()
end

return Aurora
