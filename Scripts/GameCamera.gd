extends Camera2D
class_name GameCamera


const PREVENT_CAMERA_MOVEMENT_START : float = 1


const ZOOM_OUT_MAX : int = -10
const ZOOM_START : int = 0
const ZOOM_IN_MAX : int = 5
const BASE_MOVE_SPEED : float = 8


@export var UI : Control
@export var UIHideable : Control
@export var PauseMenu : Control
@export var PlayerInfo : Control
@export var PlayerActions : Control
@export var AdvanceTurnButton : BaseButton
@export var EndTurnButton : BaseButton
@export var ForfeitButton : BaseButton
@export var PauseButton : BaseButton
@export var TurnOrder : AlignmentList
@export var Attacks : RichTextLabel
@export var PowerSprite : TextureRect
@export var PowerAmount : Label
@export var CurrentTurn : Label
@export var CurrentAction : Label
@export var VictoryMessage : Control
@export var DefeatMessage : Control
@export var LeaveMessage : Control
@export var ForfeitMessage : Control
@export var CommandCallout : CommandCallouts

@onready var game_control : GameControl = get_parent()
@onready var region_control : RegionControl
@onready var window_size : Vector2

var farthest_left : int = 0
var farthest_right : int = 0
var farthest_up : int = 0
var farthest_down : int = 0

var cam_movement_stop : float = PREVENT_CAMERA_MOVEMENT_START
var next_position : Vector2 = position

var zoom_level : int = 0

var hovering_advance_turn : bool = false
var hovering_turn_order : bool = false

var hovered_player : int = -1


func _ready():
	z_index = 100
	window_size.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	window_size.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	
	game_control.game_camera = self
	game_control.command_callout = CommandCallout
	call_deferred("_deffered_ready")
	
	zoom_level = ZOOM_START
	zoom_change(0)


func _deffered_ready():
	region_control = game_control.region_control as RegionControl
	
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
	farthest_right += region_control.offset.x
	@warning_ignore("narrowing_conversion")
	farthest_left += region_control.offset.x
	@warning_ignore("narrowing_conversion")
	farthest_down += region_control.offset.y
	@warning_ignore("narrowing_conversion")
	farthest_up += region_control.offset.y
	
#	print(farthest_right, " ",farthest_left, " ",farthest_down, " ",farthest_up,)
	
	if position.x > farthest_right:
		position.x = farthest_right
	if position.x < farthest_left:
		position.x = farthest_left
	if position.y > farthest_down:
		position.y = farthest_down
	if position.y < farthest_up:
		position.y = farthest_up
	next_position = position
	
	AdvanceTurnButton.pressed.connect(_advance_turn)
	EndTurnButton.pressed.connect(_end_turn)
	ForfeitButton.pressed.connect(_forfeit_show)
	AdvanceTurnButton.mouse_entered.connect(_button_cam_disable)
	AdvanceTurnButton.mouse_exited.connect(_button_cam_enable)
	EndTurnButton.mouse_entered.connect(_button_cam_disable)
	EndTurnButton.mouse_exited.connect(_button_cam_enable)
	ForfeitButton.mouse_entered.connect(_button_cam_disable)
	ForfeitButton.mouse_exited.connect(_button_cam_enable)
	TurnOrder.mouse_entered.connect(_TurnOrder_cam_disable)
	TurnOrder.mouse_exited.connect(_TurnOrder_cam_enable)
	
	PauseButton.pressed.connect(show_pause_menu)
	
	call_deferred("_ready_turn_order")
	
	region_control.turn_ended.connect(_turn_ended)
	
	update_current_turn()


func _ready_turn_order():
	TurnOrder._ready_list(region_control)
	
	if TurnOrder.size.x > AlignmentList.PLAY_ORDER_MAX_SIZE:
		Attacks.size.x = AlignmentList.PLAY_ORDER_MAX_SIZE
	else:
		Attacks.size.x = TurnOrder.size.x


func _physics_process(_delta):
	position = next_position


func _process(_delta):
	if hovering_advance_turn or hovering_turn_order:
		cam_movement_stop = 1
	
	PlayerActions.modulate = region_control.align_color[region_control.current_playing_align]
	PowerSprite.self_modulate = region_control.align_color[region_control.current_playing_align]
	PlayerActions.modulate.a = 1
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
	
	PlayerActions.visible = region_control.is_player_controled and not ReplayControl.replay_active
	if not region_control.is_player_controled:
		hovering_advance_turn = false
	
	PlayerInfo.visible = hovering_turn_order
	if hovering_turn_order:
		var hovering_over_player : int = int((game_control.mouse_position.x - AlignmentList.PLAY_ORDER_SCREEN_BORDER_GAP) / (AlignmentList.PLAY_ORDER_SPACING * TurnOrder.scale.x))
		
		if hovering_over_player >= region_control.align_amount - 1:
			hovering_over_player = region_control.align_amount - 2
		if hovering_over_player < 0:
			hovering_over_player = 0
		
		var new_player : bool = false
		if hovered_player != hovering_over_player:
			hovered_player = hovering_over_player
			new_player = true
		
		var player_alignment : int = region_control.align_play_order[hovered_player]
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


func move_camera(direction : Vector2, shift : bool, ctrl : bool):
	var move_speed = BASE_MOVE_SPEED * UI.scale.x
	if shift:
		move_speed *= 2.0
	if ctrl:
		move_speed *= 0.3
	next_position += direction * Vector2(move_speed, move_speed)
	
	snapped(next_position, Vector2(1.0, 1.0))
	if next_position.x > farthest_right:
		next_position.x = farthest_right
	if next_position.x < farthest_left:
		next_position.x = farthest_left
	if next_position.y < farthest_up:
		next_position.y = farthest_up
	if next_position.y > farthest_down:
		next_position.y = farthest_down


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


func reset_zoom():
	zoom_level = ZOOM_START
	zoom_change(0)


func _advance_turn():
	region_control.change_current_action()


func _end_turn():
	region_control.turn_end(true)


func _forfeit_show():
	ForfeitMessage.visible = true


func _forfeit_hide():
	ForfeitMessage.visible = false


func show_victory_message(alignment : int):
	VictoryMessage.visible = true
	VictoryMessage.modulate = region_control.align_color[alignment]


func show_defeat_message(alignment : int):
	DefeatMessage.visible = true
	DefeatMessage.modulate = region_control.align_color[alignment]


func _forfeit():
	_forfeit_hide()
	region_control.forfeit()


func _button_cam_disable():
	hovering_advance_turn = true


func _button_cam_enable():
	hovering_advance_turn = false


func _TurnOrder_cam_disable():
	hovering_turn_order = true


func _TurnOrder_cam_enable():
	hovering_turn_order = false


func _turn_ended():
	TurnOrder.update_list(region_control)
	
	update_current_turn()


func update_current_turn():
	CurrentTurn.text = "TURN " + str(region_control.current_turn)


func show_pause_menu():
	PauseMenu.visible = not PauseMenu.visible


func toggle_ui_visibility():
	UIHideable.visible = not UIHideable.visible


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


func _leaving():
	LeaveMessage.visible = true


func _not_leaving():
	LeaveMessage.visible = false


func _confirmed_leave():
	game_control.leave()


func center_camera(pos : Vector2):
	next_position = pos
