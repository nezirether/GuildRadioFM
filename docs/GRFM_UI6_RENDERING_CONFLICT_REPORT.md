# UI.6 rendering ownership and legacy conflict report

UI.6 is developed on ui/readability-ui6. The playback, Live and Wire engine files are protected against frozen commit 53842d97fc0cbeb3e2cfff56467508f2e05383a0. Existing artwork and the supplied Trogdor logo remain in use.

## Ownership matrix

| Surface or control | Owner in UI.6 | Fallback | Demonstrated conflict and repair |
| --- | --- | --- | --- |
| Masthead | SkinRenderer header descriptor in its own viewport | Skin-specific banner | Preserve art and branding. Body material stays below the header. |
| Outer frame | Trim and its one descriptor binding | Shared Kit corner/edge pieces | Descriptor hides the grouped fallback when present. Trogdor frame stays isolated to Trogdor. |
| Major queue/footer panels | Explicit panel binding | Plain fill | Retain deliberate framing at major boundaries. |
| General Fill surfaces | Plain texture only | None needed | Removed automatic panel binding from Fill. Settings rows and search areas no longer acquire ornate panel art. |
| Text buttons | Plain fill, one subtle outline, live label | Same control | Removed shared bevel texture and descriptor from every text button. |
| Icon buttons | Icon binding and plain interaction state | Legacy icon atlas | Removed default transport-art binding from small icons. Theme emblems remain separate from playback glyphs. |
| Main Play | High-contrast glyph, simple fill and outline | Same control | Live inspection showed the decorative frame obscuring Play. Removed it. |
| Settings rows | Single plain fill and readable text | Same control | Replaced ornate two-column layout with grouped scroll content. |
| Settings toggles | Large hit area, knob and On/Off state | Same control | Fixed 76 by 32 controls replace tiny unlabeled switches. |
| Lists | Plain rows, selection marker and measured visible-row count | Same control | Increased row height and capped visible rows by actual viewport height. |
| Main progress | One background, dynamic fill, optional decorative track/fill | Plain textures | Geometry remains owned by the progress update. New artwork hides the corresponding fill fallback. |
| Mini-player | Dark backing, miniBorder fallback and plain controls | Shared slim trim | It never binds the main outer or transport roles. Title, status and time have separate bounds. |
| Content text | UI.lua font floor and role-specific sizes | Installed WoW fonts | Removed sub-13 overrides, raised primary track labels, and enforced light body/secondary colors on dark panels. |
| Skin switching | ApplySkin then Renderer Refresh | Per-role fallback | Tests check stale part hiding and per-skin ownership. Real-client switching captures are included separately. |

## Scope limits

The twelve non-Trogdor production emblems remain missing from the earlier art work. UI.6 retains their existing headers and adds no substitute emblems. This repair establishes no completion claim for that art requirement.

The owner-reported 33 working / 17 untested / 0 broken RC2 audit remains separate from UI.6 rendering checks. Multiplayer recovery scenarios were not reclassified based on these UI checks.
