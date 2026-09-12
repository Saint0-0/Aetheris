# Color Picker

Opens a colour picker popup and reports the chosen colour.

```lua
section:ColorPicker({
    Name = "Crosshair Colour",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color) print(color) end,
}, showColorPicker)
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label. |
| `Default` | Color3 | Starting colour. |
| `Callback` | function | Called with the new `Color3`. |

## The second argument

The second argument is the popup factory — in the demo it's `window:ColorPickerPopUp` (wrapped as `showColorPicker`).
