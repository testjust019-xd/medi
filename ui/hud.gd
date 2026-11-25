extends CanvasLayer
## HUD — affichage pendant le match.

@onready var timer_label: Label = $Margin/VBox/TimerLabel
@onready var hp_bar: ProgressBar = $Margin/VBox/HPBar
@onready var stamina_bar: ProgressBar = $Margin/VBox/StaminaBar
@onready var capture_bar: ProgressBar = $Margin/VBox/CaptureBar
@onready var capture_label: Label = $Margin/VBox/CaptureLabel
@onready var result_panel: Panel = $ResultPanel
@onready var result_label: Label = $ResultPanel/ResultLabel
@onready var controls_label: Label = $Margin/VBox/ControlsLabel

var _event_label: Label
var _choices_label: Label

func _ready() -> void:
	capture_bar.visible = false
	capture_label.visible = false
	result_panel.visible = false
	controls_label.text = "[ZQSD] bouger · [Shift] courir · [Espace] saut · [E] interagir/capturer · [V] caméra"

func update_timer(time_left: float) -> void:
	var mins := int(time_left) / 60
	var secs := int(time_left) % 60
	timer_label.text = "%01d:%02d" % [mins, secs]
	if time_left < 30.0:
		timer_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

func show_capture_progress(duration: float) -> void:
	capture_bar.visible = true
	capture_label.visible = true
	capture_label.text = "Capture en cours..."
	capture_bar.value = 0.0

func update_capture_progress(pct: float) -> void:
	capture_bar.value = clamp(pct * 100.0, 0.0, 100.0)

func hide_capture_progress() -> void:
	capture_bar.visible = false
	capture_label.visible = false

func show_result(winner: String) -> void:
	result_panel.visible = true
	var text := "Victoire des chasseurs !" if winner == "hunters" else "Les fugitifs survivent !"
	result_label.text = text

func update_hp(hp: int) -> void:
	hp_bar.value = hp

func update_stamina(stamina: float) -> void:
	stamina_bar.value = stamina

func _ensure_event_ui() -> void:
	if _event_label:
		return
	var root := get_node_or_null("Margin/VBox")
	if root == null:
		return
	_event_label = Label.new()
	_event_label.name = "EventLabel"
	_event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_event_label.add_theme_color_override("font_color", Color(0.92, 0.8, 0.45))
	_event_label.add_theme_font_size_override("font_size", 13)
	_event_label.visible = false
	root.add_child(_event_label)
	_choices_label = Label.new()
	_choices_label.name = "EventChoices"
	_choices_label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65))
	_choices_label.add_theme_font_size_override("font_size", 11)
	_choices_label.visible = false
	root.add_child(_choices_label)

func show_event(data: Dictionary) -> void:
	_ensure_event_ui()
	if _event_label == null:
		return
	_event_label.visible = true
	_event_label.text = "⚔ %s — %s" % [data.get("name", "?"), data.get("description", "")]
	if data.get("player_choices", false) and data.get("id") == "the_condemned":
		_choices_label.visible = true
		_choices_label.text = "[1] Observer  [2] Chercher preuve  [3] Convaincre témoin  [4] Alerter gardes  [5] Partir"
	else:
		if _choices_label:
			_choices_label.visible = false

func update_event(data: Dictionary) -> void:
	show_event(data)

func hide_event() -> void:
	if _event_label:
		_event_label.visible = false
	if _choices_label:
		_choices_label.visible = false
