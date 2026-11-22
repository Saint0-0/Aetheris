--[[
	Aetheris/Utils/Hyperlinks.luau

	Inline link syntax for text components:
	  {label:page}       navigates to a settings page or sidebar tab
	  {label:copy}       copies the label
	  {label:copy:value} copies an explicit value

	Rendering is word based: each line is measured with TextMetrics and laid out
	with plain TextLabels plus TextButtons for links, so links can sit inside a
	wrapped paragraph and remain individually clickable.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Tween = require("./Tween")
local Locale = require("./Locale")
local TextMetrics = require("./TextMetrics")
local ThemeManager = require("../Themes/ThemeManager")
local Constants = require("../Constants")
local UUID = require("./UUID")

local Hyperlinks = {}

-- Live renderers follow a font swap without waiting for a resize.
local liveRenderers = setmetatable({}, { __mode = "k" })

local LINK_PATTERN = "{([^:{}]+):([^{}]+)}"
local HOVER = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Split the raw string into plain and link segments.
function Hyperlinks.parse(text)
	local segments = {}
	if type(text) ~= "string" or text == "" then
		return segments
	end
	local pos = 1
	while true do
		local s, e, label, target = string.find(text, LINK_PATTERN, pos)
		if not s then
			if pos <= #text then
				segments[#segments + 1] = { text = string.sub(text, pos) }
			end
			break
		end
		if s > pos then
			segments[#segments + 1] = { text = string.sub(text, pos, s - 1) }
		end
		-- Only copy is a keyword; everything else is a page name, spaces included.
		local action, value
		local lower = string.lower(target)
		if lower == "copy" then
			action = "copy"
		elseif string.sub(lower, 1, 5) == "copy:" then
			action, value = "copy", string.sub(target, 6)
		elseif string.sub(lower, 1, 5) == "page:" then
			action, value = "page", string.sub(target, 6)
		else
			action, value = "page", target
		end
		segments[#segments + 1] = {
			text = label,
			action = action,
			target = (value ~= nil and value ~= "") and value or nil,
		}
		pos = e + 1
	end
	return segments
end

-- The same string with every link replaced by its label.
function Hyperlinks.plain(text)
	local segments = Hyperlinks.parse(text)
	local out = {}
	for _, segment in ipairs(segments) do
		out[#out + 1] = segment.text
	end
	return table.concat(out)
end

function Hyperlinks.hasLinks(text)
	for _, segment in ipairs(Hyperlinks.parse(text)) do
		if segment.action then
			return true
		end
	end
	return false
end

-- GetTextBoundsAsync takes a Font object, so the shared custom family measures
-- correctly. TextMetrics caches widths; a font that is still loading is retried
-- on the next build instead of freezing a fallback width.
local function measure(text, size, font)
	if text == "" then
		return 0
	end
	return TextMetrics.textWidth(font, size, text)
end

local function lineHeightFor(size, font)
	local height = TextMetrics.textHeight(font, size, "Ag", math.huge)
	if height <= 0 then
		height = math.ceil(size * 1.25)
	end
	return height + 2
end

-- Words plus explicit breaks; spaces stay implicit so wrapping can drop them.
local function tokenize(segments)
	local tokens = {}
	for _, segment in ipairs(segments) do
		local text = segment.text
		local i = 1
		while i <= #text do
			local ch = string.sub(text, i, i)
			if ch == "\n" then
				tokens[#tokens + 1] = { newline = true }
				i += 1
			elseif ch == " " then
				while i <= #text and string.sub(text, i, i) == " " do
					i += 1
				end
				tokens[#tokens + 1] = { space = true }
			else
				local j = i
				while j <= #text do
					local c = string.sub(text, j, j)
					if c == " " or c == "\n" then
						break
					end
					j += 1
				end
				tokens[#tokens + 1] = {
					text = string.sub(text, i, j - 1),
					action = segment.action,
					target = segment.target,
					label = segment.text,
				}
				i = j
			end
		end
	end
	return tokens
end

local function layout(tokens, maxWidth, textSize, font)
	-- A lone space trims to zero width, so derive it from a two-word sample.
	local spaceWidth = measure("a a", textSize, font) - 2 * measure("a", textSize, font)
	if spaceWidth <= 0 then
		spaceWidth = textSize * 0.28
	end
	local lines = { {} }
	local line = lines[1]
	local x = 0
	for _, token in ipairs(tokens) do
		if token.newline then
			line = {}
			lines[#lines + 1] = line
			x = 0
		elseif token.space then
			if x > 0 then
				x += spaceWidth
			end
		else
			local width = measure(token.text, textSize, font)
			if x > 0 and x + width > maxWidth then
				line = {}
				lines[#lines + 1] = line
				x = 0
			end
			line[#line + 1] = { token = token, x = x, width = width }
			x += width
		end
	end
	return lines, spaceWidth
end

-- Merge neighbouring words that share an action into one instance.
local function groupLine(line)
	local groups = {}
	for _, entry in ipairs(line) do
		local token = entry.token
		local last = groups[#groups]
		if
			last
			and last.action == token.action
			and last.target == token.target
			and (last.target ~= nil or last.label == token.label)
		then
			last.text = last.text .. " " .. token.text
			last.width = (entry.x + entry.width) - last.x
		else
			local spaceBefore = false
			if last then
				spaceBefore = entry.x > (last.x + last.width + 0.5)
			end
			groups[#groups + 1] = {
				text = token.text,
				action = token.action,
				target = token.target,
				label = token.label,
				x = entry.x,
				width = entry.width,
				spaceBefore = spaceBefore,
			}
		end
	end
	return groups
end

local function applyColors(renderer, theme)
	local plain = (renderer._textThemeKey and theme[renderer._textThemeKey]) or renderer._textColor
	local link = (renderer._linkThemeKey and theme[renderer._linkThemeKey]) or renderer._linkColor
	local transparency = (renderer._transparencyThemeKey and theme[renderer._transparencyThemeKey])
		or renderer._textTransparency
		or 0
	for _, record in ipairs(renderer._labels) do
		local color = record.link and link or plain
		record.baseColor = color
		record.instance.TextColor3 = color
		record.instance.TextTransparency = transparency
		if record.underline then
			record.underline.BackgroundColor3 = link
			record.underline.BackgroundTransparency = math.min(transparency + 0.35, 1)
		end
	end
end

function Hyperlinks.render(parent, opts)
	opts = opts or {}
	local renderer = {
		_source = opts.Text or "",
		_textSize = opts.TextSize or 14,
		_font = opts.FontFace or Constants.Font(Enum.FontWeight.Medium),
		_textColor = opts.TextColor3 or Color3.fromRGB(255, 255, 255),
		_linkColor = opts.LinkColor3 or Color3.fromRGB(96, 165, 250),
		_textTransparency = opts.TextTransparency or 0,
		_textThemeKey = opts.TextThemeKey,
		_linkThemeKey = opts.LinkThemeKey,
		_transparencyThemeKey = opts.TransparencyThemeKey,
		_defaultTransparencyThemeKey = opts.TransparencyThemeKey,
		_onAction = opts.OnAction,
		_labels = {},
		_lastWidth = -1,
	}

	local root = Instance.new("Frame")
	root.Name = opts.Name or UUID.Generate("Hyperlinks")
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.AnchorPoint = opts.AnchorPoint or Vector2.new(0, 0)
	root.Position = opts.Position or UDim2.fromOffset(0, 0)
	local width = opts.Width or UDim2.fromScale(1, 0)
	root.Size = UDim2.new(width.X.Scale, width.X.Offset, 0, opts.TextSize or 14)
	root.Parent = parent
	renderer.Root = root

	local lineHeight = lineHeightFor(renderer._textSize, renderer._font)
	local bottomPadding = opts.BottomPadding or 0
	local buildToken = 0

	local function clear()
		renderer._labels = {}
		for _, child in ipairs(root:GetChildren()) do
			child:Destroy()
		end
	end

	local function fire(action, target, label)
		if type(renderer._onAction) == "function" then
			renderer._onAction(action, target, label)
		end
	end

	local function buildLine(line, lineIndex, spaceWidth)
		local y = (lineIndex - 1) * lineHeight
		local groups = groupLine(line)
		-- Measure each merged run as a whole and keep runs from overlapping the
		-- next one, even if kerning makes a run a pixel wider than its words.
		local cursor = 0
		for index, group in ipairs(groups) do
			local groupWidth = measure(group.text, renderer._textSize, renderer._font)
			if index > 1 then
				local minimum = cursor + (group.spaceBefore and spaceWidth or 0)
				if group.x < minimum then
					group.x = minimum
				end
			end
			group.width = groupWidth
			cursor = group.x + groupWidth
		end
		for _, group in ipairs(groups) do
			local isLink = group.action ~= nil
			local instance
			if isLink then
				instance = Instance.new("TextButton")
				instance.AutoButtonColor = false
			else
				instance = Instance.new("TextLabel")
			end
			instance.Name = UUID.Generate(isLink and "Hyperlink" or "HyperlinkText")
			instance.BackgroundTransparency = 1
			instance.BorderSizePixel = 0
			instance.Text = group.text
			instance.TextSize = renderer._textSize
			instance.FontFace = renderer._font
			instance.TextXAlignment = Enum.TextXAlignment.Left
			instance.TextYAlignment = Enum.TextYAlignment.Top
			instance.TextTruncate = Enum.TextTruncate.None
			instance.ClipsDescendants = false
			-- One extra pixel keeps the final glyph from clipping.
			instance.Size = UDim2.fromOffset(math.ceil(group.width) + 1, lineHeight)
			instance.Position = UDim2.fromOffset(group.x, y)
			instance.Parent = root

			local record = { instance = instance, link = isLink }
			if isLink then
				instance.TextColor3 = renderer._linkColor
				local underline = Instance.new("Frame")
				underline.Name = UUID.Static("HyperlinkUnderline")
				underline.BorderSizePixel = 0
				underline.BackgroundColor3 = renderer._linkColor
				underline.BackgroundTransparency = 0.55
				underline.AnchorPoint = Vector2.new(0, 1)
				underline.Position = UDim2.fromScale(0, 1)
				underline.Size = UDim2.new(1, 0, 0, 1)
				underline.Parent = instance
				record.underline = underline

				local baseColor = renderer._linkColor
				instance.MouseEnter:Connect(function()
					local bright = (record.baseColor or baseColor):Lerp(Color3.new(1, 1, 1), 0.35)
					Tween.Play(instance, HOVER, { TextColor3 = bright })
					Tween.Play(underline, HOVER, { BackgroundTransparency = 0.2 })
				end)
				instance.MouseLeave:Connect(function()
					Tween.Play(instance, HOVER, { TextColor3 = record.baseColor or baseColor })
					Tween.Play(underline, HOVER, { BackgroundTransparency = 0.55 })
				end)
				instance.MouseButton1Click:Connect(function()
					fire(group.action, group.target, group.label)
				end)
			else
				instance.TextColor3 = renderer._textColor
			end
			instance.TextTransparency = renderer._textTransparency or 0
			renderer._labels[#renderer._labels + 1] = record
		end
	end

	local function rebuild()
		if not root or not root.Parent then
			return
		end
		local available = root.AbsoluteSize.X
		if available <= 0 then
			available = 300
		end
		if math.abs(available - renderer._lastWidth) < 0.5 then
			return
		end
		renderer._lastWidth = available
		buildToken += 1
		local token = buildToken
		-- GetTextBoundsAsync yields, so measure off the caller's thread and drop
		-- this build if a newer one started while it was measuring.
		task.spawn(function()
			local text = Locale.resolve(renderer._source)
			local lines, spaceWidth =
				layout(tokenize(Hyperlinks.parse(text)), available, renderer._textSize, renderer._font)
			if token ~= buildToken or not root or not root.Parent then
				return
			end
			lineHeight = lineHeightFor(renderer._textSize, renderer._font)
			clear()
			for index, line in ipairs(lines) do
				buildLine(line, index, spaceWidth)
			end
			root.Size = UDim2.new(width.X.Scale, width.X.Offset, 0, #lines * lineHeight + bottomPadding)
			applyColors(renderer, ThemeManager.GetTheme(nil))
		end)
	end

	function renderer:SetText(text)
		renderer._source = text or ""
		renderer._lastWidth = -1
		rebuild()
	end

	function renderer:SetTransparency(transparency)
		renderer._textTransparency = transparency
		renderer._transparencyThemeKey = transparency == nil and renderer._defaultTransparencyThemeKey or nil
		applyColors(renderer, ThemeManager.GetTheme(nil))
	end

	function renderer:SetFont(font)
		if font then
			renderer._font = font
			renderer._lastWidth = -1
			rebuild()
		end
	end

	function renderer:Destroy()
		if root then
			root:Destroy()
			root = nil
		end
	end

	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if math.abs(root.AbsoluteSize.X - renderer._lastWidth) >= 0.5 then
			rebuild()
		end
	end)
	task.defer(rebuild)

	local unsubscribe = ThemeManager.OnThemeApplied(function(applied)
		applyColors(renderer, applied)
	end, root)
	root.Destroying:Connect(unsubscribe)

	local localeListener = function()
		renderer._lastWidth = -1
		if root and root.Parent then
			rebuild()
		end
	end
	Locale.onChanged(localeListener)
	root.Destroying:Connect(function()
		Locale.offChanged(localeListener)
	end)
	liveRenderers[root] = renderer
	root.Destroying:Connect(function()
		liveRenderers[root] = nil
	end)

	return renderer
end

-- Called after a live font swap so every link line re-measures.
function Hyperlinks.RefreshFonts()
	for root, renderer in pairs(liveRenderers) do
		if root.Parent and renderer._font then
			renderer:SetFont(Constants.Font(renderer._font.Weight, renderer._font.Style))
		end
	end
end

return Hyperlinks
