# Viewport

A `ViewportFrame` showing a player's character, framed like a character select screen, with a slim health bar beside it.

```lua
section:Viewport({
	Name = "Preview",
	Player = localPlayer,
	Framing = "UpperBody",
	Rotate = true,
	Height = 220,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label for the panel. |
| `Player` | Player | Whose character to show. |
| `Height` | number | Frame height in pixels. Defaults to `160`. |
| `Framing` | string | `"Full"`, `"UpperBody"`, `"Torso"` or `"Head"`. |
| `Rotate` | boolean | Slowly turn the model. On by default. |
| `Info` | table | The info column and its rows (see below). Omit it for a viewport-only card; `{}` shows the default four player fields. |
| `HealthBar` | boolean | The slim vertical bar beside the viewport. On by default; `false` drops it and the view takes the extra width. |

The camera follows the framing you pick: `"Full"` shows the whole character, the others push in. If the character dies or respawns, the viewport tracks it, and the health bar tracks the character's humanoid — it fills from the bottom and shifts red to yellow to green as health drops.

## Custom info rows

Each row takes a `Caption`, then either a `Key` (any Player property, read live) or a `Text` (fixed text you set). `Suffix` appends to the value.

```lua
section:Viewport({
	Name = "Preview",
	Info = {
		{ Caption = "USERNAME", Key = "Name" },
		{ Caption = "USER ID", Key = "UserId" },
		{ Caption = "LEVEL", Text = "42" },
	},
})
```

## Methods

| Method | Description |
| --- | --- |
| `:SetPlayer(Player)` | Show a different player. |
| `:SetFraming(string)` | Change the camera framing. |
| `:SetRotate(bool)` | Turn the rotation on or off. |
| `:SetVisible(bool)` | Show or hide. |
| `:GetVisible()` | Returns whether it is showing. |
| `:Destroy()` | Remove the viewport. |
