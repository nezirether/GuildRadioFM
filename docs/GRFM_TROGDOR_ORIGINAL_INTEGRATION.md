# Supplied Trogdor original integration

The owner supplied codex-clipboard-e6f931e3-619f-446c-986a-2f016b2e58ed.png as the original Trogdor emblem. It is authoritative for this skin, including its lettering and circular outer design. The generic shared medallion treatment remains retired. The supplied composition itself is preserved intact.

- Original dimensions 256 by 256, RGBA.
- Original SHA-256 c411bc01fd4f51cdc2e10ea8bc71516d14a8f317a3875602a0ccb739f38038be.
- Source copied unchanged to assets/trogdor/emblem.png.
- Exported to Media/Skins/trogdor/emblem.tga without resizing, cropping, recoloring or alpha modification.
- The renderer supports native 256/512 emblem dimensions and uses actual source dimensions for UVs.
- The production compiler requires an explicit native flag for a supplied 256-pixel original. Newly commissioned artwork still defaults to 512 by 512.
- Existing aspect-aware bindings display the asset in Now Playing, header, skin picker, mini-player and popups. No faction emblem is used as a playback control.

The main painted viewport is bounded by 164 by 144 logical units, so the complete square emblem displays at 144 by 144. At the existing maximum UI scale of 1.4 this remains below the original 256-pixel source size. Small header/mini placements preserve the whole logo, although fine lettering is naturally less legible at those sizes.

The other twelve production emblems remain pending their supplied or approved originals. They are not declared corrected by this Trogdor-only asset integration.

Four Lua suites and four Python pipeline tests cover descriptor geometry, actual source registration, original logo pixel/alpha equality and the inherited UI/playback regression cases. Actual in-game rendering screenshots for this asset have not been captured in this turn. The prior computer-use session was stopped by the owner.
