class_name Weapon
extends Resource
## Arme médiévale — configurable dans l'inspecteur.

enum Kind { SWORD, DAGGER, SPEAR, BOW, SHIELD }
enum Type { MELEE, RANGED, DEFENSE }

@export var kind: Kind = Kind.SWORD
@export var type: Type = Type.MELEE
@export var display_name: String = "Sword"
@export var damage: int = 25
@export var attack_range: float = 2.2          # portée mêlée en mètres
@export var attack_angle: float = 60.0          # angle de cône devant l'attaquant (degrés)
@export var cooldown_sec: float = 0.8           # temps entre deux attaques
@export var stamina_cost: float = 15.0          # coût en endurance par attaque
@export var knockback_force: float = 4.0        # recul appliqué à la cible
@export var projectile_speed: float = 35.0      # arc seulement
@export var projectile_lifetime: float = 3.0     # arc seulement
@export var block_damage_reduction: float = 0.0  # bouclier: 0.0-1.0 (0.7 = -70% dégâts)
@export var mesh_path: String = ""               # path vers le mesh 3D de l'arme
@export var icon_path: String = ""
