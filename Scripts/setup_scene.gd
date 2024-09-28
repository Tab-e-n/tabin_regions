extends Node


var current_map : RegionControl

var maps : Array

enum {MENU_LORE, MENU_ALIGNMENTS, MENU_DIFFICULTY}
var current_menu : int = 0


@onready var tintable_ui : Node2D = $tintable_ui

@onready var map_list : ItemList = $tintable_ui/map_list
@onready var map_options : Control = $tintable_ui/def
@onready var map_ai : Control = $tintable_ui/diff

@onready var map_name : Label = $tintable_ui/map_name
@onready var map_lore : Label = $tintable_ui/lore

@onready var options_label : Label = $tintable_ui/def/map_data
@onready var slider_player : HSlider = $tintable_ui/def/players
@onready var slider_leader : HSlider = $tintable_ui/def/leaders
@onready var slider_aliances : HSlider = $tintable_ui/def/aliances

@onready var ai_preset : Label = $tintable_ui/diff/preset
@onready var ai_cursor : Sprite2D = $tintable_ui/diff/AiSelected


func _ready():
	Options.save_options()
	
	maps = DirAccess.get_files_at("res://Maps")
	
#	maps.sort()
#	print(maps)
	
	for i in range(maps.size()):
		maps[i] = maps[i].trim_suffix(".remap")
		var new_name : String = maps[i].trim_suffix(".tscn")
		new_name = new_name.replace("_", " ")
		map_list.add_item(new_name)
	
	var map = maps.find(MapSetup.current_map_name)
	
	if map == -1:
		map_list.select(0)
		_on_map_list_item_selected(0)
	else:
		map_list.select(map)
		_on_map_list_item_selected(map)
	
	MapSetup.preset_alignments.clear()
	
	ai_selected_pos()
	
	ReplayControl.clear_replay()


func _process(_delta):
	pass


func _on_leaders_value_changed(value):
	if slider_player.value > value:
		slider_player.value = value
	_on_def_slider_value_changed(value)


func _on_players_value_changed(value):
	if slider_leader.value < value:
		slider_leader.value = value
	_on_def_slider_value_changed(value)


func _on_def_slider_value_changed(_value):
	map_data_text()


func _on_map_list_item_activated(index):
	start_playing(index)


func _on_map_list_item_selected(index):
	if current_map != null:
		current_map.queue_free()
	var packed_map : PackedScene = load("res://Maps/" + maps[index])
	current_map = packed_map.instantiate() as RegionControl
	
	current_map.dummy = true
	
	current_map.position = Vector2(768, 384)
	current_map.scale = Vector2(0.5, 0.5)
	
	tintable_ui.modulate = current_map.slight_tint(current_map.color)
	
	$map.add_child(current_map)
	
	map_name.text = map_list.get_item_text(index)
	
	map_data_text()
	
	slider_leader.visible = not current_map.lock_align_amount
	slider_leader.max_value = current_map.align_amount - 1
	
	slider_player.visible = not current_map.lock_player_amount
	if current_map.max_player_amount >= 0:
		slider_player.max_value = current_map.max_player_amount
	else:
		slider_player.max_value = current_map.align_amount - 1
	
	slider_aliances.visible = not current_map.lock_aliances
	slider_aliances.max_value = current_map.align_amount - 1
	
	ai_preset.visible = current_map.use_custom_ai_setup
	ai_cursor.visible = !current_map.use_custom_ai_setup
	
	map_lore.text = current_map.tag + ", " + current_map.complexity + "\n" + current_map.lore
	
	if MapSetup.current_map_name != maps[index]:
		if current_map.used_alignments >= 2:
			slider_leader.value = current_map.used_alignments
		else:
			slider_leader.value = current_map.align_amount - 1
		slider_player.value = current_map.player_amount
		slider_aliances.value = 1
		MapSetup.current_map_name = maps[index]
	else:
		slider_player.value = MapSetup.player_amount
		slider_aliances.value = MapSetup.aliances_amount
		slider_leader.value = MapSetup.used_aligments


func map_data_text():
	options_label.text = ("PRESET ORDER" if current_map.use_preset_alignments else "RANDOM ORDER")
	options_label.text += "\nLEADERS: " + String.num(slider_leader.value)
	options_label.text += "\nPLAYERS: " + (String.num(slider_player.value) if slider_player.value > 0 else "X")
	options_label.text += "\nALIANCES: " + (String.num(slider_aliances.value) if slider_aliances.value > 1 else "X")


func _on_play_pressed():
	#print(map_list.is_anything_selected())
	if map_list.is_anything_selected():
		start_playing(map_list.get_selected_items()[0])


func start_playing(index):
	MapSetup.current_map_name = maps[index]
	MapSetup.player_amount = int(slider_player.value)
	MapSetup.aliances_amount = int(slider_aliances.value)
	MapSetup.used_aligments = int(slider_leader.value)
	if current_map.use_alignment_picker and MapSetup.player_amount > 0:
		get_tree().change_scene_to_file("res://alignment_picker.tscn")
	else:
		get_tree().change_scene_to_file("res://main.tscn")


func _on_next_menu_pressed():
	current_menu += 1
	if current_menu > 2:
		current_menu = 0
	
	map_lore.visible = current_menu == MENU_LORE
	map_options.visible = current_menu == MENU_ALIGNMENTS
	map_ai.visible = current_menu == MENU_DIFFICULTY


func ai_selected_pos():
	match(MapSetup.default_ai_controler):
		AIControler.CONTROLER_TURTLE:
			ai_cursor.position.x = 624
		AIControler.CONTROLER_DEFAULT:
			ai_cursor.position.x = 752
		AIControler.CONTROLER_NEURAL:
			ai_cursor.position.x = 880
		AIControler.CONTROLER_CHEATER:
			ai_cursor.position.x = 1008


func _on_ai_turtle_pressed():
	MapSetup.default_ai_controler = AIControler.CONTROLER_TURTLE
	ai_selected_pos()


func _on_ai_default_pressed():
	MapSetup.default_ai_controler = AIControler.CONTROLER_DEFAULT
	ai_selected_pos()


func _on_ai_cheater_pressed():
	MapSetup.default_ai_controler = AIControler.CONTROLER_CHEATER
	ai_selected_pos()


func _on_replay_pressed():
	$replay_window.popup_centered(Vector2(480, 480))


func _on_replay_window_file_selected(path):
	ReplayControl.load_replay(path)
	get_tree().change_scene_to_file("res://main.tscn")
#	print(path)

