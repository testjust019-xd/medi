extends Node3D
## THE ROYAL CASTLE — château multi-niveaux (version enrichie).
## Cour, grande salle, chambres, donjons, tours, escaliers, passages, verticalité & cachettes.

const STONE := Color(0.48, 0.46, 0.42)
const DARK_STONE := Color(0.32, 0.30, 0.28)
const WOOD := Color(0.40, 0.26, 0.15)
const ROOF := Color(0.28, 0.11, 0.08)
const GROUND := Color(0.30, 0.28, 0.25)
const CARPET := Color(0.35, 0.12, 0.12)
const BANNER := Color(0.45, 0.10, 0.10)

const HALF := 28.0

var _mats: Dictionary = {}


func _ready() -> void:
	_build_ground()
	_build_outer_walls()
	_build_courtyard()
	_build_great_hall()
	_build_royal_wing()
	_build_dungeons()
	_build_kitchen_and_service()
	_build_towers_and_keep()
	_build_stairs_and_passages()
	_build_cover_and_props()
	_build_lighting()
	_add_map_spawns()


func _mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.75
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


func _cyl(pos: Vector3, r: float, h: float, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.global_position = pos
	add_child(body)
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = h
	mi.mesh = mesh
	mi.material_override = _mat(color)
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = r
	shape.height = h
	col.shape = shape
	body.add_child(col)
	return body


func _stair(start: Vector3, steps: int, step_size: Vector3, color: Color, axis: String = "z") -> void:
	for i in range(steps):
		var offset := Vector3.ZERO
		if axis == "z":
			offset = Vector3(0, step_size.y * (i + 0.5), step_size.z * i * 0.9)
		else:
			offset = Vector3(step_size.x * i * 0.9, step_size.y * (i + 0.5), 0)
		_box(start + offset, step_size, color)


func _build_ground() -> void:
	_box(Vector3(0, -0.1, 0), Vector3(HALF * 2, 0.2, HALF * 2), GROUND)


func _build_outer_walls() -> void:
	var h := 11.0
	_box(Vector3(0, h/2, -HALF), Vector3(HALF*2, h, 1.6), DARK_STONE)
	_box(Vector3(0, h/2, HALF), Vector3(HALF*2, h, 1.6), DARK_STONE)
	_box(Vector3(-HALF, h/2, 0), Vector3(1.6, h, HALF*2), DARK_STONE)
	_box(Vector3(HALF, h/2, 0), Vector3(1.6, h, HALF*2), DARK_STONE)
	_box(Vector3(0, 3.5, -HALF + 1.0), Vector3(HALF*2 - 6, 0.35, 0.9), STONE)
	_box(Vector3(0, 3.5, HALF - 1.0), Vector3(HALF*2 - 6, 0.35, 0.9), STONE)


func _build_courtyard() -> void:
	_cyl(Vector3(0, 0.85, 6), 1.15, 1.7, DARK_STONE)
	_cyl(Vector3(0, 1.85, 6), 1.35, 0.3, STONE)
	_box(Vector3(0, 0.7, 0), Vector3(10, 1.4, 0.6), STONE)
	_box(Vector3(-5, 0.7, 4), Vector3(0.6, 1.4, 6), STONE)
	_box(Vector3(5, 0.7, 4), Vector3(0.6, 1.4, 6), STONE)


func _build_great_hall() -> void:
	var cx := 0.0
	var cz := -14.0
	_box(Vector3(cx, 4.5, cz), Vector3(18, 9, 12), STONE)
	_box(Vector3(cx, 9.3, cz), Vector3(19, 1.0, 13), ROOF)
	_box(Vector3(cx - 6, 3, cz + 6.2), Vector3(3, 6, 0.5), STONE)
	_box(Vector3(cx + 6, 3, cz + 6.2), Vector3(3, 6, 0.5), STONE)
	_box(Vector3(cx, 7.5, cz + 6.2), Vector3(18, 1.5, 0.5), STONE)
	_box(Vector3(cx, 0.05, cz), Vector3(16, 0.12, 10), GROUND)
	_box(Vector3(cx, 0.12, cz), Vector3(4, 0.08, 9), CARPET)
	_box(Vector3(cx, 0.7, cz - 1), Vector3(10, 0.35, 1.8), WOOD)
	_box(Vector3(cx, 0.4, cz + 1.2), Vector3(10, 0.4, 0.6), WOOD)
	_box(Vector3(cx, 0.4, cz - 3.2), Vector3(10, 0.4, 0.6), WOOD)
	_box(Vector3(cx - 7, 5, cz + 5.5), Vector3(0.15, 3.5, 1.2), BANNER)
	_box(Vector3(cx + 7, 5, cz + 5.5), Vector3(0.15, 3.5, 1.2), BANNER)


func _build_royal_wing() -> void:
	var cx := 14.0
	var cz := 0.0
	_box(Vector3(cx, 3.2, cz), Vector3(10, 6.4, 14), STONE)
	_box(Vector3(cx, 4.0, cz), Vector3(9.5, 0.35, 13.5), WOOD)
	_box(Vector3(cx, 7.0, cz), Vector3(11, 0.9, 15), ROOF)
	_box(Vector3(cx, 2.5, cz), Vector3(0.4, 5, 13), STONE)
	_box(Vector3(cx - 2, 2.5, cz + 3), Vector3(5, 5, 0.4), STONE)
	_box(Vector3(cx + 3, 0.45, cz + 4), Vector3(2.2, 0.5, 3.0), WOOD)
	_box(Vector3(cx + 3, 0.45, cz - 4), Vector3(2.2, 0.5, 3.0), WOOD)
	_box(Vector3(cx - 3, 0.45, cz + 4), Vector3(2.2, 0.5, 3.0), WOOD)


func _build_dungeons() -> void:
	var cz := 14.0
	_box(Vector3(0, 1.8, cz), Vector3(14, 3.6, 10), DARK_STONE)
	_box(Vector3(0, 0.05, cz), Vector3(3, 0.1, 9), GROUND)
	for x in [-4.5, 4.5]:
		_box(Vector3(x, 1.5, cz), Vector3(0.35, 3, 8), DARK_STONE)
	for z in [10.0, 12.0, 14.0, 16.0]:
		_box(Vector3(-4.5, 1.5, z), Vector3(0.15, 2.2, 0.15), Color(0.2, 0.2, 0.22))
		_box(Vector3(4.5, 1.5, z), Vector3(0.15, 2.2, 0.15), Color(0.2, 0.2, 0.22))
	_stair(Vector3(0, 0, 9), 5, Vector3(2.5, 0.4, 1.2), STONE, "z")


func _build_kitchen_and_service() -> void:
	var cx := -14.0
	_box(Vector3(cx, 3.0, 2), Vector3(9, 6, 12), STONE)
	_box(Vector3(cx, 6.3, 2), Vector3(10, 0.8, 13), WOOD)
	_box(Vector3(cx, 0.7, 2), Vector3(4, 0.4, 3), WOOD)
	_box(Vector3(cx - 2, 0.5, -2), Vector3(2, 0.9, 2), WOOD)
	_box(Vector3(cx, 2.5, 7), Vector3(3, 5, 1.5), DARK_STONE)
	_box(Vector3(cx, 5.2, 7), Vector3(2, 1.2, 2), DARK_STONE)


func _build_towers_and_keep() -> void:
	for pos in [Vector3(-HALF + 2.5, 0, -HALF + 2.5), Vector3(HALF - 2.5, 0, -HALF + 2.5), Vector3(-HALF + 2.5, 0, HALF - 2.5), Vector3(HALF - 2.5, 0, HALF - 2.5)]:
		_cyl(Vector3(pos.x, 8, pos.z), 2.6, 16, STONE)
		_cyl(Vector3(pos.x, 16.5, pos.z), 3.1, 2.2, ROOF)
		_box(Vector3(pos.x, 6, pos.z), Vector3(4, 0.3, 4), WOOD)
	_cyl(Vector3(0, 11, -6), 3.4, 22, STONE)
	_cyl(Vector3(0, 22.5, -6), 3.9, 2.8, ROOF)
	_stair(Vector3(3, 0, -6), 8, Vector3(1.4, 0.5, 1.3), STONE, "z")
	_box(Vector3(0, 4.5, -3), Vector3(5, 0.3, 3), WOOD)


func _build_stairs_and_passages() -> void:
	_stair(Vector3(7, 0, -8), 7, Vector3(1.5, 0.48, 1.3), STONE, "z")
	_box(Vector3(-8, 1.8, 2), Vector3(6, 0.3, 2.5), WOOD)
	_box(Vector3(-8, 0.9, 0.9), Vector3(0.3, 1.8, 0.3), WOOD)
	_box(Vector3(-8, 0.9, 3.1), Vector3(0.3, 1.8, 0.3), WOOD)
	_box(Vector3(0, 7.5, -HALF + 2), Vector3(20, 0.35, 1.5), STONE)
	_box(Vector3(HALF - 2, 7.5, 0), Vector3(1.5, 0.35, 16), STONE)


func _build_cover_and_props() -> void:
	for pos in [Vector3(-3, 0.5, 9), Vector3(-4, 0.5, 9.3), Vector3(3, 0.5, 9), Vector3(4, 0.5, 8.7), Vector3(-10, 0.5, -2), Vector3(10, 0.5, 4)]:
		_cyl(pos, 0.48, 1.0, WOOD)
	for pos in [Vector3(6, 0.45, 8), Vector3(7, 0.45, 8.3), Vector3(6.5, 0.95, 8.1), Vector3(-11, 0.45, 6), Vector3(-6, 0.45, -10)]:
		_box(pos, Vector3(0.9, 0.9, 0.9), WOOD)
	_box(Vector3(-5, 2, -14), Vector3(0.5, 4, 0.5), STONE)
	_box(Vector3(5, 2, -14), Vector3(0.5, 4, 0.5), STONE)
	_box(Vector3(8, 0.7, -4), Vector3(0.6, 1.4, 5), STONE)
	_box(Vector3(-8, 0.7, -4), Vector3(0.6, 1.4, 5), STONE)


func _build_lighting() -> void:
	var positions := [Vector3(0, 5, 6), Vector3(0, 6, -14), Vector3(14, 4, 0), Vector3(-14, 4, 2), Vector3(0, 3, 14), Vector3(0, 8, -6), Vector3(-HALF + 3, 6, 0), Vector3(HALF - 3, 6, 0), Vector3(0, 6, -HALF + 3), Vector3(0, 6, HALF - 3)]
	for pos in positions:
		var light := OmniLight3D.new()
		light.position = pos
		light.light_color = Color(1.0, 0.65, 0.3)
		light.light_energy = 1.5
		light.omni_range = 11.0
		light.shadow_enabled = false
		add_child(light)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 40, 0)
	sun.light_energy = 0.5
	sun.light_color = Color(1.0, 0.92, 0.85)
	sun.shadow_enabled = false
	add_child(sun)


func _add_map_spawns() -> void:
	var spawns := Node3D.new()
	spawns.name = "MapSpawns"
	add_child(spawns)
	var positions := [Vector3(0, 1, 8), Vector3(-10, 1, 2), Vector3(10, 1, 2), Vector3(0, 1, -8), Vector3(0, 1, 16), Vector3(14, 1, 4), Vector3(-14, 1, 2), Vector3(0, 5, -12)]
	for i in positions.size():
		var m := Marker3D.new()
		m.name = "Spawn%d" % i
		m.position = positions[i]
		spawns.add_child(m)
