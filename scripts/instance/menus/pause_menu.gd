class_name PauseMenu
extends MenuInstance

@export_group("Background Music Audio Effects")
@export var background_music_active_effect_params : Array[AudioEffect]
@export var background_music_inactive_effect_params : Array[AudioEffect]

@export_group("Sound Effects Audio Effects")
@export var sound_effects_active_effect_params : Array[AudioEffect]
@export var sound_effects_inactive_effect_params : Array[AudioEffect]

func open(_params: Array[Variant] = [])-> void:
	for i in background_music_active_effect_params.size():
		AudioManager.add_bus_effect(
			"Background Music", 
			background_music_active_effect_params[i],
			background_music_inactive_effect_params[i],
			open_duration,
			"PauseMenu" + str(i)
			)
	for i in sound_effects_active_effect_params.size():
		AudioManager.add_bus_effect(
			"Sound Effects", 
			sound_effects_active_effect_params[i],
			sound_effects_inactive_effect_params[i],
			open_duration,
			"PauseMenu" + str(i)
			)
	super()

func close() -> void:
	for i in background_music_active_effect_params.size():
		AudioManager.remove_bus_effect_from_name(
			"Background Music", 
			"PauseMenu" + str(i),
			close_duration
			)
	for i in sound_effects_active_effect_params.size():
		AudioManager.remove_bus_effect_from_name(
			"Background Music", 
			"PauseMenu" + str(i),
			close_duration
			)
	super()

func _on_quick_save_button_pressed() -> void:
	var current_save_slot = SaveManager.current_game_data.save_slot

	if current_save_slot < 5:
		MenuManager.open_question_menu(
			"Overwrite Save Slot " + str(SaveManager.current_game_data.save_slot + 1) + "?",
			{
				"Yes":
					func():
						SaveManager.save_game_data(SaveManager.current_game_data, current_save_slot),
				"No":
					func():
						pass,
			}
		)
	else:
		MenuManager.open_save_slots_menu(SaveSlotsMenu.SaveSlotMenuVariant.SAVE_GAME)

func _on_save_game_button_pressed() -> void:
	MenuManager.open_save_slots_menu(SaveSlotsMenu.SaveSlotMenuVariant.SAVE_GAME)

func _on_load_game_button_pressed() -> void:
	MenuManager.open_save_slots_menu(SaveSlotsMenu.SaveSlotMenuVariant.LOAD_GAME)

func _on_settings_button_pressed() -> void:
	MenuManager.open_settings_menu()

func _on_return_to_main_menu_button_pressed() -> void:
	MenuManager.open_question_menu(
		"Quick Save before Returning to Main Menu?",
		{
			"Yes":
				func():
					var current_save_slot = SaveManager.current_game_data.save_slot
					
					if current_save_slot < 5:
						SaveManager.save_game_data(SaveManager.current_game_data, SaveManager.current_game_data.save_slot)
						SceneManager.goto_scene("res://scenes/main_menu_scene.tscn")
					else:
						MenuManager.open_save_slots_menu(SaveSlotsMenu.SaveSlotMenuVariant.SAVE_AUTOSAVE_BEFORE_RETURNING),
			"No":
				func():
					SceneManager.goto_scene("res://scenes/main_menu_scene.tscn"),
		}
	)

func _on_continue_game_button_pressed() -> void:
	close()
