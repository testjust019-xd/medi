extends CharacterBody3D
## NPC — villageois avec routines simples.
## FSM: IDLE → PATROL → REACT → IDLE.
## Les PNJ ne révèlent JAMAIS la position des fugitifs (règle du GDD).

enum State { IDLE, PATROL, REACT }

var state: State = State.IDLE
var patrol_points: Array[Vector3] = []
var current_point: int = 0
var state_timer: float = 0.0
var npc_type: int = 0  # 0=villager, 1=merchant, 2=guard_npc, 3=farmer
var walk_speed: float = 1.5
var react_target: Vector3 = Vector3.ZERO

@onready var mesh: MeshInstance3D = $Body
@onready var name_label: Label3D = $NameLabel

const GRAVITY: float = 9.8
const NPC_NAMES := ["Villager", "Merchant", "Guard", "Farmer", "Baker", "Smith"]


func _ready() -> void:
	name_label.text = NPC_NAMES[npc_type % NPC_NAMES.size()]
	_apply_type_color()
	state_timer = randf_range(1.0, 4.0)  # idle initial


func _apply_type_color() -> void:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.7
	match npc_type:
		0: mat.albedo_color = Color(0.5, 0.4, 0.3)  # villager: brun
		1: mat.albedo_color = Color(0.6, 0.5, 0.2)  # merchant: doré
		2: mat.albedo_color = Color(0.3, 0.3, 0.4)  # guard: bleu-gris
		3: mat.albedo_color = Color(0.4, 0.5, 0.3)  # farmer: vert
		_: mat.albedo_color = Color(0.5, 0.5, 0.5)
	mesh.material_override = mat


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	state_timer -= delta

	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, delta * 5.0)
			velocity.z = move_toward(velocity.z, 0, delta * 5.0)
			if state_timer <= 0.0:
				_start_patrol()

		State.PATROL:
			if patrol_points.is_empty():
				state = State.IDLE
				state_timer = randf_range(2.0, 5.0)
				return
			var target := patrol_points[current_point]
			var to := target - global_position
			to.y = 0
			var dist := to.length()
			if dist < 0.5:
				current_point = (current_point + 1) % patrol_points.size()
				state = State.IDLE
				state_timer = randf_range(1.0, 3.0)
			else:
				var dir := to.normalized()
				velocity.x = dir.x * walk_speed
				velocity.z = dir.z * walk_speed
				# Tourner vers la direction
				mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(dir.x, dir.z), delta * 5.0)

		State.REACT:
			velocity.x = move_toward(velocity.x, 0, delta * 5.0)
			velocity.z = move_toward(velocity.z, 0, delta * 5.0)
			# Regarder vers l'événement
			var to_event := react_target - global_position
			if to_event.length() > 0.1:
				mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(to_event.x, to_event.z), delta * 3.0)
			if state_timer <= 0.0:
				state = State.IDLE
				state_timer = randf_range(2.0, 4.0)

	move_and_slide()


## Appelé par npc_manager quand un événement (capture) se produit à proximité
func react_to_event(event_pos: Vector3) -> void:
	# Les PNJ regardent vers l'événement mais NE révèlent PAS les positions
	react_target = event_pos
	state = State.REACT
	state_timer = randf_range(2.0, 4.0)


func set_patrol_points(points: Array[Vector3]) -> void:
	patrol_points = points
	if not points.is_empty():
		current_point = randi() % points.size()


func _start_patrol() -> void:
	if patrol_points.is_empty():
		state = State.IDLE
		state_timer = randf_range(2.0, 5.0)
	else:
		state = State.PATROL
