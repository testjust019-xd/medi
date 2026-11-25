extends Node
## WorldMemory — mémoire légère du royaume (user:// JSON).

const SAVE_PATH := "user://valdoria_world_memory.json"
const MAX_EVENTS := 50
const MAX_NPC_FACTS := 40

var kingdom_name: String = "Valdoria"
var events: Array = []
var npc_facts: Array = []
var player_rep: Dictionary = {}
var flags: Dictionary = {}

signal memory_changed()

func _ready() -> void:
	load_memory()
	print("[WorldMemory] Loaded %d events, rep=%s" % [events.size(), player_rep])

func load_memory() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		return
	var data: Dictionary = json.data
	events = data.get("events", [])
	npc_facts = data.get("npc_facts", [])
	player_rep = data.get("player_rep", {})
	flags = data.get("flags", {})
	kingdom_name = data.get("kingdom_name", "Valdoria")

func save_memory() -> void:
	var data := {
		"kingdom_name": kingdom_name,
		"events": events,
		"npc_facts": npc_facts,
		"player_rep": player_rep,
		"flags": flags,
		"saved_at": Time.get_unix_time_from_system(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))

func record_event(event_id: String, event_name: String, outcome: String) -> void:
	events.append({"id": event_id, "name": event_name, "outcome": outcome, "at": Time.get_unix_time_from_system()})
	while events.size() > MAX_EVENTS:
		events.pop_front()
	if event_id == "the_condemned":
		match outcome:
			"acquitted", "investigation":
				flags["condemned_helped"] = true
				_add_rep("local", 3)
			"confirmed_guilty":
				flags["condemned_guilty"] = true
			"left", "observed":
				flags["condemned_ignored"] = true
			"guards_arrive":
				flags["condemned_guards"] = true
				_add_rep("local", 1)
	save_memory()
	memory_changed.emit()

func record_npc_fact(npc_id: String, fact: String) -> void:
	npc_facts.append({"npc_id": npc_id, "fact": fact, "at": Time.get_unix_time_from_system()})
	while npc_facts.size() > MAX_NPC_FACTS:
		npc_facts.pop_front()
	save_memory()

func _add_rep(key: String, delta: int) -> void:
	var v := int(player_rep.get(key, 0)) + delta
	player_rep[key] = clampi(v, -50, 50)

func get_rep(key: String = "local") -> int:
	return int(player_rep.get(key, 0))

func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))

func get_recent_events(n: int = 5) -> Array:
	if events.is_empty():
		return []
	var start := maxi(0, events.size() - n)
	return events.slice(start, events.size())

func summary_line() -> String:
	var rep := get_rep()
	var last := ""
	if events.size() > 0:
		var e: Dictionary = events[events.size() - 1]
		last = "%s (%s)" % [e.get("name", "?"), e.get("outcome", "?")]
	return "Valdoria | réputation %d | dernier: %s" % [rep, last if last else "—"]
