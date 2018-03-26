extends PathFollow2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	hide()

func _process(delta):
	if get_parent().get_name() == "Path2D":
		set_offset(get_offset() + 20*delta)
	elif get_parent().get_name() == "Path2D2":
		set_offset(get_offset() + 500*delta)
	
	if GameState.score >= GameState.max_score_val:
		if get_parent().get_name() == "Path2D":
			if is_visible_in_tree():
				hide()
		elif get_parent().get_name() == "Path2D2":
			if not is_visible_in_tree():
				show()
	else:
		if get_parent().get_name() == "Path2D":
			if not is_visible_in_tree():
				show()
		elif get_parent().get_name() == "Path2D2":
			if is_visible_in_tree():
				hide()