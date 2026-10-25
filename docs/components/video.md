# Video

Embeds a Roblox `VideoFrame` with the library's styling.

```lua
section:Video({
    VideoId = "rbxassetid://5670794788",
    Loop = true,
    Height = 90,
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `VideoId` | string | The video asset id. |
| `Loop` | bool | Loop playback. |
| `Height` | number | Height in pixels. |
| `Volume` | number | Playback volume 0–1 (`:SetVolume` / `:GetVolume` change it live). |

## Notes

The video fades with the rest of the UI (minimize, tab switch, theme switch) via a gradient handle — so it dims and restores in step with everything else instead of popping.

The video pauses the moment its page is switched away (and resumes only if it was playing) — this is always on, independent of the **Page Animations** setting.
