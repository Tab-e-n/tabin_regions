extends Line2D
class_name RegionArrow

@export var from_position : Vector2
@export var to_position : Vector2

@export var from_color : Color
@export var to_color : Color

var timer : float = 2

func _ready():
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
