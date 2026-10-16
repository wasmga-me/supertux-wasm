//  wasmga.me: the play page's Resume snapshots (snapshot.diff).
//
//  wg_request_snapshot() asks for one; it is written to SNAPSHOT_FILE at the
//  top of a frame, once Tux stands on the ground, and wg_snapshot_count() goes
//  up. wg_restore() loads RESTORE_FILE: the screens above the title close,
//  the snapshot's worldmap opens, and the level it was in starts again with
//  Tux where he stood, with the coins and power-up he had.
#pragma once

#include <string>

#include "math/vector.hpp"

namespace wg {

inline const char* const SNAPSHOT_FILE = "/wg/snapshot.txt";
inline const char* const RESTORE_FILE = "/wg/restore.txt";

struct Snapshot
{
  std::string kind = "none"; // none, map or level
  std::string world, map, map_sector, level, sector;
  Vector pos;
  int coins = 0;
  int bonus = 0;
};

/** The folder of the world last opened on a worldmap (World::get_basedir()). */
inline std::string world_dir;
/** The level the opening worldmap enters, once its sector is up. */
inline bool enter_pending = false;
/** Set while that level is being entered from the worldmap. */
inline bool entering = false;
/** Set until Tux, in the level just entered, has the snapshot's power-up. */
inline bool bonus_pending = false;
inline Snapshot pending;

/** Runs at the top of every frame. */
void tick();

} // namespace wg
