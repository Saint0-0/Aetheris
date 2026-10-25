# Code View

A syntax-highlighted code block with line numbers and an optional edit mode.

```lua
section:CodeView({
    Name = "Snippet",
    Height = 190,
    Language = "lua",
    Text = "local x = 1",
    Editable = true,
    OnCopy = function(content) end,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Header label (hidden when nil/empty). |
| `Text` | string | The code content. |
| `Language` | string | `"lua"` (default), `"javascript"` or `"python"` — aliases `luau`/`js`/`py` work; unknown values fall back to Lua rules. |
| `Height` | number | Panel height in pixels (min 72, default 140). |
| `Editable` | bool | `true` lets a click swap in a multiline TextBox for editing. |
| `OnCopy` | function | Called with `(content, component)` when the header's Copy button is clicked. |

## Methods

| Method | Description |
| --- | --- |
| `:SetText(string)` | Replace the content and re-highlight. |
| `:GetContent()` | Returns the current text (live box text while editing). |
| `:SetLanguage(string)` | Switch language and re-highlight. |
| `:SetOnCopy(function)` | Attach/replace the copy handler later. |
| `:SetVisibility(bool)` | Show or hide the component. |

## Notes

Highlighting is theme-tinted: every token class is a hue offset from the theme accent, and the panel's luminance picks bright or dark values — so colours shift with the theme without collapsing into one another. Plain identifiers ride the theme's primary text colour; operators, punctuation and comments are the secondary text colour dimmed toward the panel.

View mode renders one RichText row per line with the line number inline; editing swaps in a plain multiline TextBox (click the code when `Editable`) and re-highlights on blur. The Copy button is inert until `OnCopy` is provided — wire `setclipboard(content)` there from an executor.
