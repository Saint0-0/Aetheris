--[[
	Aetheris/Core/Settings/Configs.luau

	Settings page for the per-game config system: save, load, delete, and edit
	config JSON in place, including pasting a config from the clipboard.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

--# selene: allow(undefined_variable)
-- getclipboard is an executor global, injected at runtime.

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
	local refreshAll
	local refreshList
	local refreshEditor

	local activeSection = tab:Section({ Name = "Active Config" })
	-- Bare label: which config the live UI currently reflects.
	local activeLabel = activeSection:Label({
		Text = "No config loaded",
		ShowContainer = false,
		NoSave = true,
	})
	activeSection:Toggle({
		Name = "Auto-Save",
		NoSave = true,
		Default = manager:GetAutoSave(),
		Callback = function(state)
			manager:SetAutoSave(state)
		end,
	})
	local nameInput = activeSection:TextInput({
		Name = "Config Name",
		Placeholder = "Name (blank uses the loaded config)",
		NoSave = true,
	})
	activeSection:Button({
		Name = "Save Current Settings",
		NoSave = true,
		Callback = function()
			local name = nameInput:GetText()
			if name == "" then
				name = manager.Active
			end
			if not name or name == "" then
				window:Error({
					Title = "Name required",
					Description = "Type a name or load a config first.",
					Duration = 4,
				})
				return
			end
			local ok, info = manager:Save(name)
			if ok then
				window:Toast({ Title = "Config saved", Description = info, Duration = 3 })
				selectedName = info
				refreshAll()
			else
				window:Error({ Title = "Save failed", Description = info or "Unknown error", Duration = 4 })
			end
		end,
	})

	local librarySection = tab:Section({ Name = "Config Library" })
	local configDropdown = librarySection:Dropdown({
		Name = "Config Files",
		Items = {},
		MaxItemsChoosable = 1,
		Placeholder = "No configs yet",
		NoSave = true,
		Callback = function(selected)
			local pick = selected[1]
			refreshEditor(pick and pick.value or nil)
		end,
	})
	librarySection:Button({
		Name = "Load Selected",
		NoSave = true,
		Callback = function()
			if not selectedName then
				window:Error({ Title = "No config selected", Description = "Pick a config first.", Duration = 4 })
				return
			end
			local ok, err = manager:Load(selectedName)
			if ok then
				window:Toast({ Title = "Config loaded", Description = selectedName, Duration = 3 })
				refreshAll()
			else
				window:Error({ Title = "Load failed", Description = err or "Unknown error", Duration = 4 })
			end
		end,
	})
	librarySection:Button({
		Name = "Delete Selected",
		NoSave = true,
		Callback = function()
			if not selectedName then
				window:Error({ Title = "No config selected", Description = "Pick a config first.", Duration = 4 })
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
	librarySection:Button({
		Name = "Refresh List",
		NoSave = true,
		Callback = function()
			refreshAll()
		end,
	})

	local editorSection = tab:Section({ Name = "JSON Editor" })
	editorSection:Label({
		Text = "Click the code to edit, or paste a config from the clipboard. Apply it to the UI, or save it as a file.",
		ShowContainer = false,
		ShowStroke = false,
		TextSize = 12,
		Padding = { Top = 0, Bottom = 2, Left = 0, Right = 0 },
	})
	local editor = editorSection:CodeView({
		Name = "Config JSON",
		Language = "json",
		Height = 300,
		Text = "{}",
		Editable = true,
		NoSave = true,
	})
	editorSection:Button({
		Name = "Apply Editor to UI",
		NoSave = true,
		Callback = function()
			local ok, err = manager:Apply(editor:GetContent())
			if ok then
				window:Toast({ Title = "Config applied", Description = "The UI now matches the editor.", Duration = 3 })
				refreshList()
			else
				window:Error({ Title = "Apply failed", Description = err or "Unknown error", Duration = 4 })
			end
		end,
	})
	editorSection:Button({
		Name = "Save Editor to File",
		NoSave = true,
		Callback = function()
			local name = nameInput:GetText()
			if name == "" then
				name = selectedName
			end
			if not name or name == "" then
				window:Error({
					Title = "Name required",
					Description = "Type a name or pick a config first.",
					Duration = 4,
				})
				return
			end
			local ok, info = manager:Write(name, editor:GetContent())
			if ok then
				window:Toast({ Title = "Config saved", Description = info, Duration = 3 })
				selectedName = info
				refreshAll()
			else
				window:Error({ Title = "Save failed", Description = info or "Unknown error", Duration = 4 })
			end
		end,
	})
	editorSection:Button({
		Name = "Revert Editor",
		NoSave = true,
		Callback = function()
			refreshEditor(selectedName)
		end,
	})
	editorSection:Button({
		Name = "Paste from Clipboard",
		NoSave = true,
		Callback = function()
			if type(getclipboard) ~= "function" then
				window:Error({
					Title = "Clipboard unavailable",
					Description = "Your executor does not support getclipboard.",
					Duration = 4,
				})
				return
			end
			local ok, content = pcall(getclipboard)
			if not ok or type(content) ~= "string" or content == "" then
				window:Error({ Title = "Clipboard empty", Description = "Copy a config JSON first.", Duration = 4 })
				return
			end
			editor:SetText(content)
			window:Toast({ Title = "Pasted", Description = "Review it, then apply or save.", Duration = 3 })
		end,
	})

	refreshEditor = function(name)
		selectedName = name
		if not name then
			editor:SetText("{}")
			return
		end
		-- Flush the pending auto-save so the editor matches the file on disk.
		manager:Flush()
		editor:SetText(manager:Preview(name) or "{}")
	end

	refreshAll = function()
		refreshList()
		refreshEditor(selectedName)
	end

	refreshList = function()
		local names = manager:List()
		local items = {}
		for _, configName in ipairs(names) do
			table.insert(items, { name = configName, value = configName })
		end
		configDropdown:SetValues(items, false)
		-- Keep the selection if it still exists, else take the first.
		if selectedName and table.find(names, selectedName) then
			configDropdown:SetValue(selectedName, true)
		else
			selectedName = names[1]
			if selectedName then
				configDropdown:SetValue(selectedName, true)
			end
		end
		local active = manager.Active
		activeLabel:SetName(active and ("Loaded: " .. active) or "No config loaded")
	end

	-- Deferred so it runs after Window.new's current thread.
	task.defer(refreshAll)
end

return Configs
