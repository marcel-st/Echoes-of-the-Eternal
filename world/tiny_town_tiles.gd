extends RefCounted

## Approved Tiny Town atlas cells for world painting.
## Keep raw atlas coordinates here so map code can use names instead of guesses.

const GRASS := Vector2i(0, 0)
const GRASS_SPECKLE := Vector2i(1, 0)
const FLOWERS := Vector2i(2, 0)

const DIRT_TOP := Vector2i(1, 1)
const DIRT_EDGE_L := Vector2i(0, 2)
const DIRT_CENTER := Vector2i(1, 2)
const DIRT_EDGE_R := Vector2i(2, 2)
const DIRT_BOTTOM := Vector2i(1, 3)

const STONE_FLOOR_A := Vector2i(0, 4)
const STONE_FLOOR_B := Vector2i(1, 4)
const STONE_FLOOR_C := Vector2i(2, 4)
const RUIN_FLOOR := Vector2i(0, 5)
const RUIN_WALL := Vector2i(6, 10)

const SIGN := Vector2i(11, 6)
const SMALL_ROCK := Vector2i(8, 9)
