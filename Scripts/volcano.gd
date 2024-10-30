extends Node
class_name Volcano


@export var residing_region : Region
@export var dummy_alignment : int

var pathways : Array[VolcanoPath] = []

@onready var region_control : RegionControl


var call_end_turn : bool = false
var active : bool = false
var iteration : int = 0


func _ready():
	region_control = get_parent() as RegionControl
	if not region_control:
		push_warning("Volcano could not find region control, thus it is not functional.")
		queue_free()
		return
	if region_control.dummy:
		queue_free()
		return
	if not residing_region:
		push_warning("Volcano could not find residing region, thus it is not functional.")
		queue_free()
		return
	
	for node in get_children():
		if not node is VolcanoPath:
			continue
		var path : VolcanoPath = node as VolcanoPath
		pathways.append(path)
		for reg_name in path.pathway_strings:
			var region = region_control.get_region(reg_name)
			if not region:
				continue
			path.pathway.append(region)
			
			if not region.has_node("VolcanoWarning"):
				var warning : RegionWarning = preload("res://Objects/warning.tscn").instantiate() as RegionWarning
				warning.warning_number = 1
				warning.name = "VolcanoWarning"
				warning.color = region_control.align_color[dummy_alignment]
				region.add_child(warning)
	
	region_control.turn_ended.connect(_start_volcano_turn)
	call_deferred("activate_pathways")
	call_deferred("_deferred_ready")


func _deferred_ready():
	region_control.ai_control.timer_has_ended.connect(_ai_control_timer_ended)
	region_control.alignment_aliances[dummy_alignment] = -1


func _ai_control_timer_ended():
	if active:
		if call_end_turn:
			region_control.turn_end(true)
			active = false
			call_end_turn = false
		else:
			call_end_turn = true
			for path in pathways:
				if not path.active:
					continue
				call_end_turn = false
				var region : Region = path.pathway[path.current] as Region
				region.incoming_attack(6, region.max_power + 1)
				region.city_particle(false)
				path.current += 1
				if path.current >= path.pathway.size():
					path.active = false
			if call_end_turn:
				activate_pathways()


func activate_pathways():
	for path in pathways:
		path.active = ((iteration + path.chosen_offset) % path.chosen_frequency) == 0
		if not path.active:
			path.hide_warnings()
		path.current = 0
	for path in pathways:
		if path.active:
			path.show_warnings()
	iteration += 1


func _start_volcano_turn():
	if region_control.current_playing_align != dummy_alignment:
		return
	
	if residing_region.power == residing_region.max_power:
		residing_region.power = 1
		residing_region.city_particle(true)
	else:
		residing_region.reinforce(dummy_alignment)
		residing_region.city_particle(false)
		call_end_turn = true
	
	active = true
