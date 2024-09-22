extends Node2D
class_name DecorElec


@export var point_amount : int = 7
@export var jump_lenght : Vector2 = Vector2(64, 64)
@export var direction : Vector2 = Vector2(0, -1)
@export var time_between : float = 0.05


@onready var bolt : Line2D = $bolt

var timer : float = 0


func _ready():
	if direction.x == 0:
		direction.x = randi_range(0, 1) * 2 - 1
	if direction.y == 0:
		direction.y = randi_range(0, 1) * 2 - 1


func bolt_offset(dir : float, lenght : float) -> float:
	var offset : float = randf_range(lenght * 0.333, lenght)
	if offset < lenght * 0.4:
		return dir * -offset
	else:
		return dir * offset


func _process(delta):
	timer -= delta
	if timer <= 0:
		timer = time_between
		
		if bolt.points.size() == point_amount:
			$anim.play("disappear")
			timer = 10
		elif bolt.points.size() > 0:
			var offset : Vector2 = Vector2(0, 0)
			offset.x = bolt_offset(direction.x, jump_lenght.x)
			offset.y = bolt_offset(direction.y, jump_lenght.y)
			bolt.add_point(bolt.points[bolt.points.size() - 2] + offset)
		else:
			bolt.add_point(Vector2(0, 0))


func _on_anim_animation_finished(_anim_name):
	get_parent().remove_child(self)
	queue_free()
