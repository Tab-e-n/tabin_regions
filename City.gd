extends TextureButton
class_name City

@export var is_capital : bool = false

@onready var region : Region = get_parent()

var text : Label = Label.new()
var region_name : Label = Label.new()

func _ready():
	if is_capital:
		texture_normal = preload("res://capital.png")
	else:
		texture_normal = preload("res://city.png")
	z_index = 20
	position = Vector2(-32, -32)
	
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.size = Vector2(64, 64)
	add_child(text)
	
	region_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	region_name.size = Vector2(256, 32)
	region_name.position = Vector2(-96, -32)
	region_name.text = region.name + " (" + String.num(region.max_power) + ")"
	region_name.visible = false
	region_name.z_index = 1
	add_child(region_name)

func _process(delta):
	text.text = String.num(region.power)
	if !region.region_control.dummy:
		region_name.visible = is_hovered()

func make_particle(mobilize : bool):
	var part : Sprite2D = Sprite2D.new()
	part.texture = preload("res://circle.png")
	part.set_script(preload("res://CitySelectedParticle.gd"))
	part.position = Vector2(32, 32)
	part.modulate = self_modulate
	part.mobilize = mobilize
	add_child(part) 
