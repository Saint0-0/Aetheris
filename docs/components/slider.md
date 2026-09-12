# Slider

A numeric range control.

```lua
section:Slider({
    Name = "Smoothness",
    Min = 0,
    Max = 100,
    Default = 50,
    Precision = 1,
    Callback = function(value) print(value) end,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label. |
| `Min` | number | Lowest value. |
| `Max` | number | Highest value. |
| `Default` | number | Starting value. |
| `Precision` | number | Decimal places. `0` for whole numbers. |
| `Callback` | function | Called with the new value as you drag. |
| `Flag` | string | Optional id for config save/load. |

## Methods

| Method | Description |
| --- | --- |
| `:SetValue(number)` | Set the value programmatically. |
| `:GetValue()` | Returns the current value. |
| `:SetVisibility(bool)` | Show or hide the component. |
