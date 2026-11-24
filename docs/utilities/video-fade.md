# Video Fade

Fades a VideoFrame through a UIGradient.

`VideoFrame.Transparency` does not affect the rendered video, so this utility attaches a `UIGradient` named `FadeGradient` and fades that instead. `UIGradient.Transparency` is a NumberSequence that `TweenService` cannot interpolate, so `fade` steps it by hand every frame.

The built-in `Video` and `Carousel` components no longer fade through this: they wrap the frame in a CanvasGroup and tween `GroupTransparency`, which is smoother and works with page fades. `Video` keeps a `FadeGradient` attached so code that drives it directly still works. Reach for `VideoFade` when you own a bare VideoFrame and cannot add a group; the tree fade picks up the tagged gradient automatically.

```lua
local VideoFade = require(ReplicatedStorage.Aetheris.Utils.VideoFade)

local grad = VideoFade.attach(videoFrame)
VideoFade.fade(grad, 1)
local value = VideoFade.get(grad)
```

## Methods

| Method | Description |
| --- | --- |
| `attach(videoFrame)` | Create and parent the `FadeGradient` UIGradient, and return it. |
| `set(grad, value)` | Write the transparency at once, 0 visible and 1 hidden. |
| `get(grad)` | Read the current transparency, 0 when the gradient has no keypoint. |
| `fade(grad, target, duration?, easing?, onComplete?)` | Move toward `target` over `duration` seconds, 0.3 by default. `easing` is `"Out"` (the default), `"InOut"` or `"Linear"`. `onComplete` runs when the move finishes. Returns a handle shaped like `Tween.Play`'s, so `handle.Tween.Completed` fires `Enum.PlaybackState.Completed` on finish. |
| `cancel(grad)` | Stop the running fade on this gradient. Retired fades report no completion. |

Starting a new fade on the same gradient retires the previous one, so a fast page change cannot leave two loops fighting over the sequence.
