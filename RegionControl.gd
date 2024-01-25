extends Polygon2D
class_name RegionControl


signal turn_ended
signal turn_phase_changed(phase)
signal game_ended(winner)


const COLOR_TOO_BRIGHT : float = 0.9


@onready var bg_color : Color = color
@onready var game_control : GameControl


@export_enum("Skirmish", "Challenge", "Bot Battle") var tag : String = "Skirmish"
@export_enum("Unspecified", "Beginner", "Simple", "Medium", "Hard", "Extreme") var complexity : String = "Unspecified"
@export_multiline var lore : String = """Insert lore here"""

@export var align_amount : int = 3
@export var align_color : Array = [
		Color("6e5769"),
		Color("ab2433"), # red
		Color("1a905e"), # green
		Color("267dbd"), # blue
		Color("af5b02"), # gold
		Color("8a21ad"), # purple
		Color("ed858d"), # pink
		Color("57f47a"), # lime
		Color("7794f2"), # teal
		Color("cfe518"), # yellow
		Color("d7cac0"), # silver
		Color("f0289b"), # magenta
		Color("395621"), # grass
		Color("213775"), # navy
		Color("673a2b"), # brown
		Color("420029"), # violet
]
@export var connections : Array = []
@export var city_size : float = 1

@export var allow_map_spec_change : bool = true

@export_subgroup("Users")
@export var user_amount : int = 1
@export var random_player_align_range : int = 0
@export var max_user_amount : int = -1
@export var use_preset_alignments : bool = false
@export var preset_user_alignments : Array = []

@export_subgroup("AI")
@export var use_custom_ai_setup : bool = false
@export_enum("None", "Default", "Turtle", "Neural", "Cheater", "Dummy") var ai_controler : int = AIControler.CONTROLER_DEFAULT
@export var custom_ai_setup : Array = []

@export_subgroup("Aliances")
@export var aliances_active : bool = false
@export var alignment_aliances : PackedInt32Array = []
@export var automatic_aliances : bool = false
@export var autoaliance_divisions_amount : int = 2


var dummy : bool = false

var current_player : int = 1
var player_order : Array = []
var player_in_play_order : int = 0


var player_controlers : Array = []
var is_user_controled : bool

var region_amount : Array = []
var last_turn_region_amount : Array = []
var capital_amount : Array = []

enum {ACTION_NORMAL, ACTION_MOBILIZE, ACTION_BONUS}
const ACTION_MODES_AMOUNT : int = 3
var current_action : int = ACTION_NORMAL

var action_amount : int = 1
var bonus_action_amount : int = 0

var current_turn : int = 1
var current_placement : int = 0

func _ready():
	if dummy:
		return
	
	game_control = get_parent()
	game_control.region_control = self
	
	user_amount = MapSetup.user_amount
	if not use_custom_ai_setup:
		ai_controler = MapSetup.ai_controler
	if not aliances_active and MapSetup.aliances_amount > 1:
		aliances_active = true
		automatic_aliances = true
		autoaliance_divisions_amount = MapSetup.aliances_amount
	
	for link in connections:
		var link_diff = 0
		if link.size() >= 3:
			link_diff = link[2]
		var region_0 : Region = get_node(link[0])
		var region_1 : Region = get_node(link[1])
		if region_0 == null or region_1 == null:
			print(link[0], " or ", link[1], " does not exist.")
			continue
		if not region_0.connections.has(link[1]):
			region_0.connections[link[1]] = link_diff
		else:
			print("connection ", link[0], " - ", link[1], " already exists.")
		if not region_1.connections.has(link[0]):
			region_1.connections[link[0]] = link_diff
		else:
			print("connection ", link[1], " - ", link[0], " already exists.")
	
	region_amount.resize(align_amount - 1)
	capital_amount.resize(align_amount - 1)
	for i in range(align_amount - 1):
		region_amount[i] = 0
		capital_amount[i] = 0
	
	count_up_regions()
	
	if random_player_align_range < max_user_amount:
		random_player_align_range = max_user_amount
	
	player_order.resize(align_amount - 1)
	var players : Array = range(align_amount)
	players.pop_front()
	
	if use_preset_alignments and user_amount > 0:
		for i in range(preset_user_alignments.size()):
			player_order[i] = preset_user_alignments[i]
			players.pop_at(players.find(preset_user_alignments[i]))
	
#	print(player_order)
	
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(players.size()):
		var pos : int = rng.randi_range(0, players.size() - 1)
		if random_player_align_range > 0 and i < random_player_align_range and not use_preset_alignments:
			pos = rng.randi_range(0, random_player_align_range - i - 1)
		var order : int = i
		if use_preset_alignments and user_amount > 0:
			order += user_amount
		player_order[order] = players.pop_at(pos)
	
#	print(player_order)
	
	current_player = player_order[0]
	
	player_controlers.resize(align_amount - 1)
	for i in range(align_amount - 1):
		if i < custom_ai_setup.size():
			player_controlers[i] = custom_ai_setup[i]
		else:
			player_controlers[i] = ai_controler
	for i in range(user_amount):
		player_controlers[player_order[i] - 1] = AIControler.CONTROLER_USER
	
	
	GameStats.reset_statistics(align_amount)
	
	for i in range(align_amount):
		GameStats.stats[i]["align color"] = align_color[i]
		if i != 0:
			GameStats.stats[i]["controler"] = player_controlers[i - 1]
		else:
			GameStats.stats[i]["controler"] = AIControler.CONTROLER_DUMMY
	
	current_placement = align_amount - 1
	
	if not aliances_active:
		alignment_aliances = range(align_amount)
	else:
		if alignment_aliances.size() < align_amount:
			alignment_aliances.resize(align_amount)
		if automatic_aliances:
			alignment_aliances[0] = 0
			var current_aliance : int = 1
			for i in range(align_amount - 1):
				alignment_aliances[player_order[i]] = current_aliance
				current_aliance += 1
				if current_aliance > autoaliance_divisions_amount:
					current_aliance = 1
	
	reset()

func _process(_delta):
	if dummy:
		return
	
	if is_user_controled:
		if Input.is_action_just_pressed("plus_turn"):
			change_current_action()
		if Input.is_action_just_pressed("plus_foward"):
			turn_end()
		if Input.is_action_just_pressed("forfeit"):
			forfeit()

func count_up_regions():
	for i in range(region_amount.size()):
		region_amount[i] = 0
	for region in get_children():
		if not region is Region:
			continue
		if region.alignment == 0 or region.alignment >= align_amount:
			continue
		region_amount[region.alignment - 1] += 1
		if region.is_capital:
			capital_amount[region.alignment - 1] += 1
	
	last_turn_region_amount = region_amount.duplicate()


func cross(capital_position : Vector2):
	game_control.cross.visible = true
	game_control.cross.position = capital_position


func action_done():
	game_control.cross.visible = false
	if current_action == ACTION_NORMAL:
		GameStats.stats[current_player]["first actions done"] += 1
		action_amount -= 1
		if action_amount == 0:
			current_action = ACTION_MOBILIZE
	elif current_action == ACTION_MOBILIZE:
		pass
	elif current_action == ACTION_BONUS:
		GameStats.stats[current_player]["bonus actions done"] += 1
		bonus_action_amount -= 1
		if bonus_action_amount == 0:
			current_action = ACTION_NORMAL
			turn_end()


func change_current_action():
	game_control.cross.visible = false
	if current_action == ACTION_NORMAL and action_amount > 0:
		bonus_action_amount = action_amount
	current_action += 1
	
	turn_phase_changed.emit(current_action)
	
	if current_action == ACTION_MODES_AMOUNT:
		current_action = ACTION_NORMAL
		turn_end()


func turn_end():
	if region_amount[current_player - 1] > 0:
		GameStats.stats[current_player]["turns lasted"] = current_turn
	var first_loop = true
	var starting_player = player_in_play_order
	while region_amount[current_player - 1] == 0 or first_loop:
		player_in_play_order += 1
		if player_in_play_order == align_amount - 1:
			player_in_play_order = 0
			current_turn += 1
		current_player = player_order[player_in_play_order]
		first_loop = false
		if player_in_play_order == starting_player:
#			victory(current_player)
			break
	check_victory()
	
	var placement = String.num(current_placement)
	
	for i in range(region_amount.size()):
		if region_amount[i] != last_turn_region_amount[i] and region_amount[i] == 0:
			GameStats.stats[i + 1]["placement"] = placement
			current_placement -= 1
	
	last_turn_region_amount = region_amount.duplicate()
	
	reset()
	
	turn_ended.emit()


func check_victory():
	var aliance = null
	for i in range(region_amount.size()):
		if region_amount[i] > 0:
			if aliance == null:
				aliance = alignment_aliances[i + 1]
			elif aliance != alignment_aliances[i + 1]:
				return
	victory(current_player)


func victory(align_victory : int):
	dummy = true
	game_control.game_camera.win(align_victory)
	GameStats.stats[align_victory]["placement"] = "1"
	if aliances_active:
		for i in range(align_amount - 1):
			if alignment_aliances[i + 1] == alignment_aliances[align_victory]:
				GameStats.stats[i + 1]["placement"] = "1"
	
	var placement = String.num(current_placement)
	
	for i in range(align_amount - 1):
		if GameStats.stats[i + 1]["placement"] == "N/A":
			GameStats.stats[i + 1]["placement"] = placement
	
	game_ended.emit(align_victory)


func reset():
	if region_amount[current_player - 1] > GameStats.stats[current_player]["most regions owned"]:
		GameStats.stats[current_player]["most regions owned"] = region_amount[current_player - 1]
	if capital_amount[current_player - 1] > GameStats.stats[current_player]["most capitals owned"]:
		GameStats.stats[current_player]["most capitals owned"] = capital_amount[current_player - 1]
	action_amount = capital_amount[current_player - 1]
	bonus_action_amount = 1 if action_amount == 0 else 0
	current_action = ACTION_MOBILIZE if action_amount == 0 else 0
	
	color = bg_color + align_color[current_player] * Color(0.25, 0.25, 0.25)
	
	is_user_controled = player_controlers[current_player - 1] == AIControler.CONTROLER_USER
	
	if !is_user_controled:
		game_control.ai_control.start_turn(current_player, player_controlers[current_player - 1])


func forfeit():
	convert_alignment(current_player, 0)
	
	turn_end()


func convert_alignment(align_old : int, align_new : int):
	if align_old < 0:
		push_warning("Alignment ", align_old, " cannot be converted.")
		return
	if align_new < 0:
		push_warning("Alignment ", align_new, " cannot be converted to.")
		return
	
	for region in get_children():
		if region is Region:
			if region.alignment == align_old:
				region.change_alignment(align_new)


func alignment_friendly(your_align, opposing_align) -> bool:
	if your_align < 0 or your_align >= align_amount:
		return false
	if opposing_align < 0 or opposing_align >= align_amount:
		return false
	return alignment_aliances[your_align] == alignment_aliances[opposing_align]
#	if your_align == opposing_align:
#		return true
#	return false
