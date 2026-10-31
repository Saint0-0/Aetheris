# Key System

Passing a `KeySystem` table to `CreateWindow` gates the window behind a key. Before anything builds, Aetheris shows a combined loading and key card: it warms the UI assets and sounds, starts your key services, checks for a saved key, then asks for one if needed.

```lua
local window = Aetheris:CreateWindow({
	Title = "My Script",
	KeySystem = {
		Key = "hello",
		SaveKey = true,
		URL = "https://example.com/getkey",
		Discord = { Link = "https://dsc.gg/saintx", Id = "1234567890" },
	},
})
```

If the card is closed without a valid key, `CreateWindow` returns `nil` and your window never opens — check the result if your script needs to know.

## Options

| Key | Type | What it does |
| --- | --- | --- |
| `Key` | string, table or function | One key, a list of keys, or `function(key) return valid, reason end`. |
| `API` | table | Key services to validate against. See below. |
| `URL` | string | Link the "Get a key" button copies when no service provides one. |
| `Discord` | string or table | Invite the Discord card copies. A table can add `Id` for live member counts. |
| `SaveKey` | boolean | Remember an accepted key and skip the prompt next launch. |

The card itself takes the window's `Title` and `Theme`, is draggable, and has an X in the top-right corner to bail out.

## Key services

Each `API` entry has a `Type`:

| Type | Fields | Notes |
| --- | --- | --- |
| `"Platoboost"` | `ServiceId`, `Secret` | `UseNonce = false` opts out of nonce checking. |
| `"Panda"` | `ServiceId` | |
| `"Custom"` | `Validate`, `GetLink` | `Validate(key)` returns `valid, reason`; `GetLink()` returns the key URL. |
| `"Stub"` | — | Never validates; useful while wiring things up. |

```lua
KeySystem = {
	API = {
		{ Type = "Platoboost", ServiceId = 1234, Secret = "..." },
		{ Type = "Custom", Validate = function(key)
			return key == "admin", "ask in discord"
		end },
	},
}
```

A key is accepted if any source says it's valid — the static `Key` or any service.

## Saved keys

With `SaveKey = true` an accepted key is written to `Aetheris/Keys/<placeId>.json` and re-checked on the next launch. If it's no longer valid the card says so and asks for a new one. The record also tracks how many checks passed and failed, visible from the Information card.

Without a file API the record can't be stored, so the key is asked for every launch.

## The loading card

The loading phase does real work and reports it on the progress bar:

1. **Loading assets** — preloads the icons and images the UI paints with.
2. **Loading sounds** — preloads every UI sound.
3. **Starting key services** — initialises each entry in `API`.
4. **Checking saved key** — re-validates a stored key, if any.

If you configured a `KeySystem` with nothing to validate against, the card runs the loading phase and then continues straight into the window.
