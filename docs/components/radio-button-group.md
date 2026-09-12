# Radio Button Group

Mutually-exclusive choices. Create the group, then add buttons to it.

```lua
local group = section:RadioButtonGroup()
group:RadioButton({
    Name = "Option A",
    Default = true,
    Callback = function() print("A") end,
})
group:RadioButton({
    Name = "Option B",
    Callback = function() print("B") end,
})
```

Only one button in a group can be selected at a time.

## RadioButton options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label. |
| `Default` | bool | Select this one at start. |
| `Callback` | function | Called when selected. |
