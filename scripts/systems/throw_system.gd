extends Node3D
## ThrowSystem — gère le lancer d'objets avec synchronisation réseau.
## Le client envoie l'intention (request_throw), le serveur valide,
## puis diffuse spawn_throwable à tous les clients (call_local).
## Chaque client instancie l'objet localement — la trajectoire est
## déterministe si les conditions initiales sont identiques.
## Les dégâts ne sont appliqués que par le serveur (body_entered).

const THROWABLE_SCENE := preload("res://actors/throwables/throwable.tscn")

signal object_thrown(pos: Vector3)

var damage_levels := [0, 5, 10, 20]  # disabled, light, normal, high
var current_damage_level: int = 1


## Client → serveur: "je lance un objet dans cette direction"
## any_peer (pas call_local): seul le serveur exécute
@rpc("any_peer", "reliable")
func request_throw(direction: Vector3, material_type: int) -> void:
	if not multiplayer.is_server():
		return
	var thrower_id := multiplayer.get_remote_sender_id()
	var match_mgr := get_parent()
	var thrower = match_mgr.players_in_match.get(thrower_id)
	if not thrower or not is_instance_valid(thrower):
		return
	if thrower.player_state >= 2:
		return  # capturé

	# Origine: légèrement au-dessus et devant le joueur
	var origin := thrower.global_position + Vector3.UP * 1.2 + direction.normalized() * 0.5
	var dmg := damage_levels[clamp(current_damage_level, 0, 3)]

	# Diffuser à tous les clients (y compris le serveur via call_local)
	spawn_throwable.rpc(origin, direction.normalized(), material_type, dmg, thrower_id)
	object_thrown.emit(origin)


## Serveur → tous: "instantie cet objet lancé"
## authority + call_local: le serveur et tous les clients spawnent l'objet
@rpc("authority", "call_local", "reliable")
func spawn_throwable(origin: Vector3, direction: Vector3, material_type: int, damage: int, thrower_id: int) -> void:
	var t := THROWABLE_SCENE.instantiate()
	t.material = material_type
	t.damage = damage
	t.thrower_id = thrower_id
	# Le combat_system est sur le Match (parent du ThrowSystem)
	var match_mgr := get_parent()
	var combat := match_mgr.get_node_or_null("CombatSystem")
	if combat:
		t.set_combat_system(combat)
	add_child(t, true)
	t.launch(origin, direction, 18.0)
	print("[THROW] Spawned throwable mat=%d dmg=%d by %d" % [material_type, damage, thrower_id])


func set_damage_level(level: int) -> void:
	current_damage_level = clamp(level, 0, 3)
