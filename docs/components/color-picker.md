# Color Picker

A colour swatch that opens the picker popup when clicked.

```lua
section:ColorPicker({
	Name = "Accent colour",
	Default = Color3.fromRGB(108, 140, 255),
	Callback = function(color)
		print(color.R, color.G, color.B)
	end,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label for the row, also the popup title. |
| `Default` | Color3 | Starting colour. Red if omitted. |
| `Callback` | function | Fires with the chosen colour. |

The popup holds a saturation square, a hue bar, an alpha bar and a hex field. It is themed with the rest of the window, so it follows your theme automatically.

## Methods

| Method | Description |
| --- | --- |
| `:GetColor()` | Returns the current colour. |
| `:SetColor(Color3, silent?)` | Set the colour. Pass `true` to skip the callback. |
| `:TogglePopup()` | Open or close the picker programmatically. |
| `:ClosePopup()` | Close it if open. |
| `:SetName(string)` | Change the label. |
| `:SetVisible(bool)` | Show or hide. |
| `:GetVisible()` | Returns whether it is showing. |
| `:Destroy()` | Remove the picker and its popup hookups. |

## Screenshot

![Color Picker](https://raw.githubusercontent.com/Saint0-0/Aetheris/main/assets/screenshots/Colorpicker(Closed).png)
