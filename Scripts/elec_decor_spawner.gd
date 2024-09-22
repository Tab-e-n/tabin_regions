extends Node2D


@export var time_range_bottom : float = 4
@export var time_range_top : float = 8
@export var point_amount_bot : int = 5
@export var point_amount_top : int = 9
@export var elec_count_bot : int = 1
@export var elec_count_top : int = 3
@export var jump_lenght : Vector2 = Vector2(64, 64)
@export var direction : Vector2 = Vector2(0, 1)
@export var time_between : float = 0.05
@export var color : Color = Color(1, 1, 1, 1)


var packed_elec : PackedScene = preload("res://Objects/elec_decor.tscn")
var timer : float = 0

@onready var elec_offset : Vector4
@onready var game_camera : GameCamera


func _ready():
	elec_offset.x = -ProjectSettings.get_setting("display/window/size/viewport_width") * 0.2 - direction.x * jump_lenght.x * point_amount_bot * 0.5
	elec_offset.y = ProjectSettings.get_setting("display/window/size/viewport_width") * 0.2 - direction.x * jump_lenght.x * point_amount_bot * 0.5
	elec_offset.z = -ProjectSettings.get_setting("display/window/size/viewport_height") * 0.2 - direction.y * jump_lenght.y * point_amount_bot * 0.5
	elec_offset.w = ProjectSettings.get_setting("display/window/size/viewport_height") * 0.2 - direction.y * jump_lenght.y * point_amount_bot * 0.5
	
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
		var elec_pos : Vector2 = Vector2(0, 0)
		if game_camera:
			elec_pos.x = randf_range(game_camera.farthest_left + elec_offset.x, game_camera.farthest_right + elec_offset.y)
			elec_pos.y = randf_range(game_camera.farthest_up + elec_offset.z, game_camera.farthest_down + elec_offset.w)
		var elec_count = randi_range(elec_count_bot, elec_count_top)
		for i in range(elec_count):
			var elec : DecorElec = packed_elec.instantiate() as DecorElec
			elec.modulate = color
			elec.point_amount = randi_range(point_amount_bot, point_amount_top)
			elec.jump_lenght = jump_lenght
			elec.direction = direction
			elec.time_between = time_between
			elec.position = elec_pos
			add_child(elec)
