<p align="center">
  <img src="assets/banner.png" alt="Aetheris" width="100%" />
</p>

<h1 align="center">Aetheris</h1>

<p align="center">
  A modern, WinUI3-styled UI library for Roblox — built entirely with <code>Instance.new</code>, with no external assets required.
</p>

<p align="center">
  <a href="https://github.com/Saint0-0/Aetheris/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/Saint0-0/Aetheris?style=flat-square" /></a>
  <a href="https://github.com/Saint0-0/Aetheris/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/Saint0-0/Aetheris?style=flat-square" /></a>
  <img alt="Luau" src="https://img.shields.io/badge/language-Luau-00A2FF?style=flat-square" />
  <img alt="Rojo" src="https://img.shields.io/badge/build-Rojo-FF7A7A?style=flat-square" />
</p>

---

## Overview

**Aetheris** is a fully customisable Roblox UI library with a clean, modern, WinUI3-inspired aesthetic. Every element is constructed at runtime with `Instance.new` — there are no image dependencies, no pre-built GUI hierarchies, and no third-party UI frameworks. Drop the library in and build interfaces entirely from code.

It ships with a **theme engine** covering 23 hand-tuned themes (with live switching and a colour crossfade), a full component set, popups and notifications, and support for running both inside Roblox Studio and within a script executor.

## Features

- **Pure `Instance.new`** — no external assets or image dependencies.
- **23 built-in themes** with live switching and a smooth colour crossfade. Every component is fully theme-aware.
- **Complete component set** — toggles, sliders, steppers, keybinds, text inputs, dropdowns, colour pickers, radio groups, progress bars, status lists, buttons, labels, paragraphs, dividers, video, and more.
- **Popups & notifications** — dropdowns, colour pickers, tooltips, and toast notifications (alert / error / variable).
- **Per-element transparency controls** — glass-style sidebars, frosted content areas, and per-theme window chrome.
- **Studio & executor support** — designed to run in both environments.
- **Rojo-based workflow** — clean, version-controlled source tree.

## Documentation

Full documentation — installation, theming, the component API, and examples — lives in the official GitBook:

> **[Aetheris Documentation →](https://example.gitbook.io/aetheris)** _<!-- TODO: replace with the live GitBook link -->_

## Installation

### Roblox Studio (Rojo)

1. Clone this repository.
2. Sync the project into Studio with [Rojo](https://rojo.space/) using the included `default.project.json`:
   ```
   rojo serve
   ```
3. Connect the Rojo plugin in Studio. The library is synced into `ReplicatedStorage.Aetheris`.

### Prebuilt bundle

A single-file bundle (`dist/Aetheris.luau`) can be generated and executed directly in an executor:

```
darklua process src/Init.luau dist/Aetheris.luau
```

## Project structure

```
Aetheris/
├─ src/                    Library source (Rojo syncs into ReplicatedStorage.Aetheris)
│  ├─ Core/                Window, TabGroup, Section, and settings
│  ├─ Components/          UI components
│  ├─ Themes/              Theme engine and definitions
│  ├─ Popups/              Popups and notifications
│  ├─ Utils/               Tween, sound, and helper utilities
│  └─ Assets/              Icons
├─ example/                Demo harness (full component showcase)
├─ assets/                 README banner and branding
├─ tools/                  rojo + darklua
├─ default.project.json    Rojo project
└─ .luaurc                 Luau language config
```

## Building

Build a place file from source:

```
rojo build default.project.json -o build/Aetheris.rbxl
```

Bundle the library into a single file:

```
darklua process src/Init.luau dist/Aetheris.luau
```

## Requirements

- Roblox Studio (or a Luau-compatible executor)
- [Rojo](https://rojo.space/) 7.x for live sync
- [darklua](https://darklua.com/) for single-file bundling

## Contributing

Contributions are welcome. Please open an issue to discuss larger changes before submitting a pull request, and keep the code style consistent with the existing modules (string-based `require`, no `script.Parent` references).

## License

Released under the MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center"><sub>Built with Luau · Themed with care · Aetheris</sub></p>
