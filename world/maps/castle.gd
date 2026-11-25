extends Node3D
## THE ROYAL CASTLE — château explorable sur plusieurs niveaux.
## Couloirs, chambres, cour intérieure, donjons, escaliers, passages secrets.

const STONE := Color(0.5, 0.48, 0.44)
const DARK_STONE := Color(0.35, 0.33, 0.3)
const WOOD := Color(0.4, 0.28, 0.18)
const ROOF := Color(0.3, 0.12, 0.08)
const GROUND := Color(0.3, 0.28, 0.25)
const HALF := 25.0

var _mats: Dictionary = {}


func _ready() -> void:
	_build_ground()
	_build_outer_walls()
	_build_inner_buildings()
	_build_towers()
	_build_courtyard()


func _mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.75
		_mats[key] = m
	return _mats[key]


func _box(pos: Vector3, size: Vector3, color: Color) -> void:
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


func _cyl(pos: Vector3, r: float, h: float, color: Color) -> void:
	var body := StaticBody3D.new()
	body.global_position = pos
	add_child(body)
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.radius = r
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


func _build_ground() -> void:
	_box(Vector3(0, -0.1, 0), Vector3(HALF * 2, 0.2, HALF * 2), GROUND)


func _build_outer_walls() -> void:
	var h := 10.0
	_box(Vector3(0, h/2, -HALF), Vector3(HALF*2, h, 1.5), DARK_STONE)
	_box(Vector3(0, h/2, HALF), Vector3(HALF*2, h, 1.5), DARK_STONE)
	_box(Vector3(-HALF, h/2, 0), Vector3(1.5, h, HALF*2), DARK_STONE)
	_box(Vector3(HALF, h/2, 0), Vector3(1.5, h, HALF*2), DARK_STONE)


func _build_inner_buildings() -> void:
	# Grande salle (nord)
	_box(Vector3(0, 4, -12), Vector3(14, 8, 8), STONE)
	_box(Vector3(0, 8.5, -12), Vector3(15, 1, 9), ROOF)
	# Chambres royales (est)
	_box(Vector3(12, 3, 0), Vector3(8, 6, 10), STONE)
	_box(Vector3(12, 6.5, 0), Vector3(9, 1, 11), ROOF)
	# Donjons (sud, sombre)
	_box(Vector3(0, 2, 12), Vector3(10, 4, 6), DARK_STONE)
	# Cuisine (ouest)
	_box(Vector3(-12, 3, 0), Vector3(6, 6, 8), STONE)
	_box(Vector3(-12, 6.5, 0), Vector3(7, 1, 9), WOOD)


func _build_towers() -> void:
	# 4 tours d'angle
	for pos in [Vector3(-HALF+2, 0, -HALF+2), Vector3(HALF-2, 0, -HALF+2), Vector3(-HALF+2, 0, HALF-2), Vector3(HALF-2, 0, HALF-2)]:
		_cyl(Vector3(pos.x, 7, pos.z), 2.5, 14, STONE)
		_cyl(Vector3(pos.x, 14.5, pos.z), 3.0, 2.5, ROOF)
	# Donjon central (tour la plus haute)
	_cyl(Vector3(0, 10, -5), 3.0, 20, STONE)
	_cyl(Vector3(0, 20.5, -5), 3.5, 3.0, ROOF)


func _build_courtyard() -> void:
	# Puits
	_cyl(Vector3(0, 0.8, 5), 1.0, 1.6, DARK_STONE)
	# Tonneaux
	for pos in [Vector3(-3, 0.5, 8), Vector3(-4, 0.5, 8), Vector3(3, 0.5, 8)]:
		_cyl(pos, 0.5, 1.0, WOOD)
	# Torchères
	for pos in [Vector3(-8, 3, 0), Vector3(8, 3, 0)]:
		var light := OmniLight3D.new()
		light.global_position = pos
		light.light_color = Color(1.0, 0.6, 0.2)
		light.light_energy = 1.5
		light.omni_range = 10.0
		light.shadow_enabled = false
		add_child(light)
