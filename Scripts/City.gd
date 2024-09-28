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
	text.z_index = 1
	text.add_theme_font_size_override("font_size", 16)
	add_child(text)
	
	region_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	region_name.visible = false
	region_name.z_index = 2
	
	region_name.add_theme_font_size_override("font_size", 16)
	region_name.clip_contents = true
	region_name.text = region.name + " (" + String.num(region.max_power) + ")"
	if OS.has_feature("editor"):
		region_name.text += " (" + String.num(region.distance_from_capital) + ")"
	region_name.size = region_name.get_theme_font("font").get_string_size(region_name.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	region_name.position = Vector2(region_name.size.x * -0.5 + 24, -32)
	
	region_name.add_theme_stylebox_override("normal", preload("res://Styles/style_label_city_name.tres"))
	add_child(region_name)


func _process(_delta):
	text.text = String.num(region.power)
	visible = region.region_control.cities_visible
	if !region.region_control.dummy:
		if was_hovered != is_hovered():
			was_hovered = is_hovered()
			if was_hovered:
				show_attacks()
			else:
				hide_attacks()
			region_name.visible = is_hovered()
		
		if Input.is_action_just_pressed("show_extra"):
			if region.power > 1 and region.region_control.current_playing_align == region.alignment:
				make_particle(true)


func make_particle(mobilize : bool):
	var part : Sprite2D = Sprite2D.new()
	part.texture = preload("res://Sprites/circle.png")
	part.set_script(preload("res://Scripts/CitySelectedParticle.gd"))
	part.position = Vector2(32, 32)
	part.modulate = self_modulate
	part.mobilize = mobilize
	add_child(part) 


func color_self(new_color : Color):
	self_modulate = new_color
	if new_color.v > region.region_control.COLOR_TOO_BRIGHT:
		text.self_modulate = Color(0, 0, 0)
#		region_name.self_modulate = Color(0, 0, 0)
#		region_name.remove_theme_color_override("font_color")
#		region_name.add_theme_color_override("font_color", Color(0, 0, 0))
#		region_name.remove_theme_color_override("font_outline")
#		region_name.add_theme_color_override("font_outline", Color(1, 1, 1))
	else:
		text.self_modulate = Color(1, 1, 1)
#		region_name.self_modulate = Color(1, 1, 1)
#		region_name.remove_theme_color_override("font_color")
#		region_name.add_theme_color_override("font_color", Color(1, 1, 1))
#		region_name.remove_theme_color_override("font_outline")
#		region_name.add_theme_color_override("font_outline", Color(0, 0, 0))
		


func show_attacks():
	if !region.region_control.dummy:
		region.region_control.game_camera.call_deferred("show_attacks", region)


func hide_attacks():
	if !region.region_control.dummy:
		region.region_control.game_camera.hide_attacks()
