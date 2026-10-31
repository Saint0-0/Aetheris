# Tooltip

Aetheris creates one tooltip per window and shows it when you hover a sidebar tab, displaying that tab's name. It's most useful in compact mode, where the sidebar collapses to icons only.

You don't create tooltips yourself — there's nothing to call. They exist so the collapsed sidebar stays usable.

## Theming

The tooltip is a popup, so it follows the popup theme keys:

| Key | What it drives |
| --- | --- |
| `PopupBackgroundColor` / `PopupBackgroundTransparency` | The card. |
| `PopupTextColor` / `PopupTextTransparency` | The label. |
| `PopupShadowColor` | The drop shadow. |

It also follows live theme switches like everything else.
