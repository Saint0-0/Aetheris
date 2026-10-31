# Quick Start

Load the library, create a window, add a tab and a section, then put components in it. That is the whole shape of an Aetheris script.

## Load

Grab `Aetheris.luau` from the [latest release](https://github.com/Saint0-0/Aetheris/releases/latest) and run it:

```lua
local Aetheris = loadstring(game:HttpGet("https://github.com/Saint0-0/Aetheris/releases/latest/download/Aetheris.luau"))()
```

In Studio, drop the `Aetheris.rbxm` model into `ReplicatedStorage` instead and use `require(ReplicatedStorage.Aetheris.Init)`.

## Your first window

```lua
local window = Aetheris:CreateWindow({
	Title = "My Script",
	Theme = "Umbral",
	MinimizeKey = "LeftControl",
})

local home = window:Tab("Home", Aetheris.Icons.house)
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

section:Button({
	Name = "Reset",
	Callback = function() end,
})
```

`CreateWindow` waits for the optional key system and loading screen before it builds, so everything after it runs with the window already on screen.

## A few things worth knowing

- Icons are a table of asset ids: `Aetheris.Icons.home`, `Aetheris.Icons.sliders-horizontal`, and so on. Pass a raw `rbxassetid://` string if you want your own.
- Sections take `Side = "Left"` (default) or `Side = "Right"` to fill two columns.
- `window:SetTheme("Gruvbox")` repaints everything live, mid-session.
- `window:Toast({ Title = "Ready" })` shows a small self-dismissing message.

From here, [Core Concepts](core-concepts.md) explains how the window, tabs and sections fit together, and [Components](components.md) covers every row you can add.
