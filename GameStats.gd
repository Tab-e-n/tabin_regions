extends Node

var default_stats : Dictionary = {
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
	
