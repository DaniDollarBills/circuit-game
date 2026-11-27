#!/usr/bin/env node
// Builds game/assets/third_party/naturalearth/natural_earth_ii_2048.jpg, the
// globe's day texture: the Natural Earth II shaded-relief raster (public
// domain, naturalearthdata.com) as tiled and recolored for the Cesium project
// (Apache-2.0). It takes the 8 × 4 level-2 tiles (256 px, EPSG:4326, origin at
// the bottom left) from the @cesium/engine@9.0.0 npm package, checks the
// package's pinned integrity, and stitches them into one 2048 × 1024
// equirectangular image with Godot.
//
// Usage: node tools/make_earth.mjs   (then pin the printed sha256)
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdtempSync, readFileSync, writeFileSync, rmSync, mkdirSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const TARBALL = "https://registry.npmjs.org/@cesium/engine/-/engine-9.0.0.tgz";
const INTEGRITY = "sha512-GIeBitHo1t6OwgWnxAsCoHuCcJEfdki2G0hbKfaP87r2EapbnDLBmfxZziscl1ksv7kQiQ6x2FOOSPuV9QFvhA==";
const TILES = "package/Source/Assets/Textures/NaturalEarthII/2";
const OUT = "assets/third_party/naturalearth/natural_earth_ii_2048.jpg";

const dir = mkdtempSync(path.join(tmpdir(), "circuit-earth-"));
try {
  const res = await fetch(TARBALL, { headers: { "User-Agent": "circuit-game-asset-fetch/1.0" } });
  if (!res.ok) throw new Error(`${TARBALL}: HTTP ${res.status}`);
  const bytes = Buffer.from(await res.arrayBuffer());
  const actual = "sha512-" + createHash("sha512").update(bytes).digest("base64");
  if (actual !== INTEGRITY) throw new Error(`integrity mismatch: ${actual}`);
  writeFileSync(path.join(dir, "engine.tgz"), bytes);
  execFileSync("tar", ["-xzf", "engine.tgz", TILES], { cwd: dir });
  mkdirSync(path.join(ROOT, "game", path.dirname(OUT)), { recursive: true });
  const godot = execFileSync(path.join(ROOT, "tools", "godot.sh")).toString().trim();
  execFileSync(godot, ["--headless", "--path", path.join(ROOT, "game"), "-s", "res://tools/stitch_tiles.gd", "--",
    `--tiles=${path.join(dir, TILES)}`, "--cols=8", "--rows=4", `--out=res://${OUT}`], { stdio: "inherit" });
  const sha = createHash("sha256").update(readFileSync(path.join(ROOT, "game", OUT))).digest("hex");
  console.log(`wrote game/${OUT} sha256 ${sha}`);
} finally {
  rmSync(dir, { recursive: true, force: true });
}
