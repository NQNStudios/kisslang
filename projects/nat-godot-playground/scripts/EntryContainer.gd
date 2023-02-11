extends PanelContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var z = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_EntryContainer_mouse_entered():
	var current_focus_z = get_parent().current_focus_z
	if is_nan(current_focus_z) or current_focus_z <= self.z:
		get_parent().current_focus = self
		get_parent().current_focus_z = self.z

func _on_EntryContainer_mouse_exited():
	if get_parent().current_focus == self:
		get_parent().current_focus = null
		get_parent().current_focus_z = NAN
