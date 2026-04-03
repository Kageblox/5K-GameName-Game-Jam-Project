class_name MainMenuSceneInstance
extends SceneInstance

func _scene_entry() -> void:
	AudioManager.play_audio("bgm_1", 1.0)
	super()
	
func _scene_exit() -> void:
	AudioManager.stop_bus_players("Background Music", 1.0)
	super()

func _on_start_new_game_button_pressed() -> void:
	#SceneManager.goto_scene("res://scenes/another_scene.tscn")
	MenuManager.open_save_slots_menu(SaveSlotsMenu.SaveSlotMenuVariant.NEW_GAME)

func _on_load_game_button_pressed() -> void:
	MenuManager.open_save_slots_menu(SaveSlotsMenu.SaveSlotMenuVariant.LOAD_GAME)
	
func _on_settings_button_pressed() -> void:
	MenuManager.open_settings_menu()

func _on_costume_room_button_pressed() -> void:
	MenuManager.open_costume_room_menu()

func _on_single_player_button_pressed() -> void:
	SceneManager.goto_scene("res://scenes/another_scene.tscn")
