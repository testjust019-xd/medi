extends Node3D
## ParkourSystem — version améliorée
## États: CLIMB, VAULT, SLIDE, WALL_RUN
## Détection plus fiable avec 5 raycasts (Forward, High, Down, Left, Right)

enum ParkourState { NONE, CLIMBING, VAULTING, SLIDING, WALL_RUNNING }

var state: ParkourState = ParkourState.NONE
var state_timer: float = 0.0

@onready var fwd_ray: RayCast3D = $ForwardRay
@onready var high_ray: RayCast3D = $HighRay
@onready var down_ray: RayCast3D = $DownRay
@onready var left_ray: RayCast3D = $LeftRay
@onready var right_ray: RayCast3D = $RightRay

var player: CharacterBody3D
var collision_shape: CollisionShape3D

# --- Tuning ---
var climb_speed: float = 3.8
var vault_duration: float = 0.38
var slide_duration: float = 0.85
var wall_run_duration: float = 1.35
var wall_run_speed: float = 9.0
var vault_boost: float = 1.6          # distance forward after vault
var min_speed_for_slide: float = 4.0
var min_speed_for_wallrun: float = 3.5

# Internals
var _vault_target: Vector3 = Vector3.ZERO
var _wall_normal: Vector3 = Vector3.ZERO
var _wall_side: int = 0               # -1 left, +1 right
var _original_shape_height: float = 1.6
var _original_shape_y: float = 0.8
var _slide_dir: Vector3 = Vector3.ZERO


func _ready() -> void:
	player = get_parent() as CharacterBody3D
	collision_shape = player.get_node_or_null("CollisionShape3D") as CollisionShape3D

	# Activer tous les rays
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

		if state_timer <= 0.0:
			_end_parkour()
	else:
		_check_parkour_input(delta)


func _check_parkour_input(_delta: float) -> void:
	if not player.is_multiplayer_authority():
		return
	if player.player_state >= 2:  # capturé / frozen
		return

	# --- SLIDE ---
	# Sprint + Crouch + assez de vitesse
	if Input.is_action_pressed("crouch") \
			and (Input.is_action_pressed("sprint") or Input.is_action_pressed("run")) \
			and player.velocity.length() > min_speed_for_slide \
			and player.is_on_floor():
		_start_slide()
		return

	# --- JUMP-based parkour ---
	if Input.is_action_just_pressed("jump"):
		# Priorité: Vault > Climb > WallRun
		if _try_vault():
			return
		if _try_climb():
			return
		if _try_wall_run():
			return


# ─────────────────────────────────────────────
# VAULT (obstacle bas 0.4m → 1.35m)
# ─────────────────────────────────────────────
func _try_vault() -> bool:
	if not fwd_ray.is_colliding():
		return false
	if high_ray.is_colliding():
		return false  # trop haut → plutôt climb

	var hit_point := fwd_ray.get_collision_point()
	var height_diff := hit_point.y - player.global_position.y

	# Plage de hauteur pour un vault propre
	if height_diff < 0.35 or height_diff > 1.35:
		return false

	# Direction d'arrivée
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
	# Courbe douce (ease-out)
	var ease_t := 1.0 - (1.0 - t) * (1.0 - t)

	player.global_position = player.global_position.lerp(_vault_target, delta * 11.0)
	player.velocity = Vector3.ZERO

	# Petit boost vers l'avant en fin de vault
	if t > 0.7:
		var forward := (_vault_target - player.global_position)
		forward.y = 0.0
		if forward.length() > 0.1:
			player.velocity = forward.normalized() * 4.5


# ─────────────────────────────────────────────
# CLIMB (mur haut)
# ─────────────────────────────────────────────
func _try_climb() -> bool:
	if not player.is_on_floor():
		return false
	if not fwd_ray.is_colliding() or not high_ray.is_colliding():
		return false

	var hit_point := fwd_ray.get_collision_point()
	var height_diff := hit_point.y - player.global_position.y

	# On accepte seulement les murs assez hauts
	if height_diff < 1.2:
		return false

	state = ParkourState.CLIMBING
	state_timer = 2.8  # durée max
	player.velocity = Vector3.ZERO
	return true


func _process_climb(delta: float) -> void:
	# Monter
	player.velocity = Vector3.ZERO
	player.velocity.y = climb_speed

	# Se coller au mur
	if fwd_ray.is_colliding():
		var normal := fwd_ray.get_collision_normal()
		player.velocity.x = -normal.x * 1.2
		player.velocity.z = -normal.z * 1.2

	player.move_and_slide()

	# Sommet atteint → se hisser
	if not high_ray.is_colliding() and not fwd_ray.is_colliding():
		# Petit hop final
		player.velocity.y = 3.5
		var forward := -player.global_transform.basis.z
		forward.y = 0.0
		player.velocity += forward.normalized() * 2.5
		_end_parkour()
		return

	# Si on perd le mur trop tôt
	if not fwd_ray.is_colliding() and state_timer < 2.3:
		_end_parkour()


# ─────────────────────────────────────────────
# WALL RUN (gauche / droite)
# ─────────────────────────────────────────────
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

	# On garde la vitesse horizontale actuelle
	var horiz := Vector3(player.velocity.x, 0, player.velocity.z)
	if horiz.length() < 0.1:
		horiz = -player.global_transform.basis.z
	horiz.y = 0.0
	player.velocity = horiz.normalized() * wall_run_speed
	return true


func _process_wall_run(delta: float) -> void:
	# Vérifier qu'on touche encore le mur
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

	# Direction le long du mur
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	# Projeter le mouvement sur le plan du mur
	var along_wall := forward.slide(_wall_normal).normalized()
	player.velocity = along_wall * wall_run_speed
	player.velocity.y = 0.0  # annule la gravité pendant wall-run

	# Léger stick au mur
	player.velocity -= _wall_normal * 1.5

	player.move_and_slide()

	# Si le joueur appuie sur saut → petit jump off
	if Input.is_action_just_pressed("jump"):
		player.velocity = _wall_normal * 6.5 + Vector3.UP * 5.0 + along_wall * 3.0
		_end_parkour()


# ─────────────────────────────────────────────
# SLIDE
# ─────────────────────────────────────────────
func _start_slide() -> void:
	state = ParkourState.SLIDING
	state_timer = slide_duration

	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	_slide_dir = forward.normalized()

	# Boost initial
	player.velocity = _slide_dir * 13.0

	# Baisser la capsule
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var shape := collision_shape.shape as CapsuleShape3D
		_original_shape_height = shape.height
		_original_shape_y = collision_shape.position.y
		shape.height = 0.9
		collision_shape.position.y = 0.45


func _process_slide(delta: float) -> void:
	# Décélération progressive
	player.velocity.x = move_toward(player.velocity.x, _slide_dir.x * 2.0, delta * 14.0)
	player.velocity.z = move_toward(player.velocity.z, _slide_dir.z * 2.0, delta * 14.0)

	# Légère gravité
	if not player.is_on_floor():
		player.velocity.y -= 9.8 * delta

	player.move_and_slide()

	# Sortie anticipée si on relâche crouch et qu'on est encore vite
	if not Input.is_action_pressed("crouch") and state_timer < slide_duration * 0.6:
		_end_parkour()


# ─────────────────────────────────────────────
# FIN D'ÉTAT
# ─────────────────────────────────────────────
func _end_parkour() -> void:
	# Restaurer la collision si on sortait d'un slide
	if state == ParkourState.SLIDING and collision_shape and collision_shape.shape is CapsuleShape3D:
		var shape := collision_shape.shape as CapsuleShape3D
		shape.height = _original_shape_height
		collision_shape.position.y = _original_shape_y

	state = ParkourState.NONE
	state_timer = 0.0
	_wall_side = 0
	_wall_normal = Vector3.ZERO


func is_active() -> bool:
	return state != ParkourState.NONE


func get_state() -> ParkourState:
	return state
