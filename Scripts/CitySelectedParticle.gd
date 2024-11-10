extends Sprite2D


var timer : float = 0
var mobilize : bool = false


func _ready():
	if mobilize:
		scale = Vector2(2, 2)


func _process(delta):
	if !mobilize:
		scale.x += delta
		scale.y += delta
	else:
		scale.x -= delta
		scale.y -= delta
	modulate.a -= delta
	timer += delta
	if timer > 1:
		queue_free()


func set_color(color : Color):
	self_modulate = color * Color(0.75, 0.75, 0.75, 1.0)
