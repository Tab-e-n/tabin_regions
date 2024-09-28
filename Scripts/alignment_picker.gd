extends Node2D


var current_map : RegionControl
var player_alignments : Array[int] = []
var align_size : int = 0

var hovering_available : bool = false
var hovering_players : bool = false

@onready var available : AlignmentList = $available
@onready var players : AlignmentList = $players


func _ready():
	var packed_map : PackedScene = load("res://Maps/" + MapSetup.current_map_name)
	if packed_map:
		current_map = packed_map.instantiate()
		current_map.dummy = true
		$play.modulate = current_map.slight_tint(current_map.color)
		$map.add_child(current_map)
	
	if current_map.random_player_align_range == 0:
		align_size = current_map.align_amount - 1
	else:
		align_size = current_map.random_player_align_range
	
	available.set_align_list_size(align_size)
	for i in range(align_size):
		var leader : Sprite2D = available.add_leader(i, i + 1)
		leader.frame = 0
		available.color_leader(leader, current_map.align_color[i + 1])
	players.set_align_list_size(MapSetup.player_amount)
	
	player_alignments.resize(MapSetup.player_amount)


func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		get_tree().change_scene_to_file("res://setup_scene.tscn")
	
	var mouse_position = get_viewport().get_mouse_position()
	
	if hovering_available:
		var hovered_player : int = (mouse_position.x - AlignmentList.PLAY_ORDER_SCREEN_BORDER_GAP) / (AlignmentList.PLAY_ORDER_SPACING * available.scale.x)
		
		if hovered_player >= align_size:
			hovered_player = align_size - 1
		if hovered_player < 0:
			hovered_player = 0
		
		if hovered_player < current_map.align_names.size():
			$text_name.text = current_map.align_names[hovered_player + 1]
		
		if Input.is_action_just_pressed("left_click"):
			choose_align(hovered_player + 1)
	else:
		$text_name.text = ""
	
	if hovering_players:
		var hovered_player : int = (mouse_position.x - AlignmentList.PLAY_ORDER_SCREEN_BORDER_GAP) / (AlignmentList.PLAY_ORDER_SPACING * players.scale.x)
		
		if hovered_player >= MapSetup.player_amount:
			hovered_player = MapSetup.player_amount - 1
		if hovered_player < 0:
			hovered_player = 0
		
		if Input.is_action_just_pressed("left_click"):
			remove_align(hovered_player)


func choose_align(align : int):
	for i in range(MapSetup.player_amount):
		if player_alignments[i] == align:
			return
	for i in range(MapSetup.player_amount):
		if player_alignments[i] == 0:
			player_alignments[i] = align
			var leader : Sprite2D = players.add_leader(i, align)
			leader.frame = 0
			players.color_leader(leader, current_map.align_color[align])
			break


func remove_align(pos : int):
	players.remove_leader(player_alignments[pos])
	player_alignments[pos] = 0


func _on_play_pressed():
	MapSetup.preset_alignments = player_alignments.duplicate()
	get_tree().change_scene_to_file("res://main.tscn")


func _on_available_mouse_entered():
	hovering_available = true


func _on_available_mouse_exited():
	hovering_available = false


func _on_players_mouse_entered():
	hovering_players = true


func _on_players_mouse_exited():
	hovering_players = false
