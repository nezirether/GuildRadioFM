# GuildRadioFM skin system audit

Phase 1 completed against source commit 53842d97fc0cbeb3e2cfff56467508f2e05383a0 and GuildRadioFM-2.8.1-rc.2-TEST.zip. Audit branch is ui/trogdor-signature-audit. Reference images are the supplied 1672 by 941 Signature interface and 1672 by 941 thirteen-skin concept sheet.

## Findings

The current system supports palette switching and four main art roles per skin. It cannot represent the supplied Signature design through asset substitution alone. The Signature reference has a large parchment masthead, a vertical cloth navigation rail, a wood-backed player, a dedicated right-hand queue, and a wide integrated transport strip. The current player is a fixed 680 by 480 layout with horizontal tabs, a separate Live screen, a compact queue summary and a separate 300 by 52 mini-player.

The thirteen-skin sheet and the Signature image have different Trogdor treatments. Current assets follow the sheet's lava-rock tile and red dragon. Phase 2 should use the Signature image as the Trogdor benchmark, with the sheet guiding future skin coverage. This is an audit interpretation of the two supplied references.

## Current architecture

- GuildRadioFM.toc loads Skins.lua before UI.lua, with interface 16001.
- Skins.lua declares thirteen entries, palettes, fonts, metal/tab/badge tints, and banner/tile/crest/decor paths. Kit.tga and the icon atlas are global.
- UI.lua stores references to textures, text and widgets in SKINNED. ApplySkin changes palette values in place, repaints registered widgets and applies the active art.
- ApplySkinArt swaps the header, crest, tile and flourish, and recolors the shared frame kit and Live badge.
- PreviewSkin and EndPreview support temporary selection. GetActiveSkin preserves an unrecognized saved key and displays Classic as fallback.
- Main scaling applies a uniform frame scale. TileGrid is built at the fixed design dimensions. Frame corners stay square and edge strips extend between them, but most control faces are single stretched atlas regions.

## Custom art and generic elements

| Component | Current implementation | Signature gap |
| --- | --- | --- |
| Header | Thirteen individual 512 by 64 RGB TGA files | Trogdor asset is a shallow lava/dragon montage. The parchment masthead, hand lettering and full illustrated dragon are missing as separate assets. |
| Background | Thirteen individual 128 by 128 RGB tiles | Trogdor uses lava cracks. The reference uses scorched timber and metal structure. |
| Crest | Twelve individual 128 by 128 RGBA crests; Classic uses the existing emblem | Trogdor is a round dragon-head medallion. The reference uses a square parchment dragon illustration. |
| Flourish | Thirteen individual 128 by 64 RGBA files | Trogdor flame is reduced to 64 by 32 in Now Playing. No reference-style cloth heading plate. |
| Outer frame | Shared 256 by 256 RGBA Kit atlas, mirrored corners, extended edges | One smooth grayscale corner and straight edges receive skin tint. Irregular iron brackets, rivets and carved timber require additional artwork. |
| Navigation and buttons | Palette fills from WHITE8X8 with shared atlas faces | No skin-specific torn cloth, state artwork or dedicated control frame. |
| Transport | Shared 1024 by 64 icon atlas, shared disc region | Symbols are custom bitmaps, but every skin shares them. Ornamented bronze play/previous/next controls are absent. |
| Progress and volume | Thin color fills and slider primitives | Molten bar, bronze trough, emblem marker and volume surround are absent. |
| Live badge | Shared pill-shaped atlas region plus microphone icon | Framed crimson badge with decorative waveform and jewel is absent. |
| Queue and Live panels | Color surfaces, outlines, labels and common controls | Dedicated wood/bronze panel art and selection surfaces are absent. |
| Mini-player | Cropped header beneath a dark gradient, common trim and icons | Dedicated masthead fragment, frame and transport treatment are absent. |
| Popups and settings | Shared custom primitives and fonts | Need consistent panel/control roles in a reusable skin system. |

The principal visible surfaces use custom textures or WHITE8X8 color fills. The custom buttons are constructed with CreateFrame, rather than stock Blizzard button templates. Optional Kalimdor/Eastern Kingdoms backgrounds and installed WoW fonts are client assets. Recoloring a shared custom atlas still gives every skin the same geometry.

## Texture and geometry checks

All 55 TGA textures in Media decoded successfully. Their dimensions are powers of two. They use uncompressed true-color TGA type 2, with RGB or RGBA channels. Every art path declared by the thirteen skin entries resolves. A valid file and dimension check establishes no successful client rendering result.

| Element | Source and destination | Assessment |
| --- | --- | --- |
| Full header | 512 by 64 to 680 by 88 | 8.00 source aspect versus 7.73 destination. Slight distortion and source upscaling. The large Signature masthead has no reserved layout space. |
| Mini background | Header UV 0.42–1.00 horizontally and 0–0.64 vertically to 300 by 52 | Approximately 297 by 41 source area stretched to 300 by 52. Around 26 percent vertical enlargement relative to horizontal. It also crops the scene independently of the dragon focal point. |
| Text button face | Kit region 192 by 32 to many button sizes | Border and corner details stretch with the entire face. Use fixed corners and extending/tiled edges. |
| Tab face | Kit region 192 by 32 to text-measured widths and 28 height | Variable horizontal distortion across labels and languages. |
| Frame corners | 64 by 64 source to 30, 18 or 16 square display | Aspect retained, detail reduced. Mirroring also mirrors the lighting. |
| Frame edge strips | Horizontal and vertical Kit regions extended between corners | Already an eight-piece technique. Repeated texture detail and bevel thickness need a stronger asset contract. |
| Now Playing tile | Square source into square inset | Aspect retained. Bright lava detail and crest compete behind the badge. |
| Skin cards | Same header crop as mini, displayed at card-dependent width and 40 height | Crop discards art context and can hide focal details. Needs its own thumbnail or an aspect-aware crop. |

## Clipping and layout risks

These are code-level risks awaiting client screenshots.

1. The concept's tall masthead and vertical navigation cannot fit the current 88-unit header and horizontal tabs without layout work.
2. Most labels have word wrapping disabled. Long titles, translated labels and unusually long room or playlist names need measured bounds and tooltips.
3. Now Playing has a 170-unit art area with a 128-unit crest and a bottom badge. The proposed parchment illustration needs explicit protected bounds.
4. Mini-player text occupies a narrow interval between x=50 and the transport buttons. Its logo/controls need layout at the final design size.
5. The four-pixel progress bar has no room for the reference's ornamental marker. Decorative overflow must stay outside interactive text bounds.
6. No actual client clipping, texture filtering or font rasterization results were captured. The supplied images are concepts.

## Required Trogdor production art

The supplied images are flattened reference compositions. They provide the intended materials and identity, but contain text, overlapping controls and backgrounds. They do not supply clean normal, hover, pressed and disabled assets. Cropping them into every control would bake labels into the UI and leave seams or unwanted neighboring artwork.

Recommended filenames and canvas sizes below are an asset specification. Final screen placements should be agreed through a Trogdor layout pass before painting. Transparent margins should be documented separately from painted content.

| Priority | Asset | Production specification |
| --- | --- | --- |
| P0 | trogdor_signature_header.tga | 1024 by 256 RGBA. Torn parchment over scorched timber with separate dragon focal area. Keep UI labels separate. Declare safe insets and preferred display aspect. |
| P0 | trogdor_wood_tile.tga | 256 by 256 RGB seamless scorched wood, restrained contrast behind text. |
| P0 | trogdor_frame.tga | 512 by 512 RGBA atlas with four distinct iron/bronze corners, horizontal and vertical repeatable edges, and inset values. Fixed corner geometry. |
| P0 | trogdor_panel.tga | 256 by 256 RGBA nine-part bronze and iron panel border with readable wood center or transparent center. Used for queue, room and playlist surfaces. |
| P0 | trogdor_dragon_parchment.tga | 256 by 256 RGBA square illustration, parchment edges intact, alpha outside the paper. |
| P1 | trogdor_tabs.tga | 1024 by 256 RGBA atlas. Four 256 by 64 state strips for crimson cloth tabs. Repeatable center and fixed endcaps, with dynamic labels. |
| P1 | trogdor_buttons.tga | 512 by 512 RGBA atlas. Normal, hover, pressed, selected and disabled frames with documented UVs and fixed caps. |
| P1 | trogdor_transport.tga | 1024 by 512 RGBA atlas. Round play/stop control and framed previous/next/shuffle/repeat controls, with state variants and separate glyphs. |
| P1 | trogdor_progress.tga | 512 by 128 RGBA atlas. Bronze trough, repeatable molten fill and fixed marker with documented transparent padding. |
| P1 | trogdor_volume.tga | 256 by 256 RGBA atlas. Matching slider track and thumb, speaker states, and optional decorative surround. Existing volume interaction stays accessible. |
| P1 | trogdor_live_badge.tga | 512 by 128 RGBA. Fixed-cap crimson/iron plaque, independent microphone and status jewel. Text stays dynamic. |
| P1 | trogdor_queue_states.tga | 512 by 128 RGBA atlas. Normal, hover, selected and unavailable row surfaces, suitable for extending horizontally. |
| P1 | trogdor_mini.tga | 1024 by 128 RGBA. Dedicated background composition with label/transport safe zones and separate border caps. |
| P2 | trogdor_flourish.tga | 256 by 64 RGBA. Secondary flames or cloth accent with protected transparent padding. |
| P2 | trogdor_thumbnail.tga | 256 by 128 RGB/RGBA. Approved skin-picker crop. |

Use power-of-two uncompressed 24/32-bit TGA for consistency with this addon. Validate alpha, orientation and texcoord gutters on Forever. Avoid relying on newer NineSlice utilities. Existing texture primitives can implement fixed corners, endcaps and tiled centers using legacy SetPoint, SetSize and SetTexCoord.

## Shared framework plan

Each skin should declare art descriptors for header, background, outer frame, panel, navigation, buttons, transport, mini-player, progress, volume, badge and queue row. A descriptor needs a path, source dimensions, UV region, logical size, insets, scaling mode and optional state map.

Keep common widget constructors and click handlers. The renderer resolves a descriptor, then builds either an aspect-preserving image, a tiled fill, a three-piece strip or an eight/nine-piece frame. Register these surfaces for skin switching. Give existing skins their current shared atlas as fallback until their own artwork is available. Reapply artwork to both existing frames and lazily created windows.

Retain GuildRadioFMDB.skin and its unknown-key behavior. Keep background preference overrides. Validate metadata and texture paths before publishing a candidate. All source edits should stay in Skins.lua and UI.lua unless an additional UI-only module is justified and placed before UI.lua in the TOC.

## Prioritized implementation sequence

1. Establish the asset specification and Signature layout. Resolve the large-reference layout at a usable screen footprint. Keep controls and labels live.
2. Obtain the P0 production textures and visually check their alpha, aspect, seams and readability at display size.
3. Add descriptor-driven fixed-corner rendering, skin-specific state artwork and legacy fallback, then implement Trogdor alone.
4. Apply the same Trogdor material language to Live, Request Line, library, playlists, settings, skin picker, popups and mini-player.
5. Run state and asset checks. Inspect every screen at 50, 80, 100 and 140 percent scale, long labels, saved selections, preview cancellation and repeated switching.
6. Capture real Forever screenshots before and after at matching scale and content. Package a distinct UI test ZIP with exact commit provenance.
7. Use the approved Trogdor result to scope subsequent skins.

## Verification performed

- Existing Lua 5.1 suites passed before any implementation changes.
- Thirteen skin registry entries resolved with zero missing declared art paths.
- Fifty-five TGA files decoded with power-of-two dimensions.
- Saved Trogdor selection, temporary Alliance preview, preview clearing and preserved unknown-key fallback passed a Lua 5.1 registry check.
- No process named WoW, WowClassic or WowForever was observed during the audit. Actual client rendering, all-screen interaction, scale/clipping inspection and screenshots remain pending.

Phase 2 implementation, a completed Signature skin and a new addon ZIP are pending production art. This phase created documentation only. The stable RC2 ZIP remains the existing deliverable.
