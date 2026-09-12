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

Each entry is `{ kind, text, colour }` where colour is a named colour (`"green"`, `"orange"`, `"red"`) or a `Color3`.
