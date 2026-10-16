#!/bin/sh
# Builds SuperTux (https://github.com/SuperTux/supertux, GPL-3.0-or-later code,
# data mostly CC-BY-SA) for the site, from upstream source with its own
# Emscripten build (mk/cmake/SuperTux/Emscripten.cmake), with these changes
# (supertux.diff and snapshot.diff beside this script):
# - the data isn't bundled into a .data file: the play page downloads it in
#   five zips (on R2, at /files/supertux/) and writes them to /data, so the
#   game starts once the first one is in;
# - main() is run by the play page (INVOKE_RUN=0) and FS is exported;
# - networking is off: add-ons aren't offered;
# - snapshot.diff adds the play page's Resume: wg_request_snapshot() writes
#   the level Tux is in, where he stands, his coins and power-up to
#   /wg/snapshot.txt, and wg_restore() opens that level again from
#   /wg/restore.txt;
# - two files whose licence (CC BY-NC 4.0) doesn't allow a site with ads are
#   replaced (supertux.diff notes it in AUTHORS, the copies are below): the
#   conveyor belt pictures, with ones drawn for this site (conveyor_belt/, by
#   draw.py there, CC0), and the death sound, with the hurt sound, as in
#   SuperTux 0.6.3.
# Its libraries (zlib, libpng, freetype, PhysFS, fmt, glm) are built here
# too; PhysFS gets a base dir of / under Emscripten (physfs.diff), as
# SuperTux gives it no argv[0] there.
#
# The zips: start (the title screen, the first world's map, its intro and
# first level), world1 and world2 hold the files listed in pack-*.txt beside
# this script, which are the files SuperTux opened when each of those levels
# was played (pack-menus.txt: when the Credits, without its music, and the
# Level Editor were opened from the title screen; start holds those); cjk
# holds the Chinese and Japanese font, and rest everything else.
#
# Needs git, cmake, make, zip and emsdk 4.0.7 (source emsdk_env.sh first).
# Usage: sh build.sh [work dir]
# Writes supertux2.js and supertux2.wasm next to this script, and the zips for
# R2 to <work dir>/r2/supertux/ (upload them to wasmgame-files under the same
# keys). For a newer SuperTux, copy this folder to supertux-<new rev>-p1 and
# change the revision below; a change to the build here takes the next -p
# number.
set -eu

SUPERTUX_REV=6970d03397801427ab7ebe4740a5cdfc5da8d804
EMSDK_VERSION=4.0.7

here=$(cd "$(dirname "$0")" && pwd)
work=${1:-${TMPDIR:-/tmp}/supertux-build}

case "$(emcc --version | head -1)" in
  *" $EMSDK_VERSION "*) ;;
  *) echo "warning: built and tested with emsdk $EMSDK_VERSION" >&2 ;;
esac

# Emscripten fetches these ports as GitHub archives; clone them instead.
. "$here/ports.sh"
port zlib madler/zlib v1.3.1 zlib-1.3.1 https://github.com/madler/zlib/archive/refs/tags/v1.3.1.tar.gz
port sdl2 libsdl-org/SDL release-2.32.0 SDL-release-2.32.0 https://github.com/libsdl-org/SDL/archive/release-2.32.0.zip
port sdl2_image libsdl-org/SDL_image release-2.6.0 SDL_image-release-2.6.0 https://github.com/libsdl-org/SDL_image/archive/refs/tags/release-2.6.0.zip
port ogg emscripten-ports/ogg version_1 Ogg-version_1 https://github.com/emscripten-ports/ogg/archive/version_1.zip
port vorbis emscripten-ports/vorbis version_1 Vorbis-version_1 https://github.com/emscripten-ports/vorbis/archive/version_1.zip

prefix=$work/deps
mkdir -p "$work/libs"
# dep <name> <repo> <tag> [cmake args]: builds and installs a library into $prefix once.
dep() {
  name=$1 repo=$2 tag=$3
  shift 3
  [ -f "$work/libs/$name.done" ] && return
  rm -rf "$work/libs/$name"
  git -c advice.detachedHead=false clone -q --depth 1 -b "$tag" "https://github.com/$repo.git" "$work/libs/$name"
  if [ "$name" = physfs ]; then git -C "$work/libs/physfs" apply "$here/physfs.diff"; fi
  emcmake cmake -S "$work/libs/$name" -B "$work/libs/$name/build" -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_PREFIX_PATH="$prefix" -DCMAKE_FIND_ROOT_PATH="$prefix" \
    -DBUILD_SHARED_LIBS=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5 "$@"
  make -j"${JOBS:-$(nproc)}" -C "$work/libs/$name/build" install
  touch "$work/libs/$name.done"
}
# zlib's build races on libz.a with more than one job.
JOBS=1 dep zlib madler/zlib v1.3.1 -DZLIB_BUILD_EXAMPLES=OFF
dep libpng pnggroup/libpng v1.6.47 -DPNG_SHARED=OFF -DPNG_TESTS=OFF -DPNG_TOOLS=OFF
dep freetype freetype/freetype VER-2-13-3 -DFT_DISABLE_HARFBUZZ=ON -DFT_DISABLE_BROTLI=ON -DFT_DISABLE_BZIP2=ON -DFT_REQUIRE_PNG=ON -DFT_REQUIRE_ZLIB=ON
dep physfs icculus/physfs release-3.2.0 -DPHYSFS_BUILD_SHARED=OFF -DPHYSFS_BUILD_TEST=OFF -DPHYSFS_BUILD_DOCS=OFF
dep fmt fmtlib/fmt 11.1.4 -DFMT_TEST=OFF -DFMT_DOC=OFF
dep glm g-truc/glm 1.0.1 -DGLM_BUILD_TESTS=OFF
# SuperTux looks for PhysFS::PhysFS; a static-only install names it PhysFS::PhysFS-static.
grep -q "PhysFS::PhysFS ALIAS" "$prefix/lib/cmake/PhysFS/PhysFSConfig.cmake" ||
  printf '\nif(NOT TARGET PhysFS::PhysFS)\n  add_library(PhysFS::PhysFS ALIAS PhysFS::PhysFS-static)\nendif()\n' >> "$prefix/lib/cmake/PhysFS/PhysFSConfig.cmake"

if [ ! -d "$work/src" ]; then
  git clone -q --recurse-submodules https://github.com/SuperTux/supertux.git "$work/src"
fi
cd "$work/src"
git checkout -q -f $SUPERTUX_REV
git submodule update -q --init --recursive

git apply "$here/snapshot.diff"
git apply "$here/supertux.diff"

emcmake cmake -S . -B "$work/build" -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$prefix" -DCMAKE_FIND_ROOT_PATH="$prefix" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DENABLE_NETWORKING=OFF -DPhysFS_PREFER_FIND_PACKAGE=ON
make -j"$(nproc)" -C "$work/build" supertux2
cp "$work/build/supertux2.js" "$work/build/supertux2.wasm" "$here/"

rm -rf "$work/r2" && mkdir -p "$work/r2/supertux" "$work/packs"
cd data
cp "$here"/conveyor_belt/*.png images/objects/conveyor_belt/
cp sounds/hurt.wav sounds/kill.wav
# start also holds the folders SuperTux adds to its search path as it starts
# (they must be there then), what any level may use (the HUD, power-ups,
# sounds, speech, particles, scripts), the first world's own folder and map
# music, every menu's pictures and levels (Options icons, the credits, the
# retro title), the end of level and star music, and the fonts but the
# Chinese and Japanese one, which is its own zip: the play page waits for it
# in those languages. world1 also holds the other title and credits music,
# world2 the second world's own folder.
find locale shader images/credits images/engine/hud images/engine/menu images/engine/options images/engine/mobile images/powerups sounds speech particles scripts fonts levels/*.nut levels/misc/*.stl levels/world1 music/antarctic/worldmap_ice.* music/misc/leveldone.* music/misc/invincible.* -type f ! -name 'NotoSansCJK*' |
  cat - "$here/pack-start.txt" "$here/pack-menus.txt" | LC_ALL=C sort -u > "$work/packs/start.txt"
echo fonts/NotoSansCJKjp-Medium.otf > "$work/packs/cjk.txt"
find music/misc -type f | cat - "$here/pack-world1.txt" | LC_ALL=C sort -u | LC_ALL=C comm -23 - "$work/packs/start.txt" > "$work/packs/world1.txt"
find levels/world2 -type f | cat - "$here/pack-world2.txt" | LC_ALL=C sort -u | LC_ALL=C comm -23 - "$work/packs/start.txt" > "$work/packs/world2.txt"
find . -type f | sed 's|^\./||' | LC_ALL=C sort > "$work/packs/all.txt"
cat "$work/packs/start.txt" "$work/packs/cjk.txt" "$work/packs/world1.txt" "$work/packs/world2.txt" | LC_ALL=C sort > "$work/packs/listed.txt"
LC_ALL=C comm -23 "$work/packs/all.txt" "$work/packs/listed.txt" > "$work/packs/rest.txt"
for p in start cjk world1 world2 rest; do
  rm -f "$work/packs/$p.zip"
  zip -q -X -D -9 -n .png:.jpg:.ogg:.ttf:.otf "$work/packs/$p.zip" -@ < "$work/packs/$p.txt"
  cp "$work/packs/$p.zip" "$work/r2/supertux/$p-$(sha256sum "$work/packs/$p.zip" | cut -c1-12).zip"
done
ls -l "$work/r2/supertux"
