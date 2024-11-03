extends Node
class_name Volcano


@export var residing_region : Region
@export var dummy_alignment : int

@onready var controler : AIDummy
@onready var ai_control : AIControler
@onready var region_control : RegionControl

var pathways : Array[VolcanoPath] = []
var active : bool = false
var iteration : int = 0


func _ready():
	if ReplayControl.replay_active:
		queue_free()
		return
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
	ai_control = region_control.ai_control
	var controler_id = region_control.align_controlers[dummy_alignment - 1]
	controler = ai_control.controlers[controler_id] as AIDummy
	if not controler:
		push_warning("Volcano could not find AIDummy, thus it is not functional.")
		queue_free()
		return
	controler.started_turn.connect(_start_volcano_turn)
	controler.thinking_normal.connect(_think_normal)
	controler.thinking_bonus.connect(_think_bonus)
	controler.thinking_mobilize.connect(_think_mobilize)
	region_control.alignment_aliances[dummy_alignment] = -1


func _think_normal():
	if controler.current_alignment != dummy_alignment:
		return
	if ai_control.CALL_change_current_action:
		return
	if not active:
		ai_control.CALL_turn_end = true
		return
	
	if region_control.action_amount == 0:
		ai_control.CALL_cheat = true
	else:
		ai_control.selected_capital = residing_region.name
		active = false


func _think_mobilize():
	if controler.current_alignment != dummy_alignment:
		return
	
	if residing_region.power == 1:
		ai_control.CALL_change_current_action = true
	else:
		ai_control.selected_capital = residing_region.name


func _think_bonus():
	if controler.current_alignment != dummy_alignment:
		return
	
	var call_end_turn = true
	for path in pathways:
		if not path.active:
			continue
		call_end_turn = false
		ai_control.CALL_overtake = true
		ai_control.selected_capital = path.pathway_strings[path.current]
		path.current += 1
		if path.current >= path.pathway_strings.size():
			path.active = false
		break
	if call_end_turn:
		ai_control.CALL_turn_end = true
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
	if controler.current_alignment != dummy_alignment:
		return
	
	if residing_region.power == residing_region.max_power:
		ai_control.CALL_change_current_action = true
#		print("Volcano Busted")
	
	active = true
