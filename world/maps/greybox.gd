extends Node3D
## Greybox — cour médiévale générée procéduralement.
## Sol, murs d'enceinte, 3 bâtiments, tonneaux (cachettes), tous avec collision.
## Style low-poly: primitives + matériaux partagés (performant sur mobile).

const WALL_HEIGHT := 6.0
const GROUND_SIZE := 40.0
const HALF := GROUND_SIZE / 2.0


func _ready() -> void:
        _build_ground()
        _build_walls()
        _build_buildings()
        _build_barrels()
        _build_torches()


func _add_static_box(pos: Vector3, size: Vector3, color: Color) -> void:
        var body := StaticBody3D.new()
        body.global_position = pos
        add_child(body)

        var mesh_inst := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = size
        mesh_inst.mesh = box
        mesh_inst.material_override = _shared_mat(color)
        body.add_child(mesh_inst)

        var col := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        col.shape = shape
        body.add_child(col)

        # Friction pour que le joueur ne glisse pas
        body.set_meta("friction", 0.8)


var _mats: Dictionary = {}
func _shared_mat(color: Color) -> StandardMaterial3D:
        var key := color.to_html()
        if not _mats.has(key):
                var mat := StandardMaterial3D.new()
                mat.albedo_color = color
                mat.roughness = 0.7
                mat.metalness = 0.0
                _mats[key] = mat
        return _mats[key]


func _build_ground() -> void:
        _add_static_box(Vector3(0, -0.1, 0), Vector3(GROUND_SIZE, 0.2, GROUND_SIZE), Color(0.35, 0.32, 0.28))


func _build_walls() -> void:
        var wall_color := Color(0.4, 0.38, 0.34)
        var half := GROUND_SIZE / 2.0
        # Nord, Sud, Est, Ouest
        _add_static_box(Vector3(0, WALL_HEIGHT/2, -half), Vector3(GROUND_SIZE, WALL_HEIGHT, 1.0), wall_color)
        _add_static_box(Vector3(0, WALL_HEIGHT/2, half), Vector3(GROUND_SIZE, WALL_HEIGHT, 1.0), wall_color)
        _add_static_box(Vector3(-half, WALL_HEIGHT/2, 0), Vector3(1.0, WALL_HEIGHT, GROUND_SIZE), wall_color)
        _add_static_box(Vector3(half, WALL_HEIGHT/2, 0), Vector3(1.0, WALL_HEIGHT, GROUND_SIZE), wall_color)


func _build_buildings() -> void:
        var stone := Color(0.5, 0.48, 0.44)
        var wood := Color(0.4, 0.28, 0.18)
        var roof := Color(0.35, 0.15, 0.1)

        # Bâtiment 1: grande maison (nord-est)
        _add_static_box(Vector3(-8, 1.5, -8), Vector3(8, 3, 6), stone)
        _add_static_box(Vector3(-8, 3.5, -8), Vector3(8.5, 1, 6.5), roof)

        # Bâtiment 2: tour (sud-est)
        _add_cylinder(Vector3(8, 3, -8), 2.0, 6.0, stone)
        _add_cylinder(Vector3(8, 6.5, -8), 2.2, 1.0, roof)

        # Bâtiment 3: petite cabane (sud-ouest) — cachette
        _add_static_box(Vector3(8, 1, 8), Vector3(4, 2, 4), wood)
        _add_static_box(Vector3(8, 2.2, 8), Vector3(4.5, 0.4, 4.5), roof)

        # Bâtiment 4: marché couvert (nord-ouest)
        _add_static_box(Vector3(-8, 0.5, 8), Vector3(6, 1, 5), wood)
        _add_static_box(Vector3(-8, 2.5, 8), Vector3(6, 0.2, 5), Color(0.3, 0.12, 0.08))


func _add_cylinder(pos: Vector3, radius: float, height: float, color: Color) -> void:
        var body := StaticBody3D.new()
        body.global_position = pos
        add_child(body)

        var mesh_inst := MeshInstance3D.new()
        var cyl := CylinderMesh.new()
        cyl.radius = radius
        cyl.height = height
        mesh_inst.mesh = cyl
        mesh_inst.material_override = _shared_mat(color)
        body.add_child(mesh_inst)

        var col := CollisionShape3D.new()
        var shape := CylinderShape3D.new()
        shape.radius = radius
        shape.height = height
        col.shape = shape
        body.add_child(col)


func _build_barrels() -> void:
        # Tonneaux = cachettes (le joueur peut se cacher derrière)
        var barrel_color := Color(0.4, 0.25, 0.12)
        var positions := [
                Vector3(-3, 0.5, 3),
                Vector3(-4, 0.5, 3),
                Vector3(3, 0.5, -3),
                Vector3(4, 0.5, -3),
                Vector3(-5, 0.5, 5),
                Vector3(5, 0.5, 5),
        ]
        for pos in positions:
                _add_cylinder(pos, 0.5, 1.0, barrel_color)


func _build_torches() -> void:
        # Petits points lumineux pour l'ambiance (sans collision)
        var positions := [
                Vector3(-HALF + 1, 3, 0),
                Vector3(HALF - 1, 3, 0),
                Vector3(0, 3, -HALF + 1),
                Vector3(0, 3, HALF - 1),
        ]
        for pos in positions:
                var light := OmniLight3D.new()
                light.global_position = pos
                light.light_color = Color(1.0, 0.7, 0.3)
                light.light_energy = 2.0
                light.omni_range = 8.0
                light.omni_attenuation = 1.5
                light.shadow_enabled = false  # perf: pas d'ombres sur les OmniLight
                add_child(light)
