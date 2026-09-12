<p align="center">
  <img src="assets/banner.png" alt="Aetheris" width="100%" />
</p>

Aetheris is a UI library for Roblox with a clean, modern look inspired by WinUI3. Everything is built at runtime with `Instance.new`, so there are no image dependencies and nothing to pre-build — you get the whole interface from code.

It comes with a theming system that ships with 23 hand-tuned themes, live theme switching with a smooth colour fade, a full set of components, popups and notifications, and it runs both in Studio and inside a script executor.

## What's inside

- Every element is created with `Instance.new` — no external assets.
- 23 built-in themes, all switchable at runtime, and every component follows the active theme.
- Components: toggles, sliders, steppers, keybinds, text inputs, dropdowns, colour pickers, radio groups, progress bars, status lists, buttons, labels, paragraphs, dividers and video.
- Popups and notifications: dropdowns, colour pickers, tooltips and toasts (alert, error and variable).
- Per-element transparency, so you can do glass-style sidebars and frosted content areas.
- Works in Studio and in executors.

## Documentation

Everything — setup, theming, the component API and examples — lives in the docs:

**[Aetheris documentation →](https://example.gitbook.io/aetheris)**

## Getting the library

Grab the single-file build from [`dist/Aetheris.luau`](dist/Aetheris.luau) and load it, or run it however you normally run a script.

```lua
loadstring(game:HttpGet("<raw url to dist/Aetheris.luau>"))()
```

## Repo layout

```
src/          the library source
  Core/         Window, TabGroup, Section and settings
  Components/   the UI components
  Themes/       the theme engine and definitions
  Popups/       popups and notifications
  Utils/        tween, sound and helpers
  Assets/       icons
example/      a demo that shows off every component
dist/         the built single-file library
assets/       the banner and other branding
tools/        rojo + darklua (dev tools)
```

## Building from source

If you want to rebuild `dist/Aetheris.luau` yourself:

```
tools\darklua.exe process src/Init.luau dist/Aetheris.luau
```

## Contributing

If you want to add something or fix a bug, open an issue first for anything bigger so we can talk it through. Keep the existing style (string requires, no `script.Parent`).

## License

MIT.
