extends CharacterBody3D
## Player — avatar multijoueur.
signal health_changed(hp: int)
signal stamina_changed(stamina: float)
signal captured(state: int)
var health: int = 100
var stamina: float = 100.0
var player_state: int = 0
var player_name: String = "Player"
var team: int = 0
var equipped_weapon: Resource = null
var is_blocking: bool = false
var capture_progress: float = 0.0
var captor_id: int = 0
var cam_first_person: bool = false
@onready var cam: Camera3D = $CameraRig/Camera3D
@onready var cam_rig: Node3D = $CameraRig
@onready var mesh: MeshInstance3D = $Body
@onready var name_label: Label3D = $NameLabel
const GRAVITY: float = 9.8
func _ready() -> void:
	set_multiplayer_authority(name.to_int())
	var is_owner := is_multiplayer_authority()
	cam.current = is_owner
	if not is_owner:
		set_process(false)
		set_process_input(false)
	name_label.text = player_name
	_apply_team_color()
func _apply_team_color() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.6, 0.65) if team == 1 else Color(0.4, 0.6, 0.5)
	mat.roughness = 0.6
	mesh.material_override = mat
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("camera_switch"):
		cam_first_person = not cam_first_person
		_switch_camera()
	if event.is_action_pressed("interact") and player_state == 0:
		if team == 1:
			_try_capture()
		else:
			_try_hide_or_secret()
	if event.is_action_pressed("attack") and equipped_weapon and player_state == 0:
		_try_attack()
	if event.is_action_pressed("block"):
		_set_blocking(true)
	elif event.is_action_released("block"):
		_set_blocking(false)
	if event.is_action_pressed("throw") and player_state == 0:
		_try_throw()
func _try_hide_or_secret() -> void:
	if has_meta("hidden_in_spot"):
		var spot = get_meta("hidden_in_spot")
		if is_instance_valid(spot) and spot.has_method("exit"):
			spot.exit(self)
		return
	var best_hide = null
	var best_d := 2.2
	for node in get_tree().get_nodes_in_group("hide_spots"):
		if not is_instance_valid(node):
			continue
		var d := global_position.distance_to(node.global_position)
		if d < best_d and node.has_method("can_enter") and node.can_enter(self):
			best_d = d
			best_hide = node
	if best_hide:
		best_hide.try_toggle(self)
		return
	var best_secret = null
	best_d = 2.5
	for node in get_tree().get_nodes_in_group("secret_spots"):
		if not is_instance_valid(node):
			continue
		var d := global_position.distance_to(node.global_position)
		if d < best_d:
			best_d = d
			best_secret = node
	if best_secret and best_secret.has_method("try_activate"):
		best_secret.try_activate(self)
func _try_capture() -> void:
	var match_mgr := get_parent()
	if not match_mgr or not match_mgr.has_method("request_capture"):
		return
	var my_id := multiplayer.get_unique_id()
	var nearest_id := 0
	var nearest_dist := 99.0
	for peer_id in match_mgr.players_in_match:
		if peer_id == my_id:
			continue
		var other = match_mgr.players_in_match[peer_id]
		if not is_instance_valid(other) or other.team != 0 or other.player_state >= 2:
			continue
		var d := global_position.distance_to(other.global_position)
		if d < nearest_dist and d <= 3.0:
			nearest_dist = d
			nearest_id = peer_id
	if nearest_id != 0:
		match_mgr.request_capture.rpc_id(1, nearest_id)
func _try_attack() -> void:
	var combat = get_parent().get_node_or_null("CombatSystem")
	if combat and combat.has_method("request_attack"):
		combat.request_attack(self)
func _set_blocking(active: bool) -> void:
	is_blocking = active
func _try_throw() -> void:
	var throw_sys = get_parent().get_node_or_null("ThrowSystem")
	if throw_sys and throw_sys.has_method("request_throw"):
		throw_sys.request_throw(self)
func _switch_camera() -> void:
	if cam_first_person:
		cam_rig.position = Vector3(0, 1.6, 0)
	else:
		cam_rig.position = Vector3(0, 2.2, 4.5)
func _process(delta: float) -> void:
	pass
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if has_meta("hidden_in_spot"):
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if player_state >= 2:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var parkour = get_node_or_null("ParkourSystem")
	if parkour and parkour.has_method("is_active") and parkour.is_active():
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := 5.0
	if Input.is_action_pressed("sprint"):
		speed = 8.5
	elif Input.is_action_pressed("run"):
		speed = 6.5
	if Input.is_action_pressed("crouch"):
		speed = 2.5
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = 4.5
	move_and_slide()
func set_player_state(new_state: int) -> void:
	player_state = new_state
	captured.emit(new_state)
