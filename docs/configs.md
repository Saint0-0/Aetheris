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

-- Apply JSON text without touching the active file.
local ok, err = configs:Apply(jsonText)

-- Write JSON text to a named file without making it the active config.
local written, name = configs:Write("shared", jsonText)
```

Files live under `Aetheris/Games/<placeId>/<window title>/` as JSON, one per config name. Saved files are pretty-printed with sorted keys so they stay readable and easy to share.

## What gets saved

Components created inside a section register automatically: Toggle, Slider, Stepper, Keybind, TextInput, Dropdown, ColorPicker and RadioButtonGroup. Pass `NoSave = true` on any of them to keep it out of configs.

Each entry is keyed as `Section.Component`, so two toggles in different sections never collide, and renaming a section or component starts a fresh entry rather than restoring the old value.

Loading pushes each saved value back through the component's setter. Colors are stored as RGB triplets, dropdown selections as their `value`s, radio groups as the selected button's name.

The active theme rides along too: saving records the window's current theme, and loading a config switches to it before the component values go back.

## Auto-save

Switch on `AutoSaveConfigs` on the UI Settings page and every change is written back to the active config about half a second after the last edit. The active config is whichever one you last saved or loaded (`configs.Active`).

## The Configs page

The built-in Configs settings page is a small manager UI over all this:

* **Active Config** — a bare "Loaded: …" label showing which config the UI reflects, the auto-save toggle, a name box, and Save Current Settings (a blank name saves over the loaded config).
* **Config Library** — a Config Files dropdown with Load Selected, Delete Selected and Refresh List.
* **JSON Editor** — the selected config in an editable code view. Click the code to edit, then Apply Editor to UI, Save Editor to File, or Revert Editor. Paste from Clipboard drops a shared config straight into the editor, so players can import a preset without touching the file system.

Saving from the editor validates the JSON first and writes it back pretty-printed. The editor keeps its content after Apply so you can still save it under a new name.
