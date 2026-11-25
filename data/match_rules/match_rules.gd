class_name MatchRules
extends Resource
## Règles de partie — configurable par l'hôte dans le lobby.

@export var match_duration_sec: float = 180.0      # 3 min pour le prototype
@export var capture_time_sec: float = 3.0           # secondes de maintien
@export var capture_range: float = 3.0              # portée de capture en mètres
@export var hp_max: int = 100
@export var stamina_max: float = 100.0
@export var stamina_drain_sprint: float = 18.0
@export var stamina_regen_rest: float = 12.0
@export var walk_speed: float = 4.0
@export var run_speed: float = 7.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 4.5
@export var camera_lerp: float = 8.0
@export var team_hunter_color: Color = Color(0.85, 0.3, 0.3)
@export var team_fugitive_color: Color = Color(0.3, 0.75, 0.55)
@export_range(0, 3) var npc_density: int = 1  # 0=ECO, 1=LOW, 2=BALANCED, 3=HIGH
