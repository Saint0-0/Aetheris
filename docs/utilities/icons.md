# Icons

Aetheris uses the Lucide icon set, exposed through the facade as `Aetheris.Icons`. It's a table of name → `rbxassetid://`.

```lua
local Icons = Aetheris.Icons

window:Tab("Home", Icons["home"])
```

Pass an icon wherever a component or tab accepts one. A common pattern is a small helper that falls back to a known icon if a name is missing:

```lua
local function ico(name)
    return Icons[name] or Icons.crosshair
end
```
