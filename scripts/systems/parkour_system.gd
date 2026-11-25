extends Node3D
## ParkourSystem — version améliorée + tree climb
## États: CLIMB, VAULT, SLIDE, WALL_RUN, TREE_CLIMB

enum ParkourState { NONE, CLIMBING, VAULTING, SLIDING, WALL_RUNNING, TREE_CLIMBING }

var state: ParkourState = ParkourState.NONE
var state_timer: float = 0.0

@onready var fwd_ray: RayCast3D = $ForwardRay
@onready var high_ray: RayCast3D = $HighRay
@onready var down_ray: RayCast3D = $DownRay
@onready var left_ray: RayCast3D = $LeftRay
@onready var right_ray: RayCast3D = $RightRay

var player: CharacterBody3D
var collision_shape: CollisionShape3D

var climb_speed: float = 3.8
var tree_climb_speed: float = 3.2
var vault_duration: float = 0.38
var slide_duration: float = 0.85
var wall_run_duration: float = 1.35
var wall_run_speed: float = 9.0
var vault_boost: float = 1.6
var min_speed_for_slide: float = 4.0
var min_speed_for_wallrun: float = 3.5
var tree_detect_radius: float = 1.6
var tree_max_height: float = 9.0

var _vault_target: Vector3 = Vector3.ZERO
var _wall_normal: Vector3 = Vector3.ZERO
var _wall_side: int = 0
var _original_shape_height: float = 1.6
var _original_shape_y: float = 0.8
var _slide_dir: Vector3 = Vector3.ZERO
var _tree_body: Node3D = null
var _tree_base_y: float = 0.0


func _ready() -> void:
	player = get_parent() as CharacterBody3D
	collision_shape = player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	for ray in [fwd_ray, high_ray, down_ray, left_ray, right_ray]:
		if ray:
			ray.enabled = true
			ray.collide_with_areas = false
			ray.collide_with_bodies = true


func _physics_process(delta: float) -> void:
	if state != ParkourState.NONE:
		state_timer -= delta
		match state:
			ParkourState.CLIMBING:
				_process_climb(delta)
			ParkourState.VAULTING:
				_process_vault(delta)
			ParkourState.SLIDING:
				_process_slide(delta)
			ParkourState.WALL_RUNNING:
				_process_wall_run(delta)
			ParkourState.TREE_CLIMBING:
				_process_tree_climb(delta)
		if state != ParkourState.TREE_CLIMBING and state_timer <= 0.0:
			_end_parkour()
	else:
		_check_parkour_input(delta)


func _check_parkour_input(_delta: float) -> void:
	if not player.is_multiplayer_authority():
		return
	if player.player_state >= 2:
		return
	if Input.is_action_pressed("crouch") and (Input.is_action_pressed("sprint") or Input.is_action_pressed("run")) and player.velocity.length() > min_speed_for_slide and player.is_on_floor():
		_start_slide()
		return
	if Input.is_action_just_pressed("jump"):
		if _try_tree_climb():
			return
		if _try_vault():
			return
		if _try_climb():
			return
		if _try_wall_run():
			return


func _try_tree_climb() -> bool:
	var tree := _find_nearby_tree()
	if tree == null:
		return false
	_tree_body = tree
	_tree_base_y = tree.global_position.y
	state = ParkourState.TREE_CLIMBING
	state_timer = 99.0
	player.velocity = Vector3.ZERO
	return true


func _find_nearby_tree() -> Node3D:
	var trees := get_tree().get_nodes_in_group("climbable_tree")
	var best: Node3D = null
	var best_dist := tree_detect_radius
	for t in trees:
		if not is_instance_valid(t):
			continue
		var horizontal := Vector2(player.global_position.x - t.global_position.x, player.global_position.z - t.global_position.z).length()
		if horizontal < best_dist and player.global_position.y < t.global_position.y + tree_max_height:
			best_dist = horizontal
			best = t
	return best


func _process_tree_climb(delta: float) -> void:
	if not is_instance_valid(_tree_body):
		_end_parkour()
		return
	var tree_pos := _tree_body.global_position
	var to_tree := tree_pos - player.global_position
	to_tree.y = 0.0
	if to_tree.length() > 0.15:
		player.global_position += to_tree.normalized() * 4.0 * delta
	var up := Input.is_action_pressed("jump") or Input.is_action_pressed("move_forward")
	var down := Input.is_action_pressed("crouch") or Input.is_action_pressed("move_back")
	if up:
		player.velocity.y = tree_climb_speed
	elif down:
		player.velocity.y = -tree_climb_speed * 1.2
	else:
		player.velocity.y = 0.0
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	player.move_and_slide()
	var height_above := player.global_position.y - _tree_base_y
	if height_above > tree_max_height:
		player.global_position.y = _tree_base_y + tree_max_height
		player.velocity.y = 0.0
	if Input.is_action_just_pressed("sprint") or Input.is_action_just_pressed("run"):
		var away := (player.global_position - tree_pos)
		away.y = 0.0
		if away.length() > 0.01:
			player.velocity = away.normalized() * 4.0 + Vector3.UP * 3.0
		_end_parkour()
		return
	if player.is_on_floor() and height_above < 1.2 and not up:
		_end_parkour()


func _try_vault() -> bool:
	if not fwd_ray.is_colliding():
		return false
	if high_ray.is_colliding():
		return false
	var hit_point := fwd_ray.get_collision_point()
	var height_diff := hit_point.y - player.global_position.y
	if height_diff < 0.35 or height_diff > 1.35:
		return false
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	_vault_target = hit_point + Vector3(0, 0.55, 0) + forward * vault_boost
	state = ParkourState.VAULTING
	state_timer = vault_duration
	player.velocity = Vector3.ZERO
	return true


func _process_vault(delta: float) -> void:
	var t := 1.0 - (state_timer / vault_duration)
	player.global_position = player.global_position.lerp(_vault_target, delta * 11.0)
	player.velocity = Vector3.ZERO
	if t > 0.7:
		var forward := (_vault_target - player.global_position)
		forward.y = 0.0
		if forward.length() > 0.1:
			player.velocity = forward.normalized() * 4.5


func _try_climb() -> bool:
	if not player.is_on_floor():
		return false
	if not fwd_ray.is_colliding() or not high_ray.is_colliding():
		return false
	var hit_point := fwd_ray.get_collision_point()
	var height_diff := hit_point.y - player.global_position.y
	if height_diff < 1.2:
		return false
	state = ParkourState.CLIMBING
	state_timer = 2.8
	player.velocity = Vector3.ZERO
	return true


func _process_climb(delta: float) -> void:
	player.velocity = Vector3.ZERO
	player.velocity.y = climb_speed
	if fwd_ray.is_colliding():
		var normal := fwd_ray.get_collision_normal()
		player.velocity.x = -normal.x * 1.2
		player.velocity.z = -normal.z * 1.2
	player.move_and_slide()
	if not high_ray.is_colliding() and not fwd_ray.is_colliding():
		player.velocity.y = 3.5
		var forward := -player.global_transform.basis.z
		forward.y = 0.0
		player.velocity += forward.normalized() * 2.5
		_end_parkour()
		return
	if not fwd_ray.is_colliding() and state_timer < 2.3:
		_end_parkour()


func _try_wall_run() -> bool:
	if player.is_on_floor():
		return false
	if player.velocity.length() < min_speed_for_wallrun:
		return false
	var best_ray: RayCast3D = null
	var side := 0
	if left_ray and left_ray.is_colliding():
		best_ray = left_ray
		side = -1
	elif right_ray and right_ray.is_colliding():
		best_ray = right_ray
		side = 1
	if best_ray == null:
		return false
	_wall_normal = best_ray.get_collision_normal()
	_wall_side = side
	state = ParkourState.WALL_RUNNING
	state_timer = wall_run_duration
	var horiz := Vector3(player.velocity.x, 0, player.velocity.z)
	if horiz.length() < 0.1:
		horiz = -player.global_transform.basis.z
	horiz.y = 0.0
	player.velocity = horiz.normalized() * wall_run_speed
	return true


func _process_wall_run(delta: float) -> void:
	var still_touching := false
	if _wall_side == -1 and left_ray.is_colliding():
		still_touching = true
		_wall_normal = left_ray.get_collision_normal()
	elif _wall_side == 1 and right_ray.is_colliding():
		still_touching = true
		_wall_normal = right_ray.get_collision_normal()
	if not still_touching:
		_end_parkour()
		return
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var along_wall := forward.slide(_wall_normal).normalized()
	player.velocity = along_wall * wall_run_speed
	player.velocity.y = 0.0
	player.velocity -= _wall_normal * 1.5
	player.move_and_slide()
	if Input.is_action_just_pressed("jump"):
		player.velocity = _wall_normal * 6.5 + Vector3.UP * 5.0 + along_wall * 3.0
		_end_parkour()


func _start_slide() -> void:
	state = ParkourState.SLIDING
	state_timer = slide_duration
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	_slide_dir = forward.normalized()
	player.velocity = _slide_dir * 13.0
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var shape := collision_shape.shape as CapsuleShape3D
		_original_shape_height = shape.height
		_original_shape_y = collision_shape.position.y
		shape.height = 0.9
		collision_shape.position.y = 0.45


func _process_slide(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, _slide_dir.x * 2.0, delta * 14.0)
	player.velocity.z = move_toward(player.velocity.z, _slide_dir.z * 2.0, delta * 14.0)
	if not player.is_on_floor():
		player.velocity.y -= 9.8 * delta
	player.move_and_slide()
	if not Input.is_action_pressed("crouch") and state_timer < slide_duration * 0.6:
		_end_parkour()


func _end_parkour() -> void:
	if state == ParkourState.SLIDING and collision_shape and collision_shape.shape is CapsuleShape3D:
		var shape := collision_shape.shape as CapsuleShape3D
		shape.height = _original_shape_height
		collision_shape.position.y = _original_shape_y
	state = ParkourState.NONE
	state_timer = 0.0
	_wall_side = 0
	_wall_normal = Vector3.ZERO
	_tree_body = null


func is_active() -> bool:
	return state != ParkourState.NONE


func get_state() -> ParkourState:
	return state
