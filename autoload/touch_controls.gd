extends CanvasLayer
## Contrôles tactiles (autoload) : joystick à gauche, glisser à droite pour regarder,
## boutons d'action. Visible uniquement pendant une partie, sur un écran tactile.

const JOY_RADIUS := 90.0
const JOY_DEADZONE := 0.15
const LOOK_SENS := 0.0045
const ACTIONS_MOVE := ["move_left", "move_right", "move_forward", "move_back"]

var _enabled := false
var _in_match := false
var _ctrl: Control
var _joy_touch := -1
var _joy_center := Vector2.ZERO
var _joy_pos := Vector2.ZERO
var _look_touch := -1
var _btn_touch: Dictionary = {}  # index du doigt -> id du bouton
var _move_state: Dictionary = {}
var _player: Node = null


func _ready() -> void:
	layer = 100
	_enabled = DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios")
	_ctrl = Control.new()
	_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ctrl.draw.connect(_draw_ui)
	add_child(_ctrl)
	_ctrl.visible = false


func _buttons() -> Array:
	var s := get_viewport().get_visible_rect().size
	return [
		{"id": "jump", "label": "SAUT", "pos": Vector2(s.x - 120, s.y - 130), "r": 56.0},
		{"id": "sprint", "label": "COURSE", "pos": Vector2(s.x - 250, s.y - 90), "r": 44.0},
		{"id": "crouch", "label": "BAS", "pos": Vector2(s.x - 250, s.y - 200), "r": 40.0},
		{"id": "attack", "label": "ATTAQUE", "pos": Vector2(s.x - 120, s.y - 260), "r": 46.0},
		{"id": "interact", "label": "ACTION", "pos": Vector2(s.x - 240, s.y - 310), "r": 46.0},
		{"id": "block", "label": "PARER", "pos": Vector2(s.x - 370, s.y - 120), "r": 40.0},
		{"id": "throw", "label": "LANCER", "pos": Vector2(s.x - 370, s.y - 220), "r": 40.0},
		{"id": "camera_switch", "label": "VUE", "pos": Vector2(s.x - 60, 150), "r": 30.0},
	]


func _process(_delta: float) -> void:
	if not _enabled:
		return
	var sc := get_tree().current_scene
	var now := sc != null and sc.scene_file_path.ends_with("match.tscn")
	if now != _in_match:
		_in_match = now
		_ctrl.visible = now
		# Pendant la partie, le toucher ne doit pas simuler un clic souris (= attaque).
		Input.emulate_mouse_from_touch = not now
		if not now:
			_release_all()
		_ctrl.queue_redraw()


func _input(event: InputEvent) -> void:
	if not _enabled or not _in_match:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touch_down(t.index, t.position)
		else:
			_touch_up(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _joy_touch:
			_joy_pos = d.position
			_update_joystick()
		elif d.index == _look_touch:
			var p := _get_player()
			if p:
				p.apply_look(d.relative, LOOK_SENS)


func _touch_down(index: int, pos: Vector2) -> void:
	for b in _buttons():
		if pos.distance_to(b["pos"]) <= b["r"] + 8.0:
			_btn_touch[index] = b["id"]
			_set_action(b["id"], 1.0)
			_ctrl.queue_redraw()
			return
	var s := get_viewport().get_visible_rect().size
	if _joy_touch == -1 and pos.x < s.x * 0.4 and pos.y > s.y * 0.25:
		_joy_touch = index
		_joy_center = pos
		_joy_pos = pos
		_update_joystick()
	elif _look_touch == -1:
		_look_touch = index


func _touch_up(index: int) -> void:
	if _btn_touch.has(index):
		_set_action(_btn_touch[index], 0.0)
		_btn_touch.erase(index)
	elif index == _joy_touch:
		_joy_touch = -1
		_apply_move(Vector2.ZERO)
	elif index == _look_touch:
		_look_touch = -1
	_ctrl.queue_redraw()


func _update_joystick() -> void:
	var v := (_joy_pos - _joy_center) / JOY_RADIUS
	if v.length() > 1.0:
		v = v.normalized()
	if v.length() < JOY_DEADZONE:
		v = Vector2.ZERO
	_apply_move(v)
	_ctrl.queue_redraw()


func _apply_move(v: Vector2) -> void:
	_set_move("move_right", maxf(v.x, 0.0))
	_set_move("move_left", maxf(-v.x, 0.0))
	_set_move("move_back", maxf(v.y, 0.0))
	_set_move("move_forward", maxf(-v.y, 0.0))


func _set_move(action: String, strength: float) -> void:
	if is_equal_approx(_move_state.get(action, 0.0), strength):
		return
	_move_state[action] = strength
	_set_action(action, strength)


func _set_action(action: String, strength: float) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = strength > 0.0
	ev.strength = strength
	Input.parse_input_event(ev)


func _release_all() -> void:
	for index in _btn_touch.keys():
		_set_action(_btn_touch[index], 0.0)
	_btn_touch.clear()
	_joy_touch = -1
	_look_touch = -1
	_apply_move(Vector2.ZERO)


func _get_player() -> Node:
	if is_instance_valid(_player):
		return _player
	var sc := get_tree().current_scene
	if sc == null:
		return null
	for c in sc.get_children():
		if c is CharacterBody3D and c.has_method("apply_look") and c.is_multiplayer_authority():
			_player = c
			return c
	return null


func _draw_ui() -> void:
	var font := ThemeDB.fallback_font
	if _joy_touch != -1:
		_ctrl.draw_circle(_joy_center, JOY_RADIUS, Color(1, 1, 1, 0.10))
		_ctrl.draw_arc(_joy_center, JOY_RADIUS, 0.0, TAU, 40, Color(1, 1, 1, 0.35), 3.0)
		var k := (_joy_pos - _joy_center).limit_length(JOY_RADIUS)
		_ctrl.draw_circle(_joy_center + k, 38.0, Color(0.88, 0.64, 0.29, 0.55))
	else:
		var s := get_viewport().get_visible_rect().size
		_ctrl.draw_arc(Vector2(150, s.y - 140), JOY_RADIUS * 0.8, 0.0, TAU, 40, Color(1, 1, 1, 0.18), 3.0)
	var down := _btn_touch.values()
	for b in _buttons():
		var pressed := down.has(b["id"])
		var fill := Color(0.88, 0.64, 0.29, 0.55) if pressed else Color(0.08, 0.07, 0.06, 0.45)
		_ctrl.draw_circle(b["pos"], b["r"], fill)
		_ctrl.draw_arc(b["pos"], b["r"], 0.0, TAU, 32, Color(1, 1, 1, 0.45), 2.0)
		var fs := 14 if b["r"] < 45.0 else 16
		_ctrl.draw_string(font, b["pos"] + Vector2(-b["r"], fs * 0.35), b["label"], HORIZONTAL_ALIGNMENT_CENTER, b["r"] * 2.0, fs, Color(1, 1, 1, 0.9))
