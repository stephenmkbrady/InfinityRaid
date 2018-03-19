extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func set_active_effects( ):
	
	for e in get_children():
		e.set_visible(false)
		
	var i = 0
	for e in GameState.active_effects:
		get_node(str(i)).set_visible(true)
		get_node(str(i)).get_node("image").set_texture(load(e["card"]["image"]))
		i = i + 1
