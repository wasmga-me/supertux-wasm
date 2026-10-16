# SuperTux in the browser

This fork is the web build of [SuperTux](https://github.com/SuperTux/supertux) that runs on wasmga.me. Play it at **https://wasmga.me/games/supertux**.

It is SuperTux 0.7.0 built with its own Emscripten setup, with networking off. Two upstream files under CC BY-NC 4.0 are replaced: the conveyor belt images with new CC0 drawings (`wasmgame/conveyor_belt/`, made by `draw.py` there) and the death sound with the hurt sound, as in SuperTux 0.6.3. It can also save and restore where the player is (`wg_request_snapshot()` and `wg_restore()`), which the page uses to resume a game.

## What's here

- Branch `wasmgame` (this one) is upstream commit [`6970d03`](https://github.com/SuperTux/supertux/commit/6970d03397801427ab7ebe4740a5cdfc5da8d804) with our changes on top as commits, so `git log` and the diff against `6970d03` show everything we changed.
- [`wasmgame/`](../wasmgame) holds the build script and the same changes as `.diff` files against that commit. `build.sh` starts from a fresh upstream checkout, applies them and builds, and its header comment lists each change.

## Building

Needs git, cmake, make, zip and emsdk 4.0.7 (source `emsdk_env.sh` first).

```sh
sh wasmgame/build.sh /tmp/supertux-build
```

It builds zlib, libpng, freetype, PhysFS (with `physfs.diff`), fmt and glm, then the game, and writes `supertux2.js` and `supertux2.wasm` next to the script. The data goes into five zips under `<work dir>/r2/supertux/`: `start` holds what the title screen and the first level open (`pack-start.txt`, `pack-menus.txt`), then `world1`, `world2`, `cjk` (the Chinese and Japanese font) and `rest`.

## Running it

The page runs `main()` itself (`INVOKE_RUN=0`) once the start zip is written to `/data`, and streams the other zips in while the game runs. For a snapshot, `wg_request_snapshot()` writes the level, position, coins and power-up to `/wg/snapshot.txt`; `wg_restore()` reopens that level from `/wg/restore.txt`.

## Licence

Same as upstream: the code is GPL-3.0-or-later, the data mostly CC-BY-SA. See upstream's own licence files in this repository. Our changes are under the same licence as the files they change.
