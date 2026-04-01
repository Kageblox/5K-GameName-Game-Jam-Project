class_name GameDataResource
extends Resource

@export var save_slot: int = -1
@export var last_saved: Dictionary = {}

func _init(
	_save_slot: int = -1,
	_last_saved: Dictionary = Time.get_datetime_dict_from_system(),
) -> void:
	save_slot = _save_slot
	last_saved = _last_saved
