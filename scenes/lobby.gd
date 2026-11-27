extends Control
## Lobby — salon privé. L'hôte voit le code d'invitation et peut démarrer.
## Les clients voient la liste des joueurs et attendent le démarrage.

@onready var code_label: Label = $VBox/CodeLabel
@onready var player_list: VBoxContainer = $VBox/PlayerList
@onready var start_btn: Button = $VBox/StartBtn
@onready var status_label: Label = $VBox/StatusLabel


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if multiplayer.is_server():
		code_label.text = "Code d'invitation: %s" % NetworkManager.get_invite_code()
		start_btn.visible = true
		status_label.text = "En attente de joueurs..."
	else:
		code_label.text = "Connecté au salon"
		start_btn.visible = false
		status_label.text = "En attente que l'hôte démarre la partie..."

	NetworkManager.peer_connected.connect(_refresh_players)
	NetworkManager.peer_disconnected.connect(_refresh_players)
	NetworkManager.players_synced.connect(_refresh_players)
	NetworkManager.server_disconnected.connect(_on_server_lost)
	_refresh_players()


func _refresh_players(_arg = null) -> void:
	for child in player_list.get_children():
		child.queue_free()
	for peer_id in NetworkManager.players:
		var data: Dictionary = NetworkManager.players[peer_id]
		var label := Label.new()
		var name_str: String = data.get("name", "Player")
		if peer_id == 1:
			label.text = "★ %s (hôte)" % name_str
		else:
			label.text = "  %s" % name_str
		label.add_theme_font_size_override("font_size", 16)
		player_list.add_child(label)

	if multiplayer.is_server():
		status_label.text = "%d joueur(s) connecté(s)" % NetworkManager.players.size()


func _on_start_pressed() -> void:
	if not multiplayer.is_server():
		return
	# Dire à tous les clients d'aller au match
	start_match.rpc()
	GameManager.go_to_match()


@rpc("authority", "call_local", "reliable")
func start_match() -> void:
	GameManager.go_to_match()


func _on_server_lost() -> void:
	print("[LOBBY] Serveur perdu, retour au menu")
	GameManager.go_to_menu()


func _on_back_pressed() -> void:
	GameManager.go_to_menu()
