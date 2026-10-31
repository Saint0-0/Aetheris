# Viewport

A `ViewportFrame` showing a player's character, framed like a character select screen.

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

The camera follows the framing you pick: `"Full"` shows the whole character, the others push in. If the character dies or respawns, the viewport tracks it.

## Methods

| Method | Description |
| --- | --- |
| `:SetPlayer(Player)` | Show a different player. |
| `:SetFraming(string)` | Change the camera framing. |
| `:SetRotate(bool)` | Turn the rotation on or off. |
| `:SetVisibility(bool)` | Show or hide. |
| `:GetVisible()` | Returns whether it is showing. |
| `:Destroy()` | Remove the viewport. |
