# Divider

A thin horizontal line to break a section into groups.

```lua
section:Divider({
	Thickness = 1,
	Padding = 6,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Optional label, mostly for your own reading. |
| `Color` | Color3 | Line colour. Section divider colour if omitted. |
| `Transparency` | number | `0` to `1`. Theme default if omitted. |
| `Thickness` | number | Height of the line. Defaults to `1`. |
| `Padding` | number | Space above and below. Defaults to `1`. |

## Methods

| Method | Description |
| --- | --- |
| `:SetColor(Color3)` | Change the colour. |
| `:SetTransparency(number)` | Fade the line. |
| `:SetVisible(bool)` | Show or hide. |
| `:GetVisible()` | Returns whether it is showing. |
| `:Destroy()` | Remove the divider. |
