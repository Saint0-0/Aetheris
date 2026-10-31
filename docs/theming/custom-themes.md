# Custom Themes

A theme is just a table of keys. You don't need all of it — anything you omit falls back to the built-in `Base` values.

```lua
local DeepSea = {
	WindowColor = Color3.fromRGB(10, 16, 24),
	SidebarColor = Color3.fromRGB(13, 21, 31),
	InputBackgroundColor = Color3.fromRGB(16, 26, 38),
	AccentColor = Color3.fromRGB(56, 168, 255),
	PrimaryColor = Color3.fromRGB(41, 128, 204),
	SecondaryColor = Color3.fromRGB(27, 74, 118),
	PrimaryTextColor = Color3.fromRGB(235, 244, 250),
	SecondaryTextColor = Color3.fromRGB(163, 184, 200),
}

local window = Aetheris:CreateWindow({ Theme = DeepSea })
```

Tables work anywhere a name does: `CreateWindow({ Theme = ... })`, `window:SetTheme(...)`, and the key screen's theme.

## The keys worth knowing

| Key | What it drives |
| --- | --- |
| `WindowColor` / `WindowTransparency` | The main frame. |
| `SidebarColor` / `SidebarTransparency` | The tab sidebar. |
| `AccentColor` | Highlights, the progress bar fill, focus glows. |
| `PrimaryColor` / `SecondaryColor` | The "on" colour and the resting colour of controls. |
| `StrokeColor` / `StrokeTransparency` | Borders around the frame and inputs. |
| `PrimaryTextColor` / `SecondaryTextColor` | Main text and dimmer text. |
| `PopupBackgroundColor`, `PopupTextColor` | Popups, dialogs and tooltips. |
| `Wallpaper` | An image id used as a background wash where enabled. |

The full list lives in `ThemeDefinitions.Base` — every key there is a key you can set. Notification surfaces and section cards are derived from the colours you provide, so most themes need only a dozen or so keys.

## Reusing parts of a built-in theme

`Aetheris.ThemeDefinitions` is exposed, so you can start from one and tweak:

```lua
local mine = table.clone(Aetheris.ThemeDefinitions.Umbral)
mine.AccentColor = Color3.fromRGB(255, 120, 90)

window:SetTheme(mine)
```

Resolved themes are merged over `Base` every time, so keep a reference to your table if you plan to reuse it. Named themes are resolved once and cached.
