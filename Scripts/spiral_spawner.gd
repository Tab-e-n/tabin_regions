extends Node2D


const SPIRAL_DISTANCE_COVERED : float = 320


@export var time_range_bottom : float = 1
@export var time_range_top : float = 4
@export var color : Color = Color(1, 1, 1, 1)
@export var direction : float = 0.0


var packed_spiral : PackedScene = preload("res://Objects/spiral.tscn")
var timer : float = 0

@onready var spiral_offset : Vector4
@onready var game_camera : GameCamera


func _ready():
	spiral_offset.x = -ProjectSettings.get_setting("display/window/size/viewport_width") * 0.2
	spiral_offset.y = ProjectSettings.get_setting("display/window/size/viewport_width") * 0.2
	spiral_offset.z = -ProjectSettings.get_setting("display/window/size/viewport_height") * 0.2
	spiral_offset.w = ProjectSettings.get_setting("display/window/size/viewport_height") * 0.2
	
	position = Vector2(0, 0)
	if get_tree().current_scene is GameControl:
		var game_control : GameControl = get_tree().current_scene as GameControl
		game_camera = game_control.game_camera
	else:
		queue_free()


func _process(delta):
	timer -= delta
	if timer <= 0:
		timer = randf_range(time_range_bottom, time_range_top)
		var spiral : DecorSpiral = packed_spiral.instantiate() as DecorSpiral
		spiral.speed = SPIRAL_DISTANCE_COVERED / DecorSpiral.SPIRAL_DURATION
		spiral.modulate = color
		if game_camera:
			spiral.position.x = randf_range(game_camera.farthest_left + spiral_offset.x, game_camera.farthest_right + spiral_offset.y)
			spiral.position.y = randf_range(game_camera.farthest_up + spiral_offset.z, game_camera.farthest_down + spiral_offset.w)
		if direction == 1.0:
			spiral.counter_clockwise = false
		elif direction == -1.0:
			spiral.counter_clockwise = true
		else:
			spiral.counter_clockwise = randi_range(0, 1)
		add_child(spiral)
