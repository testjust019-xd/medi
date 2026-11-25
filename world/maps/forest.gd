extends Node3D
## THE FORBIDDEN FOREST — version polie
## Forêt dense + vent léger sur les feuilles, village, ruines, animaux, décor utilisable, lacs, arbres grimpables.

const BARK := Color(0.30, 0.22, 0.14)
const LEAF := Color(0.16, 0.30, 0.15)
const DARK_LEAF := Color(0.12, 0.22, 0.11)
const STONE := Color(0.42, 0.40, 0.36)
const DARK_STONE := Color(0.28, 0.26, 0.24)
const WOOD := Color(0.38, 0.25, 0.14)
const GROUND := Color(0.18, 0.16, 0.12)
const MOSS := Color(0.22, 0.32, 0.18)
const ROOF := Color(0.28, 0.11, 0.07)
const FUR_BROWN := Color(0.45, 0.32, 0.18)
const FUR_GRAY := Color(0.55, 0.52, 0.48)

const HALF := 40.0

var _mats: Dictionary = {}
var _rng := RandomNumberGenerator.new()

var _leaf_nodes: Array[MeshInstance3D] = []
var _leaf_base_rot: Array[Vector3] = []
var _leaf_phase: Array[float] = []
var _wind_time: float = 0.0

const WIND_STRENGTH := 0.045
const WIND_SPEED := 1.1


func _ready() -> void:
	_rng.seed = 77
	_build_ground()
	_build_lakes()
	_build_dense_forest()
	_build_abandoned_village()
	_build_ruins()
	_build_caves()
	_build_bridge_and_ravine()
	_build_usable_decor()
	_build_animals()
	_build_lighting()
	_add_map_spawns()


func _process(delta: float) -> void:
	_wind_time += delta * WIND_SPEED
	_apply_wind()


func _apply_wind() -> void:
	for i in _leaf_nodes.size():
		var leaf := _leaf_nodes[i]
		if not is_instance_valid(leaf):
			continue
		var phase: float = _leaf_phase[i]
		var base: Vector3 = _leaf_base_rot[i]
		var sway_x := sin(_wind_time + phase) * WIND_STRENGTH
		var sway_z := cos(_wind_time * 0.7 + phase * 1.3) * WIND_STRENGTH * 0.7
		leaf.rotation = base + Vector3(sway_x, 0.0, sway_z)


func _mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.82
		_mats[key] = m
	return _mats[key]


func _box(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.global_position = pos
	add_child(body)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _mat(color)
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body


func _cyl(pos: Vector3, r: float, h: float, color: Color, parent: Node = null) -> MeshInstance3D:
	var body: Node3D
	if parent == null:
		body = StaticBody3D.new()
		body.global_position = pos
		add_child(body)
		var col := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = r
		shape.height = h
		col.shape = shape
		body.add_child(col)
	else:
		body = parent
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = h
	mi.mesh = mesh
	mi.material_override = _mat(color)
	if parent:
		mi.position = pos
	else:
		mi.position = Vector3.ZERO
	body.add_child(mi)
	return mi


func _tree(pos: Vector3, scale: float = 1.0) -> void:
	var trunk_h := _rng.randf_range(4.5, 7.5) * scale
	var leaf_r := _rng.randf_range(2.2, 3.8) * scale
	var leaf_color := LEAF if _rng.randf() > 0.3 else DARK_LEAF
	var trunk_body := StaticBody3D.new()
	trunk_body.global_position = pos
	trunk_body.add_to_group("climbable_tree")
	add_child(trunk_body)
	var trunk_mi := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.4 * scale
	trunk_mesh.bottom_radius = 0.5 * scale
	trunk_mesh.height = trunk_h
	trunk_mi.mesh = trunk_mesh
	trunk_mi.material_override = _mat(BARK)
	trunk_mi.position = Vector3(0, trunk_h * 0.5, 0)
	trunk_body.add_child(trunk_mi)
	var trunk_col := CollisionShape3D.new()
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.45 * scale
	trunk_shape.height = trunk_h
	trunk_col.shape = trunk_shape
	trunk_col.position = Vector3(0, trunk_h * 0.5, 0)
	trunk_body.add_child(trunk_col)
	var leaf_mi := MeshInstance3D.new()
	var leaf_mesh := CylinderMesh.new()
	leaf_mesh.top_radius = leaf_r * 0.3
	leaf_mesh.bottom_radius = leaf_r
	leaf_mesh.height = trunk_h * 0.65
	leaf_mi.mesh = leaf_mesh
	leaf_mi.material_override = _mat(leaf_color)
	leaf_mi.position = Vector3(pos.x, trunk_h * 0.85, pos.z)
	add_child(leaf_mi)
	_leaf_nodes.append(leaf_mi)
	_leaf_base_rot.append(leaf_mi.rotation)
	_leaf_phase.append(_rng.randf() * TAU)


func _build_ground() -> void:
	_box(Vector3(0, -0.1, 0), Vector3(HALF * 2.2, 0.2, HALF * 2.2), GROUND)
	_box(Vector3(0, -0.05, 0), Vector3(14, 0.12, 14), MOSS)
	_box(Vector3(18, -0.05, -12), Vector3(10, 0.12, 8), MOSS)


func _build_lakes() -> void:
	_build_lake(Vector3(22, -0.15, 22), 11.0, 8.5)
	_build_lake(Vector3(-20, -0.15, -18), 6.5, 5.0)
	_build_lake(Vector3(8, -0.12, -8), 4.0, 3.2)


func _build_lake(center: Vector3, radius_x: float, radius_z: float) -> void:
	var water := MeshInstance3D.new()
	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = max(radius_x, radius_z)
	water_mesh.bottom_radius = max(radius_x, radius_z)
	water_mesh.height = 0.25
	water.mesh = water_mesh
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.15, 0.35, 0.45, 0.85)
	water_mat.roughness = 0.15
	water_mat.metallic = 0.3
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.material_override = water_mat
	water.position = center
	water.scale = Vector3(radius_x / max(radius_x, radius_z), 1.0, radius_z / max(radius_x, radius_z))
	add_child(water)
	var shore := MeshInstance3D.new()
	var shore_mesh := CylinderMesh.new()
	shore_mesh.top_radius = max(radius_x, radius_z) + 1.2
	shore_mesh.bottom_radius = max(radius_x, radius_z) + 1.2
	shore_mesh.height = 0.18
	shore.mesh = shore_mesh
	shore.material_override = _mat(MOSS)
	shore.position = center + Vector3(0, -0.05, 0)
	shore.scale = Vector3(radius_x / max(radius_x, radius_z), 1.0, radius_z / max(radius_x, radius_z))
	add_child(shore)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(center.x * 100 + center.z)
	for i in 5:
		var angle := rng.randf() * TAU
		var r := max(radius_x, radius_z) * rng.randf_range(0.75, 1.05)
		var p := center + Vector3(cos(angle) * r * (radius_x / max(radius_x, radius_z)), 0.4, sin(angle) * r * (radius_z / max(radius_x, radius_z)))
		_box(p, Vector3(rng.randf_range(0.8, 1.6), rng.randf_range(0.5, 1.1), rng.randf_range(0.8, 1.5)), STONE)


func _build_dense_forest() -> void:
	for i in 70:
		var pos := Vector3(_rng.randf_range(-HALF, HALF), 0, _rng.randf_range(-HALF, HALF))
		if pos.distance_to(Vector3.ZERO) < 10.0:
			continue
		if pos.distance_to(Vector3(22, 0, 0)) < 6.0:
			continue
		_tree(pos, _rng.randf_range(0.85, 1.25))
	for pos in [Vector3(-28, 0, -22), Vector3(30, 0, 25), Vector3(-25, 0, 28)]:
		_tree(pos, 1.6)


func _build_abandoned_village() -> void:
	var huts := [Vector3(-5, 0, -4), Vector3(5, 0, -3), Vector3(0, 0, 6), Vector3(-7, 0, 5)]
	for i in huts.size():
		var pos: Vector3 = huts[i]
		var w := 4.5 + (i % 2)
		var d := 3.8 + (i % 3) * 0.3
		var h := 2.8
		_box(Vector3(pos.x, h/2, pos.z), Vector3(w, h, d), STONE)
		_box(Vector3(pos.x, h + 0.3, pos.z), Vector3(w + 0.5, 0.55, d + 0.5), ROOF)
		_box(Vector3(pos.x, 1.1, pos.z + d/2 + 0.05), Vector3(1.2, 2.0, 0.15), WOOD)
	_cyl(Vector3(0, 0.7, 0), 1.1, 1.4, DARK_STONE)
	_box(Vector3(0.8, 1.3, 0.3), Vector3(0.4, 0.3, 1.2), STONE)


func _build_ruins() -> void:
	_box(Vector3(16, 1.6, -16), Vector3(7, 3.2, 0.9), STONE)
	_box(Vector3(19, 1.1, -13), Vector3(0.9, 2.2, 5.5), STONE)
	_box(Vector3(14, 0.8, -18), Vector3(3, 1.6, 0.8), STONE)
	_cyl(Vector3(12, 2.0, -19), 0.55, 4.0, STONE)
	_cyl(Vector3(21, 1.3, -10), 0.5, 2.6, STONE)
	_box(Vector3(17, 3.4, -16), Vector3(3.5, 0.5, 0.9), STONE)


func _build_caves() -> void:
	_box(Vector3(-22, 1.2, 20), Vector3(5, 2.4, 3.5), Color(0.07, 0.06, 0.05))
	_box(Vector3(-26, 1.6, 23), Vector3(3.5, 3.2, 3.0), Color(0.05, 0.04, 0.04))
	_box(Vector3(-20, 0.8, 18), Vector3(2.5, 1.6, 1.8), DARK_STONE)
	_box(Vector3(-24, 0.9, 21), Vector3(2.0, 1.8, 1.5), DARK_STONE)


func _build_bridge_and_ravine() -> void:
	_box(Vector3(22, -1.2, 0), Vector3(10, 2.0, 8), Color(0.12, 0.10, 0.08))
	_box(Vector3(22, 0.6, 0), Vector3(9, 0.35, 3.2), WOOD)
	_box(Vector3(22, 1.2, -1.55), Vector3(9, 1.1, 0.25), WOOD)
	_box(Vector3(22, 1.2, 1.55), Vector3(9, 1.1, 0.25), WOOD)
	_cyl(Vector3(18.5, -0.3, 0), 0.4, 2.0, WOOD)
	_cyl(Vector3(25.5, -0.3, 0), 0.4, 2.0, WOOD)


func _build_usable_decor() -> void:
	for pos in [Vector3(8, 0.6, 10), Vector3(-10, 0.7, -8), Vector3(4, 0.55, -12), Vector3(-15, 0.65, 12), Vector3(12, 0.5, 6), Vector3(-6, 0.6, 15)]:
		_box(pos, Vector3(_rng.randf_range(1.4, 2.4), _rng.randf_range(1.0, 1.6), _rng.randf_range(1.3, 2.2)), STONE)
	_box(Vector3(6, 0.4, -6), Vector3(5.5, 0.8, 0.9), BARK)
	_box(Vector3(-12, 0.4, 3), Vector3(0.9, 0.8, 4.8), BARK)
	_box(Vector3(15, 0.4, 14), Vector3(4.2, 0.75, 0.85), BARK)
	for pos in [Vector3(2, 0.45, 8), Vector3(3, 0.45, 8.4), Vector3(2.5, 0.95, 8.2), Vector3(-4, 0.45, -7), Vector3(-3.2, 0.45, -7.3)]:
		_box(pos, Vector3(0.85, 0.85, 0.85), WOOD)
	_cyl(Vector3(1, 0.5, 9.5), 0.45, 1.0, Color(0.36, 0.22, 0.12))
	_cyl(Vector3(-8, 0.5, 4), 0.45, 1.0, Color(0.36, 0.22, 0.12))
	_cyl(Vector3(1, 0.25, 1), 0.9, 0.3, Color(0.15, 0.12, 0.1))
	for angle in [0.0, 1.5, 3.0, 4.5]:
		var p := Vector3(cos(angle) * 0.7, 0.35, sin(angle) * 0.7)
		_box(Vector3(1, 0, 1) + p, Vector3(0.25, 0.7, 0.25), BARK)
	_box(Vector3(-18, 0.8, -15), Vector3(6, 1.6, 5), MOSS)
	_box(Vector3(-18, 1.6, -15), Vector3(4, 0.8, 3.5), MOSS)


func _build_animals() -> void:
	_spawn_deer(Vector3(10, 0, -20))
	_spawn_deer(Vector3(-20, 0, 8))
	_spawn_deer(Vector3(25, 0, 18))
	_spawn_rabbit(Vector3(3, 0, 12))
	_spawn_rabbit(Vector3(-8, 0, -10))
	_spawn_rabbit(Vector3(14, 0, 5))
	_spawn_rabbit(Vector3(-15, 0, 18))
	_spawn_bird(Vector3(8, 3.5, -6))
	_spawn_bird(Vector3(-12, 4.0, 2))
	_spawn_bird(Vector3(18, 2.8, 12))


func _spawn_deer(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	root.name = "Deer"
	add_child(root)
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.7, 0.9, 1.6)
	body.mesh = body_mesh
	body.material_override = _mat(FUR_BROWN)
	body.position = Vector3(0, 0.9, 0)
	root.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.4, 0.4, 0.55)
	head.mesh = head_mesh
	head.material_override = _mat(FUR_BROWN)
	head.position = Vector3(0, 1.35, 0.9)
	root.add_child(head)
	for x in [-0.15, 0.15]:
		var antler := MeshInstance3D.new()
		var a_mesh := BoxMesh.new()
		a_mesh.size = Vector3(0.08, 0.5, 0.08)
		antler.mesh = a_mesh
		antler.material_override = _mat(Color(0.55, 0.45, 0.3))
		antler.position = Vector3(x, 1.7, 0.85)
		root.add_child(antler)


func _spawn_rabbit(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	root.name = "Rabbit"
	add_child(root)
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.35, 0.3, 0.45)
	body.mesh = body_mesh
	body.material_override = _mat(FUR_GRAY)
	body.position = Vector3(0, 0.25, 0)
	root.add_child(body)
	for x in [-0.08, 0.08]:
		var ear := MeshInstance3D.new()
		var e_mesh := BoxMesh.new()
		e_mesh.size = Vector3(0.06, 0.28, 0.06)
		ear.mesh = e_mesh
		ear.material_override = _mat(FUR_GRAY)
		ear.position = Vector3(x, 0.5, 0.1)
		root.add_child(ear)


func _spawn_bird(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	root.name = "Bird"
	add_child(root)
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.15, 0.12, 0.25)
	body.mesh = body_mesh
	body.material_override = _mat(Color(0.2, 0.2, 0.22))
	root.add_child(body)


func _build_lighting() -> void:
	for pos in [Vector3(0, 8, 0), Vector3(18, 7, -12), Vector3(-15, 7, 15)]:
		var light := OmniLight3D.new()
		light.position = pos
		light.light_color = Color(0.85, 0.9, 0.7)
		light.light_energy = 0.9
		light.omni_range = 14.0
		light.shadow_enabled = false
		add_child(light)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 20, 0)
	sun.light_energy = 0.35
	sun.light_color = Color(0.75, 0.82, 0.7)
	sun.shadow_enabled = false
	add_child(sun)


func _add_map_spawns() -> void:
	var spawns := Node3D.new()
	spawns.name = "MapSpawns"
	add_child(spawns)
	var positions := [Vector3(0, 1, 10), Vector3(-12, 1, -5), Vector3(12, 1, -5), Vector3(0, 1, -12), Vector3(20, 1.2, 3), Vector3(-20, 1, 15), Vector3(10, 1, 15), Vector3(-8, 1, 8)]
	for i in positions.size():
		var m := Marker3D.new()
		m.name = "Spawn%d" % i
		m.position = positions[i]
		spawns.add_child(m)
