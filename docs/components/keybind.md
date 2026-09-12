# Keybind

Captures a keyboard key.

```lua
section:Keybind({
    Name = "Primary Key",
    Default = "G",
    Callback = function(key) print(key) end,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label. |
| `Default` | string | Starting key. |
| `Callback` | function | Called with the captured key. |
| `Flag` | string | Optional id for config save/load. |

## Methods

| Method | Description |
| --- | --- |
| `:SetKey(string)` | Set the key programmatically. |
| `:GetKey()` | Returns the current key. |
| `:SetVisibility(bool)` | Show or hide the component. |
