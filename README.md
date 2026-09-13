<p align="center">
  <img src="assets/banner rectangular.png" alt="Aetheris" width="100%" />
</p>

<p align="center">
  <a href="https://github.com/Saint0-0/Aetheris/releases/latest"><img src="https://img.shields.io/github/v/release/Saint0-0/Aetheris?include_prereleases&label=release" alt="Latest release" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="License: MIT" /></a>
  <a href="https://dsc.gg/saintx"><img src="https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white" alt="Discord" /></a>
</p>

Aetheris is a UI library for Roblox with a clean, modern look, inspired by WinUI3, maclib and Fluent. Everything is built at runtime with `Instance.new`, so there are no image dependencies and nothing to pre-build. You get the whole interface from code.

> **Work in progress.** Aetheris is not finished. Some features are still being built, and it may not have full exploit integration or full save-state support yet.

## Download

**[Latest release ->](https://github.com/Saint0-0/Aetheris/releases/latest)**

Two files are attached to each release:

- **Aetheris.luau** - the single-file build, load it with `loadstring`.
- **Aetheris.rbxm** - a Roblox model (an `Aetheris` folder holding an `Init` ModuleScript). Drop it into `ReplicatedStorage` and require `Aetheris.Init`.

## Install

```lua
loadstring(game:HttpGet("https://github.com/Saint0-0/Aetheris/releases/latest/download/Aetheris.luau"))()
```

## Documentation

Setup, theming, the component API and examples all live in the docs:

**[Aetheris documentation ->](https://saint-3.gitbook.io/aetheris)**

## Build from source

The build pipeline lives in `build/` and is run with [lune](https://github.com/lune-org/lune):

```
tools\lune.exe run build
```

That produces two artifacts in `dist/`:

- `dist/Aetheris.luau` - the bundle, minified with darklua, header prepended.
- `dist/Aetheris.rbxm` - the Roblox model, built with rojo from the bundle.

## Credits

- **WinUI3** by Microsoft, for the visual language Aetheris is built around.
- **[maclib](https://brady-xyz.gitbook.io/maclib-ui-library)** by brady-xyz, for inspiration.
- **[Fluent](https://github.com/dawid-scripts/Fluent)** by dawid-scripts, for inspiration, and for the build tooling - the files in [`build/`](build) are adapted from [Fluent's `build/` folder](https://github.com/dawid-scripts/Fluent/tree/master/build).

## License

MIT.
