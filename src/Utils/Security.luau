--[[
	Aetheris/Utils/Security.luau

	Optional hardening for AETHERIS_SECUREMODE. Parenting prefers gethui, then
	CoreGui, then PlayerGui, and every call is pcall-guarded.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local UUID = require("./UUID")

local Security = {}

function Security.RandomName(prefix)
	local id = UUID.Generate()
	if prefix then
		return string.format("%s_%s", prefix, id)
	end
	return id
end

function Security.ParentHidden(gui, player)
	-- selene: allow(global_usage)
	local globals = _G
	-- Executors often expose these as bare globals rather than _G entries.
	local function tryContainer(containerFn)
		if type(containerFn) ~= "function" then
			return false
		end
		local ok, container = pcall(containerFn)
		if not ok or typeof(container) ~= "Instance" then
			return false
		end
		return pcall(function()
			gui.Parent = container
		end)
	end
	-- selene: allow(undefined_variable)
	if tryContainer(globals.gethui or gethui) then
		return true
	end
	-- selene: allow(undefined_variable)
	if tryContainer(globals.get_hidden_ui or get_hidden_ui) then
		return true
	end

	if pcall(function()
		gui.Parent = game:GetService("CoreGui")
	end) then
		return true
	end

	if player then
		local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
		if playerGui then
			gui.Parent = playerGui
			return true
		end
	end

	return false
end

function Security.Protect(gui)
	-- selene: allow(global_usage)
	local globals = _G
	local syn = globals.syn
	if syn and type(syn.protect_gui) == "function" then
		pcall(syn.protect_gui, gui)
	end
	-- Bare reads catch executors that only define the hook as a global.
	-- selene: allow(undefined_variable)
	local protect = globals.protect_gui or protect_gui
	if type(protect) == "function" then
		pcall(protect, gui)
	end
	-- selene: allow(undefined_variable)
	local protectGui = globals.protectgui or protectgui
	if type(protectGui) == "function" then
		pcall(protectGui, gui)
	end
end

function Security.Apply(gui, opts)
	opts = opts or {}
	if opts.Parent ~= nil then
		gui.Parent = opts.Parent
	else
		Security.ParentHidden(gui, opts.Player)
	end
	gui.Name = Security.RandomName(opts.Prefix)
	Security.Protect(gui)
	return gui
end

return Security
