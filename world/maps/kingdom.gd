extends Node3D
## KINGDOM — grande cité médiévale fortifiée (version améliorée).
## Château, marché, quartiers, ruelles, verticalité, cachettes, parkour.

const STONE := Color(0.50, 0.48, 0.44)
const DARK_STONE := Color(0.36, 0.34, 0.31)
const WOOD := Color(0.42, 0.28, 0.17)
const ROOF := Color(0.32, 0.13, 0.09)
const GROUND := Color(0.33, 0.30, 0.26)
const GRASS := Color(0.26, 0.36, 0.20)
const BARREL := Color(0.38, 0.24, 0.12)
const CRATE := Color(0.45, 0.32, 0.18)
const HAY := Color(0.55, 0.48, 0.28)

const WALL_H := 8.5
const MAP_SIZE := 80.0
const HALF := MAP_SIZE / 2.0

var _mats: Dictionary = {}


func _ready() -> void:
	_build_ground()
	_build_perimeter_walls()
	_build_castle()
	_build_market()
	_build_residential()
	_build_streets_and_cover()
	_build_parkour_elements()
	_build_forest_perimeter()
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


func _cyl(pos: Vector3, radius: float, height: float, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.global_position = pos
	add_child(body)
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.material_override = _mat(color)
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	col.shape = shape
	body.add_child(col)
	return body


func _stair(start: Vector3, steps: int, step_size: Vector3, color: Color) -> void:
	for i in range(steps):
		var pos := start + Vector3(0, step_size.y * (i + 0.5), step_size.z * i * 0.9)
		_box(pos, step_size, color)


func _build_ground() -> void:
	_box(Vector3(0, -0.1, 0), Vector3(MAP_SIZE, 0.2, MAP_SIZE), GROUND)
	_box(Vector3(0, -0.15, HALF + 18), Vector3(MAP_SIZE + 40, 0.2, 36), GRASS)
	_box(Vector3(0, -0.15, -HALF - 18), Vector3(MAP_SIZE + 40, 0.2, 36), GRASS)
	_box(Vector3(HALF + 18, -0.15, 0), Vector3(36, 0.2, MAP_SIZE), GRASS)
	_box(Vector3(-HALF - 18, -0.15, 0), Vector3(36, 0.2, MAP_SIZE), GRASS)


func _build_perimeter_walls() -> void:
	var h := WALL_H
	_box(Vector3(0, h/2, -HALF), Vector3(MAP_SIZE, h, 1.6), DARK_STONE)
	_box(Vector3(0, h/2, HALF), Vector3(MAP_SIZE, h, 1.6), DARK_STONE)
	_box(Vector3(-HALF, h/2, 0), Vector3(1.6, h, MAP_SIZE), DARK_STONE)
	_box(Vector3(HALF, h/2, 0), Vector3(1.6, h, MAP_SIZE), DARK_STONE)
	for pos in [Vector3(-HALF, 0, -HALF), Vector3(HALF, 0, -HALF), Vector3(-HALF, 0, HALF), Vector3(HALF, 0, HALF)]:
		_cyl(Vector3(pos.x, h * 0.7, pos.z), 2.8, h * 1.4, DARK_STONE)
		_cyl(Vector3(pos.x, h * 1.5, pos.z), 3.2, 1.8, ROOF)
	for x in [-HALF/2, HALF/2]:
		_cyl(Vector3(x, h * 0.55, -HALF), 2.0, h * 1.1, DARK_STONE)
		_cyl(Vector3(x, h * 0.55, HALF), 2.0, h * 1.1, DARK_STONE)
	for z in [-HALF/2, HALF/2]:
		_cyl(Vector3(-HALF, h * 0.55, z), 2.0, h * 1.1, DARK_STONE)
		_cyl(Vector3(HALF, h * 0.55, z), 2.0, h * 1.1, DARK_STONE)
	_box(Vector3(0, 3.2, -HALF + 1.1), Vector3(MAP_SIZE - 8, 0.35, 1.0), STONE)
	_box(Vector3(0, 3.2, HALF - 1.1), Vector3(MAP_SIZE - 8, 0.35, 1.0), STONE)


func _build_castle() -> void:
	var cx := -22.0
	var cz := -22.0
	_box(Vector3(cx, 4.2, cz), Vector3(20, 8.4, 16), STONE)
	_box(Vector3(cx, 8.8, cz), Vector3(21, 1.0, 17), ROOF)
	_cyl(Vector3(cx, 11, cz), 3.8, 22, STONE)
	_cyl(Vector3(cx, 22.5, cz), 4.3, 2.5, ROOF)
	for corner in [Vector3(cx-9, 0, cz-7), Vector3(cx+9, 0, cz-7), Vector3(cx-9, 0, cz+7), Vector3(cx+9, 0, cz+7)]:
		_cyl(Vector3(corner.x, 7, corner.z), 2.2, 14, STONE)
		_cyl(Vector3(corner.x, 14.5, corner.z), 2.7, 1.6, ROOF)
	_box(Vector3(cx + 12, 0.6, cz + 2), Vector3(6, 1.2, 10), STONE)
	_box(Vector3(cx + 12, 0.6, cz - 6), Vector3(8, 1.2, 0.8), STONE)
	_stair(Vector3(cx + 12, 0, cz + 10), 6, Vector3(2.0, 0.5, 1.5), STONE)
	_box(Vector3(cx + 8, 2.5, cz + 9), Vector3(4, 0.3, 2), WOOD)
	_box(Vector3(cx - 14, 2.0, cz + 10), Vector3(6, 4, 5), STONE)
	_box(Vector3(cx - 14, 4.3, cz + 10), Vector3(6.6, 0.7, 5.6), ROOF)


func _build_market() -> void:
	var mx := 4.0
	var mz := 4.0
	for i in 9:
		var px := mx + (i % 3 - 1) * 7.0
		var pz := mz + int(i / 3) * 6.5 - 6.5
		_box(Vector3(px, 0.65, pz), Vector3(4.2, 1.3, 3.2), WOOD)
		_box(Vector3(px, 1.55, pz), Vector3(4.7, 0.3, 3.7), ROOF)
	_cyl(Vector3(mx, 0.85, mz), 1.3, 1.7, DARK_STONE)
	_cyl(Vector3(mx, 1.9, mz), 1.5, 0.3, STONE)
	_box(Vector3(mx - 12, 0.5, mz + 12), Vector3(10, 1.0, 7), WOOD)
	_box(Vector3(mx - 12, 2.8, mz + 12), Vector3(10.5, 0.3, 7.5), Color(0.28, 0.11, 0.07))
	for x in [mx - 16.0, mx - 8.0]:
		for z in [mz + 9.0, mz + 15.0]:
			_cyl(Vector3(x, 1.5, z), 0.4, 3.0, WOOD)


func _build_residential() -> void:
	var houses := [
		Vector3(18, 0, 16), Vector3(26, 0, 16), Vector3(18, 0, 24),
		Vector3(26, 0, 24), Vector3(34, 0, 18),
		Vector3(-16, 0, 18), Vector3(-24, 0, 18), Vector3(-16, 0, 26),
		Vector3(-24, 0, 26), Vector3(-32, 0, 20),
		Vector3(28, 0, -8), Vector3(28, 0, 2), Vector3(34, 0, -4),
		Vector3(-28, 0, -6), Vector3(-28, 0, 4),
	]
	for i in houses.size():
		var pos: Vector3 = houses[i]
		var w := 5.0 + (i % 3) * 0.8
		var h := 3.2 + (i % 2) * 1.2
		_build_house_walls(pos, w, h)
		_box(Vector3(pos.x, h + 0.35, pos.z), Vector3(w + 0.6, 0.65, w + 0.6), ROOF)
		_add_door_trigger(pos, w, i)
		if i % 3 == 0:
			_box(Vector3(pos.x, h - 0.6, pos.z + w/2 + 0.6), Vector3(w * 0.6, 0.25, 1.1), WOOD)


func _build_house_walls(pos: Vector3, w: float, h: float) -> void:
	var t := 0.35
	var hw := w / 2.0
	_box(Vector3(pos.x, h/2, pos.z - hw), Vector3(w, h, t), STONE)
	_box(Vector3(pos.x - hw, h/2, pos.z), Vector3(t, h, w), STONE)
	_box(Vector3(pos.x + hw, h/2, pos.z), Vector3(t, h, w), STONE)
	var side_w := (w - 1.6) / 2.0
	_box(Vector3(pos.x - hw + side_w/2, h/2, pos.z + hw), Vector3(side_w, h, t), STONE)
	_box(Vector3(pos.x + hw - side_w/2, h/2, pos.z + hw), Vector3(side_w, h, t), STONE)
	_box(Vector3(pos.x, h - 0.55, pos.z + hw), Vector3(1.6, 1.1, t), STONE)
	_box(Vector3(pos.x, -0.04, pos.z), Vector3(w - 0.3, 0.1, w - 0.3), GROUND)


func _add_door_trigger(pos: Vector3, w: float, index: int) -> void:
	var door_pos := Vector3(pos.x, 1.0, pos.z + w/2.0 + 0.55)
	var area := Area3D.new()
	area.position = door_pos
	area.name = "DoorTrigger_%d" % index
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 2.2, 1.6)
	col.shape = shape
	area.add_child(col)
	add_child(area)
	var loader := get_parent().get_parent().get_node_or_null("InteriorLoader")
	if loader and loader.has_method("register_building"):
		loader.register_building("house_%d" % index, area, "res://world/interiors/house_interior.tscn")


func _build_streets_and_cover() -> void:
	_box(Vector3(8, 0.7, -8), Vector3(12, 1.4, 0.7), STONE)
	_box(Vector3(-6, 0.7, 10), Vector3(0.7, 1.4, 10), STONE)
	_box(Vector3(12, 0.7, 8), Vector3(0.7, 1.4, 8), STONE)
	_box(Vector3(-10, 0.7, -4), Vector3(8, 1.4, 0.7), STONE)
	var barrel_spots := [
		Vector3(2, 0.5, 12), Vector3(3, 0.5, 12.5), Vector3(1.5, 0.5, 13),
		Vector3(-8, 0.5, 8), Vector3(-7, 0.5, 8.5),
		Vector3(15, 0.5, -12), Vector3(16, 0.5, -11.5), Vector3(14.5, 0.5, -12.5),
		Vector3(-18, 0.5, -8), Vector3(-17, 0.5, -8.5),
		Vector3(6, 0.5, -18), Vector3(7, 0.5, -17.5),
		Vector3(-4, 0.5, 20), Vector3(-3, 0.5, 20.5),
	]
	for pos in barrel_spots:
		_cyl(pos, 0.48, 1.0, BARREL)
	for pos in [Vector3(10, 0.45, 0), Vector3(11, 0.45, 0.3), Vector3(10.5, 0.95, 0.2), Vector3(-12, 0.45, -12), Vector3(-11, 0.45, -12.3), Vector3(20, 0.45, 10), Vector3(20.5, 0.45, 10.5)]:
		_box(pos, Vector3(0.9, 0.9, 0.9), CRATE)
	_cyl(Vector3(30, 0.75, 28), 1.2, 1.5, HAY)
	_cyl(Vector3(28, 0.7, 30), 1.0, 1.4, HAY)
	_cyl(Vector3(-30, 0.75, 28), 1.15, 1.5, HAY)
	_cyl(Vector3(-28, 0.7, 30), 0.95, 1.35, HAY)


func _build_parkour_elements() -> void:
	_stair(Vector3(-32, 0, -10), 7, Vector3(1.5, 0.48, 1.4), STONE)
	_stair(Vector3(30, 0, 8), 6, Vector3(1.5, 0.48, 1.4), STONE)
	_stair(Vector3(10, 0, -28), 5, Vector3(1.5, 0.48, 1.4), STONE)
	_box(Vector3(0, 3.5, -15), Vector3(5, 0.3, 3.5), WOOD)
	_box(Vector3(16, 3.0, 6), Vector3(4, 0.3, 3), WOOD)
	_box(Vector3(-14, 3.2, 8), Vector3(4.5, 0.3, 3), WOOD)
	_box(Vector3(-18, 1.4, 0), Vector3(1.3, 2.8, 10), DARK_STONE)
	_box(Vector3(20, 1.4, -5), Vector3(1.3, 2.8, 9), DARK_STONE)
	_box(Vector3(0, 2.8, 0), Vector3(8, 0.3, 1.8), WOOD)
	_box(Vector3(-4.2, 1.6, 0), Vector3(0.4, 2.5, 0.4), WOOD)
	_box(Vector3(4.2, 1.6, 0), Vector3(0.4, 2.5, 0.4), WOOD)


func _build_forest_perimeter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 40:
		var angle := i * TAU / 40.0
		var r := HALF + rng.randf_range(6, 22)
		var pos := Vector3(cos(angle) * r, 0, sin(angle) * r)
		_cyl(pos, 0.4, 4.2, WOOD)
		_cyl(Vector3(pos.x, 5.2, pos.z), 1.9, 3.2, GRASS)
	for i in 18:
		var pos := Vector3(rng.randf_range(-HALF - 28, HALF + 28), 0, rng.randf_range(-HALF - 28, HALF + 28))
		if abs(pos.x) < HALF - 2 and abs(pos.z) < HALF - 2:
			continue
		_cyl(pos, 0.35, 3.8, WOOD)
		_cyl(Vector3(pos.x, 4.8, pos.z), 1.7, 2.8, GRASS)


func _build_lighting() -> void:
	for x in [-HALF + 4, HALF - 4]:
		for z in [-HALF + 12, 0, HALF - 12]:
			var light := OmniLight3D.new()
			light.position = Vector3(x, WALL_H - 0.5, z)
			light.light_color = Color(1.0, 0.68, 0.3)
			light.light_energy = 1.6
			light.omni_range = 11.0
			light.shadow_enabled = false
			add_child(light)
	for pos in [Vector3(4, 3.5, 4), Vector3(-8, 3.2, 12), Vector3(-22, 6, -16), Vector3(-14, 4, -14), Vector3(18, 3, 16), Vector3(-18, 3, 18)]:
		var light := OmniLight3D.new()
		light.position = pos
		light.light_color = Color(1.0, 0.65, 0.28)
		light.light_energy = 1.4
		light.omni_range = 9.0
		light.shadow_enabled = false
		add_child(light)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 35, 0)
	sun.light_energy = 0.6
	sun.light_color = Color(1.0, 0.94, 0.86)
	sun.shadow_enabled = false
	add_child(sun)


func _add_map_spawns() -> void:
	var spawns := Node3D.new()
	spawns.name = "MapSpawns"
	add_child(spawns)
	var positions := [Vector3(0, 1, 12), Vector3(-12, 1, 0), Vector3(12, 1, 0), Vector3(0, 1, -12), Vector3(20, 1, 12), Vector3(-20, 1, 12), Vector3(8, 1, -20), Vector3(-8, 1, -18)]
	for i in positions.size():
		var m := Marker3D.new()
		m.name = "Spawn%d" % i
		m.position = positions[i]
		spawns.add_child(m)
