--[[
	Security  ·  Aetheris UI Library

	Optional hardening for AETHERIS_SECUREMODE. Parenting prefers gethui,
	then CoreGui, then PlayerGui; protection hooks are called when the
	executor exposes them. All calls are pcall-guarded so the UI still loads
	in a plain Studio session.
]]

local Security = {}

local function randomHex()
	return string.format("%08x%08x", math.random(0, 0x7FFFFFFF), math.random(0, 0x7FFFFFFF))
end

function Security.RandomName(prefix)
	return string.format("%s_%s", prefix or "Aetheris", randomHex())
end

function Security.ParentHidden(gui, player)
	-- selene: allow(global_usage)
	local globals = _G
	local gethui = globals.gethui
	if type(gethui) == "function" then
		local ok, container = pcall(gethui)
		if ok and typeof(container) == "Instance" and pcall(function()
			gui.Parent = container
		end) then
			return true
		end
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
	local protect = globals.protect_gui
	if type(protect) == "function" then
		pcall(protect, gui)
	end
	local protectGui = globals.protectgui
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
