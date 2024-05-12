@tool
extends Polygon2D
class_name Region


const TEXTURE_SIZE : Vector2 = Vector2(1024, 1024)


enum RENDER_MODE {DISABLED, ALIGNMENT, POWER, MAX_POWER, CAPITAL}


@export var alignment : int = 0

@export var power : int = 1
@export var max_power : int = 5

@export var is_capital : bool = false

@export var connections : Dictionary = {}


@onready var region_control : RegionControl = get_parent() as RegionControl


@onready var city : City


var tool_render_mode : int = RENDER_MODE.ALIGNMENT


func _ready():
	if Engine.is_editor_hint():
		return
	
	city = City.new()
	city.is_capital = is_capital
	add_child(city)
	if !region_control.dummy:
		city.pressed.connect(_on_capital_pressed)
		city.mouse_entered.connect(make_region_arrows)
	
	color_self()

func _process(_delta):
	if Engine.is_editor_hint() and region_control:
		tool_render_mode = region_control.render_mode
		match(tool_render_mode):
			RENDER_MODE.DISABLED:
				color = Color(1, 1, 1, 1)
			RENDER_MODE.ALIGNMENT:
				color = region_control.align_color[alignment]
			RENDER_MODE.POWER:
				var c : float = 1.0 - clampf(power, 0, 20) * 0.05
				color =  Color(c, c, c, 1)
			RENDER_MODE.MAX_POWER:
				var c : float = 1.0 - clampf(max_power - 1, 0, 20) * 0.05
				color =  Color(c, c, c, 1)
			RENDER_MODE.CAPITAL:
				if is_capital:
					color = Color(0.9, 1, 0.9, 1)
				else:
					color = Color(0.3, 0.1, 0.1, 1)


func change_alignment(align : int):
	if alignment > 0:
		region_control.region_amount[alignment - 1] -= 1
		if is_capital:
			region_control.capital_amount[alignment - 1] -= 1
	alignment = align
	color_self()
	if alignment > 0:
		region_control.region_amount[alignment - 1] += 1
		if is_capital:
			region_control.capital_amount[alignment - 1] += 1


func color_self():
	color = region_control.align_color[alignment]
	city.color_self(region_control.align_color[alignment])


func _on_capital_pressed():
	if region_control.is_user_controled and !region_control.dummy:
		action_decided()


func action_decided():
	city.call_deferred("make_particle", region_control.current_action == region_control.ACTION_MOBILIZE)
	if region_control.current_action != region_control.ACTION_MOBILIZE:
		if region_control.alignment_friendly(region_control.current_player, alignment):
			if reinforce(region_control.current_player):
				region_control.action_done()
				return
		elif can_attack(region_control.current_player):
			if incoming_attack(region_control.current_player):
				region_control.action_done()
				return
		region_control.cross(position)
	else:
		if region_control.current_player == alignment:
			if mobilize():
				region_control.action_done()
				return
		region_control.cross(position)


func can_attack(attack_align : int) -> bool:
	for region in connections.keys():
		if region_control.get_node(region).alignment == attack_align:
			return true
	return false


func incoming_attack(attack_align : int, attack_power : int = 0, test_only : bool = false):
	for region in connections.keys():
		if region_control.get_node(region).alignment == attack_align:
			attack_power += max(region_control.get_node(region).power - connections[region], 0)
	if attack_power > power:
		if test_only:
			return true
		GameStats.add_to_stat(attack_align, "enemy units removed", power)
		GameStats.add_to_stat(alignment, "units lost", power)
#		GameStats.stats[attack_align]["enemy units removed"] += power
#		GameStats.stats[alignment]["units lost"] += power
		power = 1
		change_alignment(attack_align)
		GameStats.add_to_stat(attack_align, "regions captured", 1)
#		GameStats.stats[alignment]["regions captured"] += 1
		if is_capital:
			GameStats.add_to_stat(attack_align, "capital regions captured", 1)
#			GameStats.stats[alignment]["capital regions captured"] += 1
		return true
	else:
		return false


func attack_power_difference(attack_align : int):
	var attack_power = 0
	for region in connections.keys():
		if region_control.get_node(region).alignment == attack_align:
			attack_power += max(region_control.get_node(region).power - connections[region], 0)
	return power - attack_power


func reinforce(reinforce_align : int = alignment, addon_power : int = 1):
	if power == max_power:
		return false
	power += addon_power
	GameStats.add_to_stat(reinforce_align, "regions reinforced", 1)
#	GameStats.stats[reinforce_align]["regions reinforced"] += 1
	return true


func mobilize(mobilize_align : int = alignment):
	if power <= 1:
		return false
	GameStats.add_to_stat(mobilize_align, "units mobilized", 1)
#	GameStats.stats[mobilize_align]["units mobilized"] += 1
	power -= 1
	region_control.bonus_action_amount += 1
	return true


func make_region_arrows():
	var i : int = 0
	for target in connections.keys():
		if region_control.has_node(target):
			var arrow : RegionArrow = RegionArrow.new()
			var target_node = region_control.get_node(target)
			arrow.from_position = position
			arrow.to_position = target_node.position
			arrow.from_color = region_control.align_color[alignment]
			arrow.to_color = region_control.align_color[target_node.alignment]
			arrow.to_name = target
			arrow.num = i
			if connections[target] > 0:
				arrow.darken = true
			region_control.add_child(arrow)
			i += 1
