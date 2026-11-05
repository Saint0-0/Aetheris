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
| `ShowInfo` | boolean | Show the info column next to the viewport. On by default; `false` leaves just the viewport, centred and widened into the freed space. |
| `Info` | table | The info rows themselves, see below. |

The camera follows the framing you pick: `"Full"` shows the whole character, the others push in. If the character dies or respawns, the viewport tracks it, and the health bar tracks the character's humanoid.

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
