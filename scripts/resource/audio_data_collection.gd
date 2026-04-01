class_name AudioDataCollectionResource
extends Resource

@export var audio_data_collection : Dictionary[String, AudioDataResource] = {}

func _init(
	_audio_data_collection : Dictionary[String, AudioDataResource] = {}
) -> void:
	audio_data_collection = _audio_data_collection
