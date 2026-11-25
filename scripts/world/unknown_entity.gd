extends CharacterBody3D
## THE UNKNOWN — entité rare autonome (squelette sans API IA).

enum Phase { HIDDEN, WANDERING, OBSERVING, TALKING, LEAVING }
@export var move_speed: float = 1.6
@export var detect_radius: float = 4.0
var phase: Phase = Phase.HIDDEN
var phase_timer: float = 0.0
var waypoints: Array[Vector3] = []
var wp_index: int = 0
var met_players: Dictionary = {}
var identity_name: String = "Voyageur"
var archetype: String = "traveler"
var _mesh: MeshInstance3D
var _label: Label3D
var _rng := RandomNumberGenerator.new()
const ARCHETYPES := [
	{"id": "traveler", "name": "Le Voyageur", "color": Color(0.35, 0.32, 0.4)},
	{"id": "watcher", "name": "Le Veilleur", "color": Color(0.25, 0.28, 0.35)},
	{"id": "nameless", "name": "Le Sans-Nom", "color": Color(0.4, 0.4, 0.42)},
	{"id": "chronicler", "name": "Le Chroniqueur", "color": Color(0.3, 0.35, 0.28)},
]
func _ready() -> void:
	_rng.randomize()
	_pick_identity()
	_build_visual()
	visible = false
	set_physics_process(false)
	add_to_group("unknown_entity")
func _pick_identity() -> void:
	var a: Dictionary = ARCHETYPES[_rng.randi() % ARCHETYPES.size()]
	archetype = a["id"]
	identity_name = a["name"]
func _build_visual() -> void:
	_mesh = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.5
	_mesh.mesh = cap
	_mesh.position = Vector3(0, 0.75, 0)
	var mat := StandardMaterial3D.new()
	for a in ARCHETYPES:
		if a["id"] == archetype:
			mat.albedo_color = a["color"]
			break
	mat.roughness = 0.6
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.3
	mat.emission_energy_multiplier = 0.4
	_mesh.material_override = mat
	add_child(_mesh)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.5
	col.shape = shape
	col.position = Vector3(0, 0.75, 0)
	add_child(col)
	_label = Label3D.new()
	_label.text = "???"
	_label.position = Vector3(0, 1.9, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 16
	_label.modulate = Color(0.8, 0.75, 0.9)
	add_child(_label)
func activate(spawn_pos: Vector3, points: Array[Vector3]) -> void:
	global_position = spawn_pos
	waypoints = points
	wp_index = 0
	visible = true
	set_physics_process(true)
	phase = Phase.WANDERING
	phase_timer = _rng.randf_range(40.0, 90.0)
	_label.text = "???"
	print("[UNKNOWN] %s appears (%s)" % [identity_name, archetype])
	var mem := get_node_or_null("/root/WorldMemory")
	if mem and mem.has_method("record_npc_fact"):
		mem.record_npc_fact("unknown_" + archetype, "appeared")
func deactivate() -> void:
	phase = Phase.HIDDEN
	visible = false
	set_physics_process(false)
	print("[UNKNOWN] leaves the region")
func _physics_process(delta: float) -> void:
	phase_timer -= delta
	if phase_timer <= 0.0 and phase != Phase.TALKING:
		if phase == Phase.LEAVING or phase == Phase.WANDERING:
			deactivate()
			return
		phase = Phase.LEAVING
		phase_timer = 8.0
	match phase:
		Phase.WANDERING:
			_wander(delta)
			_check_player_near()
		Phase.OBSERVING:
			velocity = Vector3.ZERO
			if phase_timer <= 0.0:
				phase = Phase.WANDERING
				phase_timer = _rng.randf_range(20.0, 40.0)
		Phase.TALKING:
			velocity = Vector3.ZERO
		Phase.LEAVING:
			_wander(delta)
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()
func _wander(delta: float) -> void:
	if waypoints.is_empty():
		return
	var target := waypoints[wp_index]
	var to := target - global_position
	to.y = 0
	if to.length() < 0.8:
		wp_index = (wp_index + 1) % waypoints.size()
		if _rng.randf() < 0.3:
			phase = Phase.OBSERVING
			phase_timer = _rng.randf_range(3.0, 8.0)
		return
	var dir := to.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	_mesh.rotation.y = lerp_angle(_mesh.rotation.y, atan2(dir.x, dir.z), delta * 4.0)
func _check_player_near() -> void:
	for p in get_tree().get_nodes_in_group("players"):
		if is_instance_valid(p) and global_position.distance_to(p.global_position) < detect_radius:
			_on_player_near(p)
			return
func _on_player_near(player: Node) -> void:
	var pname := str(player.get("player_name") if player.get("player_name") else player.name)
	var count := int(met_players.get(pname, 0))
	met_players[pname] = count + 1
	phase = Phase.OBSERVING
	phase_timer = 5.0
	_label.text = identity_name
	print("[UNKNOWN] Meeting %s (x%d) with %s" % [pname, count + 1, identity_name])
	var mem := get_node_or_null("/root/WorldMemory")
	if mem and mem.has_method("record_npc_fact"):
		mem.record_npc_fact("unknown_" + archetype, "met_" + pname)
func try_talk(player: Node) -> String:
	var pname := str(player.get("player_name") if player.get("player_name") else "étranger")
	var count := int(met_players.get(pname, 0))
	phase = Phase.TALKING
	phase_timer = 6.0
	var lines: Array[String] = []
	match archetype:
		"traveler":
			lines = ["Les routes de Valdoria changent quand on ne les regarde pas.", "Je ne reste jamais longtemps. Toi non plus, peut-être.", "On m'a parlé d'un village qui n'est sur aucune carte…"]
		"watcher":
			lines = ["…", "Je regarde. C'est tout.", "Tu as l'air de chercher quelque chose."]
		"nameless":
			lines = ["Un nom n'est qu'une porte. Je préfère les murs.", "Ne demande pas qui je suis.", "Les registres se trompent souvent."]
		"chronicler":
			lines = ["J'écris ce que les autres oublient.", "Ce procès… j'en ai déjà vu d'autres.", "Valdoria a une mémoire. Moi aussi."]
		_:
			lines = ["…"]
	var mem := get_node_or_null("/root/WorldMemory")
	if mem and mem.has_method("has_flag") and mem.has_flag("condemned_helped"):
		lines.append("On dit que tu as aidé quelqu'un sur la place. Les murs ont des oreilles.")
	if count > 1:
		lines.append("On se revoit. C'est rare, pour moi.")
	var line: String = lines[_rng.randi() % lines.size()]
	print("[UNKNOWN] \"%s\"" % line)
	return line
