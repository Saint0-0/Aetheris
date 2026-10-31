# Configs

Aetheris can save the state of your components to disk and restore them later, in the style of Fluent's SaveManager. Components built through sections register themselves; you decide when to save and load.

Configs need an executor with a file API (`writefile`, `readfile`). Without one, `window.ConfigManager.Available` is false and save/load return an error.

## Usage

```lua
local configs = window.ConfigManager

configs:Save("default")
configs:Load("default")

print(unpack(configs:List())) -- every saved config name
configs:Delete("old")
```

Files live under `Aetheris/Games/<placeId>/<window title>/` as JSON, one per config name.

## What gets saved

Components created inside a section register automatically: Toggle, Slider, Stepper, Keybind, TextInput, Dropdown, ColorPicker and RadioButtonGroup. Pass `NoSave = true` on any of them to keep it out of configs.

Each entry is keyed as `Section.Component`, so two toggles in different sections never collide, and renaming a section or component starts a fresh entry rather than restoring the old value.

Loading pushes each saved value back through the component's setter. Colors are stored as RGB triplets, dropdown selections as their `value`s, radio groups as the selected button's name.

## Auto-save

Switch on `AutoSaveConfigs` on the UI Settings page and every change is written back to the active config about half a second after the last edit. The active config is whichever one you last saved or loaded (`configs.Active`).

## The Configs page

The built-in Configs settings page is a small manager UI over all this: a name box to save under, a dropdown of saved configs with load and delete buttons, an auto-save toggle, and a preview of the selected config's raw JSON.
