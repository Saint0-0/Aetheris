# Graph

A line graph drawn from straight segments, with a value readout in the corner. Points animate between updates, so a live feed slides instead of jumping.

```lua
local graph = section:Graph({
	Name = "Throughput",
	Height = 130,
	MaxPoints = 40,
	Format = "number",
})

task.spawn(function()
	while task.wait(1) do
		graph:Push(math.random(20, 90))
	end
end)
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Name` | string | Heading above the plot. |
| `Points` | table | Starting values, oldest first. |
| `MaxPoints` | number | Values kept on screen; the oldest roll off. Default `60`. |
| `Height` | number | Plot height in pixels. Default `120`. |
| `Format` | string or function | `"number"`, `"percent"`, `"studs"`, `"time"`, or a function that formats the readout. |
| `MinValue` | number | Fixed lower bound. Omit to auto-scale. |
| `MaxValue` | number | Fixed upper bound. Omit to auto-scale. |
| `ShowGrid` | boolean | Draw the horizontal grid lines. On by default. |
| `ShowPoints` | boolean | Draw a dot at each value. On by default. |
| `Animate` | boolean | Interpolate between updates. On by default. |
| `Duration` | number | Seconds per interpolation. Default `0.35`. |
| `LineColor` | Color3 | Line colour. Defaults to the theme accent. |
| `Thickness` | number | Line thickness in pixels. Default `2`. |
| `GridColor` | Color3 | Grid tint. Defaults to the theme tertiary colour. |

Without `MinValue`/`MaxValue` the graph scales to the smallest and largest visible value, with a small margin. Fix the bounds when several graphs should share a scale.

## Methods

| Method | Description |
| --- | --- |
| `:SetPoints(points)` | Replace every value. |
| `:Push(value)` | Append a value, dropping the oldest past `MaxPoints`. |
| `:SetValue(index, value)` | Change one point by position. |
| `:GetPoints()` | Returns a copy of the values. |
| `:SetRange(min, max)` | Fix or release (`nil`) the vertical bounds. |
| `:SetLineColor(colour)` | Set the line colour, or `nil` to follow the theme. |
| `:SetAnimated(bool)` | Turn interpolation on or off. |
| `:SetFormat(formatter)` | Change the readout format. |
| `:SetGridVisible(bool)` | Show or hide the grid. |
| `:Clear()` | Remove every point. |
| `:SetName(string)` | Change the heading. |
| `:SetVisible(bool)` | Show or hide. |
| `:GetVisible()` | Returns whether it is showing. |
| `:Destroy()` | Remove the graph. |
