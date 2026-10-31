# Sound

The UI's central audio layer.

Each asset is one reusable `Sound` instance, and every one of them sits in a single `AetherisUI` SoundGroup in SoundService. That is what lets one volume slider cover the whole interface.

```lua
local Sound = require(ReplicatedStorage.Aetheris.Utils.Sound)

Sound.Preload(function(loaded, total, name, status)
    print(loaded .. "/" .. total)
end)

Sound.Play("UIOpen")
Sound.Play("Notification", { Volume = 0.5, PlaybackSpeed = 1.1 })
Sound.SetVolume(0.7)
```

## Named assets

`Sound.Assets` maps a name to an `rbxassetid://`, and `Preload` walks that table. An entry added here loads with everything else.

| Name | Plays |
| --- | --- |
| `UIStart` | When the window finishes opening. |
| `UIOpen` | When the window is restored from the minimize pill. |
| `UIClose` | When the window minimizes or is destroyed. |
| `Notification` | Toasts and modal dialogs. |
| `KeySystemOpen` | When the key card opens. |
| `KeySystemClose` | When the key card closes. |
| `UIShutdown` | Shipped as an asset, never played by the library. |

## Methods

| Method | Description |
| --- | --- |
| `Preload(progressCallback?)` | Load every asset through ContentProvider so the first `Play` has no delay. The callback receives `(loaded, total, name, status)` after each asset. A second call after a successful preload only repeats the final count. |
| `GetProgress()` | Load progress from 0 to 1, for a bar that would rather poll than take the callback. Returns 1 when nothing is pending. |
| `IsPreloaded()` | Whether every asset has finished loading. |
| `Play(name, properties?)` | Play a named sound and return its `Sound`. An unknown name warns and returns nil. `properties` sets one off fields such as `Volume` and `PlaybackSpeed`, and a retrigger restarts the sound instead of layering a copy. |
| `Stop(name)` / `StopAll()` | Stop one sound, or every sound. |
| `SetVolume(volume)` / `GetVolume()` | Master volume from 0 to 1, clamped, written to the SoundGroup. |
| `Release(name)` / `ReleaseAll()` | Destroy the instance so it can be collected rather than just silenced. `ReleaseAll` also clears the preload state. |

The settings page has a UI Volume slider from 0 to 100. It calls `SetVolume`, stores the value in the settings file, and the window applies it again the next time it opens.
