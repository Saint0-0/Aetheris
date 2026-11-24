# Page Fade

The single source of truth for page transitions.

A page fades through [Tree Fade](tree-fade.md), which walks the page and tweens each instance's own transparency properties. There is no page-wide `CanvasGroup`: a group rasterises its content into a texture capped at 1024px, which softens text and images as the window grows.

The layer is still a plain transparent `Frame` that owns its page content, but the fade values live on the descendants. Tree Fade captures every opacity base when the page hides and restores them when it returns, so a page can sit invisible for a while without losing per-component values such as a radio's selected image or a slider's sheen.

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
| `WINDOW_PRESET` | `"WindowFade"` | Longer preset used for the whole window minimize, restore and close. |

## Methods

| Method | Description |
| --- | --- |
| `Layer(parent, name?)` | Create a full size transparent Frame under `parent`, register it with Tree Fade and start it marked hidden. Page content goes inside it. |
| `Snap(layer, transparency)` | Set the fade at once and cancel anything in flight. |
| `Show(layer, instant?, onComplete?, preset?)` | Fade the page in. `instant` snaps instead of tweening, `onComplete` runs when the fade finishes. |
| `Hide(layer, instant?, onComplete?, preset?)` | Fade the page out, with the same optional arguments. |
| `Crossfade(outgoing, incoming, onComplete?)` | Fade the outgoing layer out while the incoming one fades in, both over `TIME`. `onComplete` runs once both are done. |
| `FadeDecorations(group, hidden, instant?, preset?)` | Fade UIStroke and UIShadow on a CanvasGroup. Kept for the minimize pill and popups, which still composite with GroupTransparency. |
| `InvalidateDecorationBases()` | Mark the decoration list dirty so a theme change is picked up on the next fade. |

## Window layers

The window shell is also a Tree Fade root, but it is marked `SkipFadeRoots` so a shell fade never touches page layers inside it. Minimize, restore and close handle the page layer they are showing separately; that keeps page crossfades and window fades from overwriting each other.
