extends GameControl
class_name NetworkTrainer


const NET_NAMES : Array[String] = ["attack", "reinforce", "mobilize"]
const ALLOWED_MAPS : Dictionary = {
	"2._Testlandia.tscn" : 5,
}


@export var network_amount : int = 100
@export var remove_amount : int = 30
@export var network_inputs : int = 8
@export var network_specifications : Array = [8, 8, 1]
@export var turn_cutoff : int = 60

var networks : Node
var rankings : Array[float] = []
var current_rankings : Array[float] = []
var choosable_networks : Array = []
var chosen_networks : Array[int] = []
var chosen_variations : int = 0


func _ready():
	MapSetup.current_map_name = "2._Testlandia.tscn"
	MapSetup.player_amount = 0
	MapSetup.default_ai_controler = AIControler.CONTROLER_NEURAL
	MapSetup.aliances_amount = 1
	MapSetup.used_aligments = 65532
	MapSetup.preset_alignments = []
	
	networks = Node.new()
	
	add_child(networks)
	
	make_new_networks(network_amount, network_inputs, network_specifications)
	
	choosable_networks = range(network_amount)
	chosen_networks.resize(ALLOWED_MAPS[MapSetup.current_map_name])
	current_rankings.resize(ALLOWED_MAPS[MapSetup.current_map_name])
	reset_rankings(current_rankings)
	
	choose_networks()
	
	super._ready()
	
	region_control.turn_ended.connect(_turn_ended)


func make_new_networks(amount : int, net_inputs : int, net_specs : Array):
	if not networks:
		return
	
	if networks.get_child_count() > 0:
		for net in networks.get_children():
			networks.remove_child(net)
			net.queue_free()
	
	for i in range(amount):
		var net_set : Node = new_network_set(i, net_inputs,net_specs)
		randomize_network_set(net_set)
	
	rankings.resize(amount)
	reset_rankings(rankings, 1.0)


func new_network_set(id : int, net_inputs : int, net_specs : Array) -> Node:
	var net_set : Node = Node.new()
	net_set.name = str(id)
	networks.add_child(net_set)
	for j in range(3):
		var net : Network = Network.new()
		net.name = NET_NAMES[j]
		net.setup_network(net_inputs, net_specs)
		net_set.add_child(net)
	return net_set


func randomize_network_set(net_set : Node):
	for net in net_set.get_children():
		net.randomize_network()


func choose_networks() -> bool:
	if chosen_networks.size() > choosable_networks.size():
		return false
	for i in range(chosen_networks.size()):
		chosen_networks[i] = choosable_networks.pop_at(randi_range(0, choosable_networks.size() - 1))
	
	print(chosen_networks)
	return true


func get_network_for_align(align : int, net_type : int) -> Network:
	var chosen_net = get_net_id(align)
	if chosen_net == -1:
		return null
	var net_set : Node = networks.get_node(str(chosen_net))
	return net_set.get_node(NET_NAMES[net_type])


func get_net_id(align : int) -> int:
	if chosen_networks.size() == 0:
		print("chosen_networks is empty")
		return -1
	var al = (align - 1 + chosen_variations) % chosen_networks.size()
	return chosen_networks[al]


func reset_rankings(ranks : Array[float], value : float = 0.0):
	for i in range(ranks.size()):
		ranks[i] = value


func sort_networks():
	for i in range(choosable_networks.size()):
		for j in range(choosable_networks.size() - i - 1):
			if rankings[j] < rankings[j + 1]:
				var t : float = rankings[j]
				rankings[j] = rankings[j + 1]
				rankings[j + 1] = t
				var n : int = choosable_networks[j]
				choosable_networks[j] = choosable_networks[j + 1]
				choosable_networks[j + 1] = n


func remove_last_networks(removed : int):
	if removed > choosable_networks.size():
		removed = choosable_networks.size()
	for i in range(removed):
		var net_id : int = choosable_networks.pop_back()
		var network : Node = networks.get_node(str(net_id))
		networks.remove_child(network)
		network.queue_free()


func fill_missing_networks(net_amount : int):
	for i in range(net_amount):
		if networks.has_node(str(i)):
			continue
		var net_set : Node = Node.new()
		net_set.name = str(i)
		networks.add_child(net_set)
		var net_set_parent : Node = networks.get_node(str(choosable_networks[randi_range(0, choosable_networks.size() - 1)]))
		for j in range(3):
			var net : Network = net_set_parent.get_node(NET_NAMES[j]).copy_self()
			net.name = NET_NAMES[j]
			net.mutate()


func win(_align : int):
	ai_control.timer = 0
	
	for i in range(chosen_networks.size()):
		var placement : String = GameStats.get_stat(i + 1, "placement") as String
		
		var al = (i + chosen_variations) % chosen_networks.size()
		
		if placement.is_valid_int():
			current_rankings[al] += 1.0 - float(placement.to_int()) / float(chosen_networks.size())
		else:
			current_rankings[al] += 0.45
	
	if chosen_variations >= chosen_networks.size() - 1:
		chosen_variations = 0
		for i in range(current_rankings.size()):
			current_rankings[i] /= float(chosen_networks.size())
			rankings[chosen_networks[i]] = current_rankings[i]
		print(current_rankings)
		reset_rankings(current_rankings)
		
		print("New Set")
		
		MapSetup.current_map_name = ALLOWED_MAPS.keys()[randi_range(0, ALLOWED_MAPS.size() - 1)]
		
		chosen_networks.resize(ALLOWED_MAPS[MapSetup.current_map_name])
		current_rankings.resize(ALLOWED_MAPS[MapSetup.current_map_name])
		reset_rankings(current_rankings)
		
		if not choose_networks():
			print("All nets tested")
			print(rankings)
			# End of session
			# Remove poorly performing nets
			choosable_networks = range(network_amount)
			sort_networks()
			remove_last_networks(remove_amount)
			# Generate new nets
			fill_missing_networks(network_amount)
			
			choosable_networks = range(network_amount)
			choose_networks()
			
			breakpoint
#			get_tree().change_scene_to_file("res://title.tscn")
			return
	else:
		chosen_variations += 1
		print(current_rankings)
		print("New variation")
	
	change_map(MapSetup.current_map_name)
	region_control.turn_ended.connect(_turn_ended)
	ai_control.current_alignment = region_control.current_playing_align


func lose(align : int):
	win(align)


func _turn_ended():
	if region_control.current_turn >= turn_cutoff:
		print("timeout")
		lose(0)


func save_all_networks():
	pass


func load_networks():
	pass
