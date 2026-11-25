# Medieval Hide & Seek — Godot 4

Jeu multijoueur médiéval de cache-cache avec exploration, poursuites, combats et parkour.

## État du projet

### V1 Prototype (jouable)
- Cache-cache 2+ joueurs, capture par maintien
- Mouvement: marche, course, sprint, saut, accroupi
- Caméra 1ère/3ème personne
- Salles privées LAN avec code d'invitation
- Carte greybox (cour médiévale)
- HUD: timer, HP, endurance, capture
- Système de qualité adaptatif (ECO/LOW/BALANCED/HIGH)

### Systèmes avancés (code complet)
- **Combat**: 5 armes (épée, dague, lance, arc, bouclier), hit detection serveur-autoritaire, dégâts, blocage, recul
- **PNJ**: villageois/marchands/gardes/farmers avec FSM (idle/patrol/react), densité configurable, ne révèlent pas les fugitifs
- **Lancer d'objets**: pierres/bouteilles/vases/bois avec RigidBody3D, pooling, dégâts configurables, distraction sonore
- **Parkour**: grimper, vault, slide, wall-run (détection par raycasts)
- **Bâtiments explorables**: InteriorLoader charge/décharge les intérieurs par proximité (gestion mémoire)
- **3 cartes**: KINGDOM (cité fortifiée), THE FORBIDDEN FOREST (forêt+ruines), THE ROYAL CASTLE (château multi-niveaux)
- **Internet multiplayer**: relay WebSocket pour NAT traversal (Node.js)

## Prérequis

- **Godot 4.3+** (recommandé 4.7) — [godotengine.org](https://godotengine.org/download)
- **Node.js 18+** (pour le relay server internet uniquement)
- Aucun addon tiers requis

## Ouverture

1. Godot Project Manager → Import → sélectionner `project.godot`
2. Attendre l'import des ressources
3. Play (F5)

## Comment jouer

### LAN (2 joueurs, même réseau)
1. **Hôte**: nom → « Héberger » → noter le code → « Démarrer »
2. **Client**: nom → saisir le code ou l'IP → « Rejoindre »

### Internet (via relay)
1. Démarrer le relay: `cd mini-services/relay-server && npm install && npm start`
2. Modifier `network_manager.gd` pour utiliser `WebSocketMultiplayerPeer` au lieu d'ENet (voir `mini-services/relay-server/README.md`)
3. Héberger le relay sur un serveur public

### Contrôles

| Touche | Action |
|--------|--------|
| ZQSD/WASD | Déplacer |
| Shift | Courir |
| Ctrl | Sprinter |
| Espace | Sauter |
| C | S'accroupir (Ctrl+C = slide) |
| E | Capturer (chasseur) |
| V | Basculer caméra |
| **Clic gauche** | **Attaquer (arme équipée)** |
| **Clic droit** | **Bloquer (bouclier)** |
| **Q** | **Lancer un objet** |
| Échap | Libérer la souris |

## Changer de carte

Dans `scenes/match.tscn`, remplacer l'instance de `greybox.tscn` par :
- `world/maps/kingdom.tscn` — grande cité fortifiée (château, marché, quartiers, remparts, forêt)
- `world/maps/forest.tscn` — forêt mystérieuse (village abandonné, ruines, grottes, pont)
- `world/maps/castle.tscn` — château multi-niveaux (couloirs, chambres, donjons, cour)

## Structure du projet

```
autoload/               Singletons
  network_manager.gd        ENet/WebSocket host/join, codes d'invitation
  game_manager.gd           Machine à états
  quality_manager.gd        Préréglages ECO/LOW/BALANCED/HIGH

actors/
  player.tscn + .gd         CharacterBody3D, mouvement, combat, lancer, capture
  npcs/npc.tscn + .gd       PNJ avec FSM (idle/patrol/react)
  throwables/throwable.tscn+.gd  Objet lancé (RigidBody3D)

scripts/
  systems/
    match_manager.gd        Timer, capture, victoire, équipement d'armes
    combat_system.gd        Hit detection, dégâts, blocage (serveur-autoritaire)
    throw_system.gd         Pooling, lancer, distraction sonore
    parkour_system.gd       Grimper, vault, slide, wall-run
    interior_loader.gd      Charge/décharge les intérieurs par proximité
  ai/
    npc_manager.gd          Spawn PNJ, densité, notification d'événements

world/maps/
  greybox.tscn + .gd        Carte prototype (cour simple)
  kingdom.tscn + .gd        KINGDOM — cité fortifiée complète
  forest.tscn + .gd         THE FORBIDDEN FOREST
  castle.tscn + .gd         THE ROYAL CASTLE

data/
  match_rules/              Règles de partie (Resource éditable)
  weapons/                  5 armes (sword, dagger, spear, bow, shield)

mini-services/relay-server/ Serveur WebSocket pour internet multiplayer

scenes/                     main_menu, lobby, match
ui/                         HUD (timer, HP, stamina, capture, résultat)
```

## Configuration

### Règles de partie
Éditer `data/match_rules/default.tres` dans l'inspecteur Godot : durée, temps de capture, dégâts des objets, vitesses, endurance.

### Armes
Chaque arme est un `.tres` dans `data/weapons/` : dégâts, portée, angle, cooldown, coût endurance, recul. Pour ajouter une arme: dupliquer un `.tres` existant.

### PNJ
Densité configurable dans `npc_manager.gd` (ECO=0, LOW=5, BALANCED=15, HIGH=30). Changer via `density` avant `_ready()`.

## Architecture technique

- **Serveur-autoritaire**: clients envoient des intentions (RPC `any_peer`), serveur valide et diffuse (`authority`). Aucun trust client.
- **MultiplayerSynchronizer**: réplique position/health/state. Autorité par nœud (name = peer_id).
- **Object pooling**: les objets lancés sont recyclés (pas d'instantiate/free dans la hot loop).
- **Matériaux partagés**: une couleur = un matériau (réduit les draw calls).
- **Renderer Mobile** par défaut (Android). Forward+ sur PC dans Project Settings.

## Notes

- Le parkour system nécessite des RayCast3D enfants (ForwardRay, HighRay, DownRay) sur le joueur — à ajouter dans l'éditeur Godot.
- Les intérieurs de bâtiments nécessitent des scènes d'intérieur dans `world/interiors/` (à créer) + des Area3D sur les portes.
- Les cartes sont générées procéduralement (primitives). Pour des graphismes finals, remplacer par des assets Blender importés en glTF.
- Le combat à l'arc utilise un raycast instantané (simplifié). En production: spawn un projectile RigidBody3D avec gravité.
