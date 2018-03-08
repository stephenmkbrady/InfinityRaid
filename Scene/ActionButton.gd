extends TextureButton

signal action_pressed

var turn_time = 30
var timer

func _ready():
	var game_state = get_tree().get_root().get_node("/root/GameState")
	game_state.connect("computer_1_placed",self,"_on_computer_1_placed")
	game_state.connect("computer_2_placed",self,"_on_computer_2_placed")
	game_state.connect("server_placed",self,"_on_server_placed")
# make action 5 - 8 buttons grey and disabled
	timer = get_parent().get_node("Power_Timer")
	if self.name == "Low" or self.name == "High" or self.name == "Medium":
		self.set_disabled(true)
		if self.name == "High" or self.name == "Medium":
			self.set_visible(false)
		
func _pressed():
	emit_signal("action_pressed", self.get_name())

func _process(delta):
# monitor timer
	var t = int(timer.time_left)
	if t == turn_time / 3:
		print("turn_time/3")
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
		print("turn_time/3")
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
		print("turn_time-10")
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
	if self.get_position_in_parent() == 2:
		self.set_disabled(true)

func _on_computer_2_placed( ):
	if self.get_position_in_parent() == 3:
		self.set_disabled(true)

func _on_server_placed():
	if self.get_position_in_parent() == 4:
		self.set_disabled(true)