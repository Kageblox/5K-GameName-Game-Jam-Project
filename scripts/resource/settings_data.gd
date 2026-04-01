class_name SettingsDataResource
extends Resource

@export_group("Sound")
@export var background_music_volume : float = 0.5
@export var sound_effects_volume : float = 0.5

func _init(
	_background_music_volume : float = 0.5,
	_sound_effects_volume : float = 0.5
) -> void:
	background_music_volume = _background_music_volume
	sound_effects_volume = _sound_effects_volume
