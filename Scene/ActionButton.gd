extends TextureButton

signal action_pressed

var turn_time = 30
var timer

func _ready():
	get_parent().connect("computer_1_placed",self,"_on_computer_1_placed")
	get_parent().connect("computer_2_placed",self,"_on_computer_2_placed")
	get_parent().connect("server_placed",self,"_on_server_placed")
# make action 5 - 8 buttons grey and disabled
	timer = get_parent().get_node("Power_Timer")
	if self.get_position_in_parent() >= 5 and self.get_position_in_parent() <= 8:
		self.set_disabled(true)

func _pressed():
# emit signal to tell other nodes what has been pressed
	emit_signal("action_pressed", self.get_position_in_parent())

func _process(delta):
# monitor timer
# enable and ungrey over time for buttons 5 - 8
	var t = int(timer.time_left)
	if t <= 1 and self.get_position_in_parent() == 5:
		self.set_disabled(false)
	if t <= turn_time / 3 and self.get_position_in_parent() == 6:
		self.set_disabled(false)
	if t <= turn_time / 2 and self.get_position_in_parent() == 7:
		self.set_disabled(false)
	if t <= turn_time - 10 and self.get_position_in_parent() == 8:
		self.set_disabled(false)
		
# If timer is stopped:
# set disable and grey action buttons 5 - 8 when a 5 - 8 has been placed on the hex
	#
	if timer.is_stopped():
		if self.get_position_in_parent() >= 5 and self.get_position_in_parent() <= 8:
			self.set_disabled(true)

func _on_computer_1_placed( ):
	if self.get_position_in_parent() == 2:
		self.set_disabled(true)

func _on_computer_2_placed( ):
	if self.get_position_in_parent() == 3:
		self.set_disabled(true)

func _on_server_placed():
	if self.get_position_in_parent() == 4:
		self.set_disabled(true)