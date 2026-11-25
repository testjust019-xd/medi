/**
 * Medieval Hide & Seek — WebSocket Relay Server
 * Permet le multijoueur Internet en relayant les paquets entre clients (NAT traversal).
 *
 * Principe: les clients Godot se connectent via WebSocketPeer au lieu d'ENet direct.
 * Le relay attribue un peer_id à chaque connexion et forward les messages entre
 * les pairs d'une même "room" (identifiée par le code d'invitation).
 *
 * Usage:
 *   node relay-server.js [--port 8080]
 *
 * Côté Godot: remplacer ENetMultiplayerPeer par WebSocketMultiplayerPeer
 *   var peer := WebSocketMultiplayerPeer.new()
 *   peer.create_client("wss://relay.exemple.com:8080/" + invite_code)
 *   multiplayer.multiplayer_peer = peer
 */

const http = require("http");
const { WebSocketServer } = require("ws");

const PORT = process.env.PORT || 8080;

// rooms: Map<roomCode, Map<peerId, WebSocket>>
const rooms = new Map();
let nextPeerId = 1;

const server = http.createServer();
const wss = new WebSocketServer({ server });

wss.on("connection", (ws, req) => {
  // URL format: /<roomCode>
  const urlPath = req.url || "/";
  const roomCode = urlPath.replace(/^\//, "").toUpperCase().substring(0, 6) || "DEFAULT";

  const peerId = nextPeerId++;
  ws.peerId = peerId;
  ws.roomCode = roomCode;

  // Rejoindre la room
  if (!rooms.has(roomCode)) {
    rooms.set(roomCode, new Map());
  }
  const room = rooms.get(roomCode);
  room.set(peerId, ws);

  console.log(`[RELAY] Peer ${peerId} joined room ${roomCode} (${room.size} peers)`);

  // Envoyer son peer_id au client
  ws.send(JSON.stringify({ type: "assign", peerId: peerId }));

  // Si c'est le premier de la room, il devient le host (id=1)
  if (room.size === 1 && peerId !== 1) {
    // Reassigner à 1 pour compatibilité Godot (server=id 1)
    ws.peerId = 1;
    room.delete(peerId);
    room.set(1, ws);
    ws.send(JSON.stringify({ type: "assign", peerId: 1 }));
    console.log(`[RELAY] Peer reassigned to host (id=1) in room ${roomCode}`);
  }

  // Notifier les autres peers
  for (const [pid, pws] of room) {
    if (pid !== ws.peerId && pws.readyState === 1) {
      pws.send(JSON.stringify({ type: "peer_joined", peerId: ws.peerId }));
    }
  }

  ws.on("message", (data, isBinary) => {
    // Forward le message au peer cible ou à tous
    try {
      if (isBinary) {
        // Paquet binaire: format [targetPeerId (4 bytes BE)] [payload]
        const targetId = data.readUInt32BE(0);
        const payload = data.subarray(4);
        if (targetId === 0) {
          // Broadcast à tous sauf l'expéditeur
          for (const [pid, pws] of room) {
            if (pid !== ws.peerId && pws.readyState === 1) {
              pws.send(Buffer.concat([Buffer.from(ws.peerId.toString().padStart(4, "0")), payload]));
            }
          }
        } else {
          // Unicast au peer cible
          const targetWs = room.get(targetId);
          if (targetWs && targetWs.readyState === 1) {
            targetWs.send(Buffer.concat([Buffer.from(ws.peerId.toString().padStart(4, "0")), payload]));
          }
        }
      }
    } catch (e) {
      console.error("[RELAY] Error forwarding:", e.message);
    }
  });

  ws.on("close", () => {
    room.delete(ws.peerId);
    console.log(`[RELAY] Peer ${ws.peerId} left room ${roomCode} (${room.size} remaining)`);
    // Notifier les autres
    for (const [pid, pws] of room) {
      if (pws.readyState === 1) {
        pws.send(JSON.stringify({ type: "peer_left", peerId: ws.peerId }));
      }
    }
    // Nettoyer la room si vide
    if (room.size === 0) {
      rooms.delete(roomCode);
      console.log(`[RELAY] Room ${roomCode} deleted (empty)`);
    }
  });

  ws.on("error", (err) => {
    console.error(`[RELAY] WebSocket error (peer ${ws.peerId}):`, err.message);
  });
});

server.listen(PORT, () => {
  console.log(`[RELAY] Medieval Hide & Seek relay server running on port ${PORT}`);
  console.log(`[RELAY] Connect Godot clients with: wss://your-host:${PORT}/<inviteCode>`);
});
