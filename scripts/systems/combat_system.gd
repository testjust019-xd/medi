extends Node
## CombatSystem — gère les attaques, les dégâts et le blocage.
## Serveur-autoritaire: le client envoie l'intention, le serveur valide et diffuse.
## À ajouter comme enfant de la scène Match.

const SWORD := preload("res://data/weapons/sword.tres")
const DAGGER := preload("res://data/weapons/dagger.tres")
const SPEAR := preload("res://data/weapons/spear.tres")
const BOW := preload("res://data/weapons/bow.tres")
const SHIELD := preload("res://data/weapons/shield.tres")

# peer_id -> last_attack_time (cooldown tracking)
var _last_attack: Dictionary = {}
# peer_id -> bool (is blocking with shield)
var _blocking: Dictionary = {}

signal damage_dealt(target_id: int, damage: int)


## Client → serveur: "j'attaque au corps-à-corps avec mon arme équipée"
@rpc("any_peer", "call_local", "reliable")
func request_melee_attack() -> void:
        if not multiplayer.is_server():
                return
        var attacker_id = (multiplayer.get_remote_sender_id() if multiplayer.get_remote_sender_id() != 0 else multiplayer.get_unique_id())
        var match_mgr = get_parent()
        var attacker = match_mgr.players_in_match.get(attacker_id)
        if not attacker or not is_instance_valid(attacker):
                return
        if attacker.player_state >= 2:
                return  # capturé, ne peut pas attaquer

        var weapon: Weapon = attacker.equipped_weapon
        if weapon == null or weapon.type != Weapon.Type.MELEE:
                return

        # Cooldown
        var now = Time.get_ticks_msec() / 1000.0
        var last: float = _last_attack.get(attacker_id, 0.0)
        if now - last < weapon.cooldown_sec:
                return

        # Stamina
        if attacker.stamina < weapon.stamina_cost:
                return
        attacker.stamina -= weapon.stamina_cost

        _last_attack[attacker_id] = now

        # Trouver toutes les cibles dans le cône d'attaque
        for target_id in match_mgr.players_in_match:
                if target_id == attacker_id:
                        continue
                var target = match_mgr.players_in_match[target_id]
                if not is_instance_valid(target) or target.player_state >= 2:
                        continue
                # Même équipe? pas de dégâts amicaux en V1 (configurable)
                if target.team == attacker.team:
                        continue

                var to_target = target.global_position - attacker.global_position
                var dist = to_target.length()
                if dist > weapon.attack_range:
                        continue

                # Vérifier l'angle (cône devant l'attaquant)
                var forward = -attacker.mesh.global_transform.basis.z.normalized()
                var angle = rad_to_deg(forward.angle_to(to_target.normalized()))
                if angle > weapon.attack_angle / 2.0:
                        continue

                # Calculer les dégâts (réduction si blocage)
                var damage = weapon.damage
                if _blocking.get(target_id, false):
                        damage = int(damage * (1.0 - SHIELD.block_damage_reduction))

                # Appliquer le recul
                var knockback_dir = to_target.normalized()
                _apply_damage.rpc(target_id, damage, knockback_dir * weapon.knockback_force)


## Client → serveur: "je tire à l'arc dans cette direction"
@rpc("any_peer", "call_local", "reliable")
func request_ranged_attack(aim_dir: Vector3) -> void:
        if not multiplayer.is_server():
                return
        var attacker_id = (multiplayer.get_remote_sender_id() if multiplayer.get_remote_sender_id() != 0 else multiplayer.get_unique_id())
        var match_mgr = get_parent()
        var attacker = match_mgr.players_in_match.get(attacker_id)
        if not attacker or not is_instance_valid(attacker):
                return

        var weapon: Weapon = attacker.equipped_weapon
        if weapon == null or weapon.type != Weapon.Type.RANGED:
                return

        var now = Time.get_ticks_msec() / 1000.0
        var last: float = _last_attack.get(attacker_id, 0.0)
        if now - last < weapon.cooldown_sec:
                return
        if attacker.stamina < weapon.stamina_cost:
                return
        attacker.stamina -= weapon.stamina_cost
        _last_attack[attacker_id] = now

        # Pour le prototype: raycast instantané dans la direction de l'arc
        # (en production: spawn un projectile RigidBody3D avec gravité)
        var origin = attacker.global_position + Vector3.UP * 1.0
        var end = origin + aim_dir.normalized() * 50.0

        # Vérifier tous les joueurs sur le chemin (simplifié: distance à la ligne)
        for target_id in match_mgr.players_in_match:
                if target_id == attacker_id:
                        continue
                var target = match_mgr.players_in_match[target_id]
                if not is_instance_valid(target) or target.player_state >= 2:
                        continue
                if target.team == attacker.team:
                        continue
                var closest = _point_line_distance(target.global_position, origin, end)
                if closest < 1.0:  # dans un rayon d'1m de la trajectoire
                        var damage = weapon.damage
                        if _blocking.get(target_id, false):
                                damage = int(damage * (1.0 - SHIELD.block_damage_reduction))
                        _apply_damage.rpc(target_id, damage, aim_dir.normalized() * 3.0)


## Client → serveur: "je bloque / j'arrête de bloquer"
@rpc("any_peer", "call_local", "reliable")
func set_blocking(active: bool) -> void:
        if not multiplayer.is_server():
                return
        var id = (multiplayer.get_remote_sender_id() if multiplayer.get_remote_sender_id() != 0 else multiplayer.get_unique_id())
        _blocking[id] = active


## Serveur → tous: "ce joueur a pris des dégâts"
@rpc("authority", "call_local", "reliable")
func _apply_damage(target_id: int, damage: int, knockback: Vector3) -> void:
        var match_mgr = get_parent()
        var target = match_mgr.players_in_match.get(target_id)
        if not target or not is_instance_valid(target):
                return
        target.health = max(target.health - damage, 0)
        target.health_changed.emit(target.health)

        # Recul
        if knockback.length() > 0.01:
                target.velocity += knockback

        # Si HP = 0 → neutralisé (capturé automatiquement)
        if target.health <= 0:
                target.set_captured(2)
                if multiplayer.is_server():
                        match_mgr.capture_completed.rpc(target_id)

        damage_dealt.emit(target_id, damage)
        print("[COMBAT] %d took %d damage (HP=%d)" % [target_id, damage, target.health])


func _point_line_distance(point: Vector3, line_start: Vector3, line_end: Vector3) -> float:
        var line_vec = line_end - line_start
        var line_len = line_vec.length()
        if line_len < 0.001:
                return point.distance_to(line_start)
        var t = clamp((point - line_start).dot(line_vec) / (line_len * line_len), 0.0, 1.0)
        var closest = line_start + line_vec * t
        return point.distance_to(closest)


func get_weapon(kind: int) -> Weapon:
        match kind:
                0: return SWORD
                1: return DAGGER
                2: return SPEAR
                3: return BOW
                4: return SHIELD
                _: return SWORD
