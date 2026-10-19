--[[
	Aurora  ·  Aetheris UI Library

	Soft accent-colored bloom that sits behind the window content. A couple of
	blurred circles drift slowly and recolor themselves from the active theme.

		local aurora = Aurora.new(parent, { Theme = theme, Enabled = true })
		aurora:SetEnabled(false)
		aurora:Destroy()
]]

local Tween = require("./Tween")
local ThemeManager = require("../Themes/ThemeManager")

local Aurora = {}
Aurora.__index = Aurora

local function makeBlob(parent, theme, opts)
	local color = theme[opts.colorKey] or theme.AccentColor or Color3.fromRGB(122, 156, 210)

	local blob = Instance.new("Frame")
	blob.Name = "AuroraBlob"
	blob.AnchorPoint = Vector2.new(0.5, 0.5)
	blob.Size = UDim2.fromScale(opts.width, opts.height)
	blob.Position = UDim2.fromScale(opts.from[1], opts.from[2])
	blob.BackgroundColor3 = color
	blob.BackgroundTransparency = opts.transparency or 0.86
	blob.BorderSizePixel = 0
	blob.ZIndex = 0
	blob.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = blob

	-- UIShadow supplies the soft edge; the circle itself is mostly transparent.
	local shadow = Instance.new("UIShadow")
	shadow.Color = color
	shadow.BlurRadius = UDim.new(0, opts.blur or 100)
	shadow.Transparency = opts.shadowTransparency or 0.45
	shadow.Parent = blob

	ThemeManager.BindColor(blob, "BackgroundColor3", opts.colorKey)
	ThemeManager.BindColor(shadow, "Color", opts.colorKey)

	return {
		frame = blob,
		from = opts.from,
		to = opts.to,
		duration = opts.duration or 18,
		handle = nil,
		flip = false,
	}
end

function Aurora.new(parent, opts)
	opts = opts or {}
	local self = setmetatable({}, Aurora)
	self._enabled = opts.Enabled ~= false
	self._theme = ThemeManager.GetTheme(opts.Theme)

	self.Root = Instance.new("CanvasGroup")
	self.Root.Name = "Aurora"
	self.Root.BackgroundTransparency = 1
	self.Root.BorderSizePixel = 0
	self.Root.ClipsDescendants = true
	self.Root.Size = UDim2.fromScale(1, 1)
	self.Root.Position = UDim2.fromScale(0, 0)
	self.Root.ZIndex = 0
	self.Root.Parent = parent

	self._blobs = {
		makeBlob(self.Root, self._theme, {
			colorKey = "AccentColor",
			width = 0.9,
			height = 0.9,
			from = { 0.08, 0.92 },
			to = { 0.26, 0.72 },
			duration = 19,
			transparency = 0.86,
			shadowTransparency = 0.42,
			blur = 110,
		}),
		makeBlob(self.Root, self._theme, {
			colorKey = "SecondaryColor",
			width = 0.72,
			height = 0.72,
			from = { 0.92, 0.06 },
			to = { 0.74, 0.22 },
			duration = 23,
			transparency = 0.9,
			shadowTransparency = 0.52,
			blur = 90,
		}),
	}

	-- ApplyTheme cancels every tween, so restart the drift once the new theme
	-- colors have been published.
	self._unbind = ThemeManager.OnThemeApplied(function(theme)
		self._theme = theme
		if self._enabled then
			self:_play()
		end
	end, self.Root)

	self.Root.Visible = self._enabled
	if self._enabled then
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
		Tween.CancelProperty(blob.frame, "Position")
	end
end

function Aurora:_play()
	for _, blob in ipairs(self._blobs) do
		local target = blob.flip and blob.from or blob.to
		blob.flip = not blob.flip
		local info = TweenInfo.new(blob.duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		blob.handle = Tween.Play(blob.frame, info, {
			Position = UDim2.fromScale(target[1], target[2]),
		})
	end
end

function Aurora:SetEnabled(on)
	self._enabled = on ~= false
	self.Root.Visible = self._enabled
	if self._enabled then
		self:_play()
	else
		self:_stop()
	end
end

function Aurora:SetTheme(theme)
	self._theme = ThemeManager.GetTheme(theme)
	if self._enabled then
		self:_play()
	end
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
