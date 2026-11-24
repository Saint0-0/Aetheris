--[[
	Aetheris/Core/SearchFilter.luau

	Filters a page by text. Sections use TreeFade and individual components drop
	out of their section, so a query narrows the results inside each section
	rather than only hiding whole sections. Labels are indexed once per page and
	cached until the tree changes.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local PageFade = require("../Utils/PageFade")
local UUID = require("../Utils/UUID")

local SearchFilter = {}

local HIDE_DELAY = 0.12
local SECTION_DELAY = 0.2

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

-- Public; the dropdown popup reuses the same highlight logic.
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

-- Weak keys let a destroyed page's index and tokens be collected.
local indexByPage = setmetatable({}, { __mode = "k" })
local dirtyByPage = setmetatable({}, { __mode = "k" })
local connectedByPage = setmetatable({}, { __mode = "k" })
local tokenByPage = setmetatable({}, { __mode = "k" })

local function nearestAncestor(instance, attribute)
	local parent = instance.Parent
	while parent do
		if parent:GetAttribute(attribute) then
			return parent
		end
		parent = parent.Parent
	end
	return nil
end

local function buildIndex(page, previous)
	local sections = {}
	local components = {}
	local componentByRoot = {}
	local sectionByInstance = {}

	local function ensureSection(section)
		local record = sectionByInstance[section]
		if not record then
			record = { instance = section, titleLabels = {}, components = {} }
			local old = previous and previous.sectionByInstance[section]
			if old then
				record.hidden = old.hidden
			end
			sectionByInstance[section] = record
			sections[#sections + 1] = record
		end
		return record
	end

	local function ensureComponent(root)
		local record = componentByRoot[root]
		if not record then
			local sectionRoot = nearestAncestor(root, UUID.Static("IsSection"))
			record = {
				root = root,
				section = sectionRoot and ensureSection(sectionRoot) or nil,
				labels = {},
			}
			-- Carry hide state across a rebuild so nothing stays invisible.
			local old = previous and previous.componentByRoot[root]
			if old then
				record.hidden = old.hidden
				record.hiddenWasVisible = old.hiddenWasVisible
			end
			componentByRoot[root] = record
			components[#components + 1] = record
			if record.section then
				record.section.components[#record.section.components + 1] = record
			end
		end
		return record
	end

	-- First pass: collect sections and component roots.
	for _, d in ipairs(page:GetDescendants()) do
		if d:GetAttribute(UUID.Static("IsSection")) then
			ensureSection(d)
		elseif d:GetAttribute(UUID.Static("IsComponentContainer")) then
			ensureComponent(d)
		end
	end

	-- Second pass: attach searchable labels to their nearest component.
	for _, d in ipairs(page:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			local name = d.Name
			if name == UUID.Static("ElementName") or name == UUID.Static("LabelDescription") then
				local componentRoot = nearestAncestor(d, UUID.Static("IsComponentContainer"))
				local component = componentRoot and componentByRoot[componentRoot]
				if component then
					component.labels[#component.labels + 1] = d
				end
			elseif name == UUID.Static("SectionTitle") then
				local sectionRoot = nearestAncestor(d, UUID.Static("IsSection"))
				if sectionRoot then
					local section = ensureSection(sectionRoot)
					section.titleLabels[#section.titleLabels + 1] = d
				end
			end
		end
	end

	-- Every component with no labels is still a valid, visible result.
	return {
		sections = sections,
		components = components,
		componentByRoot = componentByRoot,
		sectionByInstance = sectionByInstance,
	}
end

local function getIndex(page)
	local idx = indexByPage[page]
	if idx and not dirtyByPage[page] then
		return idx
	end
	idx = buildIndex(page, idx)
	indexByPage[page] = idx
	dirtyByPage[page] = nil
	if not connectedByPage[page] then
		connectedByPage[page] = true
		-- Connections attach to the page's signals and end with it.
		page.DescendantAdded:Connect(function()
			dirtyByPage[page] = true
		end)
		page.DescendantRemoving:Connect(function()
			dirtyByPage[page] = true
		end)
	end
	return idx
end

local function baseText(label)
	local base = label:GetAttribute(UUID.Static("SearchBaseText"))
	if base == nil then
		base = label.Text
		label:SetAttribute(UUID.Static("SearchBaseText"), base)
		label:SetAttribute(UUID.Static("SearchBaseRich"), label.RichText)
		return base
	end
	-- A component may repaint its label mid-search; adopt the newer text.
	local current = label.Text
	if current ~= base and current ~= label:GetAttribute(UUID.Static("SearchHighlightText")) then
		base = current
		label:SetAttribute(UUID.Static("SearchBaseText"), base)
		label:SetAttribute(UUID.Static("SearchBaseRich"), label.RichText)
		label:SetAttribute(UUID.Static("SearchHighlightText"), nil)
	end
	return base
end

local function restore(label)
	local base = label:GetAttribute(UUID.Static("SearchBaseText"))
	if base == nil then
		return
	end
	label.Text = base
	local rich = label:GetAttribute(UUID.Static("SearchBaseRich"))
	if rich ~= nil then
		label.RichText = rich
	end
	label:SetAttribute(UUID.Static("SearchBaseText"), nil)
	label:SetAttribute(UUID.Static("SearchBaseRich"), nil)
	label:SetAttribute(UUID.Static("SearchHighlightText"), nil)
end

local function highlight(label, query, hex)
	local base = baseText(label)
	local lower = string.lower(base)
	if string.find(lower, query, 1, true) then
		local painted = buildHighlight(base, lower, query, hex)
		label.RichText = true
		label.Text = painted
		label:SetAttribute(UUID.Static("SearchHighlightText"), painted)
		return true
	end
	label.Text = base
	local rich = label:GetAttribute(UUID.Static("SearchBaseRich"))
	if rich ~= nil then
		label.RichText = rich
	end
	label:SetAttribute(UUID.Static("SearchHighlightText"), nil)
	return false
end

local function showComponent(record)
	local root = record.root
	if not root.Parent then
		return
	end
	-- Components fade with their section; hiding one is a plain visibility
	-- toggle so a query never scales or resizes the row itself.
	if not record.hidden then
		return
	end
	record.hidden = false
	if record.hiddenWasVisible ~= false then
		root.Visible = true
	end
end

local function hideComponent(record, token, page)
	local root = record.root
	if not root.Parent then
		return
	end
	if record.hidden then
		return
	end
	record.hidden = true
	record.hiddenWasVisible = root.Visible
	task.delay(HIDE_DELAY, function()
		if tokenByPage[page] ~= token or not root.Parent then
			return
		end
		root.Visible = false
	end)
end

local function showSection(record, animate)
	local section = record.instance
	if not section.Parent then
		return
	end
	section.Visible = true
	if not animate then
		PageFade.Snap(section, 0)
	else
		PageFade.Show(section, false)
	end
	record.hidden = false
end

local function hideSection(record, token, page)
	local section = record.instance
	if not section.Parent then
		return
	end
	if record.hidden then
		return
	end
	record.hidden = true
	PageFade.Hide(section, false)
	task.delay(SECTION_DELAY, function()
		if tokenByPage[page] ~= token or not section.Parent then
			return
		end
		section.Visible = false
	end)
end

local function bumpToken(page)
	local token = (tokenByPage[page] or 0) + 1
	tokenByPage[page] = token
	return token
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
	local token = bumpToken(page)
	local accent = (theme and theme.AccentColor) or Color3.fromRGB(96, 165, 250)
	local hex = colorToHex(accent)
	local idx = getIndex(page)

	-- Decide each component first, then let sections follow their contents.
	local matchedSections = {}
	for _, component in ipairs(idx.components) do
		local matched = false
		for _, label in ipairs(component.labels) do
			local base = baseText(label)
			if string.find(string.lower(base), query, 1, true) then
				matched = true
			end
			highlight(label, query, hex)
		end
		component.matched = matched
		if matched and component.section then
			matchedSections[component.section] = true
		end
	end

	for _, section in ipairs(idx.sections) do
		local titleMatch = false
		for _, label in ipairs(section.titleLabels) do
			local base = baseText(label)
			if string.find(string.lower(base), query, 1, true) then
				titleMatch = true
			end
			highlight(label, query, hex)
		end
		-- A title hit reveals the whole section; otherwise components decide.
		local visible = titleMatch or matchedSections[section] == true
		if visible then
			showSection(section, true)
			for _, component in ipairs(section.components) do
				if titleMatch or component.matched then
					showComponent(component)
				else
					hideComponent(component, token, page)
				end
			end
		else
			for _, component in ipairs(section.components) do
				hideComponent(component, token, page)
			end
			hideSection(section, token, page)
		end
	end

	-- Components outside any section still filter on their own.
	for _, component in ipairs(idx.components) do
		if not component.section then
			if component.matched then
				showComponent(component)
			else
				hideComponent(component, token, page)
			end
		end
	end
end

function SearchFilter.Clear(page)
	if not page then
		return
	end
	bumpToken(page)
	local idx = getIndex(page)
	for _, section in ipairs(idx.sections) do
		showSection(section, true)
		for _, component in ipairs(section.components) do
			showComponent(component)
		end
		for _, label in ipairs(section.titleLabels) do
			restore(label)
		end
	end
	for _, component in ipairs(idx.components) do
		for _, label in ipairs(component.labels) do
			restore(label)
		end
	end
end

return SearchFilter
