# KeybindDispatcher

One shared input listener for every Keybind row.

Each Keybind used to own its own `InputBegan` connection, so N binds meant N handlers firing on every keypress, each comparing key names as strings. The dispatcher keeps a `KeyCode.Name` to callbacks map and does one lookup per keystroke, so the listener count stays at one however many binds exist.

The connection is created on the first `Register` and kept for the session. Buckets are reference counted per key, so unregistering the last callback for a key drops its map entry. Input that chat or a focused TextBox has already claimed is ignored, and so is anything that is not a keyboard key.

```lua
local KeybindDispatcher = require(ReplicatedStorage.Aetheris.Utils.KeybindDispatcher)

local token = KeybindDispatcher.Register("F", function()
    print("F pressed")
end)

KeybindDispatcher.Unregister(token)
```

## Methods

| Method | Description |
| --- | --- |
| `Register(keyName, callback)` | Run `callback` whenever `keyName` is pressed. Returns a token, or nil when `keyName` is empty. |
| `Unregister(token)` | Remove a callback. Safe to call with nil or a token that is already gone. |
