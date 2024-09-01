extends Polygon2D
class_name RegionControl


signal turn_ended
signal turn_phase_changed(phase)
signal game_ended(winner)


const COLOR_TOO_BRIGHT : float = 0.9

enum APPLY_PENALTIES {OFF, CURRENT_CAPITAL, PREVIOUS_CAPITAL}


@onready var bg_color : Color = color
@onready var game_control : GameControl
@onready var game_camera : GameCamera


@export var allow_map_spec_change : bool = true
@export var use_alignment_picker : bool = true

@export_subgroup("Gameplay")
# After a player reaches `key : int` capital amount, every subsequent capitol gains them `value: float`% less.
@export_enum ("Off", "Current Capital Amount", "Previous Capital Amount") var apply_penalties : int = APPLY_PENALTIES.OFF
@export var power_gain_penalties : Dictionary = {
	3 : .325,
	13 : .25,
	21 : .125,
} 

@export_subgroup("Alignments & Players")
@export var align_amount : int = 3
@export var player_amount : int = 1
@export var random_player_align_range : int = 0
@export var max_player_amount : int = -1
@export var use_preset_alignments : bool = false
@export var preset_alignments : Array[int] = []

@export_subgroup("AI")
@export_enum("None", "Default", "Turtle", "Neural", "Cheater", "Dummy") var default_ai_controler : int = AIControler.CONTROLER_DEFAULT
@export var use_custom_ai_setup : bool = false
@export var custom_ai_setup : Array[int] = []

@export_subgroup("Aliances")
@export var use_aliances : bool = false
@export var alignment_aliances : Array[int] = []
@export var use_autoaliances : bool = false
@export var autoaliances_divisions_amount : int = 2

@export_subgroup("Cosmetics")
@export_enum("Skirmish", "Challenge", "Bot Battle") var tag : String = "Skirmish"
@export_enum("Unspecified", "Beginner", "Simple", "Intermediate", "Advanced", "Extreme") var complexity : String = "Unspecified"
@export_multiline var lore : String = """Insert lore here"""

@export var align_color : Array[Color] = [
		Color("625775"), # purplish gray
		
		Color("a72b37"), # red
		Color("368d61"), # green
		Color("2b7dba"), # blue
		Color("ae5b15"), # orange
		Color("8927a8"), # purple
		
		Color("ed858d"), # salmon
		Color("c5ebbf"), # pistachio
		Color("213775"), # navy
		Color("a58260"), # dirt
		Color("dd4f96"), # magenta
		
		Color("deaac7"), # pink
		Color("6da63d"), # vibrant green
		Color("7795ed"), # teal
		Color("d09f15"), # gold
		Color("b177c9"), # lavender
		
		Color("7a0e43"), # violet
		Color("395621"), # grass
		Color("556aa2"), # denim
		Color("d7e06b"), # yellow
		Color("895870"), # dim lavender
		
		Color("3f0628"), # dark red
		Color("7ded92"), # lime
		Color("2b4456"), # swamp
		Color("d7cac0"), # tan
		Color("828387"), # gray
		
		Color("673a2b"), # brown
		Color("4e4c32"), # tank
		Color("b6b7eb"), # silver
		Color("eda75b"), # sandstorm
		Color("2e5949"), # dark green
]
@export var align_names : Array[String] = []

@export var city_size : float = 1
@export var snap_camera_to_first_align_capital : bool = true
@export var hide_turn_order : bool = false

@export_subgroup("Editor")
@export var connections : Array = []
@export_enum("Disabled", "Alignment", "Power", "Max Power", "Capital", "Position") var render_mode : int = 0
@export var render_range : float = 20

var dummy : bool = false

var current_playing_align : int = 1
var align_play_order : Array = []
var play_order_i : int = 0


var align_controlers : Array = []
var is_player_controled : bool

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

var penalty_amount : Array = []


func _ready():
	if dummy:
		return
	
	game_control = get_parent()
	game_control.region_control = self
	game_camera = game_control.game_camera
	
	if ReplayControl.replay_active:
		align_play_order = ReplayControl.replay_play_order
		alignment_aliances = ReplayControl.replay_aliances
		align_controlers = ReplayControl.replay_controlers
		use_aliances = ReplayControl.replay_uses_aliances
	else:
		player_amount = MapSetup.player_amount
		if not use_custom_ai_setup:
			default_ai_controler = MapSetup.default_ai_controler
		if not use_aliances and MapSetup.aliances_amount > 1:
			use_aliances = true
			use_autoaliances = true
			autoaliances_divisions_amount = MapSetup.aliances_amount
		if not use_preset_alignments and use_alignment_picker:
			preset_alignments = MapSetup.preset_alignments.duplicate()
			use_preset_alignments = true
	
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
	penalty_amount.resize(align_amount - 1)
	for i in range(align_amount - 1):
		region_amount[i] = 0
		capital_amount[i] = 0
		penalty_amount[i] = 0
	
	count_up_regions()
	
	bake_capital_distance()
	
	if not ReplayControl.replay_active:
		if random_player_align_range < max_player_amount:
			random_player_align_range = max_player_amount
		
		align_play_order.resize(align_amount - 1)
		var players : Array = range(align_amount)
		players.pop_front()
		
		var preset_aligments_amount = preset_alignments.size()
		if use_preset_alignments and preset_aligments_amount > 0:
			for i in range(preset_alignments.size()):
				if preset_alignments[i] != 0:
					align_play_order[i] = preset_alignments[i]
					players.pop_at(players.find(preset_alignments[i]))
		
	#	print(align_play_order)
		
		var rng : RandomNumberGenerator = RandomNumberGenerator.new()
		rng.randomize()
		var order : int = -1
		for i in range(align_amount - 1):
			if align_play_order[i]:
				continue
			var pos : int = 0
			if random_player_align_range > 0 and i < random_player_align_range and not use_preset_alignments:
				pos = rng.randi_range(0, random_player_align_range - i - 1)
			else:
				pos = rng.randi_range(0, players.size() - 1)
			align_play_order[i] = players.pop_at(pos)
	
#	print(align_play_order)
#	print(players)
	
	current_playing_align = align_play_order[0]
	
	if not ReplayControl.replay_active:
		align_controlers.resize(align_amount - 1)
		for i in range(align_amount - 1):
			if i < custom_ai_setup.size():
				align_controlers[i] = custom_ai_setup[i]
			else:
				align_controlers[i] = default_ai_controler
		for i in range(player_amount):
			align_controlers[align_play_order[i] - 1] = AIControler.CONTROLER_USER
	
	
	GameStats.reset_statistics(align_amount)
	
	for align in range(align_amount):
		GameStats.set_stat(align, "align color", align_color[align])
#		GameStats.stats[align]["align color"] = align_color[align]
		if align != 0:
			GameStats.set_stat(align, "controler", align_controlers[align - 1])
#			GameStats.stats[align]["controler"] = align_controlers[align - 1]
		else:
			GameStats.set_stat(align, "controler", AIControler.CONTROLER_DUMMY)
#			GameStats.stats[align]["controler"] = AIControler.CONTROLER_DUMMY
	
	current_placement = align_amount - 1
	
	if not ReplayControl.replay_active:
		if alignment_aliances.size() < align_amount:
			alignment_aliances.resize(align_amount)
		
		if not use_aliances:
			for i in range(align_amount):
				alignment_aliances[i] = i
		else:
			if use_autoaliances:
				alignment_aliances[0] = 0
				var current_aliance : int = 1
				for i in range(align_amount - 1):
					alignment_aliances[align_play_order[i]] = current_aliance
					current_aliance += 1
					if current_aliance > autoaliances_divisions_amount:
						current_aliance = 1
	
	align_names.resize(align_amount)
	for align in range(align_amount):
		GameStats.set_stat(align, "alignment name", align_names[align])
	
	reset()
	
	if hide_turn_order:
		game_camera.toggle_turn_order_visibility()
	
	if snap_camera_to_first_align_capital:
		var center_camera : Vector2 = Vector2(0, 0)
		for region in get_children():
			if region is Region:
				if region.alignment == current_playing_align:
					center_camera = region.position
					if region.is_capital:
						break
		game_camera.center_camera(center_camera)
	
	if not ReplayControl.replay_active:
		ReplayControl.clear_replay()
		
		ReplayControl.replay_play_order = align_play_order.duplicate()
		ReplayControl.replay_aliances = alignment_aliances.duplicate()
		ReplayControl.replay_controlers = align_controlers.duplicate()
		
		ReplayControl.replay_uses_aliances = use_aliances


func _process(_delta):
	if dummy:
		return
	
	if is_player_controled:
		if Input.is_action_just_pressed("forfeit"):
			forfeit()
			game_camera.CommandCallout.new_callout("Forfeit")
		elif Input.is_action_just_pressed("plus_foward"):
			turn_end(true)
			game_camera.CommandCallout.new_callout("End turn")
		elif Input.is_action_just_pressed("plus_turn"):
			change_current_action()
			game_camera.CommandCallout.new_callout("Advance turn")


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


func bake_capital_distance():
	for capital in get_children():
		if not capital is Region:
			continue
		if not capital.is_capital:
			continue
		capital.distance_from_capital = 0
		var current_distance : int = 2
		var regions : Array = capital.connections.keys()
		while regions.size() > 0:
			var next_regions : Array = []
			for reg_name in regions:
				var region : Region = get_node(reg_name) as Region
				if region.distance_from_capital < current_distance:
					continue
				elif region.is_capital:
					region.distance_from_capital = 0
				elif region.distance_from_capital > current_distance:
					region.distance_from_capital = current_distance
					next_regions.append_array(region.connections.keys())
				elif region.distance_from_capital == current_distance:
					region.distance_from_capital -= 1
			current_distance += 2
			
			regions.clear()
#			for reg_name in next_regions:
#				if not regions.has(reg_name):
#					regions.append(reg_name)
			
			while next_regions.size() > 0:
				var reg = next_regions.pop_back()
				if reg == "":
					continue
				regions.append(reg)
				for i in range(next_regions.size()):
					if next_regions[i] == reg:
						next_regions[i] = ""
			
#			print(regions)


func cross(capital_position : Vector2):
	game_control.cross.visible = true
	game_control.cross.position = capital_position


func action_done(region_name : String):
	game_control.cross.visible = false
	if current_action == ACTION_NORMAL:
		if action_amount > 0:
			GameStats.add_to_stat(current_playing_align, "first actions done", 1)
			action_amount -= 1
			ReplayControl.record_move(ReplayControl.RECORD_TYPE_REGION, region_name)
		if action_amount <= 0:
			current_action = ACTION_MOBILIZE
	elif current_action == ACTION_MOBILIZE:
		ReplayControl.record_move(ReplayControl.RECORD_TYPE_REGION, region_name)
	elif current_action == ACTION_BONUS:
		if bonus_action_amount > 0:
			GameStats.add_to_stat(current_playing_align, "bonus actions done", 1)
			bonus_action_amount -= 1
			ReplayControl.record_move(ReplayControl.RECORD_TYPE_REGION, region_name)
		if bonus_action_amount <= 0:
			current_action = ACTION_NORMAL
			turn_end(false)


func has_enough_actions() -> bool:
	if current_action == ACTION_NORMAL:
		return action_amount > 0
	elif current_action == ACTION_BONUS:
		return bonus_action_amount > 0
	else:
		return true
	


func change_current_action():
	game_control.cross.visible = false
	if current_action == ACTION_NORMAL and action_amount > 0:
		bonus_action_amount = action_amount
	current_action += 1
	
	turn_phase_changed.emit(current_action)
	
	if current_action == ACTION_MODES_AMOUNT:
		current_action = ACTION_NORMAL
		turn_end(false)
	
	ReplayControl.record_move(ReplayControl.RECORD_TYPE_FUNCTION, "change_current_action")


func turn_end(record : bool):
	calculate_penalty(current_playing_align, true)
	
	if region_amount[current_playing_align - 1] > 0:
		GameStats.set_stat(current_playing_align, "turns lasted", current_turn)
#		GameStats.stats[current_playing_align]["turns lasted"] = current_turn
	var first_loop = true
	var starting_player = play_order_i
	while region_amount[current_playing_align - 1] == 0 or first_loop:
		play_order_i += 1
		if play_order_i == align_amount - 1:
			play_order_i = 0
			current_turn += 1
		current_playing_align = align_play_order[play_order_i]
		first_loop = false
		if play_order_i == starting_player:
#			victory(current_playing_align)
			break
	check_victory()
	
	var placement = String.num(current_placement)
	
	for i in range(region_amount.size()):
		if region_amount[i] != last_turn_region_amount[i] and region_amount[i] == 0: 
			GameStats.set_stat(i + 1, "placement", placement)
#			GameStats.stats[i + 1]["placement"] = placement
			current_placement -= 1
	
	last_turn_region_amount = region_amount.duplicate()
	
	reset()
	
	turn_ended.emit()
	
	if record:
		ReplayControl.call_deferred("record_move", ReplayControl.RECORD_TYPE_FUNCTION, "turn_end")
#		ReplayControl.record_move(ReplayControl.RECORD_TYPE_FUNCTION, "turn_end")


func check_victory():
	var aliance = null
	for i in range(region_amount.size()):
		if region_amount[i] > 0:
			if aliance == null:
				aliance = alignment_aliances[i + 1]
			elif aliance != alignment_aliances[i + 1]:
				return
	victory(current_playing_align)


func victory(align_victory : int):
	dummy = true
	game_camera.win(align_victory)
	GameStats.set_stat(align_victory, "placement", "1")
#	GameStats.stats[align_victory]["placement"] = "1"
	if use_aliances:
		for i in range(align_amount - 1):
			if alignment_aliances[i + 1] == alignment_aliances[align_victory]:
				GameStats.set_stat(i + 1, "placement", "1")
#				GameStats.stats[i + 1]["placement"] = "1"
	
	var placement = String.num(current_placement)
	
	for i in range(align_amount - 1):
		if GameStats.get_stat(i + 1, "placement") == "N/A": #stats[i + 1]["placement"]
			GameStats.set_stat(i + 1, "placement", placement)
#			GameStats.stats[i + 1]["placement"] = placement
	
	game_ended.emit(align_victory)


func reset():
	
	if region_amount[current_playing_align - 1] > GameStats.get_stat(current_playing_align, "most regions owned"): #GameStats.stats[current_playing_align]["most regions owned"]
		GameStats.set_stat(current_playing_align, "most regions owned", region_amount[current_playing_align - 1])
#		GameStats.stats[current_playing_align]["most regions owned"] = region_amount[current_playing_align - 1]
	if capital_amount[current_playing_align - 1] > GameStats.get_stat(current_playing_align, "most capitals owned"): #GameStats.stats[current_playing_align]["most capitals owned"]
		GameStats.set_stat(current_playing_align, "most capitals owned", capital_amount[current_playing_align - 1])
#		GameStats.stats[current_playing_align]["most capitals owned"] = capital_amount[current_playing_align - 1]
	calculate_penalty(current_playing_align)
	action_amount = capital_amount[current_playing_align - 1] - penalty_amount[current_playing_align - 1]
	bonus_action_amount = 1 if action_amount == 0 else 0
	current_action = ACTION_MOBILIZE if action_amount == 0 else ACTION_NORMAL
	
	var bg_color_tinted : Color = bg_color + align_color[current_playing_align] * Color(0.25, 0.25, 0.25)
	if MapSetup.speedrun_ai:
		if align_controlers[current_playing_align - 1] == AIControler.CONTROLER_USER:
			color = bg_color_tinted
		else:
			color = bg_color
	else:
		color = bg_color_tinted
	
	if ReplayControl.replay_active:
		is_player_controled = false
	else:
		is_player_controled = align_controlers[current_playing_align - 1] == AIControler.CONTROLER_USER
	
	if !is_player_controled:
		game_control.ai_control.start_turn(current_playing_align, align_controlers[current_playing_align - 1])


func calculate_penalty(alignment : int, end_of_turn : bool = false):
	if apply_penalties == APPLY_PENALTIES.OFF:
		return
	if apply_penalties == APPLY_PENALTIES.PREVIOUS_CAPITAL and not end_of_turn:
		return
	if power_gain_penalties.size() == 0:
		return
	
	var capitals : int = capital_amount[alignment - 1]
	
	var penalty : float = 0.0
	for i in power_gain_penalties.keys():
		if capitals <= i:
			break
		penalty += float(capitals - i) * power_gain_penalties[i]
	var penalty_total = int(penalty)
#	print(penalty_total)
	
	penalty_amount[alignment - 1] = penalty_total


func forfeit():
	convert_alignment(current_playing_align, 0)
	
	turn_end(false)
	
	ReplayControl.record_move(ReplayControl.RECORD_TYPE_FUNCTION, "forfeit")


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


func alignment_neutral(align) -> bool:
	return align == 0 or align >= align_amount
