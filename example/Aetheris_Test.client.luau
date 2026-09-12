-- ============================================================================
--  Aetheris_Test.lua
--  Quick manual test harness for the Saint X UI library.
--  Organized with each section having <=5 components, all stored in locals.
-- ============================================================================

local Aetheris = require(game:GetService("StarterGui"):WaitForChild("NewScripts").Init)
-- Icons are reached through the facade: Aetheris.Icons["search"].
local Icons = Aetheris.Icons


-- ============================================================================
--  1. CREATE THE MAIN WINDOW
-- ============================================================================

local window = Aetheris:CreateWindow({
	Title = "Saint X Test",
	Description = '<font color="#777780">SAINT X</font> <font color="#55555F">/</font> <font color="#6C8CFF">v0.1.0</font> <font color="#55555F">/</font> <font color="#777780">BETA</font>',
	AnimationStyle = "Smooth",
	DragStyle = "Smooth", -- "Instant" (snaps to cursor) | "Smooth" (glides behind cursor)
	Theme = "Forest",  -- Use a predefined theme name ("Default", "Black", "Light")
	MinimizeKey = "LeftControl",  -- default keybind to minimize/restore the UI
	SettingsPages = {
		{ Name = "Keybinds", Icon = Icons["keyboard"] },
		{ Name = "Macros", Icon = Icons["mouse-pointer-click"] },
	},
	DefaultSettingsPage = "Themes",
})

-- ============================================================================
--  2. HELPERS (shared across tabs)
-- ============================================================================
local function showNotification(settings)
	return window:UINotification(settings)
end

local function showDropdown(id, settings)
	return window:DropdownPopUp(id, settings)
end

local function showColorPicker(id, settings)
	return window:ColorPickerPopUp(id, settings)
end

local dropdownItems = {
	{ name = "Apple", icon = Icons["apple"], value = "apple" },
	{ name = "Banana", icon = Icons["banana"], value = "banana" },
	{ name = "Orange", icon = Icons["orange"], value = "orange" },
	{ name = "Grapes", icon = Icons["grapes"], value = "grapes" },
	{ name = "Strawberry", icon = Icons["strawberry"], value = "strawberry" },
	{ name = "Watermelon", icon = Icons["watermelon"], value = "watermelon" },
}

-- ============================================================================
--  3. CREATE TABS
-- ============================================================================
local aimbotTab = window:Tab("Aimbot", Icons.crosshair)
local visualsTab = window:Tab("Visuals", Icons.eye)
window:Divider()
local settingsTab = window:Tab("Settings", Icons.settings)

-- ============================================================================
--  4. AIMBOT TAB – LEFT COLUMN SECTIONS
-- ============================================================================

-- 4.1 Video section (Left)
local videoSection = aimbotTab:Section({ Name = "Video", Side = "Left" })
local videoPlayer = videoSection:Video({
	VideoId = "rbxassetid://5670794788",
	Loop = true,
	Height = 70,
})

-- 4.2 Main Toggles (Left)
local toggleSection = aimbotTab:Section({ Name = "Main Toggles", Side = "Left" })
local enableAimbotToggle = toggleSection:Toggle({
	Name = "Enable Aimbot",
	Default = true,
	Callback = function(state) print("[Aimbot] Toggle:", state) end
})
local dangerousToggle = toggleSection:Toggle({
	Name = "Dangerous Toggle",
	Default = false,
	Confirm = {
		Enabled = true,
		Title = "Warning!",
		Description = "This feature may cause performance issues. Are you sure you want to <font color=\"rgb(255,0,0)\">enable</font> it?",
		TitleColor = Color3.fromRGB(255, 100, 100),
		ConfirmText = "Yes, enable it",
		CancelText = "No, cancel",
	},
	Callback = function(state)
		print("[Aimbot] Dangerous toggle changed to:", state)
	end
}, showNotification)

local mainTogglesDivider = toggleSection:Divider({ Color = Color3.fromRGB(255, 0, 0) })
local mainTogglesDivider = toggleSection:Divider()

-- 4.3 Adjustments (Left)
local adjustSection = aimbotTab:Section({ Name = "Adjustments", Side = "Left" })
local smoothnessSlider = adjustSection:Slider({
	Name = "Smoothness",
	Min = 0,
	Max = 100,
	Default = 50,
	Precision = 1,
	Callback = function(value) print("[Aimbot] Smoothness:", value) end
})
local aimbotKeybind = adjustSection:Keybind({
	Name = "Aimbot Key",
	Default = "G",
	Callback = function(key) print("[Aimbot] Keybind:", key) end
})
local playerNameInput = adjustSection:TextInput({
	Name = "Player Name",
	Placeholder = "Enter name...",
	Default = "",
	Callback = function(text) print("[Aimbot] Text input:", text) end
})
local statusElement = adjustSection:Status({
	Name = "System Status",
	Entries = {
		{ "info", "All systems nominal", "green" },
		{ "alert", "CPU usage high", "orange" },
		{ "error", "Critical failure", "red" },
		{ "custom", "Custom color", Color3.fromRGB(255, 200, 100) },
	}
})

-- 4.4 Player Stats (Left)
local statsSection = aimbotTab:Section({ Name = "Player Stats", Side = "Left" })
local healthBar = statsSection:ProgressBar({
	Name = "Health",
	MinValue = 0,
	MaxValue = 100,
	Value = 100,
	Color = Color3.fromRGB(255, 50, 50),
	ShowPercentage = true,
	ShowFraction = true,
	Animate = true,
})
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
humanoid.HealthChanged:Connect(function(health)
	healthBar:SetValue(health)
end)
local ammoStepper = statsSection:Stepper({
	Name = "Ammo Count",
	Min = 0,
	Max = 100,
	Default = 30,
	Step = 5,
	Integer = true,
	Callback = function(value)
		print("[Stepper] Ammo set to:", value)
	end
})

-- ============================================================================
--  5. AIMBOT TAB – RIGHT COLUMN SECTIONS
-- ============================================================================

-- 5.1 Right Controls (Right)
local rightControls = aimbotTab:Section({ Name = "Right Controls", Side = "Right" })
local rightToggle = rightControls:Toggle({
	Name = "Right Toggle",
	Default = true,
	Callback = function(state) print("[Aimbot Right] Toggle:", state) end
})
local rightSlider = rightControls:Slider({
	Name = "Right Slider",
	Min = 0,
	Max = 200,
	Default = 100,
	Precision = 0,
	Callback = function(value) print("[Aimbot Right] Slider:", value) end
})
local radioGroup = rightControls:RadioButtonGroup()
local radioA = radioGroup:RadioButton({ Name = "Option A", Default = true, Callback = function() print("[Radio] A selected") end })
local radioB = radioGroup:RadioButton({ Name = "Option B", Callback = function() print("[Radio] B selected") end })
local radioC = radioGroup:RadioButton({ Name = "Option C", Callback = function() print("[Radio] C selected") end })

-- 5.2 Dropdowns (Right)
local dropdownSection = aimbotTab:Section({ Name = "Dropdowns", Side = "Right" })
local dropdownCapped = dropdownSection:Dropdown({
	Name = "Fruit Selection (cap: 2)",
	Items = dropdownItems,
	Default = { "apple", "banana" },
	MaxItemsChoosable = 2,
	Placeholder = "Select fruits...",
	Callback = function(selected)
		local names = {}
		for _, item in ipairs(selected) do table.insert(names, item.name) end
		print("[Dropdown] Selected (cap 2):", table.concat(names, ", "))
	end
}, showDropdown)
local dropdownUncapped = dropdownSection:Dropdown({
	Name = "Fruit Selection (no cap)",
	Items = dropdownItems,
	Default = { "apple" },
	Placeholder = "Select any fruits...",
	Callback = function(selected)
		local names = {}
		for _, item in ipairs(selected) do table.insert(names, item.name) end
		print("[Dropdown] Selected (no cap):", table.concat(names, ", "))
	end
}, showDropdown)

-- 5.3 Misc (Right) – labels and button
local miscSection = aimbotTab:Section({ Name = "Misc", Side = "Right" })
local testButton = miscSection:Button({
	Name = "Test Button",
	Callback = function()
		print("[Button] Clicked!")
		showNotification({
			Title = "Button Clicked",
			Description = "You clicked the test button.",
		})
	end
})
local labelWithContainer = miscSection:Label({
	Text = "Label with container (default)",
})
local plainLabel = miscSection:Label({
	Text = "Plain label (no container)",
	ShowContainer = false,
	ShowStroke = false,
})
local boldLabel = miscSection:Label({
	Text = "Bold label (with container)",
	FontWeight = "Bold",
})

-- ============================================================================
--  6. VISUALS TAB – SECTIONS & COMPONENTS
-- ============================================================================
local visualSection = visualsTab:Section({ Name = "Visual Settings", Side = "Left" })
local visualToggle = visualSection:Toggle({
	Name = "Show Crosshair",
	Default = false,
	Callback = function(state) print("[Visuals] Crosshair:", state) end
})
local visualParagraph = visualSection:Paragraph({
	Title = "Visual Settings",
	Description = "Configure your visual preferences here.\nThis is a multi-line description.",
})
local plainLabel2 = visualSection:Label({
	Text = "Another plain label",
	ShowContainer = false,
	ShowStroke = false,
})

-- 6.15 Notification tests (Left)
local notifSection = visualsTab:Section({ Name = "Notifications", Side = "Left" })
notifSection:Button({
	Name = "Alert",
	Callback = function()
		window:Alert({
			Title = "Alert",
			Description = "This is an alert notification.",
			Duration = 4,
		})
	end,
})
notifSection:Button({
	Name = "Error",
	Callback = function()
		window:Error({
			Title = "Error",
			Description = "Something went wrong.",
			Duration = 4,
		})
	end,
})
notifSection:Button({
	Name = "Variable (success)",
	Callback = function()
		window:VariableNotification({
			Title = "Changes saved!",
			Description = "Your settings have been saved successfully.",
			Duration = 5,
			ShowBackground = true,
		})
	end,
})
notifSection:Button({
	Name = "Variable (custom + actions)",
	Callback = function()
		window:VariableNotification({
			Title = "New update available",
			Description = "Version 2.0 is ready to install.",
			Duration = 8,
			Icon = "rbxassetid://8445470559",
			IconColor = Color3.fromRGB(96, 165, 250),
			GradientColor = Color3.fromRGB(139, 92, 246),
			ShowBackground = true,
			Actions = {
				{ Text = "Install", Callback = function() print("[Notif] Install") end },
				{ Text = "Later", Callback = function() print("[Notif] Later") end }
			},
		})
	end,
})

-- 6.2 Color Settings (Right)
local colorSection = visualsTab:Section({ Name = "Color Settings", Side = "Right" })
local crosshairColor = colorSection:ColorPicker({
	Name = "Crosshair Color",
	Default = Color3.fromRGB(255, 0, 0),
	Callback = function(value) print("[Visuals] Crosshair color:", value) end
}, showColorPicker)

-- ============================================================================
--  7. SETTINGS TAB – theme switcher
-- ============================================================================
local settingsSection = settingsTab:Section({ Name = "General", Side = "Left" })

-- Theme switcher (right column)
local themeSection = settingsTab:Section({ Name = "Themes", Side = "Right" })
local themeItems = {
	{ name = "Default", value = "Default" },
	{ name = "Black", value = "Black" },
	{ name = "Light", value = "Light" },
	{ name = "Midnight", value = "Midnight" },
	{ name = "Graphite", value = "Graphite" },
	{ name = "Pearl", value = "Pearl" },
	{ name = "Slate", value = "Slate" },
}
local themeDropdown = themeSection:Dropdown({
	Name = "Theme",
	Items = themeItems,
	Default = { "Black" }, -- matches the initial theme set in CreateWindow
	MaxItemsChoosable = 1, -- limit to single selection
	Placeholder = "Select theme...",
	Callback = function(selected)
		if selected and #selected > 0 then
			local themeName = selected[1].value
			window:SetTheme(themeName)
			print("[Settings] Theme changed to:", themeName)
		end
	end
}, showDropdown)

-- ============================================================================
--  8. SUMMARY & STARTUP LOG
-- ============================================================================
print("[Aetheris_Test] Window created, tabs: Aimbot, Visuals, Settings")
print("[Aetheris_Test] Active tab: " .. window.TabGroup.ActiveTab.Name)
print("[Aetheris_Test] Components: Toggle, Slider, Keybind, TextInput, Status, Radio, Video, Dropdown, ProgressBar, Stepper, Button, Label, Paragraph, ColorPicker")
print("[Aetheris_Test] Labels now support FontWeight option (Regular, Medium, SemiBold, Bold, Heavy, ExtraBold).")
print("[Aetheris_Test] Click the dangerous toggle to see a confirmation notification.")
print("[Aetheris_Test] Health bar is linked to your player's health.")
print("[Aetheris_Test] Click the Crosshair Color picker to open the color picker popup.")
print("[Aetheris_Test] Each section has <=5 components and all are stored in local variables.")

-- ============================================================================
--  9. OPTIONAL: AUTO-DESTROY AFTER 5 SECONDS (uncomment to test)
-- ============================================================================
-- task.wait(5)
-- window:Destroy()
