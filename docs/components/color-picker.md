# Color Picker

A colour swatch that opens the picker popup when clicked.

```lua
section:ColorPicker({
	Name = "Accent colour",
	Default = Color3.fromRGB(108, 140, 255),
	Alpha = 255,
	Callback = function(color, alpha)
		print(color.R, color.G, color.B, alpha)
	end,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label for the row, also the popup title. |
| `Default` | Color3 | Starting colour. Red if omitted. |
| `Alpha` | number | Starting opacity, `0`-`255`. Fully opaque if omitted. |
| `Callback` | function | Fires with `(color, alpha)` after Confirm. `alpha` is `0`-`255`. |

The popup has a saturation/value square, hue and alpha bars, a hex field with a live swatch, RGB fields, preset and recent swatches, and an original → new pair in the footer. It is themed with the rest of the window, so it follows your theme automatically, and it scales down to fit compact windows.

The hex field accepts `#abc`, `abc`, `#AABBCC` and `#AABBCCAA` (the last two set alpha too). Clicking outside the popup cancels the edit.

## Methods

| Method | Description |
| --- | --- |
| `:GetColor()` | Returns the current colour. |
| `:SetColor(Color3, silent?)` | Set the colour. Pass `true` to skip the callback. |
| `:GetAlpha()` | Returns the current alpha, `0`-`255`. |
| `:SetAlpha(number, silent?)` | Set the alpha. Pass `true` to skip the callback. |
| `:TogglePopup()` | Open or close the picker programmatically. |
| `:ClosePopup()` | Close it if open. |
| `:SetName(string)` | Change the label. |
| `:SetVisible(bool)` | Show or hide. |
| `:GetVisible()` | Returns whether it is showing. |
| `:Destroy()` | Remove the picker and its popup hookups. |

Configs save the colour and alpha as `{ r, g, b, a }`; older three-value entries still load.

## Screenshot

![Color Picker](https://raw.githubusercontent.com/Saint0-0/Aetheris/main/assets/screenshots/Colorpicker(Closed).png)