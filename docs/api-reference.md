# API Reference

What requiring Aetheris gives you.

```lua
local Aetheris = loadstring(game:HttpGet("https://github.com/Saint0-0/Aetheris/releases/latest/download/Aetheris.luau"))()
```

Everything hangs off that one table, so day to day work never needs a deep require.

## Facade

| Member | Type | Description |
| --- | --- | --- |
| `Aetheris:CreateWindow(Settings)` | function | Build a window, the entry point for everything else. Returns nil plus a reason when a key system is closed before a key is accepted. |
| `Aetheris.Icons` | table | Lucide icon set, name to `rbxassetid://`. |
| `Aetheris.Window` | table | The Window module itself, for advanced use such as reading `Window.DragStyle`. |
| `Aetheris.ThemeManager` | table | Theme lookup and bindings: `GetTheme`, `ApplyTheme`, `Bind`, `BindColor`, `BindTransparency`, `Unbind`. |
| `Aetheris.ThemeDefinitions` | table | The named theme tables, one entry per theme. |
| `Aetheris.SetAuroraTexture(id)` | function | Point the aurora glow at an uploaded texture. Pass nil to go back to the built in glow. |

## CreateWindow settings

| Key | Type | Description |
| --- | --- | --- |
| `Title` | string | Window title, also used to name the close prompt. |
| `Theme` | string | Theme name, defaults to `Umbral`. A theme saved by the user wins over this. |
| `AnimationStyle` | string | `"Smooth"` (default) or `"Snappy"`, chooses the minimize preset and the close fade. |
| `DragStyle` | string | `"Smooth"` or `"Instant"` (default), how the window follows the mouse. |
| `MinimizeKey` | string | Key that minimizes the window. A single letter is uppercased, anything else must match `Enum.KeyCode.Name`. Defaults to `"M"`. |
| `Tags` | array | Up to 3 pills under the title, as plain strings or `{ Name, BackgroundColor, TextColor, AccentColor }`. |
| `SettingsPages` | array | Extra settings pages, each `{ Name, Icon, Active, Build }`. `Build(window, tab)` fills the page. |
| `DefaultSettingsPage` | string | Settings page that opens first. |
| `KeySystem` | table or `true` | Key card shown before the window opens. |
| `AETHERIS_SECUREMODE` | boolean | Hardened instance naming and parenting, false by default. |
| `ScreenGuiName` | string | Name of the ScreenGui, defaults to `Aetheris`. |
| `DisplayOrder` | number | ScreenGui display order. |
| `IgnoreGuiInset` | boolean | ScreenGui ignore inset, false by default. |
| `Parent` | instance | Where the ScreenGui is parented. Without it the window uses PlayerGui, then CoreGui. |

## Window methods

| Method | Description |
| --- | --- |
| `:Tab(name, icon)` | Create a tab and return it. |
| `:Divider()` | A sidebar divider between tabs. |
| `:SetTitle(text)` | Change the window title. |
| `:SetFont(asset)` | Swap the font family across the window and persist the choice. |
| `:SetTheme(theme)` | Switch theme at runtime, by name or by theme table. Named themes are saved. |
| `:UINotification(settings)` | Show a modal confirm dialog. One at a time, the previous one is closed first. |
| `:Alert(settings)` | Neutral toast, same settings as `Toast`. |
| `:Error(settings)` | Red error toast, same settings as `Toast`. |
| `:Toast(settings)` | Toast with `Title`, `Description`, `Duration`, `Icon`, `IconColor`, `GradientColor` and `Actions`. |
| `:DropdownPopUp(id, settings)` | Open the dropdown popup stored under `id`, creating it on first use. |
| `:ColorPickerPopUp(id, settings)` | Open the colour picker popup stored under `id`, creating it on first use. |
| `:HidePopups()` | Close the open dialog and both popup types. |
| `:OnDestroy(callback)` | Register cleanup that runs when the window closes. Several callbacks can be registered. |
| `:Destroy()` | Run teardown hooks, fade the window out and destroy it. |

The window also carries helpers the library calls itself:

| Method | Description |
| --- | --- |
| `:ToggleMinimize()` | Minimize or restore from a stable state. |
| `:ResetLayout()` | Tween the window back to its default size and position. |
| `:SetPillPosition(side)` | Move the minimize pill and save the choice. |
| `:SetCompact(on)` | Collapse or expand the sidebar. |
| `:ApplyTheme(theme)` | Run a theme pass over the window shell. |
| `:GetActivePage()` | The page the sidebar search filters: the active settings page, else the active tab content. |
| `:ApplySearch()` | Apply the current search text to that page. |

See Components for the per component option tables and methods.
