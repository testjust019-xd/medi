extends Node3D
## Greybox — cour médiévale améliorée pour cache-cache + parkour.
## Plus de verticalité, cachettes, ledges, toits accessibles, couloirs.
## Style low-poly: primitives + matériaux partagés (performant).

const WALL_HEIGHT := 7.0
const GROUND_SIZE := 48.0
const HALF := GROUND_SIZE / 2.0

# Palette
const COL_GROUND := Color(0.34, 0.31, 0.27)
const COL_STONE := Color(0.48, 0.46, 0.42)
const COL_DARK_STONE := Color(0.36, 0.34, 0.31)
const COL_WOOD := Color(0.42, 0.28, 0.17)
const COL_ROOF := Color(0.32, 0.13, 0.09)
const COL_BARREL := Color(0.38, 0.24, 0.12)
const COL_HAY := Color(0.55, 0.48, 0.28)
const COL_CRATE := Color(0.45, 0.32, 0.18)


func _ready() -> void:
	_build_ground()
	_build_walls()
	_build_main_buildings()
	_build_parkour_structures()
	_build_cover_and_hiding()
	_build_lighting()
	_add_spawn_hints()  # marqueurs visuels optionnels


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────
var _mats: Dictionary = {}

func _mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.72
		m.metalness = 0.0
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


# ─────────────────────────────────────────────
# Sol & murs d'enceinte
# ─────────────────────────────────────────────
func _build_ground() -> void:
	_box(Vector3(0, -0.1, 0), Vector3(GROUND_SIZE, 0.2, GROUND_SIZE), COL_GROUND)

	# Quelques zones de terre / herbe pour casser le plat
	_box(Vector3(-12, -0.05, 12), Vector3(10, 0.12, 8), Color(0.32, 0.36, 0.24))
	_box(Vector3(14, -0.05, -10), Vector3(8, 0.12, 10), Color(0.33, 0.35, 0.25))


func _build_walls() -> void:
	var h := WALL_HEIGHT
	var half := HALF

	# Murs principaux
	_box(Vector3(0, h/2, -half), Vector3(GROUND_SIZE, h, 1.2), COL_DARK_STONE)
	_box(Vector3(0, h/2, half), Vector3(GROUND_SIZE, h, 1.2), COL_DARK_STONE)
	_box(Vector3(-half, h/2, 0), Vector3(1.2, h, GROUND_SIZE), COL_DARK_STONE)
	_box(Vector3(half, h/2, 0), Vector3(1.2, h, GROUND_SIZE), COL_DARK_STONE)

	# Tours d'angle (climbables)
	for pos in [
		Vector3(-half + 1.5, 0, -half + 1.5),
		Vector3(half - 1.5, 0, -half + 1.5),
		Vector3(-half + 1.5, 0, half - 1.5),
		Vector3(half - 1.5, 0, half - 1.5)
	]:
		_cyl(Vector3(pos.x, h * 0.55, pos.z), 2.2, h * 1.1, COL_DARK_STONE)
		_cyl(Vector3(pos.x, h * 1.15, pos.z), 2.5, 1.4, COL_ROOF)

	# Ouvertures / portes (trous dans les murs via absence)
	# Porte nord
	_box(Vector3(-4, 1.6, -half), Vector3(3.5, 3.2, 1.4), COL_WOOD)  # porte fermée visuelle
	# Porte est (ouverte conceptuellement — on laisse un passage latéral)
	# On crée des murets bas près des portes pour le parkour
	_box(Vector3(0, 0.6, -half + 2.5), Vector3(8, 1.2, 0.8), COL_STONE)


# ─────────────────────────────────────────────
# Bâtiments principaux
# ─────────────────────────────────────────────
func _build_main_buildings() -> void:
	# === 1. Grande maison (NW) — toit accessible ===
	_box(Vector3(-11, 1.6, -11), Vector3(9, 3.2, 7), COL_STONE)
	_box(Vector3(-11, 3.5, -11), Vector3(9.6, 0.9, 7.6), COL_ROOF)
	# Ledge / balcon côté cour
	_box(Vector3(-11, 2.9, -6.8), Vector3(5, 0.25, 1.2), COL_WOOD)
	# Escaliers / blocs pour monter
	_box(Vector3(-6.5, 0.4, -7.5), Vector3(1.4, 0.8, 1.8), COL_STONE)
	_box(Vector3(-6.5, 1.0, -8.2), Vector3(1.4, 0.8, 1.4), COL_STONE)

	# === 2. Tour ronde (NE) — grimpable ===
	_cyl(Vector3(11, 3.5, -11), 2.4, 7.0, COL_STONE)
	_cyl(Vector3(11, 7.3, -11), 2.7, 1.3, COL_ROOF)
	# Plateforme intermédiaire
	_box(Vector3(11, 3.8, -8.5), Vector3(3.5, 0.3, 1.5), COL_WOOD)
	# Blocs d'accès
	_box(Vector3(8.5, 0.45, -9.5), Vector3(1.3, 0.9, 1.5), COL_STONE)
	_box(Vector3(9.2, 1.1, -10.2), Vector3(1.3, 0.9, 1.3), COL_STONE)

	# === 3. Cabane basse (SE) — cachette + toit bas vaultable ===
	_box(Vector3(12, 1.1, 11), Vector3(5.5, 2.2, 5.5), COL_WOOD)
	_box(Vector3(12, 2.4, 11), Vector3(6.0, 0.45, 6.0), COL_ROOF)
	# Petite extension ouverte
	_box(Vector3(8.5, 0.7, 11), Vector3(2.5, 1.4, 3.5), COL_WOOD)

	# === 4. Marché couvert (SW) ===
	_box(Vector3(-11, 0.55, 11), Vector3(8, 1.1, 6), COL_WOOD)
	_box(Vector3(-11, 2.6, 11), Vector3(8.5, 0.25, 6.5), Color(0.28, 0.12, 0.08))
	# Piliers
	for x in [-14.0, -8.0]:
		for z in [8.5, 13.5]:
			_cyl(Vector3(x,  exp Syn 1.4, z), 0.35, 2.8, COL_WOOD)

	# === 5. Petit entrepôt central-est ===
	_box(Vector3(4, 1.3, 2), Vector3(4.5, 2.6, 4), COL_STONE)
	_box(Vector3(4, 2.8, 2), Vector3(5, 0.5, 4.5), COL_ROOF)


# ─────────────────────────────────────────────
# Structures parkour (ledges, murets, plateformes)
# ─────────────────────────────────────────────
func _build_parkour_structures() -> void:
	# Murets bas au centre (vault + cover)
	_box(Vector3(0, 0.55, 0), Vector3(7, 1.1, 0.7), COL_STONE)
	_box(Vector3(0, 0.55, 4.5), Vector3(0.7, 1.1, 5), COL_STONE)
	_box(Vector3(-3, 0.55, -3), Vector3(4, 1.1, 0.7), COL_STONE)

	# Enfilade de blocs pour wall-run / climb
	_box(Vector3(-16, 1.2, 0), Vector3(1.2, 2.4, 6), COL_DARK_STONE)
	_box(Vector3(16, 1.2, 2), Vector3(1.2, 2.4, 7), COL_DARK_STONE)

	# Plateformes en hauteur (toits secondaires)
	_box(Vector3(-4, 3.2, 8), Vector3(4, 0.3, 3), COL_WOOD)
	_box(Vector3(6, 2.6, -4), Vector3(3.5, 0.3, 3), COL_WOOD)

	# Escaliers de pierre (accès toits)
	_build_stair(Vector3(-14, 0, -4), 5, Vector3(1.2, 0.45, 1.4), COL_STONE)
	_build_stair(Vector3(14, 0, 6), 4, Vector3(1.2, 0.45, 1.4), COL_STONE)

	# Ledges le long des murs d'enceinte (wall-run friendly)
	_box(Vector3(0, 2.8, -HALF + 1.0), Vector3(18, 0.3, 0.9), COL_STONE)
	_box(Vector3(0, 2.8, HALF - 1.0), Vector3(14, 0.3, 0.9), COL_STONE)


func _build_stair(start: Vector3, steps: int, step_size: Vector3, color: Color) -> void:
	for i in range(steps):
		var pos := start + Vector3(0, step_size.y * (i + 0.5), step_size.z * i * 0.85)
		_box(pos, step_size, color)


# ─────────────────────────────────────────────
# Cachettes & cover
# ─────────────────────────────────────────────
func _build_cover_and_hiding() -> void:
	# Tonneaux (groupes)
	var barrel_groups := [
		[Vector3(-5, 0.5, 5), Vector3(-4, 0.5, 5.5), Vector3(-5.5, 0.5, 4.2)],
		[Vector3(5, 0.5, -5), Vector3(6, 0.5, -4.5), Vector3(4.5, 0.5, -6)],
		[Vector3(9, 0.5, 6), Vector3(10, 0.5, 6.5)],
		[Vector3(-8, 0.5, -3), Vector3(-7, 0.5, -3.5)],
		[Vector3(0, 0.5, 12), Vector3(1, 0.5, 12.5), Vector3(-1, 0.5, 11.5)],
	]
	for group in barrel_groups:
		for pos in group:
			_cyl(pos, 0.48, 1.0, COL_BARREL)

	# Caisses
	var crates := [
		Vector3(2, 0.45, -7), Vector3(3.1, 0.45, -7.2),
		Vector3(-13, 0.45, 6), Vector3(-12, 0.45, 5.5),
		Vector3(7, 0.45, 3), Vector3(7.8, 0.9, 3.2),  # empilée
	]
	for pos in crates:
		_box(pos, Vector3(0.9, 0.9, 0.9), COL_CRATE)

	# Meules de foin / bottes
	_cyl(Vector3(-15, 0.7, 14), 1.1, 1.4, COL_HAY)
	_cyl(Vector3(-13.5, 0.7, 15), 0.9, 1.3, COL_HAY)
	_cyl(Vector3(15, 0.7, -15), 1.0, 1.35, COL_HAY)

	# Petits murs de couverture isolés
	_box(Vector3(0, 0.7, -12), Vector3(5, 1.4, 0.6), COL_STONE)
	_box(Vector3(8, 0.7, 0), Vector3(0.6, 1.4, 4), COL_STONE)
	_box(Vector3(-7, 0.7, 3), Vector3(3.5, 1.4, 0.6), COL_STONE)


# ─────────────────────────────────────────────
# Éclairage
# ─────────────────────────────────────────────
func _build_lighting() -> void:
	var torch_positions := [
		Vector3(-HALF + 2, 3.2, 0),
		Vector3(HALF - 2, 3.2, 0),
		Vector3(0, 3.2, -HALF + 2),
		Vector3(0, 3.2, HALF - 2),
		Vector3(-11, 3.8, -7),
		Vector3(11, 4.5, -9),
		Vector3(4, 3.2, 2),
		Vector3(-8, 2.8, 11),
	]
	for pos in torch_positions:
		var light := OmniLight3D.new()
		light.position = pos
		light.light_color = Color(1.0, 0.68, 0.32)
		light.light_energy = 1.8
		light.omni_range = 9.0
		light.omni_attenuation = 1.4
		light.shadow_enabled = false
		add_child(light)

	# Légère lumière ambiante directionnelle (simule le ciel)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 0.55
	sun.light_color = Color(1.0, 0.95, 0.88)
	sun.shadow_enabled = false
	add_child(sun)


# ─────────────────────────────────────────────
# Points de spawn (utiles pour debug / futur)
# ─────────────────────────────────────────────
func _add_spawn_hints() -> void:
	# Ces nœuds peuvent être utilisés plus tard par MatchManager
	var spawns := Node3D.new()
	spawns.name = "MapSpawns"
	add_child(spawns)

	var positions := [
		Vector3(0, 1, 8),
		Vector3(-10, 1, 0),
		Vector3(10, 1, 0),
		Vector3(0, 1, -10),
		Vector3(8, 1, 8),
		Vector3(-8, 1, -8),
	]
	for i in range(positions.size()):
		var marker := Marker3D.new()
		marker.name = "Spawn%d" % i
		marker.position = positions[i]
		spawns.add_child(marker)
