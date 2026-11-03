# Core Concepts

Four ideas: the window, tabs, sections, and the theme that paints all of them.

## Window

`Aetheris:CreateWindow(settings)` builds everything at runtime with `Instance.new` and returns one object that owns the gui, the settings store and the popups. Nothing is pre-built, so there are no image assets to import beyond the icon ids.

```lua
local window = Aetheris:CreateWindow({ Title = "My Script" })
```

## Tabs

Tabs are the sidebar entries. Each one is a page with its own sections and its own search filter.

```lua
local home = window:Tab("Home", Aetheris.Icons.house)
local combat = window:Tab("Combat", Aetheris.Icons.swords)
window:Divider() -- thin separator between tabs
```

The first tab opens active. Pass `Active = true` to pick a different starting tab.

## Sections

A section is the card inside a tab that holds your components. Tabs have two columns, so a section takes `Side = "Left"` (default) or `"Right"`.

```lua
local section = home:Section({ Name = "Combat" })
```

Sections can opt out of config saving with `NoSave = true`, which is what the settings pages do so game configs never capture UI state.

## Components

Rows go into sections: toggles, sliders, keybinds, dropdowns, and the rest. See [Components](components.md) for the full list with options and methods.

```lua
section:Toggle({ Name = "Auto farm", Callback = function(on) end })
```

Two shared rules hold everywhere:

- Every component exposes `:SetName()`, `:SetVisible()`, `:GetVisible()` and `:Destroy()`.
- Values you set in code and values the player changes both live in memory. Window-level settings (theme, scale, volume) persist between sessions; per-component values do not persist yet.

## Themes

One theme table drives the whole window. Changing it repaints every component with a colour fade instead of a rebuild.

```lua
window:SetTheme("Gruvbox")
```

Custom themes merge over `Base`, so you only define the keys you want to change. See [Theming](theming.md).

## The rest

- [Window](window.md) for the frame, its options and methods.
- [Popups & Notifications](popups-and-notifications.md) for toasts, dialogs and tooltips.
- [Utilities](utilities.md) for the modules underneath: tween, sound, icons, odometer.
- [API Reference](api-reference.md) for what `require`ing Aetheris exposes.
