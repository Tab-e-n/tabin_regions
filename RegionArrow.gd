extends Line2D
class_name RegionArrow

@export var from_position : Vector2
@export var to_position : Vector2

@export var from_color : Color
@export var to_color : Color

@export var to_name : String

var timer : float = 2

func _ready():
	
	var difference = to_position - from_position
	var distance = sqrt(pow(abs(difference.x), 2) + pow(abs(difference.y), 2))
	
	#print(distance)
	
	if distance > 896:
#		print("Before: ", from_position, " ", to_position)
		to_position.x = from_position.x + (difference.x * 256) / distance
		to_position.y = from_position.y + (difference.y * 256) / distance
#		print("After: ", from_position, " ", to_position)
		
		
		var label = Label.new()
		label.text = to_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = Vector2(256, 32)
		label.position = to_position + Vector2(-128, -16)
		label.z_index = 1
		add_child(label)
	
	default_color = Color(0, 0, 0.2)
	add_point(from_position)
	add_point(to_position)
	gradient = Gradient.new()
	gradient.set_color(0, from_color * Color(0.5, 0.5, 0.5))
	gradient.set_color(1, to_color * Color(0.5, 0.5, 0.5))
	#gradient.add_point(0, from_color)
	#gradient.add_point(1, to_color)
	
	z_index = 10

func _process(delta):
	timer -= delta
	if timer <= 0:
		queue_free()
