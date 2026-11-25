extends CharacterBody3D
## NPC — routines par rôle, un peu plus vivant.
enum State { IDLE, PATROL, WORK, REACT, PANIC }
var state: State = State.IDLE
var patrol_points: Array[Vector3] = []
var work_point: Vector3 = Vector3.ZERO
var has_work_point: bool = false
var current_point: int = 0
var state_timer: float = 0.0
var npc_type: int = 0
var walk_speed: float = 1.5
var react_target: Vector3 = Vector3.ZERO
var home_center: Vector3 = Vector3.ZERO
var home_radius: float = 8.0
@onready var mesh: MeshInstance3D = $Body
@onready var name_label: Label3D = $NameLabel
const GRAVITY: float = 9.8
const NPC_NAMES := [["Aldric", "Bram", "Cora", "Dina", "Edric"],["Mira", "Tobin", "Selene", "Garr", "Lysa"],["Ser Kael", "Ser Ryn", "Ser Voss", "Ser Ina", "Ser Holt"],["Petyr", "Ned", "Bess", "Tom", "Willa"]]
func _ready() -> void:
	var names: Array = NPC_NAMES[npc_type % NPC_NAMES.size()]
	name_label.text = names[randi() % names.size()]
	_apply_type_color()
	_apply_type_stats()
	state_timer = randf_range(1.0, 3.5)
	home_center = global_position
func _apply_type_color() -> void:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.7
	match npc_type:
		0: mat.albedo_color = Color(0.52, 0.40, 0.30)
		1: mat.albedo_color = Color(0.62, 0.50, 0.22)
		2: mat.albedo_color = Color(0.32, 0.34, 0.42)
		3: mat.albedo_color = Color(0.40, 0.50, 0.30)
		_: mat.albedo_color = Color(0.5, 0.5, 0.5)
	mesh.material_override = mat
func _apply_type_stats() -> void:
	match npc_type:
		0: walk_speed = 1.4
		1: walk_speed = 1.1
		2: walk_speed = 1.7
		3: walk_speed = 1.3
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	state_timer -= delta
	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, delta * 5.0)
			velocity.z = move_toward(velocity.z, 0, delta * 5.0)
			if state_timer <= 0.0:
				_pick_next_behavior()
		State.PATROL:
			_move_toward_patrol(delta)
		State.WORK:
			velocity.x = move_toward(velocity.x, 0, delta * 4.0)
			velocity.z = move_toward(velocity.z, 0, delta * 4.0)
			if has_work_point:
				var to := work_point - global_position
				to.y = 0
				if to.length() > 1.2:
					var dir := to.normalized()
					velocity.x = dir.x * walk_speed * 0.6
					velocity.z = dir.z * walk_speed * 0.6
					mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(dir.x, dir.z), delta * 4.0)
			if state_timer <= 0.0:
				state = State.IDLE
				state_timer = randf_range(1.5, 3.0)
		State.REACT:
			velocity.x = move_toward(velocity.x, 0, delta * 5.0)
			velocity.z = move_toward(velocity.z, 0, delta * 5.0)
			var to_event := react_target - global_position
			if to_event.length() > 0.1:
				mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(to_event.x, to_event.z), delta * 3.0)
			if state_timer <= 0.0:
				state = State.IDLE
				state_timer = randf_range(1.5, 3.5)
		State.PANIC:
			if state_timer > 1.0:
				var dir := Vector3(sin(state_timer * 3.0), 0, cos(state_timer * 2.0)).normalized()
				velocity.x = dir.x * walk_speed * 1.8
				velocity.z = dir.z * walk_speed * 1.8
				mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(dir.x, dir.z), delta * 8.0)
			else:
				velocity.x = move_toward(velocity.x, 0, delta * 6.0)
				velocity.z = move_toward(velocity.z, 0, delta * 6.0)
			if state_timer <= 0.0:
				state = State.IDLE
				state_timer = randf_range(2.0, 4.0)
	var from_home := global_position - home_center
	from_home.y = 0
	if from_home.length() > home_radius + 2.0 and state != State.PANIC:
		var back := -from_home.normalized()
		velocity.x = back.x * walk_speed
		velocity.z = back.z * walk_speed
	move_and_slide()
func _move_toward_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		state = State.IDLE
		state_timer = randf_range(2.0, 4.0)
		return
	var target := patrol_points[current_point]
	var to := target - global_position
	to.y = 0
	var dist := to.length()
	if dist < 0.6:
		current_point = (current_point + 1) % patrol_points.size()
		state = State.IDLE
		state_timer = randf_range(0.5, 3.0) if npc_type == 2 else randf_range(1.5, 4.0)
	else:
		var dir := to.normalized()
		velocity.x = dir.x * walk_speed
		velocity.z = dir.z * walk_speed
		mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(dir.x, dir.z), delta * 5.0)
func _pick_next_behavior() -> void:
	match npc_type:
		1:
			if has_work_point and randf() < 0.7:
				state = State.WORK
				state_timer = randf_range(4.0, 10.0)
			else:
				_start_patrol()
		2:
			_start_patrol()
		3:
			if has_work_point and randf() < 0.5:
				state = State.WORK
				state_timer = randf_range(3.0, 8.0)
			else:
				_start_patrol()
		_:
			if randf() < 0.65:
				_start_patrol()
			else:
				state = State.IDLE
				state_timer = randf_range(2.0, 5.0)
func react_to_event(event_pos: Vector3) -> void:
	react_target = event_pos
	if npc_type == 2:
		state = State.REACT
		state_timer = randf_range(3.0, 5.0)
	elif randf() < 0.25:
		state = State.PANIC
		state_timer = randf_range(2.5, 4.5)
	else:
		state = State.REACT
		state_timer = randf_range(2.0, 3.5)
func set_patrol_points(points: Array[Vector3]) -> void:
	patrol_points = points
	if not points.is_empty():
		current_point = randi() % points.size()
func set_work_point(pos: Vector3) -> void:
	work_point = pos
	has_work_point = true
func set_home(center: Vector3, radius: float) -> void:
	home_center = center
	home_radius = radius
func _start_patrol() -> void:
	if patrol_points.is_empty():
		state = State.IDLE
		state_timer = randf_range(2.0, 5.0)
	else:
		state = State.PATROL
