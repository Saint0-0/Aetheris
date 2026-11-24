# Tree Fade

Fades a whole UI subtree without a `CanvasGroup`.

A CanvasGroup rasterises everything under it into a texture capped at 1024px, so wide windows and tall pages came out blurry. Tree Fade instead walks the tree and tweens each instance's own opacity properties. Colours, layout and hit areas are untouched.

```lua
local TreeFade = require(ReplicatedStorage.Aetheris.Utils.TreeFade)

TreeFade.Set(root, true) -- fade out, capturing the current look
TreeFade.Set(root, false, false, "Fast", function()
    print("restored")
end)
```

## What it fades

| Class | Properties |
| --- | --- |
| `GuiObject` | `BackgroundTransparency` |
| `TextLabel`, `TextButton`, `TextBox` | `TextTransparency`, `TextStrokeTransparency` |
| `ImageLabel`, `ImageButton` | `ImageTransparency` |
| `ScrollingFrame` | `ScrollBarImageTransparency` |
| `UIStroke`, `UIShadow` | `Transparency` |
| `CanvasGroup` | `GroupTransparency` (children are skipped) |
| `VideoFrame` | Tagged `UIGradient.Transparency` (the raw frame property has no visual effect) |
| Tagged fade veil | `BackgroundTransparency`, inverted: opaque when hidden, invisible when shown |

## Methods

| Method | Description |
| --- | --- |
| `Set(root, hidden, instant?, preset?, onComplete?, skipRoots?)` | Hide or show. Hiding captures every opacity base; showing restores them. `onComplete` fires when the tweens finish. |
| `Snap(root, hidden, skipRoots?)` | Apply the end state at once. |
| `MarkRoot(root)` | Register a root owned by another fade so a parent can skip it. |
| `IsRoot(root)` | Whether a root was registered. |
| `IsHidden(inst)` | Whether this instance or an ancestor was left faded out. |

## Behaviour notes

- State is stored per root, not per instance, and is cleared once a show completes.
- Hiding an already hidden root reuses the stored state; it never captures faded values as the new base.
- Every `Set`/`Snap` on a root bumps a generation, so a callback from a superseded fade (a fast tab double-click, a theme switch) does not run.
- A cancelled tween never reports `Completed`, so each fade arms a fallback timer to keep callers moving.
- `skipRoots` makes a parent fade ignore registered child roots; this is how the window shell avoids clobbering page layers.
- Videos fade through the `<IsVideoFade>` gradient that `Utils/VideoFade` attaches, so the video itself dims rather than just its frame.
- Viewports have no transparency. Components that render into one (like `Viewport`) can add a frame tagged `<IsFadeVeil>`; the fade covers it when hiding and uncovers it when showing.
