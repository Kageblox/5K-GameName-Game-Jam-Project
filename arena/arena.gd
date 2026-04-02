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
	var _layers: int = 6
	var _rang: int = 25
	var ball_count: int = 1000

	for i in range(_layers):
		var final: bool = (i == _layers - 1)
		spawn_balls(_rang, ball_count, i * _drop_height, final)

		var timer = Timer.new()
		timer.wait_time = 0.3
		timer.one_shot = true
		add_child(timer)
		timer.start()
		await timer.timeout

func spawn_balls(rang: int = 15, count: int = 100, height: float = 1.0, final: bool = false):
	for color in ball_colors:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		colored_materials[color] = mat

	for i in range(count):
		var ball = ball_scene.instantiate()
		ball.position = Vector3(randf_range(-rang, rang), randf_range(height - 1.0, height + 1.0), randf_range(-rang, rang))
		var mat = colored_materials[ball_colors.pick_random()]
		ball.get_node("MeshInstance3D").material_override = mat
		ballpit.add_child(ball)

		if not final:
			var timer = Timer.new()
			timer.wait_time = 0.1
			timer.one_shot = true
			timer.timeout.connect(freeze_ball.bind(ball))
			add_child(timer)
			timer.start()


func freeze_ball(ball: RigidBody3D):
	ball.set_physics_process(false)
	#ball.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	ball.freeze = true
