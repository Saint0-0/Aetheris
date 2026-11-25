--[[
	Aetheris/Themes/CustomThemeManager.luau

	Manages user-created custom themes: saving to and loading from Aetheris/Custom Themes/ as JSON.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

--# selene: allow(undefined_variable)

local HttpService = game:GetService("HttpService")
local ThemeDefinitions = require("./ThemeDefinitions")
local ThemeManager = require("./ThemeManager")

local CustomThemeManager = {}

local ROOT = "Aetheris"
local FOLDER = "Aetheris/Custom Themes"
local FILE = FOLDER .. "/Custom Themes.json"

local hasFileAPI = (typeof(writefile) == "function" and typeof(readfile) == "function")

local _customThemes = {}
local _changeCallbacks = {}

local function ensureFolder(path)
	if typeof(makefolder) ~= "function" then
		return
	end
	if typeof(isfolder) == "function" and isfolder(path) then
		return
	end
	pcall(makefolder, path)
end

function CustomThemeManager.EnsureFolders()
	if not hasFileAPI then
		return
	end
	ensureFolder(ROOT)
	ensureFolder(FOLDER)
end

local function cleanThemeName(name)
	if type(name) ~= "string" then
		return nil
	end
	local clean = string.gsub(name, '[/\\:*?"<>|]', "")
	clean = string.gsub(clean, "^%s+", "")
	clean = string.gsub(clean, "%s+$", "")
	return clean
end

local function colorToTable(color)
	if typeof(color) == "Color3" then
		return {
			r = math.round(color.R * 255),
			g = math.round(color.G * 255),
			b = math.round(color.B * 255),
		}
	end
	return color
end

local function tableToColor(val)
	if typeof(val) == "Color3" then
		return val
	end
	if type(val) == "table" then
		local r = val.r or val.R
		local g = val.g or val.G
		local b = val.b or val.B
		if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
			return nil
		end
		return Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255))
	end
	if type(val) == "string" and string.sub(val, 1, 1) == "#" then
		local ok, c = pcall(Color3.fromHex, val)
		if ok and c then
			return c
		end
	end
	return nil
end

local function serializeTheme(def)
	local out = {}
	for k, v in pairs(def) do
		if typeof(v) == "Color3" then
			out[k] = colorToTable(v)
		elseif
			(type(v) == "table" and (v.r or v.R))
			or type(v) == "number"
			or type(v) == "string"
			or type(v) == "boolean"
		then
			out[k] = v
		end
	end
	return out
end

local function deserializeTheme(raw, baseName)
	-- Missing keys come from the preset the creator started from.
	local base = (type(baseName) == "string" and ThemeDefinitions[baseName]) or ThemeDefinitions.Base
	local out = table.clone(base)
	for k, v in pairs(raw) do
		local c = tableToColor(v)
		if c then
			out[k] = c
		else
			out[k] = v
		end
	end
	return out
end

-- Custom themes must not shadow a built-in name, or deleting one would remove
-- the built-in definition from the live registry.
local function registerTheme(themeName, theme)
	local existing = _customThemes[themeName]
	if not existing and ThemeDefinitions[themeName] then
		warn("[CustomThemeManager] Skipping custom theme that shadows built-in: " .. tostring(themeName))
		return
	end
	_customThemes[themeName] = theme
	ThemeDefinitions[themeName] = theme
	ThemeManager.RegisterTheme(themeName, theme)
end

local function fireChanged()
	for _, fn in ipairs(_changeCallbacks) do
		task.spawn(fn, _customThemes)
	end
end

function CustomThemeManager.OnThemesChanged(fn)
	table.insert(_changeCallbacks, fn)
	return function()
		for i, f in ipairs(_changeCallbacks) do
			if f == fn then
				table.remove(_changeCallbacks, i)
				break
			end
		end
	end
end

function CustomThemeManager.GetNames()
	local names = {}
	for name in pairs(_customThemes) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function CustomThemeManager.Get(name)
	return _customThemes[name]
end

function CustomThemeManager.GetAll()
	return _customThemes
end

function CustomThemeManager.Save(name, themeData, description)
	local cleanName = cleanThemeName(name)
	if not cleanName or cleanName == "" then
		return false, "Invalid theme name"
	end
	if not _customThemes[cleanName] and ThemeDefinitions[cleanName] then
		return false, "A built-in theme already uses this name"
	end
	themeData = type(themeData) == "table" and themeData or {}

	local baseName = type(themeData.BaseTheme) == "string" and themeData.BaseTheme or "Base"
	if not ThemeDefinitions[baseName] then
		baseName = "Base"
	end
	local base = ThemeDefinitions[baseName] or ThemeDefinitions.Base
	local fullTheme = table.clone(base)
	for k, v in pairs(themeData) do
		if v ~= nil then
			fullTheme[k] = v
		end
	end
	if description then
		fullTheme.Description = description
	end
	fullTheme.Name = cleanName
	fullTheme.BaseTheme = baseName

	registerTheme(cleanName, fullTheme)

	if hasFileAPI then
		CustomThemeManager.EnsureFolders()
		local allSerialized = {}
		for tName, def in pairs(_customThemes) do
			allSerialized[tName] = serializeTheme(def)
		end
		local ok1, encoded = pcall(function()
			return HttpService:JSONEncode(allSerialized)
		end)
		if ok1 and encoded then
			pcall(writefile, FILE, encoded)
		end

		local singleOk, singleEncoded = pcall(function()
			return HttpService:JSONEncode(serializeTheme(fullTheme))
		end)
		if singleOk and singleEncoded then
			pcall(writefile, FOLDER .. "/" .. cleanName .. ".json", singleEncoded)
		end
	end

	fireChanged()
	return true, cleanName
end

function CustomThemeManager.Delete(name)
	if not _customThemes[name] then
		return false, "Theme not found"
	end
	_customThemes[name] = nil
	ThemeManager.UnregisterTheme(name)

	if hasFileAPI then
		CustomThemeManager.EnsureFolders()
		local allSerialized = {}
		for tName, def in pairs(_customThemes) do
			allSerialized[tName] = serializeTheme(def)
		end
		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(allSerialized)
		end)
		if ok and encoded then
			pcall(writefile, FILE, encoded)
		end

		local singleFile = FOLDER .. "/" .. name .. ".json"
		if typeof(delfile) == "function" and typeof(isfile) == "function" then
			local fileOk, hasFile = pcall(isfile, singleFile)
			if fileOk and hasFile then
				pcall(delfile, singleFile)
			end
		end
	end

	fireChanged()
	return true
end

function CustomThemeManager.LoadAll()
	if not hasFileAPI or typeof(isfile) ~= "function" then
		return _customThemes
	end
	CustomThemeManager.EnsureFolders()

	local ok, exists = pcall(isfile, FILE)
	if ok and exists then
		local readOk, content = pcall(readfile, FILE)
		if readOk and type(content) == "string" and #content > 0 then
			local decodeOk, data = pcall(function()
				return HttpService:JSONDecode(content)
			end)
			if decodeOk and type(data) == "table" then
				for name, rawDef in pairs(data) do
					if type(name) == "string" and type(rawDef) == "table" then
						local theme = deserializeTheme(rawDef, rawDef.BaseTheme)
						registerTheme(name, theme)
					end
				end
			end
		end
	end

	if typeof(listfiles) == "function" then
		local listOk, files = pcall(listfiles, FOLDER)
		if listOk and type(files) == "table" then
			for _, filePath in ipairs(files) do
				local norm = string.gsub(filePath, "\\", "/")
				if string.sub(norm, -5) == ".json" and not string.find(norm, "Custom Themes.json", 1, true) then
					local lastSlash = string.find(string.reverse(norm), "/")
					local fName = lastSlash and string.sub(norm, #norm - lastSlash + 2, -6) or string.sub(norm, 1, -6)
					if fName ~= "" and not _customThemes[fName] then
						local rOk, c = pcall(readfile, norm)
						if rOk and type(c) == "string" and #c > 0 then
							local dOk, raw = pcall(function()
								return HttpService:JSONDecode(c)
							end)
							if dOk and type(raw) == "table" then
								local theme = deserializeTheme(raw, raw.BaseTheme)
								registerTheme(fName, theme)
							end
						end
					end
				end
			end
		end
	end

	fireChanged()
	return _customThemes
end

return CustomThemeManager
