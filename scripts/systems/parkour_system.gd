extends Node3D
## ParkourSystem — composant du joueur pour le parkour avancé.
## Détecte murs, corniches et obstacles via raycasts.
## États: CLIMB, VAULT, SLIDE, WALL_RUN.
## À ajouter comme enfant du Player (avec des RayCast3D).

enum ParkourState { NONE, CLIMBING, VAULTING, SLIDING, WALL_RUNNING }

var state: ParkourState = ParkourState.NONE
var state_timer: float = 0.0

@onready var fwd_ray: RayCast3D = $ForwardRay
@onready var high_ray: RayCast3D = $HighRay
@onready var down_ray: RayCast3D = $DownRay

var player: CharacterBody3D
var climb_speed: float = 3.0
var vault_duration: float = 0.4
var slide_duration: float = 0.8
var wall_run_duration: float = 1.2
var wall_run_speed: float = 8.0


func _ready() -> void:
        player = get_parent()
        fwd_ray.enabled = true
        high_ray.enabled = true
        down_ray.enabled = true


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


func _check_parkour_input(delta: float) -> void:
        if not player.is_multiplayer_authority():
                return

        # Slide: sprint + crouch en mouvement
        if Input.is_action_pressed("crouch") and Input.is_action_pressed("sprint") and player.velocity.length() > 3.0:
                _start_slide()
                return

        # Vault / Climb: appui sur saut près d'un obstacle
        if Input.is_action_just_pressed("jump"):
                if _try_vault():
                        return
                if _try_climb():
                        return
                if _try_wall_run():
                        return


func _try_vault() -> bool:
        # Obstacle bas devant (le bas raycast touche, le haut raycast ne touche pas)
        if fwd_ray.is_colliding() and not high_ray.is_colliding():
                var point := fwd_ray.get_collision_point()
                var height_diff := point.y - player.global_position.y
                if height_diff > 0.3 and height_diff < 1.5:
                        # Obstacle franchissable → vault
                        state = ParkourState.VAULTING
                        state_timer = vault_duration
                        _vault_target = point + Vector3(0, 0.5, 0) + player.velocity.normalized() * 1.0
                        return true
        return false

var _vault_target: Vector3 = Vector3.ZERO

func _process_vault(delta: float) -> void:
        # Tween vers la position de vault
        var t := 1.0 - (state_timer / vault_duration)
        player.global_position = player.global_position.lerp(_vault_target, delta * 8.0)
        player.velocity = Vector3.ZERO


func _try_climb() -> bool:
        # Mur devant (les deux raycasts touchent) + le joueur est au sol
        if fwd_ray.is_colliding() and high_ray.is_colliding():
                var point := fwd_ray.get_collision_point()
                var height_diff := point.y - player.global_position.y
                if height_diff > 1.5:
                        # Mur trop haut pour vault → grimper
                        state = ParkourState.CLIMBING
                        state_timer = 3.0  # max 3 secondes de grimpe
                        return true
        return false


func _process_climb(delta: float) -> void:
        player.velocity = Vector3.ZERO
        player.velocity.y = climb_speed
        # Avancer légèrement vers le mur
        var normal := fwd_ray.get_collision_normal()
        player.velocity.x = -normal.x * 0.5
        player.velocity.z = -normal.z * 0.5
        player.move_and_slide()

        # Vérifier si on a atteint le sommet (le haut raycast ne touche plus)
        if not high_ray.is_colliding():
                # Se hisser au-dessus
                player.global_position.y += 0.5
                _end_parkour()


func _try_wall_run() -> bool:
        # Mur à gauche ou à droite + en l'air + en mouvement horizontal
        if not player.is_on_floor() and player.velocity.length() > 3.0:
                # Utiliser un raycast latéral (simplifié: réutiliser fwd_ray avec rotation)
                # En production: ajouter LeftRay et RightRay
                if fwd_ray.is_colliding():
                        state = ParkourState.WALL_RUNNING
                        state_timer = wall_run_duration
                        return true
        return false


func _process_wall_run(delta: float) -> void:
        # Maintenir la vélocité horizontale, annuler la gravité
        var horiz := Vector3(player.velocity.x, 0, player.velocity.z)
        if horiz.length() < 0.1:
                _end_parkour()
                return
        horiz = horiz.normalized() * wall_run_speed
        player.velocity = Vector3(horiz.x, 0, horiz.z)  # pas de gravité pendant wall-run
        player.move_and_slide()


func _start_slide() -> void:
        state = ParkourState.SLIDING
        state_timer = slide_duration
        # Accélérer en glissade
        var fwd := -player.mesh.global_transform.basis.z.normalized()
        player.velocity = fwd * 12.0


func _process_slide(delta: float) -> void:
        # Décélération progressive
        player.velocity.x = move_toward(player.velocity.x, 0, delta * 15.0)
        player.velocity.z = move_toward(player.velocity.z, 0, delta * 15.0)
        # Baisser la collision (crouch)
        # En production: ajuster le CollisionShape3D


func _end_parkour() -> void:
        state = ParkourState.NONE
        state_timer = 0.0


func is_active() -> bool:
        return state != ParkourState.NONE
