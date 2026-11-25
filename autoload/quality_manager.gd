extends Node
## QualityManager — autoload
## Détecte le matériel et applique un préréglage de qualité.

enum Preset { ECO, LOW, BALANCED, HIGH }

signal quality_changed(preset: Preset)

var current: Preset = Preset.BALANCED


func _ready() -> void:
	current = _detect_preset()
	apply_preset(current)


func _detect_preset() -> Preset:
	if OS.has_feature("android"):
		var model := OS.get_model_name()
		print("[QUALITY] Device model: ", model)
		# TECNO Spark 7 Pro et appareils modestes
		if "Spark" in model or "TECNO" in model:
			return Preset.LOW
		return Preset.BALANCED
	# PC par défaut
	return Preset.HIGH


func apply_preset(p: Preset) -> void:
	current = p
	match p:
		Preset.ECO:
			get_viewport().scaling_3d_scale = 0.5
			Engine.max_fps = 30
		Preset.LOW:
			get_viewport().scaling_3d_scale = 0.65
			Engine.max_fps = 30
		Preset.BALANCED:
			get_viewport().scaling_3d_scale = 0.8
			Engine.max_fps = 45
		Preset.HIGH:
			get_viewport().scaling_3d_scale = 1.0
			Engine.max_fps = 60
	print("[QUALITY] Preset appliqué: ", Preset.keys()[p])
	quality_changed.emit(p)


func cycle_preset() -> void:
	var next := (current + 1) % (Preset.size())
	apply_preset(next)
