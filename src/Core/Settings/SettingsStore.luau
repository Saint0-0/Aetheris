--[[
	SettingsStore  ·  Aetheris UI Library

	Central store for user-adjustable settings (theme, UI scale, minimize key,
	spin toggle, confirm-on-close, UI volume). Single source of truth that the
	UI reads from on build and writes to on change.

	Persistence: saves JSON to a file when an executor file API is available
	(writefile/readfile/isfile), otherwise falls back to a session-only table.
	This keeps it working in Studio and in a plain game, while persisting
	across sessions in an executor.

	Public API: Load, Get, Set, Save (debounced), SaveNow, Flush, Defaults.
]]

--# selene: allow(undefined_variable)
-- The executor file API (writefile/readfile/isfile) is injected by the host
-- executor at runtime, not defined in source. It is probed defensively with
-- type(x) == "function", so referencing it is intentional. Scoped to THIS
-- file only, so a genuine undefined-variable typo elsewhere is still caught.

local HttpService = game:GetService("HttpService")

local SettingsStore = {}

local FILE_NAME = "Aetheris_settings.json"

-- Defaults. Anything missing from a loaded config falls back to these.
SettingsStore.Defaults = {
	Theme = nil,            -- nil = whatever CreateWindow was given
	UIScale = 1,            -- window scale, 0.8 - 1.25
	MinimizeKey = nil,      -- nil = whatever CreateWindow was given
	SpinsEnabled = true,
	ConfirmClose = true,
	Volume = 1,
	PillPosition = "right", -- minimize pill: "right" | "left" | "top" | "bottom"
	CompactMode = "auto",   -- "auto" (by width) | "always" | "never"
}

SettingsStore.Data = {}
for k, v in pairs(SettingsStore.Defaults) do
	SettingsStore.Data[k] = v
end

-- Executor file API (present in most executors, absent in Studio/vanilla).
local hasFileAPI = (type(writefile) == "function" and type(readfile) == "function")

function SettingsStore.Load()
	if not hasFileAPI then
		return SettingsStore.Data
	end
	local ok, content = pcall(function()
		if isfile and not isfile(FILE_NAME) then
			return nil
		end
		return readfile(FILE_NAME)
	end)
	if ok and content and content ~= "" then
		local decoded
		local ok2, result = pcall(function() return HttpService:JSONDecode(content) end)
		if ok2 and type(result) == "table" then
			decoded = result
		end
		if decoded then
			for k in pairs(SettingsStore.Defaults) do
				if decoded[k] ~= nil then
					SettingsStore.Data[k] = decoded[k]
				end
			end
		end
	end
	return SettingsStore.Data
end

-- Immediate write. Does the JSON encode + writefile synchronously. Most
-- callers should use Save() (debounced) instead; Flush() forces this now.
function SettingsStore.SaveNow()
	if not hasFileAPI then
		return
	end
	local ok, encoded = pcall(function() return HttpService:JSONEncode(SettingsStore.Data) end)
	if ok and encoded then
		pcall(function() writefile(FILE_NAME, encoded) end)
	end
end

-- Debounced write. A drag of the UI Scale / Volume slider fires Set() on every
-- mouse move; writing the file each tick is disk I/O per frame. Coalesce those
-- into one write ~300ms after the last change. Flush() (called on window
-- teardown) writes immediately if a write is pending.
local SAVE_DEBOUNCE = 0.3
local pendingSave = nil

function SettingsStore.Save()
	if not hasFileAPI then
		return
	end
	if pendingSave then
		task.cancel(pendingSave)
	end
	pendingSave = task.delay(SAVE_DEBOUNCE, function()
		pendingSave = nil
		SettingsStore.SaveNow()
	end)
end

-- Write any pending change immediately (e.g. window closing). Safe to call
-- when nothing is pending.
function SettingsStore.Flush()
	if pendingSave then
		task.cancel(pendingSave)
		pendingSave = nil
		SettingsStore.SaveNow()
	end
end

-- Get a setting (falls back to its default).
function SettingsStore.Get(key)
	local v = SettingsStore.Data[key]
	if v == nil then
		return SettingsStore.Defaults[key]
	end
	return v
end

-- Set a setting and persist.
function SettingsStore.Set(key, value)
	SettingsStore.Data[key] = value
	SettingsStore.Save()
end

return SettingsStore