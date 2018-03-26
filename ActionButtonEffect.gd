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


func _on_yellow_animation_finished():
	self.queue_free()


func _on_red_animation_finished():
	self.queue_free()


func _on_green_animation_finished():
	self.queue_free()
