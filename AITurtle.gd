extends Node


var controler : AIControler
var controler_id : int
var current_alignment : int


func _ready():
	pass


func start_turn(align : int):
	current_alignment = align


func think_bonus():
	think_normal(true)


func think_normal(is_bonus : bool = false):
	if is_bonus and controler.region_control.bonus_action_amount == 0:
		controler.CALL_change_current_action = true
		return
	if not is_bonus and controler.region_control.action_amount == 0:
		controler.CALL_change_current_action = true
		return
	
#	print("think default first")
	var eligable_regions : Array = []
	
#	print(eligable_regions)
	
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	
	for region in controler.get_owned_regions():
		if region.power != region.max_power:
			eligable_regions.append(region)
	if eligable_regions.size() > 0:
		controler.selected_capital = eligable_regions[rng.randi_range(0, eligable_regions.size() - 1)].name
	else:
		for region in controler.get_owned_regions():
	#		print("owned: ", region.name)
			var in_threat : bool = false
			for connection_name in region.connections.keys():
	#			print("connected_name: ", connection_name)
				var connection = controler.get_region(connection_name)
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
		
		if eligable_regions.size() > 0:
			controler.selected_capital = eligable_regions[0].name
			var highest_benefit = calculate_benefit_default(eligable_regions.pop_front(), is_bonus)
			rng.randomize()
			var results : Array = []
			for region in eligable_regions:
				var benefit = calculate_benefit_default(region, is_bonus)
				if benefit > highest_benefit:
					results = [region.name]
					highest_benefit = benefit
				if benefit == highest_benefit:
					results.append(region.name)
					highest_benefit = benefit
			if results:
				controler.selected_capital = results[rng.randi_range(0, results.size() - 1)]
		else:
			controler.CALL_change_current_action = true


func think_mobilize():
#	if region_control.capital_amount[current_alignment - 1] == 0:
#		var forfeit : bool = true
#		for region in owned_regions[current_alignment]:
#			if region.power > 1:
#				forfeit = false
#				break
#		if forfeit:
#			CALL_forfeit = true
	
	if controler.get_capitol_amount() == 0:
		var no_more_extra : bool = true
		for region in controler.get_owned_regions():
			var threat : int = determine_attacks(region)
			if threat >= 1 and region.power > 1 and not region.name in controler.get_current_moves():
				controler.selected_capital = region.name
				no_more_extra = false
				break
	#	print("think default mobilize")
		if no_more_extra:
			if controler.get_bonus_action_amount() == 0:
				controler.CALL_turn_end = true
			else:
				controler.CALL_change_current_action = true
	else:
		controler.CALL_change_current_action = true


func calculate_benefit_default(region : Region, is_bonus : bool):
	var action_amount : int
	if not is_bonus:
		action_amount = controler.get_action_amount()
	else:
		action_amount = controler.get_bonus_action_amount()
	var benefit = 0
	if region.alignment == current_alignment:
		var threat : int = determine_attacks(region)
		if threat < -action_amount:
			benefit = -region.power - 1
		if threat == -action_amount:
			if region.is_capital and region.power != region.max_power:
				benefit += 4
		if threat >= -action_amount:
			@warning_ignore("integer_division")
			benefit += region.power / 2
	else:
		if region.is_capital:
			benefit += 5
		benefit += region.power + 1
		if controler.used_region_previously(region.name):
			benefit -= 4
	
#	print(region, ": ", benefit)
	return benefit


func determine_attacks(region : Region):
	var attacks : Array = []
	for align in range(controler.get_alingment_amout() - 1):
		if align + 1 == current_alignment:
			continue
		attacks.append(region.attack_power_difference(align + 1))
	var biggest_threat : int = attacks.pop_front()
	for i in attacks:
		if i < biggest_threat:
			biggest_threat = i
#	print(biggest_threat)
	return biggest_threat
