# Carousel

A swipeable strip of image and video pages, with a blob indicator over the media.

```lua
local carousel = section:Carousel({
	{ "rbxassetid://92458734285074", "image" },
	{ "rbxassetid://5670794788", "video" },
	{ "rbxassetid://11094025229", "image" },

	Height = 160,
	Interval = 4,
})

carousel:Next()
```

## Pages

The array part of the settings table is the page list. Each entry is `{ assetId, kind }`, where `kind` is `"image"` or `"video"` and defaults to `"image"`. A carousel accepts at most five pages.

Dragging left or right changes the page. The blob row sits over the bottom of the media; the active blob fills with the current page's progress.

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Component name. |
| `Height` | number | Height in pixels. Defaults to `160`. |
| `Interval` | number | Auto-advance delay in seconds. Defaults to `4`. |
| `AutoAdvance` | boolean | Advance to the next page on a timer. On by default. |
| `Volume` | number | `0` to `1` for video pages. Muted by default. |

Image pages advance on the interval. A video page advances when its loop restarts, so the blob always fills completely first. Videos on hidden pages pause, and only the current page decodes.

## Methods

| Method | Description |
| --- | --- |
| `:SetPage(number)` | Jump to a page, one-based. |
| `:Next()` | Move forward one page. |
| `:Prev()` | Move back one page. |
| `:GetPage()` | Returns the current page, one-based. |
| `:GetPageCount()` | Returns the page count. |
| `:SetHeight(number)` | Resize the carousel. |
| `:GetHeight()` | Returns the current height. |
