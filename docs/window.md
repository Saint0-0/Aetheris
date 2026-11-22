# Window

The window is the frame everything else lives in: title bar, sidebar, tabs, the settings gear, and the minimize pill.

```lua
local window = Aetheris:CreateWindow({
	Title = "My Script",
	Theme = "Umbral",
	MinimizeKey = "LeftControl",
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Title` | string | Shown in the title bar. |
| `Theme` | string | Starting theme name. `"Default"` uses the launch theme. |
| `MinimizeKey` | string | Key that hides and restores the window. Defaults to `M`. |
| `Tags` | table | Up to three pills under the title. See [Tags](window/tags.md). |
| `SettingsPages` | table | Custom pages for the settings window. See [Settings Pages](window/settings-pages.md). |
| `DefaultSettingsPage` | string | Page the settings window opens on. |
| `AnimationStyle` | string | `"Smooth"` (default) or `"Snappy"`. |
| `DragStyle` | string | `"Smooth"` glides after the cursor, `"Instant"` snaps. |
| `DisplayOrder` | number | Z-order of the gui. |
| `Parent` | Instance | Put the gui somewhere specific instead of the default. |
| `ScreenGuiName` | string | Name of the ScreenGui when not in secure mode. |
| `IgnoreGuiInset` | boolean | Let the window sit under the topbar. |
| `AETHERIS_SECUREMODE` | boolean | Parent through `gethui` and rename to UUIDs. |
| `KeySystem` | table | Gate the window behind a key. See [Key System](key-system.md). |
| `Version` | string | Version for the script's own changelog. |
| `Changelog` | table | Array of `{ Title, Description, Icon, Tint }` entries. |

A saved setting always beats the value you pass here: if the player changed the theme or minimize key in the settings window, that wins on the next launch.

## Methods

| Method | Description |
| --- | --- |
| `:Tab(name, icon)` | Add a sidebar page. Returns the tab. |
| `:Divider()` | Separator between tabs. |
| `:SetTitle(string)` | Change the title text. |
| `:SetTheme(string)` | Repaint everything to another theme. |
| `:SetFont(asset)` | Swap the font family. |
| `:SetCompact(bool)` | Collapse the sidebar into the pill row. |
| `:SetPillPosition(...)` | Move the minimized pill. |
| `:ToggleMinimize()` | Minimize or restore. |
| `:Toast(settings)` | Short self-dismissing message. |
| `:Alert(settings)` | Alert-style notification. |
| `:Error(settings)` | Error-style notification. |
| `:UINotification(settings)` | Modal confirm/cancel dialog. |
| `:DropdownPopUp(id, settings)` | Open a dropdown popup directly. |
| `:ColorPickerPopUp(id, settings)` | Open a picker popup directly. |
| `:HidePopups()` | Close any open popup. |
| `:NavigateTo(name)` | Open a settings page, then a sidebar tab, by name. |
| `:CopyToClipboard(text, label)` | Copy text and show a toast. Returns whether it worked. |
| `:OnDestroy(callback)` | Run something when the window is destroyed. |
| `:Close()` | Close the window from code. Same as `:Destroy()`. |
| `:Destroy()` | Tear the window down. |

## Changelog

Two changelogs share one popup. `Version` and `Changelog` are the script's own release notes: they open once per version string, then stay quiet until that string changes. Aetheris keeps its own list in the same popup, keyed on the library version, and `Settings > Actions > Aetheris Changelog` re-opens it; `window.AetherisChangelog:Show()` does the same from code, while `window.Changelog:Show()` re-opens the script's list.

Entries take an optional `Icon` (any key from [Icons](utilities/icons.md)) and `Tint` (`blue`, `purple`, `teal`, `orange`, `red`, `yellow`). Without a tint, entries cycle through the palette in order.

```lua
local window = Aetheris:CreateWindow({
	Title = "My Script",
	Version = "2.1.0",
	Changelog = {
		{ Title = "Faster startup", Description = "Cached theme lookups shave a frame off the first paint.", Tint = "blue" },
		{ Title = "New configs page", Description = "Save, load and overwrite presets without leaving Settings.", Icon = "save" },
	},
})
```

## Notifications in one line each

```lua
window:Toast({ Title = "Saved", Duration = 4 })
window:Alert({ Title = "Heads up", Description = "Key expires soon." })
window:Error({ Title = "Request failed", Description = "Bad response from the API." })
window:UINotification({
	Title = "Delete config?",
	Description = "This cannot be undone.",
	OnConfirm = function() end,
	OnCancel = function() end,
})
```

Toasts stack in the corner and dismiss themselves. `UINotification` blocks until the player picks one. Full options live in [Notifications](window/notifications.md).

## Layout

The window drags, resizes and maximizes from its edges, and the search box filters the active tab's rows as you type. `SetCompact(true)` swaps the sidebar for a pill row of tabs, which is the mobile-friendly view. Everything repaints live on `SetTheme`.

Tabs and sections are covered in [Core Concepts](core-concepts.md).

## Screenshot

![Window](https://raw.githubusercontent.com/Saint0-0/Aetheris/main/assets/screenshots/Main%20UI.png)
