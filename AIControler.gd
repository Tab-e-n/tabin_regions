extends Node
class_name AIControler

@onready var game_control : GameControl = get_parent()
@onready var region_control : RegionControl

const THINKING_TIMER_DEFAULT : float = 0.5
const THINKING_TIMER_SPEEDRUN : float = 0.05

var speedrun_ai : bool = false
var thinking_timer : float = THINKING_TIMER_DEFAULT

enum {CONTROLER_USER, CONTROLER_DEFAULT, CONTROLER_TURTLE, CONTROLER_NEURAL, CONTROLER_CHEATER, CONTROLER_DUMMY}
const PACKED_CONTROLERS : Array = [
	null, # CONTROLER_USER (can be just null)
	preload("res://AINormal.gd"), # CONTROLER_DEFAULT
	preload("res://AITurtle.gd"), # CONTROLER_TURTLE
	null, # CONTROLER_NEURAL
	preload("res://AINormal.gd"), # CONTROLER_CHEATER
	preload("res://AIDummy.gd") # CONTROLER_DUMMY
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

var controlers : Array = []


func _ready():
	game_control.ai_control = self
	
	controlers.resize(PACKED_CONTROLERS.size())
	
	for i in range(PACKED_CONTROLERS.size()):
		if PACKED_CONTROLERS[i]:
			controlers[i] = Node.new()
			controlers[i].set_script(PACKED_CONTROLERS[i])
			controlers[i].controler = self
			controlers[i].controler_id = i
			add_child(controlers[i])
	
	call_deferred("set_region_control")


func set_region_control():
	region_control = game_control.region_control


func _process(delta):
	
	if region_control.dummy:
		return
	
	if Input.is_action_just_pressed("ai_speedrun"):
		speedrun_ai = not speedrun_ai
		if speedrun_ai:
			thinking_timer = THINKING_TIMER_SPEEDRUN
		else:
			thinking_timer = THINKING_TIMER_DEFAULT
	
#	print(timer)
	if region_control.is_user_controled:
		timer = 0
	if timer > 0:
		timer -= delta
		if timer == 0:
			timer = -1
	if timer < 0:
		timer = 0
		timer_ended()


func start_turn(align : int, control : int):
#	print("start turn")
	
	current_alignment = align
	current_controler = control
	
	if current_moves.has(current_alignment):
		previous_moves = current_moves[current_alignment].duplicate()
	current_moves[current_alignment] = []
	
	if controlers[current_controler].has_method("start_turn"):
		controlers[current_controler].call("start_turn", align)
	
	call_deferred("think")


func think():
#	print("think")
	
	timer = thinking_timer
	
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


func find_owned_regions():
	owned_regions[current_alignment] = []
	for region in region_control.get_children():
		if not region is Region:
			continue
		if region.alignment != current_alignment:
			continue
		owned_regions[current_alignment].append(region)


func used_region_previously(region_name) -> bool:
	return previous_moves.has(region_name)


func get_owned_regions() -> Array:
	return owned_regions[current_alignment]


func get_region(connection_name : String) -> Region:
	return region_control.get_node(connection_name)


func get_current_moves() -> Array:
	return current_moves[current_alignment]


func get_action_amount() -> int:
	return region_control.action_amount


func get_bonus_action_amount() -> int:
	return region_control.bonus_action_amount


func get_alingment_amout() -> int:
	return region_control.align_amount


func get_capitol_amount() -> int:
	return region_control.capital_amount[current_alignment - 1]


func timer_ended():
#	print("timer ended")
	var should_think : bool = true
	if CALL_forfeit:
		reset_CALL()
		region_control.forfeit()
		should_think = false
#		current_moves[current_alignment].append(3)
	elif CALL_turn_end:
		reset_CALL()
		region_control.turn_end()
		should_think = false
#		current_moves[current_alignment].append(2)
	elif CALL_change_current_action:
		reset_CALL()
		region_control.change_current_action()
#		current_moves[current_alignment].append(1)
	else:
		region_control.get_node(selected_capital).action_decided()
		current_moves[current_alignment].append(selected_capital)
	if should_think:
		think()
#	print(current_moves)

func reset_CALL():
	CALL_forfeit = false
	CALL_turn_end = false
	CALL_change_current_action = false
