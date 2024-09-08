extends Node2D


const CLOUD_DISTANCE_COVERED : float = 1024


@export var time_range_bottom : float = 8
@export var time_range_top : float = 24
@export var color : Color = Color(1, 1, 1, 1)


var packed_cloud : PackedScene = preload("res://Objects/cloud.tscn")
var timer : float = 0

@onready var cloud_offset : Vector4
@onready var game_camera : GameCamera


func _ready():
	cloud_offset.x = -ProjectSettings.get_setting("display/window/size/viewport_width") * 0.4 + CLOUD_DISTANCE_COVERED * 0.5
	cloud_offset.y = ProjectSettings.get_setting("display/window/size/viewport_width") * 0.4 + CLOUD_DISTANCE_COVERED * 0.5
	cloud_offset.z = -ProjectSettings.get_setting("display/window/size/viewport_height") * 0.4
	cloud_offset.w = ProjectSettings.get_setting("display/window/size/viewport_height") * 0.4
	
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
		var cloud : DecorCloud = packed_cloud.instantiate() as DecorCloud
		cloud.speed = CLOUD_DISTANCE_COVERED / DecorCloud.CLOUD_DURATION
		cloud.self_modulate = color
		if game_camera:
			cloud.position.x = randf_range(game_camera.farthest_left + cloud_offset.x, game_camera.farthest_right + cloud_offset.y)
			cloud.position.y = randf_range(game_camera.farthest_up + cloud_offset.z, game_camera.farthest_down + cloud_offset.w)
		add_child(cloud)
