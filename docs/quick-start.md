# Quick Start

## Loading the library

Aetheris is distributed as a single file. Load it however you normally run scripts:

```lua
loadstring(game:HttpGet("<raw url to dist/Aetheris.luau>"))()
```

In Studio, you can instead require the module directly if you have the source synced into `ReplicatedStorage.Aetheris`.

## Your first window

The only entry point you need is `CreateWindow`. It returns a window you build tabs and sections on.

```lua
local Aetheris = require(game.ReplicatedStorage.Aetheris.Init)

local window = Aetheris:CreateWindow({
    Title = "Aetheris",
    Description = "my first window",
    Theme = "Default",
    MinimizeKey = "LeftControl",
})
```

## Adding a tab and a toggle

```lua
local tab = window:Tab("Main", Aetheris.Icons["home"])
local section = tab:Section({ Name = "General", Side = "Left" })

section:Toggle({
    Name = "Enable feature",
    Default = true,
    Callback = function(state)
        print("toggled:", state)
    end,
})
```

That's the whole pattern: create a window, add tabs, add sections to those tabs, then add components to the sections. Everything else in these docs is just detail on each piece.
