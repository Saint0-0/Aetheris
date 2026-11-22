--[[
	Aetheris/Utils/ComponentAPI.luau

	Shared public surface for every component: SetName, SetVisible, GetVisible
	and a fallback Destroy. Methods carries component-unique API so each file
	declares its surface once.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ComponentAPI = {}
local Locale = require("./Locale")
local UUID = require("./UUID")

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
	-- Names stay raw so a locale change can re-resolve them.
	local name = opts.Name
	local children = opts.Children

	if name ~= nil then
		component._name = name
	end

	-- SearchFilter treats every component root as an individual result.
	local resolvedRoot = resolve(component, root)
	if typeof(resolvedRoot) == "Instance" then
		resolvedRoot:SetAttribute(UUID.Static("IsComponentContainer"), true)
	end

	local setName = function(me, newName)
		me._name = newName
		if opts.OnName then
			opts.OnName(me, newName)
		elseif label then
			Locale.set(label, "Text", newName)
		end
	end
	component.SetName = setName

	-- Re-assert the name for components without a custom OnName handler.
	if label and not opts.OnName and name ~= nil then
		Locale.set(label, "Text", name)
	end

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

	-- Merged last so a component can override a shared method.
	local methods = opts.Methods
	if methods then
		for key, fn in pairs(methods) do
			component[key] = fn
		end
	end

	return component
end

return ComponentAPI
