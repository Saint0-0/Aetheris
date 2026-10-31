# Stepper

A number with a minus and plus button. Good for values you set in small fixed steps.

```lua
section:Stepper({
	Name = "Repeat count",
	Min = 1,
	Max = 50,
	Default = 5,
	Step = 1,
	Callback = function(value)
		print(value)
	end,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label for the row. |
| `Min` | number | Lowest value. Defaults to `0`. |
| `Max` | number | Highest value. Defaults to `100`. |
| `Default` | number | Starting value. Defaults to `50`. |
| `Step` | number | Amount per click. Defaults to `1`. |
| `Integer` | boolean | Keep values whole. On by default. |
| `Callback` | function | Runs with the new value on every step. |

Set `Integer = false` and a `Step` under `1` for fine values, for example `Step = 0.1`.

## Methods

| Method | Description |
| --- | --- |
| `:SetValue(number, noCallback?)` | Set the value. Pass `true` to skip the callback. |
| `:GetValue()` | Returns the current value. |
| `:SetMin(number)` | Move the lower bound. |
| `:SetMax(number)` | Move the upper bound. |
| `:SetStep(number)` | Change the step size. |
| `:UpdateName(string)` | Change the label. |
| `:SetVisible(bool)` | Show or hide. |
| `:GetVisible()` | Returns whether it is showing. |
| `:Destroy()` | Remove the stepper and its bindings. |

## Screenshot

![Stepper](https://raw.githubusercontent.com/Saint0-0/Aetheris/main/assets/screenshots/Stepper.png)
