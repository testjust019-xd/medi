extends Node
const HideSpotScript = preload("res://scripts/systems/hide_spot.gd")
const SecretSpotScript = preload("res://scripts/systems/secret_spot.gd")
static func add_hide_spot(parent: Node3D, pos: Vector3, spot_name: String = "Cachette") -> Area3D:
	var area := Area3D.new()
	area.set_script(HideSpotScript)
	area.position = pos
	area.spot_name = spot_name
	area.add_to_group("hide_spots")
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.2
	col.shape = shape
	area.add_child(col)
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 0.08
	mi.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.18, 0.15, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.position = Vector3(0, 0.04, 0)
	area.add_child(mi)
	parent.add_child(area)
	return area
static func add_secret(parent: Node3D, pos: Vector3, secret_id: String, secret_name: String, stype: int = 0, teleport: Vector3 = Vector3(0, 0, 3)) -> Area3D:
	var area := Area3D.new()
	area.set_script(SecretSpotScript)
	area.position = pos
	area.secret_id = secret_id
	area.secret_name = secret_name
	area.secret_type = stype
	area.teleport_offset = teleport
	area.add_to_group("secret_spots")
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.4
	col.shape = shape
	area.add_child(col)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.6, 0.3)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.7, 0.9, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.5, 0.8)
	mat.emission_energy_multiplier = 0.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.position = Vector3(0, 0.4, 0)
	area.add_child(mi)
	parent.add_child(area)
	return area
