# Third-party assets

Every file here is free to use, with no attribution required. We credit the artists anyway.
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
- **License:** Public domain (Natural Earth). The tiles come from the Cesium project's `@cesium/engine` 9.0.0 npm package (Apache-2.0), which tiles and recolors the raster; `tools/make_earth.mjs` checks the package's integrity and stitches its level-2 tiles.
- **Why not NASA Blue Marble:** NASA's image host (eoimages.gsfc.nasa.gov) refused connections from the build machine; the plan's fallback applies until it opens.

