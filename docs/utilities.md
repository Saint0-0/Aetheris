# Utilities

The utility modules are the internal engine of Aetheris, and each one can be required on its own.

| Utility | What it does |
| --- | --- |
| [Tween](utilities/tween.md) | Central tween registry and spin manager, every animation in the library routes through it. |
| [Sound](utilities/sound.md) | One reusable Sound per named asset, all on a single SoundGroup so one volume covers the UI. |
| [Video Fade](utilities/video-fade.md) | Fades a VideoFrame with a UIGradient, because VideoFrame.Transparency does nothing. |
| [Icons](utilities/icons.md) | The Lucide icon set as name to rbxassetid, exposed as Aetheris.Icons. |
| [Odometer](utilities/odometer.md) | Per digit slot reel number roll, used by LiveStat. |
| [Page Fade](utilities/page-fade.md) | Page transitions through one CanvasGroup.GroupTransparency per page. |
| [KeybindDispatcher](utilities/keybinddispatcher.md) | One shared input listener for every Keybind row. |

## Requiring a utility

The utilities live in `src/Utils`, apart from Icons which is in `src/Assets`. With the source in `ReplicatedStorage.Aetheris` you require them by relative path:

```lua
local Tween = require(ReplicatedStorage.Aetheris.Utils.Tween)
```
