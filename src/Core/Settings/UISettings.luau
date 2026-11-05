--[[
	Aetheris/Core/Settings/UISettings.luau

	Builds the "UI Settings" page as one vertical column of named Sections
	(Interface, Compact Mode, Behaviour, Visuals, Minimize Pill, Actions);
	every control is created through the Section component factories.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Tween = require("../../Utils/Tween")
local Sound = require("../../Utils/Sound")
local SettingsStore = require("./SettingsStore")
local PageAwareness = require("../../Utils/PageAwareness")
local Constants = require("../../Constants")
local UUID = require("../../Utils/UUID")

local UISettings = {}

function UISettings.Build(window, tab)
	local page = tab.Page

	page.Name = UUID.Static("UISettings")
	page.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	page.BackgroundTransparency = 1
	page.AnchorPoint = Vector2.new(0, 0)
	page.Size = UDim2.fromScale(1, 1)
	page.Position = UDim2.fromScale(0, 0)
	page.LayoutOrder = 1

	-- no page heading: the settings tab bar already names the page
	tab:Scroller()

	local interfaceSection = tab:Section({ Name = "Interface" })
	interfaceSection:Slider({
		Name = "UI Scale",
		Min = 80,
		Max = 125,
		Default = math.floor((SettingsStore.Get("UIScale") or 1) * 100 + 0.5),
		Precision = 0,
		Callback = function(value)
			local scale = value / 100
			local us = window.MainFrame and window.MainFrame:FindFirstChild(UUID.Static("WindowScale"))
			if us then
				us.Scale = scale
			end
			SettingsStore.Set("UIScale", scale)
		end,
	})

	-- first entry is the built-in font, stored as nil so it stays "unset"
	local fontChoices = Constants.FontChoices
	local fontItems = {}
	local storedFont = SettingsStore.Get("Font") or fontChoices[1].Value
	local fontDefault = { fontChoices[1].Value }
	for _, choice in ipairs(fontChoices) do
		table.insert(fontItems, { name = choice.Name, value = choice.Value })
		if choice.Value == storedFont then
			fontDefault = { choice.Value }
		end
	end
	interfaceSection:Dropdown({
		Name = "Font",
		Items = fontItems,
		Default = fontDefault,
		MaxItemsChoosable = 1,
		Callback = function(selected)
			local pick = selected[1]
			local value = (pick and pick.value) or nil
			if value == fontChoices[1].Value then
				value = nil
			end
			if window.SetFont then
				window:SetFont(value)
			end
		end,
	})

	-- Decides auto-mask: on means the name lines open masked and clicks only
	-- toast, off means free clicking with no toast. The callback routes through
	-- Window:SetMaskEnabled so the store, the toggle and the name lines stay
	-- in sync from one place.
	local maskToggle = interfaceSection:Toggle({
		Name = "Auto Mask User/Display Name",
		Default = SettingsStore.Get("MaskDisplayName"),
		Callback = function(state)
			if window.SetMaskEnabled then
				window:SetMaskEnabled(state, true)
			else
				SettingsStore.Set("MaskDisplayName", state)
			end
		end,
	})
	window._maskToggle = maskToggle

	local compactSection = tab:Section({ Name = "Compact Mode" })
	local currentCompact = SettingsStore.Get("CompactMode") or "auto"
	-- guard a stale stored value so one option is always selected
	if currentCompact ~= "auto" and currentCompact ~= "always" and currentCompact ~= "never" then
		currentCompact = "auto"
	end
	local compactGroup = compactSection:RadioButtonGroup()
	for _, opt in ipairs({
		{ key = "auto", label = "Auto" },
		{ key = "always", label = "Always" },
		{ key = "never", label = "Never" },
	}) do
		compactGroup:RadioButton({
			Name = opt.label,
			Default = (opt.key == currentCompact),
			Callback = function()
				SettingsStore.Set("CompactMode", opt.key)
				if window._ResolveCompact then
					window._ResolveCompact()
				end
			end,
		})
	end

	local behaviourSection = tab:Section({ Name = "Behaviour" })
	behaviourSection:Toggle({
		Name = "Spinning Animations",
		Default = SettingsStore.Get("SpinsEnabled"),
		Callback = function(state)
			Tween.SetSpinsEnabled(state)
			SettingsStore.Set("SpinsEnabled", state)
		end,
	})
	behaviourSection:Toggle({
		Name = "Page Animations",
		Default = SettingsStore.Get("PageAnimations") ~= false,
		Callback = function(state)
			SettingsStore.Set("PageAnimations", state)
			-- no page transition fires on this click, so re-apply the gates now
			PageAwareness.ReapplyGates()
		end,
	})
	behaviourSection:Toggle({
		Name = "Confirm On Close",
		Default = SettingsStore.Get("ConfirmClose"),
		Callback = function(state)
			SettingsStore.Set("ConfirmClose", state)
		end,
	})
	behaviourSection:Keybind({
		Name = "Minimize UI",
		Default = window._minimizeKey,
		Callback = function()
			if window.ToggleMinimize then
				window.ToggleMinimize()
			end
		end,
		-- rebind updates the live window key and persists it for next session
		OnRebind = function(key)
			if key and key ~= "" then
				window._minimizeKey = key
				SettingsStore.Set("MinimizeKey", key)
			end
		end,
	})

	local visualsSection = tab:Section({ Name = "Visuals" })
	visualsSection:Toggle({
		Name = "Aurora Background",
		Default = SettingsStore.Get("AuroraEnabled") ~= false,
		Callback = function(state)
			SettingsStore.Set("AuroraEnabled", state)
			if window.Aurora then
				window.Aurora:SetEnabled(state)
			end
		end,
	})
	-- aurora glow transparency: 0 = solid accent, 100 = gone
	visualsSection:Slider({
		Name = "Aurora Transparency",
		Min = 10,
		Max = 95,
		Default = math.floor((SettingsStore.Get("AuroraTransparency") or 0.5) * 100 + 0.5),
		Precision = 0,
		Callback = function(value)
			local transparency = value / 100
			SettingsStore.Set("AuroraTransparency", transparency)
			if window.Aurora then
				window.Aurora:SetTransparency(transparency)
			end
		end,
	})
	visualsSection:Slider({
		Name = "UI Volume",
		Min = 0,
		Max = 100,
		Default = math.floor((SettingsStore.Get("Volume") or 1) * 100 + 0.5),
		Precision = 0,
		Callback = function(value)
			local vol = value / 100
			Sound.SetVolume(vol)
			SettingsStore.Set("Volume", vol)
		end,
	})

	local pillSection = tab:Section({ Name = "Minimize Pill" })
	local currentPill = SettingsStore.Get("PillPosition") or "right"
	local pillGroup = pillSection:RadioButtonGroup()
	for _, pos in ipairs({ "right", "left", "top", "bottom" }) do
		pillGroup:RadioButton({
			Name = pos:sub(1, 1):upper() .. pos:sub(2),
			Default = (pos == currentPill),
			Callback = function()
				if window.SetPillPosition then
					window:SetPillPosition(pos)
				end
			end,
		})
	end

	local actionsSection = tab:Section({ Name = "Actions" })
	actionsSection:Button({
		Name = "Reset Layout",
		Callback = function()
			if window.ResetLayout then
				window.ResetLayout()
			end
		end,
	})

	-- no page-level theme wrapper: every control themes itself via the registry
end

return UISettings
