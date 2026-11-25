extends Node3D
## MatchManager — scène de partie.
## Gère: spawn des joueurs, chronomètre, capture, conditions de victoire.
## Autorité serveur: le serveur (hôte) valide toutes les captures.

const PLAYER_SCENE := preload("res://actors/player.tscn")
const MATCH_RULES := preload("res://data/match_rules/default.tres")
const SWORD := preload("res://data/weapons/sword.tres")
const DAGGER := preload("res://data/weapons/dagger.tres")
const BOW := preload("res://data/weapons/bow.tres")
const SHIELD := preload("res://data/weapons/shield.tres")

@onready var spawn_points: Node3D = $SpawnPoints
@onready var hud: CanvasLayer = $HUD
@onready var maps_root: Node3D = $MapsRoot

var time_left: float = 180.0
var match_active: bool = false
var players_in_match: Dictionary = {}  # peer_id -> Player node
var capture_in_progress: Dictionary = {}  # target_id -> { hunter_id, progress }


func _ready() -> void:
        time_left = MATCH_RULES.match_duration_sec
        # Verrouiller la souris
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

        # Charger la carte sélectionnée
        _load_map()

        if multiplayer.is_server():
                _spawn_all_players()
        match_active = true


func _load_map() -> void:
        var map_path := GameManager.selected_map
        if not ResourceLoader.exists(map_path):
                push_error("[MATCH] Map not found: " + map_path)
                map_path = "res://world/maps/greybox.tscn"  # fallback
        var map_scene := load(map_path)
        var map_instance := map_scene.instantiate()
        maps_root.add_child(map_instance)
        print("[MATCH] Loaded map: ", map_path)


func _process(delta: float) -> void:
        if not match_active:
                return
        time_left -= delta
        if hud:
                hud.update_timer(time_left)
        if time_left <= 0.0:
                _end_match("fugitives")
        elif multiplayer.is_server():
                _check_capture_progress(delta)


## Spawn: le serveur instancie un avatar par joueur connecté et le nomme avec le peer_id
func _spawn_all_players() -> void:
        var i := 0
        for peer_id in NetworkManager.players:
                var player := PLAYER_SCENE.instantiate()
                player.name = str(peer_id)
                player.player_name = NetworkManager.players[peer_id].get("name", "Player")
                # Team: pair ids = hunters, impair = fugitifs (simple pour le prototype)
                player.team = 1 if i % 2 == 0 else 0
                # Position de spawn
                var sp := spawn_points.get_child(i % spawn_points.get_child_count())
                if sp:
                        player.global_position = sp.global_position
                players_in_match[peer_id] = player
                add_child(player, true)  # true = nom lisible
                # Équiper une arme selon l'équipe (configurable via MatchRules)
                if player.team == 1:  # chasseur: épée + bouclier
                        player.equip_weapon(SWORD)
                else:  # fugitif: dague (défense minimale)
                        player.equip_weapon(DAGGER)
                i += 1
                print("[MATCH] Spawned player %d (team=%d)" % [peer_id, player.team])


# ━━ Capture RPCs ━━

## Client (hunter) → serveur: "je veux capturer le fugitif target_id"
@rpc("any_peer", "call_local", "reliable")
func request_capture(target_id: int) -> void:
        if not multiplayer.is_server():
                return
        var hunter_id := multiplayer.get_remote_sender_id()
        if not _can_capture(hunter_id, target_id):
                return
        if capture_in_progress.has(target_id):
                return  # déjà en cours
        capture_in_progress[target_id] = { "hunter_id": hunter_id, "progress": 0.0 }
        capture_started.rpc(hunter_id, target_id, MATCH_RULES.capture_time_sec)
        print("[CAPTURE] start: hunter=%d target=%d" % [hunter_id, target_id])


## Serveur → tous: la capture commence (affiche la barre sur le HUD)
@rpc("authority", "call_local", "reliable")
func capture_started(hunter_id: int, target_id: int, duration: float) -> void:
        if hud:
                hud.show_capture_progress(duration)
        # Geler le fugitif
        var target := players_in_match.get(target_id)
        if target:
                target.set_captured(1)  # being_captured
        # Notifier les PNJ (réagissent au bruit de la capture)
        _notify_npcs(players_in_match.get(target_id, null).global_position if target else Vector3.ZERO)


## Serveur → tous: la capture est annulée (le fugitif s'est échappé)
@rpc("authority", "call_local", "reliable")
func capture_cancelled(target_id: int) -> void:
        capture_in_progress.erase(target_id)
        if hud:
                hud.hide_capture_progress()
        var target := players_in_match.get(target_id)
        if target:
                target.set_captured(0)  # alive again


## Serveur → tous: le fugitif est capturé
@rpc("authority", "call_local", "reliable")
func capture_completed(target_id: int) -> void:
        capture_in_progress.erase(target_id)
        if hud:
                hud.hide_capture_progress()
        var target := players_in_match.get(target_id)
        if target:
                target.set_captured(2)  # captured
        # Vérifier condition de victoire
        if multiplayer.is_server():
                _check_win_condition()


func _can_capture(hunter_id: int, target_id: int) -> bool:
        var hunter := players_in_match.get(hunter_id)
        var target := players_in_match.get(target_id)
        if not hunter or not target:
                return false
        if hunter.team != 1 or target.team != 0:
                return false  # seul un chasseur peut capturer un fugitif
        if target.player_state >= 2:
                return false  # déjà capturé
        # Vérifier la distance
        var dist := hunter.global_position.distance_to(target.global_position)
        return dist <= MATCH_RULES.capture_range


func _check_capture_progress(delta: float) -> void:
        for target_id in capture_in_progress.keys():
                var data: Dictionary = capture_in_progress[target_id]
                var hunter_id: int = data["hunter_id"]
                # Vérifier que le chasseur maintient l'interaction et reste à portée
                if not _can_capture(hunter_id, target_id):
                        capture_cancelled.rpc(target_id)
                        continue
                data["progress"] = data["progress"] + delta
                if hud:
                        hud.update_capture_progress(data["progress"] / MATCH_RULES.capture_time_sec)
                if data["progress"] >= MATCH_RULES.capture_time_sec:
                        capture_completed.rpc(target_id)


func _check_win_condition() -> void:
        # Si tous les fugitifs sont capturés → chasseurs gagnent
        var fugitives_alive := 0
        for peer_id in players_in_match:
                var p = players_in_match[peer_id]
                if p.team == 0 and p.player_state < 2:
                        fugitives_alive += 1
        if fugitives_alive == 0:
                _end_match("hunters")


func _end_match(winner: String) -> void:
        match_active = false
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        print("[MATCH] Fin — gagnant: ", winner)
        if hud:
                hud.show_result(winner)
        # Retour au menu après 5 secondes
        await get_tree().create_timer(5.0).timeout
        GameManager.go_to_menu()


func _notify_npcs(event_pos: Vector3) -> void:
        var npc_mgr := get_node_or_null("NpcManager")
        if npc_mgr and npc_mgr.has_method("notify_event"):
                npc_mgr.notify_event(event_pos, 12.0)


func _exit_tree() -> void:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
