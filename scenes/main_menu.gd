extends Control
## MainMenu — écran d'accueil.

@onready var name_edit: LineEdit = $VBox/NameEdit
@onready var code_edit: LineEdit = $VBox/JoinBox/CodeEdit


func _ready() -> void:
	NetworkManager.leave()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_host_pressed() -> void:
	var pname := name_edit.text.strip_edges()
	if pname.is_empty():
		pname = "Player"
	GameManager.local_player_name = pname
	var err := NetworkManager.host(pname)
	if err == OK:
		GameManager.go_to_lobby()


func _on_join_pressed() -> void:
	var pname := name_edit.text.strip_edges()
	if pname.is_empty():
		pname = "Player"
	GameManager.local_player_name = pname
	var code := code_edit.text.strip_edges().to_upper()
	if code.is_empty():
		code = "127.0.0.1"
	var address := code
	if code.length() <= 6 and code.length() >= 4:
		address = NetworkManager.decode_invite_code(code)
	print("[MENU] Joining ", address)
	var err := NetworkManager.join(address, pname)
	if err == OK:
		# Attendre la connexion puis aller au lobby
		await NetworkManager.connected_to_server
		GameManager.go_to_lobby()
