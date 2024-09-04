extends %BASE%

var connections : Array = [
#	Basic Connections are defined as such:
#	["Region 1", "Region 2"],
#	Connections that are harder to traverse are defined as such:
#	["Hilly Region 1", "Hilly Region 2", 1],
]


func _ready():
	get_parent().connections = connections.duplicate()
	queue_free()

