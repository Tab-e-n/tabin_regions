extends TextureButton


@export_multiline var text : String = """default text"""

@onready var label : Label = $text
@onready var anim : AnimationPlayer = $anim


func _ready():
	label.text = text


func _on_toggled(pressed):
	if pressed:
		anim.play("appear")
	else:
		anim.play("disappear")
