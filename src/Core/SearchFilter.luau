--[[
	SearchFilter  ·  Aetheris UI Library

	Filters the sections of a page by a text query and highlights the matched
	substring inside each component's ElementName label with the theme accent
	color. Used by the sidebar search box (per active page).

	One GetDescendants pass collects the sections + their ElementName labels,
	marks which sections contain a match, toggles section visibility, and
	rewrites matching labels as RichText spans. The original text and RichText
	flag are stashed in attributes so they restore exactly on clear.
]]

local SearchFilter = {}

local function colorToHex(c)
	local r = math.floor(c.R * 255 + 0.5)
	local g = math.floor(c.G * 255 + 0.5)
	local b = math.floor(c.B * 255 + 0.5)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function escapeRich(s)
	s = string.gsub(s, "&", "&amp;")
	s = string.gsub(s, "<", "&lt;")
	s = string.gsub(s, ">", "&gt;")
	return s
end

local function buildHighlight(base, lower, lq, hex)
	local out = {}
	local pos = 1
	while true do
		local s, e = string.find(lower, lq, pos, true)
		if not s then
			table.insert(out, escapeRich(string.sub(base, pos)))
			break
		end
		table.insert(out, escapeRich(string.sub(base, pos, s - 1)))
		table.insert(out, '<font color="' .. hex .. '">' .. escapeRich(string.sub(base, s, e)) .. "</font>")
		pos = e + 1
	end
	return table.concat(out)
end

-- Public: build a RichText string with every occurrence of `query` wrapped
-- in an accent-colored <font> span. Exposed so the dropdown popup reuses the
-- exact same highlight logic. Returns nil when there is no match.
function SearchFilter.Highlight(base, query, color)
	if not base or base == "" then return nil end
	local lq = string.lower(query or "")
	if lq == "" then return nil end
	local lower = string.lower(base)
	if not string.find(lower, lq, 1, true) then return nil end
	local hex = colorToHex(color or Color3.fromRGB(96, 165, 250))
	return buildHighlight(base, lower, lq, hex)
end

local function nearestSection(inst)
	local p = inst.Parent
	while p do
		if p:GetAttribute("IsSection") then
			return p
		end
		p = p.Parent
	end
	return nil
end

function SearchFilter.Apply(page, query, theme)
	if not page then return end
	query = string.lower(query or "")
	if query == "" then
		SearchFilter.Clear(page)
		return
	end
	local accent = (theme and theme.AccentColor) or Color3.fromRGB(96, 165, 250)
	local hex = colorToHex(accent)

	local sections = {}
	local labels = {}
	for _, d in ipairs(page:GetDescendants()) do
		if d:GetAttribute("IsSection") then
			sections[d] = false
		elseif d:IsA("TextLabel") and d.Name == "ElementName" then
			table.insert(labels, d)
		end
	end

	for _, d in ipairs(labels) do
		local base = d:GetAttribute("SearchBaseText")
		if base == nil then
			base = d.Text
			d:SetAttribute("SearchBaseText", base)
			d:SetAttribute("SearchBaseRich", d.RichText)
		end
		local lower = string.lower(base)
		if string.find(lower, query, 1, true) then
			local sec = nearestSection(d)
			if sec and sections[sec] ~= nil then
				sections[sec] = true
			end
			d.RichText = true
			d.Text = buildHighlight(base, lower, query, hex)
		else
			d.Text = base
			local br = d:GetAttribute("SearchBaseRich")
			if br ~= nil then
				d.RichText = br
			end
		end
	end

	for sec, matched in pairs(sections) do
		sec.Visible = matched
	end
end

function SearchFilter.Clear(page)
	if not page then return end
	for _, d in ipairs(page:GetDescendants()) do
		if d:GetAttribute("IsSection") then
			d.Visible = true
		elseif d:IsA("TextLabel") and d.Name == "ElementName" then
			local base = d:GetAttribute("SearchBaseText")
			if base ~= nil then
				d.Text = base
				local br = d:GetAttribute("SearchBaseRich")
				if br ~= nil then d.RichText = br end
				d:SetAttribute("SearchBaseText", nil)
				d:SetAttribute("SearchBaseRich", nil)
			end
		end
	end
end

return SearchFilter