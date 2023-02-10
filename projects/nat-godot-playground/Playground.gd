extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var current_focus = null
var current_focus_z = NAN

func get_drag_data(position):
	return current_focus

func can_drop_data(position, data):
	return data != null
	
func drop_data(position, data):
	data.rect_position = position

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
