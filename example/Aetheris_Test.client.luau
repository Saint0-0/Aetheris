--[[
============================================================================
  Aetheris  ·  Full Component Demo  (example/Aetheris_Test.client.luau)
============================================================================

  A living showcase of the ENTIRE Aetheris UI library. Every element the
  library exposes is created at least once here.

  What it demonstrates
  --------------------
    Window API : CreateWindow, :Tab, :Divider, :SetTheme, :Alert, :Error,
                 :Toast, :UINotification, :DropdownPopUp,
                 :ColorPickerPopUp, :Destroy
    Layout     : Tabs, Left/Right Sections
    Components : Toggle, Slider, Keybind, TextInput, Stepper, RadioButtonGroup
                 (+ RadioButton), Dropdown, ColorPicker, Status, ProgressBar,
                 Button, Label, Paragraph, Divider, Video, LiveStat, Console,
                 CodeView, DataTable, Graph
    Security   : AETHERIS_SECUREMODE (gethui/CoreGui parenting + UUID rename)
    API        : SetName, SetVisible/GetVisible, Destroy,
                 and Status:AddEntry/SetEntry/SetEntries

  How to run
  ----------
    Drop this LocalScript into StarterPlayerScripts, or paste it into the
    command bar while the game is running. No pre-built assets required.
============================================================================
]]

-- == 0. LIBRARY BOOTSTRAP ==================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Aetheris = require(ReplicatedStorage:WaitForChild("Aetheris").Init, 5)
	or loadstring(game:HttpGet("https://github.com/Saint0-0/Aetheris/releases/latest/download/Aetheris.luau"))()
local Icons = Aetheris.Icons

-- A missing icon key falls back to the crosshair icon so a typo'd name can't crash the demo.
local function ico(name)
	return Icons[name] or Icons.crosshair
end

-- Grab the local player's humanoid so the Health ProgressBar can bind to real health changes.
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- == 1. CREATE THE MAIN WINDOW =============================================
-- CreateWindow is the preferred entry point; the theme name sets the starting theme.
-- The aurora behind the window uses the glow texture in Constants.AuroraGlow (tinted
-- per theme) - swap in your own neutral glow PNG, or pass nil for the fallback:
-- Aetheris.SetAuroraTexture("rbxassetid://0")
local window = Aetheris:CreateWindow({
	Title = "Aetheris",
	-- Up to 3 tag pills under the description. A plain string uses theme colours; a
	-- table pins explicit colours, override-locked so theme switches leave them alone.
	Tags = {
		{
			Name = "v0.2.0",
			BackgroundColor = Color3.fromRGB(217, 119, 6),
			TextColor = Color3.fromRGB(255, 255, 255),
			AccentColor = Color3.fromRGB(255, 221, 109),
		},
		{
			Name = "build",
			BackgroundColor = Color3.fromRGB(9, 52, 145),
			TextColor = Color3.fromRGB(255, 255, 255),
			AccentColor = Color3.fromRGB(167, 206, 255),
		},
		{
			Name = "DEMO",
			BackgroundColor = Color3.fromRGB(6, 119, 47),
			TextColor = Color3.fromRGB(255, 255, 255),
			AccentColor = Color3.fromRGB(149, 255, 188),
		},
	},
	Theme = "Linen", -- any name from ThemeDefinitions ("Default" still aliases the launch theme)
	-- Shown in the changelog popup; the stored ChangelogVersion decides whether
	-- the popup auto-opens (it stamps itself the first time it actually shows).
	Version = "1.2.0",
	Changelog = {
		-- Optional per entry: Icon (Icons key) and Tint
		-- (blue/purple/teal/orange/red/yellow); entries cycle tints when omitted.
		{
			Title = "Example changelog",
			Description = "This list is the script's own release notes. Leave Version and Changelog out to skip the popup entirely.",
			Icon = "rocket",
			Tint = "purple",
		},
		{
			Title = "Icons and tints",
			Description = "Every entry takes an optional Icon key and Tint name; without them the popup cycles through the tints.",
			Icon = "sparkles",
			Tint = "teal",
		},
	},
	AnimationStyle = "Smooth", -- "Smooth" | "Snappy"
	DragStyle = "Smooth", -- "Smooth" (glides) | "Instant" (snaps)
	MinimizeKey = "LeftControl",
	AETHERIS_SECUREMODE = false, -- true parents via gethui/CoreGui and renames to a UUID
	KeySystem = {
		-- "stub" accepts anything in Keys (or any key if Keys is omitted). Swap in a real
		-- service (platoboost/panda + ServiceId), or add Key = "MYKEY" for a static key.
		API = {
			{ Type = "stub", Keys = { "TEST" }, Link = "https://example.com/getkey" },
		},
		SaveKey = true,
		-- Discord = "https://discord.gg/invite", -- copy-link card on the key screen
		-- Discord = { Link = "https://discord.gg/invite", Id = "123456789" }, -- + live counts
	},
	SettingsPages = { -- extra pages shown in the Settings tab
		{
			Name = "Keybinds",
			Icon = ico("keyboard"),
			-- Dummy content exercising the custom-page pipeline. NOTE: Build runs DURING
			-- CreateWindow, so it can't use popup helpers (openDropdown, notify...) defined later.
			Build = function(window, tab)
				local move = tab:Section({ Name = "Movement" })
				move:Keybind({ Name = "Jump", Default = "Space", Callback = function() end })
				move:Keybind({ Name = "Crouch", Default = "LeftControl", Callback = function() end })
				move:Keybind({ Name = "Sprint", Default = "LeftShift", Callback = function() end })

				move:Divider({ Padding = 10 })
				move:Toggle({ Name = "Toggle Sprint", Default = false, Callback = function() end })

				local combat = tab:Section({ Name = "Combat" })
				combat:Keybind({ Name = "Aim", Default = "Q", Callback = function() end })
				combat:Keybind({ Name = "Reload", Default = "R", Callback = function() end })
				combat:Label({
					Text = "Dummy keybind page built via the Build callback.",
					ShowContainer = false,
					ShowStroke = false,
				})
			end,
		},
		{
			Name = "Macros",
			Icon = ico("mouse-pointer-click"),
			Build = function(window, tab)
				local list = tab:Section({ Name = "Recorded Macros" })
				list:Paragraph({
					Title = "Macros",
					Description = "Sample custom settings page. Everything here is a real Aetheris component, stacked in one column.",
				})
				list:Divider({ Padding = 10 })
				list:Label({
					Text = "No macros recorded yet.",
					FontWeight = "SemiBold",
					ShowContainer = false,
					ShowStroke = false,
				})

				local timing = tab:Section({ Name = "Timing" })
				timing:Slider({
					Name = "Loop Delay",
					Min = 0,
					Max = 100,
					Default = 25,
					Precision = 0,
					Callback = function() end,
				})
				timing:Stepper({
					Name = "Repeat Count",
					Min = 1,
					Max = 50,
					Default = 5,
					Step = 1,
					Integer = true,
					Callback = function() end,
				})
				timing:Toggle({ Name = "Loop Forever", Default = true, Callback = function() end })
				timing:Button({
					Name = "Record Macro",
					Callback = function()
						print("[Demo] Record Macro")
					end,
				})
			end,
		},
	},
	DefaultSettingsPage = "Themes",
})

-- == 2. CREATE THE TABS ====================================================
-- window:Tab(name, icon) adds a sidebar page; window:Divider() adds a thin separator.
local homeTab = window:Tab("Home", ico("home"))
local controlsTab = window:Tab("Controls", ico("sliders-horizontal"))
local inputsTab = window:Tab("Inputs", ico("list"))
local feedbackTab = window:Tab("Feedback", ico("bell"))
local mediaTab = window:Tab("Media", ico("play"))
local statsTab = window:Tab("Stats", ico("chart-line"))
window:Divider()
local settingsTab = window:Tab("Settings", ico("settings"))
-- Deliberately more tabs than fit: the minimize pill scrolls past seven, and
-- these prove the hover-scaled buttons no longer clip at the strip edges.
local farmTab = window:Tab("Farm", ico("sprout"))
local followTab = window:Tab("Follow", ico("users"))
local spotsTab = window:Tab("Spots", ico("map-pin"))
local extraTab = window:Tab("Extra", ico("box"))

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

heroSection:Label({
	Text = "Bold label with container",
	FontWeight = "Bold",
})

heroSection:Divider({ Color = Color3.fromRGB(108, 140, 255) })

local actionSection = homeTab:Section({ Name = "Actions", Side = "Right" })

actionSection:Button({
	Name = "Do The Thing",
	Callback = function()
		print("[Demo] Button clicked")
	end,
})

-- A button that fires the full UINotification modal (confirm/cancel dialog).
actionSection:Button({
	Name = "Open UINotification",
	Callback = function()
		window:UINotification({
			Title = "Delete Save?",
			Description = "This action cannot be undone.",
			ConfirmText = "Delete",
			CancelText = "Keep",
			OnConfirm = function()
				print("[Demo] UINotification confirmed")
			end,
			OnCancel = function()
				print("[Demo] UINotification cancelled")
			end,
		})
	end,
})

actionSection:Button({
	Name = "Send a toast",
	Callback = function()
		window:Toast({
			Title = "Hello!",
			Description = "This is a variable notification with an action.",
			Duration = 6,
			ShowBackground = true,
			Actions = {
				{
					Text = "Nice",
					Callback = function()
						print("[Demo] toast action")
					end,
				},
			},
		})
	end,
})

-- =========================================================================
--  3a. SECURE MODE / COMPONENT API
-- =========================================================================
-- Every component shares the same public surface:
--   SetName      - change the displayed label
--   SetVisible   - show or hide the component's root
--   GetVisible   - current visibility
--   Destroy      - tear the component down
-- Status also exposes per-entry updates: AddEntry / SetEntry / SetEntries.
local apiSection = homeTab:Section({ Name = "Secure Mode / API", Side = "Right" })

local apiLabel = apiSection:Label({
	Text = "API target - drive me with the buttons",
	ShowContainer = false,
	ShowStroke = false,
})

local apiStatus = apiSection:Status({
	Name = "Live status",
	Entries = {
		{ "info", "Ready", "green" },
	},
})

apiSection:Button({
	Name = "Rename (SetName)",
	Callback = function()
		apiLabel:SetName("SetName @ " .. os.date("%H:%M:%S"))
	end,
})

apiSection:Button({
	Name = "Hide / Show (SetVisible)",
	Callback = function()
		apiLabel:SetVisible(not apiLabel:GetVisible())
	end,
})

apiSection:Button({
	Name = "Append entry (Status:AddEntry)",
	Callback = function()
		apiStatus:AddEntry("info", "Hi again @ " .. os.date("%H:%M:%S"), "green")
	end,
})

apiSection:Button({
	Name = "Update entry + colour (Status:SetEntry)",
	Callback = function()
		local flipping = apiStatus:GetEntry("info") ~= nil and apiStatus:GetEntry("info"):find("nominal") ~= nil
		if flipping then
			apiStatus:SetEntry("info", "CPU usage high", "orange")
		else
			apiStatus:SetEntry("info", "All systems nominal", "green")
		end
	end,
})

apiSection:Button({
	Name = "Destroy label (Destroy)",
	Callback = function()
		apiLabel:Destroy()
	end,
})

-- =========================================================================
--  3b. STATS TAB  -  LiveStat readouts (left) + the buttons that drive them (right)
-- =========================================================================
-- LiveStat shows ONE number driven via :Set(number). Two shapes: Size = "Full" (90px
-- card) or "Compact" (41px row). Its accent spin auto-pauses off-screen like the sliders.

local statSection = statsTab:Section({ Name = "Readouts", Side = "Left" })

local scoreStat = statSection:LiveStat({
	Name = "Score",
	Size = "Full",
	Icon = ico("trophy"),
	Value = 100,
})

local timeStat = statSection:LiveStat({
	Name = "Time",
	Size = "Compact",
	Icon = ico("clock"),
	Suffix = "s",
	Value = 0,
})

local statControls = statsTab:Section({ Name = "Controls", Side = "Right" })

-- Driving the value up vs down shows the count-up roll and accent direction change.
statControls:Button({
	Name = "Set Score = 100",
	Callback = function()
		scoreStat:Set(100)
	end,
})
statControls:Button({
	Name = "Set Score = 2500",
	Callback = function()
		scoreStat:Set(2500)
	end,
})
statControls:Button({
	Name = "Set Score = 40",
	Callback = function()
		scoreStat:Set(40)
	end,
})
statControls:Button({
	Name = "Tick Time",
	Callback = function()
		timeStat:Set(timeStat:Get() + 1)
	end,
})

-- =========================================================================
--  3c. DATA TABLE + GRAPH  -  live rows and a streaming line graph
-- =========================================================================
-- DataTable columns are weighted, never fixed-width: Weight 1 means an equal
-- share of the row, 2 twice the share. There is no Width option by design.
local tableSection = statsTab:Section({ Name = "Live Data", Side = "Left" })

local STATUS_COLORS = {
	Farming = Color3.fromRGB(74, 200, 120),
	Idle = Color3.fromRGB(200, 200, 200),
	Trade = Color3.fromRGB(96, 165, 250),
}

local demoTable = tableSection:DataTable({
	Name = "Tracked Players",
	MaxRows = 6, -- viewport caps at six rows; the body scrolls past that
	SortBy = "Score", -- sort live: UpdateRow re-sorts automatically
	SortDescending = true,
	Columns = {
		{ Key = "Name", Label = "PLAYER", Weight = 2 },
		{ Key = "Score", Label = "SCORE", Weight = 1.4, Align = "right", Format = "number" },
		{
			Key = "Ping",
			Label = "PING",
			Weight = 1,
			Align = "right",
			Format = function(value)
				return tostring(math.floor(value + 0.5)) .. " ms"
			end,
		},
		{
			Key = "Status",
			Label = "STATUS",
			Weight = 1.3,
			Color = function(value)
				return STATUS_COLORS[value] or Color3.fromRGB(200, 200, 200)
			end,
		},
	},
	Action = {
		Label = "Kick",
		Callback = function(id, row)
			demoTable:RemoveRow(id)
			print("[Demo] DataTable kicked", row.Name)
		end,
	},
})

demoTable:SetRows({
	{ id = "alpha", Name = "Alpha", Score = 18450, Ping = 42, Status = "Farming" },
	{ id = "bravo", Name = "Bravo", Score = 9200, Ping = 87, Status = "Idle" },
	{ id = "charlie", Name = "Charlie", Score = 27800, Ping = 31, Status = "Trade" },
	{ id = "delta", Name = "Delta", Score = 5400, Ping = 120, Status = "Farming" },
	{ id = "echo", Name = "Echo", Score = 15100, Ping = 65, Status = "Idle" },
	{ id = "foxtrot", Name = "Foxtrot", Score = 7300, Ping = 98, Status = "Trade" },
})

local tableControls = statsTab:Section({ Name = "Data Controls", Side = "Right" })

tableControls:Button({
	Name = "Bump every score",
	Callback = function()
		for _, row in ipairs(demoTable:GetRows()) do
			-- UpdateRow patches fields and re-sorts against the active SortBy.
			demoTable:UpdateRow(row._id, { Score = row.Score + math.random(500, 4000) })
		end
	end,
})

tableControls:Button({
	Name = "Add a row",
	Callback = function()
		local id = "row_" .. tostring(os.clock())
		local statuses = { "Farming", "Idle", "Trade" }
		demoTable:AddRow({
			id = id,
			Name = "Guest",
			Score = math.random(1000, 20000),
			Ping = math.random(20, 150),
			Status = statuses[math.random(#statuses)],
		})
	end,
})

tableControls:Button({
	Name = "Highlight a row",
	Callback = function()
		local rows = demoTable:GetRows()
		if #rows > 0 then
			local pick = rows[math.random(#rows)]
			if demoTable:GetRowColor(pick._id) then
				demoTable:SetRowColor(pick._id, nil)
			else
				demoTable:SetRowColor(pick._id, Color3.fromRGB(96, 165, 250))
			end
		end
	end,
})

tableControls:Button({
	Name = "Sort by ping",
	Callback = function()
		local key, descending = demoTable:GetSort()
		local nextDescending = (key == "Ping") and not descending or false
		demoTable:SetSort("Ping", nextDescending)
	end,
})

-- Graph draws straight line segments (no bars) and interpolates between the
-- old and new values on every Push, so a live feed animates smoothly.
local graphSection = statsTab:Section({ Name = "Graph", Side = "Right" })

local graphSeed = {}
for index = 1, 18 do
	graphSeed[index] = 45 + math.sin(index * 0.55) * 18 + (index % 4) * 2
end

local demoGraph = graphSection:Graph({
	Name = "Throughput",
	Height = 130,
	MaxPoints = 40,
	Format = "number",
	Points = graphSeed,
})

local graphPaused = false
local graphTick = 0
local graphThread = task.spawn(function()
	while true do
		task.wait(1)
		if not graphPaused then
			graphTick += 1
			demoGraph:Push(50 + math.sin(graphTick * 0.4) * 25 + math.noise(graphTick * 0.3) * 14)
		end
	end
end)

graphSection:Button({
	Name = "Push spike",
	Callback = function()
		demoGraph:Push(165)
	end,
})

graphSection:Button({
	Name = "Pause / resume feed",
	Callback = function()
		graphPaused = not graphPaused
		print("[Demo] Graph feed paused:", graphPaused)
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
	Callback = function(state)
		print("[Demo] Toggle:", state)
	end,
})

-- Toggle with a confirmation prompt: when Confirm.Enabled, flipping the switch shows a modal.
switchSection:Toggle({
	Name = "Dangerous Toggle",
	Default = false,
	Confirm = {
		Enabled = true,
		Title = "Are you sure?",
		Description = 'This may cause <font color="#FF5555">performance issues</font>. Continue?',
		TitleColor = Color3.fromRGB(255, 100, 100),
		ConfirmText = "Yes, enable it",
		CancelText = "No, cancel",
	},
	Callback = function(state)
		print("[Demo] Dangerous toggle:", state)
	end,
})

local valueSection = controlsTab:Section({ Name = "Values", Side = "Left" })

-- Slider: numeric range. Precision = decimal places shown/stored.
valueSection:Slider({
	Name = "Smoothness",
	Min = 0,
	Max = 100,
	Default = 50,
	Precision = 1,
	Callback = function(v)
		print("[Demo] Slider:", v)
	end,
})

-- Stepper: an odometer value reel with +/- buttons; click the field to type a value.
-- Integer forces whole numbers, Step is the click increment.
valueSection:Stepper({
	Name = "Ammo Count",
	Min = 0,
	Max = 100,
	Default = 30,
	Step = 5,
	Integer = true,
	Callback = function(v)
		print("[Demo] Stepper:", v)
	end,
})

local textSection = controlsTab:Section({ Name = "Text", Side = "Right" })

-- Keybind: capture a keyboard key. Default is the starting key ("G").
textSection:Keybind({
	Name = "Primary Key",
	Default = "G",
	Callback = function(key)
		print("[Demo] Keybind:", key)
	end,
})

-- TextInput: free-form single-line text with a placeholder.
textSection:TextInput({
	Name = "Player Name",
	Placeholder = "Enter a name...",
	Default = "",
	Callback = function(text)
		print("[Demo] TextInput:", text)
	end,
})

-- RadioButtonGroup: mutually-exclusive choices - create the group, then add RadioButtons to it.
local choiceSection = controlsTab:Section({ Name = "Choices", Side = "Right" })
local radioGroup = choiceSection:RadioButtonGroup()
radioGroup:RadioButton({
	Name = "Option A",
	Default = true,
	Callback = function()
		print("[Demo] Radio A")
	end,
})
radioGroup:RadioButton({
	Name = "Option B",
	Callback = function()
		print("[Demo] Radio B")
	end,
})
radioGroup:RadioButton({
	Name = "Option C",
	Callback = function()
		print("[Demo] Radio C")
	end,
})

-- =========================================================================
--  5. INPUTS TAB  -  Dropdown, ColorPicker
-- =========================================================================
local dropdownItems = {
	{ name = "Apple", icon = ico("apple"), value = "apple" },
	{ name = "Banana", icon = ico("banana"), value = "banana" },
	{ name = "Orange", icon = ico("orange"), value = "orange" },
	{ name = "Grapes", icon = ico("grapes"), value = "grapes" },
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
		if selected[1] then
			print("[Demo] Dropdown (single):", selected[1].name)
		end
	end,
})

dropSection:Dropdown({
	Name = "Snack Selection (max 2)",
	Items = dropdownItems,
	Default = { "apple", "banana" },
	MaxItemsChoosable = 2,
	Placeholder = "Pick up to two...",
	Callback = function(selected)
		local names = {}
		for _, item in ipairs(selected) do
			table.insert(names, item.name)
		end
		print("[Demo] Dropdown (multi):", table.concat(names, ", "))
	end,
})

-- Dropdown, uncapped multi-select (omit MaxItemsChoosable).
dropSection:Dropdown({
	Name = "Fruit Salad (any amount)",
	Items = dropdownItems,
	Default = {},
	Placeholder = "Choose freely...",
	Callback = function(selected)
		print("[Demo] Dropdown (uncapped):", #selected, "items")
	end,
})

local colorSection = inputsTab:Section({ Name = "Colors", Side = "Right" })

-- ColorPicker: opens a themed colour-picker popup.
colorSection:ColorPicker({
	Name = "Accent Colour",
	Default = Color3.fromRGB(108, 140, 255),
	Callback = function(color, alpha)
		print("[Demo] ColorPicker:", color, "alpha", alpha)
	end,
})

colorSection:ColorPicker({
	Name = "Crosshair Colour",
	Default = Color3.fromRGB(255, 80, 80),
	Alpha = 180,
	Callback = function(color, alpha)
		print("[Demo] ColorPicker 2:", color, "alpha", alpha)
	end,
})

-- =========================================================================
--  6. FEEDBACK TAB  -  Status, ProgressBar, Notifications, Video
-- =========================================================================
local statusSection = feedbackTab:Section({ Name = "System Status", Side = "Left" })

-- Status: a list of { kind, text, color } entries; color is a name ("green"/"orange"/"red") or Color3.
statusSection:Status({
	Name = "Diagnostics",
	Entries = {
		{ "info", "All systems nominal", "green" },
		{ "alert", "CPU usage high", "orange" },
		{ "error", "Cache miss detected", "red" },
		{ "custom", "Custom-tinted entry", Color3.fromRGB(255, 200, 100) },
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
humanoid.HealthChanged:Connect(function(hp)
	healthBar:SetValue(hp)
end)

progressSection:ProgressBar({
	Name = "Download",
	MinValue = 0,
	MaxValue = 100,
	Value = 42,
	ShowPercentage = true,
	Animate = false,
})

local toastSection = feedbackTab:Section({ Name = "Notifications", Side = "Right" })

toastSection:Button({
	Name = "Alert",
	Callback = function()
		window:Alert({ Title = "Alert", Description = "This is an alert notification.", Duration = 4 })
	end,
})

toastSection:Button({
	Name = "Error",
	Callback = function()
		window:Error({ Title = "Error", Description = "Something went wrong.", Duration = 4 })
	end,
})

toastSection:Button({
	Name = "Rich Toast",
	Callback = function()
		window:Toast({
			Title = "Update available",
			Description = "Version 2.0 is ready to install.",
			Duration = 8,
			Icon = ico("download"),
			IconColor = Color3.fromRGB(96, 165, 250),
			GradientColor = Color3.fromRGB(139, 92, 246),
			ShowBackground = true,
			Actions = {
				{
					Text = "Install",
					Callback = function()
						print("[Demo] Install")
					end,
				},
				{
					Text = "Later",
					Callback = function()
						print("[Demo] Later")
					end,
				},
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

-- Carousel: swipeable image/video pages (drag left/right), hard max 5.
-- Pages auto-advance every 4s (Interval / AutoAdvance = false to change).
-- The blob row tracks the current page — the active blob fills with the
-- video's playback progress (or the dwell countdown for images), off-view
-- videos pause to save decode.
mediaSection:Carousel({
	{ "rbxassetid://92458734285074", "image" },
	{ "rbxassetid://5670794788", "video" },
	{ "rbxassetid://11094025229", "image" },
})

-- Viewport: renders a live character clone; Framing picks the camera crop.
-- Omitting `Info` hides the side labels (viewport centres and widens into the
-- freed space); the health bar hugs the viewport's right edge unless
-- HealthBar = false.
local viewportDemo = mediaSection:Viewport({
	Player = Players.LocalPlayer,
	Rotate = true,
	Framing = "UpperBody",
	Height = 170,
	Info = {
		{ Caption = "USERNAME", Key = "Name" },
		{ Caption = "USER ID", Key = "UserId" },
		{ Caption = "SESSION", Text = "live" },
	},
})

local framingModes = { "Full", "UpperBody", "Torso", "Head" }
local framingIndex = 2

mediaSection:Button({
	Name = "Cycle framing",
	Callback = function()
		framingIndex = framingIndex % #framingModes + 1
		viewportDemo:SetFraming(framingModes[framingIndex])
	end,
})

local orbitOn = true
mediaSection:Button({
	Name = "Toggle rotation",
	Callback = function()
		orbitOn = not orbitOn
		viewportDemo:SetRotate(orbitOn)
	end,
})

mediaSection:Button({
	Name = "Re-bind player (SetPlayer)",
	Callback = function()
		viewportDemo:SetPlayer(Players.LocalPlayer)
	end,
})

-- Three more variants so the card's options are easy to compare.
local viewportVariants = mediaTab:Section({ Name = "Viewport Variants", Side = "Right" })

viewportVariants:Paragraph({
	Title = "Health bar",
	Description = "The bar beside each viewport fills from the bottom and shifts red to yellow to green with the bound character's humanoid health. HealthBar = false drops it entirely.",
})

-- Viewport-only: no `Info` table, so the label column is skipped and the view
-- widens and centres into the freed space. The health bar still hugs its edge.
viewportVariants:Viewport({
	Name = "Viewport only",
	Player = Players.LocalPlayer,
	Framing = "Full",
	Rotate = true,
	Height = 170,
})

-- Static 3/4 head shot, fixed text rows plus a suffixed live value, and no
-- side bar (HealthBar = false).
viewportVariants:Viewport({
	Name = "Static + custom rows",
	Player = Players.LocalPlayer,
	Framing = "Head",
	Rotate = false,
	Height = 150,
	HealthBar = false,
	Info = {
		{ Caption = "USERNAME", Key = "Name" },
		{ Caption = "ACCOUNT AGE", Key = "AccountAge", Suffix = " days" },
		{ Caption = "STATUS", Text = "in lobby" },
	},
})

-- Short card with the default four rows (Name, DisplayName, UserId, AccountAge):
-- an empty `Info` table keeps the standard fields.
viewportVariants:Viewport({
	Name = "Compact card",
	Player = Players.LocalPlayer,
	Framing = "Torso",
	Rotate = true,
	Height = 120,
	Info = {},
})

-- =========================================================================
--  8. SETTINGS TAB  -  live theme switcher
-- =========================================================================
local settingsSection = settingsTab:Section({ Name = "General", Side = "Left" })
settingsSection:Paragraph({
	Title = "Settings",
	Description = "The Settings tab also hosts the Themes card grid that the library builds automatically. Use the dropdown opposite to switch themes live and watch every element crossfade.",
})

-- Re-opens the changelog on demand: the popup only auto-opens once per
-- stored version, so this is how you preview it again while testing.
settingsSection:Button({
	Name = "Show changelog",
	Callback = function()
		if window.Changelog then
			window.Changelog:Show()
		else
			window:Toast({ Title = "Changelog", Description = "No Changelog entries were passed to CreateWindow." })
		end
	end,
})

local themeSection = settingsTab:Section({ Name = "Theme Switcher", Side = "Right" })
-- Build from the live ThemeDefinitions so the list can't go stale; "Base" is the merge fallback, not a theme.
local themeItems = {}
for name in pairs(Aetheris.ThemeDefinitions) do
	if name ~= "Base" then
		table.insert(themeItems, { name = name, value = name })
	end
end
table.sort(themeItems, function(a, b)
	return a.name < b.name
end)

themeSection:Dropdown({
	Name = "Theme",
	Items = themeItems,
	Default = { window._themeName or "Umbral" },
	MaxItemsChoosable = 1,
	Placeholder = "Select theme...",
	Callback = function(selected)
		if selected[1] then
			window:SetTheme(selected[1].value)
			print("[Demo] Theme ->", selected[1].value)
		end
	end,
})

-- =========================================================================
--  8b. CONSOLE  -  monospaced, self-scrolling log block (ported from Rayfield)
-- =========================================================================
-- A Console holds its height and scrolls inside itself so a growing log never pushes
-- the page down. Lines are pooled and recycled in a ring, so Append stays O(1).
local consoleSection = settingsTab:Section({ Name = "Console", Side = "Left" })

local demoConsole = consoleSection:Console({
	Name = "Output",
	Height = 140,
	Follow = true, -- pin to the newest line on Append
	MaxLines = 200, -- oldest lines roll off past this
	Text = "[Aetheris] Console ready.\nWaiting for output...",
	RichText = true, -- let the numbered lines dim the number, not the text
})

local consoleLine = 0
local consoleControls = settingsTab:Section({ Name = "Console Controls", Side = "Right" })

consoleControls:Button({
	Name = "Append a line",
	Callback = function()
		consoleLine += 1
		demoConsole:Append(string.format('<font transparency="0.55">%3d</font>  appended line', consoleLine))
	end,
})

consoleControls:Button({
	Name = "Append 25 lines",
	Callback = function()
		for _ = 1, 25 do
			consoleLine += 1
			demoConsole:Append(string.format('<font transparency="0.55">%3d</font>  burst line', consoleLine))
		end
	end,
})

consoleControls:Button({
	Name = "Set body",
	Callback = function()
		demoConsole:Set("[Aetheris] Body replaced via Set().\nSecond line.\nThird line.")
	end,
})

consoleControls:Button({
	Name = "Clear",
	Callback = function()
		demoConsole:Clear()
		consoleLine = 0
	end,
})

-- =========================================================================
--  8c. CODE VIEW  -  syntax-highlighted block, line numbers, optional editing
-- =========================================================================
-- View mode renders theme-tinted RichText; clicking swaps in a multiline TextBox when
-- Editable (re-highlighted on blur). OnCopy receives the content - wire setclipboard there.
local codeSection = settingsTab:Section({ Name = "CodeView", Side = "Left" })

local demoCode = codeSection:CodeView({
	Name = "Highlighted (view only)",
	Height = 190,
	Language = "lua",
	Text = [==[local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Tracks the local player's respawn and re-applies their loadout.
local function onCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = 16
	print(`spawned: {character.Name}`)
end

local player = Players.LocalPlayer
if player then
	player.CharacterAdded:Connect(onCharacter)
end]==],
	OnCopy = function(content)
		print("[Aetheris Demo] copy requested,", #content, "bytes")
	end,
})

local codeControls = settingsTab:Section({ Name = "CodeView Editable", Side = "Right" })

local demoCodeEdit = codeControls:CodeView({
	Name = "Click the code to edit",
	Height = 190,
	Language = "javascript",
	Editable = true,
	Text = [==[// Debounce a resize handler.
const debounce = (fn, ms = 150) => {
  let timer = null;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), ms);
  };
};

window.addEventListener("resize", debounce(() => {
  console.log("resized", window.innerWidth);
}));]==],
})

codeControls:Button({
	Name = "Replace text (SetText)",
	Callback = function()
		demoCodeEdit:SetText(`// Replaced at ${os.date("%H:%M:%S")}\nprint("edit me");`)
	end,
})

codeControls:Button({
	Name = "Swap language (SetLanguage)",
	Callback = function()
		local nextLang = if demoCodeEdit:GetContent():find("local") then "javascript" else "lua"
		demoCodeEdit:SetLanguage(nextLang)
		print("[Aetheris Demo] language ->", nextLang)
	end,
})

-- =========================================================================
--  8d. EXTRA TABS  -  filler pages that push the sidebar past the pill's fit
-- =========================================================================
-- Four more tabs than the seven the minimize pill shows at once, so the strip
-- always scrolls and the edge-clipping fix is visible at rest and on hover.
local function stubPage(tab, description)
	local section = tab:Section({ Name = tab.Name .. " Page", Side = "Left" })
	section:Paragraph({ Title = tab.Name, Description = description })
	section:Label({ Text = "Placeholder content — this page exists to test pill scrolling." })
end

stubPage(farmTab, "A stand-in farming page. Scroll the sidebar or the minimize pill to reach it.")
stubPage(followTab, "A stand-in follow page, kept clickable so tab switching and fades stay exercised.")
stubPage(spotsTab, "A stand-in teleport-spot page with no live logic behind the controls.")
stubPage(extraTab, "The last filler page; the pill should scroll cleanly to it without clipping.")

-- =========================================================================
--  9. STARTUP LOG
-- =========================================================================
print(
	"[Aetheris Demo] Window built. Tabs: Home, Controls, Inputs, Feedback, Media, Stats, Settings, Farm, Follow, Spots, Extra"
)
print("[Aetheris Demo] Active tab:", window.TabGroup.ActiveTab.Name)
print(
	"[Aetheris Demo] All components exercised: Toggle, Slider, Keybind, TextInput, Stepper, RadioButton(Group), Dropdown, ColorPicker, Status, ProgressBar, Button, Label, Paragraph, Divider, Video, LiveStat, Console, CodeView, DataTable, Graph."
)
print(
	"[Aetheris Demo] Secure mode off (AETHERIS_SECUREMODE = false); Component API: SetName, SetVisible/GetVisible, Destroy, Status:AddEntry."
)

-- =========================================================================
-- 10. OPTIONAL: auto-destroy after 10s (uncomment to test teardown)
-- =========================================================================
-- task.wait(10)
-- window:Destroy()

-- =========================================================================
-- 11. ONDESTROY HOOK — script-side cleanup when the UI closes
-- =========================================================================
-- Stands in for a real loop (autofarm, autosell, ...): it would keep running after the
-- window is gone unless something stops it. Close the window to watch it cancel.
local demoLoopStart = os.clock()
local demoLoopThread = task.spawn(function()
	while true do
		task.wait(1)
		print(string.format("[Aetheris Demo] demo loop alive (%.0fs)", os.clock() - demoLoopStart))
	end
end)

window:OnDestroy(function()
	task.cancel(demoLoopThread)
	task.cancel(graphThread)
	print(string.format("[Aetheris Demo] OnDestroy: demo loop cancelled after %.1fs", os.clock() - demoLoopStart))
end)
