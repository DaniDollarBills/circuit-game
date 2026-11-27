#!/usr/bin/env node
// Builds game/data/land_110m.json: Natural Earth's 1:110m land outlines
// (public domain) from the world-atlas@2.0.2 npm package, as
// {"polygons": [[[lon, lat], …], …]} with outer rings only, 2 decimals.
//
// Usage: node tools/make_land.mjs
// The package is fetched with `npm pack` into a fresh temp folder. Only its
// data file is read; the TopoJSON is decoded here, so no downloaded code runs.
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const OUT = path.join(ROOT, "game", "data", "land_110m.json");

const dir = mkdtempSync(path.join(tmpdir(), "circuit-land-"));
try {
  execFileSync("npm", ["pack", "world-atlas@2.0.2", "--silent"], { cwd: dir, stdio: ["ignore", "pipe", "inherit"] });
  execFileSync("tar", ["-xzf", "world-atlas-2.0.2.tgz", "package/land-110m.json"], { cwd: dir });
  const topo = JSON.parse(readFileSync(path.join(dir, "package", "land-110m.json"), "utf8"));
  const polygons = decodeLand(topo);
  writeFileSync(OUT, JSON.stringify({ polygons }));
  console.log(`wrote ${path.relative(ROOT, OUT)}: ${polygons.length} polygons, ${readFileSync(OUT).length} bytes`);
} finally {
  rmSync(dir, { recursive: true, force: true });
}

// TopoJSON: arcs are delta-encoded, quantized points; a ring lists arc
// indices, where ~i means arc i reversed; joined arcs share their end point.
function decodeLand(topo) {
  const [sx, sy] = topo.transform.scale;
  const [tx, ty] = topo.transform.translate;
  const arcs = topo.arcs.map((arc) => {
    let x = 0;
    let y = 0;
    return arc.map(([dx, dy]) => {
      x += dx;
      y += dy;
      return [x * sx + tx, y * sy + ty];
    });
  });
  const ring = (indices) => {
    const out = [];
    for (const i of indices) {
      const pts = i >= 0 ? arcs[i] : arcs[~i].slice().reverse();
      out.push(...(out.length ? pts.slice(1) : pts));
    }
    return out.map(([lon, lat]) => [round(lon), round(lat)]);
  };
  const land = topo.objects.land;
  const geoms = land.type === "GeometryCollection" ? land.geometries : [land];
  const polygons = [];
  for (const g of geoms) {
    const polys = g.type === "MultiPolygon" ? g.arcs : g.type === "Polygon" ? [g.arcs] : [];
    for (const p of polys) polygons.push(ring(p[0]));
  }
  return polygons;
}

function round(v) {
  return Math.round(v * 100) / 100;
}
