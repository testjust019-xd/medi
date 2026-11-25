extends Node3D
## KINGDOM — la carte principale, une grande cité médiévale fortifiée.
## Générée procéduralement: château, marché, quartiers résidentiels, remparts, forêt.
## Plus détaillée que la greybox: ruelles, tours, bâtiments explorables.

const STONE := Color(0.5, 0.48, 0.44)
const DARK_STONE := Color(0.38, 0.36, 0.33)
const WOOD := Color(0.4, 0.28, 0.18)
const ROOF := Color(0.35, 0.15, 0.1)
const GROUND := Color(0.32, 0.3, 0.26)
const GRASS := Color(0.25, 0.35, 0.2)
const WALL_H := 8.0
const MAP_SIZE := 80.0
const HALF := MAP_SIZE / 2.0

var _mats: Dictionary = {}


func _ready() -> void:
        _build_ground()
        _build_perimeter_walls()
        _build_castle()
        _build_market()
        _build_residential()
        _build_forest_perimeter()
        _build_torches()


func _mat(color: Color) -> StandardMaterial3D:
        var key := color.to_html()
        if not _mats.has(key):
                var m := StandardMaterial3D.new()
                m.albedo_color = color
                m.roughness = 0.75
                _mats[key] = m
        return _mats[key]


func _box(pos: Vector3, size: Vector3, color: Color) -> void:
        var body := StaticBody3D.new()
        body.global_position = pos
        add_child(body)
        var mi := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = size
        mi.mesh = mesh
        mi.material_override = _mat(color)
        body.add_child(mi)
        var col := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        col.shape = shape
        body.add_child(col)


func _cyl(pos: Vector3, radius: float, height: float, color: Color) -> void:
        var body := StaticBody3D.new()
        body.global_position = pos
        add_child(body)
        var mi := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.radius = radius
        mesh.height = height
        mi.mesh = mesh
        mi.material_override = _mat(color)
        body.add_child(mi)
        var col := CollisionShape3D.new()
        var shape := CylinderShape3D.new()
        shape.radius = radius
        shape.height = height
        col.shape = shape
        body.add_child(col)


func _build_ground() -> void:
        # Sol de la cité
        _box(Vector3(0, -0.1, 0), Vector3(MAP_SIZE, 0.2, MAP_SIZE), GROUND)
        # Herbe périphérique
        _box(Vector3(0, -0.15, HALF + 15), Vector3(MAP_SIZE + 30, 0.2, 30), GRASS)
        _box(Vector3(0, -0.15, -HALF - 15), Vector3(MAP_SIZE + 30, 0.2, 30), GRASS)
        _box(Vector3(HALF + 15, -0.15, 0), Vector3(30, 0.2, MAP_SIZE), GRASS)
        _box(Vector3(-HALF - 15, -0.15, 0), Vector3(30, 0.2, MAP_SIZE), GRASS)


func _build_perimeter_walls() -> void:
        # Remparts avec tours aux coins
        _box(Vector3(0, WALL_H/2, -HALF), Vector3(MAP_SIZE, WALL_H, 1.5), DARK_STONE)
        _box(Vector3(0, WALL_H/2, HALF), Vector3(MAP_SIZE, WALL_H, 1.5), DARK_STONE)
        _box(Vector3(-HALF, WALL_H/2, 0), Vector3(1.5, WALL_H, MAP_SIZE), DARK_STONE)
        _box(Vector3(HALF, WALL_H/2, 0), Vector3(1.5, WALL_H, MAP_SIZE), DARK_STONE)
        # Tours aux 4 coins
        for pos in [Vector3(-HALF, 0, -HALF), Vector3(HALF, 0, -HALF), Vector3(-HALF, 0, HALF), Vector3(HALF, 0, HALF)]:
                _cyl(Vector3(pos.x, WALL_H, pos.z), 2.5, WALL_H * 1.5, DARK_STONE)
                _cyl(Vector3(pos.x, WALL_H * 1.7, pos.z), 3.0, 2.0, ROOF)


func _build_castle() -> void:
        # Château royal (nord-est, la structure la plus grande)
        var cx := -20.0
        var cz := -20.0
        # Corps principal
        _box(Vector3(cx, 4, cz), Vector3(18, 8, 14), STONE)
        _box(Vector3(cx, 8.5, cz), Vector3(19, 1, 15), ROOF)
        # Donjon central (tour haute)
        _cyl(Vector3(cx, 10, cz), 3.5, 20, STONE)
        _cyl(Vector3(cx, 20.5, cz), 4.0, 2.5, ROOF)
        # Tours d'angle du château
        for corner in [Vector3(cx-8, 0, cz-6), Vector3(cx+8, 0, cz-6), Vector3(cx-8, 0, cz+6), Vector3(cx+8, 0, cz+6)]:
                _cyl(Vector3(corner.x, 6, corner.z), 2.0, 12, STONE)
                _cyl(Vector3(corner.x, 12.5, corner.z), 2.5, 1.5, ROOF)


func _build_market() -> void:
        # Grand marché (centre)
        var mx := 5.0
        var mz := 5.0
        # Étales (petites structures en bois)
        for i in 6:
                var px := mx + (i % 3 - 1) * 6
                var pz := mz + (i / 3 - 1) * 6
                _box(Vector3(px, 0.6, pz), Vector3(4, 1.2, 3), WOOD)
                _box(Vector3(px, 1.5, pz), Vector3(4.5, 0.3, 3.5), ROOF)
        # Puits central
        _cyl(Vector3(mx, 0.8, mz), 1.2, 1.6, DARK_STONE)


func _build_residential() -> void:
        # Quartiers résidentiels (sud-ouest et sud-est) — maisons explorables
        var houses := [
                Vector3(15, 0, 15), Vector3(22, 0, 15), Vector3(15, 0, 22),
                Vector3(-15, 0, 20), Vector3(-22, 0, 20), Vector3(-15, 0, 27),
                Vector3(25, 0, -10), Vector3(30, 0, -10),
        ]
        for i in houses.size():
                var pos := houses[i]
                var w := 5.0 + (i % 3)
                var h := 3.0 + (i % 2) * 1.5
                # Corps de la maison (creux: 4 murs au lieu d'un bloc plein)
                _build_house_walls(pos, w, h)
                # Toit
                _box(Vector3(pos.x, h + 0.3, pos.z), Vector3(w + 0.5, 0.6, w + 0.5), ROOF)
                # Trigger de porte pour l'InteriorLoader
                _add_door_trigger(pos, w, i)


func _build_house_walls(pos: Vector3, w: float, h: float) -> void:
        # 4 murs avec ouverture pour la porte (face avant, largeur 1.5m)
        var t := 0.3  # épaisseur mur
        var hw := w / 2.0
        # Mur arrière (plein)
        _box(Vector3(pos.x, h/2, pos.z - hw), Vector3(w, h, t), STONE)
        # Mur gauche (plein)
        _box(Vector3(pos.x - hw, h/2, pos.z), Vector3(t, h, w), STONE)
        # Mur droit (plein)
        _box(Vector3(pos.x + hw, h/2, pos.z), Vector3(t, h, w), STONE)
        # Mur avant: deux morceaux avec ouverture (porte de 1.5m au centre)
        var side_w := (w - 1.5) / 2.0
        _box(Vector3(pos.x - hw + side_w/2, h/2, pos.z + hw), Vector3(side_w, h, t), STONE)
        _box(Vector3(pos.x + hw - side_w/2, h/2, pos.z + hw), Vector3(side_w, h, t), STONE)
        # Linteau au-dessus de la porte
        _box(Vector3(pos.x, h - 0.5, pos.z + hw), Vector3(1.5, 1.0, t), STONE)
        # Sol intérieur
        _box(Vector3(pos.x, -0.05, pos.z), Vector3(w - 0.2, 0.1, w - 0.2), GROUND)


func _add_door_trigger(pos: Vector3, w: float, index: int) -> void:
        # Area3D devant la porte (côté +Z de la maison)
        var door_pos := Vector3(pos.x, 1.0, pos.z + w/2.0 + 0.5)
        var area := Area3D.new()
        area.global_position = door_pos
        area.name = "DoorTrigger_%d" % index
        var col := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(2.0, 2.0, 1.5)
        col.shape = shape
        area.add_child(col)
        add_child(area)
        # Enregistrer auprès de l'InteriorLoader (sur le nœud Match)
        var loader := get_parent().get_parent().get_node_or_null("InteriorLoader")
        if loader and loader.has_method("register_building"):
                loader.register_building("house_%d" % index, area, "res://world/interiors/house_interior.tscn")


func _build_forest_perimeter() -> void:
        # Arbres (MultiMesh pour les performances en production; cylindres pour le prototype)
        var tree_positions: Array[Vector3] = []
        for i in 30:
                var angle := i * TAU / 30.0
                var r := HALF + randf_range(5, 20)
                tree_positions.append(Vector3(cos(angle) * r, 0, sin(angle) * r))
        # Ajouter quelques arbres dispersés dans la zone herbeuse
        for i in 15:
                tree_positions.append(Vector3(
                        randf_range(-HALF - 25, HALF + 25), 0,
                        randf_range(-HALF - 25, HALF + 25)
                ))
        for pos in tree_positions:
                # Tronc
                _cyl(pos, 0.4, 4.0, WOOD)
                # Feuillage (cône)
                _cyl(Vector3(pos.x, 5, pos.z), 2.0, 3.0, GRASS)


func _build_torches() -> void:
        # Torches sur les remparts
        for x in [-HALF + 3, HALF - 3]:
                for z in [-HALF + 10, 0, HALF - 10]:
                        var light := OmniLight3D.new()
                        light.global_position = Vector3(x, WALL_H, z)
                        light.light_color = Color(1.0, 0.7, 0.3)
                        light.light_energy = 1.5
                        light.omni_range = 10.0
                        light.shadow_enabled = false
                        add_child(light)
        # Torches de marché
        for i in 4:
                var angle := i * TAU / 4.0
                var light := OmniLight3D.new()
                light.global_position = Vector3(5 + cos(angle) * 8, 3, 5 + sin(angle) * 8)
                light.light_color = Color(1.0, 0.6, 0.2)
                light.light_energy = 1.0
                light.omni_range = 8.0
                light.shadow_enabled = false
                add_child(light)
