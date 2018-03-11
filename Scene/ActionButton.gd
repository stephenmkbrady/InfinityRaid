extends TextureButton

signal action_pressed

var timer
var snd_select_action

var mouse_cursor

func _ready():
	snd_select_action = get_tree().get_root().get_node("Node2D/audio/select_action")
	
	mouse_cursor = load("res://Assets/mouse.png")
	var game_state = get_tree().get_root().get_node("/root/GameState")
	game_state.connect("Computer_1_placed",self,"_on_action_placed")
	game_state.connect("Computer_2_placed",self,"_on_action_placed")
	game_state.connect("Server_placed",self,"_on_action_placed")
	game_state.connect("High_placed",self,"_on_action_placed")
	game_state.connect("Medium_placed",self,"_on_action_placed")
	game_state.connect("Low_placed",self,"_on_action_placed")
# make action 5 - 8 buttons grey and disabled
	timer = get_tree().get_root().get_node("Node2D/Power_Timer")
	if self.name == "Low" or self.name == "High" or self.name == "Medium":
		self.set_disabled(true)
		if self.name == "High" or self.name == "Medium":
			self.set_visible(false)
		
func _pressed():
	self.set_disabled(true)
	snd_select_action.play()
	var tex
	if self.get_name() == "Computer_1":
		tex = load("res://Assets/hex_computer_1_mouse.png")
	elif self.get_name() == "Computer_2":
		tex = load("res://Assets/hex_computer_2_mouse.png")
	elif self.get_name() == "Server":
		tex = load("res://Assets/hex_server_mouse.png")
	else:
		tex = mouse_cursor
	Input.set_custom_mouse_cursor(tex)
	
	
	emit_signal("action_pressed", self.get_name())

func _process(delta):
# monitor timer
	var t = int(timer.time_left)
	if t == GameState.power_time / 3:
		if self.get_name() == "High":
			self.set_disabled(false)
			self.set_visible(true)
		elif self.get_name() == "Medium":
			self.set_disabled(true)
			self.set_visible(false)
		elif self.get_name() == "Low":
			self.set_disabled(true)
			self.set_visible(false)
	if t == GameState.power_time / 2:
		if self.get_name() == "High":
			self.set_disabled(true)
			self.set_visible(false)
		elif self.get_name() == "Medium":
			self.set_disabled(false)
			self.set_visible(true)
		elif self.get_name() == "Low":
			self.set_disabled(true)
			self.set_visible(false)
	if t == GameState.power_time - 10 :
		if self.get_name() == "High":
			self.set_disabled(true)
			self.set_visible(false)
		elif self.get_name() == "Medium":
			self.set_disabled(true)
			self.set_visible(false)
		elif self.get_name() == "Low":
			self.set_disabled(false)
			self.set_visible(true)

# If timer is stopped:
	if timer.is_stopped():
		if self.name == "Low" or self.name == "High" or self.name == "Medium":
			self.set_disabled(true)
			if self.name == "High" or self.name == "Medium":
				self.set_visible(false)
			elif self.name == "Low":
				self.set_visible(true)
			
func _on_action_placed( ):
	Input.set_custom_mouse_cursor(mouse_cursor)
