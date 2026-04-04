extends CharacterBody3D

@export var move_speed: float = 8.0
@export var acceleration: float = 30.0
@export var rotation_speed: float = 20.0
@export var bob_speed: float = 12.0
@export var bob_amount: float = 0.3
@export var shoot_speed: float = 40.0
@export var shoot_cooldown: float = 0.15
@export var crouch_height: float = -3.0
@export var crouch_speed: float = 10.0
@export var dash_speed: float = 30.0
@export var dash_duration: float = 0.5
@export var breath_max: float = 1.0
@export var breath_regen_rate: float = 0.5
@export var camera_offset: Vector3 = Vector3(0, 24, 14)
@export var use_mouse_aim: bool = true

@onready var player_model: Node3D = $PlayerModel
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera: Camera3D = $Camera3D

var last_aim_direction: Vector3 = Vector3(0, 0, -1)
var bob_timer: float = 0.0
var model_base_y: float
var shoot_timer: float = 0.0
var ball_scene = preload("res://arena/ball.tscn")
var crouching: bool = false
var dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO
var breath: float = 1.0
var crosshair: Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_create_crosshair()
	model_base_y = player_model.position.y
	breath = breath_max
	camera.position = camera_offset
	camera.look_at(global_position, Vector3.UP)
	# Put player model on visibility layer 2 (so snapshot camera can exclude it)
	_set_visibility_layer_recursive(player_model, 2)

func _create_crosshair() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	crosshair = CrosshairDraw.new()
	canvas.add_child(crosshair)

func _set_visibility_layer_recursive(node: Node, layer: int) -> void:
	if node is VisualInstance3D:
		node.layers = 1 << (layer - 1)
	for child in node.get_children():
		_set_visibility_layer_recursive(child, layer)

func _physics_process(delta: float) -> void:
	# Crouch (hold)
	crouching = Input.is_action_pressed("crouch")

	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_direction := Vector3(move_input.x, 0, move_input.y).normalized()

	# Dash
	if Input.is_action_just_pressed("dash") and not dashing and breath >= dash_duration:
		if move_direction != Vector3.ZERO:
			dashing = true
			dash_timer = dash_duration
			dash_direction = move_direction
			breath -= dash_duration

	if dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			dashing = false
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
	else:
		var speed = crouch_speed if crouching else move_speed
		if move_direction != Vector3.ZERO:
			velocity.x = move_direction.x * speed
			velocity.z = move_direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, acceleration * delta)
			velocity.z = move_toward(velocity.z, 0, acceleration * delta)

	move_and_slide()

	# Breath regen
	if not dashing:
		breath = min(breath + breath_regen_rate * delta, breath_max)

	# Crouch/dash height (visual only)
	var is_low = crouching or dashing
	var target_model_y = crouch_height if is_low else model_base_y
	player_model.position.y = move_toward(player_model.position.y, target_model_y, delta * 20.0)

	# Bob
	if not is_low and move_direction != Vector3.ZERO:
		bob_timer += delta * bob_speed
		player_model.position.y = target_model_y + abs(sin(bob_timer)) * bob_amount
	else:
		bob_timer = 0.0

	# Aim
	var aim_input := Input.get_vector("aim_left", "aim_right", "aim_forward", "aim_backward")
	var aim_direction := Vector3(aim_input.x, 0, -aim_input.y).normalized()

	if aim_direction != Vector3.ZERO:
		last_aim_direction = aim_direction
	elif use_mouse_aim:
		if camera:
			var mouse_pos = get_viewport().get_mouse_position()
			var from = camera.project_ray_origin(mouse_pos)
			var dir = camera.project_ray_normal(mouse_pos)
			if dir.y != 0:
				var t = (global_position.y - from.y) / dir.y
				var hit = from + dir * t
				var mouse_dir = hit - global_position
				mouse_dir.y = 0
				if mouse_dir.length() > 0.1:
					mouse_dir = mouse_dir.normalized()
					last_aim_direction = Vector3(mouse_dir.x, 0, -mouse_dir.z)
	elif move_direction != Vector3.ZERO:
		last_aim_direction = Vector3(move_direction.x, 0, -move_direction.z)

	var target_angle = atan2(-last_aim_direction.x, last_aim_direction.z)
	player_model.rotation.y = lerp_angle(player_model.rotation.y, target_angle, rotation_speed * delta)

	# Shoot (not while dashing)
	shoot_timer -= delta
	if not dashing and Input.is_action_pressed("shoot") and shoot_timer <= 0:
		shoot_timer = shoot_cooldown
		_shoot()

func _shoot() -> void:
	var shoot_dir = Vector3(last_aim_direction.x, 0, -last_aim_direction.z)
	var ball = ball_scene.instantiate()
	ball.position = global_position + Vector3(0, 5, 0) + shoot_dir * 3.0
	ball.freeze = false
	ball.lifetime = 3.0
	ball.collision_mask = 7
	get_parent().add_child(ball)
	ball.linear_velocity = shoot_dir * shoot_speed

class CrosshairDraw extends Control:
	var line_length := 28.0
	var gap := 12.0
	var thickness := 4.0
	var circle_radius := 24.0
	var color := Color.WHITE
	var outline_color := Color.BLACK

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(PRESET_FULL_RECT)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var center := get_viewport().get_mouse_position()
		# Circle
		draw_arc(center, circle_radius, 0, TAU, 64, outline_color, thickness + 2.0, true)
		draw_arc(center, circle_radius, 0, TAU, 64, color, thickness, true)
		# Crosshair lines
		for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			var from = center + dir * gap
			var to = center + dir * line_length
			draw_line(from, to, outline_color, thickness + 2.0, true)
			draw_line(from, to, color, thickness, true)
		# Center dot
		draw_circle(center, 2.0, color)
