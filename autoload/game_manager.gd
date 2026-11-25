extends Node
## GameManager — navigation entre scènes et état global.

enum State { MENU, LOBBY, MATCH, RESULT }

var state: State = State.MENU
var local_player_name: String = "Player"
var selected_map: String = "res://world/maps/kingdom.tscn"
var medieval_unknown: bool = false

func go_to_lobby() -> void:
	state = State.LOBBY
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func go_to_match() -> void:
	state = State.MATCH
	get_tree().change_scene_to_file("res://scenes/match.tscn")

func go_to_menu() -> void:
	state = State.MENU
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func go_to_result(winner: String) -> void:
	state = State.RESULT
	print("[Game] Winner: ", winner)
	go_to_menu()
