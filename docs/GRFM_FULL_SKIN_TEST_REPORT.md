# Full skin framework UI test report

Candidate label 2.8.1-rc.2-ui.1. Stable engine baseline 53842d97fc0cbeb3e2cfff56467508f2e05383a0. Development branch ui/full-skin-framework continues the audit branch.

## Implemented

- Descriptor renderer with normalized UV regions, fixed corners, three-piece strips, nine-part frames, tiled fills and aspect-preserving images.
- Per-skin surface and icon registrations, state descriptors, runtime texture-load fallback and legacy assets.
- Thirty-two semantic icons in an eight-column, four-row atlas, with independent state atlases. Original icon art remains active until production files are integrated.
- UI bindings for main header/background, borders, panels, tabs, controls, volume, progress, badges, list rows, crest, flourish and mini-player.
- PNG-to-TGA compiler with explicit manifest, geometry validation and generated registration.
- Artwork and icon specifications and a complete thirteen-skin production checklist.

## Executed automated checks

With Python dependencies lupa and Pillow available, run from the addon checkout.

```text
python tests/run_tests.py
python tests/test_skin_pipeline.py
```

Four Lua 5.1 suites passed. Fourteen TOC modules and four suites compiled. Interface remains 16001. The inherited multiplayer and local audio regression suite passed.

The new renderer suite checks all thirteen keys and all thirty-two icon UV regions, normal/hover/pressed/selected/disabled descriptors, fixed corner sizes, resizing, contain/three/tile/stretch geometry, failed texture loads, saved preferences, preview and unknown-key fallback.

The new UI harness constructs the actual main window and mini-player and traverses six screens for all thirteen skins with synthetic descriptor registrations. It exercises 50, 80, 100 and 140 percent scales and a long track title without Lua errors in the mocked API.

Two Python pipeline tests passed, covering PNG conversion, alpha preservation, Lua registration execution, invalid paths, dimensions, insets and UVs, and refusing to overwrite a populated staging directory. Synthetic fixture images exist only in temporary test directories.

## Pending production and client checks

All thirteen new production art sets are missing. Current skins retain legacy fallback art. This candidate establishes the renderer and integration points. Stages B, C and D remain pending the approved assets listed in the production checklist.

Font measurement, real clipping, layer ordering, filtering, event behavior and actual visual polish require Forever. The UI mock exercises calls and state changes. It cannot establish pixel-level appearance. Capture matching before/after client screenshots for every screen, mini-player, scale and state when the new artwork is integrated. The tall Signature header and vertical sidebar require an additional layout pass after the material assets are approved.

## Installation

Back up the installed addon and SavedVariables. Install the separate GuildRadioFM folder from the UI test ZIP. The TOC carries the UI candidate suffix. The player's runtime version remains the stable engine version. Use the supplied specs to produce artwork and compile it into a staging overlay before integration.
