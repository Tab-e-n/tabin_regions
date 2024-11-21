extends Node


enum {RECORD_TYPE_REGION, RECORD_TYPE_FUNCTION, RECORD_TYPE_OVERTAKE}


var replay_active : bool = false

var replay : Dictionary = {}
var current_replay_pos : int = 0

var replay_play_order : Array = []
var replay_controlers : Array = []

var replay_uses_aliances : bool = false
var replay_aliances : Array[int] = []

var replay_removed_alignments : Array = []


func clear_replay():
	replay.clear()
	current_replay_pos = 0
	replay_play_order.clear()
	replay_uses_aliances = false
	replay_aliances.clear()
	replay_controlers.clear()
	replay_active = false


func record_move(type : int, action : String):
	if not replay_active:
		replay[str(current_replay_pos)] = [type, action]
		current_replay_pos += 1
#		print([type, action])


func get_next_move():
	if current_replay_pos < replay.keys().size():
		var next_move = replay[str(current_replay_pos)]
		current_replay_pos += 1
#		print(current_replay_pos)
		return next_move
	else:
		return [1, "nothing"]


func save_replay(replay_name : String):
	var replay_save : Dictionary = {
		"replay_map" : MapSetup.current_map_name,
		"replay_play_order" : replay_play_order,
		"replay_aliances" : replay_aliances,
		"replay_controlers" : replay_controlers,
		"replay" : replay,
		"replay_uses_aliances" : replay_uses_aliances,
		"replay_removed_alignments" : replay_removed_alignments,
	}
	
	
	if FileAccess.file_exists("user://REPLAY " + replay_name + ".json"):
		var i : int = 1
		while FileAccess.file_exists("user://REPLAY " + replay_name + " " + str(i) + ".json"):
			i += 1
		replay_name += " " + str(i)
	
	var file = FileAccess.open("user://REPLAY " + replay_name + ".json", FileAccess.WRITE)
	
	file.store_string(JSON.stringify(replay_save))
	
	file.close()


func load_replay(replay_name : String):
	var replay_save : Dictionary = {
	}
	
	if FileAccess.file_exists(replay_name):
		var file = FileAccess.open(replay_name, FileAccess.READ)
		
		replay_save = JSON.parse_string(file.get_as_text())
		
		file.close()
		
		MapSetup.current_map_name = replay_save["replay_map"]
		
		replay_play_order = replay_save["replay_play_order"]
		replay_controlers = replay_save["replay_controlers"]
		replay = replay_save["replay"]
		replay_uses_aliances = replay_save["replay_uses_aliances"]
		replay_removed_alignments = replay_save["replay_removed_alignments"]
		
		var ra_size = replay_save["replay_aliances"].size()
		replay_aliances.resize(ra_size)
		for i in range(ra_size):
			replay_aliances[i] = int(replay_save["replay_aliances"][i])
		
		replay_active = true
		
		return true
	else:
		return false
