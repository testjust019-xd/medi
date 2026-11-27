extends Node
## NetworkManager — autoload
## ENet host/join, codes d'invitation, signaux de connexion.

signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal connected_to_server()
signal server_disconnected()
signal players_synced()

const PORT: int = 7000
const MAX_PLAYERS: int = 8

var players: Dictionary = {}  # peer_id -> { name, team, ready }


func host(player_name: String) -> Error:
	# Navigateur : pas d'UDP/ENet -> partie solo locale (le multijoueur web passe par le relay).
	if OS.has_feature("web"):
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
		players.clear()
		players[1] = { "name": player_name, "team": 0, "ready": false }
		peer_connected.emit(1)
		return OK
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		push_error("Cannot host: %s" % error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	_connect_signals()
	players.clear()
	players[1] = { "name": player_name, "team": 0, "ready": false }
	peer_connected.emit(1)
	return OK


func join(address: String, player_name: String) -> Error:
	if OS.has_feature("web"):
		push_error("Rejoindre une partie n'est pas encore disponible dans le navigateur (relay requis).")
		return ERR_UNAVAILABLE
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, PORT)
	if err != OK:
		push_error("Cannot join: %s" % error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	_connect_signals()
	players.clear()
	players[multiplayer.get_unique_id()] = { "name": player_name, "team": 0, "ready": false }
	return OK


func leave() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()


## Code d'invitation court (IP:port encodé en base64, 6 caractères)
func get_invite_code() -> String:
	var addresses := IP.get_local_addresses()
	var ip := "127.0.0.1"
	for addr in addresses:
		if addr != "0.0.0.0" and not addr.begins_with("::") and not addr.begins_with("127"):
			ip = str(addr)
			break
	var raw := "%s:%d" % [ip, PORT]
	return Marshalls.utf8_to_base64(raw).substr(0, 6).to_upper()


## Décode un code d'invitation en adresse IP
func decode_invite_code(code: String) -> String:
	var padded := code + "====".substr(0, (4 - code.length() % 4) % 4)
	var decoded := Marshalls.base64_to_utf8(padded)
	if ":" in decoded:
		return decoded.split(":")[0]
	return "127.0.0.1"


func _connect_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)


# RPC: un client s'enregistre auprès du serveur avec son nom
@rpc("any_peer", "call_local", "reliable")
func register_player(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	players[id] = { "name": player_name, "team": 0, "ready": false }
	# Diffuser la liste mise à jour à tous les clients
	sync_players.rpc(players)


@rpc("authority", "call_local", "reliable")
func sync_players(updated: Dictionary) -> void:
	players = updated
	players_synced.emit()


func _on_peer_connected(id: int) -> void:
	print("[NET] peer_connected: ", id)
	peer_connected.emit(id)
	# Le nouveau client s'enregistre (seul le serveur stocke)
	if multiplayer.is_server():
		pass  # attend register_player du client


func _on_peer_disconnected(id: int) -> void:
	print("[NET] peer_disconnected: ", id)
	players.erase(id)
	peer_disconnected.emit(id)


func _on_connected_to_server() -> void:
	print("[NET] connected_to_server")
	connected_to_server.emit()
	# S'enregistrer auprès du serveur
	var my_name: String = players.get(multiplayer.get_unique_id(), {}).get("name", "Player")
	register_player.rpc_id(1, my_name)


func _on_server_disconnected() -> void:
	print("[NET] server_disconnected")
	server_disconnected.emit()
