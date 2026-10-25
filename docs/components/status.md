# Status

A list of labelled status entries, each with a colour.

```lua
section:Status({
    Name = "System Status",
    Entries = {
        { "info",  "All systems nominal", "green" },
        { "alert", "CPU usage high",      "orange" },
        { "error", "Critical failure",    "red" },
        { "custom", "Custom colour",      Color3.fromRGB(255, 200, 100) },
    },
})
```

## Entry format

Each entry is `{ kind, text, colour }` where colour is a named colour (`"green"`, `"orange"`, `"red"`) or a `Color3`. An empty `kind` renders the text without the `kind:` prefix.

## API

| Method | Description |
| --- | --- |
| `:SetEntry(key, text, colour?)` | Update an existing entry, or append it when the key is new. |
| `:AddEntry(key, text, colour?)` | Always append a new line (empty `key` = unkeyed); returns `nil` past the 8-entry cap. |
| `:GetEntry(key)` | Current text for `key`, or `nil`. |
| `:SetEntries(entries)` | Replace all entries. |
