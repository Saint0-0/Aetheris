<p align="center">
  <img src="assets/banner rectangular.png" alt="Aetheris" width="100%" />
</p>

<p align="center">
  <a href="https://github.com/Saint0-0/Aetheris/releases/latest"><img src="https://img.shields.io/github/v/release/Saint0-0/Aetheris?include_prereleases&label=release" alt="Latest release" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="License: MIT" /></a>
</p>

Aetheris is a UI library for Roblox with a clean, modern look, inspired by WinUI3, maclib and Fluent. Everything is built at runtime with `Instance.new`, so there are no image dependencies and nothing to pre-build. You get the whole interface from code.

> **Work in progress.** Aetheris is not finished. Some features are still being built, and it may not have full exploit integration or full save-state support yet.

## Download

**[Latest release ->](https://github.com/Saint0-0/Aetheris/releases/latest)**

Two files are attached to each release:

- **Aetheris.rbxl** - a ready-made place with the library synced in.
- **Aetheris.luau** - the single-file build, load it with `loadstring`.

## Install

```lua
loadstring(game:HttpGet("https://github.com/Saint0-0/Aetheris/releases/latest/download/Aetheris.luau"))()
```

## Documentation

Setup, theming, the component API and examples all live in the docs:

**[Aetheris documentation ->](https://app.gitbook.com/s/WPkBDlqrRRp8P5YpSOrg)**

## Build from source

```
tools\darklua.exe process src/Init.luau dist/Aetheris.luau
```

## Credits

- **WinUI3** by Microsoft, for the visual language Aetheris is built around.
- **[maclib](https://brady-xyz.gitbook.io/maclib-ui-library)** by brady-xyz, for inspiration.
- **[Fluent](https://github.com/dawid-scripts/Fluent)** by dawid-scripts, for inspiration.

## License

MIT.
