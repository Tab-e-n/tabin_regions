extends Node2D
class_name RegionWarning


@export var color : Color = Color(1, 1, 1, 1)
@export var warning_number : int = 1

@onready var visual : Sprite2D = $visual
@onready var outline : Sprite2D = $visual/outline


func _ready():
	visual.position.x = 24 * (warning_number + 1)
	hide_self()


func hide_self():
	visual.visible = false


func show_self():
	visual.self_modulate = color
	if color.v > RegionControl.COLOR_TOO_BRIGHT:
		outline.self_modulate = Color(0, 0, 0)
	else:
		outline.self_modulate = Color(1, 1, 1)
	visual.visible = true
