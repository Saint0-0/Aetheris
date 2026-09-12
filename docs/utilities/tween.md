# Tween

The tween utility is what makes the UI feel alive. It wraps Roblox's `TweenService` and adds named presets, spin management and group cancellation.

## Presets

Common motion is exposed as named presets rather than raw `TweenInfo`, so the whole UI stays consistent:

- `Fast` — quick transitions (hover, small state changes).
- `Smooth` — the default crossfades.
- `OnOff` — used by toggles and indicators.
- `Minimize` / `MinimizeSnappy` — the window minimize/restore animation, chosen by the window's `AnimationStyle`.
- `SpinIdle` — the idle rotation for spinning gradients.

## Spins

Spinning gradients (tab backdrops, slider fills, progress bars) route through a central spin system, so they can be paused, resumed and restarted as a group.

## Cancellation

`CancelAll(instance)` stops every tween on an instance and its descendants — used before a theme switch so stale tweens can't overwrite new values.
