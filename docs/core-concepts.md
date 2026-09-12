# Core Concepts

Aetheris is organised around four things: the **window**, **tabs**, **sections**, and **components**. Once that hierarchy clicks, everything else is just options on the individual pieces.

## The hierarchy

```
Window
 └─ Tab
     └─ Section
         └─ Component
```

- A **Window** is the whole UI shell — title bar, sidebar, content area and settings pages.
- A **Tab** is a page in the sidebar. Each tab owns its own content area.
- A **Section** is a card inside a tab's column. It groups related components.
- A **Component** is a single control (toggle, slider, button, and so on).

## Window

Created once with `Aetheris:CreateWindow(settings)`. The settings control the title, description, starting theme, the minimize keybind, and which pages show up in the settings tab.

```lua
local window = Aetheris:CreateWindow({
    Title = "Aetheris",
    Description = "v1.0",
    Theme = "Default",
    AnimationStyle = "Smooth",
    DragStyle = "Smooth",
    MinimizeKey = "LeftControl",
    SettingsPages = {
        { Name = "Keybinds", Icon = Aetheris.Icons["keyboard"] },
    },
    DefaultSettingsPage = "Themes",
})
```

## Tabs

Add a tab with `window:Tab(name, icon)`. A `window:Divider()` puts a separator in the sidebar between groups of tabs.

```lua
local main = window:Tab("Main", Aetheris.Icons["home"])
window:Divider()
local settings = window:Tab("Settings", Aetheris.Icons["settings"])
```

## Sections

A section is created on a tab, and you pick which column it sits in (`"Left"` or `"Right"`).

```lua
local section = main:Section({ Name = "Combat", Side = "Left" })
```

## Components

Every component is a method on a section. They all follow the same shape — a settings table with a `Name` and a `Callback` at minimum.

```lua
section:Toggle({
    Name = "Enable Aimbot",
    Default = true,
    Callback = function(state) print(state) end,
})
```

See the **Components** section of the docs for each one's full options.
