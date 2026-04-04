extends Node3D

@export var use_particle_rendering: bool = false
@export var white_balls: bool = true
@export var drop_height: float = 0.1
@export var layers: int = 4
@export var ball_count: int = 500
@export var arena_width: int = 50
@export var arena_height: int = 50
@export var depth_texture_size: int = 2048

@onready var ballpit: Node3D = $Ballpit
@onready var floor_mesh: MeshInstance3D = $Floor/MeshInstance3D

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
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var black_screen := ColorRect.new()
	black_screen.color = Color.BLACK
	black_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	var loading_label := Label.new()
	loading_label.text = "Loading..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_label.add_theme_font_size_override("font_size", 48)
	loading_label.add_theme_color_override("font_color", Color.WHITE)
	var canvas := CanvasLayer.new()
	canvas.layer = 99
	canvas.add_child(black_screen)
	canvas.add_child(loading_label)
	add_child(canvas)

	floor_mesh.mesh = floor_mesh.mesh.duplicate()
	floor_mesh.mesh.size = Vector3(arena_width, 20, arena_height)
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color.YELLOW
	floor_mat.emission_enabled = true
	floor_mat.emission = Color.YELLOW
	floor_mesh.material_override = floor_mat
	_create_walls()
	for i in range(layers):
		var final: bool = (i == layers - 1)
		var balls = spawn_balls(ball_count, i * drop_height, final)

		if not final:
			var balls_timer = Timer.new()
			balls_timer.wait_time = 1.0
			balls_timer.one_shot = true
			balls_timer.timeout.connect(bake_balls.bind(balls))
			add_child(balls_timer)
			balls_timer.start()

		var layer_timer = Timer.new()
		layer_timer.wait_time = 0.3
		layer_timer.one_shot = true
		add_child(layer_timer)
		layer_timer.start()
		await layer_timer.timeout

	canvas.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	## Top-down rasterizer (disabled)
	#var snap_timer = Timer.new()
	#snap_timer.wait_time = 1.0
	#snap_timer.one_shot = true
	#add_child(snap_timer)
	#snap_timer.start()
	#await snap_timer.timeout
	#_take_depth_snapshot()

#func _take_depth_snapshot() -> void:
	#var aspect = float(arena_width) / float(arena_height)
	#var tex_w = depth_texture_size if aspect >= 1.0 else int(depth_texture_size * aspect)
	#var tex_h = depth_texture_size if aspect <= 1.0 else int(depth_texture_size / aspect)
	#
	#var vp = SubViewport.new()
	#vp.size = Vector2i(tex_w, tex_h)
	#vp.transparent_bg = true
	#vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	#add_child(vp)
	#
	#var cam = Camera3D.new()
	#cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	#cam.size = arena_height
	#cam.position = Vector3(0, 50, 0)
	#cam.rotation_degrees = Vector3(-90, 0, 0)
	#cam.cull_mask = 1
	#cam.near = 0.1
	#cam.far = 200.0
	#vp.add_child(cam)
	#
	#await RenderingServer.frame_post_draw
	#
	#var img = vp.get_texture().get_image()
	#vp.queue_free()
	#
	#var tex = ImageTexture.create_from_image(img)
	#
	#var mat = StandardMaterial3D.new()
	#mat.albedo_texture = tex
	#mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	#floor_mesh.material_override = mat

func _create_walls() -> void:
	var wall_height: float = 10.0
	var wall_thickness: float = 2.0
	var half_w: float = arena_width / 2.0
	var half_h: float = arena_height / 2.0
	var y: float = wall_height / 2.0

	var walls = [
		{"pos": Vector3(0, y, -half_h - wall_thickness / 2.0), "size": Vector3(arena_width + wall_thickness * 2, wall_height, wall_thickness)},
		{"pos": Vector3(0, y, half_h + wall_thickness / 2.0), "size": Vector3(arena_width + wall_thickness * 2, wall_height, wall_thickness)},
		{"pos": Vector3(-half_w - wall_thickness / 2.0, y, 0), "size": Vector3(wall_thickness, wall_height, arena_height)},
		{"pos": Vector3(half_w + wall_thickness / 2.0, y, 0), "size": Vector3(wall_thickness, wall_height, arena_height)},
	]

	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color.BLUE
	wall_mat.emission_enabled = true
	wall_mat.emission = Color.BLUE

	for w in walls:
		var body = StaticBody3D.new()
		body.position = w["pos"]
		body.collision_layer = 2  # Environment
		body.collision_mask = 0

		var shape = BoxShape3D.new()
		shape.size = w["size"]
		var col = CollisionShape3D.new()
		col.shape = shape
		body.add_child(col)

		var mesh = BoxMesh.new()
		mesh.size = w["size"]
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = mesh
		mesh_inst.material_override = wall_mat
		body.add_child(mesh_inst)

		add_child(body)

func spawn_balls(count: int = 100, height: float = 1.0, is_final: bool = false) -> Array[RigidBody3D]:
	var balls : Array[RigidBody3D] = []

	for color in ball_colors:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.metallic = 0.0
		mat.metallic_specular = 0.8
		mat.roughness = 0.15
		colored_materials[color] = mat

	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color.WHITE
	white_mat.metallic = 0.0
	white_mat.metallic_specular = 0.8
	white_mat.roughness = 0.15

	for i in range(count):
		var ball = ball_scene.instantiate()
		ball.position = Vector3(randf_range(-arena_width / 2.0, arena_width / 2.0), randf_range(height - 1.0, height + 1.0), randf_range(-arena_height / 2.0, arena_height / 2.0))
		if white_balls and not is_final:
			ball.get_node("MeshInstance3D").material_override = white_mat
		else:
			var mat = colored_materials[ball_colors.pick_random()]
			ball.get_node("MeshInstance3D").material_override = mat
		ballpit.add_child(ball)
		balls.append(ball)

	return balls

func bake_balls(balls: Array[RigidBody3D]) -> void:
	if balls.is_empty():
		return

	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []

	for ball in balls:
		transforms.append(ball.global_transform)
		var ball_mat = ball.get_node("MeshInstance3D").material_override as StandardMaterial3D
		colors.append(ball_mat.albedo_color if ball_mat else Color.WHITE)

	if use_particle_rendering:
		_bake_as_particles(transforms, colors)
	else:
		_bake_as_multimesh(transforms, colors)

	# Single StaticBody3D for all collision
	var static_body = StaticBody3D.new()
	static_body.collision_layer = 8
	static_body.collision_mask = 15
	ballpit.add_child(static_body)

	var sphere_shape = SphereShape3D.new()
	for i in transforms.size():
		var col = CollisionShape3D.new()
		col.shape = sphere_shape
		col.global_transform = transforms[i]
		static_body.add_child(col)

	# Remove original balls
	for ball in balls:
		ball.queue_free()

func _bake_as_multimesh(transforms: Array[Transform3D], colors: Array[Color]) -> void:
	var mesh = SphereMesh.new()
	var mat = StandardMaterial3D.new()
	mat.metallic = 0.0
	mat.metallic_specular = 0.8
	mat.roughness = 0.15
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = transforms.size()

	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])

	var mm_instance = MultiMeshInstance3D.new()
	mm_instance.multimesh = mm
	mm_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ballpit.add_child(mm_instance)

func _bake_as_particles(transforms: Array[Transform3D], colors: Array[Color]) -> void:
	var count = transforms.size()

	# Encode positions into a float texture (RGBF: x, y, z)
	var pos_img = Image.create(count, 1, false, Image.FORMAT_RGBF)
	for i in count:
		var p = transforms[i].origin
		pos_img.set_pixel(i, 0, Color(p.x, p.y, p.z))
	var pos_tex = ImageTexture.create_from_image(pos_img)

	# Encode colors into an RGBA8 texture
	var col_img = Image.create(count, 1, false, Image.FORMAT_RGBA8)
	for i in count:
		col_img.set_pixel(i, 0, Color.WHITE if white_balls else colors[i])
	var col_tex = ImageTexture.create_from_image(col_img)

	var proc_mat = ParticleProcessMaterial.new()
	proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
	proc_mat.emission_point_count = count
	proc_mat.emission_point_texture = pos_tex
	proc_mat.emission_color_texture = col_tex
	proc_mat.direction = Vector3.ZERO
	proc_mat.spread = 0.0
	proc_mat.initial_velocity_min = 0.0
	proc_mat.initial_velocity_max = 0.0
	proc_mat.gravity = Vector3.ZERO

	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	var mat = StandardMaterial3D.new()
	mat.metallic = 0.0
	mat.metallic_specular = 0.8
	mat.roughness = 0.15
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat

	var particles = GPUParticles3D.new()
	particles.amount = count
	particles.lifetime = 1000.0
	particles.explosiveness = 1.0
	particles.fixed_fps = 0
	particles.process_material = proc_mat
	particles.draw_pass_1 = mesh
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Scale each particle to match ball size (1.5)
	proc_mat.scale_min = 1.5
	proc_mat.scale_max = 1.5

	ballpit.add_child(particles)
