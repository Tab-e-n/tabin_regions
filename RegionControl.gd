extends Polygon2D
class_name RegionControl

@export_enum("Skirmish", "Challenge", "Bot Battle") var tag : String = "Skirmish"
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
		Color("420029"), # violet
		Color("673a2b"), # brown
]
@export var connections : Array = []

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

var dummy : bool = false

@onready var game_control : GameControl

var current_player : int = 1
var player_order : Array = []
var player_in_play_order : int = 0


var player_controlers : Array = []
var is_user_controled : bool

var region_amount : Array = []
var last_turn_region_amount : Array = []
var capital_amount : Array = []

enum {ACTION_NORMAL, ACTION_MOBILIZE, ACTION_BONUS}
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
	ai_controler = MapSetup.ai_controler
	
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
			print(link[0], " already has this connection.")
		if not region_1.connections.has(link[0]):
			region_1.connections[link[0]] = link_diff
		else:
			print(link[1], " already has this connection.")
	
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
	
	reset()

func _process(delta):
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
		if region.alignment == 0:
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
	if current_action == 0 and action_amount > 0:
		bonus_action_amount = action_amount
	current_action += 1
	if current_action == 3:
		current_action = 0
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
			dummy = true
			game_control.game_camera.win(current_player)
			GameStats.stats[current_player]["placement"] = "1"
			break
	
	var placement = String.num(current_placement)
	
	for i in range(region_amount.size()):
		if region_amount[i] != last_turn_region_amount[i] and region_amount[i] == 0:
			GameStats.stats[i + 1]["placement"] = placement
			current_placement -= 1
	
	last_turn_region_amount = region_amount.duplicate()
	
	reset()

func reset():
	if region_amount[current_player - 1] > GameStats.stats[current_player]["most regions owned"]:
		GameStats.stats[current_player]["most regions owned"] = region_amount[current_player - 1]
	if capital_amount[current_player - 1] > GameStats.stats[current_player]["most capitals owned"]:
		GameStats.stats[current_player]["most capitals owned"] = capital_amount[current_player - 1]
	action_amount = capital_amount[current_player - 1]
	bonus_action_amount = 1 if action_amount == 0 else 0
	current_action = 1 if action_amount == 0 else 0
	
	color = align_color[current_player]
	color.a = 0.25
	
	is_user_controled = player_controlers[current_player - 1] == AIControler.CONTROLER_USER
	
	if !is_user_controled:
		game_control.ai_control.start_turn(current_player, player_controlers[current_player - 1])

func forfeit():
	for region in get_children():
		if not region is Region:
			continue
		if region.alignment == current_player:
			region.alignment = 0
			region.color_self()
	
	region_amount[current_player - 1] = 0
	capital_amount[current_player - 1] = 0
	
	turn_end()
