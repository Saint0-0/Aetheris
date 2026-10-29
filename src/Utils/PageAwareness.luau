--[[
	Aetheris/Utils/PageAwareness.luau

	Tracks which page is currently visible so components can react when their
	page is shown or hidden (video pauses, viewport stops orbiting, controls
	dim to zero and tween back on focus). A tiny singleton registry, single
	window, like SettingsStore.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local SettingsStore = require("../Core/Settings/SettingsStore")

local PageAwareness = {}

local attachedWindow = nil
local entries = {}
local nextToken = 0

-- Reads window fields directly so it works during construction.
local function currentActivePage()
	local win = attachedWindow
	if not win then
		return nil
	end
	if win._minimized then
		return nil
	end
	if win.SettingsPages and win.SettingsPages.Visible then
		local stab = win.SettingsTabGroup and win.SettingsTabGroup.ActiveTab
		return stab and stab.Page or nil
	end
	local tab = win.TabGroup and win.TabGroup.ActiveTab
	return tab and tab.ContentScroller or nil
end

local function isActiveRoot(root)
	if not root or not root.Parent then
		return false
	end
	local page = currentActivePage()
	if not page then
		return false
	end
	return root == page or root:IsDescendantOf(page)
end

-- OnActive always restores; OnInactive is gated by a settings key. `instant`
-- lets a collapse bypass its tween (registration priming).
local function fire(entry, active, instant)
	if active then
		if entry.OnActive then
			pcall(entry.OnActive)
		end
	elseif entry.OnInactive then
		local allowed = true
		if entry.Gate then
			allowed = SettingsStore.Get(entry.Gate) ~= false
		end
		if allowed then
			pcall(entry.OnInactive, instant)
		end
	end
end

function PageAwareness.Attach(win)
	attachedWindow = win
end

function PageAwareness.Detach()
	attachedWindow = nil
	for token in pairs(entries) do
		PageAwareness.Unregister(token)
	end
	table.clear(entries)
	nextToken = 0
end

-- Recompute every registration's active state and fire handlers on change.
function PageAwareness.Refresh()
	if not attachedWindow then
		return
	end
	-- Snapshot first: a handler may register or unregister as a side effect.
	local snapshot = {}
	for _, entry in pairs(entries) do
		table.insert(snapshot, entry)
	end
	for _, entry in ipairs(snapshot) do
		if entries[entry.token] then
			local now = isActiveRoot(entry.root)
			if now ~= entry.active then
				entry.active = now
				fire(entry, now)
			end
		end
	end
end

-- handlers = { OnActive, OnInactive(instant?), Gate? }. Primes the entry so the
-- first reveal has distance to cover: OnInactive collapses instantly, and a
-- visible page gets a deferred restore so startup paints a tween-in.
-- Returns a token for Unregister; the registration auto-removes on root destroy.
function PageAwareness.Register(root, handlers)
	if not root then
		return nil
	end
	handlers = handlers or {}
	nextToken += 1
	local token = nextToken
	local entry = {
		token = token,
		root = root,
		OnActive = handlers.OnActive,
		OnInactive = handlers.OnInactive,
		Gate = handlers.Gate,
		active = isActiveRoot(root),
	}
	entries[token] = entry
	if root.Destroying then
		local conn
		conn = root.Destroying:Connect(function()
			PageAwareness.Unregister(token)
			if conn then
				conn:Disconnect()
			end
		end)
		entry._conn = conn
	end
	if entry.OnInactive then
		fire(entry, false, true)
	end
	if entry.active then
		-- Restore next resumption so the pair reads as a tween-in rather than a snap.
		task.defer(function()
			local live = entries[token]
			if live and live.active then
				fire(live, true)
			end
		end)
	end
	return token
end

-- Re-apply gated handlers for off-page entries after a gate setting changed;
-- Refresh can't catch this because the visible page hasn't changed.
function PageAwareness.ReapplyGates()
	local snapshot = {}
	for _, entry in pairs(entries) do
		if entry.Gate and not entry.active then
			table.insert(snapshot, entry)
		end
	end
	for _, entry in ipairs(snapshot) do
		if entries[entry.token] then
			if SettingsStore.Get(entry.Gate) ~= false then
				pcall(entry.OnInactive)
			else
				pcall(entry.OnActive)
			end
		end
	end
end

function PageAwareness.Unregister(token)
	local entry = entries[token]
	if not entry then
		return
	end
	entries[token] = nil
	if entry._conn then
		entry._conn:Disconnect()
		entry._conn = nil
	end
end

function PageAwareness.IsActive(root)
	return isActiveRoot(root)
end

return PageAwareness
