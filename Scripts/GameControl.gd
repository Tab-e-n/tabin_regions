extends Node2D
class_name GameControl


@export var map : String = "Testlandia.tscn"

@onready var game_camera : GameCamera
@onready var cross : Polygon2D = $Cross
@onready var region_control : RegionControl
@onready var ai_control : AIControler

var hide_cross : float = 0


func _ready():
	map = MapSetup.current_map_name
	var packed_map : PackedScene = load("res://Maps/" + map)
	region_control = packed_map.instantiate()
	add_child(region_control)
	move_child(region_control, 1)


func _process(delta):
	if cross.visible == true and hide_cross < 0:
		hide_cross = 1
	hide_cross -= delta
	if hide_cross < 0:
		cross.visible = false
