# Page Fade

The single source of truth for page transitions.

A page fades through one `CanvasGroup.GroupTransparency` on a per page layer. Nothing scans or snapshots the transparency of each descendant.

The old TabGroup and SettingsTabGroup fade systems captured a per element transparency base and put it back when the page returned. That fights any component state stored as transparency, such as a radio's selected image or a slider's sheen, so a stale snapshot could revert a user's selection after a theme change. One GroupTransparency per page removes that whole class of bug, and a CanvasGroup also fades a playing VideoFrame.

```lua
local PageFade = require(ReplicatedStorage.Aetheris.Utils.PageFade)

local layer = PageFade.Layer(parent, "Page1")
-- reparent the page content into layer
PageFade.Show(layer)
PageFade.Hide(layer)
PageFade.Crossfade(oldLayer, newLayer, function()
    print("done")
end)
```

## Constants

| Name | Value | Description |
| --- | --- | --- |
| `TIME` | `0.2` | The shared page transition duration, so every fade in the library matches. |
| `PRESET` | `"Fast"` | Preset name used for fades, routed through the Tween registry. |

## Methods

| Method | Description |
| --- | --- |
| `Layer(parent, name?)` | Create a full size transparent CanvasGroup under `parent`. Page content goes inside it, and its GroupTransparency is the fade value. |
| `Snap(layer, transparency)` | Set the fade at once and cancel anything in flight. |
| `Show(layer, instant?, onComplete?)` | Fade to 0. `instant` snaps instead of tweening, `onComplete` runs when the fade finishes. |
| `Hide(layer, instant?, onComplete?)` | Fade to 1, with the same two optional arguments. |
| `Crossfade(outgoing, incoming, onComplete?)` | Fade the outgoing layer out while the incoming one fades in, both over `TIME`. `onComplete` runs once both are done. |
| `FadeDecorations(group, hidden, instant?)` | Fade UIStroke and UIShadow, which GroupTransparency does not cover. The fade methods call it for you. |
| `InvalidateDecorationBases()` | Mark the decoration list dirty so a theme change is picked up on the next fade. |
