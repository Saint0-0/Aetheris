--[[
	KeybindDispatcher  ·  Aetheris UI Library

	One shared UserInputService.InputBegan listener for every Keybind row.

	Previously each Keybind owned its own InputBegan connection, so N binds
	meant N handlers firing on every keypress, each string-comparing
	input.KeyCode.Name. The dispatcher keeps a KeyCode.Name -> callbacks map
	and does ONE O(1) map lookup per keystroke; the listener count is constant
	no matter how many binds exist.

	Lifecycle: the connection is created lazily on the first Register and kept
	for the session (cheap: one connection, one map lookup per keypress). A
	register/unregister pair is reference-counted per key so emptying a key's
	bucket drops the map entry.

	Public API:
		Register(keyName, callback) -> token   -- token is an opaque handle
		Unregister(token)
]]

local UserInputService = game:GetService("UserInputService")

local KeybindDispatcher = {}

-- [keyName] = { [token] = callback }
local byKey = {}
-- [token] = keyName  (reverse lookup for Unregister)
local tokenToKey = {}
local nextToken = 0
local connection = nil

local function ensureConnection()
	if connection then return end
	connection = UserInputService.InputBegan:Connect(function(input, processed)
		-- Respect game-processed input (chat / a focused TextBox), matching
		-- the old per-row handler's behavior.
		if processed then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local bucket = byKey[input.KeyCode.Name]
		if not bucket then return end
		-- Copy-free iteration is fine here: callbacks must not mutate the
		-- bucket synchronously in a way that would break the loop. If one
		-- does (unregisters itself), pairs() on a table with a single
		-- removed key is still well-defined in Luau.
		for _, cb in pairs(bucket) do
			cb()
		end
	end)
end

function KeybindDispatcher.Register(keyName, callback)
	if not keyName or keyName == "" then
		return nil
	end
	nextToken = nextToken + 1
	local token = nextToken
	local bucket = byKey[keyName]
	if not bucket then
		bucket = {}
		byKey[keyName] = bucket
	end
	bucket[token] = callback
	tokenToKey[token] = keyName
	ensureConnection()
	return token
end

function KeybindDispatcher.Unregister(token)
	if not token then return end
	local keyName = tokenToKey[token]
	if not keyName then return end
	tokenToKey[token] = nil
	local bucket = byKey[keyName]
	if bucket then
		bucket[token] = nil
		if next(bucket) == nil then
			byKey[keyName] = nil
		end
	end
end

return KeybindDispatcher
