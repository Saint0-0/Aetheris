# Color Picker Popup

The colour chooser that opens from a [Color Picker](../components/color-picker.md) component.

## Opening it

Same pattern as the dropdown — the component opens it through the factory you pass:

```lua
local function showColorPicker(id, settings)
    return window:ColorPickerPopUp(id, settings)
end

section:ColorPicker({ Name = "Accent", Default = Color3.fromRGB(108, 140, 255) }, showColorPicker)
```

## Behaviour

- Returns the chosen colour to the component's `Callback`.
- Reads the live theme for its stroke and background colours, so it stays consistent across theme switches.
