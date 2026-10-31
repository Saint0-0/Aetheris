# Live Switching

`window:SetTheme(nameOrTable)` repaints the whole UI while it's on screen. Nothing is rebuilt — every colour property is re-resolved in place.

What happens on a switch:

* Colours crossfade over about 0.7 seconds instead of snapping.
* In-flight tweens under the window are cancelled first, so a tween started by the old theme can't finish late and overwrite the new colours.
* Spinning gradients pause during the switch and restart after it.
* Toast notifications already on screen recolour in place, including their accent rim and glow.
* Page decorations (strokes, dividers) restore to their resting transparency once the switch lands.
* The new theme is saved, so the next launch starts on it.

Components hold their on/off state across a switch — a toggle that was on stays on and keeps its "on" colour under the new theme.

```lua
window:SetTheme("Ember")

-- or a custom table, same call
window:SetTheme(myThemeTable)
```

The key screen follows the same rules if it's still up when the theme changes.
