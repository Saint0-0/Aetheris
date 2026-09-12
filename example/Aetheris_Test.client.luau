--[[
============================================================================
  Aetheris  ·  Full Component Demo  (example/Aetheris_Test.client.luau)
============================================================================

  A living showcase of the ENTIRE Aetheris UI library. Every element the
  library exposes is created at least once here, and every block is heavily
  commented so this file doubles as the reference documentation.

  What it demonstrates
  --------------------
    Window API : CreateWindow, :Tab, :Divider, :SetTheme, :Alert, :Error,
                 :VariableNotification, :UINotification, :DropdownPopUp,
                 :ColorPickerPopUp, :Destroy
    Layout     : Tabs, Left/Right Sections
    Components : Toggle, Slider, Keybind, TextInput, Stepper, RadioButtonGroup
                 (+ RadioButton), Dropdown, ColorPicker, Status, ProgressBar,
                 Button, Label, Paragraph, Divider, Video

  How to run
  ----------
    Drop this LocalScript into StarterPlayerScripts, or paste it into the
    command bar while the game is running. The whole window is built purely
    with Instance.new by the library - no pre-built assets required.
============================================================================
]]

-- == 0. LIBRARY BOOTSTRAP ==================================================
-- Aetheris is the single facade for the whole library. Requiring Init gives
-- us every public entry point (CreateWindow, Icons, ThemeManager, ...).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Aetheris = require(ReplicatedStorage:WaitForChild("Aetheris").Init)
local Icons = Aetheris.Icons

-- Tiny helper: a missing icon key falls back to the crosshair icon (which
-- always exists) so the demo never crashes on a typo'd icon name.
local function ico(name)
	return Icons[name] or Icons.crosshair
end

-- Grab the local player + humanoid once, so the Health ProgressBar can bind
-- to real health changes later on.
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- == 1. CREATE THE MAIN WINDOW =============================================
-- CreateWindow is the preferred entry point. Everything you see is themed by
-- the library; the theme name below is the starting theme.
local window = Aetheris:CreateWindow({
	Title = "Aetheris",
	Description = '<font color="#777780">AETHERIS</font> <font color="#55555F">/</font> <font color="#6C8CFF">v0.2.0</font> <font color="#55555F">/</font> <font color="#777780">DEMO</font>',
	Theme = "Default",           -- any name from ThemeDefinitions
	AnimationStyle = "Smooth",   -- "Smooth" | "Snappy"
	DragStyle = "Smooth",        -- "Smooth" (glides) | "Instant" (snaps)
	MinimizeKey = "LeftControl", -- press to minimize / restore the window
	SettingsPages = {            -- extra pages shown in the Settings tab
		{ Name = "Keybinds", Icon = ico("keyboard") },
		{ Name = "Macros",   Icon = ico("mouse-pointer-click") },
	},
	DefaultSettingsPage = "Themes",
})

-- Helpers handed to components that open popups, so the popups inherit the
-- window's theme + positioning instead of building their own.
local function notify(settings) return window:UINotification(settings) end
local function openDropdown(id, settings) return window:DropdownPopUp(id, settings) end
local function openColorPicker(id, settings) return window:ColorPickerPopUp(id, settings) end

-- == 2. CREATE THE TABS ====================================================
-- window:Tab(name, icon) adds a page to the sidebar. window:Divider() inserts
-- a thin separator (used here to visually detach the Settings tab).
local homeTab     = window:Tab("Home", ico("home"))
local controlsTab = window:Tab("Controls", ico("sliders-horizontal"))
local inputsTab   = window:Tab("Inputs", ico("list"))
local feedbackTab = window:Tab("Feedback", ico("bell"))
local mediaTab    = window:Tab("Media", ico("play"))
window:Divider()
local settingsTab = window:Tab("Settings", ico("settings"))

-- =========================================================================
--  3. HOME TAB  -  Paragraph, Label, Divider, Button
-- =========================================================================
local heroSection = homeTab:Section({ Name = "Welcome", Side = "Left" })

-- Paragraph: a titled block of descriptive text.
heroSection:Paragraph({
	Title = "Aetheris Component Showcase",
	Description = "Every element the library offers, on one screen.\nSwitch tabs on the sidebar, tweak the settings, and watch the theme engine repaint everything live.",
})

-- Divider: a horizontal rule. Pass Color to tint it (defaults to the theme).
heroSection:Divider()

-- Label: single-line text. ShowContainer/ShowStroke toggle its card styling.
heroSection:Label({
	Text = "Plain label - no container, no stroke",
	ShowContainer = false,
	ShowStroke = false,
})

-- Label with a heavier font weight, and the default container styling.
heroSection:Label({
	Text = "Bold label with container",
	FontWeight = "Bold",
})

-- Divider with a custom accent color.
heroSection:Divider({ Color = Color3.fromRGB(108, 140, 255) })

-- Button section (right column).
local actionSection = homeTab:Section({ Name = "Actions", Side = "Right" })

actionSection:Button({
	Name = "Do The Thing",
	Callback = function() print("[Demo] Button clicked") end,
})

-- A button that fires a themed toast notification with clickable actions.
actionSection:Button({
	Name = "Send a toast",
	Callback = function()
		window:VariableNotification({
			Title = "Hello!",
			Description = "This is a variable notification with an action.",
			Duration = 6,
			ShowBackground = true,
			Actions = {
				{ Text = "Nice", Callback = function() print("[Demo] toast action") end },
			},
		})
	end,
})

-- =========================================================================
--  4. CONTROLS TAB  -  Toggle, Slider, Keybind, TextInput, Stepper, Radio
-- =========================================================================
local switchSection = controlsTab:Section({ Name = "Switches", Side = "Left" })

-- Toggle: an on/off switch. `Default` sets the initial state.
switchSection:Toggle({
	Name = "Enable Feature",
	Default = true,
	Callback = function(state) print("[Demo] Toggle:", state) end,
})

-- Toggle with a confirmation prompt. When Confirm.Enabled is true, flipping
-- the switch shows a modal; the 2nd arg (notify) is the notification engine.
switchSection:Toggle({
	Name = "Dangerous Toggle",
	Default = false,
	Confirm = {
		Enabled = true,
		Title = "Are you sure?",
		Description = 'This may cause <font color="rgb(255,0,0)">performance issues</font>. Continue?',
		TitleColor = Color3.fromRGB(255, 100, 100),
		ConfirmText = "Yes, enable it",
		CancelText = "No, cancel",
	},
	Callback = function(state) print("[Demo] Dangerous toggle:", state) end,
}, notify)

local valueSection = controlsTab:Section({ Name = "Values", Side = "Left" })

-- Slider: numeric range. Precision = decimal places shown/stored.
valueSection:Slider({
	Name = "Smoothness",
	Min = 0,
	Max = 100,
	Default = 50,
	Precision = 1,
	Callback = function(v) print("[Demo] Slider:", v) end,
})

-- Stepper: +/- numeric field. Integer=true forces whole numbers, Step sets the
-- increment per click.
valueSection:Stepper({
	Name = "Ammo Count",
	Min = 0,
	Max = 100,
	Default = 30,
	Step = 5,
	Integer = true,
	Callback = function(v) print("[Demo] Stepper:", v) end,
})

local textSection = controlsTab:Section({ Name = "Text", Side = "Right" })

-- Keybind: capture a keyboard key. Default is the starting key ("G").
textSection:Keybind({
	Name = "Primary Key",
	Default = "G",
	Callback = function(key) print("[Demo] Keybind:", key) end,
})

-- TextInput: free-form single-line text with a placeholder.
textSection:TextInput({
	Name = "Player Name",
	Placeholder = "Enter a name...",
	Default = "",
	Callback = function(text) print("[Demo] TextInput:", text) end,
})

-- RadioButtonGroup: mutually-exclusive choices. Create the group, then add
-- RadioButtons to it; only one can be selected at a time.
local choiceSection = controlsTab:Section({ Name = "Choices", Side = "Right" })
local radioGroup = choiceSection:RadioButtonGroup()
radioGroup:RadioButton({ Name = "Option A", Default = true, Callback = function() print("[Demo] Radio A") end })
radioGroup:RadioButton({ Name = "Option B", Callback = function() print("[Demo] Radio B") end })
radioGroup:RadioButton({ Name = "Option C", Callback = function() print("[Demo] Radio C") end })

-- =========================================================================
--  5. INPUTS TAB  -  Dropdown, ColorPicker
-- =========================================================================
local dropdownItems = {
	{ name = "Apple",      icon = ico("apple"),      value = "apple" },
	{ name = "Banana",     icon = ico("banana"),     value = "banana" },
	{ name = "Orange",     icon = ico("orange"),     value = "orange" },
	{ name = "Grapes",     icon = ico("grapes"),     value = "grapes" },
	{ name = "Strawberry", icon = ico("strawberry"), value = "strawberry" },
	{ name = "Watermelon", icon = ico("watermelon"), value = "watermelon" },
}

local dropSection = inputsTab:Section({ Name = "Dropdowns", Side = "Left" })

-- Dropdown, single-select (MaxItemsChoosable = 1). Opens a themed popup.
dropSection:Dropdown({
	Name = "Favourite Fruit",
	Items = dropdownItems,
	Default = { "apple" },
	MaxItemsChoosable = 1,
	Placeholder = "Pick one...",
	Callback = function(selected)
		if selected[1] then print("[Demo] Dropdown (single):", selected[1].name) end
	end,
}, openDropdown)

-- Dropdown, multi-select capped at 2.
dropSection:Dropdown({
	Name = "Snack Selection (max 2)",
	Items = dropdownItems,
	Default = { "apple", "banana" },
	MaxItemsChoosable = 2,
	Placeholder = "Pick up to two...",
	Callback = function(selected)
		local names = {}
		for _, item in ipairs(selected) do table.insert(names, item.name) end
		print("[Demo] Dropdown (multi):", table.concat(names, ", "))
	end,
}, openDropdown)

-- Dropdown, uncapped multi-select (omit MaxItemsChoosable).
dropSection:Dropdown({
	Name = "Fruit Salad (any amount)",
	Items = dropdownItems,
	Default = {},
	Placeholder = "Choose freely...",
	Callback = function(selected) print("[Demo] Dropdown (uncapped):", #selected, "items") end,
}, openDropdown)

local colorSection = inputsTab:Section({ Name = "Colors", Side = "Right" })

-- ColorPicker: opens a themed colour-picker popup; the 2nd arg is the popup
-- factory so it renders consistently with the rest of the window.
colorSection:ColorPicker({
	Name = "Accent Colour",
	Default = Color3.fromRGB(108, 140, 255),
	Callback = function(color) print("[Demo] ColorPicker:", color) end,
}, openColorPicker)

colorSection:ColorPicker({
	Name = "Crosshair Colour",
	Default = Color3.fromRGB(255, 80, 80),
	Callback = function(color) print("[Demo] ColorPicker 2:", color) end,
}, openColorPicker)

-- =========================================================================
--  6. FEEDBACK TAB  -  Status, ProgressBar, Notifications, Video
-- =========================================================================
local statusSection = feedbackTab:Section({ Name = "System Status", Side = "Left" })

-- Status: a list of labelled entries. Each entry is { kind, text, color }
-- where color is a named colour ("green"/"orange"/"red") or a Color3.
statusSection:Status({
	Name = "Diagnostics",
	Entries = {
		{ "info",  "All systems nominal",   "green" },
		{ "alert", "CPU usage high",        "orange" },
		{ "error", "Cache miss detected",   "red" },
		{ "custom", "Custom-tinted entry",  Color3.fromRGB(255, 200, 100) },
	},
})

local progressSection = feedbackTab:Section({ Name = "Progress", Side = "Left" })

-- ProgressBar bound to the local player's health. Animate tweens the fill.
local healthBar = progressSection:ProgressBar({
	Name = "Health",
	MinValue = 0,
	MaxValue = 100,
	Value = humanoid.Health,
	Color = Color3.fromRGB(255, 60, 60),
	ShowPercentage = true,
	ShowFraction = true,
	Animate = true,
})
humanoid.HealthChanged:Connect(function(hp) healthBar:SetValue(hp) end)

-- A second, static progress bar to show the default styling.
progressSection:ProgressBar({
	Name = "Download",
	MinValue = 0,
	MaxValue = 100,
	Value = 42,
	ShowPercentage = true,
	Animate = false,
})

local toastSection = feedbackTab:Section({ Name = "Notifications", Side = "Right" })

-- Alert toast.
toastSection:Button({
	Name = "Alert",
	Callback = function()
		window:Alert({ Title = "Alert", Description = "This is an alert notification.", Duration = 4 })
	end,
})

-- Error toast.
toastSection:Button({
	Name = "Error",
	Callback = function()
		window:Error({ Title = "Error", Description = "Something went wrong.", Duration = 4 })
	end,
})

-- Variable toast with a gradient icon + action buttons.
toastSection:Button({
	Name = "Rich Toast",
	Callback = function()
		window:VariableNotification({
			Title = "Update available",
			Description = "Version 2.0 is ready to install.",
			Duration = 8,
			Icon = ico("download"),
			IconColor = Color3.fromRGB(96, 165, 250),
			GradientColor = Color3.fromRGB(139, 92, 246),
			ShowBackground = true,
			Actions = {
				{ Text = "Install", Callback = function() print("[Demo] Install") end },
				{ Text = "Later",   Callback = function() print("[Demo] Later") end },
			},
		})
	end,
})

-- =========================================================================
--  7. MEDIA TAB  -  Video
-- =========================================================================
local mediaSection = mediaTab:Section({ Name = "Video Player", Side = "Left" })

-- Video: embeds a Roblox VideoFrame. Loop repeats; Height is in pixels.
mediaSection:Video({
	VideoId = "rbxassetid://5670794788",
	Loop = true,
	Height = 90,
})

mediaSection:Paragraph({
	Title = "Video Element",
	Description = "The Video component wraps a VideoFrame with the library's stroke, rounding and shadow styling, all theme-aware.",
})

-- =========================================================================
--  8. SETTINGS TAB  -  live theme switcher
-- =========================================================================
local settingsSection = settingsTab:Section({ Name = "General", Side = "Left" })
settingsSection:Paragraph({
	Title = "Settings",
	Description = "The Settings tab also hosts the Themes card grid that the library builds automatically. Use the dropdown opposite to switch themes live and watch every element crossfade.",
})

local themeSection = settingsTab:Section({ Name = "Theme Switcher", Side = "Right" })
local themeItems = {}
for _, name in ipairs(Aetheris.ThemeManager.ThemeOrder or {}) do
	table.insert(themeItems, { name = name, value = name })
end
-- Fallback: if ThemeOrder isn't exposed, list the ones we know are safe.
if #themeItems == 0 then
	for _, name in ipairs({ "Default", "Black", "Light", "Midnight", "Graphite", "Ocean", "Nord", "Forest", "Glass", "Azure", "Fjord", "Summit" }) do
		table.insert(themeItems, { name = name, value = name })
	end
end

themeSection:Dropdown({
	Name = "Theme",
	Items = themeItems,
	Default = { "Default" },
	MaxItemsChoosable = 1,
	Placeholder = "Select theme...",
	Callback = function(selected)
		if selected[1] then
			window:SetTheme(selected[1].value)
			print("[Demo] Theme ->", selected[1].value)
		end
	end,
}, openDropdown)

-- =========================================================================
--  9. STARTUP LOG
-- =========================================================================
print("[Aetheris Demo] Window built. Tabs: Home, Controls, Inputs, Feedback, Media, Settings")
print("[Aetheris Demo] Active tab:", window.TabGroup.ActiveTab.Name)
print("[Aetheris Demo] All components exercised: Toggle, Slider, Keybind, TextInput, Stepper, RadioButton(Group), Dropdown, ColorPicker, Status, ProgressBar, Button, Label, Paragraph, Divider, Video.")

-- =========================================================================
-- 10. OPTIONAL: auto-destroy after 10s (uncomment to test teardown)
-- =========================================================================
-- task.wait(10)
-- window:Destroy()
