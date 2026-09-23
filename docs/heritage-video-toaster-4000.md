<!-- docs/heritage-video-toaster-4000.md -->

# Video Toaster 4000 / LightWave Heritage Laboratory

Consumer proof for the eighth promoted theme in [Heritage Themes #103](https://github.com/scarver2/activeadmin-react-showcase/issues/103).
Visit `/admin/video_toaster_4000_laboratory` after signing in, or choose
**Overview → Video Toaster 4000 Laboratory**. It is a separate production-tool
study rather than a skin on the Haiku beta6 or Amiga laboratories.

Presentation comes from the stacked `activeadmin-themes` Video Toaster 4000
theme at exact head `26a7cd6f7b4df39e61e33bfb12e77ec50d0f8bb0`.
Showcase maps the gem's immutable 24 semantic roles onto
host-owned Rails markup and keeps routes, records, authorization, filtering,
accessibility, and native behavior local. It contains no Showcase presentation
patch. The installed stylesheet is byte-identical to the exact gem composer.

## Reference And Provenance

The reference corpus was inspected September 22, 2026. The historical boundary
is Video Toaster 4000 software 3.1 (1993) and LightWave 3D 3.5 for Amiga
(1994), not a generic dark video editor or a later Windows/TriCaster lineage:

- [Official LightWave3D history](https://lightwave3d.com/documentation/lightwave-history/), used for chronology and product-lineage context.
- Official first-party 1994 [LightWave 3.5 Layout](https://lightwave3d.com/media/images/1994-Layout3.5.width-800.png) and [LightWave 3.5 Modeler](https://lightwave3d.com/media/images/1994-Modeler3.5.width-800.gif) captures, used as the canonical LightWave spatial-workbench references. The history page's 1993 LightWave 3 / Video Toaster 4000 images establish lineage only.
- [NewTek Video Toaster 4000 Manual](https://retro-commodore.eu/files/downloads/amigamanuals-xiik.net/Hardware/Video%20Toaster%204000%20-%20Manual-ENG.pdf), a ©1990–1995 NewTek period primary reference inspected without redistributing its contents.
- [NewTek Video Toaster Developer's Handbook](https://discreetfx.com/documents/NewTekVideoToasterDevelopersHandbook.pdf), a ©1995 period primary technical reference inspected without redistributing its contents.
- [Kansas Historical Society Video Toaster Manual artifact record](https://www.kansashistory.gov/museum/musobjs/view/320071), independently corroborating the historical artifact.
- [Amiga Hardware Database Video Toaster 4000 record](https://amiga.resource.cx/exp/videotoaster4000), used as a secondary reference for the 1993 product/version boundary.
- [Issue #103 visual reference](https://i.ytimg.com/vi/6yFdaCmRkBk/maxresdefault.jpg), supplied by Sheriff as secondary observational evidence only, not an official period promotion.

No NewTek, Video Toaster, or LightWave source, screenshot, logo, icon, font,
texture, effect thumbnail, interface bitmap, proprietary control, product
behavior, video hardware behavior, or 3D runtime is redistributed. Surviving Open Video Toaster licensing records are not
clear enough to establish a reusable source boundary, so the implementation
does not copy from or depend on that code. All installed CSS, geometry, palette,
decoration, responsive rules, and states are original work supplied by the gem.
The referenced marks belong to their respective owners; this independent study
is not an official product or endorsement.

## Historical Reference → Constraint → Adaptation

| Historical reference | AA4 / modern constraint | Heritage adaptation |
| --- | --- | --- |
| Toaster operator console: dense horizontal control banks, effects selectors, MAIN/PREVIEW buses, and action row | ActiveAdmin owns semantics, authorization, routes, and behavior | Bus and bank hierarchy groups real Rails routes, the account data view, and its allowlisted GET filter without simulating video switching |
| Toaster purple-charcoal and lavender controls, with red reserved for tally/danger | Status cannot depend on color alone | Text labels, borders, shape, and semantic status content reinforce every restrained color cue |
| LightWave spatial workbench: top mode tabs, stacked tool groups, dominant dark viewport, bottom status/timeline | The host must not simulate a 3D viewport, tools, scene state, or timeline | Semantic launchers, data region, provenance disclosure, and truthful record-count footer adapt the hierarchy to real host capabilities |
| LightWave grayscale field with selected yellow | Keyboard focus and selection are distinct states | Selected/current emphasis combines yellow with border/shape while a separate visible focus ring remains intact |
| Compact period production tools | Pointer, zoom, responsive, and assistive access must remain usable | System-monospace typography stays readable, coarse-pointer targets reach 44px, and the composition preserves local overflow, reduced motion, and forced-colors support |

## Behavior And Ownership

ActiveAdmin owns authentication, navigation, resource routes and actions. The
unchanged `Showcase::HeritageAccountsWorkspace` allowlists account status,
orders by name and id, and returns at most eight existing records. Rails escapes
record content and generates every URL. The page adds no write action,
persistence, JavaScript state machine, network dependency, or production data.

Only this route opts into `data-activeadmin-theme="video_toaster_4000"`. The gem
owns every `--video-toaster-4000-*` token, composition selector, and installed
byte. Showcase owns semantic markup, accessible names, behavior, tests, and
evidence. The integration spec rejects any Video Toaster 4000 token or
selector in the host entrypoint beyond its explicit stylesheet import.

## Verification

Request coverage verifies authentication, all 24 recipe roles, GET filtering,
escaping, empty recovery, route isolation, and byte-identical installation.
Chromium coverage exercises desktop and narrow
layouts, keyboard use, focusable local overflow, no document overflow, native
filtering/navigation, reduced motion, forced colors, and a no-JavaScript path.

Actual browser 200% zoom, physical devices, and additional engines are not
claimed. A 390px viewport is responsive evidence, not genuine browser zoom.

The host pins `activeadmin-themes` exact head
`26a7cd6f7b4df39e61e33bfb12e77ec50d0f8bb0`; installed Video Toaster 4000 CSS
SHA-256 is `a5296593724aea2d14ad5dfaf2d48b07df573398e930936c49cd48abbcffb2e8`.
The first browser capture was visually inspected before final evidence was
recorded. At 390px, the host's existing global color-palette selector truncates
its visible “Classic Neutral” label outside the route-scoped theme workspace;
this pre-existing shell issue is disclosed rather than patched in this slice.

## Collection Remains Open

This slice does not complete #103. Mercury Flight and subsequent Heritage
studies remain independently scoped. No release, deployment, publication, or
Rodeo adoption is authorized.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
