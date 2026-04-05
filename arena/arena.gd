extends Node3D

@export var use_particle_rendering: bool = false
@export var white_balls: bool = true
@export var drop_height: float = 0.8
@export var layers: int = 4
@export var ball_count: int = 500
@export var first_layer_ball_count: int = 0
@export var final_layer_ball_count: int = 0
@export var arena_width: int = 50
@export var arena_height: int = 50
@export var drop_time: float = 0.05
@export var depth_texture_size: int = 2048
@export var grid_cells: int = 4
@export var batch_spawn: bool = false
@export var distance_culling: bool = true
@export var cull_distance: float = 80.0

@onready var ballpit: Node3D = $Ballpit
@onready var floor_mesh: MeshInstance3D = $Floor/MeshInstance3D
@onready var floor_collision: CollisionShape3D = $Floor/CollisionShape3D

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

	# Color("#b32733"),
	# Color("#288e43"),
	# Color("#2852bb"),
	# Color("#bb991e"),
	# Color("#b33388"),
	# Color("#1b9d9d"),
	# Color("#bb591e"),
	# Color("#7733aa"),
	# Color("#68aa28"),
	# Color("#2877bb"),
]

var colored_materials: Dictionary = {}
var cell_data: Array = []  # [{node, center}]
var player_node: Node3D = null
var debug_menu: PanelContainer

func _make_plastic_mat(color: Color = Color.WHITE, use_vertex_color: bool = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.0
	mat.metallic_specular = 0.3
	mat.roughness = 0.3
	# mat.rim_enabled = true
	# mat.rim = 1.0
	# mat.rim_tint = 0.3
	if use_vertex_color:
		mat.vertex_color_use_as_albedo = true
	return mat

# spawn balls to fill pit
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var black_screen := TextureRect.new()
	black_screen.texture = preload("res://assets/images/darkbg.png")
	black_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	black_screen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
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

	# Disable player during load so balls fall through
	var player = get_node_or_null("Player")
	if player:
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.get_node("CollisionShape3D").disabled = true

	floor_mesh.mesh = floor_mesh.mesh.duplicate()
	floor_mesh.mesh.size = Vector3(arena_width, 20, arena_height)
	floor_collision.shape = floor_collision.shape.duplicate()
	floor_collision.shape.size = Vector3(arena_width, 20, arena_height)
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_texture = preload("res://arena/floor.png")
	floor_mat.uv1_scale = Vector3(arena_width / 16.0, arena_height / 16.0, 1)
	floor_mesh.material_override = floor_mat
	_create_walls()

	var ball_radius = 0.75
	var ball_diameter = ball_radius * 2.0
	var floor_top = $Floor.global_position.y + floor_mesh.mesh.size.y / 2.0

	# Bake all non-final layers directly (no physics, no RigidBody3D)
	for i in range(layers - 1):
		var count = first_layer_ball_count if i == 0 and first_layer_ball_count > 0 else ball_count
		var layer_y = floor_top + ball_radius + i * ball_diameter * drop_height
		_bake_layer(count, layer_y)

	# Add a flat collision surface at the pile top for player/gameplay
	var pile_top = floor_top + ball_radius + (layers - 1) * ball_diameter * drop_height
	var pile_body = StaticBody3D.new()
	pile_body.collision_layer = 8
	pile_body.collision_mask = 15
	ballpit.add_child(pile_body)
	var pile_shape = BoxShape3D.new()
	pile_shape.size = Vector3(arena_width, ball_diameter, arena_height)
	var pile_col = CollisionShape3D.new()
	pile_col.shape = pile_shape
	pile_col.position = Vector3(0, pile_top - ball_radius, 0)
	pile_body.add_child(pile_col)

	# Final layer: spawn as physics objects for gameplay
	var final_count = final_layer_ball_count if final_layer_ball_count > 0 else ball_count
	if layers > 0:
		await get_tree().physics_frame
		var final_balls = spawn_balls(final_count, pile_top + drop_height, true)
		await get_tree().physics_frame
		_snap_balls_down(final_balls)
		for ball in final_balls:
			ball.freeze = false

	canvas.queue_free()

	# Re-enable player
	if player:
		player.get_node("CollisionShape3D").disabled = false
		player.process_mode = Node.PROCESS_MODE_INHERIT
	player_node = player

	_create_debug_menu()

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

func _create_debug_menu() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	debug_menu = PanelContainer.new()
	debug_menu.position = Vector2(10, 40)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.set_content_margin_all(8)
	style.set_corner_radius_all(4)
	debug_menu.add_theme_stylebox_override("panel", style)
	canvas.add_child(debug_menu)

	var vbox = VBoxContainer.new()
	debug_menu.add_child(vbox)

	var title = Label.new()
	title.text = "Debug"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	var cull_check = CheckBox.new()
	cull_check.text = "Distance Culling"
	cull_check.button_pressed = distance_culling
	cull_check.add_theme_font_size_override("font_size", 14)
	cull_check.add_theme_color_override("font_color", Color.WHITE)
	cull_check.toggled.connect(func(on): distance_culling = on; _update_cell_visibility())
	vbox.add_child(cull_check)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()

func _process(_delta: float) -> void:
	if not distance_culling or not player_node:
		return
	var player_pos = player_node.global_position
	for data in cell_data:
		var dist = player_pos.distance_to(data.center)
		data.node.visible = dist <= cull_distance

func _update_cell_visibility() -> void:
	if distance_culling and player_node:
		var player_pos = player_node.global_position
		for data in cell_data:
			data.node.visible = player_pos.distance_to(data.center) <= cull_distance
	else:
		for data in cell_data:
			data.node.visible = true

func _bake_layer(count: int, snap_y: float) -> void:
	var half_w = arena_width / 2.0
	var half_h = arena_height / 2.0
	var ball_scale = Vector3(1.5, 1.5, 1.5)

	var all_transforms: Array = []
	var all_colors: Array = []
	for n in range(count):
		var pos = Vector3(
			randf_range(-half_w, half_w),
			snap_y + randf_range(-0.3, 0.3),
			randf_range(-half_h, half_h))
		all_transforms.append(Transform3D(Basis.from_scale(ball_scale), pos))
		all_colors.append(ball_colors.pick_random() if not white_balls else Color.WHITE)

	if grid_cells > 1:
		var cells: Dictionary = {}
		for idx in all_transforms.size():
			var t = all_transforms[idx]
			var cell = _get_cell(t.origin)
			if not cells.has(cell):
				cells[cell] = {"transforms": [], "colors": []}
			cells[cell]["transforms"].append(t)
			cells[cell]["colors"].append(all_colors[idx])

		for cell in cells:
			var data = cells[cell]
			var cell_node = Node3D.new()
			cell_node.name = "Cell_%d_%d" % [cell.x, cell.y]
			ballpit.add_child(cell_node)
			if use_particle_rendering:
				_bake_as_particles(cell_node, data["transforms"], data["colors"])
			else:
				_bake_as_multimesh(cell_node, data["transforms"], data["colors"])
			_add_cell_notifier(cell_node, cell)
	else:
		if use_particle_rendering:
			_bake_as_particles(ballpit, all_transforms, all_colors)
		else:
			_bake_as_multimesh(ballpit, all_transforms, all_colors)

func _snap_balls_down(balls: Array[RigidBody3D]) -> void:
	var space_state = get_world_3d().direct_space_state
	var ball_radius = 0.75  # SphereShape3D(0.5) * ball scale(1.5)
	for ball in balls:
		var from = Vector3(ball.global_position.x, 100.0, ball.global_position.z)
		var to = Vector3(ball.global_position.x, -100.0, ball.global_position.z)
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = 15
		query.exclude = [ball.get_rid()]
		var result = space_state.intersect_ray(query)
		if result:
			ball.global_position = Vector3(ball.global_position.x, result.position.y + ball_radius, ball.global_position.z)
		ball.freeze = true

func _get_cell(pos: Vector3) -> Vector2i:
	var half_w = arena_width / 2.0
	var half_h = arena_height / 2.0
	var cx = clampi(int((pos.x + half_w) / arena_width * grid_cells), 0, grid_cells - 1)
	var cz = clampi(int((pos.z + half_h) / arena_height * grid_cells), 0, grid_cells - 1)
	return Vector2i(cx, cz)

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
		colored_materials[color] = _make_plastic_mat(color)

	var white_mat = _make_plastic_mat(Color.WHITE)

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

func _spawn_balls_in_cell(count: int, height: float, is_final: bool, cx: int, cz: int) -> Array[RigidBody3D]:
	var balls: Array[RigidBody3D] = []
	var cell_w = float(arena_width) / grid_cells
	var cell_h = float(arena_height) / grid_cells
	var half_w = arena_width / 2.0
	var half_h = arena_height / 2.0
	var min_x = -half_w + cx * cell_w
	var min_z = -half_h + cz * cell_h

	var white_mat = _make_plastic_mat(Color.WHITE)

	for i in range(count):
		var ball = ball_scene.instantiate()
		ball.position = Vector3(
			randf_range(min_x, min_x + cell_w),
			randf_range(height - 1.0, height + 1.0),
			randf_range(min_z, min_z + cell_h))
		if white_balls and not is_final:
			ball.get_node("MeshInstance3D").material_override = white_mat
		else:
			if colored_materials.is_empty():
				for color in ball_colors:
					colored_materials[color] = _make_plastic_mat(color)
			ball.get_node("MeshInstance3D").material_override = colored_materials[ball_colors.pick_random()]
		ballpit.add_child(ball)
		balls.append(ball)

	return balls

func bake_balls(balls: Array[RigidBody3D]) -> void:
	if balls.is_empty():
		return

	var all_transforms: Array = []
	var all_colors: Array = []
	for ball in balls:
		all_transforms.append(ball.global_transform)
		var ball_mat = ball.get_node("MeshInstance3D").material_override as StandardMaterial3D
		all_colors.append(ball_mat.albedo_color if ball_mat else Color.WHITE)

	if grid_cells > 1:
		# Group balls by grid cell with culling
		var cells: Dictionary = {}
		for idx in all_transforms.size():
			var t = all_transforms[idx]
			var cell = _get_cell(t.origin)
			if not cells.has(cell):
				cells[cell] = {"transforms": [], "colors": []}
			cells[cell]["transforms"].append(t)
			cells[cell]["colors"].append(all_colors[idx])

		for cell in cells:
			var data = cells[cell]
			var cell_node = Node3D.new()
			cell_node.name = "Cell_%d_%d" % [cell.x, cell.y]
			ballpit.add_child(cell_node)
			if use_particle_rendering:
				_bake_as_particles(cell_node, data["transforms"], data["colors"])
			else:
				_bake_as_multimesh(cell_node, data["transforms"], data["colors"])
			_add_cell_notifier(cell_node, cell)
	else:
		# No grid, just one big batch (no culling)
		if use_particle_rendering:
			_bake_as_particles(ballpit, all_transforms, all_colors)
		else:
			_bake_as_multimesh(ballpit, all_transforms, all_colors)

	# Single StaticBody3D for all collision (not culled)
	var static_body = StaticBody3D.new()
	static_body.collision_layer = 8
	static_body.collision_mask = 15
	ballpit.add_child(static_body)

	var sphere_shape = SphereShape3D.new()
	for ball in balls:
		var col = CollisionShape3D.new()
		col.shape = sphere_shape
		col.global_transform = ball.global_transform
		static_body.add_child(col)

	# Remove original balls
	for ball in balls:
		ball.queue_free()

func _bake_as_multimesh(parent: Node3D, transforms: Array, colors: Array) -> void:
	var mesh = SphereMesh.new()
	mesh.material = _make_plastic_mat(Color.WHITE, true)

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
	parent.add_child(mm_instance)

func _bake_as_particles(parent: Node3D, transforms: Array, colors: Array) -> void:
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
	mesh.material = _make_plastic_mat(Color.WHITE, true)

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

	parent.add_child(particles)

func _add_cell_notifier(cell_node: Node3D, cell: Vector2i) -> void:
	var cell_w = float(arena_width) / grid_cells
	var cell_h = float(arena_height) / grid_cells
	var half_w = arena_width / 2.0
	var half_h = arena_height / 2.0

	var cell_min_x = -half_w + cell.x * cell_w
	var cell_min_z = -half_h + cell.y * cell_h
	var center = Vector3(cell_min_x + cell_w / 2.0, 5.0, cell_min_z + cell_h / 2.0)

	cell_data.append({node = cell_node, center = center})

	var notifier = VisibleOnScreenNotifier3D.new()
	notifier.name = "Notifier_%d_%d" % [cell.x, cell.y]
	notifier.position = center
	notifier.aabb = AABB(Vector3(-cell_w / 2.0, -5.0, -cell_h / 2.0), Vector3(cell_w, 10.0, cell_h))
	notifier.screen_entered.connect(func(): cell_node.visible = true)
	notifier.screen_exited.connect(func(): cell_node.visible = false)
	# Add as sibling so hiding cell_node doesn't disable the notifier
	ballpit.add_child(notifier)
