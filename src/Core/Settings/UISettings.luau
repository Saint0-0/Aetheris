--[[
	UISettings  ·  Aetheris UI Library

	Builds the "UI Settings" page. The page is ONE vertical column of named
	Sections -- Section draws its own title, so there are no hand-built section
	labels or separators here; the section system owns that structure. Every
	control is created through the Section component factories.
	UISettings.Build(window, tab) is called by Settings/Init.BuildDefaultPages.
]]

local Tween = require("../../Utils/Tween")
local Sound = require("../../Utils/Sound")
local SettingsStore = require("./SettingsStore")
local ThemeManager = require("../../Themes/ThemeManager")

local UISettings = {}

function UISettings.Build(window, tab)
	local theme = window._theme or {}
	local page = tab.Page

	page.Name = "UISettings"
	page.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	page.BackgroundTransparency = 1
	page.AnchorPoint = Vector2.new(0, 0)
	page.Size = UDim2.new(1, 0, 1, 0)
	page.Position = UDim2.new(0, 0, 0, 0)
	page.LayoutOrder = 1

	-- No page heading: the settings tab bar already names the page. The
	-- heading was removed because a settings-page fade/theme switch kept
	-- leaving it stuck transparent. Everything below is Sections.
	-- Single-column scroller; tab:Section() stacks every section into it.
	tab:Scroller()

	-- == Input ==============================================================
	local inputSection = tab:Section({ Name = "Input" })
	inputSection:Keybind({
		Name = "Minimize UI",
		Default = window._minimizeKey,
		Callback = function()
			if window.ToggleMinimize then window.ToggleMinimize() end
		end,
		-- Persist a rebind: update the live window key AND save it so it survives
		-- across sessions (Window reads SettingsStore 'MinimizeKey' on CreateWindow).
		OnRebind = function(key)
			if key and key ~= "" then
				window._minimizeKey = key
				SettingsStore.Set("MinimizeKey", key)
			end
		end,
	})

	-- == Minimize Pill ======================================================
	local pillSection = tab:Section({ Name = "Minimize Pill" })
	local currentPill = SettingsStore.Get("PillPosition") or "right"
	local pillGroup = pillSection:RadioButtonGroup()
	for _, pos in ipairs({ "right", "left", "top", "bottom" }) do
		pillGroup:RadioButton({
			Name = pos:sub(1, 1):upper() .. pos:sub(2),
			Default = (pos == currentPill),
			Callback = function()
				if window.SetPillPosition then window:SetPillPosition(pos) end
			end,
		})
	end

	-- == Compact Mode =======================================================
	local compactSection = tab:Section({ Name = "Compact Mode" })
	local currentCompact = SettingsStore.Get("CompactMode") or "auto"
	-- Guard a stale/invalid stored value so one option is always selected.
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
				if window._ResolveCompact then window._ResolveCompact() end
			end,
		})
	end

	-- == Behaviour ==========================================================
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
		Name = "Confirm On Close",
		Default = SettingsStore.Get("ConfirmClose"),
		Callback = function(state)
			SettingsStore.Set("ConfirmClose", state)
		end,
	})

	-- == Visuals ============================================================
	local visualsSection = tab:Section({ Name = "Visuals" })
	visualsSection:Slider({
		Name = "UI Scale",
		Min = 80,
		Max = 125,
		Default = math.floor((SettingsStore.Get("UIScale") or 1) * 100 + 0.5),
		Precision = 0,
		Callback = function(value)
			local scale = value / 100
			local us = window.MainFrame and window.MainFrame:FindFirstChild("WindowScale")
			if us then us.Scale = scale end
			SettingsStore.Set("UIScale", scale)
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

	-- == Actions ============================================================
	local actionsSection = tab:Section({ Name = "Actions" })
	actionsSection:Button({
		Name = "Reset Layout",
		Callback = function()
			if window.ResetLayout then window.ResetLayout() end
		end,
	})

	-- No page-level theme wrapper needed: the scroller, sections and every
	-- control are registered components and theme themselves via the registry.
end

return UISettings
