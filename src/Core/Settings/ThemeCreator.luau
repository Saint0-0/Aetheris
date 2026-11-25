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
local Sound = require("../../Utils/Sound")
local UUID = require("../../Utils/UUID")

local ThemeCreator = {}

-- Grouped colour keys exposed by the creator. PrimaryTextColor is loaded and
-- saved with the rest, but the Primary Text picker writes it alongside
-- TitleTextColor, so it has no picker of its own.
local COLOR_GROUPS = {
	{
		Name = "Brand",
		Items = {
			{ key = "AccentColor", label = "Accent Color" },
			{ key = "PrimaryColor", label = "Primary Color" },
			{ key = "SecondaryColor", label = "Secondary Color" },
			{ key = "TertiaryColor", label = "Tertiary Color" },
		},
	},
	{
		Name = "Surfaces",
		Items = {
			{ key = "WindowColor", label = "Window Background" },
			{ key = "SidebarColor", label = "Sidebar Background" },
			{ key = "ContentBackgroundColor", label = "Content Background" },
			{ key = "SectionBackgroundColor", label = "Section Background" },
			{ key = "ComponentBackgroundColor", label = "Component Background" },
			{ key = "InputBackgroundColor", label = "Input Well Background" },
			{ key = "PopupBackgroundColor", label = "Popup Background" },
		},
	},
	{
		Name = "Text",
		Items = {
			{ key = "TitleTextColor", label = "Primary Text Color" },
			{ key = "SecondaryTextColor", label = "Secondary Text Color" },
		},
	},
	{
		Name = "Borders & Controls",
		Items = {
			{ key = "StrokeColor", label = "Border / Stroke Color" },
			{ key = "SectionStrokeColor", label = "Section Stroke Color" },
			{ key = "ActiveTabButtonColor", label = "Active Tab Button" },
			{ key = "SearchBarBackgroundColor", label = "Search Bar Background" },
		},
	},
}

local THEME_COLOR_KEYS = { "PrimaryTextColor" }
for _, group in ipairs(COLOR_GROUPS) do
	for _, item in ipairs(group.Items) do
		table.insert(THEME_COLOR_KEYS, item.key)
	end
end

-- Carried with the draft so the live preview and saved themes keep the base
-- preset's depth instead of falling back to opaque surfaces.
local THEME_STYLE_KEYS = {
	"WindowTransparency",
	"SidebarTransparency",
	"ContentBackgroundTransparency",
	"ComponentBackgroundTransparency",
	"InputBackgroundTransparency",
	"SectionBackgroundTransparency",
	"SectionStrokeTransparency",
	"SectionDividerTransparency",
	"ActiveTabButtonTransparency",
	"SearchBarBackgroundTransparency",
	"PrimaryTextTransparency",
	"SecondaryTextTransparency",
	"PopupBackgroundTransparency",
	"WallpaperTransparency",
}

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

	-- Parent to the window frame so the popup centres on the whole window,
	-- not on the content pane the PopUps layer mirrors.
	local previewPopUp = ThemePreviewPopUp.new(window.MainFrame or window.PopUpsFolder or window.Base, window)

	-- Working theme state: start from the live theme, fall back to Base.
	local baseTheme = ThemeManager.GetCurrent()
	local draft = {
		Name = "My Theme",
		Description = "Custom theme",
		BaseTheme = "Base",
		Wallpaper = "Base",
	}
	for _, key in ipairs(THEME_COLOR_KEYS) do
		draft[key] = baseTheme[key] or ThemeDefinitions.Base[key]
	end
	for _, key in ipairs(THEME_STYLE_KEYS) do
		draft[key] = baseTheme[key] or ThemeDefinitions.Base[key]
	end

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
	local presetDropdown
	local colorPickers = {}

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
		for key, picker in pairs(colorPickers) do
			if draft[key] then
				picker:SetColor(draft[key])
			end
		end
		if wpDropdown then
			-- Deselects when the value is a custom name/asset, leaving the
			-- text input as the single manual path.
			wpDropdown:SetValue(draft.Wallpaper, true)
		end
		if presetDropdown then
			presetDropdown:SetValue(draft.BaseTheme or "Base", true)
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

	presetDropdown = profileSection:Dropdown({
		Name = "Load Base Preset",
		Items = presetItems,
		Default = { "Base" },
		MaxItemsChoosable = 1,
		NoSave = true,
		Callback = function(selected)
			local pick = selected and selected[1]
			local chosen = (pick and pick.value) or "Base"
			local src = ThemeDefinitions[chosen] or ThemeDefinitions.Base
			draft.BaseTheme = chosen
			for _, key in ipairs(THEME_COLOR_KEYS) do
				local value = src[key] or ThemeDefinitions.Base[key]
				if value then
					draft[key] = value
				end
			end
			for _, key in ipairs(THEME_STYLE_KEYS) do
				local value = src[key]
				if value == nil then
					value = ThemeDefinitions.Base[key]
				end
				if value ~= nil then
					draft[key] = value
				end
			end
			-- Accent and Primary fall back to each other on older presets.
			draft.AccentColor = draft.AccentColor or draft.PrimaryColor
			draft.PrimaryColor = draft.PrimaryColor or draft.AccentColor
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
		local items = {}
		for _, f in ipairs(files) do
			table.insert(items, { name = f, value = f })
		end
		if #items == 0 then
			table.insert(items, { name = "(No local wallpapers)", value = "__none__" })
		end
		return items
	end

	wpDropdown = wpSection:Dropdown({
		Name = "Local Wallpapers",
		Items = getWallpaperItems(),
		Default = { draft.Wallpaper },
		MaxItemsChoosable = 1,
		NoSave = true,
		Callback = function(selected)
			local pick = selected and selected[1]
			local val = pick and pick.value
			if val == "__none__" then
				-- Placeholder is not a wallpaper; restore the typed value.
				wpDropdown:SetValue(draft.Wallpaper, true)
				return
			end
			if val then
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
			if wpDropdown then
				-- Keep the dropdown in sync when the typed name matches a file.
				wpDropdown:SetValue(val, true)
			end
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
				wpDropdown:SetValue(draft.Wallpaper, true)
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

	local function addColorPicker(key, labelText)
		colorPickers[key] = colorSection:ColorPicker({
			Name = labelText,
			Default = draft[key],
			NoSave = true,
			Callback = function(c)
				draft[key] = c
				-- Title and primary text travel together, as components read
				-- PrimaryTextColor while the preview reads TitleTextColor.
				if key == "TitleTextColor" then
					draft.PrimaryTextColor = c
				end
				liveUpdatePreview()
			end,
		})
	end

	for groupIndex, group in ipairs(COLOR_GROUPS) do
		if groupIndex > 1 then
			colorSection:Divider({ Padding = 6 })
		end
		colorSection:Label({
			Text = group.Name,
			ShowContainer = false,
			ShowStroke = false,
			TextSize = 12,
			FontWeight = "SemiBold",
			Padding = { Top = 2, Bottom = 0, Left = 4, Right = 4 },
		})
		for _, item in ipairs(group.Items) do
			addColorPicker(item.key, item.label)
		end
	end

	-- Section 4: Actions
	local actionsSection = tab:Section({ Name = "Actions" })

	actionsSection:Button({
		Name = "Preview Theme",
		NoSave = true,
		Callback = function()
			if previewPopUp:IsOpen() then
				previewPopUp:Close()
			else
				previewPopUp:Open(draft)
				-- Same open cue the dropdown and colour picker popups play.
				Sound.Play("Notification")
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
		MaxItemsChoosable = 1,
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
				for _, key in ipairs(THEME_COLOR_KEYS) do
					if loaded[key] then
						draft[key] = loaded[key]
					end
				end
				for _, key in ipairs(THEME_STYLE_KEYS) do
					if loaded[key] ~= nil then
						draft[key] = loaded[key]
					end
				end
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
