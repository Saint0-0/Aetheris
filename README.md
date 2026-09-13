<p align="center">
  <img src="assets/banner rectangular.png" alt="Aetheris" width="100%" />
</p>

Aetheris is a UI library for Roblox with a clean, modern look inspired by WinUI3. Everything is built at runtime with `Instance.new`, so there are no image dependencies and nothing to pre-build. You get the whole interface from code.

> **Work in progress.** Aetheris is not finished. Some features are still being built, and it may not have full exploit integration or full save-state support yet.

## Documentation

Setup, theming, the component API and examples all live in the docs:

**[Aetheris documentation ->](https://app.gitbook.com/s/WPkBDlqrRRp8P5YpSOrg)**

## Install

Grab the single-file build from [`dist/Aetheris.luau`](dist/Aetheris.luau) and load it:

```lua
loadstring(game:HttpGet("<raw url to dist/Aetheris.luau>"))()
```

## Build from source

```
tools\darklua.exe process src/Init.luau dist/Aetheris.luau
```

## License

MIT.
