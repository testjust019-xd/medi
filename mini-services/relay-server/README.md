# Relay Server — Multijoueur Internet

Le relay WebSocket permet de jouer sur Internet en traversant le NAT (la plupart des box opérateurs bloquent les connexions entrantes).

## Principe

```
Client 1 (Godot) ──WebSocket──┐
                              ├── Relay Server ──── forward les paquets entre pairs
Client 2 (Godot) ──WebSocket──┘
```

Au lieu d'une connexion ENet directe (bloquée par le NAT), les clients se connectent au relay via WebSocket. Le relay forward les paquets entre les pairs d'une même room (identifiée par le code d'invitation).

## Installation

```bash
cd mini-services/relay-server
npm install    # installe le module ws
```

## Démarrage

```bash
npm start                      # port 8080 par défaut
# ou
node relay-server.js --port 3001
```

## Déploiement

Déployez le relay sur un serveur public (VPS, Railway, Fly.io, Render...). Il doit être accessible depuis internet (IP publique + port ouvert).

Exemple avec Fly.io :
```bash
fly deploy   # après avoir configuré fly.toml
```

## Côté Godot — connexion via WebSocket

Remplacez l'ENet peer par un WebSocket peer dans `network_manager.gd` :

```gdscript
# Connexion Internet via relay
func join_relay(relay_url: String, invite_code: String, player_name: String) -> Error:
    var peer := WebSocketMultiplayerPeer.new()
    var url := "%s/%s" % [relay_url, invite_code.to_upper()]
    var err := peer.create_client(url)
    if err != OK:
        push_error("Cannot join relay: %s" % error_string(err))
        return err
    multiplayer.multiplayer_peer = peer
    _connect_signals()
    return OK
```

Le relay assigne automatiquement le peer_id 1 au premier client (hôte) et des ids suivants aux autres.

## Format des paquets

- **Paquets de contrôle** (JSON texte) : `assign`, `peer_joined`, `peer_left`
- **Paquets de jeu** (binaire) : `[targetPeerId (4 bytes BE)] [payload]`
  - targetPeerId = 0 → broadcast à tous les pairs
  - targetPeerId = N → unicast au pair N

## Notes

- Le relay ne valide pas les paquets de jeu (c'est le serveur Godot qui le fait)
- Pour la production: ajouter TLS (wss://), authentification, rate limiting
- Le relay est stateless entre les rooms (une room vide est supprimée)
