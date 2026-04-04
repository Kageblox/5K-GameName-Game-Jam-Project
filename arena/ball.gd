extends RigidBody3D

@export var lifetime: float = 0.0

var timer: float = 0.0

func _process(delta: float) -> void:
	if lifetime <= 0.0:
		return
	timer += delta
	if timer >= lifetime:
		queue_free()
