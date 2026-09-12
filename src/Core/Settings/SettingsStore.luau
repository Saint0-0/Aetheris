--[[
	SettingsStore  ·  Aetheris UI Library

	Central store for user-adjustable settings (theme, UI scale, minimize key,
	spin toggle, confirm-on-close, UI volume). Single source of truth that the
	UI reads from on build and writes to on change.

	Persistence: saves JSON to a file when an executor file API is available
	(writefile/readfile/isfile), otherwise falls back to a session-only table.
	This keeps it working in Studio and in a plain game, while persisting
	across sessions in an executor.

	Public API: Load, Get, Set, Save, Defaults.
]]

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

function SettingsStore.Save()
	if not hasFileAPI then
		return
	end
	local ok, encoded = pcall(function() return HttpService:JSONEncode(SettingsStore.Data) end)
	if ok and encoded then
		pcall(function() writefile(FILE_NAME, encoded) end)
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