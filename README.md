# Aetheris

A WinUI3-styled Roblox UI library, built purely with `Instance.new`. Fully
themeable, fully customisable, and designed to run both in Studio and inside an
executor.

## Project layout

```
Aetheris/
  default.project.json   Rojo project (maps src/ into Studio)
  src/                   Library source (Rojo syncs this into ReplicatedStorage.Aetheris)
  tools/                 rojo.exe + Rojo.rbxm (Studio plugin)
  .luaurc                Luau language config
  .vscode/               Editor settings
```

## Development workflow

1. Open this folder in VS Code.
2. Start the Rojo server:
   ```
   tools\rojo.exe serve
   ```
3. In Roblox Studio, open the place, click the **Rojo** plugin, and Connect.
4. Edit files under `src/` — Studio updates live.

## Building a place file

```
tools\rojo.exe build default.project.json -o build/Aetheris.rbxl
```
