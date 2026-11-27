extends Node3D
## NpcManager — spawn PNJ avec zones de rôle (marché, murs, champs, village).
const NPC_SCENE := preload("res://actors/npcs/npc.tscn")
const MATCH_RULES := preload("res://data/match_rules/default.tres")
var npcs: Array[CharacterBody3D] = []
var density: int = 1
func _ready() -> void:
	add_to_group("npc_manager")
	density = MATCH_RULES.npc_density
	await get_tree().process_frame
	_spawn_npcs()
func _spawn_npcs() -> void:
	var counts := [0, 6, 14, 24]
	var count: int = counts[clampi(density, 0, 3)]
	if count == 0:
		print("[NPC] ECO density — no NPCs")
		return
	var market_zone := { "center": Vector3(4, 0, 4), "radius": 10.0 }
	var wall_zones := [{ "center": Vector3(0, 0, -20), "radius": 8.0 },{ "center": Vector3(20, 0, 0), "radius": 8.0 },{ "center": Vector3(-20, 0, 0), "radius": 8.0 },{ "center": Vector3(0, 0, 18), "radius": 8.0 }]
	var village_zone := { "center": Vector3(0, 0, 0), "radius": 14.0 }
	var farm_zone := { "center": Vector3(18, 0, 18), "radius": 10.0 }
	for i in count:
		var npc := NPC_SCENE.instantiate()
		var role := i % 4
		npc.npc_type = role
		var zone: Dictionary
		match role:
			1: zone = market_zone
			2: zone = wall_zones[i % wall_zones.size()]
			3: zone = farm_zone
			_: zone = village_zone
		var center: Vector3 = zone["center"]
		var radius: float = zone["radius"]
		npc.global_position = center + Vector3(randf_range(-radius, radius), 0, randf_range(-radius, radius))
		npc.set_home(center, radius + 4.0)
		var points: Array[Vector3] = []
		for j in 4:
			points.append(center + Vector3(randf_range(-radius, radius), 0, randf_range(-radius, radius)))
		npc.set_patrol_points(points)
		if role == 1 or role == 3:
			npc.set_work_point(center + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)))
		add_child(npc)
		npcs.append(npc)
	print("[NPC] Spawned %d NPCs (density=%d) with role routines" % [count, density])
func notify_event(event_pos: Vector3, radius: float = 15.0) -> void:
	for npc in npcs:
		if is_instance_valid(npc) and npc.global_position.distance_to(event_pos) <= radius:
			npc.react_to_event(event_pos)
func clear_npcs() -> void:
	for npc in npcs:
		if is_instance_valid(npc):
			npc.queue_free()
	npcs.clear()
