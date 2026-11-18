# UI.5 repair report

The owner supplied in-game screenshots showing mixed Trogdor/Alliance chrome and an unreadable mini-player in UI.4. These are confirmed visual regressions. The earlier headless checks did not establish visual correctness.

## Repairs

- Signature outer frame, cloth navigation, framed controls and wood are now limited to Trogdor. Other skins retain their own existing fallback geometry and materials.
- Body material starts beneath the masthead and stops above the footer. Legacy material tiles are hidden when the active skin supplies a custom background.
- Skin-card names use 16-point text on a separate dark label strip; state tags use 13-point text.
- The mini-player uses its own simple border role. It no longer draws the full-window Signature frame or artwork behind its labels.
- Mini-player dimensions are 520 by 76 logical units, with 18-point title, 12-point status, 36-unit play button, 34-unit previous/next buttons and a four-unit progress line.
- Dragging, expanding, closing, playback callbacks, song identity and SavedVariables retain their existing entry points.

## Checks

Four Lua 5.1 suites and five pipeline tests passed. New checks prohibit Signature outer/tab/transport registration on the other twelve skins, prohibit the main outer-border role on the mini-player, and check its font and control dimensions.

Frozen RC2 engine and audio bytes are compared during packaging. The stable RC2 ZIP is retained.

## Remaining verification

No new client screenshot was captured for UI.5. The screenshots supplied by the owner are the failure evidence. Real-client layer ordering, font readability, hover behavior, skin changes and main/mini presentation still need validation before visual acceptance. Full independent artwork for the twelve other skins remains unfinished.
