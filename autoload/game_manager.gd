extends Node
## GameManager — autoload
## Machine à états du jeu: MENU -> LOBBY -> MATCH -> RESULT

enum State { MENU, LOBBY, MATCH, RESULT }

signal state_changed(new_state: State)

var state: State = State.MENU
var local_player_name: String = "Player"
var selected_map: String = "res://world/maps/kingdom.tscn"  # carte par défaut


func go_to_lobby() -> void:
        get_tree().change_scene_to_file("res://scenes/lobby.tscn")
        state = State.LOBBY
        state_changed.emit(state)


func go_to_match() -> void:
        get_tree().change_scene_to_file("res://scenes/match.tscn")
        state = State.MATCH
        state_changed.emit(state)


func go_to_menu() -> void:
        NetworkManager.leave()
        get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
        state = State.MENU
        state_changed.emit(state)


func go_to_result(winner: String) -> void:
        # Pour le prototype: affiche le résultat et retour au menu après 5s
        print("[GAME] Match terminé — gagnant: ", winner)
        await get_tree().create_timer(5.0).timeout
        go_to_menu()
