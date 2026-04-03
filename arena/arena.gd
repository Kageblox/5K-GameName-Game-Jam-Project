extends Node3D

@onready var ballpit: Node3D = $Ballpit

var ball_scene = preload("res://arena/ball.tscn")

var ball_colors: Array[Color] = [
	Color("#ee3344"),
	Color("#33bb55"),
	Color("#3366ee"),
	Color("#eecc22"),
	Color("#ee44aa"),
	Color("#22cccc"),
	Color("#ee7722"),
	Color("#9944dd"),
	Color("#88dd33"),
	Color("#3399ee"),
]

var colored_materials: Dictionary = {}

# spawn balls to fill pit
func _ready():
	var _drop_height: float = 0.1
	var _layers: int = 10
	var _rang: int = 50
	var ball_count: int = 1000

	for i in range(_layers):
		var final: bool = (i == _layers - 1)
		var balls = spawn_balls(_rang, ball_count, i * _drop_height)

		if not final:
			var balls_timer = Timer.new()
			balls_timer.wait_time = 0.1
			balls_timer.one_shot = true
			balls_timer.timeout.connect(freeze_balls.bind(balls))
			add_child(balls_timer)
			balls_timer.start()

		var layer_timer = Timer.new()
		layer_timer.wait_time = 0.3
		layer_timer.one_shot = true
		add_child(layer_timer)
		layer_timer.start()
		await layer_timer.timeout

func spawn_balls(rang: int = 15, count: int = 100, height: float = 1.0) -> Array[RigidBody3D]:
	var balls : Array[RigidBody3D] = []
	
	for color in ball_colors:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.metallic = 0.0
		mat.metallic_specular = 0.8
		mat.roughness = 0.15
		colored_materials[color] = mat

	for i in range(count):
		var ball = ball_scene.instantiate()
		ball.position = Vector3(randf_range(-rang, rang), randf_range(height - 1.0, height + 1.0), randf_range(-rang, rang))
		var mat = colored_materials[ball_colors.pick_random()]
		ball.get_node("MeshInstance3D").material_override = mat
		ballpit.add_child(ball)
		balls.append(ball)

	return balls

func freeze_balls(balls: Array[RigidBody3D]) -> void:
	for ball in balls:
		ball.set_physics_process(false)
		#ball.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		ball.freeze = true
