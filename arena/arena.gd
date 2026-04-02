extends Node3D

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
	spawn_balls()

func spawn_balls():
	# cache the ball with each color
	for color in ball_colors:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		colored_materials[color] = mat

	for i in range(2000):
		var ball = ball_scene.instantiate()
		var rang: int = 15
		ball.position = Vector3(randf_range(-rang, rang), randf_range(5, 15), randf_range(-rang, rang))
		var mat = colored_materials[ball_colors.pick_random()]
		ball.get_node("MeshInstance3D").material_override = mat
		add_child(ball)
		# await get_tree().process_frame
