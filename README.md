<p align="center">
  <img src="assets/banner rectangular.png" alt="Aetheris" width="100%" />
</p>

<p align="center">
  <a href="https://github.com/Saint0-0/Aetheris/releases/latest"><img src="https://img.shields.io/github/v/release/Saint0-0/Aetheris?include_prereleases&label=release" alt="Latest release" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MPL--2.0-blue" alt="License: MPL-2.0" /></a>
  <a href="https://dsc.gg/saintx"><img src="https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white" alt="Discord" /></a>
</p>

Aetheris is a UI library for Roblox with a clean, modern look, inspired by WinUI3, maclib and Fluent. Everything is built at runtime with `Instance.new` - there is nothing to import or pre-build, the whole interface comes from code.

## Download

**[Latest release ->](https://github.com/Saint0-0/Aetheris/releases/latest)**

Two files are attached to each release:

- **Aetheris.luau** - the single-file build, load it with `loadstring`.
- **Aetheris.rbxm** - a Roblox model (an `Aetheris` folder holding an `Init` ModuleScript). Drop it into `ReplicatedStorage` and require `Aetheris.Init`.

## Quick start

```lua
local Aetheris = loadstring(game:HttpGet("https://github.com/Saint0-0/Aetheris/releases/latest/download/Aetheris.luau"))()

local window = Aetheris:CreateWindow({
	Title = "My Script",
	Theme = "Umbral",
	MinimizeKey = "LeftControl", -- press to minimize / restore
})

local home = window:Tab("Home", Aetheris.Icons.home)
local section = home:Section({ Name = "Combat" })

section:Toggle({
	Name = "Auto farm",
	Default = false,
	Callback = function(on)
		print("toggled", on)
	end,
})

section:Slider({
	Name = "Walk speed",
	Min = 16,
	Max = 100,
	Default = 16,
	Precision = 1,
	Callback = function(value) end,
})

section:Button({ Name = "Reset", Callback = function() end })

window:Toast({ Title = "Ready", Description = "Everything loaded.", Duration = 4 })
```

## What's inside

**Window** - tabs and sections with optional left/right columns, sidebar search that filters the active page, compact mode (sidebar collapses into a pill row), a minimize pill with per-tab buttons and tooltips, drag, resize, maximize, tag pills, sounds, and live theme switching with `window:SetTheme("Nocturne")`.

**Components** - Button, Toggle, Slider, Stepper, Keybind, TextInput, Dropdown, ColorPicker, RadioButton / RadioButtonGroup, Label, Paragraph, Divider, Status, ProgressBar, ValueReadout, LiveStat, Console, CodeView, Video, Viewport.

**Notifications** - self-dismissing toasts via `window:Alert()` / `window:Error()` / `window:Toast()` (with action buttons), and modal confirm dialogs via `window:UINotification()`.

**Key system** - optional gate in `CreateWindow` with a loading screen. Supports static keys, Platoboost and panda auth, per-place key saving, and a Discord card with live member counts:

```lua
KeySystem = {
	API = {
		{ Type = "platoboost", ServiceId = "...", Secret = "...", Link = "https://example.com/getkey" },
	},
	SaveKey = true,
}
```

**Theming** - 40 built-in themes, every component repaints live on switch. Custom themes merge over `Base`, so one key is enough to restyle everything. `Aetheris.SetAuroraTexture(id)` swaps the window glow.

**Extras** - per-game config manager, saved user settings (theme, font, volume, pill position), custom settings pages, custom font families, UI scale, and `AETHERIS_SECUREMODE` for hidden `gethui`/CoreGui parenting with UUID-renamed instances.

## Documentation

Setup, theming, the component API and examples all live in the docs:

**[Aetheris documentation ->](https://saint-3.gitbook.io/aetheris)**

A full component showcase ships in this repo: [`example/Aetheris_Test.client.luau`](example/Aetheris_Test.client.luau).

## Credits

- **WinUI3** by Microsoft, for the visual language Aetheris is built around.
- **[maclib](https://brady-xyz.gitbook.io/maclib-ui-library)** by brady-xyz, for inspiration.
- **[Fluent](https://github.com/dawid-scripts/Fluent)** by dawid-scripts, for inspiration, and for the build tooling.
- **[RayField Gen-2](https://github.com/SiriusSoftwareLtd/rayfield-gen2)** by Shlex, for inspiration (Live Stat Element and Compact Mode)

## License

MPL-2.0 - see [LICENSE](LICENSE) or <https://mozilla.org/MPL/2.0/>.

Copyright (c) 2026 Saint0-0
