local g_desert = {} --Flags lookup table

local function toDesertIndex( se, sw, nw, ne )
	return bit.bor( bit.lshift( se, 3 ), bit.lshift( sw, 2 ), bit.lshift( nw, 1 ), bit.tobit( ne ) )
end

function initCustomTiles()

  -- Desert tiles
	g_desert = {
		AddTile( 3001507, "$CONTENT_DATA/Terrain/Tiles/Drisnya/desert_01.tile", 3 ),
	}

  -- Just north/south straight road tiles with no cliff data
  	g_roads = { 
		tiles = { 
			AddTile( 1128001, "$CONTENT_DATA/Terrain/Tiles/MetroRoad.tile" ), 
		},
		rotation = 3
	}

	g_road_obstacles = { 
		tiles = { 
			AddTile( 1128001, "$CONTENT_DATA/Terrain/Tiles/MetroRoad2.tile" ), 
		},
		rotation = 3,
		chance = 5 ---100%(max)
	}

  	g_roads_r = { 
		tiles = { 
			AddTile( 1128002, "$CONTENT_DATA/Terrain/Tiles/MetroCurveR.tile" ), 
		},
		rotation = 0
	}

	g_roads_l = { 
		tiles = { 
			AddTile( 1128004, "$CONTENT_DATA/Terrain/Tiles/MetroCurveL.tile" ), 
		},
		rotation = 0
	}

  	g_road_ends = { 
		AddTile( 1293000, "$CONTENT_DATA/Terrain/Tiles/Drisnya/road_end.tile" ), 
	}
	
  	g_starter_connectors = { 
		AddTile( 5323001, "$CONTENT_DATA/Terrain/Tiles/Drisnya/StarterConnectionRoad.tile" ), 
	}

  	g_elevators = { 
		AddTile( 9423000, "$CONTENT_DATA/Terrain/Tiles/Drisnya/elevator.tile" ), 
	}

  	g_fences = {
		AddTile( 5002500, "$CONTENT_DATA/Terrain/Tiles/Drisnya/fence_01.tile", 5 ),
		AddTile( 5002501, "$CONTENT_DATA/Terrain/Tiles/Drisnya/fence_02.tile", 5 ),
	}

  	g_fence_corners = {
		AddTile( 5002600, "$CONTENT_DATA/Terrain/Tiles/Drisnya/fence_corner_01.tile", 5 ),
	}

  	g_scorched = {
		AddTile( 1232500, "$CONTENT_DATA/Terrain/Tiles/Drisnya/scorched_01.tile", 5 ),
		AddTile( 1232501, "$CONTENT_DATA/Terrain/Tiles/Drisnya/scorched_02.tile", 5 ),
		AddTile( 1232502, "$CONTENT_DATA/Terrain/Tiles/Drisnya/scorched_03.tile", 5 ),
		AddTile( 1232503, "$CONTENT_DATA/Terrain/Tiles/Drisnya/scorched_04.tile", 5 ),
	}

	g_starter_houses = {
		AddTile( 1222500, "$CONTENT_DATA/Terrain/Tiles/Start Depo.tile" )
	}
	
	g_road_pois = {
		{tile = AddTile( 4201008, "$CONTENT_DATA/Terrain/Tiles/Drisnya/RadioStation01.tile", 5 ), size = 1, offset = 0, rotation = 3, flippable = true},
	}
end

----------------------------------------------------------------------------------------------------
-- Getters
----------------------------------------------------------------------------------------------------

function getDesertTileId( variationNoise )
	local tileCount = #g_desert

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_desert[variationNoise % tileCount + 1]
end

function getRoadTileIdAndRotation( variationNoise )
	local tiles = nil

	if sm.noise.randomRange(0, 100) <= g_road_obstacles.chance then
		tiles = g_road_obstacles.tiles
	else
		tiles = g_roads.tiles
	end

	local tileCount = #tiles

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	local rotation = g_roads.rotation

	return tiles[variationNoise % tileCount + 1], rotation
end

function getRoadRTileIdAndRotation( variationNoise )
	local tiles = g_roads_r.tiles

	local tileCount = #tiles

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	local rotation = g_roads_r.rotation

	return tiles[variationNoise % tileCount + 1], rotation
end

function getRoadLTileIdAndRotation( variationNoise )
	local tiles = g_roads_l.tiles

	local tileCount = #tiles

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	local rotation = g_roads_l.rotation

	return tiles[variationNoise % tileCount + 1], rotation
end

function getFenceTileId( variationNoise )
	local tileCount = #g_fences

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_fences[variationNoise % tileCount + 1]
end

function getRoadPoi( variationNoise )
	local tileCount = #g_road_pois

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_road_pois[variationNoise % tileCount + 1]
end

function getStarterConnector( variationNoise )
	local tileCount = #g_starter_connectors

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_starter_connectors[variationNoise % tileCount + 1]
end

function getFenceCornerTileId( variationNoise )
	local tileCount = #g_fence_corners

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_fence_corners[variationNoise % tileCount + 1]
end

function getScorchedTileId( variationNoise )
	local tileCount = #g_scorched

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_scorched[variationNoise % tileCount + 1]
end

function getRoadEndTileId( variationNoise )
	local tileCount = #g_road_ends

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_road_ends[variationNoise % tileCount + 1]
end

function getElevatorTileId( variationNoise )
	local tileCount = #g_elevators

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_elevators[variationNoise % tileCount + 1]
end

function getHouseTileID( variationNoise )
	local tileCount = #g_starter_houses

	if tileCount == 0 then
		return ERROR_TILE_UUID, 0
	end

	return g_starter_houses[variationNoise % tileCount + 1]
end
