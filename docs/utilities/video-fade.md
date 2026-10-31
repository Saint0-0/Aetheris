# Video Fade

Fades a VideoFrame through a UIGradient.

`VideoFrame.Transparency` does not affect the rendered video, so the Video component adds a `UIGradient` named `FadeGradient` and fades that instead. `UIGradient.Transparency` is a NumberSequence that `TweenService` cannot interpolate, so `fade` steps it by hand every frame.

The window and tab fade systems look for the tagged gradient and fade it along with everything else, so you rarely call these yourself.

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
| `fade(grad, target, duration?, easing?, onComplete?)` | Move toward `target` over `duration` seconds, 0.3 by default. `easing` is `"Out"` (the default), `"InOut"` or `"Linear"`. `onComplete` runs when the move finishes or the gradient leaves the tree. |
