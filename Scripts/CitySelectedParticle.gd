extends Sprite2D

var timer : int = 0
var mobilize : bool = false

# Called when the node enters the scene tree for the first time.
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
