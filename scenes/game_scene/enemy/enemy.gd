extends Node2D

enum EnemyState {
	IDLE,
	DOWN
}
var enemy_state: EnemyState = EnemyState.IDLE

var moveset
var max_energy: int
var energy: int

var is_defend: bool = false

var potential_actions = ["Defend", "Attack", "Heal"]

signal energy_changed(energy: int, max_energy: int)
signal enemy_downed()
signal update_status_message(message: String)

func _ready() -> void:
	_load_enemy_data()
	
	%AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	%AnimatedSprite2D.play("idle")

func _load_enemy_data():
	var enemy_data = EnemyData.units[name]
	max_energy = enemy_data["energy"]
	energy = max_energy
	moveset = enemy_data["moveset"]
	
func _on_animation_finished():
	pass
	
func _set_energy(value: int):
	energy = clamp(value, 0, max_energy)
	energy_changed.emit(energy, max_energy)
	if energy <= 0:
		_handle_death()
		
func _handle_death():
	enemy_state = EnemyState.DOWN
	enemy_downed.emit()
	
func take_damage(power: int, voltage: int):
	if is_defend:
		pass
	var amount = power * voltage
	_set_energy(energy - amount)
	
func select_action():
	is_defend = false
	
	var mid_health_threshold = 0.75 * max_energy
	var low_health_threshold = 0.25 * max_energy
	var is_valid_to_heal = bool(energy < mid_health_threshold)
	
	#   If the health is low, add healing as a valid action
	var valid_actions = \
		potential_actions.slice(0, potential_actions.size() - 2) if is_valid_to_heal \
		else potential_actions.slice(0, potential_actions.size() - 1)
		
	#	Set up the probabilities for all valid actions
	var probability = randi_range(1, 100)
	if not is_valid_to_heal:
		if probability < 50:
#			Defend
			action_defend()
		else:
#			Attack
			action_attack()
	elif energy < low_health_threshold:
#		Increased chance of healing
		if probability < 25:
#			Defend
			action_defend()
		elif probability < 50:
#			Attack
			action_attack()
		else:
#			Heal
			action_heal()
	elif energy < mid_health_threshold:
		if probability < 33:
#			Defend
			action_defend()
		elif probability < 67:
#			Attack
			action_attack()
		else:
#			Heal
			action_heal()

func action_attack():
	var attack_moves = moveset["Attack"]
	var random_index = randi_range(1, attack_moves.size())
	var move_name = attack_moves.keys()[random_index]
	var move = attack_moves[move_name]
	var cost = move["cost"]
	var power = move["power"]
	var target_type = move["target_type"]
	
	var players = get_tree().get_nodes_in_group("Player")
	if players == null:
		printerr("")
		return
		
	var message = "Enemy used %s!" % move_name
	
	match target_type:
		"player":
			# Find random target
			random_index = randi_range(1, players.size())
			var p = players[random_index]
			p.take_damage(power)
		"players":
			for p in players:
				p.take_damage(power)
		_:
			printerr("")
			return
	
	# Expend energy
	_set_energy(energy - cost)
	update_status_message.emit(message)
	
func action_heal():
	var heal_moves = moveset["Heal"]
	var random_index = randi_range(1, heal_moves.size())
	var move_name = heal_moves.keys()[random_index]
	var move = heal_moves[move_name]
	var cost = move["cost"]
	var power = move["power"]
	var target_type = move["target_type"]
	
	var players = get_tree().get_nodes_in_group("Player")
	if players == null:
		printerr("")
		return
		
	var message = "Enemy used %s!" % move_name
	
	match target_type:
		"enemy":
			heal(power)
		"player":
			random_index = randi_range(1, players.size())
			var p = players[random_index]
			p.take_damage(power)
			#heal(power * voltage)
		_:
			printerr("")
			return
	
	_set_energy(energy - cost)
	update_status_message.emit(message)

func action_defend():
	var defend_moves = moveset["Defend"]
	var random_index = randi_range(1, defend_moves.size())
	var move_name = defend_moves.keys()[random_index]
	var move = defend_moves[move_name]
	var cost = move["cost"]
	var target_type = move["target_type"]
	
	var message = "Enemy used %s!" % move_name
	
	match target_type:
		"enemy":
			is_defend = true
		_:
			printerr("")
			return
	
	_set_energy(energy - cost)
	update_status_message.emit(message)

func heal(amount: int):
	_set_energy(energy + amount)
	
func is_down():
	return enemy_state == EnemyState.DOWN
