--[[
	Aetheris/Core/Settings/SettingsStore.luau

	Central store for user-adjustable settings (theme, UI scale, minimize key,
	spin toggle, confirm-on-close, UI volume), persisted as JSON to
	Aetheris/UI Settings/ when an executor file API exists, session-only
	otherwise. Load, Get, Set, Save (debounced), SaveNow, Flush, Defaults.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

--# selene: allow(undefined_variable)
-- Executor file APIs (writefile/readfile/isfile) are injected by the host and
-- probed with type() checks before every use.

local HttpService = game:GetService("HttpService")

local SettingsStore = {}

-- Settings live in their own folder; the old root-level file migrates in-place
local SETTINGS_FOLDER = "Aetheris/UI Settings"
local FILE_NAME = SETTINGS_FOLDER .. "/UI Settings.json"
local LEGACY_FILE = "Aetheris_settings.json"

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

local migratedFromLegacy = false -- Load read the old root file; SaveNow rewrites then deletes it

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

-- nil defaults (Theme / MinimizeKey / Font) can't round-trip through a Lua
-- table or the saved JSON on their own; list them so Load keeps them.
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
		-- fall back to the old root-level file (migrated below)
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

-- Immediate write; most callers want the debounced Save() instead.
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

-- Debounced write: a UI Scale / Volume slider drag fires Set() per mouse
-- move, so coalesce into one write ~300ms after the last change.
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

function SettingsStore.Flush()
	if pendingSave then
		task.cancel(pendingSave)
		pendingSave = nil
		SettingsStore.SaveNow()
	end
end

function SettingsStore.Get(key)
	local v = SettingsStore.Data[key]
	if v == nil then
		return SettingsStore.Defaults[key]
	end
	return v
end

function SettingsStore.Set(key, value)
	SettingsStore.Data[key] = value
	SettingsStore.Save()
end

return SettingsStore
