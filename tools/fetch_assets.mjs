#!/usr/bin/env node
// Downloads the third-party assets listed in game/assets/third_party/manifest.json
// and verifies every file against its checksum.
//
// Poly Haven files are resolved through https://api.polyhaven.com/files/<id>
// at 2K: HDRIs as .hdr, textures as the diff, nor_gl and rough JPGs. Any other
// source must give a url and a sha256. Files that already verify are skipped;
// any mismatch exits non-zero.
//
//   node tools/fetch_assets.mjs          download and verify
//   node tools/fetch_assets.mjs --pin    also write the resolved urls and md5s
//                                        into the manifest (for new entries)
//
// Behind an HTTPS proxy, run Node 22.21+ with NODE_USE_ENV_PROXY=1.
// Node 22, no dependencies.
import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const GAME = path.join(ROOT, "game");
const MANIFEST = path.join(GAME, "assets/third_party/manifest.json");
const USER_AGENT = "circuit-game-asset-fetch/1.0";
const PIN = process.argv.includes("--pin");

async function get(url) {
  const res = await fetch(url, { headers: { "User-Agent": USER_AGENT } });
  if (!res.ok) throw new Error(`${url}: HTTP ${res.status}`);
  return res;
}

function digest(algorithm, bytes) {
  return createHash(algorithm).update(bytes).digest("hex");
}

async function readOrNull(file) {
  try {
    return await readFile(file);
  } catch {
    return null;
  }
}

// The Poly Haven listing entry for one manifest file, chosen by its name.
function polyhavenFile(listing, file) {
  const name = path.basename(file.path);
  if (name.endsWith(".hdr")) return listing.hdri["2k"].hdr;
  const maps = { "_diff_2k.jpg": "Diffuse", "_nor_gl_2k.jpg": "nor_gl", "_rough_2k.jpg": "Rough" };
  for (const [suffix, key] of Object.entries(maps)) {
    if (name.endsWith(suffix)) return listing[key]["2k"].jpg;
  }
  throw new Error(`${file.path}: not a 2K hdr, diff, nor_gl or rough file`);
}

async function main() {
  const manifest = JSON.parse(await readFile(MANIFEST, "utf8"));
  let failed = false;
  for (const entry of manifest) {
    const listing = entry.source === "polyhaven"
      ? await (await get(`https://api.polyhaven.com/files/${entry.id}`)).json()
      : null;
    for (const file of entry.files) {
      const target = path.join(GAME, file.path);
      let url = file.url;
      let algorithm = file.md5 ? "md5" : "sha256";
      let expected = file.md5 ?? file.sha256;
      if (listing) {
        const remote = polyhavenFile(listing, file);
        if (file.md5 && file.md5 !== remote.md5) {
          console.error(`MISMATCH ${file.path}: Poly Haven now lists md5 ${remote.md5}, the manifest pins ${file.md5}`);
          failed = true;
          continue;
        }
        url = remote.url;
        algorithm = "md5";
        expected = remote.md5;
        if (PIN) {
          file.url = remote.url;
          file.md5 = remote.md5;
        }
      }
      if (!url || !expected) {
        console.error(`MISSING ${file.path}: needs a url and a checksum`);
        failed = true;
        continue;
      }
      const existing = await readOrNull(target);
      if (existing && digest(algorithm, existing) === expected) {
        console.log(`verified ${file.path} (already present)`);
        continue;
      }
      const bytes = Buffer.from(await (await get(url)).arrayBuffer());
      const actual = digest(algorithm, bytes);
      if (actual !== expected) {
        console.error(`MISMATCH ${file.path}: ${algorithm} ${actual}, expected ${expected}`);
        failed = true;
        continue;
      }
      await mkdir(path.dirname(target), { recursive: true });
      await writeFile(target, bytes);
      console.log(`verified ${file.path} (${bytes.length} bytes)`);
    }
  }
  if (PIN) await writeFile(MANIFEST, JSON.stringify(manifest, null, 2) + "\n");
  process.exit(failed ? 1 : 0);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
