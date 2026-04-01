class_name AnotherSceneInstance
extends SceneInstance


func _on_create_autosave_button_pressed() -> void:
	SaveManager.save_game_data(SaveManager.current_game_data, 5)


func _on_play_bgm_1_button_pressed() -> void:
	AudioManager.play_audio("bgm_1", 2.5)


func _on_play_bgm_2_button_pressed() -> void:
	AudioManager.play_audio("bgm_2", 2.5)
