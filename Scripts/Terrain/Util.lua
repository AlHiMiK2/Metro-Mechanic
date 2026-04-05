CELL_MIN_X = -16
CELL_MAX_X = 16
CELL_MIN_Y = -127
CELL_MAX_Y = 127
PADDING = 8
-- Dev
-- CELL_MIN_X = -1
-- CELL_MAX_X = 2
-- CELL_MIN_Y = -2
-- CELL_MAX_Y = 2

-- This is here to expose stuff to other classes (as SurvivalGame handles respawning player and needs values)
function getElevation(x, y, seed, startTile)
  local elevation = 1.5
  if startTile then
    local fixedElevation = getElevation(x, y, 353672611)
    local proportion = math.min(math.max(y / (CELL_MAX_Y - PADDING - 1), 0), 1)
    elevation = (elevation * proportion) + (fixedElevation * (1 - proportion))
end

  return elevation
end