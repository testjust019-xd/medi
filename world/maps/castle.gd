extends Node3D
## THE ROYAL CASTLE — château multi-niveaux (v3, bâtiments creux).
## Cour avec fontaine + marché, grande salle avec galerie, aile royale à étage,
## cuisine, cachots (toit accessible), donjon à 3 niveaux, chemin de ronde.
##
## Notes de design :
## - Les accès verticaux sont des RAMPES (pente < 45°) et non des marches :
##   le joueur n'a pas de step-up automatique.
## - Tous les bâtiments sont creux (portes + fenêtres) -> cachettes et parkour.
## - Les points d'apparition sont tous en espace libre.

const STONE := Color(0.48, 0.46, 0.42)
const DARK_STONE := Color(0.32, 0.30, 0.28)
const WOOD := Color(0.40, 0.26, 0.15)
const DARK_WOOD := Color(0.26, 0.16, 0.09)
const ROOF := Color(0.28, 0.11, 0.08)
const GROUND := Color(0.30, 0.28, 0.25)
const PATH := Color(0.40, 0.37, 0.33)
const CARPET := Color(0.35, 0.12, 0.12)
const BANNER := Color(0.45, 0.10, 0.10)
const IRON := Color(0.2, 0.2, 0.22)
const NO_COLOR := Color(0, 0, 0, 0)

const HALF := 28.0
const WALL_H := 11.0
const WALK_Y := 8.0

var _mats: Dictionary = {}


func _ready() -> void:
	_build_ground()
	_build_outer_walls()
	_build_wall_walk()
	_build_towers()
	_build_courtyard()
	_build_great_hall()
	_build_royal_wing()
	_build_dungeons()
	_build_kitchen()
	_build_keep()
	_build_cover_and_props()
	_build_lighting()
	_add_map_spawns()


# ---------------------------------------------------------------- helpers

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
	body.position = pos
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
	body.position = pos
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


## Décor sans collision (bannières, merlons, tapis, bandes de fer...).
func _deco(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _mat(color)
	mi.position = pos
	add_child(mi)


## Rampe de a (bas) vers b (haut). Pente max conseillée : ~35°.
func _ramp(a: Vector3, b: Vector3, width: float, color: Color = STONE) -> void:
	var dir := b - a
	var body := StaticBody3D.new()
	add_child(body)
	var basis := Basis.looking_at(dir.normalized(), Vector3.UP)
	body.transform = Transform3D(basis, (a + b) / 2.0 - basis.y * 0.15)
	var size := Vector3(width, 0.3, dir.length())
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


func _op(off: float, w: float, y0: float, h: float) -> Dictionary:
	return {"off": off, "w": w, "y0": y0, "h": h}


func _wall_seg(c: Vector3, along_x: bool, a: float, b: float, y0: float, y1: float, t: float, color: Color) -> void:
	if b - a < 0.01 or y1 - y0 < 0.01:
		return
	var mid := (a + b) / 2.0
	var ym := (y0 + y1) / 2.0
	if along_x:
		_box(c + Vector3(mid, ym, 0), Vector3(b - a, y1 - y0, t), color)
	else:
		_box(c + Vector3(0, ym, mid), Vector3(t, y1 - y0, b - a), color)


## Mur avec ouvertures (portes y0=0, fenêtres y0>0). c = centre au sol.
## openings : [_op(offset, largeur, y_bas, hauteur)] ; offset relatif au centre.
func _wall(c: Vector3, along_x: bool, length: float, h: float, t: float, color: Color, openings: Array = []) -> void:
	var ops: Array = openings.duplicate()
	ops.sort_custom(func(a, b): return a["off"] < b["off"])
	var cur: float = -length / 2.0
	for o in ops:
		var a: float = o["off"] - o["w"] / 2.0
		var b: float = o["off"] + o["w"] / 2.0
		_wall_seg(c, along_x, cur, a, 0.0, h, t, color)
		_wall_seg(c, along_x, a, b, 0.0, o["y0"], t, color)
		_wall_seg(c, along_x, a, b, o["y0"] + o["h"], h, t, color)
		cur = b
	_wall_seg(c, along_x, cur, length / 2.0, 0.0, h, t, color)


## Pièce creuse. ops = {"n": [...], "s": [...], "e": [...], "w": [...]}
## n = z-, s = z+, e = x+, w = x-. Toit si roof_color.a > 0, sol décoratif si floor_color.a > 0.
func _room(cx: float, cz: float, w: float, d: float, h: float, t: float, color: Color, roof_color: Color, ops: Dictionary = {}, floor_color: Color = NO_COLOR) -> void:
	_wall(Vector3(cx, 0, cz - d / 2.0 + t / 2.0), true, w, h, t, color, ops.get("n", []))
	_wall(Vector3(cx, 0, cz + d / 2.0 - t / 2.0), true, w, h, t, color, ops.get("s", []))
	_wall(Vector3(cx + w / 2.0 - t / 2.0, 0, cz), false, d - 2.0 * t, h, t, color, ops.get("e", []))
	_wall(Vector3(cx - w / 2.0 + t / 2.0, 0, cz), false, d - 2.0 * t, h, t, color, ops.get("w", []))
	if roof_color.a > 0.0:
		_box(Vector3(cx, h + 0.15, cz), Vector3(w + 1.0, 0.3, d + 1.0), roof_color)
	if floor_color.a > 0.0:
		_deco(Vector3(cx, 0.02, cz), Vector3(w - 2.0 * t, 0.04, d - 2.0 * t), floor_color)


## Dalle dont la face supérieure est à y = top.
func _slab(x0: float, x1: float, z0: float, z1: float, top: float, color: Color, thick: float = 0.3) -> void:
	if x1 - x0 < 0.01 or z1 - z0 < 0.01:
		return
	_box(Vector3((x0 + x1) / 2.0, top - thick / 2.0, (z0 + z1) / 2.0), Vector3(x1 - x0, thick, z1 - z0), color)


## Plancher rectangulaire percé d'une trappe (pour laisser passer une rampe).
func _floor_with_hole(rx0: float, rx1: float, rz0: float, rz1: float, top: float, hx0: float, hx1: float, hz0: float, hz1: float, color: Color) -> void:
	_slab(rx0, hx0, rz0, rz1, top, color)
	_slab(hx1, rx1, rz0, rz1, top, color)
	_slab(hx0, hx1, rz0, hz0, top, color)
	_slab(hx0, hx1, hz1, rz1, top, color)


# ---------------------------------------------------------------- enceinte

func _build_ground() -> void:
	_box(Vector3(0, -0.1, 0), Vector3(HALF * 2, 0.2, HALF * 2), GROUND)
	# Chemin pavé porte -> grande salle
	_deco(Vector3(0, 0.02, 10), Vector3(5, 0.04, 36), PATH)


func _build_outer_walls() -> void:
	var L := HALF * 2.0
	_wall(Vector3(0, 0, -HALF), true, L, WALL_H, 1.6, DARK_STONE)
	_wall(Vector3(-HALF, 0, 0), false, L, WALL_H, 1.6, DARK_STONE)
	_wall(Vector3(HALF, 0, 0), false, L, WALL_H, 1.6, DARK_STONE)
	# Mur sud avec porte de la forteresse (fermée : le joueur ne tombe pas du monde)
	_wall(Vector3(0, 0, HALF), true, L, WALL_H, 1.6, DARK_STONE, [_op(0.0, 6.0, 0.0, 7.0)])
	_box(Vector3(0, 3.4, HALF), Vector3(5.8, 6.8, 0.5), WOOD)
	_deco(Vector3(0, 2.0, HALF - 0.3), Vector3(5.8, 0.2, 0.1), IRON)
	_deco(Vector3(0, 4.6, HALF - 0.3), Vector3(5.8, 0.2, 0.1), IRON)
	# Créneaux (décor)
	for i in range(-11, 12):
		var p := i * 2.4
		_deco(Vector3(p, WALL_H + 0.6, -HALF), Vector3(1.2, 1.2, 1.6), DARK_STONE)
		_deco(Vector3(p, WALL_H + 0.6, HALF), Vector3(1.2, 1.2, 1.6), DARK_STONE)
		_deco(Vector3(-HALF, WALL_H + 0.6, p), Vector3(1.6, 1.2, 1.2), DARK_STONE)
		_deco(Vector3(HALF, WALL_H + 0.6, p), Vector3(1.6, 1.2, 1.2), DARK_STONE)


## Chemin de ronde (y = 8) : ouest, nord, est. Accès par deux rampes dans la cour.
func _build_wall_walk() -> void:
	var inner := HALF - 0.8 - 1.2  # centre du chemin, collé au mur
	_slab(-HALF + 0.8, HALF - 0.8, -HALF + 0.8, -HALF + 3.2, WALK_Y, STONE)  # nord
	_slab(-HALF + 0.8, -HALF + 3.2, -HALF + 0.8, 8.0, WALK_Y, STONE)  # ouest
	_slab(HALF - 3.2, HALF - 0.8, -HALF + 0.8, 8.0, WALK_Y, STONE)  # est
	# Rampes d'accès (pente ~34°)
	_ramp(Vector3(-inner, 0, 20.0), Vector3(-inner, WALK_Y, 8.0), 2.4)
	_ramp(Vector3(inner, 0, 20.0), Vector3(inner, WALK_Y, 8.0), 2.4)


func _build_towers() -> void:
	# Bastions ronds : plateformes accessibles depuis le chemin de ronde (sommet à y = 8)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var x: float = sx * (HALF - 2.5)
			var z: float = sz * (HALF - 2.5)
			_cyl(Vector3(x, 4.0, z), 3.0, 8.0, STONE)
			_deco(Vector3(x, 10.6, z), Vector3(0.12, 5.2, 0.12), IRON)
			_deco(Vector3(x + 0.65, 11.6, z), Vector3(1.2, 1.5, 0.05), BANNER)


# ---------------------------------------------------------------- cour

func _build_courtyard() -> void:
	# Fontaine
	_cyl(Vector3(0, 0.85, 6), 1.15, 1.7, DARK_STONE)
	_cyl(Vector3(0, 1.85, 6), 1.35, 0.3, STONE)
	# Muret en U autour de la fontaine (ouvert côté porte)
	_box(Vector3(0, 0.7, 0), Vector3(10, 1.4, 0.6), STONE)
	_box(Vector3(-5, 0.7, 4), Vector3(0.6, 1.4, 6), STONE)
	_box(Vector3(5, 0.7, 4), Vector3(0.6, 1.4, 6), STONE)
	# Petit marché (laisse le chemin central libre)
	for px in [-7.0, -3.7, 3.7]:
		_box(Vector3(px, 0.6, 15), Vector3(2.8, 1.15, 2.0), WOOD)
		_box(Vector3(px, 1.35, 15), Vector3(3.1, 0.25, 2.3), ROOF)
	_cyl(Vector3(-9.5, 0.5, 18), 0.45, 1.0, WOOD)
	_box(Vector3(-5.5, 0.4, 19), Vector3(2.5, 0.45, 0.9), WOOD)
	# Auvent / loft accolé à la cuisine (à franchir en parkour)
	_box(Vector3(-6.3, 1.8, 2), Vector3(6, 0.3, 2.5), WOOD)
	_box(Vector3(-4.0, 0.9, 0.9), Vector3(0.3, 1.8, 0.3), WOOD)
	_box(Vector3(-4.0, 0.9, 3.1), Vector3(0.3, 1.8, 0.3), WOOD)


# ---------------------------------------------------------------- grande salle

func _build_great_hall() -> void:
	var cx := 0.0
	var cz := -14.0
	var ops := {
		"s": [_op(0.0, 4.0, 0.0, 4.5), _op(-6.0, 1.2, 2.5, 2.5), _op(6.0, 1.2, 2.5, 2.5)],
		"w": [_op(-3.0, 2.4, 0.0, 3.0), _op(3.0, 1.2, 2.5, 2.5)],
		"e": [_op(-2.5, 1.2, 2.5, 2.5), _op(2.5, 1.2, 2.5, 2.5)],
		"n": [_op(-4.0, 1.2, 5.5, 2.0), _op(4.0, 1.2, 5.5, 2.0)],
	}
	_room(cx, cz, 18, 12, 9, 0.5, STONE, ROOF, ops, Color(0.25, 0.2, 0.16))
	_deco(Vector3(cx, 0.05, cz), Vector3(4, 0.03, 9), CARPET)
	# Estrade + tables
	_box(Vector3(cx, 0.7, cz - 4.5), Vector3(8, 1.4, 2.0), WOOD)
	_box(Vector3(cx, 0.4, cz - 1.0), Vector3(10, 0.8, 1.0), WOOD)
	_box(Vector3(cx, 0.4, cz + 1.8), Vector3(10, 0.8, 1.0), WOOD)
	# Piliers
	for p in [Vector3(-4.5, 4.5, -11.0), Vector3(4.5, 4.5, -11.0), Vector3(-4.5, 4.5, -16.5), Vector3(4.5, 4.5, -16.5)]:
		_cyl(p, 0.5, 9.0, STONE)
	# Galerie à y = 4.5 (nord + est), rampe d'accès côté est
	_slab(-8.5, 8.5, -19.5, -17.7, 4.5, WOOD)
	_slab(6.6, 8.5, -17.7, -16.4, 4.5, WOOD)
	_ramp(Vector3(7.5, 0, -9.2), Vector3(7.5, 4.5, -16.4), 1.8, WOOD)
	_box(Vector3(-0.95, 5.0, -17.65), Vector3(15.1, 1.0, 0.1), DARK_WOOD)  # garde-corps
	# Bannières
	_deco(Vector3(-7, 5, -8.5), Vector3(0.15, 3.5, 1.2), BANNER)
	_deco(Vector3(-7, 5, -19.4), Vector3(1.2, 3.5, 0.15), BANNER)
	_deco(Vector3(0, 6, -19.4), Vector3(1.6, 3.5, 0.15), BANNER)


# ---------------------------------------------------------------- aile royale

func _build_royal_wing() -> void:
	var cx := 14.0
	var cz := 0.0
	var ops := {
		"w": [_op(-3.0, 2.4, 0.0, 3.0), _op(2.5, 1.2, 1.3, 1.3), _op(5.0, 1.2, 4.8, 1.3)],
		"s": [_op(2.0, 2.4, 0.0, 3.0), _op(-2.5, 1.2, 4.8, 1.3), _op(4.0, 1.2, 4.8, 1.3)],
		"n": [_op(-2.5, 1.2, 1.3, 1.3), _op(2.5, 1.2, 1.3, 1.3), _op(0.0, 1.6, 4.8, 1.3)],
		"e": [_op(-3.0, 1.2, 1.3, 1.3), _op(3.0, 1.2, 1.3, 1.3), _op(0.0, 1.6, 4.8, 1.3)],
	}
	_room(cx, cz, 10, 14, 7, 0.5, STONE, ROOF, ops, Color(0.3, 0.22, 0.15))
	# Étage à y = 3.8, trappe au-dessus de la rampe (ouest de la pièce)
	_floor_with_hole(9.5, 18.5, -6.5, 6.5, 3.8, 9.5, 11.5, -1.0, 3.2, WOOD)
	_ramp(Vector3(10.4, 0, 5.8), Vector3(10.4, 3.8, -1.0), 2.0, WOOD)
	# Mobilier
	_box(Vector3(17, 0.45, 4), Vector3(2.2, 0.5, 3.0), WOOD)
	_box(Vector3(17, 0.45, -4), Vector3(2.2, 0.5, 3.0), WOOD)
	_box(Vector3(17, 4.25, -4), Vector3(2.2, 0.5, 3.0), WOOD)
	_box(Vector3(17, 4.25, 4), Vector3(2.2, 0.5, 3.0), WOOD)
	_box(Vector3(13.5, 0.4, 0), Vector3(2.0, 0.8, 2.0), DARK_WOOD)


# ---------------------------------------------------------------- cachots

func _build_dungeons() -> void:
	var cx := 14.0
	var cz := 19.0
	var ops := {
		"n": [_op(0.0, 2.4, 0.0, 2.8)],
		"s": [_op(-3.0, 0.5, 2.0, 0.8), _op(3.0, 0.5, 2.0, 0.8)],
	}
	_room(cx, cz, 12, 9, 3.6, 0.5, DARK_STONE, DARK_STONE, ops, Color(0.2, 0.19, 0.18))
	# Cellules : cloisons avec une porte chacune
	_wall(Vector3(11.0, 0, cz), false, 8.0, 3.6, 0.35, DARK_STONE, [_op(0.0, 1.4, 0.0, 2.4)])
	_wall(Vector3(17.0, 0, cz), false, 8.0, 3.6, 0.35, DARK_STONE, [_op(0.0, 1.4, 0.0, 2.4)])
	for z in [16.0, 22.0]:
		_deco(Vector3(11.0, 1.5, z), Vector3(0.1, 2.2, 0.1), IRON)
		_deco(Vector3(17.0, 1.5, z), Vector3(0.1, 2.2, 0.1), IRON)
	# Rampe vers le toit (toit : y = 3.9)
	_ramp(Vector3(6.6, 0, 25.0), Vector3(6.6, 3.9, 14.5), 2.0)


# ---------------------------------------------------------------- cuisine

func _build_kitchen() -> void:
	var cx := -14.0
	var cz := 2.0
	var ops := {
		"e": [_op(0.0, 2.6, 0.0, 3.0), _op(-3.5, 1.2, 1.5, 1.3)],
		"s": [_op(-2.0, 2.0, 0.0, 2.8)],
		"n": [_op(-2.0, 1.2, 1.5, 1.3), _op(2.0, 1.2, 1.5, 1.3)],
		"w": [_op(0.0, 1.2, 1.5, 1.3)],
	}
	_room(cx, cz, 9, 12, 6, 0.5, STONE, WOOD, ops, Color(0.27, 0.22, 0.18))
	_box(Vector3(-14.5, 0.7, 3), Vector3(4, 0.4, 3), WOOD)  # grande table
	_box(Vector3(-16, 0.5, -2), Vector3(2, 0.9, 2), WOOD)
	_box(Vector3(-17.6, 1.0, 6), Vector3(1.4, 2.0, 3), DARK_STONE)  # âtre
	_box(Vector3(-17.6, 7.2, 6), Vector3(1.2, 2.6, 1.2), DARK_STONE)  # cheminée


# ---------------------------------------------------------------- donjon (3 niveaux)

func _build_keep() -> void:
	var cx := -19.0
	var cz := -17.0
	var t := 0.6
	var slit_w := 0.6
	var ops := {
		"e": [_op(0.0, 2.4, 0.0, 3.0), _op(3.0, slit_w, 7.0, 1.4), _op(-3.0, slit_w, 12.5, 1.4)],
		"n": [_op(-2.0, slit_w, 2.5, 1.4), _op(2.0, slit_w, 7.0, 1.4), _op(0.0, 1.0, 12.5, 1.6)],
		"s": [_op(-2.0, slit_w, 2.5, 1.4), _op(2.0, slit_w, 7.0, 1.4), _op(0.0, 1.0, 12.5, 1.6)],
		"w": [_op(0.0, slit_w, 2.5, 1.4), _op(-2.0, 1.0, 7.0, 1.6), _op(2.0, 1.0, 12.5, 1.6)],
	}
	# Murs montés à 17.2 : parapet de 1.2 m au-dessus de la terrasse (y = 16)
	_room(cx, cz, 9, 9, 17.2, t, STONE, NO_COLOR, ops, Color(0.25, 0.22, 0.2))
	var x0 := cx - 4.5 + t
	var x1 := cx + 4.5 - t
	var z0 := cz - 4.5 + t
	var z1 := cz + 4.5 - t
	# Rampes : O (sol -> 5.3), E (5.3 -> 10.6), O (10.6 -> 16)
	var rw := cx - 2.8
	var re := cx + 2.8
	_ramp(Vector3(rw, 0, cz + 4.4), Vector3(rw, 5.3, cz - 4.4), 2.0)
	_ramp(Vector3(re, 5.3, cz - 4.4), Vector3(re, 10.6, cz + 4.4), 2.0)
	_ramp(Vector3(rw, 10.6, cz + 4.4), Vector3(rw, 16.0, cz - 4.4), 2.0)
	# Planchers avec trappes
	_floor_with_hole(x0, x1, z0, z1, 5.3, x0, cx - 1.8, z0, cz + 0.0, WOOD)
	_floor_with_hole(x0, x1, z0, z1, 10.6, cx + 1.8, x1, cz - 0.8, z1, WOOD)
	_floor_with_hole(x0, x1, z0, z1, 16.0, x0, cx - 1.8, z0, cz - 0.4, ROOF)
	# Drapeau au sommet
	_deco(Vector3(cx, 19.0, cz), Vector3(0.14, 5.0, 0.14), IRON)
	_deco(Vector3(cx + 0.8, 20.2, cz), Vector3(1.5, 1.6, 0.05), BANNER)


# ---------------------------------------------------------------- couvert & accessoires

func _build_cover_and_props() -> void:
	for pos in [Vector3(-3, 0.5, 20), Vector3(-4, 0.5, 20.3), Vector3(3, 0.5, 20), Vector3(4, 0.5, 19.7), Vector3(-8, 0.5, -2), Vector3(6, 0.5, 4)]:
		_cyl(pos, 0.48, 1.0, WOOD)
	for pos in [Vector3(6, 0.45, 9), Vector3(7, 0.45, 9.3), Vector3(6.5, 0.95, 9.1), Vector3(-8, 0.45, 6), Vector3(-12, 0.45, -9)]:
		_box(pos, Vector3(0.9, 0.9, 0.9), WOOD)
	# Muret de couvert
	_box(Vector3(-8, 0.7, -5), Vector3(0.6, 1.4, 5), STONE)


func _build_lighting() -> void:
	var positions := [
		Vector3(0, 5, 8), Vector3(0, 5, 23), Vector3(0, 6, -14),
		Vector3(14, 2.5, 0), Vector3(14, 6, 0), Vector3(-14, 4, 2),
		Vector3(14, 2.5, 19), Vector3(-19, 3, -17), Vector3(-19, 8, -17), Vector3(-19, 13, -17),
	]
	for pos in positions:
		var light := OmniLight3D.new()
		light.position = pos
		light.light_color = Color(1.0, 0.65, 0.3)
		light.light_energy = 1.5
		light.omni_range = 9.0
		light.shadow_enabled = false
		add_child(light)


func _add_map_spawns() -> void:
	var spawns := Node3D.new()
	spawns.name = "MapSpawns"
	add_child(spawns)
	var positions := [
		Vector3(0, 1, 10),      # cour
		Vector3(-11, 1, 2),     # cuisine
		Vector3(14, 1, -2),     # aile royale, rez-de-chaussée
		Vector3(0, 1, -10.5),   # grande salle
		Vector3(14, 1, 19),     # cachots
		Vector3(-17, 1, -17),   # donjon
		Vector3(0, 1, 23),      # près de la porte
		Vector3(-20, 1, 14),    # cour ouest
		Vector3(15, 4.6, -2),   # aile royale, étage
	]
	for i in positions.size():
		var m := Marker3D.new()
		m.name = "Spawn%d" % i
		m.position = positions[i]
		spawns.add_child(m)
