--[[
	PageAwareness  ·  Aetheris UI Library

	Tracks which page is currently visible so components can react when their
	page is shown or hidden (video pauses, viewport stops orbiting, controls
	dim to zero and tween back on focus). A tiny singleton registry, single
	window, like SettingsStore.
]]

local SettingsStore = require("../Core/Settings/SettingsStore")

local PageAwareness = {}

local attachedWindow = nil
local entries = {}
local nextToken = 0

-- Resolve the container of the page that is on screen right now, or nil when
-- nothing is showing (window minimized). Reads window fields directly so it
-- works during construction, before the window's GetActivePage closure exists.
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

-- OnActive always restores. OnInactive is gated by a settings key so a feature
-- can be switched off; because OnActive is unconditional, toggling the gate off
-- can never leave a component visually stuck in its dimmed state.
-- `instant` is passed through to OnInactive as its first argument so a
-- collapse can bypass its tween (used by registration priming, where a
-- tweened collapse would still be mid-flight when the restore lands).
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
-- Safe to call on any page transition; components are evaluated lazily against
-- the current window state rather than tracked eagerly.
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

-- handlers = { OnActive, OnInactive(instant?), Gate? }. Evaluates active state
-- at registration, then PRIMES the entry so the first reveal has distance to
-- cover: OnInactive fires immediately (instantly, gated exactly like a real
-- hide) to collapse the control, and if the page is already visible OnActive
-- is deferred a resumption so startup paints a tween-in instead of showing
-- pre-set values. Hidden pages simply keep the collapsed state until the
-- normal Refresh transition restores them.
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
		-- Page already on screen (the startup tab, or a component created
		-- later on the visible page): restore next resumption so the pair
		-- reads as a tween-in rather than a snap.
		task.defer(function()
			local live = entries[token]
			if live and live.active then
				fire(live, true)
			end
		end)
	end
	return token
end

-- Re-apply gated handlers for off-page entries after a gate setting changed:
-- turning a feature on dims them again, turning it off restores them. Refresh
-- can't do this because the visible page hasn't changed, so nothing would fire.
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
