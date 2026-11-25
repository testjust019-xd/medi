extends Node
## EventDirector — événements dynamiques du royaume Valdoria.

signal event_started(event_id: String, data: Dictionary)
signal event_updated(event_id: String, data: Dictionary)
signal event_ended(event_id: String, outcome: String)

@export var enabled: bool = true
@export var min_interval_sec: float = 45.0
@export var max_interval_sec: float = 120.0
@export var max_active_events: int = 2

var _timer: float = 20.0
var _active: Dictionary = {}
var _history: Array[Dictionary] = []
var _lore: Dictionary = {}
var _rng := RandomNumberGenerator.new()

const CATALOG := [
	{"id": "village_market", "name": "Marché du village", "type": "ordinary", "duration": 90.0, "weight": 3.0, "description": "Les étals s'animent. Marchands et villageois se rassemblent."},
	{"id": "neighbor_dispute", "name": "Dispute de voisins", "type": "ordinary", "duration": 60.0, "weight": 2.5, "description": "Deux habitants s'invectivent sur la place. La foule s'attroupe."},
	{"id": "the_condemned", "name": "Le Condamné", "type": "important", "duration": 120.0, "weight": 1.2, "description": "Un habitant doit être jugé. Les témoignages se contredisent.", "player_choices": true},
	{"id": "lost_traveler", "name": "Voyageur perdu", "type": "ordinary", "duration": 50.0, "weight": 2.0, "description": "Un voyageur demande son chemin, confus et inquiet."},
	{"id": "mystery_letter", "name": "Lettre oubliée", "type": "mystery", "duration": 40.0, "weight": 1.0, "description": "Une lettre froissée apparaît près d'un bâtiment. Personne ne la réclame."},
	{"id": "tavern_brawl", "name": "Bagarre de taverne", "type": "ordinary", "duration": 45.0, "weight": 2.0, "description": "Des voix s'élèvent dans la taverne. Une dispute dégénère — stylisée, sans sang."},
	{"id": "escaped_animal", "name": "Animal échappé", "type": "ordinary", "duration": 40.0, "weight": 2.2, "description": "Une bête de ferme court dans les rues. Les villageois s'agitent."},
	{"id": "guard_arrest", "name": "Arrestation", "type": "important", "duration": 70.0, "weight": 1.3, "description": "Les gardes emmènent un habitant. La foule murmure."},
	{"id": "missing_villager", "name": "Disparition", "type": "important", "duration": 80.0, "weight": 1.0, "description": "Un habitant n'est pas rentré. On fouille les environs."},
]

func _ready() -> void:
	_rng.randomize()
	_load_lore()
	_timer = _rng.randf_range(15.0, min_interval_sec)
	print("[EventDirector] Valdoria online. Next event in ~%.0fs" % _timer)
	await get_tree().process_frame
	var hud := get_tree().current_scene.get_node_or_null("HUD") if get_tree().current_scene else null
	if hud:
		if not event_started.is_connected(hud.show_event):
			event_started.connect(hud.show_event)
		if not event_updated.is_connected(hud.update_event):
			event_updated.connect(hud.update_event)
		if not event_ended.is_connected(_on_event_ended):
			event_ended.connect(_on_event_ended)

func _on_event_ended(event_id: String, outcome: String) -> void:
	var hud := get_tree().current_scene.get_node_or_null("HUD") if get_tree().current_scene else null
	if hud and hud.has_method("hide_event"):
		hud.hide_event()
	print("[EventDirector] HUD cleared after ", event_id, " / ", outcome)

func _load_lore() -> void:
	var path := "res://data/lore/valdoria.json"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		var json := JSON.new()
		if json.parse(f.get_as_text()) == OK:
			_lore = json.data
			print("[EventDirector] Lore loaded: ", _lore.get("kingdom_name", "?"))
	else:
		_lore = {"kingdom_name": "Valdoria"}

func _process(delta: float) -> void:
	if not enabled:
		return
	var to_end: Array[String] = []
	for id in _active.keys():
		var ev: Dictionary = _active[id]
		ev["time_left"] = float(ev.get("time_left", 0.0)) - delta
		if ev["time_left"] <= 0.0:
			to_end.append(id)
		else:
			_active[id] = ev
	for id in to_end:
		_end_event(id, str(_active[id].get("outcome", "expired")))
	_timer -= delta
	if _timer <= 0.0 and _active.size() < max_active_events:
		_try_start_random_event()
		_timer = _rng.randf_range(min_interval_sec, max_interval_sec)

func _try_start_random_event() -> void:
	var pool: Array = []
	var total_w := 0.0
	for def in CATALOG:
		if _active.has(def["id"]):
			continue
		var w := float(def.get("weight", 1.0))
		if def.get("type") == "mystery":
			w *= 0.7
		pool.append(def)
		total_w += w
	if pool.is_empty() or total_w <= 0.0:
		return
	var roll := _rng.randf() * total_w
	var acc := 0.0
	var chosen: Dictionary = pool[0]
	for def in pool:
		acc += float(def.get("weight", 1.0))
		if roll <= acc:
			chosen = def
			break
	_start_event(chosen)

func _start_event(def: Dictionary) -> void:
	var id := str(def["id"])
	var data := {
		"id": id,
		"name": def.get("name", id),
		"type": def.get("type", "ordinary"),
		"description": def.get("description", ""),
		"time_left": float(def.get("duration", 60.0)),
		"duration": float(def.get("duration", 60.0)),
		"player_choices": def.get("player_choices", false),
		"outcome": "ongoing",
		"stage": 0,
	}
	match id:
		"the_condemned":
			data["guilt_hint"] = _rng.randf() > 0.5
			data["outcome"] = "pending_player"
		"neighbor_dispute":
			data["heat"] = 1
		"village_market":
			data["stalls_open"] = true
	_active[id] = data
	_history.append({"id": id, "started_at": Time.get_unix_time_from_system(), "name": data["name"]})
	if _history.size() > 30:
		_history.pop_front()
	event_started.emit(id, data)
	print("[EventDirector] START %s — %s" % [data["name"], data["description"]])
	_notify_npcs(Vector3.ZERO, 40.0)

func _end_event(id: String, outcome: String) -> void:
	if not _active.has(id):
		return
	var data: Dictionary = _active[id]
	data["outcome"] = outcome
	_active.erase(id)
	event_ended.emit(id, outcome)
	print("[EventDirector] END %s → %s" % [data.get("name", id), outcome])
	_record_memory(id, str(data.get("name", id)), outcome)

func _record_memory(event_id: String, event_name: String, outcome: String) -> void:
	var mem := get_node_or_null("/root/WorldMemory")
	if mem == null and get_tree().current_scene:
		mem = get_tree().current_scene.get_node_or_null("WorldMemory")
	if mem and mem.has_method("record_event"):
		mem.record_event(event_id, event_name, outcome)

func player_intervene(event_id: String, choice: String) -> bool:
	if not _active.has(event_id):
		return false
	var ev: Dictionary = _active[event_id]
	if event_id == "the_condemned":
		match choice:
			"observe":
				ev["description"] = "Tu observes. Les témoignages restent contradictoires."
				ev["outcome"] = "observed"
			"find_proof":
				if ev.get("guilt_hint", false):
					ev["outcome"] = "acquitted"
					ev["description"] = "Une preuve d'alibi est trouvée. Le jugement est réexaminé."
				else:
					ev["outcome"] = "confirmed_guilty"
					ev["description"] = "La preuve confirme les accusations. Le procès suit son cours."
				ev["time_left"] = 8.0
			"convince_witness":
				ev["outcome"] = "investigation"
				ev["description"] = "Un témoin accepte de parler aux gardes. Une enquête s'ouvre."
				ev["time_left"] = 10.0
			"alert_guards":
				ev["outcome"] = "guards_arrive"
				ev["description"] = "Les gardes renforcent la place. L'événement s'étend."
				ev["time_left"] = 12.0
			"leave":
				ev["outcome"] = "left"
				ev["description"] = "Tu quittes les lieux. Les conséquences se joueront sans toi."
				ev["time_left"] = 5.0
			_:
				return false
		_active[event_id] = ev
		event_updated.emit(event_id, ev)
		print("[EventDirector] Player choice on %s: %s → %s" % [event_id, choice, ev["outcome"]])
		return true
	return false

func get_active_events() -> Array:
	return _active.values()

func get_lore() -> Dictionary:
	return _lore

func get_history() -> Array:
	return _history

func _notify_npcs(pos: Vector3, radius: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("npc_manager"):
		if n.has_method("notify_event"):
			n.notify_event(pos, radius)
	var match_root := tree.current_scene
	if match_root:
		var mgr := match_root.get_node_or_null("NpcManager")
		if mgr and mgr.has_method("notify_event"):
			mgr.notify_event(pos, radius)

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if not _active.has("the_condemned"):
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var choice := ""
	match event.keycode:
		KEY_1: choice = "observe"
		KEY_2: choice = "find_proof"
		KEY_3: choice = "convince_witness"
		KEY_4: choice = "alert_guards"
		KEY_5: choice = "leave"
		_: return
	player_intervene("the_condemned", choice)
