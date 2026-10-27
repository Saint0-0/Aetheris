--[[
	Aetheris/Core/Settings/Configs.luau

	Settings page for the per-game config system: save the current component
	values under a name, load or delete them from a dropdown, toggle
	auto-save, and preview the selected config's JSON in a CodeView.
	License: Saint0-0 Source License - use in your own scripts, no editing or
	redistribution without permission. (c) 2026 Saint0-0.
]]

local Configs = {}

function Configs.Build(window, tab)
	tab:Scroller()

	local manager = window.ConfigManager
	if not manager or not manager.Available then
		local notice = tab:Section({ Name = "Configs" })
		notice:Label({
			Text = "Config files need an executor file API (writefile/readfile). They are unavailable in Studio or a plain game.",
		})
		return
	end

	local selectedName = nil
	local refreshAll -- forward declared: Save also refreshes the list
	local refreshPreview -- forward declared: the dropdown callback previews

	local saveSection = tab:Section({ Name = "Save" })
	local nameInput = saveSection:TextInput({
		Name = "Config Name",
		Placeholder = "My loadout",
		NoSave = true,
	})
	saveSection:Button({
		Name = "Save Config",
		NoSave = true,
		Callback = function()
			local name = nameInput:GetText()
			local ok, err = manager:Save(name)
			if ok then
				window:Toast({ Title = "Config saved", Description = name, Duration = 3 })
				refreshAll()
			else
				window:Error({ Title = "Save failed", Description = err or "Unknown error", Duration = 4 })
			end
		end,
	})

	local loadSection = tab:Section({ Name = "Load" })
	local configDropdown = loadSection:Dropdown({
		Name = "Config",
		Items = {},
		MaxItemsChoosable = 1,
		Placeholder = "No configs yet",
		NoSave = true,
		Callback = function(selected)
			local pick = selected[1]
			refreshPreview(pick and pick.value or nil)
		end,
	})
	loadSection:Button({
		Name = "Load Config",
		NoSave = true,
		Callback = function()
			if not selectedName then
				window:Error({ Title = "No config selected", Description = "Save a config first.", Duration = 4 })
				return
			end
			local ok, err = manager:Load(selectedName)
			if ok then
				window:Toast({ Title = "Config loaded", Description = selectedName, Duration = 3 })
			else
				window:Error({ Title = "Load failed", Description = err or "Unknown error", Duration = 4 })
			end
		end,
	})
	loadSection:Button({
		Name = "Delete Config",
		NoSave = true,
		Callback = function()
			if not selectedName then
				window:Error({ Title = "No config selected", Description = "Save a config first.", Duration = 4 })
				return
			end
			local name = selectedName
			local ok, err = manager:Delete(name)
			if ok then
				window:Toast({ Title = "Config deleted", Description = name, Duration = 3 })
				selectedName = nil
				refreshAll()
			else
				window:Error({ Title = "Delete failed", Description = err or "Unknown error", Duration = 4 })
			end
		end,
	})

	local optionsSection = tab:Section({ Name = "Options" })
	optionsSection:Toggle({
		Name = "Auto-Save",
		NoSave = true,
		Default = manager:GetAutoSave(),
		Callback = function(state)
			manager:SetAutoSave(state)
		end,
	})

	local previewSection = tab:Section({ Name = "Preview" })
	local preview = previewSection:CodeView({
		Name = "Config Preview",
		Language = "json",
		Height = 260,
		Text = "{}",
		NoSave = true,
	})

	refreshPreview = function(name)
		selectedName = name
		if not name then
			preview:SetText("{}")
			return
		end
		local content = manager:Preview(name)
		preview:SetText(content or "{}")
	end

	refreshAll = function()
		local names = manager:List()
		local items = {}
		for _, configName in ipairs(names) do
			table.insert(items, { name = configName, value = configName })
		end
		configDropdown:SetValues(items, false)
		-- keep the selection if it still exists, else fall back to the first
		if selectedName and table.find(names, selectedName) then
			configDropdown:SetValue(selectedName, true)
		else
			selectedName = names[1]
			if selectedName then
				configDropdown:SetValue(selectedName, true)
			end
		end
		refreshPreview(selectedName)
	end

	-- deferred so it runs after Window.new's current thread
	task.defer(refreshAll)
end

return Configs
