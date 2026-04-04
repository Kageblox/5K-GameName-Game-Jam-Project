class_name SettingsMenu
extends MenuInstance

@export var background_music_slider: Slider
@export var sound_effects_slider: Slider
@export var apply_modified_button: CustomLabelButton

var modified_settings: SettingsDataResource

func open(_params: Array[Variant] = [])-> void:
	background_music_slider.set_value_no_signal(AudioManager.background_music_volume)
	sound_effects_slider.set_value_no_signal(AudioManager.sound_effects_volume)
	
	modified_settings = SettingsDataResource.new(
		AudioManager.background_music_volume,
		AudioManager.sound_effects_volume,
	)
	
	apply_modified_button.visible = false
	super()

func _on_apply_modified_button_pressed() -> void:
	MenuManager.open_question_menu(
		"Apply Modified Settings?",
		{
			"Yes":
				func():
					SaveManager.apply_new_settings(modified_settings)
					apply_modified_button.visible = false,
			"No":
				func():
					pass,
		}
	)

func _on_restore_default_button_pressed() -> void:
	MenuManager.open_question_menu(
		"Restore Default Settings?",
		{
			"Yes":
				func():
					SaveManager.restore_default_settings()
					background_music_slider.set_value_no_signal(AudioManager.background_music_volume)
					sound_effects_slider.set_value_no_signal(AudioManager.sound_effects_volume)
					apply_modified_button.visible = false,
			"No":
				func():
					pass,
		}
	)

func _on_return_button_pressed() -> void:
	if apply_modified_button.visible:
		MenuManager.open_question_menu(
			"Apply Modified Settings before returning?",
			{
				"Yes":
					func():
						SaveManager.apply_new_settings(modified_settings)
						close(),
				"No":
					func():
						close(),
			}
		)
	else:
		close()


func _on_background_volume_slider_value_changed(value: float) -> void:
	apply_modified_button.visible = true
	modified_settings.background_music_volume = value

func _on_sound_effects_volume_slider_value_changed(value: float) -> void:
	apply_modified_button.visible = true
	modified_settings.sound_effects_volume = value
