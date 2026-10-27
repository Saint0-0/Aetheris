--[[
	Aetheris/Core/KeyServices.luau

	Key validation backends for the optional key system: a static key list or
	function, remote services (Platoboost, Panda), a custom hook, and a stub
	for testing. Also owns the saved-key record that KeySystem.SaveKey writes,
	so a valid key survives re-execution and its check history can be shown in
	the key screen's Information card.

	License: Saint0-0 Source License - use in your own scripts, no editing or
	redistribution without permission. (c) 2026 Saint0-0.
]]

--# selene: allow(undefined_variable)
-- The executor APIs (request, loadstring, writefile, setclipboard, ...) are
-- injected by the host at runtime, not defined in source. They are probed
-- with type() checks throughout; the directive scopes the lint to this file.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local KeyServices = {}

----------------------------------------------------------------
-- SHA-256
----------------------------------------------------------------

-- Platoboost identifiers and nonce integrity hashes are sha256 hex digests.
-- This is a straight FIPS 180-4 implementation over bit32 so we carry no
-- dependency on the minified hash from any service's official library.

local bit32_band, bit32_bnot, bit32_bxor = bit32.band, bit32.bnot, bit32.bxor
local bit32_lshift, bit32_rshift, bit32_rrotate = bit32.lshift, bit32.rshift, bit32.rrotate

local SHA_K = {
	0x428a2f98,
	0x71374491,
	0xb5c0fbcf,
	0xe9b5dba5,
	0x3956c25b,
	0x59f111f1,
	0x923f82a4,
	0xab1c5ed5,
	0xd807aa98,
	0x12835b01,
	0x243185be,
	0x550c7dc3,
	0x72be5d74,
	0x80deb1fe,
	0x9bdc06a7,
	0xc19bf174,
	0xe49b69c1,
	0xefbe4786,
	0x0fc19dc6,
	0x240ca1cc,
	0x2de92c6f,
	0x4a7484aa,
	0x5cb0a9dc,
	0x76f988da,
	0x983e5152,
	0xa831c66d,
	0xb00327c8,
	0xbf597fc7,
	0xc6e00bf3,
	0xd5a79147,
	0x06ca6351,
	0x14292967,
	0x27b70a85,
	0x2e1b2138,
	0x4d2c6dfc,
	0x53380d13,
	0x650a7354,
	0x766a0abb,
	0x81c2c92e,
	0x92722c85,
	0xa2bfe8a1,
	0xa81a664b,
	0xc24b8b70,
	0xc76c51a3,
	0xd192e819,
	0xd6990624,
	0xf40e3585,
	0x106aa070,
	0x19a4c116,
	0x1e376c08,
	0x2748774c,
	0x34b0bcb5,
	0x391c0cb3,
	0x4ed8aa4a,
	0x5b9cca4f,
	0x682e6ff3,
	0x748f82ee,
	0x78a5636f,
	0x84c87814,
	0x8cc70208,
	0x90befffa,
	0xa4506ceb,
	0xbef9a3f7,
	0xc67178f2,
}

local function sha256(message)
	local bytes = table.create(#message + 72)
	for index = 1, #message do
		bytes[index] = string.byte(message, index)
	end

	-- padding: 0x80, zeros, then the 64-bit big-endian bit length
	local bitLength = #message * 8
	table.insert(bytes, 0x80)
	while #bytes % 64 ~= 56 do
		table.insert(bytes, 0)
	end
	local highWord = math.floor(bitLength / 0x100000000)
	local lowWord = bitLength % 0x100000000
	for _, word in ipairs({ highWord, lowWord }) do
		for shift = 24, 0, -8 do
			table.insert(bytes, bit32_band(bit32_rshift(word, shift), 0xFF))
		end
	end

	local h0, h1, h2, h3 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
	local h4, h5, h6, h7 = 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

	local w = table.create(64)
	for chunk = 1, #bytes, 64 do
		for i = 0, 15 do
			local j = chunk + i * 4
			w[i] = bit32_lshift(bytes[j], 24)
				+ bit32_lshift(bytes[j + 1], 16)
				+ bit32_lshift(bytes[j + 2], 8)
				+ bytes[j + 3]
		end
		for i = 16, 63 do
			local w15, w2 = w[i - 15], w[i - 2]
			local s0 = bit32_bxor(bit32_rrotate(w15, 7), bit32_rrotate(w15, 18), bit32_rshift(w15, 3))
			local s1 = bit32_bxor(bit32_rrotate(w2, 17), bit32_rrotate(w2, 19), bit32_rshift(w2, 10))
			w[i] = (w[i - 16] + s0 + w[i - 7] + s1) % 0x100000000
		end

		local a, b, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7
		for i = 0, 63 do
			local bigS1 = bit32_bxor(bit32_rrotate(e, 6), bit32_rrotate(e, 11), bit32_rrotate(e, 25))
			local ch = bit32_bxor(bit32_band(e, f), bit32_band(bit32_bnot(e), g))
			local temp1 = (h + bigS1 + ch + SHA_K[i + 1] + w[i]) % 0x100000000
			local bigS0 = bit32_bxor(bit32_rrotate(a, 2), bit32_rrotate(a, 13), bit32_rrotate(a, 22))
			local maj = bit32_bxor(bit32_band(a, b), bit32_band(a, c), bit32_band(b, c))
			local temp2 = (bigS0 + maj) % 0x100000000
			h = g
			g = f
			f = e
			e = (d + temp1) % 0x100000000
			d = c
			c = b
			b = a
			a = (temp1 + temp2) % 0x100000000
		end

		h0 = (h0 + a) % 0x100000000
		h1 = (h1 + b) % 0x100000000
		h2 = (h2 + c) % 0x100000000
		h3 = (h3 + d) % 0x100000000
		h4 = (h4 + e) % 0x100000000
		h5 = (h5 + f) % 0x100000000
		h6 = (h6 + g) % 0x100000000
		h7 = (h7 + h) % 0x100000000
	end

	return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4, h5, h6, h7)
end

KeyServices.Sha256 = sha256

----------------------------------------------------------------
-- Executor helpers
----------------------------------------------------------------

local function getRequestFunction()
	local fn = request or http_request
	if fn == nil and type(syn) == "table" then
		fn = syn.request
	end
	if fn == nil and type(http) == "table" then
		fn = http.request
	end
	if type(fn) == "function" then
		return fn
	end
	return nil
end

local function getHwid()
	if type(gethwid) == "function" then
		local ok, hwid = pcall(gethwid)
		if ok and hwid ~= nil and tostring(hwid) ~= "" then
			return tostring(hwid)
		end
	end
	local player = Players.LocalPlayer
	return tostring(player and player.UserId or 0)
end

local function trimKey(key)
	return tostring(key or ""):match("^%s*(.-)%s*$") or ""
end

local function decodeJson(body)
	local ok, result = pcall(HttpService.JSONDecode, HttpService, body)
	if ok and type(result) == "table" then
		return result
	end
	return nil
end

----------------------------------------------------------------
-- Platoboost
----------------------------------------------------------------

local Platoboost = {}
Platoboost.__index = Platoboost

local PB_HOSTS = { "https://api.platoboost.app", "https://api.platoboost.com", "https://api.platoboost.net" }
local PB_JSON_HEADERS = { ["Content-Type"] = "application/json" }
local PB_RATE_LIMIT = "you are being rate limited, please wait a moment and try again."
local PB_BAD_STATUS = "the key server returned a bad response, please try again later."
local PB_LINK_CACHE_TIME = 600

local function generateNonce()
	local chars = table.create(16)
	for i = 1, 16 do
		chars[i] = string.char(math.random(97, 122))
	end
	return table.concat(chars)
end

function Platoboost.new(config)
	local self = setmetatable({}, Platoboost)
	local service = config.ServiceId or config.Service or config.service
	self.service = tonumber(service) or service
	self.secret = config.Secret or config.secret
	self.useNonce = config.UseNonce ~= false
	self.host = nil
	self.identifier = nil
	self.linkCache = nil
	self.linkCacheTime = 0
	self.busy = false
	return self
end

-- Probe the mirrors once and remember the first that answers.
function Platoboost:_host()
	if self.host then
		return self.host
	end
	local req = getRequestFunction()
	if req then
		for _, host in ipairs(PB_HOSTS) do
			local ok, res = pcall(req, { Url = host .. "/public/connectivity", Method = "GET" })
			if ok and type(res) == "table" and (res.StatusCode == 200 or res.StatusCode == 429) then
				self.host = host
				return self.host
			end
		end
	end
	self.host = PB_HOSTS[1]
	return self.host
end

function Platoboost:_identifier()
	if not self.identifier then
		self.identifier = sha256(getHwid())
	end
	return self.identifier
end

function Platoboost:_send(options)
	local req = getRequestFunction()
	if not req then
		return nil, "your executor doesn't support HTTP requests."
	end
	local ok, res = pcall(req, options)
	if not ok then
		return nil, tostring(res)
	end
	if type(res) ~= "table" then
		return nil, "invalid response from server."
	end
	return res
end

-- With a nonce the server signs its answer with the secret; check the stamp.
function Platoboost:_integrityOk(data, nonce)
	if not self.useNonce then
		return true
	end
	return data.hash == sha256("true" .. "-" .. nonce .. "-" .. tostring(self.secret))
end

function Platoboost:_verify(key)
	local nonce = generateNonce()
	local url = self:_host()
		.. "/public/whitelist/"
		.. tostring(self.service)
		.. "?identifier="
		.. self:_identifier()
		.. "&key="
		.. HttpService:UrlEncode(key)
	if self.useNonce then
		url = url .. "&nonce=" .. nonce
	end

	local res, err = self:_send({ Url = url, Method = "GET" })
	if not res then
		return false, err
	end
	if res.StatusCode == 429 then
		return false, PB_RATE_LIMIT
	end
	if res.StatusCode ~= 200 then
		return false, PB_BAD_STATUS
	end

	local decoded = decodeJson(res.Body)
	if not decoded then
		return false, "invalid response from server."
	end
	if decoded.success ~= true then
		return false, tostring(decoded.message or "request failed.")
	end

	local data = type(decoded.data) == "table" and decoded.data or {}
	if data.valid == true then
		if not self:_integrityOk(data, nonce) then
			return false, "failed to verify integrity."
		end
		return true
	end

	-- Keys minted on the Platoboost site start with KEY_ and must be redeemed first
	if key:sub(1, 4) == "KEY_" then
		return self:_redeem(key)
	end
	return false, "key is invalid."
end

function Platoboost:_redeem(key)
	local nonce = generateNonce()
	local body = { identifier = self:_identifier(), key = key }
	if self.useNonce then
		body.nonce = nonce
	end

	local res, err = self:_send({
		Url = self:_host() .. "/public/redeem/" .. tostring(self.service),
		Method = "POST",
		Body = HttpService:JSONEncode(body),
		Headers = PB_JSON_HEADERS,
	})
	if not res then
		return false, err
	end
	if res.StatusCode == 429 then
		return false, PB_RATE_LIMIT
	end
	if res.StatusCode ~= 200 then
		return false, PB_BAD_STATUS
	end

	local decoded = decodeJson(res.Body)
	if not decoded then
		return false, "invalid response from server."
	end
	if decoded.success ~= true then
		local message = tostring(decoded.message or "request failed.")
		if message:sub(1, 27) == "unique constraint violation" then
			return false, "you already have an active key, please wait for it to expire."
		end
		return false, message
	end

	local data = type(decoded.data) == "table" and decoded.data or {}
	if data.valid ~= true then
		return false, "key is invalid."
	end
	if not self:_integrityOk(data, nonce) then
		return false, "failed to verify integrity."
	end
	return true
end

function Platoboost:Init(report)
	self:_host()
	if report then
		report(1)
	end
	return true
end

function Platoboost:CheckKey(key)
	key = trimKey(key)
	if key == "" then
		return false, "key is empty."
	end
	if self.service == nil or self.service == "" then
		return false, "Platoboost ServiceId is missing."
	end
	if self.useNonce and (type(self.secret) ~= "string" or self.secret == "") then
		return false, "Platoboost Secret is missing."
	end
	if self.busy then
		return false, "a request is already being sent, please slow down."
	end

	self.busy = true
	local ok, valid, reason = pcall(self._verify, self, key)
	self.busy = false

	if not ok then
		return false, tostring(valid)
	end
	return valid == true, reason
end

function Platoboost:GetKeyLink()
	if self.linkCache and self.linkCacheTime + PB_LINK_CACHE_TIME > os.time() then
		return self.linkCache
	end
	if self.service == nil or self.service == "" then
		return nil, "Platoboost ServiceId is missing."
	end

	local res, err = self:_send({
		Url = self:_host() .. "/public/start",
		Method = "POST",
		Body = HttpService:JSONEncode({ service = self.service, identifier = self:_identifier() }),
		Headers = PB_JSON_HEADERS,
	})
	if not res then
		return nil, err
	end
	if res.StatusCode == 429 then
		return nil, PB_RATE_LIMIT
	end
	if res.StatusCode == 200 then
		local decoded = decodeJson(res.Body)
		if decoded then
			if decoded.success == true and type(decoded.data) == "table" and decoded.data.url then
				self.linkCache = decoded.data.url
				self.linkCacheTime = os.time()
				return self.linkCache
			end
			return nil, tostring(decoded.message or "couldn't get the key link.")
		end
	end
	return nil, "couldn't get the key link."
end

----------------------------------------------------------------
-- Panda
----------------------------------------------------------------

local Panda = {}
Panda.__index = Panda

local PANDA_LIB_URL = "https://secure.pandauth.com/pv4/lib"

function Panda.new(config)
	local self = setmetatable({}, Panda)
	local serviceId = config.ServiceId or config.Service or config.serviceId
	self.serviceId = serviceId ~= nil and tostring(serviceId) or ""
	self.lib = nil
	return self
end

function Panda:_load()
	if self.lib then
		return self.lib
	end
	if self.serviceId == "" then
		return nil, "Panda ServiceId is missing."
	end
	if type(loadstring) ~= "function" then
		return nil, "loadstring is not available on this executor."
	end

	-- selene: allow(incorrect_standard_library_use)
	-- HttpGet is a real DataModel method; older selene stds don't list it.
	local okFetch, src = pcall(function()
		return game:HttpGet(PANDA_LIB_URL)
	end)
	if not okFetch or type(src) ~= "string" or src == "" then
		return nil, "couldn't download the Panda library."
	end

	local fn, compileError = loadstring(src)
	if not fn then
		return nil, "couldn't load the Panda library: " .. tostring(compileError)
	end
	local okRun, result = pcall(fn)
	if not (okRun and type(result) == "table" and type(result.configure) == "function") then
		return nil, "Panda library failed to initialize."
	end
	local okConfig = pcall(result.configure, { serviceId = self.serviceId, kickOnDetect = false })
	if not okConfig then
		return nil, "couldn't configure the Panda library."
	end

	self.lib = result
	return self.lib
end

function Panda:Init(report)
	local lib = self:_load()
	if report then
		report(1)
	end
	return lib ~= nil
end

function Panda:CheckKey(key)
	key = trimKey(key)
	if key == "" then
		return false, "key is empty."
	end
	local lib, err = self:_load()
	if not lib then
		return false, err
	end

	if type(lib.validateEx) == "function" then
		local ok, valid, reason = pcall(lib.validateEx, key)
		if not ok then
			return false, tostring(valid)
		end
		if valid == true then
			return true
		end
		return false, tostring(reason or "key is invalid or expired.")
	end

	local ok, result = pcall(lib.validate, key)
	if not ok then
		return false, tostring(result)
	end
	if type(result) == "table" and result.success == true then
		return true
	end
	local reason = type(result) == "table" and (result.reason or result.error) or nil
	return false, tostring(reason or "key is invalid.")
end

function Panda:GetKeyLink()
	local lib, err = self:_load()
	if not lib then
		return nil, err
	end
	if type(lib.getKeyUrl) ~= "function" then
		return nil, "Panda has no getKeyUrl."
	end
	local ok, url = pcall(lib.getKeyUrl)
	if ok and type(url) == "string" and url ~= "" then
		return url
	end
	return nil, "couldn't get the key link."
end

----------------------------------------------------------------
-- Custom
----------------------------------------------------------------

-- { Type = "custom", Validate = function(key) -> valid, reason,
--                     GetLink = function() -> url } -- both optional hooks
local Custom = {}
Custom.__index = Custom

function Custom.new(config)
	return setmetatable({ config = config or {} }, Custom)
end

function Custom:Init(report)
	if report then
		report(1)
	end
	return true
end

function Custom:CheckKey(key)
	local check = self.config.Validate
	if type(check) ~= "function" then
		return false, "custom key service has no Validate function."
	end
	local ok, valid, reason = pcall(check, trimKey(key))
	if not ok then
		return false, tostring(valid)
	end
	return valid == true, reason
end

function Custom:GetKeyLink()
	local getLink = self.config.GetLink
	if type(getLink) ~= "function" then
		return nil, "custom key service has no GetLink function."
	end
	local ok, url = pcall(getLink)
	if ok and type(url) == "string" and url ~= "" then
		return url
	end
	return nil, "couldn't get the key link."
end

----------------------------------------------------------------
-- Stub (testing)
----------------------------------------------------------------

-- { Type = "stub", Keys = { "TEST" }, Link = "https://..." }
-- Accepts a key from the list (or any non-empty key when Keys is omitted).
local Stub = {}
Stub.__index = Stub

function Stub.new(config)
	return setmetatable({ config = config or {} }, Stub)
end

function Stub:Init(report)
	if report then
		report(1)
	end
	return true
end

function Stub:CheckKey(key)
	key = trimKey(key)
	if key == "" then
		return false, "key is empty."
	end
	local list = self.config.Keys
	if type(list) ~= "table" then
		return true
	end
	for _, candidate in ipairs(list) do
		if tostring(candidate) == key then
			return true
		end
	end
	return false, "key is invalid."
end

function Stub:GetKeyLink()
	if type(self.config.Link) == "string" and self.config.Link ~= "" then
		return self.config.Link
	end
	return nil, "the stub service has no link."
end

----------------------------------------------------------------
-- Validator (combines static keys + services)
----------------------------------------------------------------

local BUILDERS = {
	platoboost = Platoboost.new,
	panda = Panda.new,
	custom = Custom.new,
	stub = Stub.new,
}

function KeyServices.Create(config)
	config = config or {}
	local services = {}
	for _, entry in ipairs(config.API or {}) do
		if type(entry) == "table" then
			local builder = BUILDERS[string.lower(tostring(entry.Type or ""))]
			if builder then
				table.insert(services, builder(entry))
			else
				warn("[Aetheris] unknown KeySystem.API type: " .. tostring(entry.Type))
			end
		end
	end

	local staticKey = config.Key
	local validator = { Services = services, Config = config }

	-- nil = nothing configured here, true/false = checked and the answer stands
	local function checkStatic(key)
		if staticKey == nil then
			return nil
		end
		if type(staticKey) == "function" then
			local ok, valid, reason = pcall(staticKey, key)
			if not ok then
				return false, tostring(valid)
			end
			return valid == true, reason
		end
		if type(staticKey) == "table" then
			for _, candidate in ipairs(staticKey) do
				if tostring(candidate) == key then
					return true
				end
			end
			return false, "key is invalid."
		end
		if tostring(staticKey) == key then
			return true
		end
		return false, "key is invalid."
	end

	function validator:HasAny()
		return staticKey ~= nil or #services > 0
	end

	function validator:Init(progress)
		local total = #services
		if total == 0 then
			if progress then
				progress(1)
			end
			return true
		end
		for index, service in ipairs(services) do
			if type(service.Init) == "function" then
				pcall(service.Init, service, function()
					if progress then
						progress(index / total)
					end
				end)
			elseif progress then
				progress(index / total)
			end
		end
		return true
	end

	function validator:CheckKey(key)
		key = trimKey(key)
		if key == "" then
			return false, "key is empty."
		end

		local staticResult, staticReason = checkStatic(key)
		if staticResult == true then
			return true
		end

		local lastReason = staticReason
		for _, service in ipairs(services) do
			local ok, valid, reason = pcall(service.CheckKey, service, key)
			if ok and valid == true then
				return true
			end
			lastReason = (ok and reason) or tostring(valid)
		end
		return false, lastReason or "key is invalid."
	end

	function validator:GetKeyLink()
		for _, service in ipairs(services) do
			if type(service.GetKeyLink) == "function" then
				local ok, url = pcall(service.GetKeyLink, service)
				if ok and type(url) == "string" and url ~= "" then
					return url
				end
			end
		end
		if type(config.URL) == "string" and config.URL ~= "" then
			return config.URL
		end
		return nil, "no key link is configured."
	end

	return validator
end

----------------------------------------------------------------
-- Saved-key record (SaveKey + Information card stats)
----------------------------------------------------------------

local KEYS_FOLDER = "Aetheris/Keys"

local function recordPath()
	return KEYS_FOLDER .. "/" .. tostring(game.PlaceId) .. ".json"
end

local function ensureKeyFolders()
	if type(makefolder) ~= "function" then
		return
	end
	pcall(makefolder, "Aetheris")
	pcall(makefolder, KEYS_FOLDER)
end

function KeyServices.LoadRecord()
	if type(readfile) ~= "function" then
		return nil
	end
	local ok, content = pcall(function()
		if type(isfile) == "function" and not isfile(recordPath()) then
			return nil
		end
		return readfile(recordPath())
	end)
	if not (ok and type(content) == "string" and content ~= "") then
		return nil
	end
	local decoded = decodeJson(content)
	if decoded and type(decoded) == "table" then
		return decoded
	end
	return nil
end

function KeyServices.SaveRecord(record)
	if type(writefile) ~= "function" then
		return
	end
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, record)
	if ok and encoded then
		pcall(ensureKeyFolders)
		pcall(writefile, recordPath(), encoded)
	end
end

function KeyServices.ClearRecord()
	if type(delfile) == "function" then
		pcall(delfile, recordPath())
	end
end

function KeyServices.CopyToClipboard(text)
	if type(setclipboard) == "function" then
		return pcall(setclipboard, text)
	end
	return false
end

function KeyServices.FetchDiscordStats(guildId)
	local req = getRequestFunction()
	if not req or guildId == nil or guildId == "" then
		return nil
	end
	local ok, res = pcall(req, {
		Url = "https://discord.com/api/guilds/" .. tostring(guildId) .. "/widget.json",
		Method = "GET",
	})
	if not (ok and type(res) == "table" and res.StatusCode == 200) then
		return nil
	end
	local data = decodeJson(res.Body)
	if not data then
		return nil
	end
	return {
		Online = tonumber(data.approximate_presence_count),
		Members = tonumber(data.approximate_member_count),
		Icon = type(data.icon) == "string"
				and ("https://cdn.discordapp.com/icons/" .. tostring(guildId) .. "/" .. data.icon .. ".png")
			or nil,
	}
end

return KeyServices
