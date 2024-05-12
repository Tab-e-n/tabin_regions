extends Node


var default_stats : Dictionary = {
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
}

var stats : Array = []


func reset_statistics(align_amount):
	stats.clear()
	stats.resize(align_amount)
	for i in range(align_amount):
		stats[i] = default_stats.duplicate()


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

