extends Node3D
## Main Menu — scène 3D médiévale vivante + UI élégante.

@onready var ui: CanvasLayer = $UI
@onready var name_edit: LineEdit = $UI/Root/Panel/Margin/VBox/NameEdit
@onready var code_edit: LineEdit = $UI/Root/Panel/Margin/VBox/JoinRow/CodeEdit
@onready var event_card: PanelContainer = $UI/Root/EventCard
@onready var event_label: Label = $UI/Root/EventCard/Margin/EventText
@onready var unknown_check: CheckBox = $UI/Root/Panel/Margin/VBox/UnknownRow/UnknownCheck

var _torch_lights: Array[OmniLight3D] = []
var _time: float = 0.0

func _ready() -> void:
	NetworkManager.leave()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_world()
	_style_ui()
	_pick_mystery_event()
	if unknown_check:
		unknown_check.button_pressed = false

func _process(delta: float) -> void:
	_time += delta
	for i in _torch_lights.size():
		var l := _torch_lights[i]
		if is_instance_valid(l):
			l.light_energy = 1.4 + sin(_time * 3.0 + i * 1.7) * 0.35

func _style_ui() -> void:
	var panel := $UI/Root/Panel as PanelContainer
	if panel:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.05, 0.04, 0.88)
		sb.border_color = Color(0.75, 0.6, 0.28, 1)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 8
		panel.add_theme_stylebox_override("panel", sb)
	var card := $UI/Root/EventCard as PanelContainer
	if card:
		var sb2 := StyleBoxFlat.new()
		sb2.bg_color = Color(0.05, 0.04, 0.03, 0.85)
		sb2.border_color = Color(0.65, 0.5, 0.22, 0.9)
		sb2.set_border_width_all(1)
		sb2.set_corner_radius_all(4)
		card.add_theme_stylebox_override("panel", sb2)

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.05, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.14, 0.2)
	env.ambient_light_energy = 0.35
	env.fog_enabled = true
	env.fog_light_color = Color(0.15, 0.18, 0.25)
	env.fog_density = 0.012
	env.tonemap_mode = Environment.TONE_MAP_ACES
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_box(Vector3(0, -0.2, 0), Vector3(80, 0.4, 80), Color(0.12, 0.11, 0.1))
	_build_castle_backdrop()
	_build_village()
	_box(Vector3(-22, 3, 2), Vector3(1.2, 6, 30), Color(0.22, 0.2, 0.18))
	_box(Vector3(22, 3, 2), Vector3(1.2, 6, 30), Color(0.22, 0.2, 0.18))
	var cam := Camera3D.new()
	cam.position = Vector3(0, 4.5, 14)
	cam.rotation_degrees = Vector3(-12, 0, 0)
	cam.fov = 55
	cam.current = true
	add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 40, 0)
	sun.light_color = Color(0.55, 0.6, 0.85)
	sun.light_energy = 0.25
	sun.shadow_enabled = false
	add_child(sun)

func _build_castle_backdrop() -> void:
	var cz := -18.0
	_box(Vector3(0, 5, cz), Vector3(16, 10, 8), Color(0.28, 0.26, 0.24))
	_cyl(Vector3(0, 9, cz - 1), 2.8, 14, Color(0.3, 0.28, 0.26))
	_cyl(Vector3(0, 16.5, cz - 1), 3.2, 2.0, Color(0.35, 0.12, 0.1))
	for x in [-7.0, 7.0]:
		_cyl(Vector3(x, 7, cz + 1), 1.8, 10, Color(0.28, 0.26, 0.24))
		_cyl(Vector3(x, 12.5, cz + 1), 2.1, 1.5, Color(0.35, 0.12, 0.1))
	for pos in [Vector3(-3, 6, cz + 4.1), Vector3(3, 6, cz + 4.1), Vector3(0, 8, cz + 4.1), Vector3(-5, 5, cz + 4.1), Vector3(5, 5, cz + 4.1)]:
		_box(pos, Vector3(0.8, 1.2, 0.15), Color(1.0, 0.7, 0.3))
		var light := OmniLight3D.new()
		light.position = pos + Vector3(0, 0, 1)
		light.light_color = Color(1.0, 0.65, 0.3)
		light.light_energy = 2.0
		light.omni_range = 8.0
		light.shadow_enabled = false
		add_child(light)
		_torch_lights.append(light)

func _build_village() -> void:
	var houses := [Vector3(-8, 0, 4), Vector3(-4, 0, 6), Vector3(5, 0, 5), Vector3(9, 0, 3), Vector3(-10, 0, -2), Vector3(8, 0, -4)]
	for i in houses.size():
		var p: Vector3 = houses[i]
		var w := 3.5 + (i % 2)
		var h := 2.5 + (i % 3) * 0.4
		_box(Vector3(p.x, h * 0.5, p.z), Vector3(w, h, 3.0), Color(0.32, 0.28, 0.22))
		_box(Vector3(p.x, h + 0.3, p.z), Vector3(w + 0.4, 0.5, 3.4), Color(0.3, 0.12, 0.08))
		if i % 2 == 0:
			_box(Vector3(p.x, 1.4, p.z + 1.55), Vector3(0.6, 0.7, 0.1), Color(1.0, 0.75, 0.35))
			var l := OmniLight3D.new()
			l.position = Vector3(p.x, 1.5, p.z + 2.2)
			l.light_color = Color(1.0, 0.6, 0.25)
			l.light_energy = 1.2
			l.omni_range = 5.0
			l.shadow_enabled = false
			add_child(l)
			_torch_lights.append(l)
	_cyl(Vector3(0, 0.6, 2), 0.9, 1.2, Color(0.25, 0.24, 0.22))
	for x in [-3.0, 3.0]:
		_cyl(Vector3(x, 1.2, 8), 0.12, 2.4, Color(0.25, 0.18, 0.12))
		var l := OmniLight3D.new()
		l.position = Vector3(x, 2.5, 8)
		l.light_color = Color(1.0, 0.55, 0.2)
		l.light_energy = 1.8
		l.omni_range = 7.0
		l.shadow_enabled = false
		add_child(l)
		_torch_lights.append(l)
	for pos in [Vector3(-2, 0, 7), Vector3(1.5, 0, 6.5), Vector3(-6, 0, 3)]:
		_cyl(Vector3(pos.x, 0.9, pos.z), 0.28, 1.8, Color(0.2, 0.18, 0.16))

func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.position = pos
	add_child(mi)

func _cyl(pos: Vector3, r: float, h: float, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = h
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.position = pos
	add_child(mi)

const MYSTERY_EVENTS := [
	"Une lumière brûle dans la tour condamnée…",
	"Le Veilleur a été aperçu sur les remparts.",
	"Le marché nocturne ouvre ses étals secrets.",
	"Une cloche a sonné, et personne n'était au clocher.",
	"Le brouillard ancien se rassemble près des ruines.",
	"Un voyageur sans destination traverse le village.",
	"Des empreintes mènent vers une porte qui n'existait pas hier.",
	"La Nuit sans lune approche — les ombres s'allongent.",
]

func _pick_mystery_event() -> void:
	if event_label:
		event_label.text = MYSTERY_EVENTS[randi() % MYSTERY_EVENTS.size()]

func _on_host_pressed() -> void:
	var pname := name_edit.text.strip_edges()
	if pname.is_empty():
		pname = "Player"
	GameManager.local_player_name = pname
	_apply_unknown_flag()
	var err := NetworkManager.host(pname)
	if err == OK:
		GameManager.go_to_lobby()

func _on_join_pressed() -> void:
	var pname := name_edit.text.strip_edges()
	if pname.is_empty():
		pname = "Player"
	GameManager.local_player_name = pname
	_apply_unknown_flag()
	var code := code_edit.text.strip_edges().to_upper()
	if code.is_empty():
		code = "127.0.0.1"
	var address := code
	if code.length() <= 6 and code.length() >= 4:
		address = NetworkManager.decode_invite_code(code)
	var err := NetworkManager.join(address, pname)
	if err == OK:
		await NetworkManager.connected_to_server
		GameManager.go_to_lobby()

func _on_explore_pressed() -> void:
	_apply_unknown_flag()
	GameManager.local_player_name = name_edit.text.strip_edges()
	if GameManager.local_player_name.is_empty():
		GameManager.local_player_name = "Explorer"
	var err := NetworkManager.host(GameManager.local_player_name)
	if err == OK:
		await get_tree().create_timer(0.15).timeout
		GameManager.go_to_match()

func _on_customize_pressed() -> void:
	event_label.text = "Personnalisation — bientôt disponible."

func _apply_unknown_flag() -> void:
	if unknown_check:
		GameManager.medieval_unknown = unknown_check.button_pressed
