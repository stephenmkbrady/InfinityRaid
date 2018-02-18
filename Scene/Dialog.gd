extends Area2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	self.connect("input_event",self,"_on_Area2D_input_event")

func _on_Area2D_input_event(viewport, event, shape_idx):
	if event.action_match(event):
		if event.is_pressed() and event.button_index == BUTTON_LEFT:
			for c in get_tree().get_root().get_node("Node2D/Position2D").get_children():
				if c.get_child(0).has_node("Area2D"):
					c.get_child(0).get_child(0).set_pickable(true)
			get_parent().get_parent().queue_free()