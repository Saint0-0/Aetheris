# Test Script

The repository ships with a single demo that builds **every** component at least once. It's the fastest way to see the whole library working and to check your install is correct.

## The script

`example/Aetheris_Test.client.luau`. It's self-contained — everything is built with `Instance.new`, so there are no assets to download first.

## How to run it

**In Studio:** drop the file into `StarterPlayerScripts` as a `LocalScript`, then press Play.

**In an executor:** paste the file contents while the game is running.

The require line at the top points at `ReplicatedStorage.Aetheris`. Change it to match wherever you've put the module.

## What it covers

* **Window** — `CreateWindow`, tabs, dividers, sections, the settings tab, and a dropdown that switches themes live.
* **Components** — toggle (including a confirm prompt), slider, stepper, keybind, text input, dropdown (single, multi and uncapped), colour picker, radio group, status list, progress bars, buttons, labels, paragraphs, dividers, video, console, live stats and code views.
* **Popups** — alert, error and rich toasts, plus the confirm/cancel `UINotification` dialog.
* **Executor detection** — a section that reads the current executor and what it can do.

Every settings table is spelled out inline, so the file doubles as a working reference for each component's options.
