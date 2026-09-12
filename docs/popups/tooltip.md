# Tooltip

A small label that appears on hover. The sidebar tab buttons and the minimize pill both use tooltips.

## Theme

Tooltips follow the active theme through `SetTheme`, so their background, text and stroke match whatever theme is live.

## Behaviour

- Shown with `ShowAt(anchor, text, side, offset)`.
- Hidden with `Hide()`.
- Positioned relative to the element it's attached to.
