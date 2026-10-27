--[[
	Aetheris/Utils/UUID.luau

	Names interface elements. Secure mode hashes fixed keys to deterministic
	UUIDs and randomizes per-instance ones; normal mode keeps readable names
	so Explorer stays usable.
	License: Saint0-0 Source License - use in your own scripts, no editing or
	redistribution without permission. (c) 2026 Saint0-0.
]]

local UUID = {}
local staticCache = {}
local dynamicCounters = {}
local secureMode = false

local function hash(text, seed)
	local value = seed
	for index = 1, #text do
		value = bit32.bxor(value, string.byte(text, index))
		value = bit32.band(bit32.lshift(value, 5) + value + seed, 0xFFFFFFFF)
	end
	return value
end

local function format(a, b, c, d)
	return string.format(
		"%08x-%04x-4%03x-%04x-%08x%04x",
		a,
		bit32.band(bit32.rshift(b, 16), 0xFFFF),
		bit32.band(c, 0x0FFF),
		bit32.bor(0x8000, bit32.band(bit32.rshift(d, 16), 0x3FFF)),
		d,
		bit32.band(a, 0xFFFF)
	)
end

function UUID.SetSecureMode(enabled)
	secureMode = enabled == true
end

function UUID.IsSecureMode()
	return secureMode
end

function UUID.Static(key)
	if not secureMode then
		return key
	end
	local cached = staticCache[key]
	if cached then
		return cached
	end
	local id = format(hash(key, 0x811C9DC5), hash(key, 0x9E3779B9), hash(key, 0x85EBCA6B), hash(key, 0xC2B2AE35))
	staticCache[key] = id
	return id
end

function UUID.Generate(prefix)
	if not secureMode then
		local label = prefix or "Element"
		local count = (dynamicCounters[label] or 0) + 1
		dynamicCounters[label] = count
		return string.format("%s_%d", label, count)
	end
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	return (
		template:gsub("[xy]", function(character)
			local value = math.random(0, 15)
			if character == "x" then
				return string.format("%x", value)
			end
			return string.format("%x", bit32.bor(8, bit32.band(value, 3)))
		end)
	)
end

return UUID
