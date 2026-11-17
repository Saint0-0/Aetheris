--[[
	Aetheris/Utils/KeybindDispatcher.luau

	Single shared InputBegan listener for every Keybind row, with one map lookup
	per keystroke. Register returns a token and Unregister drops it.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local UserInputService = game:GetService("UserInputService")

local KeybindDispatcher = {}

local byKey = {} -- [keyName] = { [token] = callback }
local tokenToKey = {} -- reverse lookup for Unregister
local nextToken = 0
local connection = nil

local function ensureConnection()
	if connection then
		return
	end
	connection = UserInputService.InputBegan:Connect(function(input, processed)
		-- Skip input consumed by chat or a focused TextBox.
		if processed then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		local bucket = byKey[input.KeyCode.Name]
		if not bucket then
			return
		end
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
	if not token then
		return
	end
	local keyName = tokenToKey[token]
	if not keyName then
		return
	end
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
