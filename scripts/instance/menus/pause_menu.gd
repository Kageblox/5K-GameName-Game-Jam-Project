class_name PauseMenu
extends MenuInstance

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
