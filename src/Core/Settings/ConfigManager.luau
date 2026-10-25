--[[
	ConfigManager  ·  Aetheris UI Library

	Per-game config save/load in the Fluent SaveManager style: JSON files
	under Aetheris/Games/<placeId>/<WindowTitle>/. Components built through
	windowed Sections register here; Save writes their values, Load restores
	them (callbacks fire so script logic reacts to a load).
]]

--# selene: allow(undefined_variable)
-- The executor file API (writefile/readfile/isfile/makefolder/delfile) is
-- injected by the host executor, not defined in source. It is probed
-- defensively with type(x) == "function" (SettingsStore pattern), scoped here.

local HttpService = game:GetService("HttpService")
local SettingsStore = require("./SettingsStore")

local ROOT = "Aetheris"
local GAMES = ROOT .. "/Games"

local hasFileAPI = (type(writefile) == "function" and type(readfile) == "function")

local ConfigManager = {}
ConfigManager.__index = ConfigManager

-- Value parsers per component kind. Save converts the component to a plain
-- (JSON-encodable) value; Load applies a plain value back via the component's
-- public setter. Setters' first arg is the self placeholder (colon calls).
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
				comp:SetText(value, true) -- silent: no focus flash on load
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
				comp:SetValue(value, true) -- silent: no callback on load
			end
		end,
	},
	Stepper = {
		Save = function(comp)
			return comp:GetValue()
		end,
		Load = function(comp, value)
			if value ~= nil then
				comp:SetValue(value, true) -- noCallback
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
			}
		end,
		Load = function(comp, value)
			if type(value) == "table" and #value == 3 then
				comp:SetColor(Color3.fromRGB(value[1] or 0, value[2] or 0, value[3] or 0), true)
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

-- Strip rich-text tags and path-illegal characters from the window title so
-- it is usable as a folder name; fall back when nothing usable remains.
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

function ConfigManager.new(window)
	local self = setmetatable({}, ConfigManager)
	self._window = window
	self._entries = {} -- { { key, parser, comp } }
	self._usedKeys = {}
	self._pendingSave = nil
	self.Active = nil -- config name auto-save writes back to
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

-- Called by Section factories. Keys are "Section.ComponentName" (Fluent
-- style) with a numeric suffix on collisions, so save files stay stable
-- across sessions as long as the script builds the same UI.
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
	for _, entry in ipairs(self._entries) do
		local ok, value = pcall(entry.parser.Save, entry.comp)
		if ok and value ~= nil then
			data[entry.key] = value
		end
	end
	return data
end

-- Re-list the folder on every call (Fluent's refresh pattern), so configs
-- written by other sessions/scripts show up without a stale cache.
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
		return HttpService:JSONEncode(self:Serialize())
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
	return true
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
	for _, entry in ipairs(self._entries) do
		local value = data[entry.key]
		if value ~= nil then
			pcall(entry.parser.Load, entry.comp, value)
		end
	end
	self.Active = name
	return true
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

-- Raw file content for the Configs page preview (CodeView, json).
function ConfigManager:Preview(name)
	if not hasFileAPI then
		return nil
	end
	name = sanitizeName(name)
	local ok, content = pcall(function()
		return readfile(self.Folder .. "/" .. name .. ".json")
	end)
	if ok and content then
		return content
	end
	return nil
end

-- Debounced auto-save hook: component callbacks ping this on every user
-- change; writes land ~0.5s after the last one, only on the active config.
function ConfigManager:NotifyChanged()
	if not self._autoSave or not self.Active then
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
	-- Make auto-save useful immediately: with no active config yet, changes
	-- would accumulate nowhere, so adopt a default target on enable.
	if self._autoSave and not self.Active then
		self.Active = "Autosave"
	end
end

function ConfigManager:GetAutoSave()
	return self._autoSave
end

-- Window teardown: write any pending auto-save now instead of losing it.
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
