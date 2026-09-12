# Dropdown Popup

The popup that opens when you click a [Dropdown](../components/dropdown.md) component. It lists the items and reports selections back.

## Opening it

You don't open it directly — the dropdown component does, using the factory you pass as the second argument:

```lua
local function showDropdown(id, settings)
    return window:DropdownPopUp(id, settings)
end

section:Dropdown({ ... }, showDropdown)
```

## Behaviour

- It's positioned relative to the dropdown that opened it.
- It respects the component's `MaxItemsChoosable` cap.
- It's themed from the active theme's popup colours.
