extends Panel
class_name AlignmentList


const PLAY_ORDER_SCREEN_BORDER_GAP : float = 64
const PLAY_ORDER_SPACING : float = 48
const PLAY_ORDER_VERTICAL_OFFSET : float = 44
const PLAY_ORDER_MAX_SIZE : float = 1024


func add_leader(pos : int, alignment : int) -> Sprite2D:
	var leader : Sprite2D = Sprite2D.new()
	leader.name = String.num(alignment)
	leader.texture = preload("res://Sprites/turn_order_players.png")
	leader.hframes = AIControler.PACKED_CONTROLERS.size()
	leader.position.x = PLAY_ORDER_SPACING / 2 + PLAY_ORDER_SPACING * pos
	leader.position.y = PLAY_ORDER_VERTICAL_OFFSET
	add_child(leader)
	var new_sweat : Sprite2D = Sprite2D.new()
	new_sweat.texture = preload("res://Sprites/leader_sweat.png")
	new_sweat.position = Vector2(-16, -16)
	new_sweat.name = "sweat"
	new_sweat.visible = false
	leader.add_child(new_sweat)
	return leader


func get_leader(alignment : int) -> Sprite2D:
	return get_node(String.num(alignment))


func remove_leader(alignment : int):
	var leader : Sprite2D = get_leader(alignment)
	remove_child(leader)
	leader.queue_free()


func add_aliance_to_leader(leader : Sprite2D, aliance : int):
	var label : Label = Label.new()
	label.name = leader.name + "_txt"
	label.size = Vector2(PLAY_ORDER_SPACING, 48)
	label.clip_text = true
	label.text = String.num_int64(aliance)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position.x = -PLAY_ORDER_SPACING * 0.5
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leader.add_child(label)


func change_leaders_aliance(leader : Sprite2D, aliance : int):
	if leader.has_node(leader.name + "_txt"):
		var label : Label = leader.get_node(leader.name + "_txt")
		label.text = String.num_int64(aliance)


func remove_aliance_from_leader(leader : Sprite2D):
	if leader.has_node(leader.name + "_txt"):
		var label : Label = leader.get_node(leader.name + "_txt")
		leader.remove_child(label)
		label.queue_free()


func color_leader(leader : Sprite2D, color : Color):
	leader.self_modulate = color
	if leader.has_node(leader.name + "_txt"):
		var label : Label = leader.get_node(leader.name + "_txt")
		if color.v > RegionControl.COLOR_TOO_BRIGHT:
			label.self_modulate = Color(0, 0, 0)
		else:
			label.self_modulate = Color(1, 1, 1)


func leader_sweat(leader : Sprite2D, sweating : bool):
	leader.get_node("sweat").visible = sweating


func set_align_list_size(i : int):
	size.x = PLAY_ORDER_SPACING * i
#	print(size)
	if size.x > PLAY_ORDER_MAX_SIZE:
		scale.x = PLAY_ORDER_MAX_SIZE / size.x
		scale.y = scale.x


func _ready_list(region_control : RegionControl):
	set_align_list_size(region_control.align_play_order.size())
	
	var play_order : Array = region_control.align_play_order.duplicate()
	for i in range(play_order.size()):
		var leader : Sprite2D = add_leader(i, play_order[i])
		leader.frame = region_control.align_controlers[play_order[i] - 1]
		if region_control.use_aliances:
			add_aliance_to_leader(leader, region_control.alignment_aliances[play_order[i]])
		color_leader(leader, region_control.align_color[play_order[i]])


func clear_list():
	for i in get_children():
		remove_child(i)
		i.queue_free()


func update_list(region_control : RegionControl):
	var play_order : Array = region_control.align_play_order.duplicate()
	for i in range(region_control.align_play_order.size()):
		var alignment : int = play_order[i]
		var leader = get_node(String.num(alignment))
		leader.visible = region_control.region_amount[alignment - 1]
		if not leader.visible:
			continue
		
		change_leaders_aliance(leader, region_control.alignment_aliances[alignment])
		
		if region_control.capital_amount[alignment - 1] > 0:
			leader_sweat(leader, false)
		else:
			leader_sweat(leader, true)

