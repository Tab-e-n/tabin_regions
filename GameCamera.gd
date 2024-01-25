extends Camera2D
class_name GameCamera


const PLAY_ORDER_SPACING : int = 48
const PREVENT_CAMERA_MOVEMENT_START : float = 1


@onready var game_control : GameControl = get_parent()
@onready var region_control : RegionControl
@onready var window_size : Vector2 = get_viewport_rect().size

var farthest_left : int = 0
var farthest_right : int = 0
var farthest_up : int = 0
var farthest_down : int = 0

var win_timer : float = -1

var cam_movement_stop : float = PREVENT_CAMERA_MOVEMENT_START

func _ready():
	game_control.game_camera = self
	call_deferred("_deffered_ready")


func _input(event):
	if event is InputEventKey:
		if event.key_label != KEY_ESCAPE:
			$leave.visible = false
	if event is InputEventMouseButton:
		$leave.visible = false


func _deffered_ready():
	region_control = game_control.region_control
	
	for i in region_control.polygon:
		if i.x > farthest_right:
			@warning_ignore("narrowing_conversion")
			farthest_right = i.x
		if i.x < farthest_left:
			@warning_ignore("narrowing_conversion")
			farthest_left = i.x
		if i.y > farthest_down:
			@warning_ignore("narrowing_conversion")
			farthest_down = i.y
		if i.y < farthest_up:
			@warning_ignore("narrowing_conversion")
			farthest_up = i.y
	
	if farthest_right < window_size.x / 2:
		@warning_ignore("narrowing_conversion")
		farthest_right = window_size.x / 2
	if farthest_left > -window_size.x / 2:
		@warning_ignore("narrowing_conversion")
		farthest_left = -window_size.x / 2
	if farthest_down < window_size.y / 2:
		@warning_ignore("narrowing_conversion")
		farthest_down = window_size.y / 2
	if farthest_up > -window_size.y / 2:
		@warning_ignore("narrowing_conversion")
		farthest_up = -window_size.y / 2
	
	@warning_ignore("narrowing_conversion")
	farthest_right -= window_size.x / 3
	@warning_ignore("narrowing_conversion")
	farthest_left += window_size.x / 3
	@warning_ignore("narrowing_conversion")
	farthest_down -= window_size.y / 3 - 64
	@warning_ignore("narrowing_conversion")
	farthest_up += window_size.y / 3
#	print(farthest_right, " ",farthest_left, " ",farthest_down, " ",farthest_up,)
	
	if position.x > farthest_right:
		position.x = farthest_right
	if position.x < farthest_left:
		position.x = farthest_left
	if position.y > farthest_down:
		position.y = farthest_down
	if position.y < farthest_up:
		position.y = farthest_up
	
	get_node("AdvanceTurn").pressed.connect(region_control.change_current_action)
	
	call_deferred("_ready_play_order")
	
	region_control.turn_ended.connect(update_turn_order)


func _ready_play_order():
	$turn_order.polygon[2].x = PLAY_ORDER_SPACING * (region_control.align_amount - 1)
	$turn_order.polygon[3].x = PLAY_ORDER_SPACING * (region_control.align_amount - 1)
	
	var play_order : Array = region_control.player_order.duplicate()
	for i in range(play_order.size()):
		var spr : Sprite2D = Sprite2D.new()
		spr.name = String.num(play_order[i])
		spr.texture = preload("res://turn_order_players.png")
		spr.hframes = 6
		spr.frame = region_control.player_controlers[play_order[i] - 1]
		@warning_ignore("integer_division")
		spr.position.x = PLAY_ORDER_SPACING / 2 + PLAY_ORDER_SPACING * i
		spr.self_modulate = region_control.align_color[play_order[i]]
		$turn_order.add_child(spr)
		if region_control.aliances_active:
			var label : Label = Label.new()
			label.name = String.num(play_order[i]) + "_txt"
			label.size = Vector2(PLAY_ORDER_SPACING, 48)
			label.clip_text = true
			label.text = String.num_int64(region_control.alignment_aliances[play_order[i]])
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			@warning_ignore("integer_division")
			label.position.x = -PLAY_ORDER_SPACING / 2
			if spr.self_modulate.v > region_control.COLOR_TOO_BRIGHT:
				label.self_modulate = Color(0, 0, 0)
			else:
				label.self_modulate = Color(1, 1, 1)
			spr.add_child(label)


func _physics_process(delta):
	if Input.is_action_just_pressed("escape"):
		if $leave.visible:
			get_tree().change_scene_to_file("res://stats.tscn")
		$leave.visible = true
	if win_timer > 0:
		win_timer -= delta
		if win_timer <= 0:
			get_tree().change_scene_to_file("res://stats.tscn")
			return
	
	if cam_movement_stop > 0:
		cam_movement_stop -= 1
	else:
		var mouse_position = get_viewport().get_mouse_position()
		if (mouse_position.x > window_size.x - 64 or Input.is_action_pressed("right")) and position.x < farthest_right:
			position.x += 8
		if (mouse_position.x < 64 or Input.is_action_pressed("left")) and position.x > farthest_left:
			position.x -= 8
		if (mouse_position.y > window_size.y - 64 or Input.is_action_pressed("down")) and position.y < farthest_down:
			position.y += 8
		if (mouse_position.y < 64 or Input.is_action_pressed("up")) and position.y > farthest_up:
			position.y -= 8
	
	$AdvanceTurn.modulate = region_control.align_color[region_control.current_player]
	$Power.self_modulate = region_control.align_color[region_control.current_player]
	$AdvanceTurn.modulate.a = 1
	$Power.self_modulate.a = 1
	if $Power.self_modulate.v > 0.9:
		$Power/text.self_modulate = Color(0, 0, 0)
	else:
		$Power/text.self_modulate = Color(1, 1, 1)
	can_translate_messages()
	if region_control.current_action == 0:
		$Action.text = "FIRST ACTION"
		$Action.text = "FIRST ACTION"
		$Power/text.text = String.num(region_control.action_amount)
	if region_control.current_action == 1:
		$Action.text = "MOBILIZE"
		$Power/text.text = String.num(region_control.bonus_action_amount)
	if region_control.current_action == 2:
		$Action.text = "BONUS ACTION"
		$Power/text.text = String.num(region_control.bonus_action_amount)
	
	$AdvanceTurn.visible = region_control.is_user_controled


func update_turn_order():
	var play_order : Array = region_control.player_order.duplicate()
	for i in range(region_control.align_amount - 1):
		var leader = $turn_order.get_node(String.num(play_order[i]))
		leader.visible = region_control.region_amount[play_order[i] - 1]
		if $turn_order.has_node(String.num(play_order[i]) + "_txt"):
			var aliance_text = $turn_order.get_node(String.num(play_order[i]) + "_txt")
			var aliance = region_control.alignment_aliances[play_order[i]]
			if aliance_text.text != String.num_int64(aliance):
				aliance_text.text = String.num_int64(aliance)


func win(align_victory : int):
	$win.visible = true
	$win.modulate = region_control.align_color[align_victory]
	win_timer = 5
