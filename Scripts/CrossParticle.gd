extends Sprite2D


const PHASE_TIMES : Array[float] = [0.1, 0.5, 0.5]
const OFFSET : Vector2 = Vector2(0, -32)
const SCALE_OFFSET : Vector2 = Vector2(2, 2)


var timer : float = 0
var part_phase : int = 0
var part_pos : Vector2


func _ready():
	scale += SCALE_OFFSET
	part_pos = position
	position += OFFSET


func _process(delta):
	var phase_speed = 1 / PHASE_TIMES[part_phase]
	if part_phase == 0:
		self_modulate.a += delta * phase_speed 
		scale -= SCALE_OFFSET * delta * phase_speed
		position -= OFFSET * delta * phase_speed 
	
	if part_phase == 2:
		self_modulate.a -= delta * phase_speed 
	
	timer += delta
	
	if timer > PHASE_TIMES[part_phase]:
		timer = 0.0
		part_phase += 1
		if part_phase == 1:
			scale = Vector2(1, 1)
			self_modulate.a = 1.0
			position = part_pos
		if part_phase == 3:
			queue_free()

func set_color(color : Color):
	self_modulate = color * Color(0.25, 0.25, 0.25, 0.0)
