extends Node2D


@export var time_range_bottom : float = 2
@export var time_range_top : float = 4
@export var star_scale_bottom : float = 0.5
@export var star_scale_top : float = 2
@export var star_count_bottom : int = 1
@export var star_count_top : int = 3
@export var color : Color = Color(1, 1, 1, 1)


var packed_star : PackedScene = preload("res://Objects/star.tscn")
var timer : float = 0

@onready var star_offset : Vector4
@onready var game_camera : GameCamera


func _ready():
	star_offset.x = -ProjectSettings.get_setting("display/window/size/viewport_width") * 0.2
	star_offset.y = ProjectSettings.get_setting("display/window/size/viewport_width") * 0.2
	star_offset.z = -ProjectSettings.get_setting("display/window/size/viewport_height") * 0.2
	star_offset.w = ProjectSettings.get_setting("display/window/size/viewport_height") * 0.2
	
	timer = time_range_bottom
	
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
		var star_amount : int = randi_range(star_count_bottom, star_count_top)
		for i in range(star_amount):
			var star : DecorStar = packed_star.instantiate() as DecorStar
			star.modulate = color
			star.scale.x = randf_range(star_scale_bottom, star_scale_top)
			star.scale.y = star.scale.x
			star.delay = float(i) * 0.1
			if game_camera:
				star.position.x = randf_range(game_camera.farthest_left + star_offset.x, game_camera.farthest_right + star_offset.y)
				star.position.y = randf_range(game_camera.farthest_up + star_offset.z, game_camera.farthest_down + star_offset.w)
			add_child(star)
