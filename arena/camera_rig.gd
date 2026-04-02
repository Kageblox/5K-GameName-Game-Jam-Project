extends CharacterBody3D

@export var move_speed: float = 8.0
@export var acceleration: float = 30.0
@export var rotation_speed: float = 20.0

@onready var visuals: Node3D = $PlayerModel
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm3D
@onready var player_model: Node3D = $PlayerModel

var last_aim_direction: Vector3 = Vector3(0, 0, -1)

func _physics_process(delta: float) -> void:
	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_direction := Vector3(move_input.x, 0, move_input.y).normalized()
	
	if move_direction != Vector3.ZERO:
		velocity.x = move_direction.x * move_speed
		velocity.z = move_direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)
	
	move_and_slide()
	
	var aim_input := Input.get_vector("aim_left", "aim_right", "aim_forward", "aim_backward")
	var aim_direction := Vector3(aim_input.x, 0, -aim_input.y).normalized()
	
	if aim_direction != Vector3.ZERO:
		last_aim_direction = aim_direction
	else:
		aim_direction = last_aim_direction
	
	if aim_direction != Vector3.ZERO:
		var target_angle = atan2(-aim_direction.x, aim_direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, rotation_speed * delta)
