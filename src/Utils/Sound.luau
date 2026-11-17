--[[
	Aetheris/Utils/Sound.luau

	Central audio layer for the UI. One reusable Sound per named asset, all
	routed through a single AetherisUI SoundGroup.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local UUID = require("../Utils/UUID")

local SoundUtil = {}

-- Every sound the UI can play, keyed by name; Preload walks this table.
SoundUtil.Assets = {
	UIStart = "rbxassetid://6958727243",
	Notification = "rbxassetid://255881176",
	UIOpen = "rbxassetid://255881176",
	UIClose = "rbxassetid://255881176",
	UIShutdown = "rbxassetid://255881176",
	KeySystemOpen = "rbxassetid://255881176",
	KeySystemClose = "rbxassetid://255881176",
	ThemeChange = "rbxassetid://1180994874",
}

-- Per-use tuning re-applied on every Play, so call-site properties still win.
SoundUtil.Tuning = {
	UIStart = { Volume = 1 },
	UIOpen = { Volume = 0.8, PlaybackSpeed = 0.9 },
	UIClose = { Volume = 0.8, PlaybackSpeed = 0.7 },
	UIShutdown = { Volume = 0.8, PlaybackSpeed = 0.7 },
	Notification = { Volume = 0.6 },
	KeySystemOpen = { Volume = 0.8, PlaybackSpeed = 0.9 },
	KeySystemClose = { Volume = 0.8, PlaybackSpeed = 0.7 },
	ThemeChange = { Volume = 0.8 },
}

local sounds = {}
local preloaded = false
local preloadedCount = 0
local totalCount = 0

local soundGroup
local function getSoundGroup()
	if soundGroup and soundGroup.Parent then
		return soundGroup
	end
	local groupName = UUID.Static("AetherisUI")
	soundGroup = SoundService:FindFirstChild(groupName)
	if not soundGroup then
		soundGroup = Instance.new("SoundGroup")
		soundGroup.Name = groupName
		soundGroup.Volume = 1
		soundGroup.Parent = SoundService
	end
	return soundGroup
end

function SoundUtil.SetVolume(volume)
	getSoundGroup().Volume = math.clamp(volume or 1, 0, 1)
end

function SoundUtil.GetVolume()
	return getSoundGroup().Volume
end

local function countAssets()
	local n = 0
	for _ in pairs(SoundUtil.Assets) do
		n += 1
	end
	return n
end

local function applyTuning(name, sound)
	local tuning = SoundUtil.Tuning[name]
	if tuning then
		for prop, value in pairs(tuning) do
			sound[prop] = value
		end
	end
end

local function buildSoundInstances()
	for name, assetId in pairs(SoundUtil.Assets) do
		if not sounds[name] then
			local s = Instance.new("Sound")
			s.Name = UUID.Static(name)
			s.SoundId = assetId
			s.SoundGroup = getSoundGroup()
			s.Parent = SoundService
			applyTuning(name, s)
			sounds[name] = s
		end
	end
end

-- Loads every sound so the first Play has no delay; a second call is a no-op.
function SoundUtil.Preload(progressCallback)
	if preloaded then
		if progressCallback then
			progressCallback(totalCount, totalCount, nil, nil)
		end
		return
	end

	buildSoundInstances()

	totalCount = countAssets()
	preloadedCount = 0

	if totalCount == 0 then
		preloaded = true
		if progressCallback then
			progressCallback(0, 0, nil, nil)
		end
		return
	end

	local assetList = {}
	for _, s in pairs(sounds) do
		table.insert(assetList, s)
	end

	ContentProvider:PreloadAsync(assetList, function(contentId, status)
		preloadedCount += 1
		if progressCallback then
			progressCallback(preloadedCount, totalCount, contentId, status)
		end
	end)

	preloaded = true
end

-- 0-1 progress for callers that poll instead of taking the callback.
function SoundUtil.GetProgress()
	if totalCount == 0 then
		return 1
	end
	return preloadedCount / totalCount
end

function SoundUtil.IsPreloaded()
	return preloaded and preloadedCount >= totalCount
end

-- Plays a named sound, reusing its instance; properties override tuning for one play.
function SoundUtil.Play(name, properties)
	local s = sounds[name]
	if not s then
		local assetId = SoundUtil.Assets[name]
		if not assetId then
			warn("SoundUtil.Play: unknown sound name '" .. tostring(name) .. "'")
			return nil
		end
		s = Instance.new("Sound")
		s.Name = UUID.Static(name)
		s.SoundId = assetId
		s.SoundGroup = getSoundGroup()
		s.Parent = SoundService
		sounds[name] = s
	end

	applyTuning(name, s)
	if properties then
		for prop, value in pairs(properties) do
			s[prop] = value
		end
	end

	-- Stop() first; Play() on a paused sound does not restart it.
	s:Stop()
	s.TimePosition = 0
	s:Play()
	return s
end

function SoundUtil.Stop(name)
	local s = sounds[name]
	if s then
		s:Stop()
	end
end

function SoundUtil.StopAll()
	for _, s in pairs(sounds) do
		s:Stop()
	end
end

function SoundUtil.Release(name)
	local s = sounds[name]
	if s then
		s:Destroy()
		sounds[name] = nil
	end
end

function SoundUtil.ReleaseAll()
	for name in pairs(sounds) do
		SoundUtil.Release(name)
	end
	preloaded = false
	preloadedCount = 0
end

return SoundUtil
