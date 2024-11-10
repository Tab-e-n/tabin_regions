extends AIBase


enum {
	INPUT_CAPITAL,
	INPUT_POWER,
	INPUT_MAX_POWER,
	INPUT_CAPITAL_DISTANCE,
	INPUT_ACTIONS,
	INPUT_ATTACK_POWER,
	INPUT_OWN_ATTACK_POWER,
	INPUT_PREVIOUS_MOVE,
}


var network_attack : Network
var network_reinforce : Network
var network_mobilize : Network
var loading_net : bool = false


func _ready():
	network_attack = Network.new()
	network_reinforce = Network.new()
	network_mobilize = Network.new()
	if loading_net:
		network_attack.load_network("test0")
		network_reinforce.load_network("test1")
		network_mobilize.load_network("test2")
#		network_attack.print_network()
	else:
		network_attack.setup_network(8, [8, 8, 1])
		network_attack.randomize_network()
		add_child(network_attack)
		network_attack.save_network("test0")
		
		network_reinforce.setup_network(8, [8, 8, 1])
		network_reinforce.randomize_network()
		add_child(network_reinforce)
		network_reinforce.save_network("test1")
		
		network_mobilize.setup_network(8, [8, 8, 1])
		network_mobilize.randomize_network()
		add_child(network_mobilize)
		network_mobilize.save_network("test2")


func start_turn(align : int):
	super.start_turn(align)


func think_normal():
	if controler.get_actions_contextual() <= 0:
		controler.CALL_change_current_action = true
		return
	
	var attack_regions : Array = []
	var reinforce_regions : Array = []
	var friendly_regions : Array = controler.get_owned_regions()
	if controler.aliances_on():
		friendly_regions.append_array(controler.get_allied_regions())
	
	for region in friendly_regions:
#		print("FROM: ", region.name)
		if region.power != region.max_power:
			reinforce_regions.append(region)
		if region.alignment != current_alignment:
#			print("allies region, cannot attack through")
			continue
		for connection_name in region.connections.keys():
			var connection = controler.get_region(connection_name)
#			print("--> ", connection.name)
			if controler.alignment_friendly(current_alignment, connection.alignment):
#				print("friendly alignment")
				continue
			if not connection.incoming_attack(current_alignment, 0, true):
#				print("cannot attack")
				continue
			attack_regions.append(connection)
	
	var chosen_attack : Array = choose_using_network(network_attack, attack_regions)
	var chosen_reinforce : Array = choose_using_network(network_reinforce, reinforce_regions)
	if chosen_attack[0] == "" and chosen_reinforce[0] == "":
		controler.CALL_change_current_action = true
	else:
		if chosen_attack[1] >= chosen_reinforce[1]:
			controler.selected_capital = chosen_attack[0]
		else:
			controler.selected_capital = chosen_reinforce[0]
	


func think_mobilize():
	var mobilize_regions : Array = []
	var friendly_regions : Array = controler.get_owned_regions()
	
	var can_mobilize : bool = false
	for region in friendly_regions:
		if region.power > 1:
			mobilize_regions.append(region)
			can_mobilize = true
	if not can_mobilize:
		if controler.get_bonus_action_amount() <= 0:
			controler.CALL_turn_end = true
		else:
			controler.CALL_change_current_action = true
		return
	
	var chosen_mobilize : Array = choose_using_network(network_mobilize, mobilize_regions)
	if chosen_mobilize[0] == "":
		if controler.get_bonus_action_amount() <= 0:
			controler.CALL_turn_end = true
		else:
			controler.CALL_change_current_action = true
	else:
		controler.selected_capital = chosen_mobilize[0]


func think_bonus():
	think_normal()


func choose_using_network(network : Network, regions : Array) -> Array:
	if regions.size() == 0:
		return ["", -1.0]
	var chosen : String = ""
	var highest_benefit : float = -1.0
	var results : Array = []
	for region in regions:
		var benefit : float = calculate_benefit(network, region)
		if benefit > highest_benefit:
			results = [region.name]
			highest_benefit = benefit
		elif benefit == highest_benefit:
			results.append(region.name)
	if highest_benefit >= 0:
		if results.size() == 1:
			chosen = results[0]
		elif results.size() > 1:
			chosen = results[randi_range(0, results.size() - 1)]
	return [chosen, highest_benefit]


func calculate_benefit(network : Network, region : Region) -> float:
	var inputs = range(8)
	
	if region.is_capital:
		inputs[INPUT_CAPITAL] = 1.0
	else:
		inputs[INPUT_CAPITAL] = 0.0
	
	inputs[INPUT_POWER] = region.power
	inputs[INPUT_MAX_POWER] = region.max_power
	inputs[INPUT_CAPITAL_DISTANCE] = region.distance_from_capital
	
	inputs[INPUT_ACTIONS] = controler.get_actions_contextual()
	
	inputs[INPUT_ATTACK_POWER] = region.strongest_enemy_attack(current_alignment)
	inputs[INPUT_OWN_ATTACK_POWER] = region.self_attack_power(current_alignment)
	
	inputs[INPUT_PREVIOUS_MOVE] = controler.used_region_previously(region.name)
	
	network.set_inputs(inputs)
	network.calculate_results()
	var results = network.get_results()
	
	return results[0]
