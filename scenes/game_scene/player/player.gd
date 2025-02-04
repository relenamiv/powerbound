class_name Player
extends Node2D

enum PlayerState {
	IDLE, # Can use a move if active
	SELECTING_TILE,
	SELECTING_PLAYER,
	DOWN
}
var player_state: PlayerState = PlayerState.IDLE
var active: bool = false

var _energy: int
var max_energy: int
var moveset: Array[String]
var passive: String

var tile_coords: Vector2i = Vector2i(-1, -1)

var incoming_heal: int = 0

@onready var grid = get_parent().get_node("SelectableGrid")

signal energy_changed(_energy: int, max_energy: int)
signal update_status_message(message: String)

func _ready() -> void:
	_load_player_data()
	
	%AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

func _load_player_data():
	var player_data = PlayerData.players[name]
	max_energy = player_data["energy"]
	_energy = max_energy # Set current health
	moveset = player_data["moveset"]
	if player_data.has("passive"):
		passive = player_data["passive"]

func _on_animation_finished():
	if %AnimatedSprite2D.animation == "die":
		hide()
	else:
		%AnimatedSprite2D.play("idle")
	
func _set_energy(value: int):
	_energy = clamp(value, 0, max_energy)
	energy_changed.emit(_energy, max_energy)
	if _energy <= 0:
		_handle_death()
	
func _handle_death():
	player_state = PlayerState.DOWN
	# grid.vacate_tile(tile_coords)
	
	%AnimatedSprite2D.play_animation("die")
	
func take_damage(power: int):
	var voltage = grid.get_voltage(tile_coords)
	var amount = power * voltage
	_set_energy(_energy - amount)
	
	%AnimatedSprite2D.play_animation("hurt")
	
func activate():
	if active:
		print("[Player] Warning: %s is already active!" % name)
	active = true
		
func deactivate():
	if not active:
		print("[Player] Warning: %s is already inactive!" % name)
	active = false
	
# return: True if the move was successfully used; false otherwise
func use_move(move_name: String) -> bool:
	if player_state != PlayerState.IDLE or !active:
		printerr("[Player] Error: Player %s cannot use a move." % name)
		return false
		
	var move_data = PlayerData.player_movelist[move_name]
	var cost = move_data["cost"]
	if _energy < cost:
		update_status_message.emit("Insufficient energy! Please select another move ...")
		return false
	var power = move_data["power"]
	var target_type = move_data["target_type"]
	
	var voltage = grid.get_voltage(tile_coords)
	var amount = power * voltage
	
	var message = "%s used %s! " % [name, move_name]
	match target_type:
		"player":
			player_state = PlayerState.SELECTING_PLAYER
			incoming_heal = amount
			#grid.enable_interaction() # Make tiles selectable
			message += "Select the player's tile to heal ..."
		"players":
			for p in get_tree().get_nodes_in_group("Player"):
				p.heal(amount)
			message += "Restored everyone with %d energy!" % amount
		"enemy":
			var enemy = get_tree().get_first_node_in_group("Enemy")
			power *= _get_move_multiplier(move_name, voltage)
			enemy.take_damage(power, voltage)
		_:
			printerr("[Player] ERROR: Unknown target type")
			return false
			
	if move_data.has("status_message"):
		message += move_data["status_message"]
	update_status_message.emit(message)
	
	_set_energy(_energy - cost)
	return true

# Move multipliers are conditional (generally based on voltage)
func _get_move_multiplier(move_name: String, voltage: int) -> int:
	match move_name:
		"Conductive Strike":
			if voltage == 4:
				return 2
		_:
			pass
	return 1
	
func heal(amount: int):
	_set_energy(_energy + amount)
	
func on_tile_selected(tile_coords: Vector2i):
	if !active:
		return
		
	match player_state:
		PlayerState.SELECTING_TILE:
			if _move_to_tile(tile_coords):
				player_state = PlayerState.IDLE
				#grid.disable_selection()
		PlayerState.SELECTING_PLAYER:
			if grid.is_tile_occupied(tile_coords):
				var target_player = grid.occupied_tiles[tile_coords]
				target_player.heal(incoming_heal)
				incoming_heal = 0
				update_status_message.emit("")
				player_state = PlayerState.IDLE
		_:
			pass

# return: True if player moves to a previously unoccupied tile; false otherwise
func _move_to_tile(tile_coords: Vector2i) -> bool:	
	if PlayerState.SELECTING_TILE and tile_coords != self.tile_coords:
		if tile_coords != null and self.tile_coords != null:
			grid.vacate_tile(self.tile_coords)
		grid.occupy_tile(tile_coords, self)
		self.tile_coords = tile_coords
		# TODO: Change position
		return true
		
	return false
