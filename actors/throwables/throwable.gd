extends RigidBody3D
## Throwable — objet lancé (pierre, bouteille, vase, morceau de bois).
## Rebondit ou se casse selon le matériau. Inflige des dégâts si configurable.
## Crée une distraction sonore en touchant le sol (attire PNJ + chasseurs).
##
## Synchronisation: chaque client instancie l'objet via spawn_throwable RPC.
## La trajectoire RigidBody3D est déterministe si les conditions initiales
## sont identiques. Les dégâts ne sont appliqués QUE par le serveur.

enum Material { ROCK, BOTTLE, VASE, WOOD }

@export var material: Material = Material.ROCK
@export var damage: int = 10
@export var break_on_impact: bool = false
@export var sound_range: float = 12.0
@export var lifetime_sec: float = 8.0

var _has_hit_player: bool = false
var _lifetime: float = 0.0
var _combat_system: Node = null
var thrower_id: int = 0


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)
	_apply_material_visual()
	# Définir break_on_impact selon le matériau
	match material:
		Material.BOTTLE, Material.VASE:
			break_on_impact = true
		_:
			break_on_impact = false


func _apply_material_visual() -> void:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.7
	match material:
		Material.ROCK:
			mat.albedo_color = Color(0.4, 0.38, 0.35)
		Material.BOTTLE:
			mat.albedo_color = Color(0.2, 0.5, 0.3, 0.8)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		Material.VASE:
			mat.albedo_color = Color(0.6, 0.5, 0.35)
		Material.WOOD:
			mat.albedo_color = Color(0.4, 0.25, 0.12)
	$Mesh.material_override = mat


func _physics_process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= lifetime_sec:
		queue_free()


func _on_body_entered(body: Node) -> void:
	# Si c'est un joueur → dégâts (uniquement sur le serveur)
	if not _has_hit_player and body is CharacterBody3D and body.has_method("set_captured"):
		# Ne pas toucher le lanceur
		if body.name.to_int() == thrower_id:
			return
		_has_hit_player = true
		# Seul le serveur applique les dégâts (server-authoritative)
		if multiplayer.is_server() and damage > 0 and is_instance_valid(_combat_system):
			var target_id := body.name.to_int()
			var knockback := linear_velocity.normalized() * 2.0
			_combat_system._apply_damage.rpc(target_id, damage, knockback)
		queue_free()
		return

	# Sol ou mur: son de distraction (uniquement sur le serveur)
	if multiplayer.is_server():
		_notify_distraction()

	if break_on_impact:
		queue_free()
	# Sinon: l'objet rebondit et continue (RigidBody3D gère le rebond)


func _notify_distraction() -> void:
	# Trouver le NpcManager sur le Match
	var match_mgr := get_parent()
	while match_mgr and not match_mgr.has_node("NpcManager"):
		match_mgr = match_mgr.get_parent()
	if match_mgr and match_mgr.has_node("NpcManager"):
		match_mgr.get_node("NpcManager").notify_event(global_position, sound_range)
	print("[THROW] Distraction sound at ", global_position, " range=", sound_range)


func launch(origin: Vector3, direction: Vector3, force: float) -> void:
	global_position = origin
	linear_velocity = direction * force
	_has_hit_player = false
	_lifetime = 0.0


func set_combat_system(cs: Node) -> void:
	_combat_system = cs
