extends Node3D
## THE FORBIDDEN FOREST — forêt mystérieuse avec village abandonné, ruines, grottes.
## Générée procéduralement: denses arbres, cabane isolée, ruines, pont, grottes.

const BARK := Color(0.3, 0.22, 0.14)
const LEAF := Color(0.18, 0.3, 0.16)
const STONE := Color(0.42, 0.4, 0.36)
const GROUND := Color(0.2, 0.18, 0.14)
const ROOF := Color(0.3, 0.12, 0.08)
const HALF := 35.0

var _mats: Dictionary = {}


func _ready() -> void:
	_build_ground()
	_build_dense_forest()
	_build_abandoned_village()
	_build_ruins()
	_build_caves()
	_build_bridge()


func _mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.8
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


func _build_dense_forest() -> void:
	# 50 arbres dispersés
	for i in 50:
		var pos := Vector3(randf_range(-HALF, HALF), 0, randf_range(-HALF, HALF))
		# Éviter le centre (village)
		if pos.distance_to(Vector3.ZERO) < 8.0:
			continue
		_cyl(pos, 0.5, randf_range(4, 7), BARK)
		_cyl(Vector3(pos.x, pos.y + 6, pos.z), randf_range(2.5, 4), randf_range(3, 5), LEAF)


func _build_abandoned_village() -> void:
	# 3 cabanes abandonnées au centre
	for i in 3:
		var angle := i * TAU / 3.0
		var pos := Vector3(cos(angle) * 6, 0, sin(angle) * 6)
		_box(pos, Vector3(5, 3, 4), STONE)
		_box(Vector3(pos.x, 3.2, pos.z), Vector3(5.5, 0.5, 4.5), ROOF)


func _build_ruins() -> void:
	# Murs en ruine (nord-est)
	_box(Vector3(15, 1.5, -15), Vector3(6, 3, 0.8), STONE)
	_box(Vector3(18, 1, -12), Vector3(0.8, 2, 5), STONE)
	# Pilier cassé
	_cyl(Vector3(12, 2, -18), 0.6, 4, STONE)


func _build_caves() -> void:
	# Entrées de grotte (boîtes sombres au sol, sud-ouest)
	_box(Vector3(-20, 1, 20), Vector3(4, 2, 3), Color(0.08, 0.07, 0.06))
	_box(Vector3(-25, 1.5, 22), Vector3(3, 3, 2.5), Color(0.06, 0.05, 0.04))


func _build_bridge() -> void:
	# Pont en bois sur un ravin (est)
	_box(Vector3(20, 0.5, 0), Vector3(8, 0.3, 3), Color(0.35, 0.22, 0.12))
	# Rambardes
	_box(Vector3(20, 1, -1.5), Vector3(8, 1, 0.2), Color(0.3, 0.2, 0.1))
	_box(Vector3(20, 1, 1.5), Vector3(8, 1, 0.2), Color(0.3, 0.2, 0.1))
