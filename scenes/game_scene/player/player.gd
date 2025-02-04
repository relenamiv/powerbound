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

var energy: int
var max_energy: int
var moveset: Array
var passive: String

var tile_coords: Vector2 = Vector2(-1, -1)

var incoming_heal: int = 0

@onready var grid = get_node("../../SelectableGrid")
@onready var id = get_index() 

signal energy_changed(energy: int, max_energy: int)
signal moved_tile(id: int)
signal player_downed(id: int)
signal update_status_message(message: String)

func _ready() -> void:
	_load_player_data()
	
	if grid != null:
		SignalUtil.try_connect_signal(grid, "tile_selected", Callable(self, "on_tile_selected"))
	
	%AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	%AnimatedSprite2D.play("idle")

func _load_player_data():
	var player_data = PlayerData.players[name]
	max_energy = player_data["energy"]
	energy = max_energy # Set current health
	moveset = player_data["moveset"]
	if player_data.has("passive"):
		passive = player_data["passive"]

func init_starting_position(starting_coord: Vector2):
	player_state = PlayerState.SELECTING_TILE
	if not _move_to_tile(starting_coord):
		printerr("[Player] ERROR: %s did not move to starting position %s" % [name, starting_coord])
	player_state = PlayerState.IDLE

func _on_animation_finished():
	if %AnimatedSprite2D.animation == "die":
		hide()
	else:
		%AnimatedSprite2D.play("idle")
	
func _set_energy(value: int):
	energy = clamp(value, 0, max_energy)
	energy_changed.emit(energy, max_energy)
	if energy <= 0:
		_handle_death()
	
func _handle_death():
	player_state = PlayerState.DOWN
	grid.vacate_tile(tile_coords)
	player_downed.emit(id)
	%AnimatedSprite2D.play("die")
	
func is_down():
	return player_state == PlayerState.DOWN
	
func take_damage(power: int):
	var voltage = grid.get_voltage(tile_coords)
	var amount = power * voltage
	_set_energy(energy - amount)
	
	if player_state != PlayerState.DOWN:
		%AnimatedSprite2D.play("hurt")
	
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
	if energy < cost:
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
			if enemy == null:
				printerr("[Player] Enemy not found in scene! Cannot use attack.")
				return false
			power *= _get_move_multiplier(move_name, voltage)
			enemy.take_damage(power, voltage)
		_:
			printerr("[Player] ERROR: Unknown target type")
			return false
			
	if move_data.has("status_message"):
		message += move_data["status_message"]
	update_status_message.emit(message)
	
	_set_energy(energy - cost)
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
	_set_energy(energy + amount)
	
func on_tile_selected(tile_coords: Vector2):
	if !active:
		return
		
	match player_state:
		PlayerState.SELECTING_TILE:
			if _move_to_tile(tile_coords):
				player_state = PlayerState.IDLE
				grid.disable_selection()
		PlayerState.SELECTING_PLAYER:
			if grid.is_tile_occupied(tile_coords):
				var target_player = grid.occupied_tiles[tile_coords]
				target_player.heal(incoming_heal)
				incoming_heal = 0
				update_status_message.emit("")
				player_state = PlayerState.IDLE
		_:
			pass

# return: True if player moves to a new, previously unoccupied tile; false otherwise
func _move_to_tile(tile_coords: Vector2) -> bool:	
	if PlayerState.SELECTING_TILE and tile_coords != self.tile_coords:
		if tile_coords != null and self.tile_coords != null:
			grid.vacate_tile(self.tile_coords)
		if grid.occupy_tile(tile_coords, self):
			self.tile_coords = tile_coords
			var adjusted_position = tile_coords * grid.scale
			position = adjusted_position
			moved_tile.emit(id)
			return true
		
	return false

func start_tile_selection():
	if active:
		player_state = PlayerState.SELECTING_TILE
		grid.enable_selection()
