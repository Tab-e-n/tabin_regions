extends Camera2D
class_name GameCamera

@onready var game_control : GameControl = get_parent()
@onready var window_size : Vector2 = get_viewport_rect().size

var farthest_left : int = 0
var farthest_right : int = 0
var farthest_up : int = 0
var farthest_down : int = 0

var win_timer : float = -1

func _ready():
	game_control.game_camera = self
	call_deferred("_deffered_ready")

func _input(event):
	if event is InputEventKey:
		if event.key_label != KEY_ESCAPE:
			$leave.visible = false

func _deffered_ready():
	for i in game_control.region_control.polygon:
		if i.x > farthest_right:
			farthest_right = i.x
		if i.x < farthest_left:
			farthest_left = i.x
		if i.y > farthest_down:
			farthest_down = i.y
		if i.y < farthest_up:
			farthest_up = i.y
	
	if farthest_right < window_size.x / 2:
		farthest_right = window_size.x / 2
	if farthest_left > -window_size.x / 2:
		farthest_left = -window_size.x / 2
	if farthest_down < window_size.y / 2:
		farthest_down = window_size.y / 2
	if farthest_up > -window_size.y / 2:
		farthest_up = -window_size.y / 2
	
	farthest_right -= window_size.x / 3
	farthest_left += window_size.x / 3
	farthest_down -= window_size.y / 3
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
	
	get_node("AdvanceTurn").pressed.connect(game_control.region_control.change_current_action)
	
	$turn_order.polygon[2].x = 64 * (game_control.region_control.align_amount - 1)
	$turn_order.polygon[3].x = 64 * (game_control.region_control.align_amount - 1)
	
	var play_order : Array = game_control.region_control.player_order.duplicate()
	for i in range(play_order.size()):
		var rep : Polygon2D = Polygon2D.new()
		var polygon : PackedVector2Array = [Vector2(-24, -24),Vector2(-24, 24),Vector2(24, 24),Vector2(24, -24),Vector2(-24, -24)]
		rep.set_polygon(polygon.duplicate())
		rep.position.x = 32 + 64 * i
		rep.color = game_control.region_control.align_color[play_order[i]]
		$turn_order.add_child(rep)

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
	var mouse_position = get_viewport().get_mouse_position()
	if mouse_position.x > window_size.x - 64 and position.x < farthest_right:
		position.x += 8
	if mouse_position.x < 64 and position.x > farthest_left:
		position.x -= 8
	if mouse_position.y > window_size.y - 64 and position.y < farthest_down:
		position.y += 8
	if mouse_position.y < 64 and position.y > farthest_up:
		position.y -= 8
	
	$AdvanceTurn.modulate = game_control.region_control.color
	$Power.self_modulate = game_control.region_control.color
	$AdvanceTurn.modulate.a = 1
	$Power.self_modulate.a = 1
	can_translate_messages()
	if game_control.region_control.current_action == 0:
		$Action.text = "FIRST ACTION"
		$Power/text.text = String.num(game_control.region_control.action_amount)
	if game_control.region_control.current_action == 1:
		$Action.text = "MOBILIZE"
		$Power/text.text = String.num(game_control.region_control.bonus_action_amount)
	if game_control.region_control.current_action == 2:
		$Action.text = "BONUS ACTION"
		$Power/text.text = String.num(game_control.region_control.bonus_action_amount)
	
	$AdvanceTurn.visible = game_control.region_control.is_user_controled

func win(align_victory : int):
	$win.visible = true
	$win.modulate = game_control.region_control.align_color[align_victory]
	win_timer = 5
