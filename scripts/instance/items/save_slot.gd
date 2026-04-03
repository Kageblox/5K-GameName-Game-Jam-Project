class_name SaveSlotInstance
extends Control

@export var save_slot_button: CustomLabelButton
@export var loaded: Control
@export var empty: Control
@export var delete_button: CustomTextureButton

@export var last_saved_label: Label

func _enter_tree() -> void:
	focus_entered.connect(save_slot_button.grab_focus)

func load_slot(index: int) -> void:
	var loaded_game_data = SaveManager.load_game_data(index)
	if loaded_game_data == null:
		empty.visible = true
		loaded.visible = false
	else:
		empty.visible = false
		loaded.visible = true
		
		var last_saved = loaded_game_data.last_saved
		
		last_saved_label.text = (
			add_zero_if_single_digit(last_saved["day"]) +
			"/" +
			add_zero_if_single_digit(last_saved["month"]) +
			"/" +
			str(last_saved["year"] - 2000) +
			"\n" +
			add_zero_if_single_digit(last_saved["hour"]) +
			":" +
			add_zero_if_single_digit(last_saved["minute"]) +
			":" +
			add_zero_if_single_digit(last_saved["second"])
		)

static func add_zero_if_single_digit(number: int) -> String:
	return str(number) if number > 9 else "0" + str(number)
