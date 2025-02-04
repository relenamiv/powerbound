extends Node

signal level_won
signal level_lost

var level_state : LevelState

func _on_lose_button_pressed():
	level_lost.emit()

func _on_win_button_pressed():
	level_won.emit()

func _ready():
	pass
	#level_state = GameState.get_level_state(scene_file_path)
	#%ColorPickerButton.color = level_state.color
	#%BackgroundColor.color = level_state.color
