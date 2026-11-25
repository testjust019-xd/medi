extends Node3D
## Intérieur de maison médiévale — généré procéduralement.
## Pièce avec sol, murs, meubles (table, chaises, tonneau=cachette), étage accessible.
## Le InteriorLoader charge cette scène quand un joueur entre dans la zone de porte.

const STONE := Color(0.45, 0.42, 0.38)
const WOOD := Color(0.4, 0.28, 0.18)
const DARK_WOOD := Color(0.3, 0.2, 0.12)
const FLOOR_COL := Color(0.35, 0.3, 0.24)

const ROOM_W := 8.0
const ROOM_D := 6.0
const WALL_H := 3.5

var _mats: Dictionary = {}


func _ready() -> void:
	_build_floor()
	_build_walls()
	_build_furniture()
	_build_upper_floor()


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


func _build_floor() -> void:
	_box(Vector3(0, -0.1, 0), Vector3(ROOM_W, 0.2, ROOM_D), FLOOR_COL)


func _build_walls() -> void:
	var hw := ROOM_W / 2.0
	var hd := ROOM_D / 2.0
	# Mur arrière (plein)
	_box(Vector3(0, WALL_H/2, -hd), Vector3(ROOM_W, WALL_H, 0.3), STONE)
	# Mur gauche (plein)
	_box(Vector3(-hw, WALL_H/2, 0), Vector3(0.3, WALL_H, ROOM_D), STONE)
	# Mur droit (plein)
	_box(Vector3(hw, WALL_H/2, 0), Vector3(0.3, WALL_H, ROOM_D), STONE)
	# Mur avant: deux morceaux avec ouverture pour la porte (au centre, largeur 2m)
	_box(Vector3(-hw + (ROOM_W-2)/4, WALL_H/2, hd), Vector3((ROOM_W-2)/2, WALL_H, 0.3), STONE)
	_box(Vector3(hw - (ROOM_W-2)/4, WALL_H/2, hd), Vector3((ROOM_W-2)/2, WALL_H, 0.3), STONE)
	# Linteau au-dessus de la porte
	_box(Vector3(0, WALL_H - 0.5, hd), Vector3(2.0, 1.0, 0.3), STONE)


func _build_furniture() -> void:
	# Table au centre
	_box(Vector3(0, 0.45, 0), Vector3(1.8, 0.1, 1.0), WOOD)
	_box(Vector3(-0.7, 0.22, 0), Vector3(0.1, 0.45, 0.1), DARK_WOOD)  # pied
	_box(Vector3(0.7, 0.22, 0), Vector3(0.1, 0.45, 0.1), DARK_WOOD)
	_box(Vector3(-0.7, 0.22, 0.4), Vector3(0.1, 0.45, 0.1), DARK_WOOD)
	_box(Vector3(0.7, 0.22, 0.4), Vector3(0.1, 0.45, 0.1), DARK_WOOD)
	# Chaises
	_box(Vector3(-1.2, 0.25, -0.6), Vector3(0.4, 0.5, 0.4), WOOD)
	_box(Vector3(1.2, 0.25, -0.6), Vector3(0.4, 0.5, 0.4), WOOD)
	# Tonneau (cachette) dans un coin
	var body := StaticBody3D.new()
	body.global_position = Vector3(-3, 0.5, -2)
	add_child(body)
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mi.mesh = mesh
	mi.material_override = _mat(DARK_WOOD)
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.5
	shape.height = 1.0
	col.shape = shape
	body.add_child(col)
	# Lit (simple) dans l'autre coin
	_box(Vector3(3, 0.25, -2), Vector3(1.2, 0.5, 2.0), WOOD)


func _build_upper_floor() -> void:
	# Étage partiel (moitié de la pièce) accessible par un escalier
	var upper_y := WALL_H - 0.5
	# Plancher de l'étage (moitié arrière)
	_box(Vector3(0, upper_y, -ROOM_D/4), Vector3(ROOM_W, 0.2, ROOM_D/2 - 0.5), WOOD)
	# Escalier (3 marches)
	for i in 3:
		var step_h := upper_y / 3.0 * (i + 1)
		var step_z := ROOM_D/2 - 1.0 - i * 0.5
		_box(Vector3(0, step_h/2, step_z), Vector3(1.5, step_h, 0.5), DARK_WOOD)
	# Garde-corps à l'étage
	_box(Vector3(0, upper_y + 0.5, 0.5), Vector3(ROOM_W, 1.0, 0.1), DARK_WOOD)
