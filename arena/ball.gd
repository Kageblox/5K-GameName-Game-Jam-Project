extends RigidBody3D

@export var lifetime: float = 0.0

var timer: float = 0.0

func _ready() -> void:
	if lifetime > 0.0:
		contact_monitor = true
		max_contacts_reported = 1
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if lifetime <= 0.0:
		return
	timer += delta
	if timer >= lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Remove bullet on wall impact (collision layer 2)
	if body is StaticBody3D and body.collision_layer & 2:
		queue_free()
