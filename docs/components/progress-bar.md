# Progress Bar

A filled bar for showing a value between a min and max.

```lua
local bar = section:ProgressBar({
    Name = "Health",
    MinValue = 0,
    MaxValue = 100,
    Value = 100,
    Color = Color3.fromRGB(255, 50, 50),
    ShowPercentage = true,
    ShowFraction = true,
    Animate = true,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label. |
| `MinValue` | number | Lower bound. |
| `MaxValue` | number | Upper bound. |
| `Value` | number | Starting value. |
| `Color` | Color3 | Fill colour. |
| `ShowPercentage` | bool | Show the value as a percentage. |
| `ShowFraction` | bool | Show the value as `x/y`. |
| `Animate` | bool | Tween the fill when the value changes. |

## Methods

| Method | Description |
| --- | --- |
| `:SetValue(number)` | Set the value (animates if `Animate` is on). |
| `:GetValue()` | Returns the current value. |
