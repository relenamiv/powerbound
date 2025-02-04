extends Control

var hovered_tile: Vector2 = Vector2(-1, -1) # (-1, -1) is an invalid tile
var tile_size: Vector2
var grid_length: int

@onready var grid = get_parent().get_node("SelectableGrid")

func _ready() -> void:
	if grid != null:
		tile_size = grid.tile_size * grid.scale
		grid_length = grid.tile_size.x
	else:
		printerr("[GridHighlighter] Error: Couldn't find SelectableGrid in scene!")


func _process(delta: float) -> void:
	var world_mouse_pos = grid.get_global_mouse_position()
	var tile_world_pos = grid.local_to_map(grid.to_local(world_mouse_pos))
	var tile_coords = grid.map_to_local(tile_world_pos)
	if grid.active and grid.is_valid_tile(tile_coords):
		if tile_coords != hovered_tile:
			hovered_tile = tile_coords
			queue_redraw()
	else:
		if hovered_tile != Vector2(-1, -1):
			hovered_tile = Vector2(-1, -1)
			queue_redraw()

func _draw():
	if hovered_tile != Vector2(-1, -1):
		var tile_offset = Vector2(tile_size.x / grid_length, tile_size.y / grid_length)
		var starting_coord = hovered_tile * grid_length / (grid.scale * 2) - tile_offset
		# Parallelogram vertices
		var p1 = starting_coord + Vector2(0, -tile_size.y / 2)
		var p2 = starting_coord + Vector2(tile_size.x / 2, 0)
		var p3 = starting_coord + Vector2(0, tile_size.y / 2)
		var p4 = starting_coord + Vector2(-tile_size.x / 2, 0)
		draw_polygon([p1, p2, p3, p4], [Color(1, 1, 1, 0.5)])  # Semi-transparent white
