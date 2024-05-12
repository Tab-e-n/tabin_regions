extends Control
class_name CommandCallouts

const REMOVE_CALLOUT_TIME : float = 3.0
const CALLOUT_SIZE : int = 16
const MAX_CALLOUTS : int = 8


var callouts : Array[Label] = []
var callout_timestamp : Array[float] = []

var timer : float = 0.0


#func _ready():
#	new_callout("a")
#	new_callout("b")
#	new_callout("c")


func _physics_process(delta):
	if callout_timestamp.size() > 0:
		timer += delta
		if timer > callout_timestamp[0]:
			remove_oldest_callout()
			
			if callouts.size() > 0:
				position_callouts()


func remove_oldest_callout():
	callout_timestamp.pop_front()
	var remove_callout : Label = callouts.pop_front()
	remove_child(remove_callout)
	remove_callout.queue_free()


func new_callout(text : String):
	var callout_number : int = callouts.size()
	if callout_number >= MAX_CALLOUTS:
		remove_oldest_callout()
	
	var callout : Label = Label.new()
	callout.add_theme_font_size_override("font_size", CALLOUT_SIZE)
	callout.text = text
	callout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	add_child(callout)
	callouts.append(callout)
	callout_timestamp.append(timer + REMOVE_CALLOUT_TIME)
	position_callouts()
	

func position_callouts():
	var callout_amount : int = callouts.size()
	for i in range(callout_amount):
		callouts[callout_amount - i - 1].position.y = i * CALLOUT_SIZE
