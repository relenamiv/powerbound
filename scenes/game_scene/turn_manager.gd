extends Node

enum TurnState { IDLE, SELECTING_ACTION, EXECUTING }
var turn_state: int = TurnState.IDLE

var current_index: int = 0
var players: Array[Player]
var current_player: Player

@export var enemy: Node2D
var enemy_turn: bool = false

@onready var grid = get_node("/GameContainer/SelectableGrid")

signal update_status_message(message: String)

signal player_turn_started(id: int)
signal enemy_turn_started()

signal all_players_down()
signal enemy_down()

func _ready():
	if enemy == null:
		printerr("[Turn Manager] Error: Enemy scene not assigned!")

func start_combat(players):
	self.players = players
	_next_turn()
	
func _next_turn():
	if current_player:
		current_player.deactivate()
	
	if enemy_turn:
		_execute_enemy_turn()
	else:
		current_player = players[current_index]
		current_player.activate()
		turn_state = TurnState.SELECTING_ACTION
		player_turn_started.emit(current_player.id)

func _end_turn():
	turn_state = TurnState.IDLE
	
	if enemy.is_down():
		enemy_down.emit()
		return
		
	if enemy_turn:
		current_index = 0
		enemy_turn = false
	else:
		current_index += 1
		
	_search_for_next_available_player()
	if current_index >= 4:
		all_players_down.emit()
		return
	if current_index == players.size():
		enemy_turn = true
	
	_next_turn()

func _search_for_next_available_player():
	while current_index < players.size() and players[current_index].is_downed():
		current_index += 1

func _execute_enemy_turn():
	turn_state = TurnState.EXECUTING
	enemy_turn_started.emit()
	
func on_enemy_timeout():
	_end_turn()
	
func _on_player_action(action_type: String, action_name: String):
	if enemy_turn or turn_state != TurnState.SELECTING_ACTION:
		print("[TurnManager] Enemy turn or action already selected.")
		return
	
	match action_type:
		"Attack":
			_execute_attack(action_name)
		"Move":
			_execute_movement()
		_:
			print("[TurnManager] Unknown action selected.")

func _execute_attack(move_name: String):
	print("[TurnManager] Executing attack: ", move_name)
	turn_state = TurnState.EXECUTING
	if current_player.use_move(move_name):
		%AttackTimer.start()

func on_attack_timeout():
	_end_turn()
	
func _execute_movement():
	print("[TurnManager] Executing movement.")
	turn_state = TurnState.EXECUTING
	current_player.start_tile_selection()
	
func _on_player_moved():
	_end_turn()
