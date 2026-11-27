extends Node
## DayNightCycle — cycle jour / nuit simple.
## Fait tourner une DirectionalLight (soleil) + ajuste ambient & energy.

signal phase_changed(phase: String)

@export var day_length_sec: float = 240.0
@export var start_time: float = 0.25

var time_of_day: float = 0.25
var _sun: DirectionalLight3D
var _current_phase: String = ""

const COLOR_DAY := Color(1.0, 0.96, 0.9)
const COLOR_DUSK := Color(1.0, 0.55, 0.3)
const COLOR_NIGHT := Color(0.35, 0.4, 0.7)
const COLOR_DAWN := Color(1.0, 0.7, 0.5)


func _ready() -> void:
	time_of_day = start_time
	_find_or_create_sun()
	_apply()


func _process(delta: float) -> void:
	if day_length_sec <= 0.0:
		return
	time_of_day = fposmod(time_of_day + delta / day_length_sec, 1.0)
	_apply()


func _find_or_create_sun() -> void:
	var lights := get_tree().get_nodes_in_group("sun_light")
	if lights.size() > 0:
		_sun = lights[0] as DirectionalLight3D
		return
	_sun = DirectionalLight3D.new()
	_sun.name = "Sun"
	_sun.add_to_group("sun_light")
	_sun.shadow_enabled = false
	add_child(_sun)


func _apply() -> void:
	if _sun == null or not is_instance_valid(_sun):
		_find_or_create_sun()
		if _sun == null:
			return
	var angle := (time_of_day * 360.0) - 90.0
	_sun.rotation_degrees = Vector3(angle, 35.0, 0.0)
	var phase := _get_phase()
	var col: Color
	var energy: float
	var ambient: Color
	match phase:
		"day":
			col = COLOR_DAY
			energy = 1.0
			ambient = Color(0.55, 0.55, 0.6)
		"dusk":
			col = COLOR_DUSK
			energy = 0.65
			ambient = Color(0.4, 0.3, 0.25)
		"night":
			col = COLOR_NIGHT
			energy = 0.15
			ambient = Color(0.08, 0.09, 0.14)
		"dawn":
			col = COLOR_DAWN
			energy = 0.5
			ambient = Color(0.35, 0.3, 0.28)
		_:
			col = COLOR_DAY
			energy = 0.8
			ambient = Color(0.5, 0.5, 0.55)
	_sun.light_color = col
	_sun.light_energy = energy
	var env: Environment = get_viewport().world_3d.environment if get_viewport() and get_viewport().world_3d else null
	if env == null:
		_ensure_environment(ambient, energy)
	else:
		env.ambient_light_color = ambient
		env.ambient_light_energy = clampf(energy * 0.6 + 0.15, 0.1, 0.8)
	if phase != _current_phase:
		_current_phase = phase
		phase_changed.emit(phase)


func _get_phase() -> String:
	var t := time_of_day
	if t >= 0.22 and t < 0.35:
		return "dawn"
	if t >= 0.35 and t < 0.65:
		return "day"
	if t >= 0.65 and t < 0.78:
		return "dusk"
	return "night"


func _ensure_environment(ambient: Color, energy: float) -> void:
	var world := get_viewport().world_3d
	if world == null:
		return
	if world.environment == null:
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.4, 0.55, 0.75)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = ambient
		env.ambient_light_energy = clampf(energy * 0.6 + 0.15, 0.1, 0.8)
		world.environment = env
	else:
		world.environment.ambient_light_color = ambient
		world.environment.ambient_light_energy = clampf(energy * 0.6 + 0.15, 0.1, 0.8)


func set_time(t: float) -> void:
	time_of_day = fposmod(t, 1.0)
	_apply()


func is_night() -> bool:
	return _get_phase() == "night"


func get_phase() -> String:
	return _current_phase
