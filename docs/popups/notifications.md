# Notifications

Aetheris has three toast notifications. They appear above the window, stack, and self-dismiss after their duration.

## Alert

A neutral informational toast.

```lua
window:Alert({
    Title = "Alert",
    Description = "This is an alert.",
    Duration = 4,
})
```

## Error

A red error toast.

```lua
window:Error({
    Title = "Error",
    Description = "Something went wrong.",
    Duration = 4,
})
```

## Variable

A flexible toast — custom icon, icon colour, gradient and action buttons.

```lua
window:VariableNotification({
    Title = "Update available",
    Description = "Version 2.0 is ready to install.",
    Duration = 8,
    Icon = "rbxassetid://8445470559",
    IconColor = Color3.fromRGB(96, 165, 250),
    GradientColor = Color3.fromRGB(139, 92, 246),
    ShowBackground = true,
    Actions = {
        { Text = "Install", Callback = function() print("install") end },
        { Text = "Later",   Callback = function() print("later") end },
    },
})
```

## Options

| Key | Type | Description |
| --- | --- | --- |
| `Title` | string | Heading. |
| `Description` | string | Body text. |
| `Duration` | number | Seconds before it dismisses. |
| `Icon` | string | Optional icon asset id (Variable only). |
| `IconColor` | Color3 | Icon tint (Variable only). |
| `GradientColor` | Color3 | Gradient tint (Variable only). |
| `ShowBackground` | bool | Whether to draw the toast background. |
| `Actions` | array | `{ Text, Callback }` buttons (Variable only). |

## Confirmation dialogs

A [Toggle](../components/toggle.md) with a `Confirm` table uses the same notification system to ask for confirmation before flipping. That's why the demo passes a notify function as the second argument to `section:Toggle`.
