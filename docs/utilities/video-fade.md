# Video Fade

Roblox `VideoFrame`s don't fade via `Transparency`, so Aetheris fades them by tweening a `UIGradient` attached to the frame instead.

## Why it exists

When the window minimizes, a tab switches, or the theme changes, everything fades as a group. Video has to fade with it — and the normal transparency property does nothing on a video. `VideoFade` is the handle the fade system uses for video specifically.

You don't usually call it directly; the tab and window fade systems detect the tagged gradient and fade it for you.
