--[[
	Aetheris/Core/Settings/ConfigManager.luau

	Per-game config save and load as JSON under Aetheris/Games/<placeId>/<WindowTitle>/.
	Windowed sections register here, so Save writes their values and Load restores them.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

--# selene: allow(undefined_variable)
-- Executor file APIs are injected by the host and probed before every use.

local HttpService = game:GetService("HttpService")
local SettingsStore = require("./SettingsStore")

local ROOT = "Aetheris"
local GAMES = ROOT .. "/Games"
-- Reserved key so the saved theme travels with the config.
local THEME_KEY = "_theme"

local hasFileAPI = (type(writefile) == "function" and type(readfile) == "function")

local ConfigManager = {}
ConfigManager.__index = ConfigManager

-- Save converts a component to JSON; Load applies it through its setter.
local Parsers = {
	Toggle = {
		Save = function(comp)
			return comp:GetState()
		end,
		Load = function(comp, value)
			if type(value) == "boolean" then
				comp:UpdateState(value)
			end
		end,
	},
	Slider = {
		Save = function(comp)
			return comp:GetValue()
		end,
		Load = function(comp, value)
			if type(value) == "number" then
				comp:UpdateValue(value)
			end
		end,
	},
	Keybind = {
		Save = function(comp)
			return comp:GetBind()
		end,
		Load = function(comp, value)
			if type(value) == "string" then
				comp:SetBind(value)
			end
		end,
	},
	TextInput = {
		Save = function(comp)
			return comp:GetText()
		end,
		Load = function(comp, value)
			if type(value) == "string" then
				comp:SetText(value)
			end
		end,
	},
	Dropdown = {
		Save = function(comp)
			local values = {}
			for _, sel in ipairs(comp:GetSelected()) do
				table.insert(values, sel.value)
			end
			return values
		end,
		Load = function(comp, value)
			if type(value) == "table" then
				comp:SetValue(value)
			end
		end,
	},
	Stepper = {
		Save = function(comp)
			return comp:GetValue()
		end,
		Load = function(comp, value)
			if value ~= nil then
				comp:SetValue(value)
			end
		end,
	},
	ColorPicker = {
		Save = function(comp)
			local color = comp:GetColor()
			if typeof(color) ~= "Color3" then
				return nil
			end
			return {
				math.floor(color.R * 255 + 0.5),
				math.floor(color.G * 255 + 0.5),
				math.floor(color.B * 255 + 0.5),
				math.floor(comp:GetAlpha() + 0.5),
			}
		end,
		Load = function(comp, value)
			if type(value) ~= "table" or #value < 3 then
				return
			end
			comp:SetColor(Color3.fromRGB(value[1] or 0, value[2] or 0, value[3] or 0))
			if #value >= 4 then
				comp:SetAlpha(value[4])
			end
		end,
	},
	RadioButtonGroup = {
		Save = function(comp)
			local selected = comp:GetSelected()
			return selected and selected._name or nil
		end,
		Load = function(comp, value)
			if type(value) ~= "string" then
				return
			end
			for _, button in ipairs(comp.Buttons) do
				if button._name == value then
					comp:Select(button)
					break
				end
			end
		end,
	},
}

-- Folder-safe copy of the window title.
local function sanitizeTitle(title)
	title = tostring(title or ""):gsub("<[^>]->", "")
	title = title:gsub('[\\/:*?"<>|]', ""):gsub("^%s+", ""):gsub("%s+$", "")
	if title == "" then
		return "Aetheris"
	end
	return title
end

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

-- Recursive, key-sorted JSON so saved files stay readable and diffable.
local function encodePretty(value, indent)
	indent = indent or 0
	local valueType = type(value)
	if valueType == "table" then
		if #value > 0 then
			local parts = {}
			for _, item in ipairs(value) do
				table.insert(parts, encodePretty(item, indent + 1))
			end
			return "[" .. table.concat(parts, ", ") .. "]"
		end
		local keys = {}
		for key in pairs(value) do
			table.insert(keys, key)
		end
		if #keys == 0 then
			return "{}"
		end
		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b)
		end)
		local pad = string.rep("  ", indent)
		local childPad = string.rep("  ", indent + 1)
		local parts = {}
		for _, key in ipairs(keys) do
			local encodedKey = HttpService:JSONEncode(tostring(key))
			table.insert(parts, childPad .. encodedKey .. ": " .. encodePretty(value[key], indent + 1))
		end
		return "{\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "}"
	end
	if valueType == "string" then
		return HttpService:JSONEncode(value)
	end
	if valueType == "number" then
		return tostring(value)
	end
	if valueType == "boolean" then
		return value and "true" or "false"
	end
	return "null"
end

function ConfigManager.new(window)
	local self = setmetatable({}, ConfigManager)
	self._window = window
	self._entries = {} -- { { key, parser, comp } }
	self._usedKeys = {}
	self._pendingSave = nil
	self.Active = nil -- Active config name for auto-save.
	self._autoSave = SettingsStore.Get("AutoSaveConfigs") == true
	self.Available = hasFileAPI

	local title = window and window.ScriptName and window.ScriptName.Text or "Aetheris"
	self.Folder = GAMES .. "/" .. tostring(game.PlaceId) .. "/" .. sanitizeTitle(title)
	self:_ensureFolders()
	return self
end

function ConfigManager:_ensureFolders()
	if not hasFileAPI then
		return
	end
	ensureFolder(ROOT)
	ensureFolder(GAMES)
	ensureFolder(GAMES .. "/" .. tostring(game.PlaceId))
	ensureFolder(self.Folder)
end

-- Keys are "Section.ComponentName", with a numeric suffix on collisions.
function ConfigManager:Register(kind, sectionName, component)
	local parser = Parsers[kind]
	if not parser then
		return
	end
	local base = component._name or kind
	if sectionName and sectionName ~= "" then
		base = sectionName .. "." .. base
	end
	local key = base
	local n = 2
	while self._usedKeys[key] do
		key = base .. "#" .. n
		n += 1
	end
	self._usedKeys[key] = true
	table.insert(self._entries, { key = key, parser = parser, comp = component })
end

function ConfigManager:Serialize()
	local data = {}
	local themeName = self._window and self._window._themeName
	if type(themeName) == "string" then
		data[THEME_KEY] = themeName
	end
	for _, entry in ipairs(self._entries) do
		local ok, value = pcall(entry.parser.Save, entry.comp)
		if ok and value ~= nil then
			data[entry.key] = value
		end
	end
	return data
end

-- Re-list on every call so configs written elsewhere show up.
function ConfigManager:List()
	local names = {}
	if not hasFileAPI then
		return names
	end
	local ok, files = pcall(function()
		return listfiles(self.Folder)
	end)
	if ok and type(files) == "table" then
		for _, file in ipairs(files) do
			local name = tostring(file):match("([^/\\]+)%.json$")
			if name then
				table.insert(names, name)
			end
		end
	end
	table.sort(names)
	return names
end

local function sanitizeName(name)
	name = tostring(name or ""):gsub('[\\/:*?"<>|]', ""):gsub("^%s+", ""):gsub("%s+$", "")
	return name
end

function ConfigManager:Save(name)
	if not hasFileAPI then
		return false, "no file API"
	end
	name = sanitizeName(name)
	if name == "" then
		return false, "invalid name"
	end
	self:_ensureFolders()
	local ok, encoded = pcall(function()
		return encodePretty(self:Serialize())
	end)
	if not ok then
		return false, "encode failed"
	end
	local wrote = pcall(function()
		writefile(self.Folder .. "/" .. name .. ".json", encoded)
	end)
	if not wrote then
		return false, "write failed"
	end
	self.Active = name
	return true, name
end

-- Shared by Load and Apply so both restore theme and component values the same way.
function ConfigManager:_applyData(data, name)
	if name then
		self.Active = name
	end
	-- Callbacks fire during load; the guard keeps them from triggering an auto-save.
	self._loading = true
	local themeName = data[THEME_KEY]
	if type(themeName) == "string" and self._window and self._window.SetTheme then
		pcall(function()
			self._window:SetTheme(themeName)
		end)
	end
	for _, entry in ipairs(self._entries) do
		local value = data[entry.key]
		if value ~= nil then
			pcall(entry.parser.Load, entry.comp, value)
		end
	end
	self._loading = false
end

function ConfigManager:Load(name)
	if not hasFileAPI then
		return false, "no file API"
	end
	name = sanitizeName(name)
	local ok, content = pcall(function()
		return readfile(self.Folder .. "/" .. name .. ".json")
	end)
	if not ok or not content then
		return false, "read failed"
	end
	local okDecode, data = pcall(function()
		return HttpService:JSONDecode(content)
	end)
	if not okDecode or type(data) ~= "table" then
		return false, "decode failed"
	end
	self:_applyData(data, name)
	return true
end

-- Applies JSON text without touching the active file, for the config editor.
function ConfigManager:Apply(content)
	local okDecode, data = pcall(function()
		return HttpService:JSONDecode(content)
	end)
	if not okDecode or type(data) ~= "table" then
		return false, "invalid JSON"
	end
	-- Nothing on disk matches the UI until the player saves it again.
	self.Active = nil
	self:_applyData(data, nil)
	return true
end

-- Writes editor JSON to a named file without making it the active config.
function ConfigManager:Write(name, content)
	if not hasFileAPI then
		return false, "no file API"
	end
	name = sanitizeName(name)
	if name == "" then
		return false, "invalid name"
	end
	local okDecode, data = pcall(function()
		return HttpService:JSONDecode(content)
	end)
	if not okDecode or type(data) ~= "table" then
		return false, "invalid JSON"
	end
	local okEncode, encoded = pcall(function()
		return encodePretty(data)
	end)
	if not okEncode then
		return false, "encode failed"
	end
	self:_ensureFolders()
	local wrote = pcall(function()
		writefile(self.Folder .. "/" .. name .. ".json", encoded)
	end)
	if not wrote then
		return false, "write failed"
	end
	return true, name
end

function ConfigManager:Delete(name)
	if not hasFileAPI then
		return false, "no file API"
	end
	name = sanitizeName(name)
	local ok = pcall(function()
		delfile(self.Folder .. "/" .. name .. ".json")
	end)
	if not ok then
		return false, "delete failed"
	end
	if self.Active == name then
		self.Active = nil
	end
	return true
end

function ConfigManager:Preview(name)
	if not hasFileAPI then
		return nil
	end
	name = sanitizeName(name)
	local ok, content = pcall(function()
		return readfile(self.Folder .. "/" .. name .. ".json")
	end)
	if not ok or not content then
		return nil
	end
	local okDecode, data = pcall(function()
		return HttpService:JSONDecode(content)
	end)
	if okDecode and type(data) == "table" then
		local okEncode, pretty = pcall(function()
			return encodePretty(data)
		end)
		if okEncode then
			return pretty
		end
	end
	return content
end

-- Debounced auto-save, about 0.5s after the last change on the active config.
function ConfigManager:NotifyChanged()
	if self._loading or not self._autoSave or not self.Active then
		return
	end
	if self._pendingSave then
		task.cancel(self._pendingSave)
	end
	local name = self.Active
	self._pendingSave = task.delay(0.5, function()
		self._pendingSave = nil
		self:Save(name)
	end)
end

function ConfigManager:SetAutoSave(on)
	self._autoSave = on == true
	SettingsStore.Set("AutoSaveConfigs", self._autoSave)
	-- Auto-save needs a target config.
	if self._autoSave and not self.Active then
		self.Active = "Autosave"
	end
end

function ConfigManager:GetAutoSave()
	return self._autoSave
end

-- Write any pending auto-save before teardown.
function ConfigManager:Flush()
	if self._pendingSave then
		local name = self.Active
		task.cancel(self._pendingSave)
		self._pendingSave = nil
		if name then
			self:Save(name)
		end
	end
end

return ConfigManager
