# Odometer

Renders a number as a row of per digit reels.

Each digit is a clipped cell holding a vertical strip of the glyphs 0 to 9. Changing a digit slides the strip so the new digit rolls up from below or down from above and eases into place. Characters that are not digits, such as separators and percent signs, stay as plain labels. Cells are variable width and the string reconciles from the right, so decimals and suffixes hold their place while digits are added on the left. Cells are pooled and reused.

Based on code from [Rayfield Gen2](https://github.com/SiriusSoftwareLtd/rayfield-gen2).

```lua
local Odometer = require(ReplicatedStorage.Aetheris.Utils.Odometer)

local odo = Odometer.new(container, { textSize = 22 })
odo:snap("1,000")
odo:to("2,500", true)
odo:setTransparency(1)
```

## Options

`Odometer.new(parent, opts)` lays the row out inside `parent`.

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `textSize` | number | `16` | Glyph size. |
| `height` | number | `math.ceil(textSize)` | Cell height. Raise it so ascenders and descenders do not clip. |
| `alignment` | Enum | `Left` | Horizontal alignment of the row. |
| `transparency` | number | `0` | Text transparency the row is built with. |
| `duration` | number | `0.55` | Roll duration in seconds. |
| `weight` | Enum | `SemiBold` | Font weight. |

## Methods

| Method | Description |
| --- | --- |
| `:snap(text)` | Set the value with no roll. |
| `:to(text, up)` | Roll toward the value. `up` picks the direction. |
| `:setTransparency(value)` | Set the transparency of every glyph. |
