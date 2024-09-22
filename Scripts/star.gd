extends Node2D
class_name DecorStar


@export var delay : float = 0


func _physics_process(delta):
	delay -= delta
	if not $anim.is_playing() and delay <= 0:
		$anim.play("star")


func _on_anim_animation_finished(_anim_name):
	get_parent().remove_child(self)
	queue_free()
