# Security

`AETHERIS_SECUREMODE = true` hardens how the UI is parented and named. It's off by default.

```lua
local window = Aetheris:CreateWindow({
	Title = "My Script",
	AETHERIS_SECUREMODE = true,
	KeySystem = { SaveKey = true, Key = "hello" },
})
```

What it does:

* The gui is parented through `gethui()` when the executor provides it, then CoreGui, then PlayerGui.
* The gui gets a random UUID name instead of a readable one.
* Executor protection hooks (`syn.protect_gui`, `protect_gui`, `protectgui`) are called when they exist.
* The key screen gets the same treatment, so the gate is covered too.

Everything is wrapped in `pcall`, so in a plain Studio session secure mode simply does nothing extra and the UI still loads.

## What it doesn't do

It won't hide the UI from a determined local attacker, and it won't stop screenshots. Treat it as best-effort obfuscation, not a guarantee — the same caveat applies to most protection schemes in the ecosystem.
