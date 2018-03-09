extends TextureButton

signal action_pressed

var turn_time = 30
var timer

var mouse_cursor

func _ready():
	mouse_cursor = load("res://Assets/mouse.png")
	var game_state = get_tree().get_root().get_node("/root/GameState")
	game_state.connect("computer_1_placed",self,"_on_computer_1_placed")
	game_state.connect("computer_2_placed",self,"_on_computer_2_placed")
	game_state.connect("server_placed",self,"_on_server_placed")
	game_state.connect("computer_1_placed",self,"_on_computer_1_placed")
	game_state.connect("computer_2_placed",self,"_on_computer_2_placed")
	game_state.connect("high_placed",self,"_on_high_placed")
	game_state.connect("medium_placed",self,"_on_high_placed")
	game_state.connect("low_placed",self,"_on_high_placed")
# make action 5 - 8 buttons grey and disabled
	timer = get_tree().get_root().get_node("Node2D/Power_Timer")
	if self.name == "Low" or self.name == "High" or self.name == "Medium":
		self.set_disabled(true)
		if self.name == "High" or self.name == "Medium":
			self.set_visible(false)
		
func _pressed():
	self.set_disabled(true)
	var tex
	if self.get_name() == "Computer_1":
		tex = load("res://Assets/hex_computer_1_mouse.png")
	elif self.get_name() == "Computer_2":
		tex = load("res://Assets/hex_computer_2_mouse.png")
	elif self.get_name() == "Server":
		tex = load("res://Assets/hex_server_mouse.png")
	else:
		tex = mouse_cursor
		#tex = load("res://Assets/hex_action_mouse.png")
	Input.set_custom_mouse_cursor(tex)
	
	
	emit_signal("action_pressed", self.get_name())

func _process(delta):
# monitor timer
	var t = int(timer.time_left)
	if t == turn_time / 3:
		if self.get_name() == "High":
			self.set_disabled(false)
			self.set_visible(true)
		elif self.get_name() == "Medium":
			self.set_disabled(true)
			self.set_visible(false)
		elif self.get_name() == "Low":
			self.set_disabled(true)
			self.set_visible(false)
	if t == turn_time / 2:
		if self.get_name() == "High":
			self.set_disabled(true)
			self.set_visible(false)
		elif self.get_name() == "Medium":
			self.set_disabled(false)
			self.set_visible(true)
		elif self.get_name() == "Low":
			self.set_disabled(true)
			self.set_visible(false)
	if t == turn_time - 10 :
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
			
func _on_computer_1_placed( ):
	Input.set_custom_mouse_cursor(mouse_cursor)
func _on_computer_2_placed( ):
	Input.set_custom_mouse_cursor(mouse_cursor)
func _on_server_placed():
	Input.set_custom_mouse_cursor(mouse_cursor)
func _on_high_placed():
	Input.set_custom_mouse_cursor(mouse_cursor)
