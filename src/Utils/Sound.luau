--[[
	Sound  ·  Aetheris UI Library

	Central audio layer for the UI. One reusable Sound instance per named
	asset (no per-play allocation), all routed through a single 'AetherisUI'
	SoundGroup so one master volume controls the whole UI.

	Public API: Assets, Preload, GetProgress, IsPreloaded, Play, Stop,
	StopAll, SetVolume, GetVolume, Release, ReleaseAll.
]]

local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local SoundUtil = {}

-- Every sound the UI can play, keyed by name. Fill in real rbxassetid://s as
-- you add sounds -- Preload() walks this table, so adding a new sound here
-- is the only step needed to have it preloaded automatically.
SoundUtil.Assets = {
	UIStart      = "rbxassetid://82845990304289",
	Notification = "rbxassetid://17208361335",
	UIOpen       = "rbxassetid://103088360945885",
	UIClose      = "rbxassetid://110295449838315",
	UIShutdown   = "rbxassetid://110807507368078",
}

-- Reusable Sound instances, one per named asset, built once so repeated
-- plays don't allocate a new Instance every time (which is where the
-- "delayed sound" feeling usually comes from -- not just missing content,
-- but paying Instance.new + parenting cost on every single play call).
local sounds = {}
local preloaded = false
local preloadedCount = 0
local totalCount = 0

-- All UI sounds route through one SoundGroup so a single master volume
-- controls them. Created lazily and reused.
local soundGroup
local function getSoundGroup()
	if soundGroup and soundGroup.Parent then
		return soundGroup
	end
	soundGroup = SoundService:FindFirstChild("AetherisUI")
	if not soundGroup then
		soundGroup = Instance.new("SoundGroup")
		soundGroup.Name = "AetherisUI"
		soundGroup.Volume = 1
		soundGroup.Parent = SoundService
	end
	return soundGroup
end

-- Master UI volume, 0-1 (drives the shared SoundGroup).
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
			s.Name = name
			s.SoundId = assetId
			s.SoundGroup = getSoundGroup()
			s.Parent = SoundService
			sounds[name] = s
		end
	end
end

--[[
	Preload(progressCallback)

	Loads every sound in SoundUtil.Assets via ContentProvider:PreloadAsync so
	the first real Play() call has zero delay. progressCallback, if given, is
	called as (loadedCount, totalCount, name, status) after each asset
	finishes loading -- wire this straight into a loading bar's progress.

	Safe to call once at startup before showing the UI. Calling it again
	after the first successful preload is a no-op.
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

-- Returns 0-1 progress. Useful for a loading bar to poll if you'd rather
-- not thread everything through the Preload callback.
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

	Plays a named sound from SoundUtil.Assets. properties (optional) is a
	table of Sound properties to set before playing -- e.g. { Volume = 0.5,
	PlaybackSpeed = 1.1 } -- for one-off variation without permanently
	mutating the shared instance's defaults beyond this call.

	Reuses the single preloaded Sound instance per name rather than creating
	a new one each call. If the same sound is triggered again while still
	playing (e.g. rapid hover events), it restarts from the beginning rather
	than layering overlapping copies -- keeps memory flat regardless of how
	fast the UI fires sound triggers.
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
		s.Name = name
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

	-- Stop() first: a Sound can be left IsPaused=true (e.g. by a prior play /
	-- Stop-Play cycle), and Play() on a paused sound does NOT restart it. Stop
	-- clears the paused state so Play always (re)starts from the beginning.
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

-- Fully releases a sound's Instance so it can be GC'd -- use for sounds you
-- know won't be needed again for a while (e.g. a one-time intro chime) when
-- you want the memory back rather than just silence.
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
