extends Line2D
class_name RegionArrow


const CUTOFF_DISTANCE : float = 768.0
const CUTOFF_ARROW_LENGHT : float = 128.0


@export var num : int = 0

@export var from_position : Vector2
@export var to_position : Vector2

@export var from_color : Color
@export var to_color : Color

@export var darken : bool = false
@export var to_name : String


var timer : float = 3.0

func _ready():
	
	var difference = to_position - from_position
	var distance = sqrt(pow(difference.x, 2) + pow(difference.y * 1.333, 2))
	
	#print(distance)
	
	if distance > CUTOFF_DISTANCE:
#		print("Before: ", from_position, " ", to_position)
		var lenght = CUTOFF_ARROW_LENGHT + num * 24
		to_position.x = from_position.x + (difference.x * lenght) / distance
		to_position.y = from_position.y + (difference.y * lenght) / distance
#		print("After: ", from_position, " ", to_position)
		
		
		var label = Label.new()
		label.text = to_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = Vector2(256, 24)
		label.position = to_position + Vector2(-128, -16)
		label.z_index = 20
		add_child(label)
	
	default_color = Color(0, 0, 0.2)
	add_point(from_position)
	add_point(to_position)
	gradient = Gradient.new()
	var dark : Color = Color(0.6, 0.6, 0.6)
	if darken:
		dark = Color(0.25, 0.25, 0.25)
	gradient.set_color(0, from_color * dark)
	gradient.set_color(1, to_color * dark)
	#gradient.add_point(0, from_color)
	#gradient.add_point(1, to_color)
	
	z_index = 10
	
	timer += num * 0.1


func _process(delta):
	timer -= delta
	if timer <= 0:
		queue_free()
