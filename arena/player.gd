extends CharacterBody3D

@export var move_speed: float = 8.0
@export var acceleration: float = 30.0
@export var rotation_speed: float = 20.0
@export var bob_speed: float = 12.0
@export var bob_amount: float = 0.3
@export var camera_height: float = 30.0
@export var camera_distance: float = 0.0
@export var camera_angle: float = -90.0

@onready var camera_rig: Node3D = $CameraRig
@onready var player_model: Node3D = $PlayerModel

var last_aim_direction: Vector3 = Vector3(0, 0, -1)
var bob_timer: float = 0.0
var model_base_y: float

func _ready() -> void:
	model_base_y = player_model.position.y
	_update_camera()

func _update_camera() -> void:
	camera_rig.position = Vector3(0, camera_height, camera_distance)
	camera_rig.rotation_degrees = Vector3(camera_angle, 0, 0)

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

	if move_direction != Vector3.ZERO:
		bob_timer += delta * bob_speed
		player_model.position.y = model_base_y + abs(sin(bob_timer)) * bob_amount
	else:
		bob_timer = 0.0
		player_model.position.y = move_toward(player_model.position.y, model_base_y, delta * 5.0)

	var aim_input := Input.get_vector("aim_left", "aim_right", "aim_forward", "aim_backward")
	var aim_direction := Vector3(aim_input.x, 0, -aim_input.y).normalized()

	if aim_direction != Vector3.ZERO:
		last_aim_direction = aim_direction
	elif move_direction != Vector3.ZERO:
		last_aim_direction = Vector3(move_direction.x, 0, -move_direction.z)

	var target_angle = atan2(-last_aim_direction.x, last_aim_direction.z)
	player_model.rotation.y = lerp_angle(player_model.rotation.y, target_angle, rotation_speed * delta)
