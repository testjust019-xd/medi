# Medieval Hide & Seek

**Godot 4** — Jeu multijoueur de cache-cache médiéval avec parkour, combat et exploration.

Prototype jouable (LAN + option internet via relay). Style low-poly / greybox procédural.

---

## Features

### Gameplay
- Cache-cache 2+ joueurs (chasseurs vs fugitifs)
- Capture par maintien
- Équipes, timer, victoire
- Caméra 1ère / 3ème personne

### Mouvement & Parkour
- Marche, course, sprint, saut, crouch
- **Vault** (obstacles bas)
- **Climb** (murs)
- **Wall-run** (gauche / droite)
- **Slide**
- **Grimper aux arbres** (monter / descendre / lâcher)

### Combat & Interaction
- 5 armes : épée, dague, lance, arc, bouclier
- Hit detection serveur-autoritaire, blocage, recul
- Lancer d’objets (pooling) + distraction
- PNJ (villageois, gardes…) avec FSM simple

### Mondes
| Map | Description |
|-----|-------------|
| **Greybox** | Cour fortifiée de test — verticalité, cachettes, parkour |
| **Kingdom** | Grande cité : château, marché, quartiers, remparts, forêt périphérique |
| **Forest** | Forêt interdite : village abandonné, ruines, grottes, pont, **lacs**, animaux, vent sur les feuilles, arbres grimpables |
| **Castle** | Château multi-niveaux (en cours d’amélioration) |

### Technique
- Architecture serveur-autoritaire
- MultiplayerSynchronizer
- Qualité adaptative (ECO / LOW / BALANCED / HIGH)
- InteriorLoader (intérieurs à la demande)
- Relay WebSocket (Node.js) pour internet

---

## Prérequis

- **Godot 4.3+** (4.7 recommandé) — [godotengine.org](https://godotengine.org/download)
- **Node.js 18+** uniquement si tu utilises le relay internet
- Aucun addon tiers

---

## Lancer le projet

1. Godot → Import → `project.godot`
2. Attendre l’import
3. F5 (Play)

### LAN
1. **Hôte** : nom → Héberger → noter le code → Démarrer  
2. **Client** : nom → code ou IP → Rejoindre  

### Internet (optionnel)
```bash
cd mini-services/relay-server
npm install && npm start
```
Voir `mini-services/relay-server/README.md` pour brancher le `WebSocketMultiplayerPeer`.

---

## Contrôles

| Touche | Action |
|--------|--------|
| ZQSD / WASD | Déplacer |
| Shift | Courir |
| Ctrl | Sprint |
| Espace | Sauter / grimper (mur ou arbre) |
| C | S’accroupir / descendre (arbre) |
| Ctrl+C ou Sprint+C | Slide |
| E | Capturer (chasseur) |
| V | Caméra 1ère ↔ 3ème |
| Clic gauche | Attaquer |
| Clic droit | Bloquer |
| Q | Lancer un objet |
| Échap | Libérer la souris |

**Arbres (Forest)**  
Proche d’un tronc + Espace → grimper.  
Espace / Avancer = monter · C / Reculer = descendre · Sprint = lâcher.

---

## Structure

```
autoload/           NetworkManager, GameManager, QualityManager
actors/             Player, NPCs, throwables
scripts/systems/    Match, Combat, Parkour, Throw, InteriorLoader
scripts/ai/         NPC Manager
world/maps/         greybox, kingdom, forest, castle
world/interiors/    Intérieurs de maisons
data/               Armes + règles de match (Resources)
scenes/             main_menu, lobby, match
ui/                 HUD
mini-services/      Relay WebSocket
docs/previews/      Concept art des maps
```

---

## Changer de map

Dans `scenes/match.tscn` (ou via `GameManager.selected_map`) :

- `res://world/maps/greybox.tscn`
- `res://world/maps/kingdom.tscn`
- `res://world/maps/forest.tscn`
- `res://world/maps/castle.tscn`

---

## Configuration rapide

- **Règles de partie** → `data/match_rules/default.tres`
- **Armes** → `data/weapons/*.tres`
- **Densité PNJ** → `scripts/ai/npc_manager.gd`
- **Parkour / arbres** → `scripts/systems/parkour_system.gd` (`tree_climb_speed`, `tree_max_height`, etc.)

---

## Previews (concept)

Des aperçus low-poly des maps se trouvent dans `docs/previews/` :

- `greybox_overview.jpg` / `greybox_ground.jpg`
- `forest_overview.jpg` / `forest_ground.jpg`

> Ce sont des visualisations de style, pas des screenshots moteur. Le rendu exact se voit en lançant Godot.

---

## Roadmap courte

- [x] Parkour solide (vault, climb, wall-run, slide, arbres)
- [x] Greybox + Kingdom + Forest enrichis
- [ ] Castle (multi-niveaux, passages, verticalité)
- [ ] Polish combat & feedback
- [ ] Animaux un peu plus vivants
- [ ] Sons / ambiance

---

## Licence

Prototype — à définir.


---

## Jouer dans le navigateur / sur téléphone (HTML5)

Chaque push sur `main` exporte le jeu en HTML5 et le publie sur GitHub Pages
(workflow `.github/workflows/web.yml`).

1. Repo → **Settings → Pages → Source : GitHub Actions** (une seule fois)
2. Pousser sur `main` (ou lancer le workflow à la main dans l'onglet *Actions*)
3. Ouvrir `https://<utilisateur>.github.io/<repo>/` sur le téléphone, en paysage

- **Contrôles tactiles** (`autoload/touch_controls.gd`) : joystick à gauche, glisser à droite pour regarder, boutons d'action.
- Dans le navigateur, **Explorer** lance une partie solo locale (ENet/UDP n'existe pas sur le web). Rejoindre une partie demandera le relay WebSocket.
- Le rendu web utilise le moteur *Compatibilité* (obligatoire pour le web).
