--[[
	SettingsStore  ·  Aetheris UI Library

	Central store for user-adjustable settings (theme, UI scale, minimize key,
	spin toggle, confirm-on-close, UI volume). Single source of truth that the
	UI reads from on build and writes to on change.

	Persistence: saves JSON to Aetheris/UI Settings/ when an executor file
	API is available, otherwise falls back to a session-only table. This keeps
	it working in Studio and in a plain game, while persisting across sessions
	in an executor.

	Public API: Load, Get, Set, Save (debounced), SaveNow, Flush, Defaults.
]]

--# selene: allow(undefined_variable)
-- The executor file API (writefile/readfile/isfile) is injected by the host
-- executor at runtime, not defined in source. It is probed defensively with
-- type(x) == "function", so referencing it is intentional. Scoped to THIS
-- file only, so a genuine undefined-variable typo elsewhere is still caught.

local HttpService = game:GetService("HttpService")

local SettingsStore = {}

-- UI settings persist in their own folder under the workspace root. The
-- pre-folder file (root of the workspace) is migrated in-place on first load.
local SETTINGS_FOLDER = "Aetheris/UI Settings"
local FILE_NAME = SETTINGS_FOLDER .. "/UI Settings.json"
local LEGACY_FILE = "Aetheris_settings.json"

-- Executor file API (present in most executors, absent in Studio/vanilla).
local hasFileAPI = (type(writefile) == "function" and type(readfile) == "function")

local function ensureFolder(path)
	if type(makefolder) ~= "function" then
		return
	end
	if isfolder and isfolder(path) then
		return
	end
	pcall(function()
		makefolder(path)
	end)
end

-- Set when Load read the pre-folder file; SaveNow writes the new path first,
-- then deletes the legacy file.
local migratedFromLegacy = false

-- Defaults. Anything missing from a loaded config falls back to these.
SettingsStore.Defaults = {
	Theme = nil, -- nil = whatever CreateWindow was given
	UIScale = 1, -- window scale, 0.8 - 1.25
	MinimizeKey = nil, -- nil = whatever CreateWindow was given
	SpinsEnabled = true,
	ConfirmClose = true,
	Volume = 1,
	PillPosition = "right", -- minimize pill: "right" | "left" | "top" | "bottom"
	CompactMode = "auto", -- "auto" (by width) | "always" | "never"
	PageAnimations = true, -- toggle/slider/stepper focus animations on page switch
	Font = nil, -- nil = built-in Aetheris font (see Constants.FontChoices)
	MaskDisplayName = false, -- start new windows with display name / username masked
	AutoSaveConfigs = false, -- auto-save the active config on component change
}

SettingsStore.Data = {}
for k, v in pairs(SettingsStore.Defaults) do
	SettingsStore.Data[k] = v
end

-- A Lua table can't hold a nil value, so keys whose default is "unset"
-- (Theme / MinimizeKey / Font) don't appear in Defaults and would be dropped
-- by the load filter below. List them so they still round-trip through the
-- saved JSON file.
SettingsStore.NilDefaultKeys = { "Theme", "MinimizeKey", "Font" }

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
	if not (ok and content and content ~= "") then
		-- Legacy migration: read the pre-folder file at the workspace root.
		local okLegacy, legacy = pcall(function()
			if isfile and not isfile(LEGACY_FILE) then
				return nil
			end
			return readfile(LEGACY_FILE)
		end)
		if okLegacy and legacy and legacy ~= "" then
			content = legacy
			migratedFromLegacy = true
		end
	end
	if content and content ~= "" then
		local decoded
		local ok2, result = pcall(function()
			return HttpService:JSONDecode(content)
		end)
		if ok2 and type(result) == "table" then
			decoded = result
		end
		if decoded then
			local allowed = {}
			for k in pairs(SettingsStore.Defaults) do
				allowed[k] = true
			end
			for _, k in ipairs(SettingsStore.NilDefaultKeys) do
				allowed[k] = true
			end
			for k, v in pairs(decoded) do
				if allowed[k] and v ~= nil then
					SettingsStore.Data[k] = v
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
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(SettingsStore.Data)
	end)
	if ok and encoded then
		local wrote = pcall(function()
			ensureFolder("Aetheris")
			ensureFolder(SETTINGS_FOLDER)
			writefile(FILE_NAME, encoded)
		end)
		-- Drop the legacy root file only after the new path has the data.
		if wrote and migratedFromLegacy then
			migratedFromLegacy = false
			pcall(function()
				if delfile then
					delfile(LEGACY_FILE)
				end
			end)
		end
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
