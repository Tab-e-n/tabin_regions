extends Node
class_name VolcanoPath


@export var pathway_strings : Array[String] = []
@export var chosen_frequency : int = 5
@export var chosen_offset : int = 0
var pathway : Array[Region] = []
var active : bool = false
var current : int = 0


func show_warnings():
	for region in pathway:
		var warning : RegionWarning = region.get_node("VolcanoWarning") as RegionWarning
		if not warning:
			continue
		warning.show_self()


func hide_warnings():
	for region in pathway:
		var warning : RegionWarning = region.get_node("VolcanoWarning") as RegionWarning
		if not warning:
			continue
		warning.hide_self()
