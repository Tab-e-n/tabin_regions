extends Node2D
class_name DecorSpiral


const SPIRAL_DURATION : float = 9.0
const SPIRALS : Array[Texture2D] = [
	preload("res://Sprites/spiral_0.png"),
	preload("res://Sprites/spiral_1.png"),
	preload("res://Sprites/spiral_2.png"),
]


@export var counter_clockwise : bool = false
@export var speed : float = 12


var dir : float = 1.0


func _ready():
	var r : int = randi_range(0, SPIRALS.size() - 1)
	$Spiral.texture = SPIRALS[r]
	
	if counter_clockwise:
		$Spiral.flip_h = true
		$anim.play("spin_counter")
		dir = -1.0
	else:
		$anim.play("spin_clockwise")


func _process(delta):
	position.x += delta * speed * dir
