# Code View

A code block with syntax highlighting, a line-number gutter, and optionally inline editing.

```lua
section:CodeView({
	Name = "Snippet",
	Language = "lua",
	Text = "local part = Instance.new(\"Part\")",
	Height = 220,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Title on the block. |
| `Text` | string | The code shown. |
| `Language` | string | Highlighting rules to use, e.g. `"lua"`. |
| `Height` | number | Block height in pixels. |
| `Editable` | boolean | Let the player type in the block. Off by default. |
| `OnCopy` | function | Runs when the copy button is used. |

With `Editable = true` the block becomes a real editor with a caret and undo-friendly edits, and `:GetContent()` returns whatever is in it now.

## Methods

| Method | Description |
| --- | --- |
| `:GetContent()` | Returns the current code. |
| `:SetText(string)` | Replace the code. |
| `:SetLanguage(string)` | Change the highlight rules. |
| `:SetOnCopy(function)` | Replace the copy hook. |
| `:SetName(string)` | Change the title. |
| `:SetVisible(bool)` | Show or hide. |
| `:GetVisible()` | Returns whether it is showing. |
| `:Destroy()` | Remove the block. |
