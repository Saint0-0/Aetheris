# Dropdown

A selectable list. Can be single-select or multi-select, with an optional cap.

```lua
section:Dropdown({
    Name = "Fruit",
    Items = {
        { name = "Apple", icon = Icons["apple"], value = "apple" },
        { name = "Banana", value = "banana" },
    },
    Default = { "apple" },
    MaxItemsChoosable = 1, -- 1 = single select
    Placeholder = "Pick one...",
    Callback = function(selected)
        for _, item in ipairs(selected) do print(item.name) end
    end,
}, showDropdown)
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label. |
| `Items` | array | `{ name, value, icon? }` entries. |
| `Default` | array | Values selected at start. |
| `MaxItemsChoosable` | number | Cap on selection. Omit for unlimited. |
| `Placeholder` | string | Text shown when nothing is selected. |
| `Callback` | function | Called with an array of selected items. |

## The second argument

The second argument to `section:Dropdown` is the popup factory — in the demo it's `window:DropdownPopUp` (wrapped as `showDropdown`). It renders the list popup and keeps it themed.
