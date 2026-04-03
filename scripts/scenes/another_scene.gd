class_name AnotherSceneInstance
extends SceneInstance

@export var inactive_effect : AudioEffect
@export var active_effect : AudioEffect

func _scene_entry() -> void:
	AudioManager.play_audio("bgm_2", 1.0)
	super()

func _scene_exit() -> void:
	AudioManager.stop_bus_players("Background Music", 1.0)
	super()


func _on_create_autosave_button_pressed() -> void:
	SaveManager.save_game_data(SaveManager.current_game_data, 5)


func _on_play_bgm_1_button_pressed() -> void:
	AudioManager.stop_bus_players("Background Music", 1.0)
	AudioManager.play_audio("bgm_1", 1.0)


func _on_play_bgm_2_button_pressed() -> void:
	AudioManager.stop_bus_players("Background Music", 1.0)
	AudioManager.play_audio("bgm_2", 1.0)


func _on_stop_bgm_button_pressed() -> void:
	AudioManager.stop_bus_players("Background Music", 1.0)

func _on_add_audio_effect_button_pressed() -> void:
	AudioManager.add_bus_effect(
		"Background Music", 
		active_effect,
		inactive_effect,
		1.0,
		"Low Pass")

func _on_remove_audio_effect_button_pressed() -> void:
	AudioManager.remove_bus_effect_from_name("Background Music", "Low Pass", 1.0)
