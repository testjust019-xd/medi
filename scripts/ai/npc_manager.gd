extends Node3D
## NpcManager — spawn et gestion des PNJ selon la densité configurée.
## Densités: ECO=0, LOW=5, BALANCED=15, HIGH=30.
## Les PNJ patrollent entre des waypoints et réagissent aux événements (captures)
## sans révéler la position des fugitifs.

const NPC_SCENE := preload("res://actors/npcs/npc.tscn")
const MATCH_RULES := preload("res://data/match_rules/default.tres")

var npcs: Array[CharacterBody3D] = []
var density: int = 1  # 0=ECO, 1=LOW, 2=BALANCED, 3=HIGH
var patrol_zones: Array[Dictionary] = []  # { center: Vector3, radius: float }


func _ready() -> void:
        density = MATCH_RULES.npc_density
        _setup_patrol_zones()
        _spawn_npcs()


func _setup_patrol_zones() -> void:
        # Zones de patrol dispersées sur la carte
        var map_half := 18.0
        for i in 6:
                var center := Vector3(
                        randf_range(-map_half, map_half),
                        0,
                        randf_range(-map_half, map_half)
                )
                patrol_zones.append({ "center": center, "radius": randf_range(4.0, 8.0) })


func _spawn_npcs() -> void:
        var counts := [0, 5, 15, 30]  # ECO, LOW, BALANCED, HIGH
        var count := counts[clamp(density, 0, 3)]

        for i in count:
                var npc := NPC_SCENE.instantiate()
                npc.npc_type = i % 4
                # Placer dans une zone de patrol aléatoire
                var zone: Dictionary = patrol_zones[randi() % patrol_zones.size()]
                var center: Vector3 = zone["center"]
                var radius: float = zone["radius"]
                npc.global_position = center + Vector3(
                        randf_range(-radius, radius), 0, randf_range(-radius, radius)
                )
                # Générer des waypoints pour ce NPC dans sa zone
                var points: Array[Vector3] = []
                for j in 4:
                        points.append(center + Vector3(
                                randf_range(-radius, radius), 0, randf_range(-radius, radius)
                        ))
                npc.set_patrol_points(points)
                add_child(npc)
                npcs.append(npc)

        print("[NPC] Spawned %d NPCs (density=%d)" % [count, density])


## Appelé quand une capture se produit — les PNJ à proximité réagissent
func notify_event(event_pos: Vector3, radius: float = 15.0) -> void:
        for npc in npcs:
                if not is_instance_valid(npc):
                        continue
                var dist := npc.global_position.distance_to(event_pos)
                if dist <= radius:
                        npc.react_to_event(event_pos)


func clear_npcs() -> void:
        for npc in npcs:
                if is_instance_valid(npc):
                        npc.queue_free()
        npcs.clear()
