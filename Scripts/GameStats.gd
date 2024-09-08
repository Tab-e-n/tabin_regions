extends Node


var DEFAULT_STATS : Dictionary = {
	"alignment name" : "",
	"align color" : Color(0, 0, 0, 0),
	"controler" : 0,
	"placement" : "N/A",
	"turns lasted" : 0,
	"first actions done" : 0,
	"bonus actions done" : 0,
	"enemy units removed" : 0,
	"units lost" : 0,
	"units mobilized" : 0,
	"most regions owned" : 0,
	"most capitals owned" : 0,
	"regions captured" : 0,
	"regions reinforced" : 0,
	"capital regions captured" : 0,
	
#	"killer alignment" : "",
}

var stats : Array = []


func reset_statistics(align_amount):
	stats.clear()
	stats.resize(align_amount)
	for i in range(align_amount):
		stats[i] = DEFAULT_STATS.duplicate()


func stat_exists(align : int, key : String) -> bool:
	if align < 0 or align >= stats.size():
		push_warning("Alignment ", align, " isn't in the statistics table.")
		return false
	if not stats[align].has(key):
		push_warning("Statistic ", key, " doesn't exist.")
		return false
	return true


func add_to_stat(align : int, key : String, value):
	if not stat_exists(align, key):
		return
	if not typeof(stats[align][key]) in [TYPE_FLOAT, TYPE_INT]:
		return
	stats[align][key] += value


func set_stat(align : int, key : String, value):
	if not stat_exists(align, key):
		return
	stats[align][key] = value


func get_stat(align : int, key : String):
	if not stat_exists(align, key):
		return null
	return stats[align][key]


func stat_keys_as_strings() -> PackedStringArray:
	return DEFAULT_STATS.keys()


func stats_as_strings(align : int) -> PackedStringArray:
	var str_stats : PackedStringArray = []
	for i in DEFAULT_STATS.keys():
		if i in ["alignment name", "placement"]:
			str_stats.append(stats[align][i])
		elif i == "align color":
			str_stats.append("#" + stats[align][i].to_html(false))
		elif i == "controler":
			str_stats.append(AIControler.CONTROLER_NAMES[stats[align][i]])
		else:
			str_stats.append(String.num(stats[align][i]))
	
	return str_stats


func save_as_csv(file_name : String):
	if FileAccess.file_exists("user://" + file_name + ".csv"):
		var i : int = 1
		while FileAccess.file_exists("user://" + file_name + " " + str(i) + ".csv"):
			i += 1
		file_name += " " + str(i)
	
	var file = FileAccess.open("user://" + file_name + ".csv", FileAccess.WRITE)
	
	file.store_csv_line(stat_keys_as_strings())
	for i in range(stats.size()):
		file.store_csv_line(stats_as_strings(i))
	
	file.close()
