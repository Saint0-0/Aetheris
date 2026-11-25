--[[
	Aetheris/Core/Settings/ThemeCreator.luau

	Full-featured theme creator page: custom palettes, local wallpaper selection, live preview modal, and JSON saving.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

--# selene: allow(undefined_variable)

local ThemeDefinitions = require("../../Themes/ThemeDefinitions")
local ThemeManager = require("../../Themes/ThemeManager")
local CustomThemeManager = require("../../Themes/CustomThemeManager")
local WallpaperManager = require("../../Utils/WallpaperManager")
local ThemePreviewPopUp = require("../../Popups/ThemePreviewPopUp")
local UUID = require("../../Utils/UUID")

local ThemeCreator = {}

function ThemeCreator.Build(window, tab)
	local page = tab.Page

	page.Name = UUID.Static("ThemeCreatorPage")
	page.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	page.BackgroundTransparency = 1
	page.AnchorPoint = Vector2.new(0, 0)
	page.Size = UDim2.fromScale(1, 1)
	page.Position = UDim2.fromScale(0, 0)
	page.LayoutOrder = 2

	tab:Scroller()

	CustomThemeManager.LoadAll()

	local previewPopUp = ThemePreviewPopUp.new(window.PopUpsFolder or window.Base, window)

	-- Working theme state
	local baseTheme = ThemeManager.GetCurrent()
	local draft = {
		Name = "My Theme",
		Description = "Custom theme",
		BaseTheme = "Base",
		Wallpaper = "Base",
		AccentColor = baseTheme.AccentColor or Color3.fromRGB(120, 156, 210),
		PrimaryColor = baseTheme.PrimaryColor or baseTheme.AccentColor or Color3.fromRGB(120, 156, 210),
		WindowColor = baseTheme.WindowColor or Color3.fromRGB(18, 18, 20),
		ContentBackgroundColor = baseTheme.ContentBackgroundColor or Color3.fromRGB(24, 24, 28),
		ComponentBackgroundColor = baseTheme.ComponentBackgroundColor or Color3.fromRGB(32, 32, 38),
		InputBackgroundColor = baseTheme.InputBackgroundColor or Color3.fromRGB(40, 40, 46),
		TitleTextColor = baseTheme.TitleTextColor or Color3.fromRGB(240, 240, 245),
		PrimaryTextColor = baseTheme.PrimaryTextColor or baseTheme.TitleTextColor or Color3.fromRGB(240, 240, 245),
		SecondaryTextColor = baseTheme.SecondaryTextColor or Color3.fromRGB(160, 160, 170),
		StrokeColor = baseTheme.StrokeColor or Color3.fromRGB(60, 60, 70),
	}

	local function liveUpdatePreview()
		if previewPopUp:IsOpen() then
			previewPopUp:UpdateTheme(draft)
		end
	end

	-- Forward declarations
	local nameInput
	local descInput
	local wpInput
	local wpDropdown
	local savedDropdown
	local cpAccent
	local cpPrimary
	local cpWindow
	local cpContent
	local cpComponent
	local cpInput
	local cpTitle
	local cpSecondary
	local cpStroke

	local function updateControlsFromDraft()
		if nameInput then
			nameInput:SetText(draft.Name or "")
		end
		if descInput then
			descInput:SetText(draft.Description or "")
		end
		if wpInput then
			wpInput:SetText(draft.Wallpaper or "")
		end
		if cpAccent then
			cpAccent:SetColor(draft.AccentColor)
		end
		if cpPrimary then
			cpPrimary:SetColor(draft.PrimaryColor)
		end
		if cpWindow then
			cpWindow:SetColor(draft.WindowColor)
		end
		if cpContent then
			cpContent:SetColor(draft.ContentBackgroundColor)
		end
		if cpComponent then
			cpComponent:SetColor(draft.ComponentBackgroundColor)
		end
		if cpInput then
			cpInput:SetColor(draft.InputBackgroundColor)
		end
		if cpTitle then
			cpTitle:SetColor(draft.TitleTextColor)
		end
		if cpSecondary then
			cpSecondary:SetColor(draft.SecondaryTextColor)
		end
		if cpStroke then
			cpStroke:SetColor(draft.StrokeColor)
		end
		if wpDropdown then
			wpDropdown:SetValue(draft.Wallpaper, true)
			local picked = wpDropdown:GetValues()
			if not picked or #picked == 0 then
				wpDropdown:SetValue("__manual__", true)
			end
		end
		liveUpdatePreview()
	end

	-- Section 1: Details & Presets
	local profileSection = tab:Section({ Name = "Theme Details" })
	nameInput = profileSection:TextInput({
		Name = "Theme Name",
		Placeholder = "Theme name (e.g. Cyberpunk)",
		Default = draft.Name,
		NoSave = true,
		Callback = function(val)
			draft.Name = val
			liveUpdatePreview()
		end,
	})

	descInput = profileSection:TextInput({
		Name = "Description",
		Placeholder = "Theme description",
		Default = draft.Description,
		NoSave = true,
		Callback = function(val)
			draft.Description = val
		end,
	})

	local presetChoices = { "Base", "Umbral", "Ember", "Vesper", "Canopy", "Solace", "Gruvbox", "Void" }
	local presetItems = {}
	for _, pName in ipairs(presetChoices) do
		table.insert(presetItems, { name = pName, value = pName })
	end

	profileSection:Dropdown({
		Name = "Load Base Preset",
		Items = presetItems,
		Default = { "Base" },
		NoSave = true,
		Callback = function(selected)
			local pick = selected and selected[1]
			local chosen = (pick and pick.value) or "Base"
			local src = ThemeDefinitions[chosen] or ThemeDefinitions.Base
			draft.BaseTheme = chosen
			draft.AccentColor = src.AccentColor or src.PrimaryColor or draft.AccentColor
			draft.PrimaryColor = src.PrimaryColor or src.AccentColor or draft.PrimaryColor
			draft.WindowColor = src.WindowColor or draft.WindowColor
			draft.ContentBackgroundColor = src.ContentBackgroundColor or draft.ContentBackgroundColor
			draft.ComponentBackgroundColor = src.ComponentBackgroundColor or draft.ComponentBackgroundColor
			draft.InputBackgroundColor = src.InputBackgroundColor or draft.InputBackgroundColor
			draft.TitleTextColor = src.TitleTextColor or src.PrimaryTextColor or draft.TitleTextColor
			draft.PrimaryTextColor = src.PrimaryTextColor or src.TitleTextColor or draft.PrimaryTextColor
			draft.SecondaryTextColor = src.SecondaryTextColor or draft.SecondaryTextColor
			draft.StrokeColor = src.StrokeColor or draft.StrokeColor
			-- Theme-name first so local and GitHub wallpapers resolve before the
			-- built-in asset fallback in WallpaperManager.
			draft.Wallpaper = chosen
			updateControlsFromDraft()
			window:Toast({
				Title = "Preset loaded",
				Description = "Loaded colors from preset: " .. chosen,
				Duration = 2.5,
			})
		end,
	})

	-- Section 2: Wallpaper
	local wpSection = tab:Section({ Name = "Wallpaper" })

	local function getWallpaperItems()
		local files = WallpaperManager.ListLocal()
		local items = {
			{ name = "(Custom / Manual Name)", value = "__manual__" },
		}
		for _, f in ipairs(files) do
			table.insert(items, { name = f, value = f })
		end
		return items
	end

	wpDropdown = wpSection:Dropdown({
		Name = "Local Wallpapers",
		Items = getWallpaperItems(),
		Default = { draft.Wallpaper },
		NoSave = true,
		Callback = function(selected)
			local pick = selected and selected[1]
			local val = pick and pick.value
			if val and val ~= "__manual__" then
				draft.Wallpaper = val
				if wpInput then
					wpInput:SetText(val)
				end
				liveUpdatePreview()
			end
		end,
	})

	wpInput = wpSection:TextInput({
		Name = "Wallpaper Name or Asset ID",
		Placeholder = "filename.png, Vesper, or rbxassetid://...",
		Default = draft.Wallpaper,
		NoSave = true,
		Callback = function(val)
			draft.Wallpaper = val
			liveUpdatePreview()
		end,
	})

	wpSection:Button({
		Name = "Refresh Wallpapers Folder",
		NoSave = true,
		Callback = function()
			WallpaperManager.EnsureFolders()
			WallpaperManager.ClearCache()
			local items = getWallpaperItems()
			if wpDropdown and wpDropdown.SetValues then
				wpDropdown:SetValues(items, true)
			end
			liveUpdatePreview()
			window:Toast({
				Title = "Wallpapers refreshed",
				Description = "Scanned Aetheris/Wallpapers/ for local images.",
				Duration = 3,
			})
		end,
	})

	-- Section 3: Colors
	local colorSection = tab:Section({ Name = "Colors & Styling" })

	cpAccent = colorSection:ColorPicker({
		Name = "Accent Color",
		Default = draft.AccentColor,
		NoSave = true,
		Callback = function(c)
			draft.AccentColor = c
			liveUpdatePreview()
		end,
	})

	cpPrimary = colorSection:ColorPicker({
		Name = "Primary Color",
		Default = draft.PrimaryColor,
		NoSave = true,
		Callback = function(c)
			draft.PrimaryColor = c
			liveUpdatePreview()
		end,
	})

	cpWindow = colorSection:ColorPicker({
		Name = "Window Background",
		Default = draft.WindowColor,
		NoSave = true,
		Callback = function(c)
			draft.WindowColor = c
			liveUpdatePreview()
		end,
	})

	cpContent = colorSection:ColorPicker({
		Name = "Content Background",
		Default = draft.ContentBackgroundColor,
		NoSave = true,
		Callback = function(c)
			draft.ContentBackgroundColor = c
			liveUpdatePreview()
		end,
	})

	cpComponent = colorSection:ColorPicker({
		Name = "Component Background",
		Default = draft.ComponentBackgroundColor,
		NoSave = true,
		Callback = function(c)
			draft.ComponentBackgroundColor = c
			liveUpdatePreview()
		end,
	})

	cpInput = colorSection:ColorPicker({
		Name = "Input Well Background",
		Default = draft.InputBackgroundColor,
		NoSave = true,
		Callback = function(c)
			draft.InputBackgroundColor = c
			liveUpdatePreview()
		end,
	})

	cpTitle = colorSection:ColorPicker({
		Name = "Primary Text Color",
		Default = draft.TitleTextColor,
		NoSave = true,
		Callback = function(c)
			draft.TitleTextColor = c
			draft.PrimaryTextColor = c
			liveUpdatePreview()
		end,
	})

	cpSecondary = colorSection:ColorPicker({
		Name = "Secondary Text Color",
		Default = draft.SecondaryTextColor,
		NoSave = true,
		Callback = function(c)
			draft.SecondaryTextColor = c
			liveUpdatePreview()
		end,
	})

	cpStroke = colorSection:ColorPicker({
		Name = "Border / Stroke Color",
		Default = draft.StrokeColor,
		NoSave = true,
		Callback = function(c)
			draft.StrokeColor = c
			liveUpdatePreview()
		end,
	})

	-- Section 4: Actions
	local actionsSection = tab:Section({ Name = "Actions" })

	actionsSection:Button({
		Name = "Preview Theme",
		NoSave = true,
		Callback = function()
			if previewPopUp:IsOpen() then
				previewPopUp:Close()
			else
				window:_claimPopup(previewPopUp)
				previewPopUp:Open(draft)
			end
		end,
	})

	actionsSection:Button({
		Name = "Save Custom Theme",
		NoSave = true,
		Callback = function()
			local name = draft.Name
			if not name or name == "" then
				window:Error({
					Title = "Name required",
					Description = "Please enter a valid theme name.",
					Duration = 4,
				})
				return
			end
			local ok, savedName = CustomThemeManager.Save(name, draft, draft.Description)
			if ok then
				draft.Name = savedName
				if nameInput then
					nameInput:SetText(savedName)
				end
				window:Toast({
					Title = "Theme saved",
					Description = "Saved custom theme '" .. tostring(savedName) .. "' to Custom Themes.json",
					Duration = 3.5,
				})
			else
				window:Error({
					Title = "Save failed",
					Description = tostring(savedName or "Unknown error"),
					Duration = 4,
				})
			end
		end,
	})

	actionsSection:Button({
		Name = "Apply Theme to Window",
		NoSave = true,
		Callback = function()
			local name = draft.Name
			if not name or name == "" then
				name = "Custom Theme"
			end
			local ok, savedName = CustomThemeManager.Save(name, draft, draft.Description)
			if not ok then
				window:Error({
					Title = "Apply failed",
					Description = tostring(savedName or "Unknown error"),
					Duration = 4,
				})
				return
			end
			draft.Name = savedName
			if nameInput then
				nameInput:SetText(savedName)
			end
			window:SetTheme(savedName)
			window:Toast({
				Title = "Theme applied",
				Description = "Applied '" .. savedName .. "' to current window.",
				Duration = 3,
			})
		end,
	})

	-- Section 5: Custom Themes Library
	local librarySection = tab:Section({ Name = "Custom Themes Library" })

	local function getSavedThemeItems()
		local names = CustomThemeManager.GetNames()
		local items = {}
		for _, tName in ipairs(names) do
			table.insert(items, { name = tName, value = tName })
		end
		if #items == 0 then
			table.insert(items, { name = "(No saved themes)", value = "__none__" })
		end
		return items
	end

	savedDropdown = librarySection:Dropdown({
		Name = "Saved Custom Themes",
		Items = getSavedThemeItems(),
		Default = { "__none__" },
		NoSave = true,
	})

	librarySection:Button({
		Name = "Load Theme into Creator",
		NoSave = true,
		Callback = function()
			local selected = savedDropdown:GetValues()
			local pick = selected and selected[1]
			local tName = pick and pick.value
			if not tName or tName == "__none__" then
				window:Error({
					Title = "No theme selected",
					Description = "Choose a saved custom theme from the dropdown first.",
					Duration = 4,
				})
				return
			end
			local loaded = CustomThemeManager.Get(tName)
			if loaded then
				draft.Name = tName
				draft.Description = loaded.Description or "Custom theme"
				draft.BaseTheme = loaded.BaseTheme or "Base"
				draft.Wallpaper = loaded.Wallpaper or loaded.Name or "Base"
				draft.AccentColor = loaded.AccentColor
				draft.PrimaryColor = loaded.PrimaryColor
				draft.WindowColor = loaded.WindowColor
				draft.ContentBackgroundColor = loaded.ContentBackgroundColor
				draft.ComponentBackgroundColor = loaded.ComponentBackgroundColor
				draft.InputBackgroundColor = loaded.InputBackgroundColor
				draft.TitleTextColor = loaded.TitleTextColor or loaded.PrimaryTextColor
				draft.PrimaryTextColor = loaded.PrimaryTextColor or loaded.TitleTextColor
				draft.SecondaryTextColor = loaded.SecondaryTextColor
				draft.StrokeColor = loaded.StrokeColor
				updateControlsFromDraft()
				window:Toast({
					Title = "Theme loaded",
					Description = "Loaded '" .. tName .. "' into Theme Creator.",
					Duration = 3,
				})
			end
		end,
	})

	librarySection:Button({
		Name = "Delete Selected Theme",
		NoSave = true,
		Callback = function()
			local selected = savedDropdown:GetValues()
			local pick = selected and selected[1]
			local tName = pick and pick.value
			if not tName or tName == "__none__" then
				window:Error({
					Title = "No theme selected",
					Description = "Choose a saved theme to delete.",
					Duration = 4,
				})
				return
			end
			local ok, err = CustomThemeManager.Delete(tName)
			if ok then
				window:Toast({
					Title = "Theme deleted",
					Description = "Deleted '" .. tName .. "'.",
					Duration = 3,
				})
			else
				window:Error({
					Title = "Delete failed",
					Description = tostring(err or "Unknown error"),
					Duration = 4,
				})
			end
		end,
	})

	-- Refresh library dropdown whenever themes change
	local unsubscribeThemes = CustomThemeManager.OnThemesChanged(function()
		if savedDropdown and savedDropdown.SetValues then
			savedDropdown:SetValues(getSavedThemeItems(), true)
		end
	end)

	window:OnDestroy(function()
		if type(unsubscribeThemes) == "function" then
			unsubscribeThemes()
		end
		if window._activePopUp == previewPopUp then
			window._activePopUp = nil
		end
		previewPopUp:Destroy()
	end)
end

return ThemeCreator
