extends Node


const SAVEFILE : String = "user://OPTIONS.json"


var speedrun_ai : bool = false
var mouse_scroll_active : bool = true
var auto_end_turn_phases : bool = false


func _ready():
	DirAccess.make_dir_absolute("user://Dev")


func save_options():
	var options : Dictionary = {
		"speedrun_ai" : speedrun_ai,
		"mouse_scroll_active" : mouse_scroll_active,
		"auto_end_turn_phases" : auto_end_turn_phases,
	}
	
	var file = FileAccess.open(SAVEFILE, FileAccess.WRITE)
	
	file.store_string(JSON.stringify(options))
	
	file.close()


func load_options():
	var options : Dictionary = {}
	
	if FileAccess.file_exists(SAVEFILE):
		var file = FileAccess.open(SAVEFILE, FileAccess.READ)
		
		options = JSON.parse_string(file.get_as_text())
		
		file.close()
		
		for i in options.keys():
			set(i, options[i])
		
		return true
	else:
		return false
