# UI.6 test results and client evidence

## Automated checks

Executed with Python, lupa's Lua 5.1 runtime and Pillow.

- Four Lua suites passed. Fifteen TOC modules and four test files compile under Lua 5.1. Interface remains 16001.
- UI harness traverses all six tabs for all thirteen skins, main and mini players, long titles and scale changes.
- Settings assertions verify ten rows, 70-unit height, 18-unit labels, 14-unit descriptions and 76 by 32 toggles. Scroll offset is tested at both bounds.
- Renderer tests verify skin registrations, icon UV regions, state changes, aspect preservation, missing assets and saved preferences.
- Existing playback, migration, packs, lyrics, room isolation, ordering, requests, host transfer and audio-ownership simulations pass.
- Five Python pipeline tests pass, including original-logo pixel/alpha equality and every registered Signature surface path/dimension.

## Actual WoW Forever observations

Observed on 2026-11-18 in the owner's running Forever client. Capture size is 790 by 623 including the window title bar. The installed UI was backed up before testing. UI files were copied in and reloaded. Playback/network source bytes were verified against the frozen RC2 baseline.

- Captured the old overcrowded Trogdor Settings page before reload.
- Inspected all six Trogdor tabs in-game. Live tour found and corrected an obscured main Play glyph and small track names before final packaging.
- Switched all thirteen skins through the real picker and captured each selected state. Headers, accents, preview tooltips and labels changed without Trogdor framing remaining on the other skins.
- Clicked main Play and Stop. The glyph, Now Playing/Stopped text, elapsed time and main/footer progress responded. Playback was returned to stopped.
- Verified mini-player-to-main navigation by right-click.
- Scrolled Settings with the mouse wheel and visible scroll buttons through Playback, Audio, Live Radio, Interface and Notifications.
- Reloaded the final installed UI source and captured the mini-player and Settings page again.
- No Lua error dialog appeared during these checks. Audio quality, FPS benchmarking, multiplayer edge cases, every preference callback, and exhaustive small-scale/long-name combinations were not reverified.
- Trogdor selection was restored. The client was left on Settings with playback stopped.

The UI tests and captures establish this tested configuration. They do not prove that every supported resolution or input combination is free of clipping.

## Screenshot files

Delivered separately in outputs and in UI6-client-screenshots.zip.

- UI6-before-settings.png
- UI6-after-settings.png
- UI6-after-settings-audio.png
- UI6-after-settings-notifications.png
- UI6-after-now.png
- UI6-after-library.png
- UI6-after-playlists.png
- UI6-after-live.png
- UI6-after-mini.png
- UI6-live-play-feedback.png
- UI6-skin-trogdor.png
- UI6-skin-alliance.png
- UI6-skin-horde.png
- UI6-skin-undercity.png
- UI6-skin-org.png
- UI6-skin-stormwind.png
- UI6-skin-thunderbluff.png
- UI6-skin-darnassus.png
- UI6-skin-ironforge.png
- UI6-skin-bloodmoon.png
- UI6-skin-sleek.png
- UI6-skin-classic.png
- UI6-skin-retail.png

## Remaining art and release scope

The twelve non-Trogdor standalone emblems were already missing before UI.6. They remain pending original artwork. Their existing banner identity is preserved. This repair does not declare the full thirteen-skin artwork project complete.

The owner's critical RC2 recovery and multiplayer checklist remains pending the dedicated two-client tests. UI.6 is a test candidate. The original frozen RC2 ZIP is retained. The owner explicitly authorized GitHub sync and merge for this repair.
