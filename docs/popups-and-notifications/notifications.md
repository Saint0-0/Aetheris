# Notifications

Toasts are small cards that slide into the bottom-right corner, count down and destroy themselves. There are three flavours:

```lua
window:Alert({ Title = "Heads up", Description = "Your key expires soon." })
window:Error({ Title = "Failed", Description = "Could not reach the server." })
window:Toast({ Title = "Saved", Description = "Settings written to disk." })
```

Each returns the notification, and each plays the notification sound unless the UI volume is muted.

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Title` | string | The bold line at the top. |
| `Description` | string | The body text; wraps as needed. |
| `Duration` | number | Seconds before it dismisses itself. Default 5. |
| `Icon` | string | Image id, replacing the flavour's default icon. |
| `IconColor` | Color3 | Overrides the icon tint. |
| `GradientColor` | Color3 | Overrides the accent bloom behind the card. |
| `ShowBackground` | boolean | Add a wallpaper wash behind the text. |
| `BackgroundImage` | string | Image id for that wash. |
| `Actions` | table | Up to two `{ Text, Callback }` buttons. |

```lua
window:Toast({
	Title = "Update available",
	Description = "Version 2.0 is ready to install.",
	Duration = 8,
	Actions = {
		{ Text = "Install", Callback = function() print("installing") end },
		{ Text = "Later", Callback = function() end },
	},
})
```

Clicking an action runs its callback and closes the toast. The timer bar along the bottom shows what's left; the X dismisses early.

## Colours

Alerts are amber, errors are red, toasts are green — but the exact shade comes from the theme. `NotificationAlertAccent`, `NotificationErrorAccent` and `NotificationVariableAccent` are tinted toward each theme's accent, so a toast in Gruvbox doesn't look identical to one in Alpine. The rim, glow, icon and timer bar all match the flavour accent, and everything recolours live if the theme switches while the toast is up.

## The confirm dialog

`window:UINotification` is the one modal: a centre-screen card that asks for a decision.

```lua
window:UINotification({
	Title = "Delete save?",
	Description = "This cannot be undone.",
	ConfirmText = "Delete",
	CancelText = "Keep",
	OnConfirm = function() print("confirmed") end,
	OnCancel = function() print("cancelled") end,
})
```

Only one dialog can be open at a time — opening another closes the first.
