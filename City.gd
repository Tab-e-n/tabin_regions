extends TextureButton
class_name City

@export var is_capital : bool = false

@onready var region : Region = get_parent()

var text : Label = Label.new()
var region_name : Label = Label.new()

var was_hovered : bool = false

func _ready():
	if is_capital:
		texture_normal = preload("res://Sprites/capital.png")
	else:
		texture_normal = preload("res://Sprites/city.png")
	z_index = 20
	var city_size : float = region.region_control.city_size
	position = Vector2(-32 * city_size, -32 * city_size)
	scale = Vector2(city_size, city_size)
	
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.size = Vector2(64, 64)
	add_child(text)
	
	region_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	region_name.size = Vector2(256, 32)
	region_name.position = Vector2(-96, -32)
	region_name.text = region.name + " (" + String.num(region.max_power) + ")"
#	region_name.text = region.name + " (" + String.num(region.distance_from_capital) + ")"
	region_name.visible = false
	region_name.z_index = 1
	add_child(region_name)


func _process(_delta):
	text.text = String.num(region.power)
	if !region.region_control.dummy:
		if was_hovered != is_hovered():
			was_hovered = is_hovered()
			if was_hovered:
				show_attacks()
			else:
				hide_attacks()
			region_name.visible = is_hovered()
		visible = not region.region_control.game_control.cities_visible


func make_particle(mobilize : bool):
	var part : Sprite2D = Sprite2D.new()
	part.texture = preload("res://Sprites/circle.png")
	part.set_script(preload("res://CitySelectedParticle.gd"))
	part.position = Vector2(32, 32)
	part.modulate = self_modulate
	part.mobilize = mobilize
	add_child(part) 


func color_self(new_color : Color):
	self_modulate = new_color
	if new_color.v > region.region_control.COLOR_TOO_BRIGHT:
		text.self_modulate = Color(0, 0, 0)
		region_name.self_modulate = Color(0, 0, 0)
	else:
		text.self_modulate = Color(1, 1, 1)
		region_name.self_modulate = Color(1, 1, 1)
		


func show_attacks():
	if !region.region_control.dummy:
		region.region_control.game_camera.call_deferred("show_attacks", region)


func hide_attacks():
	if !region.region_control.dummy:
		region.region_control.game_camera.hide_attacks()
