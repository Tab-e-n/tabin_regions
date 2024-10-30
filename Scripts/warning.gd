extends Node2D
class_name RegionWarning


@export var color : Color = Color(1, 1, 1, 1)
@export var warning_number : int = 1

@onready var visual : Sprite2D = $visual


func _ready():
	visual.position.x = 24 * (warning_number + 1)
	visual.modulate = color
	hide_self()


func hide_self():
	visual.visible = false


func show_self():
	visual.modulate = color
	visual.visible = true
