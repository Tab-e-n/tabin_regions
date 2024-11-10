extends Polygon2D
class_name Neuron


var layer : int = 0

var value : float = 0.0
var bias : float = 0.0

var weights : Array = []

@onready var network : Network = get_parent() as Network


func sigmoid(x : float):
	return 1 / (1 + pow(2.71828, -x))


func calculate_value():
	if network:
		var summary : float = 0
		var neurons : Array = network.get_layer(layer - 1)
		for i in range(neurons.size()):
			if i < weights.size():
				summary += weights[i] * neurons[i].value
		
		value = sigmoid(summary + bias) * 2.0 - 1.0


func randomize_neuron():
	for i in range(weights.size()):
		weights[i] = randf_range(-1.0, 1.0)
	bias = randf_range(-weights.size(), weights.size())


func mutate(amount : float):
	for i in range(weights.size()):
		weights[i] += randf_range(-1.0, 1.0) * amount
	bias += randf_range(-1.0, 1.0) * amount
