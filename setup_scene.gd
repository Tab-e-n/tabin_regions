extends Node

var current_map : RegionControl

var maps : Array

enum {MENU_LORE, MENU_ALIGNMENTS, MENU_DIFFICULTY}
var current_menu : int = 0

func _ready():
	maps = DirAccess.get_files_at("res://Maps")
	
	#maps.sort()
	#print(maps)
	
	for i in range(maps.size()):
		var new_name : String = maps[i].trim_suffix(".tscn")
		new_name = new_name.replace("_", " ")
		$map_list.add_item(new_name)
	
	$map_list.select(0)
	_on_map_list_item_selected(0)

func _process(delta):
	pass

func _on_players_value_changed(value):
	$def/map_data.text = $def/map_data.text.substr(0, $def/map_data.text.rfind("\n")) + "\nPLAYERS: " + String.num($def/players.value)

func _on_map_list_item_activated(index):
	start_playing(index)

func _on_map_list_item_selected(index):
	if current_map != null:
		current_map.queue_free()
	var packed_map : PackedScene = load("res://Maps/" + maps[index])
	current_map = packed_map.instantiate()
	
	current_map.dummy = true
	
	current_map.position = Vector2(768, 384)
	current_map.scale = Vector2(0.5, 0.5)
	
	$map.add_child(current_map)
	
	$map_name.text = $map_list.get_item_text(index)
	
	$def/map_data.text = ("Preset Turn Order" if current_map.use_preset_alignments else "Random Turn Order") + "\nLEADERS: " + String.num(current_map.align_amount - 1) + "\nPLAYERS: " + String.num($def/players.value)
	
	if current_map.max_user_amount >= 0:
		$def/players.max_value = current_map.max_user_amount - 1
	else:
		$def/players.max_value = current_map.align_amount - 1
	$def/players.value = current_map.user_amount
	
	$diff/preset.visible = current_map.use_custom_ai_setup
	
	$lore.text = current_map.tag + "\n" + current_map.lore


func _on_play_pressed():
	#print($map_list.is_anything_selected())
	if $map_list.is_anything_selected():
		start_playing($map_list.get_selected_items()[0])

func start_playing(index):
	MapSetup.current_map_name = maps[index]
	MapSetup.user_amount = $def/players.value
	get_tree().change_scene_to_file("res://main.tscn")

func _on_next_menu_pressed():
	current_menu += 1
	if current_menu > 2:
		current_menu = 0
	
	$lore.visible = current_menu == MENU_LORE
	$def.visible = current_menu == MENU_ALIGNMENTS
	$diff.visible = current_menu == MENU_DIFFICULTY

func _on_ai_default_pressed():
	MapSetup.ai_controler = AIControler.CONTROLER_DEFAULT

