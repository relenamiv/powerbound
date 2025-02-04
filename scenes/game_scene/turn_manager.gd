extends Node

enum TurnState { IDLE, SELECTING_ACTION, EXECUTING }
var turn_state: int = TurnState.IDLE

var current_index: int = 0
var players: Array[Player]
var current_player: Player

@export var enemy: Node2D
var enemy_turn: bool = false

@onready var grid = get_parent().get_node("GameContainer/SelectableGrid")

signal update_status_message(message: String)

signal player_turn_started(id: int)
signal enemy_turn_started()

signal all_players_down()
signal enemy_down()

var num_players_down: int = 0
var num_player_turns_in_round: int = 0

func _ready():
	if grid == null:
		printerr("[Turn Manager] Error: Grid not found!")
		return
		
	if enemy == null:
		print("[Turn Manager] Warning: Enemy scene not assigned!")

func start_combat(players):
	self.players = players
	
	_connect_player_signals()
	
	_next_turn()
	
func _connect_player_signals():
	for player in players:
		SignalUtil.try_connect_signal(player, "moved_tile", Callable(self, "_on_player_moved"))
		SignalUtil.try_connect_signal(player, "player_downed", Callable(self, "_on_player_death"))
	
func _next_turn():
	if enemy_turn:
		_execute_enemy_turn()
	else:
		current_player = players[current_index]
		current_player.activate()
		turn_state = TurnState.SELECTING_ACTION
		player_turn_started.emit(current_player.id)

func _end_turn():	
	turn_state = TurnState.IDLE	
	
	# TODO: implement enemy class
	#if enemy.is_down():
		#enemy_down.emit()
		#return
		
	if players.size() - num_players_down == 0:
		all_players_down.emit()
		return
		
	if enemy_turn:
		enemy_turn = false
		num_player_turns_in_round = 0 # Start new round
		
		# Set next available player
		current_index = 0
		current_player = _get_next_available_player(current_index)
		if current_player == null:
			all_players_down.emit()
			return
		current_index = players.find(current_player)
	else:
		num_player_turns_in_round += 1 # Finished player round
		if num_player_turns_in_round == (players.size() - num_players_down): # Reached final valid turn in round; Start enemy turn
			enemy_turn = true
			if current_player:
				current_player.deactivate()
			current_index = -1
			current_player = null
		else:
			if current_player:
				current_player.deactivate()
			current_index += 1
			current_player = _get_next_available_player(current_index)
			if current_player == null:
				all_players_down.emit()
				return
			current_index = players.find(current_player)
			
	_next_turn()

func _get_next_available_player(start_index: int) -> Player:
	var index = start_index
	while index < players.size():
		var player = players[index]
		if player and not player.is_down():
			return player
		index += 1
	return null
	
func _on_player_death(id: int):
	# id unused, meant for UI
	num_players_down += 1

func _execute_enemy_turn():
	turn_state = TurnState.EXECUTING
	enemy_turn_started.emit()
	_kill_random_player()
	%EnemyTimer.start()
	
func on_enemy_timeout():
	_end_turn()
	
func on_player_action(action_type: String, action_name: String):
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
	else:
		turn_state = TurnState.SELECTING_ACTION

func on_attack_timeout():
	_end_turn()
	
func _execute_movement():
	print("[TurnManager] Executing movement.")
	turn_state = TurnState.EXECUTING
	current_player.start_tile_selection()
	
func _on_player_moved(id: int):
	if current_player.id == id:
		_end_turn()
		
# Testing
func _kill_random_player():
	if players.is_empty():
		print("[TurnManager] No players available!")
		return

	var available_players := []
	for player in players:
		if player and not player.is_down():
			available_players.append(player)
	
	if available_players.is_empty():
		print("[TurnManager] All players are down!")
		return
	
	var random_index = randi() % available_players.size()
	var random_player = available_players[random_index]
	print("[TurnManager] Killing %s" % random_player.name)
	random_player.take_damage(100)
