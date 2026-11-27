extends Node
## InteriorLoader — charge/décharge les intérieurs de bâtiments par proximité.
## Gère la mémoire: seuls les intérieurs proches du joueur sont en mémoire.
## Chaque bâtiment a: une Area3D (porte) + un fichier de scène intérieure.

# bâtiment_id -> { trigger: Area3D, interior_scene: PackedScene, loaded_interior: Node, loaded: bool }
var _buildings: Dictionary = {}
const LOAD_DISTANCE := 15.0  # mètres
const INTERIOR_DIR := "res://world/interiors/"


## Enregistre un bâtiment comme explorable
func register_building(building_id: String, trigger: Area3D, interior_path: String) -> void:
	_buildings[building_id] = {
		"trigger": trigger,
		"interior_path": interior_path,
		"loaded_interior": null,
		"loaded": false,
	}
	# Connecter le signal d'entrée/sortie
	if not trigger.body_entered.is_connected(_on_building_entered.bind(building_id)):
		trigger.body_entered.connect(_on_building_entered.bind(building_id))
	if not trigger.body_exited.is_connected(_on_building_exited.bind(building_id)):
		trigger.body_exited.connect(_on_building_exited.bind(building_id))
	print("[INTERIOR] Registered building: ", building_id)


func _on_building_entered(body: Node, building_id: String) -> void:
	if not body is CharacterBody3D:
		return
	if not body.has_method("is_multiplayer_authority"):
		return
	if not body.is_multiplayer_authority():
		return  # seul le joueur local déclenche le chargement
	_load_interior(building_id)


func _on_building_exited(body: Node, building_id: String) -> void:
	if not body is CharacterBody3D:
		return
	if not body.has_method("is_multiplayer_authority"):
		return
	if not body.is_multiplayer_authority():
		return
	# Delay avant déchargement (pour éviter les rechargements fréquents)
	await get_tree().create_timer(3.0).timeout
	_unload_interior(building_id)


func _load_interior(building_id: String) -> void:
	var data: Dictionary = _buildings.get(building_id, {})
	if data.is_empty() or data.get("loaded", false):
		return
	var path: String = data["interior_path"]
	if not ResourceLoader.exists(path):
		push_warning("[INTERIOR] Interior scene not found: ", path)
		return
	var scene: PackedScene = load(path)
	var interior := scene.instantiate()
	# Placer à la position du bâtiment
	var trigger: Area3D = data["trigger"]
	interior.global_position = trigger.global_position
	get_parent().add_child(interior)
	data["loaded_interior"] = interior
	data["loaded"] = true
	_buildings[building_id] = data
	print("[INTERIOR] Loaded: ", building_id)


func _unload_interior(building_id: String) -> void:
	var data: Dictionary = _buildings.get(building_id, {})
	if data.is_empty() or not data.get("loaded", false):
		return
	var interior: Node = data["loaded_interior"]
	if is_instance_valid(interior):
		interior.queue_free()
	data["loaded_interior"] = null
	data["loaded"] = false
	_buildings[building_id] = data
	print("[INTERIOR] Unloaded: ", building_id)


## Décharge tous les intérieurs (changement de carte)
func unload_all() -> void:
	for building_id in _buildings.keys():
		_unload_interior(building_id)
