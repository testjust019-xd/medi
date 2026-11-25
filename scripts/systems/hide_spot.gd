extends Area3D
## HideSpot — cachette interactive.
@export var spot_name: String = "Cachette"
@export var max_users: int = 1
var _occupants: Array[Node] = []
func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1
func can_enter(player: Node) -> bool:
	if not is_instance_valid(player):
		return false
	if player.get("team") != 0:
		return false
	if player.get("player_state") != 0:
		return false
	if player in _occupants:
		return false
	if _occupants.size() >= max_users:
		return false
	if global_position.distance_to(player.global_position) > 2.2:
		return false
	return true
func try_toggle(player: Node) -> bool:
	if player in _occupants:
		exit(player)
		return true
	if can_enter(player):
		enter(player)
		return true
	return false
func enter(player: Node) -> void:
	if player in _occupants:
		return
	_occupants.append(player)
	player.set_meta("hidden_in_spot", self)
	var mesh := player.get_node_or_null("Body") as MeshInstance3D
	if mesh:
		mesh.visible = false
	var label := player.get_node_or_null("NameLabel") as Label3D
	if label:
		label.visible = false
	player.global_position = global_position + Vector3(0, 0.2, 0)
	player.velocity = Vector3.ZERO
func exit(player: Node) -> void:
	if player not in _occupants:
		return
	_occupants.erase(player)
	if player.has_meta("hidden_in_spot"):
		player.remove_meta("hidden_in_spot")
	var mesh := player.get_node_or_null("Body") as MeshInstance3D
	if mesh:
		mesh.visible = true
	var label := player.get_node_or_null("NameLabel") as Label3D
	if label:
		label.visible = true
	player.global_position = global_position + Vector3(1.2, 0.2, 0)
