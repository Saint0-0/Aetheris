--[[
	Aetheris/Utils/Sound.luau

	Central audio layer for the UI. One reusable Sound instance per named
	asset (no per-play allocation), all routed through a single 'AetherisUI'
	SoundGroup so one master volume controls the whole UI.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local UUID = require("../Utils/UUID")

local SoundUtil = {}

-- Every sound the UI can play, keyed by name; Preload walks this table.
SoundUtil.Assets = {
	UIStart = "rbxassetid://82845990304289",
	Notification = "rbxassetid://17208361335",
	UIOpen = "rbxassetid://103088360945885",
	UIClose = "rbxassetid://110295449838315",
	UIShutdown = "rbxassetid://110807507368078",
	KeySystemOpen = "rbxassetid://624706518",
	KeySystemClose = "rbxassetid://231731980",
}

-- One reusable Sound per name, built once so repeated plays don't allocate.
local sounds = {}
local preloaded = false
local preloadedCount = 0
local totalCount = 0

-- One SoundGroup so a single master volume controls every UI sound.
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

local function buildSoundInstances()
	for name, assetId in pairs(SoundUtil.Assets) do
		if not sounds[name] then
			local s = Instance.new("Sound")
			s.Name = UUID.Static(name)
			s.SoundId = assetId
			s.SoundGroup = getSoundGroup()
			s.Parent = SoundService
			sounds[name] = s
		end
	end
end

--[[
	Preload(progressCallback)

	Loads every sound via ContentProvider so the first Play() has zero delay.
	progressCallback, if given, receives (loaded, total, name, status) after
	each asset. A second call after a successful preload is a no-op.
]]
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

-- 0-1 progress for a loading bar that would rather poll than take the callback.
function SoundUtil.GetProgress()
	if totalCount == 0 then
		return 1
	end
	return preloadedCount / totalCount
end

function SoundUtil.IsPreloaded()
	return preloaded and preloadedCount >= totalCount
end

--[[
	Play(name, properties)

	Plays a named sound, reusing its preloaded instance. `properties` sets
	one-off overrides (e.g. { Volume = 0.5, PlaybackSpeed = 1.1 }). Re-triggering
	while still playing restarts it rather than layering overlapping copies.
]]
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

	if properties then
		for prop, value in pairs(properties) do
			s[prop] = value
		end
	end

	-- Stop() first: Play() on a paused sound does NOT restart it.
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

-- Destroys the instance so it can be GC'd, not just silenced.
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
