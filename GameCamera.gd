extends Camera2D
class_name GameCamera


const PLAY_ORDER_SCREEN_BORDER_GAP : float = 64
const PLAY_ORDER_SPACING : float = 48
const PLAY_ORDER_VERTICAL_OFFSET : float = 44
const PLAY_ORDER_MAX_SIZE : float = 1024
const PREVENT_CAMERA_MOVEMENT_START : float = 1


const ZOOM_OUT_MAX : int = -10
const ZOOM_START : int = 0
const ZOOM_IN_MAX : int = 5
const BASE_MOVE_SPEED : float = 8


@export var UI : Control
@export var UIHideable : Control
@export var PauseMenu : Control
@export var PlayerInfo : Control
@export var AdvanceTurnButton : BaseButton
@export var PauseButton : BaseButton
@export var TurnOrder : Panel
@export var Attacks : RichTextLabel
@export var PowerSprite : TextureRect
@export var PowerAmount : Label
@export var CurrentAction : Label
@export var VictoryMessage : Control
@export var LeaveMessage : Control
@export var CommandCallout : CommandCallouts


@onready var game_control : GameControl = get_parent()
@onready var region_control : RegionControl
@onready var window_size : Vector2 = get_viewport_rect().size

var farthest_left : int = 0
var farthest_right : int = 0
var farthest_up : int = 0
var farthest_down : int = 0

var win_timer : float = -1

var cam_movement_stop : float = PREVENT_CAMERA_MOVEMENT_START


var zoom_level : int = 0
var mouse_wheel_input : int = 0

var hovering_advance_turn : bool = false
var hovering_turn_order : bool = false

var hovered_player : int = -1


func _ready():
	game_control.game_camera = self
	call_deferred("_deffered_ready")
	
	zoom_level = ZOOM_START
	zoom_change(0)


func _input(event):
	if event is InputEventKey:
		if event.key_label != KEY_ESCAPE:
			LeaveMessage.visible = false
	if event is InputEventMouseButton:
		LeaveMessage.visible = false
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				mouse_wheel_input = 1
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				mouse_wheel_input = -1


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
	
	AdvanceTurnButton.pressed.connect(region_control.change_current_action)
	AdvanceTurnButton.mouse_entered.connect(_AdvanceTurnButton_cam_disable)
	AdvanceTurnButton.mouse_exited.connect(_AdvanceTurnButton_cam_enable)
	TurnOrder.mouse_entered.connect(_TurnOrder_cam_disable)
	TurnOrder.mouse_exited.connect(_TurnOrder_cam_enable)
	
	PauseButton.pressed.connect(show_pause_menu)
	
	call_deferred("_ready_play_order")
	
	region_control.turn_ended.connect(update_turn_order)


func _ready_play_order():
	var size : float = PLAY_ORDER_SPACING * (region_control.align_amount - 1)
	TurnOrder.size.x = size
#	print(size)
	if size > PLAY_ORDER_MAX_SIZE:
		TurnOrder.scale.x = PLAY_ORDER_MAX_SIZE / size
		TurnOrder.scale.y = TurnOrder.scale.x
		Attacks.size.x = PLAY_ORDER_MAX_SIZE
	else:
		Attacks.size.x = size
	
	
	var play_order : Array = region_control.player_order.duplicate()
	for i in range(play_order.size()):
		var spr : Sprite2D = Sprite2D.new()
		spr.name = String.num(play_order[i])
		spr.texture = preload("res://Sprites/turn_order_players.png")
		spr.hframes = AIControler.PACKED_CONTROLERS.size()
		spr.frame = region_control.player_controlers[play_order[i] - 1]
		@warning_ignore("integer_division")
		spr.position.x = PLAY_ORDER_SPACING / 2 + PLAY_ORDER_SPACING * i
		spr.position.y = PLAY_ORDER_VERTICAL_OFFSET
		spr.self_modulate = region_control.align_color[play_order[i]]
		TurnOrder.add_child(spr)
		if region_control.aliances_active:
			var label : Label = Label.new()
			label.name = String.num(play_order[i]) + "_txt"
			label.size = Vector2(PLAY_ORDER_SPACING, 48)
			label.clip_text = true
			label.text = String.num_int64(region_control.alignment_aliances[play_order[i]])
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.position.x = -PLAY_ORDER_SPACING * 0.5
			if spr.self_modulate.v > region_control.COLOR_TOO_BRIGHT:
				label.self_modulate = Color(0, 0, 0)
			else:
				label.self_modulate = Color(1, 1, 1)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			spr.add_child(label)


func _physics_process(delta):
	var mouse_position = get_viewport().get_mouse_position()
	var shift = Input.is_action_pressed("shift")
	
	if Input.is_action_just_pressed("escape"):
		if LeaveMessage.visible:
			leave()
		LeaveMessage.visible = true
	if win_timer > 0:
		win_timer -= delta
		if win_timer <= 0:
			leave()
			return
	
	var direction : Vector2 = Vector2(0, 0)
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("down"):
		direction.y += 1
	if Input.is_action_pressed("up"):
		direction.y -= 1
	
	if hovering_advance_turn or hovering_turn_order:
		cam_movement_stop = 1
	
	if cam_movement_stop > 0:
		cam_movement_stop -= 1
	elif MapSetup.mouse_scroll_active:
		if mouse_position.x > window_size.x - 64:
			direction.x += 1
		if mouse_position.x < 64:
			direction.x -= 1
		if mouse_position.y > window_size.y - 64:
			direction.y += 1
		if mouse_position.y < 64:
			direction.y -= 1
		
	var move_speed = BASE_MOVE_SPEED * UI.scale.x
	if shift:
		move_speed *= 2.0
	position += direction * Vector2(move_speed, move_speed)
	
	snapped(position, Vector2(1.0, 1.0))
	if position.x > farthest_right:
		position.x = farthest_right
	if position.x < farthest_left:
		position.x = farthest_left
	if position.y < farthest_up:
		position.y = farthest_up
	if position.y > farthest_down:
		position.y = farthest_down
	
	if Input.is_action_just_pressed("zoom_out") or mouse_wheel_input < 0:
		zoom_change(-1)
	if Input.is_action_just_pressed("zoom_in") or mouse_wheel_input > 0:
		zoom_change(1)
	if Input.is_action_just_pressed("zoom_reset"):
		zoom_level = ZOOM_START
		zoom_change(0)
		CommandCallout.new_callout("Reset zoom")
	
	mouse_wheel_input = 0
	
	if Input.is_action_just_pressed("hide_ui"):
		UIHideable.visible = not UIHideable.visible
		CommandCallout.new_callout("Toggle hide UI")
	
	if Input.is_action_just_pressed("hide_turn_order"):
		toggle_turn_order_visibility()
		CommandCallout.new_callout("Toggle turn order")
	
	if Input.is_action_just_pressed("disable_mouse_scroll"):
		MapSetup.mouse_scroll_active = not MapSetup.mouse_scroll_active
		if MapSetup.mouse_scroll_active:
			CommandCallout.new_callout("Mouse scrolling active")
		else:
			CommandCallout.new_callout("Mouse scrolling disabled")
	
	AdvanceTurnButton.modulate = region_control.align_color[region_control.current_player]
	PowerSprite.self_modulate = region_control.align_color[region_control.current_player]
	AdvanceTurnButton.modulate.a = 1
	PowerSprite.self_modulate.a = 1
	if PowerSprite.self_modulate.v > 0.9:
		PowerAmount.self_modulate = Color(0, 0, 0)
	else:
		PowerAmount.self_modulate = Color(1, 1, 1)
	can_translate_messages()
	if region_control.current_action == 0:
		CurrentAction.text = "FIRST ACTION"
		CurrentAction.text = "FIRST ACTION"
		PowerAmount.text = String.num(region_control.action_amount)
	if region_control.current_action == 1:
		CurrentAction.text = "MOBILIZE"
		PowerAmount.text = String.num(region_control.bonus_action_amount)
	if region_control.current_action == 2:
		CurrentAction.text = "BONUS ACTION"
		PowerAmount.text = String.num(region_control.bonus_action_amount)
	
	AdvanceTurnButton.visible = region_control.is_user_controled
	if not region_control.is_user_controled:
		hovering_advance_turn = false
	
	PlayerInfo.visible = hovering_turn_order
	if hovering_turn_order:
		var hovering_over_player : int = (mouse_position.x - PLAY_ORDER_SCREEN_BORDER_GAP) / (PLAY_ORDER_SPACING * TurnOrder.scale.x)
		
		if hovering_over_player >= region_control.align_amount - 1:
			hovering_over_player = region_control.align_amount - 2
		if hovering_over_player < 0:
			hovering_over_player = 0
		
		var new_player : bool = false
		if hovered_player != hovering_over_player:
			hovered_player = hovering_over_player
			new_player = true
		
		var player_alignment : int = region_control.player_order[hovered_player]
		var leader : Sprite2D = TurnOrder.get_node(String.num(player_alignment)) as Sprite2D
		if leader.visible:
			var city_amount : Label = PlayerInfo.get_node("CityAmount") as Label
			var capital_amount : Label = PlayerInfo.get_node("CapitalAmount") as Label
			if new_player:
				var info_leader : Sprite2D = PlayerInfo.get_node("Player") as Sprite2D
				info_leader.self_modulate = leader.self_modulate
				info_leader.frame = leader.frame
				PlayerInfo.get_node("City").self_modulate = leader.self_modulate
				PlayerInfo.get_node("Capital").self_modulate = leader.self_modulate
				if leader.self_modulate.v > region_control.COLOR_TOO_BRIGHT:
					city_amount.self_modulate = Color(0, 0, 0)
					capital_amount.self_modulate = Color(0, 0, 0)
				else:
					city_amount.self_modulate = Color(1, 1, 1)
					capital_amount.self_modulate = Color(1, 1, 1)
				PlayerInfo.get_node("Name").text = region_control.align_names[player_alignment]
			
			city_amount.text = String.num(region_control.region_amount[player_alignment - 1])
			capital_amount.text = String.num(region_control.capital_amount[player_alignment - 1])
			if region_control.penalty_amount[player_alignment - 1] > 0:
				capital_amount.text += "\n-" + String.num(region_control.penalty_amount[player_alignment - 1])
		else:
			PlayerInfo.visible = false


func zoom_change(amount : int):
	zoom_level += amount
	if zoom_level < ZOOM_OUT_MAX:
		zoom_level = ZOOM_OUT_MAX
	if zoom_level > ZOOM_IN_MAX:
		zoom_level = ZOOM_IN_MAX
	zoom.x = pow(1.25, zoom_level)
	zoom.y = zoom.x
	UI.scale.x = 1 / zoom.x
	UI.scale.y = UI.scale.x


func update_turn_order():
	var play_order : Array = region_control.player_order.duplicate()
	for i in range(region_control.align_amount - 1):
		var alignment : int = play_order[i]
		var leader = TurnOrder.get_node(String.num(alignment))
		leader.visible = region_control.region_amount[alignment - 1]
		if not leader.visible:
			continue
		
		if TurnOrder.has_node(String.num(alignment) + "_txt"):
			var aliance_text = TurnOrder.get_node(String.num(alignment) + "_txt")
			var aliance = region_control.alignment_aliances[alignment]
			if aliance_text.text != String.num_int64(aliance):
				aliance_text.text = String.num_int64(aliance)
		
		if leader.has_node("sweat"):
			if region_control.capital_amount[alignment - 1] > 0:
				leader.get_node("sweat").queue_free()
		else:
			if region_control.capital_amount[alignment - 1] == 0:
				var new_sweat : Sprite2D = Sprite2D.new()
				new_sweat.texture = preload("res://Sprites/leader_sweat.png")
				new_sweat.position = Vector2(-16, -16)
				new_sweat.name = "sweat"
				leader.add_child(new_sweat)
			


func win(align_victory : int):
	VictoryMessage.visible = true
	VictoryMessage.modulate = region_control.align_color[align_victory]
	win_timer = 5.0


func _AdvanceTurnButton_cam_disable():
	hovering_advance_turn = true


func _AdvanceTurnButton_cam_enable():
	hovering_advance_turn = false


func _TurnOrder_cam_disable():
	hovering_turn_order = true


func _TurnOrder_cam_enable():
	hovering_turn_order = false


func show_pause_menu():
	PauseMenu.visible = not PauseMenu.visible


func toggle_turn_order_visibility():
	TurnOrder.visible = not TurnOrder.visible


func show_attacks(region : Region):
	if not TurnOrder.visible:
		return
	
	var adjanced : Array[int] = region.get_adjacent_attack_power()
	
	var text : String = ""
	var align_amount : int = region_control.align_amount
	
	for alignment in range(adjanced.size()):
		if alignment == 0 or adjanced[alignment] == 0:
			align_amount -= 1
			continue
		var color : Color = region_control.align_color[alignment]
		var text_color : Color = Color(1, 1, 1)
		if color.v > region_control.COLOR_TOO_BRIGHT:
			text_color = Color(0, 0, 0)
		text += "[cell][bgcolor=#" + color.to_html() + "][color=#" + text_color.to_html() + "] "
		text += String.num(adjanced[alignment]) + " [/color][/bgcolor][/cell]"
	
	if align_amount > 0:
		text = "[center][table=" + String.num(align_amount) + "]" + text + "[/table][/center]"
		
		Attacks.clear()
		Attacks.append_text(text)
		Attacks.visible = true


func hide_attacks():
	Attacks.visible = false


func leave():
	get_tree().change_scene_to_file("res://stats.tscn")
