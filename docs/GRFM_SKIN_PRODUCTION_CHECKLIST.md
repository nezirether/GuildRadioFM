# GuildRadioFM skin production checklist

This checklist tracks the full thirteen-skin artwork target. Existing banners, tiles, crests and flourishes from the RC2 build are fallback artwork. The new production set requires independent review of the full frame, control and icon families.

## Current production status

All thirteen production sets are awaiting artwork. The compatible renderer and generated registrations can consume complete or partial sets. A working fallback proves that the player can render while art is missing. It does not complete an artwork row.

| Stage | Skin key | Surface set | Icon set | Production art review | Forever visual review |
| --- | --- | --- | --- | --- | --- |
| B | trogdor | Missing | Missing | Pending | Pending |
| B | horde | Missing | Missing | Pending | Pending |
| B | alliance | Missing | Missing | Pending | Pending |
| C | undercity | Missing | Missing | Pending | Pending |
| C | org | Missing | Missing | Pending | Pending |
| C | stormwind | Missing | Missing | Pending | Pending |
| C | thunderbluff | Missing | Missing | Pending | Pending |
| C | darnassus | Missing | Missing | Pending | Pending |
| C | ironforge | Missing | Missing | Pending | Pending |
| D | bloodmoon | Missing | Missing | Pending | Pending |
| D | sleek | Missing | Missing | Pending | Pending |
| D | classic | Missing | Missing | Pending | Pending |
| D | retail | Missing | Missing | Pending | Pending |

## Files required for every skin

For each key in the table above, deliver these source files under `assets/<key>/`. Their TGA counterparts belong under `Media/Skins/<key>/` after conversion. Dimensions, alpha, atlas regions and safe zones are defined in GRFM_FULL_SKIN_ART_SPEC.md and GRFM_ICON_SYSTEM_SPEC.md.

- [ ] header.png
- [ ] background.png
- [ ] crest.png
- [ ] decor.png
- [ ] surfaces.png
- [ ] surfaces_hover.png
- [ ] surfaces_pressed.png
- [ ] surfaces_selected.png
- [ ] surfaces_disabled.png
- [ ] mini.png
- [ ] thumbnail.png
- [ ] icons.png
- [ ] icons_hover.png
- [ ] icons_pressed.png
- [ ] icons_selected.png
- [ ] icons_disabled.png

This is 16 source files per skin and 208 source files across thirteen complete sets. Additional independent artwork is welcome when represented by explicit descriptor paths and geometry.

## Role coverage required for every skin

- [ ] Main background and masthead suit the theme and leave readable title space.
- [ ] Crest has its own clear silhouette at full-player and mini-player size.
- [ ] Outer frame has fixed corners, consistent lighting and repeatable edges.
- [ ] Panels, queue rows and room presentation use matching materials.
- [ ] Navigation, buttons and transport have aligned normal, hover, pressed, selected and disabled states.
- [ ] Progress track and fill retain endcap shape and align with the playback clock.
- [ ] Volume track, fill and thumb are readable and functional at minimum supported scale.
- [ ] Live badge has dynamic text space and a clear status treatment.
- [ ] Mini-player composition has protected title and transport regions.
- [ ] Thirty-two icon cells are present and align across the five state atlases.
- [ ] Disabled and selected states can be understood beyond color alone.
- [ ] Theme identity comes from material and geometry as well as palette.

## Asset acceptance

- [ ] Source PNGs decode and match the declared dimensions.
- [ ] Exported TGA files decode and use the agreed uncompressed RGBA format.
- [ ] Every registered path points to a packaged file.
- [ ] Every UV and fixed inset fits its source rectangle.
- [ ] Transparent gutters prevent atlas bleeding.
- [ ] Tiled backgrounds and fills have no visible seams.
- [ ] Corner and endcap ornaments preserve their intended proportions.
- [ ] Texture safe zones match the target UI layout.
- [ ] Authorship and usage permission are recorded with the artwork delivery.

## Automated acceptance

- [ ] Thirteen skin registrations load in Lua 5.1.
- [ ] TOC interface stays 16001 and skin modules load before UI construction.
- [ ] All production paths, dimensions, UVs and icon cells validate.
- [ ] Missing-role and missing-state fallbacks resolve consistently.
- [ ] Switching skins updates already created full-player, mini-player and popup surfaces.
- [ ] Preview cancellation restores the saved skin.
- [ ] Unknown saved skin keys remain preserved.
- [ ] Hover, pressed, selected and disabled resolution obey the state priority.
- [ ] Existing tooltip and multiplayer regression suites still pass.
- [ ] Protected audio and network source files match baseline 53842d97fc0cbeb3e2cfff56467508f2e05383a0.

## Forever acceptance

These checks require the real client and remain pending until captures and results are recorded.

- [ ] Open Now Playing, Library, Playlists, Live, Settings, Skins and every existing popup.
- [ ] Inspect full player and mini-player at 50, 80, 100 and 140 percent scale.
- [ ] Exercise all transport, volume, queue, request, voting and chat controls.
- [ ] Check long song titles, room names, playlist names and localized labels.
- [ ] Check hover and pressed changes without pointer jitter or shape shifts.
- [ ] Switch through all thirteen skins with both players already visible.
- [ ] Save a skin preference, reload and confirm the same selection.
- [ ] Inspect texture orientation, alpha edges, sampling seams and missing-art indicators.
- [ ] Capture baseline and candidate screens with matching song, room, scale and resolution.
- [ ] Record the tested source commit, client build and ZIP hash with results.

A completed theme needs its production files integrated and visually reviewed. The current delivery should identify the renderer and test progress separately from the outstanding artwork and client review.

## Supplied original update

The owner supplied the authoritative 256 by 256 transparent Trogdor logo. It is now integrated unchanged through the dedicated emblem renderer. Trogdor emblem artwork is supplied, with actual client verification pending. Other Trogdor decorative surfaces and the twelve other emblem sets remain pending. See GRFM_TROGDOR_ORIGINAL_INTEGRATION.md.
