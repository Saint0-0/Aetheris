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

* The gui is parented through `gethui()` when the executor provides it — checked both as a `_G` entry and as a plain global, plus `get_hidden_ui()` — then CoreGui, then PlayerGui.
* The gui gets a random UUID name instead of a readable one.
* Executor protection hooks (`syn.protect_gui`, `protect_gui`, `protectgui`) are called when they exist.
* The key screen gets the same treatment, so the gate is covered too.
* The default window title is suppressed, so the library name never lands on screen — pass `Title` yourself.

Everything is wrapped in `pcall`, so in a plain Studio session secure mode simply does nothing extra and the UI still loads.

## What it doesn't do

It won't hide the UI from a determined local attacker, and it won't stop screenshots. Treat it as best-effort obfuscation, not a guarantee — the same caveat applies to most protection schemes in the ecosystem.

Two deliberate trade-offs: settings and configs still live under the `Aetheris/` workspace folder (renaming it would lose them whenever the flag flips), and theme wallpapers keep their fixed asset ids, since that's how theming works.
