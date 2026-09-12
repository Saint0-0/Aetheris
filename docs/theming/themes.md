# Themes

Aetheris ships with 23 hand-tuned themes. Every component follows the active theme automatically — you never theme a component by hand.

## The roster

Default, Black, Light, Midnight, Graphite, Pearl, Slate, Ocean, Nord, Forest, Amethyst, Rose, Retro, Glass, Porcelain, Mist, Sandstone, Dusk, Frost, Azure, Fjord, Summit, Blossom.

## Setting a theme

Pass the name when you create the window:

```lua
local window = Aetheris:CreateWindow({ Theme = "Midnight" })
```

Or switch at runtime:

```lua
window:SetTheme("Ocean")
```

## Transparency

Each theme defines its own transparency per surface, driven by a `THEME_TRANSPARENCY` map in the theme definitions:

- Some themes have a **transparent sidebar** over an opaque content area.
- Some invert that — **transparent content** over an opaque sidebar.
- A couple are fully opaque.
- `Glass` is the strong frosted-glass option.

So the same component set can look like a solid app or a see-through overlay depending on the theme.
