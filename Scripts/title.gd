extends Node2D


const CHANGE_ALIGN_TIMER : float = 0.5


var timer : float = 0.5

var regions : Array[Region] = []
var alignments : Array = []
var current_region : int = 0
var current_align : int = 1


var going_network : bool = false


func _ready():
	Options.load_options()
	
	for i in $title.get_children():
		if i is Region:
			i.change_alignment(0, false)
			regions.append(i)
	
	alignments = range(1, 30)
	alignments.shuffle()


func _process(delta):
	timer -= delta
	if timer <= 0:
		timer = CHANGE_ALIGN_TIMER
		regions[current_region].change_alignment(alignments[current_align], true)
		current_region += 1
		if current_region >= regions.size():
			current_region = 0
			current_align += 1
			if current_align >= 30:
				current_align = 0
				alignments.shuffle()
#		print(current_region, " ", current_align)
	
	if Input.is_action_just_pressed("left_click"):
		if going_network:
			get_tree().change_scene_to_file("res://AI/network_trainer.tscn")
		else:
			get_tree().change_scene_to_file("res://setup_scene.tscn")


func _on_network_mouse_entered():
	going_network = true


func _on_network_mouse_exited():
	going_network = false
