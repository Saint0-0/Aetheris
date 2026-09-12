# Toggle

An on/off switch with a label.

```lua
section:Toggle({
    Name = "Enable feature",
    Default = true,
    Callback = function(state) print(state) end,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label shown next to the switch. |
| `Default` | bool | Starting state. Defaults to `false`. |
| `Callback` | function | Called with the new state when toggled. |
| `Flag` | string | Optional id for config save/load. |
| `Confirm` | table | Optional confirmation dialog (see below). |

## Confirmation dialog

Pass a `Confirm` table to make the toggle ask before changing. Handy for anything risky.

```lua
section:Toggle({
    Name = "Dangerous toggle",
    Confirm = {
        Enabled = true,
        Title = "Are you sure?",
        Description = "This may cause issues.",
        ConfirmText = "Yes",
        CancelText = "No",
    },
    Callback = function(state) print(state) end,
}, notify)
```

The second argument to `section:Toggle` is the notification function used to render the confirmation — in the demo it's `window:UINotification`.

## Methods

| Method | Description |
| --- | --- |
| `:UpdateState(bool)` | Set the state (animates). |
| `:GetState()` | Returns the current state. |
| `:SetVisibility(bool)` | Show or hide the component. |
| `:UpdateName(string)` | Change the label. |
