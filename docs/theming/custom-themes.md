# Custom Themes

A theme is just a table of keys that override the defaults. `GetTheme` merges any theme over `Default`, so you only need to specify what you want to change.

## Writing one

```lua
local MyTheme = {
    WindowColor = Color3.fromRGB(20, 20, 28),
    SidebarColor = Color3.fromRGB(28, 28, 38),
    PrimaryColor = Color3.fromRGB(140, 120, 255),
    AccentColor = Color3.fromRGB(160, 140, 255),
    -- ...any other keys; the rest fall back to Default
}
```

## Applying it

Pass the table straight to `SetTheme` — it accepts a name or a table:

```lua
window:SetTheme(MyTheme)
```

## Keys

The full set of theme keys covers the window, sidebar, components, text, tabs, sections, search bar and popups. See the source `src/Themes/ThemeDefinitions.luau` for the complete list and what each key affects.
