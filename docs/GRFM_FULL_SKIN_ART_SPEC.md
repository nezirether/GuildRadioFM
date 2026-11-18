# GuildRadioFM full skin artwork specification

This production contract extends the audit at baseline `53842d97fc0cbeb3e2cfff56467508f2e05383a0`. It applies to all thirteen skins. The supplied Signature interface guides Trogdor. The supplied thirteen-skin sheet guides the remaining materials, silhouettes and coverage.

The runtime supports production asset registration independently from the player. A skin becomes visually complete after its production artwork is integrated, reviewed at display size and checked in Forever. The existing artwork remains the active fallback while new production files are absent.

## Delivery structure

Author PNG source under `assets/<key>/`. Build outputs go to `Media/Skins/<key>/` as uncompressed 32-bit RGBA TGA. Use lowercase skin keys from the registry. Keep names and UV metadata identical between source, manifest and generated registration.

| File stem | PNG/TGA dimensions | Alpha | Purpose and scaling |
| --- | --- | --- | --- |
| header | 1024 × 256 | RGBA | Masthead. Preserve aspect or deliberately crop using approved UV metadata. Keep dynamic title space clear. |
| background | 256 × 256 | RGBA | Seamless, low-contrast material tile. Repeat rather than stretch. |
| crest | 256 × 256 | RGBA | Main skin emblem or parchment illustration. Preserve aspect. |
| decor | 256 × 64 | RGBA | Secondary flourish. Preserve aspect, with transparent breathing room. |
| surfaces | 1024 × 1024 | RGBA | Normal-state frame/control atlas, mapped below. |
| surfaces_hover | 1024 × 1024 | RGBA | Hover surfaces at the same coordinates. |
| surfaces_pressed | 1024 × 1024 | RGBA | Pressed surfaces at the same coordinates. |
| surfaces_selected | 1024 × 1024 | RGBA | Selected surfaces at the same coordinates. |
| surfaces_disabled | 1024 × 1024 | RGBA | Disabled surfaces at the same coordinates. |
| mini | 1024 × 128 | RGBA | Dedicated mini-player composition. Dynamic title and controls need clear safe zones. |
| thumbnail | 256 × 128 | RGBA | Approved skin-picker composition. This is a source deliverable for thumbnail integration. |
| icons | 512 × 256 | RGBA | Thirty-two semantic icon cells. See the icon specification. |
| icons_hover | 512 × 256 | RGBA | Hover icon states. |
| icons_pressed | 512 × 256 | RGBA | Pressed icon states. |
| icons_selected | 512 × 256 | RGBA | Selected icon states. |
| icons_disabled | 512 × 256 | RGBA | Disabled icon states. |

Dimensions are source canvas dimensions. Decorative elements must have a recorded painted rectangle and alpha margin. Dynamic song titles, counts, room names, playlist names, tooltips, playback position and volume values remain runtime text.

## Surface atlas layout

Pixels are measured from the upper-left origin. Leave at least two transparent pixels inside each region boundary to reduce sampling bleed. Fixed insets are source pixels and include that gutter. Corners and control rims must occupy the fixed regions.

| Role | Pixel rectangle x, y, width, height | Suggested mode | Fixed source insets L, R, T, B |
| --- | --- | --- | --- |
| outer | 0, 0, 256, 256 | nine | 48, 48, 48, 48 |
| panel | 256, 0, 256, 256 | nine | 24, 24, 24, 24 |
| button | 512, 0, 256, 64 | three | 24, 24, 0, 0 |
| tab | 512, 64, 256, 64 | three | 32, 32, 0, 0 |
| badge | 512, 128, 256, 64 | three | 24, 24, 0, 0 |
| queueRow | 512, 192, 256, 64 | three | 16, 16, 0, 0 |
| transport | 768, 0, 128, 128 | contain | 0, 0, 0, 0 |
| progressTrack | 0, 256, 512, 32 | three | 16, 16, 0, 0 |
| progressFill | 0, 288, 512, 32 | tile | 0, 0, 0, 0 |
| volumeTrack | 0, 320, 256, 32 | three | 16, 16, 0, 0 |
| volumeThumb | 256, 320, 32, 32 | contain | 0, 0, 0, 0 |
| volumeFill | 0, 352, 256, 32 | tile | 0, 0, 0, 0 |
| mini border | 0, 384, 256, 256 | nine | 24, 24, 24, 24 |

The mini background uses the separate `mini` descriptor. Its border can reuse the panel role or a documented nine-part atlas region. Additional regions may occupy unused space if all bounds and states are specified in the manifest.

For a rectangle x, y, w, h in a W by H atlas, UV is `{x/W, (x+w)/W, y/H, (y+h)/H}`. Insets are measured inside that rectangle. UVs must stay in the 0–1 interval. Fixed left and right insets together must fit within the region width. The same rule applies vertically.

## Runtime contract

`GuildRadioFM.RegisterSkinAssets(key, {surfaces={...}, icons={...}})` registers production descriptors after the base skin registry loads. Surface roles are `background`, `header`, `crest`, `decor`, `outer`, `panel`, `tab`, `button`, `transport`, `progressTrack`, `progressFill`, `volumeTrack`, `volumeFill`, `volumeThumb`, `badge`, `queueRow`, and `mini`.

A surface descriptor has these fields.

| Field | Contract |
| --- | --- |
| path | Addon-relative texture path rooted at `Interface\\AddOns\\GuildRadioFM\\Media\\Skins\\<key>\\`. |
| width, height | Full source texture dimensions. |
| uv | Normalized `{left,right,top,bottom}` rectangle. Omission means the full image. |
| insets | `{left,right,top,bottom}` fixed slices in source pixels. |
| mode | `nine`, `three`, `tile`, `stretch`, or `contain`. |
| safe | `{left,right,top,bottom}` content exclusion margins for artwork review and layout. |
| states | Optional `hover`, `pressed`, `selected`, and `disabled` descriptor overrides. |

`nine` preserves corners, extends edge strips and fills the center. `three` preserves horizontal endcaps. `tile` repeats a material or fill with cropped partial tiles. `contain` preserves aspect inside the target rectangle. `stretch` is reserved for art whose design allows distortion, such as a uniform wash.

Safe margins describe intended content bounds. Verify that each UI role honors its bounds before approving artwork. They do not change a button's click target.

State artwork must keep painted geometry and glyph alignment stable. Hover may brighten edge light, pressed may deepen material recesses, selected needs a persistent shape or outline, and disabled needs readable low-emphasis treatment. Labels and hitboxes stay in the same positions.

## Theme briefs

| Key | Display name | Required visual identity |
| --- | --- | --- |
| trogdor | Trogdor | Scorched timber, torn parchment, dark iron, bronze, crimson cloth and molten orange. Use the supplied burninating dragon illustration language and a parchment crest. |
| alliance | Alliance | Royal-blue enamel, polished gold, lion heraldry and ceremonial symmetrical metalwork. |
| horde | Horde | Torn crimson banners, dark forged iron, angular weapon-like rims and rugged fasteners. |
| undercity | Undercity | Purple gothic stone, pale bone, plague-green alchemical glow and vaulted silhouettes. |
| org | Orgrimmar | Spiked timber, tusks, leather binding, red sandstone and tribal metal. Keep tusks clear of text. |
| stormwind | Stormwind | White stone, blue enamel and elegant gold architectural borders. |
| thunderbluff | Thunder Bluff | Carved wood, leather, turquoise, feathers and naturally asymmetric ornament. |
| darnassus | Darnassus | Moonlit violet, silver filigree, vines, ancient wood and restrained ethereal light. |
| ironforge | Ironforge | Dwarven bronze, carved stone, geometric runes, forge light and substantial square construction. |
| bloodmoon | Blood Moon | Obsidian, blood-red highlights, gothic silhouettes and sharp dramatic rims. |
| sleek | Sleek | Minimal dark glass, precise geometry, restrained cyan/violet light and clear geometric icons. |
| classic | Classic | Aged parchment, bronze borders and traditional fantasy control shapes. |
| retail | Retail | Refined layered fantasy surfaces, luminous blue, polished gold and clean spacing. |

Each theme needs independent shape and material decisions in frames, tabs, controls and icons. Review normal-state screens in grayscale to check that their geometry remains distinguishable.

## Source and export review

Use straight alpha with clean colored edge pixels. Avoid embedded interface text. Preserve layered source documents alongside final PNGs when available. Match file names exactly on case-sensitive builds. Record an asset's authorship and license with the production handoff.

`tools/build_skin_assets.py` accepts a manifest JSON plus `--source` and `--output`. It validates declared paths, dimensions and atlas geometry, converts PNG artwork to TGA, and emits `SkinAssets.lua` registration. The actual tool help and shipped manifest schema govern invocation. A registration can be partial while missing roles retain fallbacks.

Before accepting a theme, review its header, crest, icon atlas, state atlases, mini composition and a full UI capture at actual display scale. A successful image decode is an asset check. Client screenshots establish the final layout and filtering result.

## Build manifest

The JSON root maps supported skin keys to asset sets. Each surface has a PNG basename in `file`, optional `mode`, normalized `uv`, source-pixel `insets`, source-pixel `safe`, and optional complete descriptor overrides in `states`. The compiler derives runtime `path`, `width` and `height` from the PNG. Each icon state maps to a PNG basename.

```json
{
  "trogdor": {
    "surfaces": {
      "panel": {
        "file": "surfaces.png",
        "mode": "nine",
        "uv": [0.25, 0.5, 0, 0.25],
        "insets": [24, 24, 24, 24],
        "safe": [28, 28, 28, 28],
        "states": {
          "hover": {
            "file": "surfaces_hover.png",
            "mode": "nine",
            "uv": [0.25, 0.5, 0, 0.25],
            "insets": [24, 24, 24, 24]
          }
        }
      }
    },
    "icons": {
      "file": "icons.png",
      "states": {
        "hover": "icons_hover.png",
        "pressed": "icons_pressed.png",
        "selected": "icons_selected.png",
        "disabled": "icons_disabled.png"
      }
    }
  }
}
```

Run `python tools/build_skin_assets.py manifest.json --source assets --output work/art-build`. The staging directory must be empty. The tool validates all inputs before writing, preserves alpha, and emits an addon overlay containing TGAs and SkinAssets.lua. Merge complete reviewed registrations in the manifest when rebuilding, since the generated registry contains the supplied entries. Keep synthetic test fixtures outside production artwork.

The current framework consumes safe-area metadata as an authoring contract. Widget text positions remain defined by UI.lua and must be checked against the approved safe rectangles during integration. Thumbnail artwork and the Signature reference's alternate sidebar layout remain follow-up integration work.
