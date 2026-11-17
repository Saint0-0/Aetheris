--[[
	Aetheris/Core/Settings/SettingsStore.luau

	Central store for user settings, persisted as JSON to Aetheris/UI Settings/.
	Without an executor file API the values are session-only.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

--# selene: allow(undefined_variable)
-- Executor file APIs are injected by the host and probed before every use.

local HttpService = game:GetService("HttpService")

local SettingsStore = {}

-- Settings live in their own folder; the root-level file migrates in place.
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

local migratedFromLegacy = false -- Set by Load; SaveNow deletes the legacy file.

SettingsStore.Defaults = {
	Theme = nil, -- nil uses CreateWindow's value.
	UIScale = 1, -- Window scale, 0.8 to 1.25.
	MinimizeKey = nil, -- nil uses CreateWindow's value.
	SpinsEnabled = true,
	ConfirmClose = true,
	Volume = 1,
	PillPosition = "right", -- Minimize pill side.
	CompactMode = "auto", -- "auto", "always" or "never".
	PageAnimations = true,
	Font = nil, -- nil uses the built-in font.
	MaskDisplayName = false,
	AutoSaveConfigs = false,
	Locale = "en", -- Active UI locale id.
	WindowWallpaperEnabled = false, -- Shell wallpaper behind translucent fills.
	ContentWallpaperEnabled = false, -- Wallpaper over the content fill.
	WallpaperTransparency = 0.85, -- Wallpaper transparency, 0 solid to 1 gone.
	EdgeFadeEnabled = false, -- Scroll edge fades.
}

SettingsStore.Data = {}
for k, v in pairs(SettingsStore.Defaults) do
	SettingsStore.Data[k] = v
end

-- Nil defaults cannot round-trip through JSON, so Load keeps them explicitly.
SettingsStore.NilDefaultKeys = { "Theme", "MinimizeKey", "Font", "ChangelogVersion", "UIChangeLogVersion" }

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
		-- Fall back to the legacy root-level file.
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

-- Immediate write; most callers want the debounced Save instead.
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
		-- Drop the legacy file only after the new path has the data.
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

-- Coalesce slider drags into one write about 300ms after the last change.
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
