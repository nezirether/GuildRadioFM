# GRFM original emblem art handoff

Codex implements layout, transparent texture integration, testing and packaging. ChatGPT supplies original emblem and decorative artwork. Candidate UI.2 removes the retired circular emblem presentation. Final visual acceptance requires all thirteen approved original emblems and actual Forever screenshots.

## Files to give ChatGPT

GRFM_EMBLEM_PRODUCTION_MANIFEST.json lists all thirteen designs, materials, filenames, canvas dimensions and per-context placements. GRFM_EMBLEM_BUILD_MANIFEST.json is ready for the conversion tool once source PNGs exist.

Create exactly one main emblem per skin at assets/<key>/emblem.png. Use a 512 by 512 RGBA PNG with a fully transparent background, clean colored edge pixels and at least a 16-pixel transparent exterior gutter. Keep every ornament, feather, flame and shadow inside the canvas. The painted silhouette can be tall, wide, open, forked or irregular. Keep lettering, counts, labels and other dynamic text out of the image.

Each image needs its own composition and material treatment. Use an original design informed by the supplied references. The source composition should remain legible when reduced to roughly 30–45 pixels in the picker and mini-player. Make the central silhouette bold. Use restrained decoration at the edges. The full Trogdor Signature reference governs its parchment dragon treatment. The supplied banner screenshot establishes the tall cloth-and-finial language for Stormwind.

## Required identity per skin

| Skin | Silhouette and treatment |
| --- | --- |
| Trogdor | Irregular scorched parchment with an original burninating dragon, crimson cloth and bronze pins. |
| Alliance | Tall ceremonial blue shield, gold lion heraldry and polished winged metalwork. |
| Horde | Forked crimson war banner, dark iron weapon brackets and a spiked crown. |
| Undercity | Gothic bone reliquary with purple stone and plague-green alchemical glass. |
| Orgrimmar | Broad tribal leather standard framed by timber and asymmetric tusks. |
| Stormwind | Long blue swallowtail pennant with lion heraldry, gold rods and white-stone finials. |
| Thunder Bluff | Narrow carved totem with turquoise and offset feathers. |
| Darnassus | Open silver crescent embracing violet ancient wood and irregular vines. |
| Ironforge | Wide bronze anvil and stone forge, geometric runes and an inset fire aperture. |
| Blood Moon | Pointed obsidian lancet with torn crimson eclipse and gothic architecture. |
| Sleek | Open faceted glass planes, precise asymmetry and subtle cyan edge light. |
| Classic | Uneven folded parchment, bronze fasteners and original music heraldry. |
| Retail | Vertical blue crystal spire with layered polished gold wings. |

The detailed JSON specifies maximum viewports, anchors and offsets for main player, picker, header, mini-player and popups. Those are placement constraints. The renderer preserves the painted aspect ratio inside them.

## Integration

Run from the addon root with Pillow installed.

```text
python tools/build_skin_assets.py docs/GRFM_EMBLEM_BUILD_MANIFEST.json --source assets --output work/emblem-build
```

The tool validates 512 by 512 canvases, transparency, nonempty alpha content and transparent corners. It computes bounds from alpha, exports uncompressed RGBA TGA and writes SkinAssets.lua with one emblem registration per skin. Review the images and generated output before integrating. The staging directory must be empty.

If other production surface/icon registrations already exist, combine their manifests with the emblem manifest before compilation. Generated SkinAssets.lua replaces the registration module. Keep existing reviewed roles in the combined input.

A runtime emblem descriptor contains path, width=512, height=512, mode=contain and bounds={left,top,right,bottom}. Bounds describe the painted alpha extent in source pixels. The renderer crops transparent padding using those bounds and fits the remaining painted aspect into each skin's viewport. A missing file hides the emblem and gives text the available main-player space. The retired circular crests are not emblem fallbacks.

The prior surfaces.crest descriptor is superseded by the emblem field for these placements. Existing emblem textures remain in the archive as historical assets and have no bindings in the redesigned main, picker, header, mini or popup presentation.

## Review required

Check every theme at actual display size against the other twelve. Confirm distinct silhouettes, clean transparency, stable material identity and recognizable small forms. Visually inspect alpha edges, soft shadows and any opaque interior plates. Automated alpha checks cannot distinguish an intentional shield from an unwanted baked rectangular background.

In Forever, inspect main, picker, mini, popup and header at 50, 80, 100 and 140 percent scale. Confirm names remain clear, ornaments remain within viewports and no decoration obscures controls. Capture Trogdor, Horde and Alliance before/after at matching scale and content.

Both linked wiki pages blocked retrieval in this session. Their images were not downloaded. The attached Stormwind-style banner screenshot and the previously supplied concept images are the visual references used for this specification.
