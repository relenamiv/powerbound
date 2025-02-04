extends Node

signal level_won
signal level_lost

var level_state : LevelState

@onready var players = get_tree().get_nodes_in_group("players")

@export var player_starting_coords: Array[Vector2] = [
	Vector2(0,0),
	Vector2(16,8),
	Vector2(32,16),
	Vector2(48,24)
]

func _on_lose_button_pressed():
	level_lost.emit()

func _on_win_button_pressed():
	level_won.emit()

func _ready():
	_assign_player_starting_coords()

func _assign_player_starting_coords():
	for player in players:
		player.move_to_starting_position(player_starting_coords)
			
