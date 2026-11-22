--[[
	Aetheris/Utils/TextMetrics.luau

	Font-aware text measurement, modelled on Rayfield Gen 2's textMetrics
	utility (MPL-2.0). TextService:GetTextBoundsAsync accepts a Font object, so
	custom families measure correctly instead of falling back to SourceSans.

	Widths are cached because GetTextBoundsAsync yields; a transient failure is
	never cached, so a slow font load cannot lock in a wrong width.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local TextService = game:GetService("TextService")

local TextMetrics = {}

local WIDTH_CACHE_CAP = 2048
local widthCache = {}
local widthCacheCount = 0

local function measure(params)
	local ok, bounds = pcall(function()
		return TextService:GetTextBoundsAsync(params)
	end)
	return ok and bounds or nil
end

local function axis(bounds, name)
	if typeof(bounds) == "Vector2" then
		return bounds[name]
	end
	if type(bounds) == "table" and type(bounds[name]) == "number" then
		return bounds[name]
	end
	return nil
end

local function cacheKey(font, size, text)
	return tostring(font.Family)
		.. "|"
		.. tostring(font.Weight)
		.. "|"
		.. tostring(font.Style)
		.. "|"
		.. tostring(size)
		.. "|"
		.. text
end

-- Width in pixels for one unwrapped string.
function TextMetrics.textWidth(font, size, text)
	text = tostring(text or "")
	if text == "" then
		return 0
	end
	local key = cacheKey(font, size, text)
	local cached = widthCache[key]
	if cached then
		return cached
	end

	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = font
	params.Size = size
	params.Width = math.huge

	local width = axis(measure(params), "X")
	if not width then
		-- Rough fallback for this call only; character count keeps non-ASCII sane.
		local length = utf8.len(text) or #text
		return math.ceil(size * 0.55 * length)
	end

	width = math.ceil(width)
	if widthCacheCount >= WIDTH_CACHE_CAP then
		widthCache = {}
		widthCacheCount = 0
	end
	widthCache[key] = width
	widthCacheCount += 1
	return width
end

-- Height in pixels for wrapped text at a fixed width.
function TextMetrics.textHeight(font, size, text, width)
	text = tostring(text or "")
	if text == "" then
		return 0
	end

	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = font
	params.Size = size
	params.Width = width

	local height = axis(measure(params), "Y")
	if not height then
		return size
	end
	return math.ceil(height)
end

return TextMetrics
