extends TileMapLayer

@export var tile_source_id: int = 0
@export var default_atlas_coords: Vector2 = Vector2(0, 0)
@export var grid_dimensions: Vector2 = Vector2(4, 4)
@export var tile_size: Vector2 = Vector2(32, 16)

var valid_tiles: Array[Vector2]
var active: bool = false
var occupied_tiles: Dictionary = {} # Key: tile_coords (Vector2), Value: Player instance

signal tile_selected(tile_coords: Vector2)

func _ready() -> void:
	if not tile_set.has_source(tile_source_id):
		printerr("[SelectableGrid] Error: Invalid tile_source_id: ", tile_source_id)
		return
	
	_generate_grid(grid_dimensions.x, grid_dimensions.y)

func _generate_grid(width: int, length: int):
	clear()
	for x in range(width):
		for y in range(length):
			var iso_x = (x - y) * (tile_size.x / 2)
			var iso_y = (x + y) * (tile_size.y / 2)
			var iso_pos = local_to_map(Vector2(iso_x, iso_y))
			set_cell(iso_pos, tile_source_id, default_atlas_coords)

			var tile_coords = map_to_local(iso_pos)
			valid_tiles.append(_get_tile_pos(tile_coords))
			print(_get_tile_pos(tile_coords))
			
func _input(event):
	if active and event is InputEventMouseButton and event.pressed:
		var world_mouse_pos = get_global_mouse_position()
		var tile_world_pos = local_to_map(to_local(world_mouse_pos))
		var tile_coords = map_to_local(tile_world_pos)
		if (is_valid_tile(tile_coords)):
			tile_selected.emit(tile_coords)

func enable_selection():
	if active:
		print("[SelectableGrid] Warning: Grid is already enabled!")
	active = true

func disable_selection():
	if not active:
		print("[SelectableGrid] Warning: Grid is already disabled!")
	active = false

func _get_tile_pos(tile_coords: Vector2) -> Vector2:
	return Vector2(floor(tile_coords.x / tile_size.y), floor(tile_coords.y / tile_size.y))
	
# Checking validity based off relative position of tiles
func is_valid_tile(tile_coords: Vector2) -> bool:
	return _get_tile_pos(tile_coords) in valid_tiles
	
func get_voltage(tile_coords: Vector2) -> int:
	var tile_pos = _get_tile_pos(tile_coords)
	return tile_pos.y + 1 - int(floor(tile_pos.x / 2.0))

func _get_layer(tile_coords: Vector2) -> int:
	var tile_pos = _get_tile_pos(tile_coords)
	return tile_pos.y + 1 + int(floor(-tile_pos.x / 2.0))

func is_tile_occupied(tile_coords: Vector2) -> bool:
	return tile_coords in occupied_tiles

# return: True if the tile was filled; false if the tile is already occupied
func occupy_tile(tile_coords: Vector2, player) -> bool:
	if tile_coords in occupied_tiles:
		printerr("[SelectableGrid] Error: Tile %s is already occupied!" % str(tile_coords))
		return false
	occupied_tiles[tile_coords] = player
	player.z_index = _get_layer(tile_coords)
	return true

func vacate_tile(tile_coords: Vector2) -> void:
	occupied_tiles.erase(tile_coords)
