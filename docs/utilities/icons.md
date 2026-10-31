# Icons

The Lucide icon set, exposed through the facade as `Aetheris.Icons`.

It is a flat table of lowercase kebab-case name to `rbxassetid://`, with about 1700 entries. The source file is generated, so new icons come from regenerating `src/Assets/Icons.luau` rather than from hand editing it.

```lua
local Icons = Aetheris.Icons

window:Tab("Home", Icons["house"])
```

Pass an icon anywhere a component or tab takes one. A helper that falls back when a name is missing keeps call sites short:

```lua
local function ico(name)
    return Icons[name] or Icons.crosshair
end
```
