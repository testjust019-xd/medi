extends CanvasLayer
## HUD — affichage pendant le match.
## Timer, HP, stamina, progression de capture, résultat.

@onready var timer_label: Label = $Margin/VBox/TimerLabel
@onready var hp_bar: ProgressBar = $Margin/VBox/HPBar
@onready var stamina_bar: ProgressBar = $Margin/VBox/StaminaBar
@onready var capture_bar: ProgressBar = $Margin/VBox/CaptureBar
@onready var capture_label: Label = $Margin/VBox/CaptureLabel
@onready var result_panel: Panel = $ResultPanel
@onready var result_label: Label = $ResultPanel/ResultLabel
@onready var controls_label: Label = $Margin/VBox/ControlsLabel


func _ready() -> void:
	capture_bar.visible = false
	capture_label.visible = false
	result_panel.visible = false
	controls_label.text = "[ZQSD] bouger · [Shift] courir · [Ctrl] sprint · [Espace] sauter · [E] capturer · [V] caméra"


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
