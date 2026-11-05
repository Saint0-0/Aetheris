# Themes

Aetheris ships with 45 hand-tuned themes. Every component follows the active one automatically — you never theme a component by hand.

## The roster

Umbral, Ember, Vesper, Duskfall, Canopy, Tidewater, Nocturne, Solace, Cielo, Honey, Dawn, Alpine, Peony, Sakura, Blush, Cinder, Mauve, Iris, Sundown, Twilight, Nebula, Monterey, Sonoma, Ventura, Vermilion, Grove, Prism, Sage, Blossom, Petal, Frost, Amber, Rosa, Gruvbox, Graphite, Mint, Lilac, Crimson, Umber, Linen, Slate, Onyx, Ash, Gunmetal, Charcoal.

`Umbral` is the default. `"Default"` in code always means the launch theme, whatever that ends up being.

## Setting a theme

Pass the name when you create the window:

```lua
local window = Aetheris:CreateWindow({ Theme = "Gruvbox" })
```

Or switch at runtime:

```lua
window:SetTheme("Tidewater")
```

If the player picked a theme in the settings window, that wins over both on the next launch.

## What a theme controls

Colours for every surface (window, sidebar, inputs, sections, popups, notifications), text colours, stroke colours and per-surface transparencies. Each theme also gets:

* A subtle accent tint blended into its surfaces, so everything feels like one palette.
* Notification accents — alert and error toasts keep their warning and danger read but shift toward the theme's accent.

Transparency varies per theme too: some ship a see-through sidebar over an opaque content area, some the other way round, and a few are fully opaque. The same code can look like a solid app or a frosted overlay depending on the theme.
