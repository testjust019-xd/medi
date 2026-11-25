extends Node
## Fait apparaître THE UNKNOWN rarement pendant un match.

@export var enabled: bool = true
@export var min_delay: float = 90.0
@export var max_delay: float = 240.0
@export var spawn_chance: float = 0.35
var _timer: float = 120.0
var _entity: CharacterBody3D = null
var _spawned_this_match: bool = false
var _rng := RandomNumberGenerator.new()
const SCRIPT_PATH := "res://scripts/world/unknown_entity.gd"
func _ready() -> void:
	_rng.randomize()
	_timer = _rng.randf_range(min_delay * 0.5, min_delay)
	if get_node_or_null("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if "medieval_unknown" in gm and not gm.medieval_unknown:
			spawn_chance *= 0.25
func _process(delta: float) -> void:
	if not enabled or _spawned_this_match:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = _rng.randf_range(min_delay, max_delay)
	if _rng.randf() > spawn_chance:
		return
	_spawn()
func _spawn() -> void:
	if _entity and is_instance_valid(_entity) and _entity.visible:
		return
	var script := load(SCRIPT_PATH)
	if script == null:
		return
	_entity = CharacterBody3D.new()
	_entity.set_script(script)
	var points: Array[Vector3] = [Vector3(8, 0, 8), Vector3(-8, 0, 6), Vector3(0, 0, -10), Vector3(12, 0, -4), Vector3(-10, 0, -8), Vector3(4, 0, 12)]
	var spawn_pos: Vector3 = points[_rng.randi() % points.size()]
	get_parent().add_child(_entity)
	_entity.activate(spawn_pos, points)
	_spawned_this_match = true
	print("[UnknownSpawner] Entity deployed")
