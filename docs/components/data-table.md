# Data Table

A compact table for changing records. Columns share the row width by weight, so the table always fits its section; there is no fixed-pixel width option.

```lua
local table = section:DataTable({
	Name = "Tracked players",
	MaxRows = 6,
	SortBy = "Score",
	SortDescending = true,
	Columns = {
		{ Key = "Name", Label = "PLAYER", Weight = 2 },
		{ Key = "Score", Label = "SCORE", Align = "right", Format = "number" },
		{ Key = "Status", Label = "STATUS", Color = function(value)
			return value == "Farming" and Color3.fromRGB(74, 200, 120) or nil
		end },
	},
	Action = {
		Label = "Kick",
		Callback = function(id, row)
			table:RemoveRow(id)
		end,
	},
})

table:SetRows({
	{ id = "alpha", Name = "Alpha", Score = 18450, Status = "Farming" },
	{ id = "bravo", Name = "Bravo", Score = 9200, Status = "Idle" },
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Heading above the table. |
| `Columns` | table | Array of column definitions. |
| `MaxRows` | number | Rows visible before the body scrolls. Default `10`. |
| `RowHeight` | number | Pixel height of one row. Default `26`. |
| `RowGap` | number | Space between rows. Default `4`. |
| `ShowHeader` | boolean | Show the header row. On by default. |
| `Striped` | boolean | Alternate row shading. On by default. |
| `EmptyText` | string | Text shown when there are no rows. |
| `RowColorTransparency` | number | Transparency of a colour set with `:SetRowColor`. Default `0.82`. |
| `SortBy` | string | Column key to sort by on creation. |
| `SortDescending` | boolean | Sort high to low. |
| `Action` | table | Optional per-row action button: `{ Label, Callback(id, row) }`. |

### Columns

| Key | Type | Description |
| --- | --- | --- |
| `Key` | string | Row field this column reads. Required. |
| `Label` | string | Header text. Defaults to the key. |
| `Weight` | number | Share of the row width. `1` is an equal share, `2` is twice the space. Default `1`. |
| `Align` | string | `"left"` (default), `"center"` or `"right"`. |
| `Format` | string or function | `"number"`, `"percent"`, `"studs"`, `"time"`, or a function that returns the cell text. |
| `Color` | Color3, string or function | Static colour, hex string, or a function `(value, row) -> Color3`. |
| `EmptyText` | string | Text for a `nil` value. Defaults to an em dash. |

Columns are weighted, never pixel-sized: every row is divided by the total weight, so the table scales with the window instead of overflowing it.

## Rows

Each row is a plain table with one field per column `Key`. Every row needs a stable unique identifier in `id` (or `Id`); if neither is present the library uses its position, which can change when rows are added or removed.

## Methods

| Method | Description |
| --- | --- |
| `:SetRows(rows)` | Replace every row. Duplicate identifiers overwrite each other. |
| `:GetRows()` | Returns a copy of the rows. |
| `:GetRow(id)` | Returns a copy of one row, or `nil`. |
| `:AddRow(row)` | Append a row and return its identifier. |
| `:UpdateRow(id, patch)` | Merge fields into a row. The table re-sorts immediately. |
| `:RemoveRow(id)` | Delete a row. Returns whether it existed. |
| `:ClearRows()` | Remove every row. |
| `:SetRowColor(id, colour)` | Highlight one row. Pass `nil` to clear it. |
| `:GetRowColor(id)` | Returns that row's highlight, or `nil`. |
| `:SetSort(key, descending)` | Change the sort column. Leave `descending` off to keep the current direction. |
| `:GetSort()` | Returns the sort key and direction. |
| `:SetMaxRows(number)` | Change the visible row cap. |
| `:SetEmptyText(string)` | Change the empty-state text. |
| `:SetColumns(columns)` | Replace the columns and rebuild the header. |
| `:SetAction(action)` | Replace or remove the per-row action button. |
| `:SetHeaderVisible(bool)` | Show or hide the header. |
| `:SetName(string)` | Change the heading. |
| `:SetVisible(bool)` | Show or hide. |
| `:GetVisible()` | Returns whether it is showing. |
| `:Destroy()` | Remove the table. |
