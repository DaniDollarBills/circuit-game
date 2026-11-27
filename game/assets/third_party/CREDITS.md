# Third-party assets

Every file here is free to use. Only the globe texture asks for anything: its tiles come under the Apache License 2.0, whose text ships beside it. We credit the artists anyway.
`tools/fetch_assets.mjs` downloads each file and checks it against the checksum pinned in `manifest.json`.

| Asset (id) | What it is | Artists | License | Link |
|---|---|---|---|---|
| Studio Small 09 (`studio_small_09`) | HDRI: a small photo studio, lights the workbench | Sergej Majboroda | CC0 | https://polyhaven.com/a/studio_small_09 |
| Kloofendal 48d Partly Cloudy, Pure Sky (`kloofendal_48d_partly_cloudy_puresky`) | HDRI: open sky for the coast | Greg Zaal, Jarod Guest | CC0 | https://polyhaven.com/a/kloofendal_48d_partly_cloudy_puresky |
| Wood Table 001 (`wood_table_001`) | Texture: the desk | Dimitrios Savva, Rico Cilliers | CC0 | https://polyhaven.com/a/wood_table_001 |
| Aerial Beach 01 (`aerial_beach_01`) | Texture: sand and shallows seen from above | Rob Tuytel | CC0 | https://polyhaven.com/a/aerial_beach_01 |
| Sand 01 (`sand_01`) | Texture: beach sand up close | Rob Tuytel | CC0 | https://polyhaven.com/a/sand_01 |

All five come from [Poly Haven](https://polyhaven.com), whose assets are CC0 (public domain dedication).

## natural_earth_ii

- **What:** the globe's day texture, `naturalearth/natural_earth_ii_2048.jpg` (2048 × 1024, equirectangular).
- **Source:** Natural Earth II with shaded relief, water and drainages, https://www.naturalearthdata.com/downloads/10m-raster-data/10m-natural-earth-2/
- **License:** the Natural Earth II raster is public domain. The tiles come from the Cesium project's `@cesium/engine` 9.0.0 npm package, which is licensed under the Apache License 2.0 and has no separate terms for them, so they are treated as Apache-2.0: the package's license is copied to `naturalearth/LICENSE-Apache-2.0.md`. `tools/make_earth.mjs` checks the package's integrity and stitches its level-2 tiles.
- **Why not NASA Blue Marble:** NASA's image host (eoimages.gsfc.nasa.gov) refused connections from the build machine; the plan's fallback applies until it opens.

## Fonts (`game/assets/fonts`)

- **Nunito** (400, 700 and 800, Latin subset), by the Nunito Project Authors, SIL Open Font License 1.1: `fonts/LICENSE`.
- **DejaVu Sans** and **DejaVu Sans Bold** 2.37, from Debian's `fonts-dejavu-core` 2.37-8, unmodified: the Bitstream Vera license, with DejaVu's own changes in the public domain, in `fonts/LICENSE-DejaVu.txt`. They draw only what Nunito lacks: Ω, superscripts, ≈, ✓, ✗, ○ and ★. SHA-256: `dejavu-sans.ttf` ae7b7855e115a5966d8b1b3f80f254ccc117ec86f9965e202ee2940453837280, `dejavu-sans-bold.ttf` 5c1247acef7f2b8522a31742c76d6adcb5569bacc0be7ceaa4dc39dd252ce895.
