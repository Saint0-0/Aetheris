# Tween

The central tween registry and spin manager for the whole library.

Only one tween runs per instance and property set, so a new tween cancels the previous one instead of fighting it. The registry is weak keyed, so a destroyed instance never keeps its tweens alive. After a theme switch the library cancels everything with `CancelAll` and then calls `RestartSpins`.

```lua
local Tween = require(ReplicatedStorage.Aetheris.Utils.Tween)

local handle = Tween.Play(frame, "Smooth", { BackgroundTransparency = 0.5 })
Tween.Play(frame, TweenInfo.new(0.2), { Position = UDim2.fromScale(0, 0) })
```

`Play` takes a `TweenInfo` or a preset name and returns a handle `{ Tween, Instance, Key, Paused }`. Its `replace` argument defaults to true, which is what cancels the tween already running on those properties.

## Methods

| Method | Description |
| --- | --- |
| `Play(instance, info, properties, replace?)` | Start a tween and return its handle. |
| `Pause(handle)` / `Resume(handle)` | Pause mid motion and continue from the same point. |
| `Cancel(handle)` | Stop one tween and drop it from the registry. |
| `CancelAll(instance)` | Stop every tween tracked on an instance. |
| `CancelProperty(instance, propertyName)` | Stop one property's tween and leave the others running. |
| `CancelAllUnder(root)` | `CancelAll` on the root and every descendant that has tweens. |
| `Group(list)` | Play `{{instance, info, properties}, ...}` as one batch and return the handles. |
| `CancelGroup(handles)` / `PauseGroup(handles)` / `ResumeGroup(handles)` | Cancel, pause or resume a list of handles. |
| `StartSpin(instance, properties, preset?)` | Start an infinite linear tween such as `{ Rotation = 360 }`. Returns nil while spins are disabled. |
| `StopSpin(instance)` | Stop a spin and forget it. |
| `PauseSpin(instance)` / `ResumeSpin(instance)` | Pause at the current angle and resume from it. |
| `GateSpinOnVisibility(instance)` / `UngateSpin(instance)` | Hold a spin while its instance is off screen and continue when it comes back. |
| `SetSpinWanted(instance, wanted)` | Say whether a spin should run, whatever the visibility says. |
| `RestartSpins()` | Start every registered spin again, used after a theme switch. |
| `SetSpinsEnabled(enabled)` / `SpinsEnabled` | The global spin switch. Disabling stops each spin and resets it to 0. |

## Presets

Pass a preset name as `info` and it routes through the registry like any other tween.

| Preset | Detail |
| --- | --- |
| `Fast`, `Smooth`, `Burst` | General purpose easing, 0.2s Quad Out, 0.3s Quad InOut, 0.6s Cubic Out. |
| `Click`, `ClickQuint`, `Release`, `ClickRelease` | Button press and release. |
| `HoverIn`, `HoverOut`, `Hover` | Pointer hover. |
| `OnOff` | Toggle style transitions. |
| `PageSwap`, `FadeOut` | Page transitions, 0.25s and 0.12s. |
| `WindowToggle`, `WindowToggleSnappy` | Window minimize, restore and maximize, 0.18s and 0.12s. |
| `Minimize`, `MinimizeSnappy` | Older minimize presets, still in the table but nothing in the library plays them. |
| `SpinIdle`, `SpinStat`, `SpinBurst` | Infinite linear spins, one revolution every 8s, 12s and 1.2s. |
