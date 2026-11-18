# Signature layout UI.4 test build

This candidate implements the structural move toward the supplied Image 3 on ui/full-skin-framework. Trogdor is the first visual target. Frozen engine baseline is 53842d97fc0cbeb3e2cfff56467508f2e05383a0.

## Working layout changes

- Large artwork masthead and six vertical navigation controls.
- Central player with the original supplied Trogdor logo, dynamic title/status/lyrics, larger controls and a framed progress bar.
- Right-side local queue with seven visible rows, scrolling, selection, move-up/down, removal and Play queue.
- Working bottom strip with title, playback status, elapsed/duration, progress and previous/play-stop/next.
- Full-size Library, Playlists, Live, Skins and Settings content areas.
- Initial and manually adjusted window scale constrained by the game viewport. Existing SavedVariables names remain in use.

The supplied Signature concept is used as a texture atlas for the masthead, wood and selected border regions. The source pixels are retained at native resolution on a padded power-of-two TGA canvas. Only border regions are drawn from frames that contain text or example controls, so their baked center content is omitted. Song titles, queues, controls and progress are rendered by Lua frames.

All thirteen skins use the shared structural layout. The twelve other skins retain their own existing header art and palette. Their complete material, border, button, icon and typography upgrades remain pending. The new non-Trogdor banner sheet contains Keepers of Trogdor lettering, so it is not used as their masthead.

## Automated verification

Run these from the addon checkout with lupa and Pillow installed.

```text
python tests/run_tests.py
python tests/test_skin_pipeline.py
```

Four Lua 5.1 suites passed, compiling fifteen TOC modules and four suites. The UI test exercises all thirteen skin registrations and six screens, main and mini players, scales and long titles. Signature-specific checks cover intended layout anchors, viewport-fit scaling, queue scrolling, reorder/removal, player-screen visibility and footer play/stop through the existing callbacks.

Five Python pipeline tests passed, including registered texture path and dimension checks for all thirteen skins. The original Trogdor emblem's pixels and alpha match the source. Candidate package checks compare protected engine files and original music against the frozen RC2 package.

## Visual acceptance pending

This is a functional layout test candidate. Premium visual completion has not been established. In-game font measurement, border seams, atlas filtering, pointer behavior, final control spacing and long-text clipping require inspection in Forever.

The two attempted client inspections were stopped by the owner with Escape. This continuation did not control the game or change the installed addon. No after screenshot is claimed. The existing screenshot supplied by the owner remains the before reference.

The current borders use resizable samples from the supplied composition. Fine frame/cloth details may need clean production assets after a real-client review. Complete independent art direction for the other twelve skins remains future work after Trogdor acceptance.
