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

## Notes

The video fades with the rest of the UI (minimize, tab switch, theme switch) via a gradient handle — so it dims and restores in step with everything else instead of popping.
