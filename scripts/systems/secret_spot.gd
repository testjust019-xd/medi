extends Area3D
## SecretSpot — lieu secret / passage.
enum SecretType { PASSAGE, LOOT_HINT, VIEWPOINT, TUNNEL }
@export var secret_id: String = "secret_01"
@export var secret_name: String = "Lieu secret"
@export var secret_type: SecretType = SecretType.PASSAGE
@export var reveal_target_path: NodePath
@export var teleport_offset: Vector3 = Vector3(0, 0, 3)
@export var one_shot: bool = true
var discovered: bool = false
var _active: bool = false
func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1
	add_to_group("secret_spots")
func try_activate(player: Node) -> bool:
	if not is_instance_valid(player):
		return false
	if global_position.distance_to(player.global_position) > 2.5:
		return false
	discovered = true
	_active = not _active
	match secret_type:
		SecretType.PASSAGE, SecretType.TUNNEL:
			_toggle_target()
			if secret_type == SecretType.TUNNEL:
				player.global_position = global_position + teleport_offset
		SecretType.LOOT_HINT:
			print("[Secret] %s découvre: %s" % [player.name, secret_name])
		SecretType.VIEWPOINT:
			print("[Secret] Point de vue: %s" % secret_name)
	print("[Secret] Découvert: %s (%s)" % [secret_name, secret_id])
	return true
func _toggle_target() -> void:
	if reveal_target_path.is_empty():
		return
	var node := get_node_or_null(reveal_target_path)
	if node:
		node.visible = _active
		if node is CollisionObject3D:
			node.set_collision_layer_value(1, not _active)
