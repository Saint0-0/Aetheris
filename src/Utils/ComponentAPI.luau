--[[
	Aetheris/Utils/ComponentAPI.luau

	Adds the shared public surface every component exposes: SetName /
	UpdateName, SetVisible / SetVisibility, GetVisible, and a fallback
	Destroy. Opts: Root (instance or fn), Label, Name, OnName, Children (fn
	returning child components for fan-out visibility); custom teardown and
	name side effects stay with the component.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
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
	local children = opts.Children

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
		if children then
			for _, child in ipairs(resolve(me, children) or {}) do
				if child.SetVisible then
					child:SetVisible(visible)
				end
			end
			return
		end
		local target = resolve(me, root)
		if target then
			target.Visible = visible
		end
	end
	component.SetVisible = setVisible
	component.SetVisibility = setVisible
	component.GetVisible = function(me)
		if children then
			local first = (resolve(me, children) or {})[1]
			return first ~= nil and first:GetVisible() or false
		end
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
