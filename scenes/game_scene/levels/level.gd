extends Node

signal level_won
signal level_lost

var level_state : LevelState

@onready var player_nodes = get_tree().get_nodes_in_group("players")
@onready var turn_manager = get_node("TurnManager")

@export var player_starting_coords: Array[Vector2] = [
	Vector2(0,0),
	Vector2(16,8),
	Vector2(32,16),
	Vector2(48,24)
]

func temp_move():
	turn_manager.on_player_action("Move", "")
	
func temp_attack():
	turn_manager.on_player_action("Attack", "Static Zap")

func _on_win_button_pressed():
	level_won.emit()

func _level_lost():
	level_lost.emit()
	
func _ready():
	if player_nodes == null || turn_manager == null:
		printerr("[Level] Error: Players or TurnManager not found")
		return
		
	SignalUtil.try_connect_signal(turn_manager, "all_players_down", Callable(self, "_level_lost"))
	
	var players = _load_players()
	if players:
		turn_manager.start_combat(players)
	
func _load_players() -> Array[Player]:
	var players: Array[Player]
	for i in range(player_nodes.size()):
		if player_nodes[i] is Player:
			players.append(player_nodes[i] as Player)
			players[i].init_starting_position(player_starting_coords[i])
	return players
