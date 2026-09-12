# Text Input

A single-line text field.

```lua
section:TextInput({
    Name = "Player Name",
    Placeholder = "Enter a name...",
    Default = "",
    Callback = function(text) print(text) end,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label. |
| `Placeholder` | string | Greyed-out hint text. |
| `Default` | string | Starting text. |
| `Callback` | function | Called with the text as it changes / on submit. |
| `Flag` | string | Optional id for config save/load. |

## Methods

| Method | Description |
| --- | --- |
| `:SetText(string)` | Set the text programmatically. |
| `:GetText()` | Returns the current text. |
| `:SetVisibility(bool)` | Show or hide the component. |
