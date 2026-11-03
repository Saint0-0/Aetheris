# Text Input

A single-line text field with a label.

```lua
section:TextInput({
	Name = "Player name",
	Placeholder = "Enter a name...",
	Callback = function(text)
		print(text)
	end,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label for the row. |
| `Placeholder` | string | Grey hint text. Defaults to `[...]`. |
| `Default` | string | Starting text. |
| `Numeric` | boolean | Digits only. Off by default. |
| `ClearOnFocus` | boolean | Empty the field when clicked. Off by default. |
| `Callback` | function | Fires with the text whenever it changes. |

## Methods

| Method | Description |
| --- | --- |
| `:GetText()` | Returns the current text. |
| `:SetText(string, flash?)` | Set the text. Pass `true` to skip the flash. |
| `:SetPlaceholder(string)` | Change the hint text. |
| `:SetName(string)` | Change the label. |
| `:SetVisible(bool)` | Show or hide. |
| `:GetVisible()` | Returns whether it is showing. |
| `:Destroy()` | Remove the field and its bindings. |

## Screenshot

![Text Input](https://raw.githubusercontent.com/Saint0-0/Aetheris/main/assets/screenshots/TextInput.png)
