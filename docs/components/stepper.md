# Stepper

A numeric field with increment/decrement buttons.

```lua
section:Stepper({
    Name = "Ammo Count",
    Min = 0,
    Max = 100,
    Default = 30,
    Step = 5,
    Integer = true,
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
| `Step` | number | Amount added/removed per click. |
| `Integer` | bool | Force whole numbers. |
| `Callback` | function | Called with the new value. |
| `Flag` | string | Optional id for config save/load. |

## Methods

| Method | Description |
| --- | --- |
| `:SetValue(number)` | Set the value programmatically. |
| `:GetValue()` | Returns the current value. |
| `:SetVisibility(bool)` | Show or hide the component. |
