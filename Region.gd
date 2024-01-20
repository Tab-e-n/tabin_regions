extends Polygon2D
class_name Region

@export var alignment : int = 0

@export var power : int = 1
@export var max_power : int = 5

@export var is_capital : bool = false

@export var connections : Dictionary = {}

@onready var region_control : RegionControl = get_parent()

var city : City = City.new()

func _ready():
	city.is_capital = is_capital
	add_child(city)
	if !region_control.dummy:
		city.pressed.connect(_on_capital_pressed)
		city.mouse_entered.connect(make_region_arrows)
	
	color_self()

func _process(_delta):
	pass

func color_self():
	color = region_control.align_color[alignment]
	city.color_self(region_control.align_color[alignment])

func _on_capital_pressed():
	if region_control.is_user_controled:
		action_decided()

func action_decided():
	city.call_deferred("make_particle", region_control.current_action == region_control.ACTION_MOBILIZE)
	if region_control.current_action != region_control.ACTION_MOBILIZE:
		if region_control.current_player == alignment:
			if reinforce():
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
	

func can_attack(attack_align : int):
	var can : bool = false
	for region in connections.keys():
		if region_control.get_node(region).alignment == attack_align:
			can = true
			break
	return can

func incoming_attack(attack_align : int, attack_power : int = 0, test_only : bool = false):
	for region in connections.keys():
		if region_control.get_node(region).alignment == attack_align:
			attack_power += max(region_control.get_node(region).power - connections[region], 0)
	if attack_power > power:
		if test_only:
			return true
		GameStats.stats[attack_align]["enemy units removed"] += power
		GameStats.stats[alignment]["units lost"] += power
		power = 1
		if alignment != 0:
			region_control.region_amount[alignment - 1] -= 1
			if is_capital:
				region_control.capital_amount[alignment - 1] -= 1
		alignment = attack_align
		GameStats.stats[alignment]["regions captured"] += 1
		region_control.region_amount[alignment - 1] += 1
		if is_capital:
			GameStats.stats[alignment]["capital regions captured"] += 1
			region_control.capital_amount[alignment - 1] += 1
		color_self()
		return true
	else:
		return false

func attack_power_difference(attack_align : int):
	var attack_power = 0
	for region in connections.keys():
		if region_control.get_node(region).alignment == attack_align:
			attack_power += max(region_control.get_node(region).power - connections[region], 0)
	return power - attack_power

func reinforce(addon_power : int = 1):
	power += addon_power
	if power > max_power:
		power = max_power
		return false
	GameStats.stats[alignment]["regions reinforced"] += 1
	return true

func mobilize():
	if power > 1:
		GameStats.stats[alignment]["units mobilized"] += 1
		power -= 1
		region_control.bonus_action_amount += 1
		return true
	return false
	

func make_region_arrows():
	for target in connections.keys():
		if region_control.has_node(target):
			var arrow : RegionArrow = RegionArrow.new()
			var target_node = region_control.get_node(target)
			arrow.from_position = position
			arrow.to_position = target_node.position
			arrow.from_color = region_control.align_color[alignment]
			arrow.to_color = region_control.align_color[target_node.alignment]
			arrow.to_name = target
			region_control.add_child(arrow)
