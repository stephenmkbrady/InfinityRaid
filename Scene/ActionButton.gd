extends TextureButton

signal action_pressed()

var timer
var snd_select_action
var button_effect 
var mouse_cursor
var ruler_high
var ruler_medium
var ruler_low
var ruler_arrow
var ruler_arrow_min_pos
var ruler_arrow_max_pos
var action_button_height

func _ready():
	snd_select_action = get_tree().get_root().get_node("Node2D/audio/select_action")
	button_effect = load("res://Scene/ActionButtonEffect.tscn")
	mouse_cursor = load("res://Assets/mouse.png")
	ruler_high = get_tree().get_root().get_node("Node2D/ruler_high")
	ruler_medium = get_tree().get_root().get_node("Node2D/ruler_medium")
	ruler_low = get_tree().get_root().get_node("Node2D/ruler_low")
	ruler_arrow = get_tree().get_root().get_node("Node2D/ruler_arrow")
	ruler_arrow_min_pos = ruler_arrow.get_global_transform().get_origin()
	action_button_height = (get_size().y - get_size().y/4) * get_scale().y
	GameState.connect("Computer_1_placed",self,"_on_action_placed")
	GameState.connect("Computer_2_placed",self,"_on_action_placed")
	GameState.connect("Server_placed",self,"_on_action_placed")
	GameState.connect("High_placed",self,"_on_action_placed")
	GameState.connect("Medium_placed",self,"_on_action_placed")
	GameState.connect("Low_placed",self,"_on_action_placed")
	
	timer = get_tree().get_root().get_node("Node2D/Power_Timer")

		
func _pressed():
	timer.stop()
	timer.start()
	ruler_arrow.set_global_transform(Transform2D(0, ruler_arrow_min_pos))
	snd_select_action.play()
	var tex
	if self.get_name() == "Computer_1":
		self.set_disabled(true)
		tex = load("res://Assets/hex_computer_1_mouse.png")
	elif self.get_name() == "Computer_2":
		self.set_disabled(true)
		tex = load("res://Assets/hex_computer_2_mouse.png")
	elif self.get_name() == "Server":
		self.set_disabled(true)
		tex = load("res://Assets/hex_server_mouse.png")
	else:
		tex = mouse_cursor
		
	Input.set_custom_mouse_cursor(tex)
	emit_signal("action_pressed", self.get_name())
	

func _process(delta):
	# Just have one of the buttons process, doesn't matter which
	update_action_buttons(delta)
	update_ruler_arrow(delta)

func update_action_buttons(delta):
	var t = int(timer.time_left)
#	print(str(GameState.power_time), " : ",str(t))
	if t < GameState.power_time / 4 and t >= 0:
		if self.get_name() == "High":
			self.set_disabled(false)
			self.add_child(button_effect.instance())
			self.get_node("effect").set_z_index(5)
			self.get_node("effect").get_node("green").play()
	if t < GameState.power_time / 2 and t > GameState.power_time / 3:
		if self.get_name() == "Medium":
			self.set_disabled(false)
			self.add_child(button_effect.instance())
			self.get_node("effect").set_z_index(5)
			self.get_node("effect").get_node("yellow").play()
	if t < GameState.power_time - 5 and t > GameState.power_time / 2:
		if self.get_name() == "Low":
			self.set_disabled(false)
			self.add_child(button_effect.instance())
			self.get_node("effect").set_z_index(5)
			self.get_node("effect").get_node("red").play()
	if t >= GameState.power_time - 1:
		print(str(GameState.power_time), " : ",str(t))
		if self.get_name() == "High" or self.get_name() == "Medium" or self.get_name() == "Low":
			self.set_disabled(true)

	if GameState.score < (GameState.max_score/4):
		if self.get_name() == "Medium" or self.get_name() == "High":
			self.set_visible(false)
		ruler_low.show()
		ruler_arrow.show()
		ruler_medium.hide()
		ruler_high.hide()
	elif GameState.score >= (GameState.max_score/2):
		if self.get_name() == "Medium":
			self.set_visible(true)
		ruler_medium.show()
	elif GameState.score >= (GameState.max_score - GameState.max_score/4):
		if self.get_name() == "High":
			self.set_visible(true)
		ruler_high.show()

func update_ruler_arrow(delta):
	var t = timer.get_time_left()/10 * get_scale().y
	var a_pos = ruler_arrow.get_global_transform().get_origin()
	if GameState.score < (GameState.max_score/4):
		ruler_arrow_max_pos = ruler_arrow_min_pos - Vector2(0, action_button_height)
	elif GameState.score >= (GameState.max_score/2) and GameState.score < (GameState.max_score - GameState.max_score/4):
		ruler_arrow_max_pos = ruler_arrow_min_pos - Vector2(0, action_button_height * 2)
	elif GameState.score >= (GameState.max_score - GameState.max_score/4):
		ruler_arrow_max_pos = ruler_arrow_min_pos - Vector2(0, action_button_height * 2)
	#print(str(ceil(t)), " : ",str(ruler_arrow.get_global_position()), " : ", str(ruler_arrow_min_pos), " : ",str(ruler_arrow_max_pos))
	if int(a_pos.y) != int(ruler_arrow_max_pos.y):
		if int(a_pos.y) <= int(ruler_arrow_max_pos.y):
			ruler_arrow.set_global_transform(Transform2D(0, (a_pos + Vector2(0, (t*delta) ) ) ))
		elif int(a_pos.y) >= int(ruler_arrow_max_pos.y):
			ruler_arrow.set_global_transform(Transform2D(0, (a_pos - Vector2(0, (t*delta) ) ) ))
func _on_action_placed( ):
	Input.set_custom_mouse_cursor(mouse_cursor)
