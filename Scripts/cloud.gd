extends Sprite2D
class_name DecorCloud


const CLOUD_DURATION : float = 64
const CLOUDS : Array[Texture2D] = [
	preload("res://Sprites/cloud_0.png"),
	preload("res://Sprites/cloud_1.png"),
	preload("res://Sprites/cloud_2.png"),
	preload("res://Sprites/cloud_3.png"),
	preload("res://Sprites/cloud_4.png"),
	preload("res://Sprites/cloud_5.png"),
	preload("res://Sprites/cloud_6.png"),
	preload("res://Sprites/cloud_7.png"),
]
const SECRET_CLOUDS : Array[Texture2D] = [
	preload("res://Sprites/cloud_secret_0.png"),
	preload("res://Sprites/cloud_secret_1.png"),
	preload("res://Sprites/cloud_secret_2.png"),
	preload("res://Sprites/cloud_secret_3.png"),
]

@export var speed : float = 16


func _ready():
	if randi_range(0, 49):
		var r : int = randi_range(0, CLOUDS.size() - 1)
		texture = CLOUDS[r]
	else:
		var r : int = randi_range(0, SECRET_CLOUDS.size() - 1)
		texture = SECRET_CLOUDS[r]
	var f : int = randi_range(0, 3)
	@warning_ignore("integer_division")
	flip_h = f / 2
	flip_v = f % 2
	$shadow.self_modulate = self_modulate
	$shadow.texture = texture
	$shadow.flip_h = flip_h
	$shadow.flip_v = flip_v
	$anim.play("Cloud")


func _process(delta):
	position.x -= delta * speed


func _on_anim_animation_finished(_anim_name):
	get_parent().remove_child(self)
	queue_free()
