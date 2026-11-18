# GuildRadioFM icon system specification

Each of the thirteen skins can provide an independently drawn icon family. Shared semantic names keep the player handlers stable while texture paths, silhouettes and materials vary by theme. Existing RC2 icon art supplies fallback coverage until a production family is integrated.

## Atlas contract

Each source atlas is 512 × 256 pixels, RGBA, with eight columns and four rows. Each cell is 64 × 64 pixels. Indexing is zero-based and row-major. All five state atlases use exactly the same cell order and alignment.

| Filename | State |
| --- | --- |
| icons.png → icons.tga | Normal |
| icons_hover.png → icons_hover.tga | Hover |
| icons_pressed.png → icons_pressed.tga | Pressed |
| icons_selected.png → icons_selected.tga | Selected |
| icons_disabled.png → icons_disabled.tga | Disabled |

For cell index i, column is `i % 8` and row is `floor(i / 8)`. UV is `{column/8, (column+1)/8, row/4, (row+1)/4}`. A two-pixel transparent cell margin prevents neighboring artwork from bleeding through texture filtering. Keep the main glyph within the central 48 × 48 pixels. A theme may use the surrounding area for a rim or short highlight.

## Semantic cell map

| Index | Name | Recognizable form |
| --- | --- | --- |
| 0 | play | Right-pointing triangle |
| 1 | pause | Two vertical bars |
| 2 | stop | Square |
| 3 | prev | Left triangle with boundary bar |
| 4 | next | Right triangle with boundary bar |
| 5 | shuffle | Crossing arrows |
| 6 | repeat | Circling or paired return arrows |
| 7 | volume | Speaker with sound waves |
| 8 | mute | Speaker with cross or clear silence mark |
| 9 | library | Music collection or book with music cue |
| 10 | playlists | Grouped list with music cue |
| 11 | queue | Ordered list or stacked tracks |
| 12 | live | Broadcast or radio signal |
| 13 | settings | Gear or unmistakable control symbol |
| 14 | search | Magnifying glass |
| 15 | heart | Filled favorite symbol |
| 16 | heartline | Outline favorite symbol |
| 17 | chat | Speech bubble |
| 18 | request | Song request or hand-and-note cue |
| 19 | vote | Vote/check or raised approval cue |
| 20 | close | Cross |
| 21 | back | Left arrow distinct from previous track |
| 22 | minimize | Horizontal bar |
| 23 | expand | Outward corner arrows |
| 24 | plus | Plus |
| 25 | minus | Minus |
| 26 | up | Up arrow |
| 27 | down | Down arrow |
| 28 | music | Music note |
| 29 | microphone | Microphone |
| 30 | room | Room doorway, gathering or station cue |
| 31 | check | Check mark |

Pause artwork supports the icon vocabulary. Its presence adds no pause or seek capability to the audio engine. Use a semantic icon only where the existing control performs the corresponding action.

## Runtime registration

A skin can register this icon descriptor through `GuildRadioFM.RegisterSkinAssets`.

```lua
icons = {
    path = "Interface\\AddOns\\GuildRadioFM\\Media\\Skins\\trogdor\\icons.tga",
    width = 512,
    height = 256,
    columns = 8,
    cell = 64,
    states = {
        hover = "Interface\\AddOns\\GuildRadioFM\\Media\\Skins\\trogdor\\icons_hover.tga",
        pressed = "Interface\\AddOns\\GuildRadioFM\\Media\\Skins\\trogdor\\icons_pressed.tga",
        selected = "Interface\\AddOns\\GuildRadioFM\\Media\\Skins\\trogdor\\icons_selected.tga",
        disabled = "Interface\\AddOns\\GuildRadioFM\\Media\\Skins\\trogdor\\icons_disabled.tga",
    },
}
```

Replace the key and directory for each theme. Generated registration should include only validated files. Missing production families use existing icon fallbacks. Missing state art resolves through the renderer's base-state fallback, preserving recognizable controls while the artwork set is incomplete.

## Design and alignment

Keep primary transport silhouettes visible at 14–22 UI units and secondary icons visible at the smaller existing control sizes. Review source art at those sizes as part of production. Thick, simple forms survive downsampling better than fine etched patterns. Material ornament belongs around the glyph without obscuring its meaning.

Use a consistent optical center per cell across every state. Previous, next, play and stop should feel like members of the same control family. Keep favorite outline and filled favorite aligned. Maintain speaker shape when toggling mute. Distinguish a navigation back arrow from a previous-track glyph.

The common cell format does not constrain every theme to the same silhouette. Trogdor can use scorched bronze and molten recesses, Alliance ceremonial gold and blue enamel, Horde rugged forged iron, Undercity bone and alchemical accents, Orgrimmar tribal metal and leather, Stormwind architectural gold and white stone, Thunder Bluff carved natural materials, Darnassus silver vines, Ironforge geometric bronze, Blood Moon obsidian cuts, Sleek precise luminous geometry, Classic bronze and parchment, and Retail polished layered blue/gold.

## State treatment

- Normal gives the glyph a readable resting contrast.
- Hover adds local edge light or an unmistakable highlight.
- Pressed deepens the recess or shifts illumination while keeping the glyph centered.
- Selected adds a persistent visual signal suitable for shuffle, repeat and favorite states.
- Disabled reduces emphasis while retaining the symbol's silhouette.

State changes need their own artwork review. A palette tint over the old atlas alone does not meet the production objective.

## Acceptance

1. Verify all thirty-two regions are within the atlas and mapped to the documented semantic names.
2. Review every icon at its actual UI size on both dark and light theme surfaces.
3. Check all five states for alignment, sampling bleed and semantic clarity.
4. Exercise skin switching after full-player, mini-player and popup icons already exist.
5. Test unknown icon names and incomplete state families through the fallback path.
6. Verify long tooltips and actual control behavior in Forever.

The production icon atlases for all thirteen themes are currently missing. Their cell maps and renderer support can be tested using controlled fixtures. Final recognizability, material quality and consistency await the actual artwork and client review.
