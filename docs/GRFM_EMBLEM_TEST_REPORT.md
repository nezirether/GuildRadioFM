# Emblem UI.2 verification

The UI branch continues stable engine commit 53842d97fc0cbeb3e2cfff56467508f2e05383a0. TOC candidate label is 2.8.1-rc.2-ui.2.

## Changed

- Removed bindings to the retired circular crests in the main player, skin picker, header, mini-player and popups.
- Removed the Now Playing crest's square tile, shared trim and pulsing halo.
- Added independent per-skin emblem dimensions and anchors for five contexts, alpha-bounds fitting and missing-art handling.
- Skin cards use their own tile and full banner, with emblem space confined above the name strip. Removed repeated color chips and decorative card numbers.
- Reduced the main material darkening and reclaimed the left column when no production emblem is installed.
- Added a thirteen-skin design manifest, build manifest and artwork handoff.

## Automated results

Four Lua 5.1 suites passed. Fourteen TOC modules and four suites compiled. The renderer suite now checks all thirteen emblem viewports, non-square painted aspect, alpha bounds, missing-file handling, invalid low-resolution inputs and picker label-safe placement.

The full UI harness exercises all six screens, thirteen skins, main and mini players, scales and long titles with synthetic production descriptors. These fixtures are call-level tests and are not shipped artwork.

Three Python pipeline tests passed, including transparent emblem conversion and alpha-bounds registration. Opaque backgrounds are rejected, as are wrong dimensions and empty alpha content.

## Pending acceptance

The thirteen original production emblems have not been supplied. This candidate hides retired emblems and uses existing banners/materials while awaiting artwork. It does not establish visual completion of any new emblem.

Actual Forever rendering, clipping, filtering, UI interaction, visual comparison and before/after screenshots remain pending. The required Trogdor, Horde and Alliance quality comparison can be accepted only after the production art is integrated and captured in the client.
