--[[
	Aetheris/Core/SearchFilter.luau

	Filters the sections of a page by a text query and highlights the matched
	substring inside each component's ElementName label with the theme accent
	color. Used by the sidebar search box (per active page); sections and labels
	are indexed once per page and cached (weak-keyed, invalidated on tree change)
	so a keystroke never walks the whole page.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local UUID = require("../Utils/UUID")

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

-- Public so the dropdown popup reuses the exact same highlight logic.
function SearchFilter.Highlight(base, query, color)
	if not base or base == "" then
		return nil
	end
	local lq = string.lower(query or "")
	if lq == "" then
		return nil
	end
	local lower = string.lower(base)
	if not string.find(lower, lq, 1, true) then
		return nil
	end
	local hex = colorToHex(color or Color3.fromRGB(96, 165, 250))
	return buildHighlight(base, lower, lq, hex)
end

-- Weak keys so a destroyed page's index + dirty flag are collected.
local indexByPage = setmetatable({}, { __mode = "k" })
local dirtyByPage = setmetatable({}, { __mode = "k" })
local connectedByPage = setmetatable({}, { __mode = "k" })

local function buildIndex(page)
	local sections = {}
	local entries = {}
	for _, d in ipairs(page:GetDescendants()) do
		if d:GetAttribute(UUID.Static("IsSection")) then
			sections[d] = false
		elseif d:IsA("TextLabel") and d.Name == UUID.Static("ElementName") then
			-- Resolve the owning section once at index time instead of walking
			-- parents on every keystroke.
			local sec = nil
			local p = d.Parent
			while p do
				if p:GetAttribute(UUID.Static("IsSection")) then
					sec = p
					break
				end
				p = p.Parent
			end
			table.insert(entries, { label = d, section = sec })
		end
	end
	return { sections = sections, entries = entries }
end

local function getIndex(page)
	local idx = indexByPage[page]
	if idx and not dirtyByPage[page] then
		return idx
	end
	idx = buildIndex(page)
	indexByPage[page] = idx
	dirtyByPage[page] = nil
	if not connectedByPage[page] then
		connectedByPage[page] = true
		-- Connections hang off the page's own signals, so they die with the
		-- page; the weak key only stops us re-connecting.
		page.DescendantAdded:Connect(function()
			dirtyByPage[page] = true
		end)
		page.DescendantRemoving:Connect(function()
			dirtyByPage[page] = true
		end)
	end
	return idx
end

function SearchFilter.Apply(page, query, theme)
	if not page then
		return
	end
	query = string.lower(query or "")
	if query == "" then
		SearchFilter.Clear(page)
		return
	end
	local accent = (theme and theme.AccentColor) or Color3.fromRGB(96, 165, 250)
	local hex = colorToHex(accent)

	local idx = getIndex(page)
	local sections = idx.sections
	local entries = idx.entries

	-- Reset matched flags; the index is reused across applies.
	for sec in pairs(sections) do
		sections[sec] = false
	end

	for _, entry in ipairs(entries) do
		local d = entry.label
		local base = d:GetAttribute(UUID.Static("SearchBaseText"))
		if base == nil then
			base = d.Text
			d:SetAttribute(UUID.Static("SearchBaseText"), base)
			d:SetAttribute(UUID.Static("SearchBaseRich"), d.RichText)
		end
		local lower = string.lower(base)
		if string.find(lower, query, 1, true) then
			local sec = entry.section
			if sec and sections[sec] ~= nil then
				sections[sec] = true
			end
			d.RichText = true
			d.Text = buildHighlight(base, lower, query, hex)
		else
			d.Text = base
			local br = d:GetAttribute(UUID.Static("SearchBaseRich"))
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
	if not page then
		return
	end
	local idx = getIndex(page)
	for sec in pairs(idx.sections) do
		sec.Visible = true
	end
	for _, entry in ipairs(idx.entries) do
		local d = entry.label
		local base = d:GetAttribute(UUID.Static("SearchBaseText"))
		if base ~= nil then
			d.Text = base
			local br = d:GetAttribute(UUID.Static("SearchBaseRich"))
			if br ~= nil then
				d.RichText = br
			end
			d:SetAttribute(UUID.Static("SearchBaseText"), nil)
			d:SetAttribute(UUID.Static("SearchBaseRich"), nil)
		end
	end
end

return SearchFilter
