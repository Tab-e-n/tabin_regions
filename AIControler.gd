extends Node
class_name AIControler

@onready var game_control : GameControl = get_parent()
@onready var region_control : RegionControl

@export var thinking_timer : float = 0.5

enum {CONTROLER_USER, CONTROLER_DEFAULT, CONTROLER_TURTLE, CONTROLER_NEURAL, CONTROLER_CHEATER, CONTROLER_DUMMY}

var current_alignment : int
var current_controler : int

var timer : float = 0

var owned_regions : Dictionary = {}
var current_moves : Dictionary = {}
var previous_moves : Array = []

var selected_capital : String = "Astoska"

var CALL_change_current_action : bool = false
var CALL_turn_end : bool = false
var CALL_forfeit : bool = false

func _ready():
	game_control.ai_control = self
	
	call_deferred("set_region_control")

func set_region_control():
	region_control = game_control.region_control
	

func _process(delta):
	if region_control.dummy:
		return
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
	
	call_deferred("think")

func think():
#	print("think")
	
	timer = thinking_timer
	
	match current_controler:
		CONTROLER_DEFAULT:
			think_default()
	

func think_default():
#	print("think default")
	
	find_owned_regions()
	
#	print(owned_regions)
	
	if region_control.capital_amount[current_alignment - 1] == 0:
		var forfeit : bool = true
		for region in owned_regions[current_alignment]:
			if region.power > 1:
				forfeit = false
				break
		if forfeit:
			CALL_forfeit = true
	
	match region_control.current_action:
		region_control.ACTION_NORMAL:
			think_default_attack()
		region_control.ACTION_MOBILIZE:
			think_default_mobilize()
		region_control.ACTION_BONUS:
			think_default_attack(true)

func think_default_attack(is_bonus : bool = false):
	if is_bonus and region_control.bonus_action_amount == 0:
		CALL_change_current_action = true
		return
	if not is_bonus and region_control.action_amount == 0:
		CALL_change_current_action = true
		return
	
#	print("think default first")
	var eligable_regions : Array = []
	
	for region in owned_regions[current_alignment]:
#		print("owned: ", region.name)
		var in_threat : bool = false
		for connection_name in region.connections.keys():
#			print("connected_name: ", connection_name)
			var connection = region_control.get_node(connection_name)
#			print("connected: ", connection.name)
			if connection.alignment == current_alignment:
#				print("friendly alignment")
				continue
			if connection.alignment != 0:
				in_threat = true
#				print("not neutral")
			if not connection.incoming_attack(current_alignment, 0, true):
#				print("cannot attack")
				continue
			eligable_regions.append(connection)
		if in_threat and region.power != region.max_power:
			eligable_regions.append(region)
	
#	print(eligable_regions)
	
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	
	if eligable_regions.size() > 0:
		selected_capital = eligable_regions[0].name
		var highest_benefit = calculate_benefit(eligable_regions.pop_front(), is_bonus)
		rng.randomize()
		for region in eligable_regions:
			var benefit = calculate_benefit(region, is_bonus)
			if benefit > highest_benefit:
				selected_capital = region.name
				highest_benefit = benefit
			if benefit == highest_benefit and rng.randi_range(0, 1):
				selected_capital = region.name
				highest_benefit = benefit
	else:
		for region in owned_regions[current_alignment]:
			if region.power != region.max_power:
				eligable_regions.append(region)
		if eligable_regions.size() > 0:
			selected_capital = eligable_regions[rng.randi_range(0, eligable_regions.size() - 1)].name
		else:
			CALL_change_current_action = true

func think_default_mobilize():
	var no_more_extra : bool = true
	for region in owned_regions[current_alignment]:
		var threat : int = determine_attacks(region)
		if threat >= 1 and region.power > 1 and not region.name in current_moves[current_alignment]:
			selected_capital = region.name
			no_more_extra = false
			break
#	print("think default mobilize")
	if no_more_extra:
		if region_control.bonus_action_amount == 0:
			CALL_turn_end = true
		else:
			CALL_change_current_action = true
	

func calculate_benefit(region : Region, is_bonus : bool):
	var action_amount : int
	if not is_bonus:
		action_amount = region_control.action_amount
	else:
		action_amount = region_control.bonus_action_amount
	var benefit = 0
	if region.alignment == current_alignment:
		var threat : int = determine_attacks(region)
		if threat < -action_amount:
			benefit = -region.power - 1
		if threat == -action_amount:
			if region.is_capital and region.power != region.max_power:
				benefit += 4
		if threat >= -action_amount:
			benefit += region.power
	else:
		if region.is_capital:
			benefit += 5
		benefit += region.power + 1
		if previous_moves.has(region.name):
			benefit -= 4
	
#	print(region, ": ", benefit)
	return benefit

func determine_attacks(region : Region):
	var attacks : Array = []
	for align in range(region_control.align_amount - 1):
		if align + 1 == current_alignment:
			continue
		attacks.append(region.attack_power_difference(align + 1))
	var biggest_threat : int = attacks.pop_front()
	for i in attacks:
		if i < biggest_threat:
			biggest_threat = i
#	print(biggest_threat)
	return biggest_threat

func find_owned_regions():
	owned_regions[current_alignment] = []
	for region in region_control.get_children():
		if not region is Region:
			continue
		if region.alignment != current_alignment:
			continue
		owned_regions[current_alignment].append(region)

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
