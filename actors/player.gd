extends CharacterBody3D
## Player — avatar multijoueur.
## Chaque client possède son avatar (autorité par nœud).
## Le serveur valide les actions (capture); les clients envoient l'intention.

signal health_changed(hp: int)
signal stamina_changed(stamina: float)
signal captured(state: int)

# État du joueur
var health: int = 100
var stamina: float = 100.0
var player_state: int = 0  # 0=alive, 1=being_captured, 2=captured, 3=frozen
var player_name: String = "Player"
var team: int = 0  # 0=fugitive, 1=hunter

# Arme équipée (null si aucune)
var equipped_weapon: Resource = null  # Weapon resource
var is_blocking: bool = false

# Capture en cours
var capture_progress: float = 0.0  # 0..1
var captor_id: int = 0

# Caméra
var cam_first_person: bool = false

@onready var cam: Camera3D = $CameraRig/Camera3D
@onready var cam_rig: Node3D = $CameraRig
@onready var mesh: MeshInstance3D = $Body
@onready var name_label: Label3D = $NameLabel

const GRAVITY: float = 9.8


func _ready() -> void:
        # L'autorité du nœud = le peer qui possède cet avatar
        set_multiplayer_authority(name.to_int())
        var is_owner := is_multiplayer_authority()

        # Seul le propriétaire active sa caméra et son input
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
        if event.is_action_pressed("interact") and team == 1 and player_state == 0:
                _try_capture()
        # Combat: attaque (clic gauche)
        if event.is_action_pressed("attack") and equipped_weapon and player_state == 0:
                _try_attack()
        # Combat: blocage (clic droit maintenu)
        if event.is_action_pressed("block"):
                _set_blocking(true)
        elif event.is_action_released("block"):
                _set_blocking(false)
        # Lancer d'objet (touche Q)
        if event.is_action_pressed("throw") and player_state == 0:
                _try_throw()


func _try_capture() -> void:
        # Trouver le fugitif le plus proche à portée
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
                if d < nearest_dist and d <= 3.0:  # capture_range
                        nearest_dist = d
                        nearest_id = peer_id
        if nearest_id != 0:
                # Envoyer la demande au serveur
                match_mgr.request_capture.rpc_id(1, nearest_id)


## Équipe une arme sur ce joueur
func equip_weapon(weapon: Resource) -> void:
        equipped_weapon = weapon
        print("[PLAYER] %s equipped %s" % [player_name, weapon.display_name if weapon else "none"])


func _try_attack() -> void:
        var match_mgr := get_parent()
        if not match_mgr:
                return
        var combat := match_mgr.get_node_or_null("CombatSystem")
        if not combat:
                return
        if equipped_weapon.type == 0:  # MELEE
                combat.request_melee_attack.rpc_id(1)
        elif equipped_weapon.type == 1:  # RANGED (bow)
                var aim := -cam_rig.global_transform.basis.z.normalized()
                combat.request_ranged_attack.rpc_id(1, aim)


func _set_blocking(active: bool) -> void:
        is_blocking = active
        var match_mgr := get_parent()
        if not match_mgr:
                return
        var combat := match_mgr.get_node_or_null("CombatSystem")
        if combat:
                combat.set_blocking.rpc_id(1, active)


func _try_throw() -> void:
        var match_mgr := get_parent()
        if not match_mgr:
                return
        var throw_sys := match_mgr.get_node_or_null("ThrowSystem")
        if not throw_sys:
                return
        var dir := -cam_rig.global_transform.basis.z.normalized()
        # Matériau aléatoire (pierre=0, bouteille=1, vase=2, bois=3)
        var mat_type := randi() % 4
        throw_sys.request_throw.rpc_id(1, dir, mat_type)


func _switch_camera() -> void:
        if cam_first_person:
                cam.position = Vector3(0, 0.6, 0.2)
                mesh.visible = false
        else:
                cam.position = Vector3(0, 2.0, 4.5)
                mesh.visible = true


func _process(delta: float) -> void:
        if not is_multiplayer_authority():
                return
        # Rotation caméra avec souris (troisième personne)
        if not cam_first_person and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
                var mouse := Input.get_last_mouse_velocity()
                cam_rig.rotate_y(-mouse.x * delta * 0.05)

        # Récupération stamina
        if stamina < 100.0:
                stamina = min(stamina + 12.0 * delta, 100.0)
                stamina_changed.emit(stamina)


func _physics_process(delta: float) -> void:
        if not is_multiplayer_authority():
                return
        if player_state >= 2:
                # Capturé: ne peut plus bouger
                velocity = Vector3.ZERO
                move_and_slide()
                return

        # Parkour: si le système parkour est actif, il gère le mouvement
        var parkour := get_node_or_null("ParkourSystem")
        if parkour and parkour.has_method("is_active") and parkour.is_active():
                return  # le parkour_system gère velocity + move_and_slide

        # Gravité
        if not is_on_floor():
                velocity.y -= GRAVITY * delta

        # Saut
        if Input.is_action_just_pressed("jump") and is_on_floor():
                velocity.y = 4.5

        # Mouvement
        var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
        var direction := (cam_rig.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

        var speed := 4.0  # walk
        if Input.is_action_pressed("run"):
                speed = 7.0
        if Input.is_action_pressed("sprint") and stamina > 0.0 and input_dir.length() > 0.1:
                speed = 10.0
                stamina = max(stamina - 18.0 * delta, 0.0)
                stamina_changed.emit(stamina)

        if direction:
                velocity.x = direction.x * speed
                velocity.z = direction.z * speed
                # Tourner le mesh vers la direction de déplacement
                var look_pos := global_position + direction
                var rot := atan2(direction.x, direction.z)
                mesh.rotation.y = lerp_angle(mesh.rotation.y, rot, delta * 10.0)
        else:
                velocity.x = move_toward(velocity.x, 0, delta * 20.0)
                velocity.z = move_toward(velocity.z, 0, delta * 20.0)

        move_and_slide()


## Appelé quand on est capturé (par RPC depuis le serveur)
func set_captured(new_state: int) -> void:
        player_state = new_state
        captured.emit(new_state)
        if new_state == 2:
                # Couleur sombre quand capturé
                var mat := mesh.material_override as StandardMaterial3D
                if mat:
                        mat.albedo_color = Color(0.3, 0.3, 0.3)
