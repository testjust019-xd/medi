extends Node
## GameManager — navigation entre scènes et état global.

enum State { MENU, LOBBY, MATCH, RESULT }

var state: State = State.MENU
var local_player_name: String = "Player"
var selected_map: String = "res://world/maps/kingdom.tscn"
var medieval_unknown: bool = false

func _ready() -> void:
	# Navigateur : ?map=castle|forest|kingdom|greybox choisit la carte au lancement.
	if OS.has_feature("web"):
		var m = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('map')")
		if m is String and m in ["castle", "forest", "kingdom", "greybox"]:
			selected_map = "res://world/maps/%s.tscn" % m

func _change_scene(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Impossible de charger %s : %s" % [path, error_string(err)])

func go_to_lobby() -> void:
	state = State.LOBBY
	_change_scene("res://scenes/lobby.tscn")

func go_to_match() -> void:
	state = State.MATCH
	_change_scene("res://scenes/match.tscn")

func go_to_menu() -> void:
	state = State.MENU
	_change_scene("res://scenes/main_menu.tscn")

func go_to_result(winner: String) -> void:
	state = State.RESULT
	print("[Game] Winner: ", winner)
	go_to_menu()
