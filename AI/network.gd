extends Node
class_name Network


const MUTATION_AMOUNT : float = 0.1

var inputs : Array = []
var layers : Array = []


func setup_network(input_amount : int, specifications : Array):
	inputs = new_layer(0, input_amount, 0)
	for layer in range(specifications.size()):
		var layer_size = specifications[layer]
		var neurons = []
		if layer == 0:
			neurons = new_layer(layer + 1, layer_size, input_amount)
		else:
			neurons = new_layer(layer + 1, layer_size, specifications[layer - 1])
		layers.append(neurons)


func new_layer(layer : int, size : int, w_amount : int) -> Array:
	var neurons : Array = []
	for i in range(size):
		var neuron : Neuron = Neuron.new()
		neuron.layer = layer
		if w_amount > 0:
			neuron.weights = range(w_amount)
			for j in range(w_amount):
				neuron.weights[j] = 1.0
		add_child(neuron)
		neurons.append(neuron)
	return neurons


func set_inputs(values : Array):
	for i in range(inputs.size()):
		if i < values.size():
			inputs[i].value = values[i]
		else:
			inputs[i].value = 0.0


func get_layer(n : int) -> Array:
	if n == 0:
		return inputs
	elif n - 1 >= 0 or n - 1 < layers.size():
		return layers[n - 1]
	else:
		return []


func get_results() -> Array:
	if layers.size() > 0:
		var layer = layers[layers.size() - 1]
		var results : Array[float] = []
		for i in layer:
			results.append(i.value)
		return results
	else:
		return []


func calculate_results():
	for layer in layers:
		for i in range(layer.size()):
			layer[i].calculate_value()


func randomize_network():
	for layer in layers:
		for neuron in layer:
			neuron.randomize_neuron()


func mutate():
	for layer in layers:
		for neuron in layer:
			neuron.mutate(MUTATION_AMOUNT)


func copy_self() -> Network:
	var network : Network = Network.new()
	var specs : Array = []
	for i in range(layers.size()):
		specs.append(layers[i].size())
	network.setup_network(inputs.size(), specs)
	copy_layer(network.inputs, inputs)
	for i in range(layers.size()):
		copy_layer(network.layers[i], layers[i])
	return network


func copy_layer(layer1 : Array, layer2 : Array):
	for i in range(layer1.size()):
		if i >= layer2.size():
			return
		layer1[i].bias = layer2[i].bias
		layer1[i].weights = layer2[i].weights.duplicate()
#		print(layer1[i].weights, " || ", layer2[i].weights)


func network_to_dict() -> Dictionary:
	var net : Dictionary = {
		"input_amount" : inputs.size(),
		"layer_amount" : layers.size(),
	}
	for i in range(layers.size()):
		
		net[str(i)] = layers[i].size()
		var layers_bias : Array = []
		for neuron in layers[i]:
			layers_bias.append(neuron.bias)
		net[str(i) + "_bias"] = layers_bias
		
		for j in range(layers[i].size()):
			net[str(i) + "_" + str(j)] = layers[i][j].weights
	
	return net


func print_network():
	print(network_to_dict())


func save_network(net_name : String):
	var save : Dictionary = network_to_dict()
	
#	print(save)
	
	var filename : String = "user://Dev/" + net_name + ".json"
	var file = FileAccess.open(filename, FileAccess.WRITE)
	
	file.store_string(JSON.stringify(save))


func load_network(net_name : String):
	var save : Dictionary = {}
	
	var filename : String = "user://Dev/" + net_name + ".json"
	if FileAccess.file_exists(filename):
		var file = FileAccess.open(filename, FileAccess.READ)
		
		save = JSON.parse_string(file.get_as_text())
		
		file.close()
		
		load_network_from_dict(save)
		
		return true
	else:
		return false


func load_network_from_dict(save : Dictionary):
	if save.is_empty():
		return
	
	var input_amount : int = save["input_amount"]
	var layer_amount : int = save["layer_amount"]
	var layer_sizes : Array = []
	for i in range(layer_amount):
		layer_sizes.append(save[str(i)])
	
	setup_network(input_amount, layer_sizes)
	
	for i in range(layers.size()):
		var layer : Array = layers[i]
		for j in range(layer.size()):
			var neuron : Neuron = layer[j] as Neuron
			neuron.bias = save[str(i) + "_bias"][j]
			neuron.weights = save[str(i) + "_" + str(j)]
