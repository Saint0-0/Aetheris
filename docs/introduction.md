# Introduction

![Aetheris](https://4126224400-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FWPkBDlqrRRp8P5YpSOrg%2Fuploads%2FDtaizQi9vypWbdXRqpXF%2Fbanner%20rectangular.png?alt=media&token=6e607f7d-d8f4-4a5b-be9d-6abe3cb6fb12)

> **Aetheris is a work in progress.** It is not finished yet. Some features are still being built, and it may not have full exploit integration or full save-state support at this time. Expect rough edges and things that change without notice.

## [**Discord**](https://dsc.gg/saintx)

Aetheris is a UI library for Roblox with a clean, modern look. It takes inspiration from **WinUI3**, **maclib**, **Rayfield Gen 2** and **Fluent**. You build the whole interface from code.

It ships with a theming engine and 45 themes, live theme switching with a smooth colour fade, a full set of components, popups and notifications, a key system, and per-game config saving. It runs in Studio and inside a script executor.

## What's inside

* Every element is created with `Instance.new` — nothing extra to download.
* 45 built-in themes, all switchable at runtime, and every component follows the active theme.
* Components: toggles, sliders, steppers, keybinds, text inputs, dropdowns, colour pickers, radio groups, progress bars, status lists, buttons, labels, paragraphs, dividers, video, console, live stats, code views and viewports.
* Popups and notifications: dropdowns, colour pickers, tooltips and toasts (alert, error and variable).
* A key system with a loading screen, Platoboost and Panda validators, or your own check function.
* Per-game configs, so players can save and reload the state of every component.
* Per-element transparency, for glass-style sidebars and frosted content areas.
* Works in Studio and in executors.

## What's not done yet

* **Save state** is only partial. Window-level settings (theme, UI scale, minimize key, volume) persist when the executor provides a file API. Component state persists through [configs](configs.md), which you trigger yourself.
* **Executor support** is best-effort. Behaviour differs between executors, and some don't expose the file APIs the settings store relies on.

## Credits

* **WinUI3** by Microsoft, for the visual language Aetheris is built around.
* [**maclib**](https://brady-xyz.gitbook.io/maclib-ui-library) by brady-xyz, for inspiration.
* [**Fluent**](https://github.com/dawid-scripts/Fluent) by dawid-scripts, for inspiration.
* [**Rayfield Gen2**](https://github.com/SiriusSoftwareLtd/rayfield-gen2) by shlex, for inspiration on a few components.

## Where to start

If you've never used Aetheris before, start with [Quick Start](quick-start.md). If you want to understand how a window is put together, read [Core Concepts](core-concepts.md) first.
