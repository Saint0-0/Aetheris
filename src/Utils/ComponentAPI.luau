--[[
	Aetheris/Utils/ComponentAPI.luau

	Adds the shared public surface every component exposes: SetName /
	UpdateName, SetVisible / SetVisibility, GetVisible, and a fallback
	Destroy. Components with custom name side effects pass OnName; components
	with custom teardown keep their own Destroy.
	License: Saint0-0 Source License - use in your own scripts, no editing or
	redistribution without permission. (c) 2026 Saint0-0.
]]

local ComponentAPI = {}

local function resolve(me, value)
	if type(value) == "function" then
		return value(me)
	end
	return value
end

function ComponentAPI.Apply(component, opts)
	opts = opts or {}
	local root = opts.Root
	local label = opts.Label
	local name = opts.Name

	if name ~= nil then
		component._name = name
	end

	local setName = function(me, newName)
		me._name = newName
		if opts.OnName then
			opts.OnName(me, newName)
		elseif label then
			label.Text = newName
		end
	end
	component.SetName = setName
	component.UpdateName = setName

	local setVisible = function(me, visible)
		local target = resolve(me, root)
		if target then
			target.Visible = visible
		end
	end
	component.SetVisible = setVisible
	component.SetVisibility = setVisible
	component.GetVisible = function(me)
		local target = resolve(me, root)
		return target ~= nil and target.Visible or false
	end

	if not component.Destroy then
		component.Destroy = function(me)
			local target = resolve(me, root)
			if target and target.Parent then
				target:Destroy()
			end
		end
	end

	return component
end

return ComponentAPI
