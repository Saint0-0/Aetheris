# Dropdown

A closed row that opens a popup of choices. Set `MaxItemsChoosable = 1` for a plain select, or leave it high for multi-select.

```lua
local items = {
	{ name = "Apple", value = "apple" },
	{ name = "Banana", value = "banana" },
	{ name = "Orange", value = "orange" },
}

section:Dropdown({
	Name = "Favourite fruit",
	Items = items,
	Default = { "apple" },
	MaxItemsChoosable = 1,
	Callback = function(selected)
		if selected[1] then
			print(selected[1].name)
		end
	end,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Label for the row, also the popup title. |
| `Items` | table | Array of `{ name, value }` tables. `icon` is optional. |
| `Default` | table | Array of values to preselect. |
| `MaxItemsChoosable` | number | Selection limit. `1` makes it single-select. |
| `Callback` | function | Fires with the selection after the player confirms. |

Each item is a table, not a string: `{ name = "Apple", value = "apple" }`. Adding `icon = Aetheris.Icons.apple` puts a glyph next to it in the popup. The callback runs on confirm, not per click, so cancelling leaves everything untouched.

The callback receives an array of the same `{ name, value }` tables, in the order the player picked them.

## Methods

| Method | Description |
| --- | --- |
| `:SetValues(table, keepSelection?)` | Replace the list, optionally keeping selections that still exist. |
| `:SetValue(valueOrList, silent?)` | Select by value. Pass `true` to skip the callback. |
| `:GetSelected()` | Returns the selected `{ name, value }` entries. |
| `:SetName(string)` | Change the label. |
| `:SetVisible(bool)` | Show or hide. |
| `:GetVisible()` | Returns whether it is showing. |
| `:Destroy()` | Remove the dropdown and its popup hookups. |

## Screenshot

![Dropdown](https://raw.githubusercontent.com/Saint0-0/Aetheris/main/assets/screenshots/Dropdowns(Closed).png)
