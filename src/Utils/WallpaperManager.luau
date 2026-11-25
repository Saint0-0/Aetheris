--[[
	Aetheris/Utils/WallpaperManager.luau

	Resolves theme wallpapers from local executor files, GitHub downloads, or Roblox asset fallbacks.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

--# selene: allow(undefined_variable, incorrect_standard_library_use)

local Constants = require("../Constants")

local WallpaperManager = {}

local ROOT = "Aetheris"
local WALLPAPERS_FOLDER = "Aetheris/Wallpapers"
local GITHUB_BASE = "https://raw.githubusercontent.com/Saint0-0/Aetheris/main/assets/wallpapers/"

WallpaperManager.Repository = GITHUB_BASE

local FALLBACK_WALLPAPERS = {
	Base = "rbxassetid://126475867393987",
	Umbral = "rbxassetid://108134687422467",
	Ember = "rbxassetid://112056619173488",
	Vesper = "rbxassetid://139008744622245",
	Duskfall = "rbxassetid://84448785488489",
	Canopy = "rbxassetid://117265363863813",
	Tidewater = "rbxassetid://135568871834704",
	Nocturne = "rbxassetid://95435913199118",
	Solace = "rbxassetid://92445107726358",
	Cielo = "rbxassetid://98569091830887",
	Honey = "rbxassetid://73850635447680",
	Dawn = "rbxassetid://88171125327716",
	Alpine = "rbxassetid://123969479560901",
	Peony = "rbxassetid://131979800493713",
	Sakura = "rbxassetid://83848197180836",
	Blush = "rbxassetid://8350591200",
	Cinder = "rbxassetid://91682462344785",
	Mauve = "rbxassetid://129556634773235",
	Iris = "rbxassetid://74675854421559",
	Sundown = "rbxassetid://80301124180881",
	Twilight = "rbxassetid://110295134647166",
	Nebula = "rbxassetid://110937489750863",
	Monterey = "rbxassetid://126475867393987",
	Sonoma = "rbxassetid://114699504726298",
	Ventura = "rbxassetid://100629172964437",
	Vermilion = "rbxassetid://18571374017",
	Grove = "rbxassetid://116321051235221",
	Prism = "rbxassetid://78613064348772",
	Sage = "rbxassetid://97394507475736",
	Blossom = "rbxassetid://13426533185317",
	Petal = "rbxassetid://119516266319751",
	Frost = "rbxassetid://81270141924137",
	Amber = "rbxassetid://79886157813963",
	Rosa = "rbxassetid://107522899082679",
	Gruvbox = "rbxassetid://73850635447680",
	Graphite = "rbxassetid://126475867393987",
	Crimson = "rbxassetid://112056619173488",
	Umber = "rbxassetid://88171125327716",
	Mint = "rbxassetid://116321051235221",
	Lilac = "rbxassetid://100629172964437",
	Linen = "rbxassetid://98569091830887",
	Slate = "rbxassetid://126475867393987",
	Onyx = "rbxassetid://108134687422467",
	Ash = "rbxassetid://88171125327716",
	Gunmetal = "rbxassetid://123969479560901",
	Charcoal = "rbxassetid://91682462344785",
	Void = "rbxassetid://108134687422467",
	Volt = "rbxassetid://117265363863813",
	Bone = "rbxassetid://73850635447680",
	Merlot = "rbxassetid://84448785488489",
	Khaki = "rbxassetid://116321051235221",
}

WallpaperManager.FallbackRegistry = FALLBACK_WALLPAPERS

local customAssetFn = (typeof(getcustomasset) == "function" and getcustomasset)
	or (typeof(getsynasset) == "function" and getsynasset)
	or nil

local hasFileAPI = (typeof(writefile) == "function" and typeof(readfile) == "function")

local function ensureFolder(path)
	if typeof(makefolder) ~= "function" then
		return
	end
	if typeof(isfolder) == "function" and isfolder(path) then
		return
	end
	pcall(makefolder, path)
end

function WallpaperManager.EnsureFolders()
	if not hasFileAPI then
		return
	end
	ensureFolder(ROOT)
	ensureFolder(WALLPAPERS_FOLDER)
end

local function cleanFileName(path)
	local name = string.gsub(path, "\\", "/")
	local lastSlash = string.find(string.reverse(name), "/")
	if lastSlash then
		return string.sub(name, #name - lastSlash + 2)
	end
	return name
end

function WallpaperManager.ListLocal()
	WallpaperManager.EnsureFolders()
	local list = {}
	if typeof(listfiles) ~= "function" then
		return list
	end
	local ok, files = pcall(listfiles, WALLPAPERS_FOLDER)
	if not ok or type(files) ~= "table" then
		return list
	end
	for _, path in ipairs(files) do
		local isDir = false
		if typeof(isfolder) == "function" then
			local dirOk, dirResult = pcall(isfolder, path)
			isDir = dirOk and dirResult == true
		end
		if not isDir then
			local name = cleanFileName(path)
			if name ~= "" then
				table.insert(list, name)
			end
		end
	end
	table.sort(list)
	return list
end

local LOCAL_EXTENSIONS = { "", ".png", ".jpg", ".jpeg", ".PNG", ".JPG", ".JPEG" }

local function findLocalFile(query)
	if not hasFileAPI or typeof(isfile) ~= "function" then
		return nil
	end
	local bases = { query }
	local lower = string.lower(query)
	if lower ~= query then
		table.insert(bases, lower)
	end
	for _, base in ipairs(bases) do
		for _, ext in ipairs(LOCAL_EXTENSIONS) do
			local path = WALLPAPERS_FOLDER .. "/" .. base .. ext
			local ok, exists = pcall(isfile, path)
			if ok and exists then
				return path
			end
		end
	end
	return nil
end

-- Percent-encode only what raw.githubusercontent.com needs; slashes and
-- ordinary filename characters stay readable.
local function encodePath(value)
	return (string.gsub(value, "[^%w%-%._~/]", function(char)
		return string.format("%%%02X", string.byte(char))
	end))
end

local function httpGet(url)
	if typeof(game) == "Instance" and typeof(game.HttpGet) == "function" then
		local ok, res = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and type(res) == "string" and #res > 0 then
			return res
		end
	end
	local req = (typeof(request) == "function" and request) or (typeof(http_request) == "function" and http_request)
	if req then
		local ok, response = pcall(req, { Url = url, Method = "GET" })
		if ok and type(response) == "table" and (response.StatusCode == 200 or response.Status == 200) then
			return response.Body
		end
	end
	return nil
end

local REMOTE_EXTENSIONS = { "", ".png", ".jpg", ".jpeg" }

local function downloadFromGitHub(name)
	if not hasFileAPI or typeof(writefile) ~= "function" then
		return nil
	end
	WallpaperManager.EnsureFolders()
	local hasExtension = string.match(name, "%.[%w]+$") ~= nil
	local extensions = hasExtension and { "" } or REMOTE_EXTENSIONS
	for _, ext in ipairs(extensions) do
		local fileName = name .. ext
		local url = WallpaperManager.Repository .. encodePath(fileName)
		local data = httpGet(url)
		if data and #data > 0 then
			local savePath = WALLPAPERS_FOLDER .. "/" .. fileName
			local ok = pcall(writefile, savePath, data)
			if ok then
				return savePath
			end
		end
	end
	return nil
end

local cache = {}
local pending = {}

function WallpaperManager.ClearCache()
	cache = {}
end

local function assetFor(str, callback)
	if cache[str] then
		return cache[str]
	end

	local fallback = FALLBACK_WALLPAPERS[str] or Constants.FallbackImage

	if not customAssetFn then
		return fallback
	end

	local localPath = findLocalFile(str)
	if localPath then
		local ok, asset = pcall(customAssetFn, localPath)
		if ok and asset then
			cache[str] = asset
			return asset
		end
	end

	if hasFileAPI then
		local entry = pending[str]
		if entry then
			table.insert(entry.callbacks, callback)
			return fallback
		end
		entry = { callbacks = { callback } }
		pending[str] = entry
		task.spawn(function()
			local downloadedPath = downloadFromGitHub(str)
			if downloadedPath then
				local ok, asset = pcall(customAssetFn, downloadedPath)
				if ok and asset then
					cache[str] = asset
					for _, fn in ipairs(entry.callbacks) do
						if type(fn) == "function" then
							pcall(fn, asset)
						end
					end
				end
			end
			pending[str] = nil
		end)
	end

	return fallback
end

function WallpaperManager.GetAsset(wallpaperInput, callback)
	if wallpaperInput == nil or wallpaperInput == "" then
		return Constants.FallbackImage
	end

	if type(wallpaperInput) == "number" then
		return string.format("rbxassetid://%d", wallpaperInput)
	end

	local str = tostring(wallpaperInput)
	if
		string.sub(str, 1, 13) == "rbxassetid://"
		or string.sub(str, 1, 11) == "rbxasset://"
		or string.sub(str, 1, 7) == "http://"
		or string.sub(str, 1, 8) == "https://"
	then
		return str
	end

	if tonumber(str) then
		return "rbxassetid://" .. str
	end

	return assetFor(str, callback)
end

return WallpaperManager
