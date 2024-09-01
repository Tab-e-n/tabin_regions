extends Node
class_name AIControler

@onready var game_control : GameControl = get_parent()
@onready var region_control : RegionControl

const THINKING_TIMER_DEFAULT : float = 0.5
const THINKING_TIMER_SPEEDRUN : float = 0.05

var thinking_timer : float = THINKING_TIMER_DEFAULT

enum {CONTROLER_USER, CONTROLER_DEFAULT, CONTROLER_TURTLE, CONTROLER_NEURAL, CONTROLER_CHEATER, CONTROLER_DUMMY}
const CONTROLER_NAMES : Array = ["User Controled", "Simple", "Turtle", "Neural", "Cheater", "Dummy"]
const PACKED_CONTROLERS : Array = [
	null, # CONTROLER_USER (can be just null)
	preload("res://AI/AINormal.gd"), # CONTROLER_DEFAULT
	preload("res://AI/AITurtle.gd"), # CONTROLER_TURTLE
	preload("res://AI/AINeural.gd"), # CONTROLER_NEURAL
	preload("res://AI/AINormal.gd"), # CONTROLER_CHEATER
	preload("res://AI/AIDummy.gd") # CONTROLER_DUMMY
]


var current_alignment : int
var current_controler : int

var timer : float = 0

var owned_regions : Dictionary = {}
var current_moves : Dictionary = {}
var previous_moves : Array = []

var selected_capital : String = ""

var CALL_change_current_action : bool = false
var CALL_turn_end : bool = false
var CALL_forfeit : bool = false
var CALL_nothing : bool = false

var controlers : Array = []

var replay_done_action : bool = true


func _ready():
	speedrun_ai_update(false)
	
	game_control.ai_control = self
	
	controlers.resize(PACKED_CONTROLERS.size())
	
	for i in range(PACKED_CONTROLERS.size()):
		if PACKED_CONTROLERS[i]:
			controlers[i] = Node.new()
			controlers[i].set_script(PACKED_CONTROLERS[i])
			controlers[i].controler = self
			controlers[i].controler_id = i
			add_child(controlers[i])
	
	call_deferred("_ready_deferred")


func _ready_deferred():
	region_control = game_control.region_control


func _process(delta):
	
	if region_control.dummy:
		return
	
	if Input.is_action_just_pressed("ai_speedrun"):
		MapSetup.speedrun_ai = not MapSetup.speedrun_ai
		speedrun_ai_update()
	
#	print(timer)
	if region_control.is_player_controled:
		timer = 0
	if timer > 0:
		timer -= delta
		if timer == 0:
			timer = -1
	if timer < 0:
		timer = 0
		timer_ended()


func speedrun_ai_update(callouts : bool = true):
	if MapSetup.speedrun_ai:
		thinking_timer = THINKING_TIMER_SPEEDRUN
		if callouts:
			game_control.game_camera.CommandCallout.new_callout("Fast AI")
	else:
		thinking_timer = THINKING_TIMER_DEFAULT
		if callouts:
			game_control.game_camera.CommandCallout.new_callout("Slow AI")


func start_turn(align : int, control : int):
#	print("start turn")
	
	current_alignment = align
	current_controler = control
	
	if not ReplayControl.replay_active:
		if current_moves.has(current_alignment):
			previous_moves = current_moves[current_alignment].duplicate()
		current_moves[current_alignment] = []
		
		if controlers[current_controler].has_method("start_turn"):
			controlers[current_controler].call("start_turn", align)
	
	call_deferred("think")


func think():
#	print("think")
	
	timer = thinking_timer
	
	if ReplayControl.replay_active:
		if replay_done_action:
			replay_done_action = false
			var next_move = ReplayControl.get_next_move()
#			print(current_alignment, " ", next_move)
			if next_move[0] == ReplayControl.RECORD_TYPE_REGION:
				selected_capital = next_move[1]
			else:
				match(next_move[1]):
					"forfeit":
						CALL_forfeit = true
					"turn_end":
						CALL_turn_end = true
					"change_current_action":
						CALL_change_current_action = true
					"nothing":
						CALL_nothing = true
	else:
		find_owned_regions()
		
		match region_control.current_action:
			region_control.ACTION_NORMAL:
				if controlers[current_controler].has_method("think_normal"):
					controlers[current_controler].call("think_normal")
			region_control.ACTION_MOBILIZE:
				if controlers[current_controler].has_method("think_mobilize"):
					controlers[current_controler].call("think_mobilize")
			region_control.ACTION_BONUS:
				if controlers[current_controler].has_method("think_bonus"):
					controlers[current_controler].call("think_bonus")


func timer_ended():
#	print("timer ended")
	var should_think : bool = true
	if CALL_nothing:
		reset_CALL()
	elif CALL_forfeit:
		reset_CALL()
		region_control.forfeit()
		should_think = false
	elif CALL_turn_end:
		reset_CALL()
		region_control.turn_end(true)
		should_think = false
	elif CALL_change_current_action:
		reset_CALL()
		region_control.change_current_action()
		should_think = region_control.current_action != region_control.ACTION_NORMAL
	else:
		reset_CALL()
		var previous_action = region_control.current_action
		region_control.get_node(selected_capital).action_decided()
		if not ReplayControl.replay_active:
			current_moves[current_alignment].append(selected_capital)
		should_think = not (previous_action != region_control.ACTION_NORMAL and region_control.current_action == region_control.ACTION_NORMAL)
	replay_done_action = true
	if should_think:
		think()
#	print(current_moves)


func reset_CALL():
	CALL_forfeit = false
	CALL_turn_end = false
	CALL_change_current_action = false
	CALL_nothing = false


func find_owned_regions(alignment : int = current_alignment):
	owned_regions[alignment] = []
	for region in region_control.get_children():
		if not region is Region:
			continue
		if region.alignment != alignment:
			continue
		owned_regions[alignment].append(region)


func used_region_previously(region_name) -> bool:
	return previous_moves.has(region_name)


func get_owned_regions(alignment : int = current_alignment) -> Array:
	if owned_regions.has(alignment):
		return owned_regions[alignment].duplicate()
	else:
		return []


func get_allied_regions(alignment : int = current_alignment) -> Array:
	var allied_regs : Array = []
	for i in range(region_control.align_amount - 1):
		if alignment_friendly(alignment, i + 1) and alignment != i + 1:
			find_owned_regions(i + 1)
			allied_regs.append_array(get_owned_regions(i + 1))
#	print(allied_regs)
	return allied_regs


func get_region(connection_name : String) -> Region:
	return region_control.get_node(connection_name)


func get_current_moves() -> Array:
	return current_moves[current_alignment].duplicate()


func get_action_amount() -> int:
	return region_control.action_amount


func get_bonus_action_amount() -> int:
	return region_control.bonus_action_amount


func get_alingment_amount() -> int:
	return region_control.align_amount


func get_capital_amount() -> int:
	return region_control.capital_amount[current_alignment - 1]


func alignment_friendly(your_align, opposing_align) -> bool:
	return region_control.alignment_friendly(your_align, opposing_align)


func alignment_neutral(align) -> bool:
	return region_control.alignment_neutral(align)

