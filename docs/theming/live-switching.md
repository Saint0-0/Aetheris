# Live Switching

Switching themes at runtime is smooth — Aetheris crossfades the colours rather than snapping them.

## How it works

1. Every element's current colours are snapshotted.
2. The new theme's values are applied instantly.
3. Any element whose colour changed is restored to its old colour and tweened to the new one.

So a theme switch reads as the whole UI fading from the old theme into the new one — no dim overlay, no flash.

## What else happens on a switch

- Spinning gradients (tab backdrops, slider fills, progress bars) are restarted, since the switch cancels in-flight tweens.
- Cached popups are dropped so they rebuild with the new theme.
- Page-fade caches are re-primed so the next tab switch restores the correct values.

## Timing

The crossfade duration is controlled by `ColorFadeTime` on the theme manager (default `0.35`). You can change it at runtime:

```lua
Aetheris.ThemeManager.ColorFadeTime = 0.5
```
