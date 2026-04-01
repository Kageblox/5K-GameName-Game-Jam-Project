@tool
class_name AudioDataResource
extends Resource

@export var stream: AudioStream
@export_range(-80, 24) var active_volume_db: float = 0.0
@export_range(-80, 24) var inactive_volume_db: float = -80.0
@export_range(0.01,4) var pitch_scale: float = 1.0
@export var bus: String = "Master"
