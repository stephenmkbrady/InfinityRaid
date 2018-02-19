extends Area2D

signal computer_1_placed
signal computer_2_placed
signal server_placed
signal high_placed
signal medium_placed
signal low_placed
signal special_placed

signal hex_attack_changed
signal hex_defense_changed
signal hex_card_changed
signal hex_owner_changed

var action
var attack_indicator_array
var green_indicator
var yellow_indicator
var red_indicator
var timer
var card = null

var hex_owner
var hex_defense = 1
var hex_attack = 1
var hex_card = null

func _ready():
	# Subscribe all hex instances to the action buttons
	self.get_tree().get_root().get_node("Node2D/Computer_1").connect("action_pressed",self,"_on_computer_1_pressed")
	self.get_tree().get_root().get_node("Node2D/Computer_2").connect("action_pressed",self,"_on_computer_2_pressed")
	self.get_tree().get_root().get_node("Node2D/Server").connect("action_pressed",self,"_on_server_pressed")
	self.get_tree().get_root().get_node("Node2D/High").connect("action_pressed",self,"_on_high_pressed")
	self.get_tree().get_root().get_node("Node2D/Medium").connect("action_pressed",self,"_on_medium_pressed")
	self.get_tree().get_root().get_node("Node2D/Low").connect("action_pressed",self,"_on_low_pressed")
	self.get_tree().get_root().get_node("Node2D/Special").connect("action_pressed",self,"_on_special_pressed")
	# Subscribe to root node to know when another hex instance has fired hex_selected
	self.get_tree().get_root().get_node("Node2D").connect("action_placed",self,"_on_action_placed")
	self.get_tree().get_root().get_node("Node2D").connect("computer_1_placed",self,"_on_computer_1_placed")
	self.get_tree().get_root().get_node("Node2D").connect("computer_2_placed",self,"_on_computer_2_placed")
	self.get_tree().get_root().get_node("Node2D").connect("server_placed",self,"_on_server_placed")
	self.get_tree().get_root().get_node("Node2D").connect("action_placed", self, "_on_high_placed")
	self.get_tree().get_root().get_node("Node2D").connect("high_placed", self, "_on_high_placed")
	self.get_tree().get_root().get_node("Node2D").connect("medium_placed", self, "_on_medium_placed")
	self.get_tree().get_root().get_node("Node2D").connect("low_placed", self, "_on_low_placed")
	self.get_tree().get_root().get_node("Node2D").connect("special_placed", self, "_on_special_placed")
	# Subscribe to GameState to find out 
	self.get_tree().get_root().get_node("/root/GameState").connect("card_drawn", self, "_on_card_drawn")
	self.connect("input_event",self,"_on_Area2D_input_event")
	
	self.connect("hex_attack_changed",self,"_on_hex_attack_changed")
	self.connect("hex_defense_changed",self,"_on_hex_defense_changed")
	self.connect("hex_card_changed",self,"_on_hex_card_changed")
	
	#Preload the strength indicators/ the gems for the tiles with actions/programs in them
	green_indicator = load("res://Scene/Gem.tscn").instance()
	yellow_indicator = load("res://Scene/Gem.tscn").instance()
	red_indicator = load("res://Scene/Gem.tscn").instance()
	yellow_indicator.get_child(0).set_texture(load("res://Assets/hex_gem_yellow_simple.png"))
	red_indicator.get_child(0).set_texture(load("res://Assets/hex_gem_red_simple.png"))
	attack_indicator_array = [red_indicator, yellow_indicator, green_indicator]
	
func _on_Area2D_input_event( viewport, event, shape_idx ):
	if event.action_match(event):
		if event.is_pressed() and event.button_index == BUTTON_LEFT:
			#print(self.get_parent().get_parent().get_position_in_parent())
			get_tree().get_root().get_node("Node2D/InfoText").set_bbcode("")
			# TODO: Only allow placement if player_name == hex_owner
			if self.hex_owner == GameState.player_name:
				if action == 2:
					self.get_parent().set_texture(load("res://Assets/hex_computer_1.png"))
					self.set_hex_card(GameState.computer_1_card)
					print("EWW ",hex_card)
					print("SDSD ",hex_attack)
					update_hex()
					emit_signal("computer_1_placed", self.get_parent().get_parent().get_position_in_parent())
				elif action == 3:
					self.get_parent().set_texture(load("res://Assets/hex_computer_2.png"))
					set_hex_card( GameState.computer_2_card)
					update_hex()
					emit_signal("computer_2_placed", self.get_parent().get_parent().get_position_in_parent())
					
				elif action == 4:
					self.get_parent().set_texture(load("res://Assets/hex_server.png"))
					set_hex_card( GameState.server_card)
					update_hex()
					emit_signal("server_placed", self.get_parent().get_parent().get_position_in_parent())
			
				if card != null and card.has("type") and card["type"] == "computer":
					if action == 5:
						self.add_child(attack_indicator_array[int(card["attack"]) - 1])
						self.get_parent().set_texture(load("res://Assets/hex_green.png"))
						update_hex()
						emit_signal("high_placed", self.get_parent().get_parent().get_position_in_parent())
					elif action == 6:
						self.add_child(attack_indicator_array[int(card["attack"]) - 1])
						self.get_parent().set_texture(load("res://Assets/hex_gold.png"))
						update_hex()
						emit_signal("medium_placed", self.get_parent().get_parent().get_position_in_parent())
					elif action == 7:
						self.add_child(attack_indicator_array[int(card["attack"]) - 1])
						self.get_parent().set_texture(load("res://Assets/hex_red.png"))
						update_hex()
						emit_signal("low_placed", self.get_parent().get_parent().get_position_in_parent())
					elif action == 8:
						self.add_child(attack_indicator_array[int(card["attack"]) - 1])
						self.get_parent().set_texture(load("res://Assets/hex_blue.png"))
						update_hex()
						emit_signal("special_placed", self.get_parent().get_parent().get_position_in_parent())
				# Daemons don't have attacks, just effects
				if card != null and card.has("type") and card["type"] == "daemon":
					if action == 5:
						self.get_parent().set_texture(load("res://Assets/hex_green.png"))
						update_hex()
						emit_signal("high_placed", self.get_parent().get_parent().get_position_in_parent())
					elif action == 6:
						self.get_parent().set_texture(load("res://Assets/hex_gold.png"))
						update_hex()
						emit_signal("medium_placed", self.get_parent().get_parent().get_position_in_parent())
					elif action == 7:
						self.get_parent().set_texture(load("res://Assets/hex_red.png"))
						update_hex()
						emit_signal("low_placed", self.get_parent().get_parent().get_position_in_parent())
					elif action == 8:
						self.get_parent().set_texture(load("res://Assets/hex_blue.png"))
						update_hex()
						emit_signal("special_placed", self.get_parent().get_parent().get_position_in_parent())
				if action == null:
					pass
			else:
				get_tree().get_root().get_node("Node2D/InfoText").set_bbcode("[center]You can only place programs in computers you own[/center]")


func _on_card_drawn(arg):
	card = arg
func set_hex_owner( name ):
	hex_owner = name
	emit_signal("hex_owner_changed")
func set_hex_attack( value ):
	hex_attack = value
	emit_signal("hex_attack_changed")
func set_hex_defence( value ):
	hex_defense = value
	emit_signal("hex_defense_change")
func set_hex_card(card):
	hex_card = card
	if card != null:
		print("blleeppepe ", card.values())
		print("SGDSGDFGSDGFDSGFSFSBSGB")
		hex_defense = card["1"]["defense"]
		hex_attack = card["1"]["attack"]
		emit_signal("hex_card_changed")
func get_hex_data():
	return {"hex_data":{"hex_card":hex_card, "hex_attack":hex_attack, "hex_defense":hex_defense, "hex_owner":hex_owner}}


func update_hex():
#compare tile atk to surrounding def
#if self.atk > targethex.def sorrounding tile is owned by player, reset tile to empty
#if if atk == def, nothing happens
#else def=def-atk, show cracks on minus defense

	# We could just check all the surrounding hex's and ignore if null node, 
	# but will want AI to know if the hex is in the corner/edge or center.
	var N = self.get_parent().get_parent().get_position_in_parent()
	var row
	var surrounding_hex_cells = []
	
	if N < GameState.board_length:
		row = 0
	else:
		row = N / GameState.board_length

	if (N < GameState.board_length - 1 and N > 0): # Top, not including corners: N<length-1, N>0
		print("Top: ",N)
		#print("R: ", self.get_parent().get_parent().get_parent().get_child(N + 1).get_node("Sprite/Area2D").get_hex_data())
		#print("L: ", self.get_parent().get_parent().get_parent().get_child(N-1).get_node("Sprite/Area2D").get_hex_data())
		#print("BR: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length+1).get_node("Sprite/Area2D").get_hex_data())
		#print("BL: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length-1).get_node("Sprite/Area2D").get_hex_data())
		var r_data = self.get_parent().get_parent().get_parent().get_child(N + 1).get_node("Sprite/Area2D").get_hex_data()
		if r_data["hex_data"]["hex_owner"] != GameState.player_name:
			r_data["hex_data"]["position"] = N + 1
			surrounding_hex_cells.append(r_data)
		var l_data = self.get_parent().get_parent().get_parent().get_child(N-1).get_node("Sprite/Area2D").get_hex_data()
		if l_data["hex_data"]["hex_owner"] != GameState.player_name:
			l_data["hex_data"]["position"] = N + 1
			surrounding_hex_cells.append(l_data)
		var br_data = self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length+1).get_node("Sprite/Area2D").get_hex_data()
		if br_data["hex_data"]["hex_owner"] != GameState.player_name:
			br_data["hex_data"]["position"] = N + GameState.board_length + 1
			surrounding_hex_cells.append(br_data)
		var bl_data = self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length-1).get_node("Sprite/Area2D").get_hex_data()
		if bl_data["hex_data"]["hex_owner"] != GameState.player_name:
			bl_data["hex_data"]["position"] = N + GameState.board_length - 1
			surrounding_hex_cells.append(bl_data)
		print ("CELL: ", surrounding_hex_cells)
		for cell in surrounding_hex_cells: 
			print(self.get_hex_data()["hex_data"]["hex_attack"], " : ", cell["hex_data"]["hex_defense"])
			if int(self.get_hex_data()["hex_data"]["hex_attack"]) > cell["hex_data"]["hex_defense"]:
				print("child: ",cell["hex_data"]["position"])
				self.get_parent().get_parent().get_parent().get_child(cell["hex_data"]["position"]).get_node("Sprite/Area2D").set_hex_owner( GameState.player_name )
				self.get_parent().get_parent().get_parent().get_child(cell["hex_data"]["position"]).get_node("Sprite/Area2D").set_hex_attack( 8 )
				self.get_parent().get_parent().get_parent().get_child(cell["hex_data"]["position"]).get_node("Sprite/Area2D").set_hex_defence( 8 )
				self.get_parent().get_parent().get_parent().get_child(cell["hex_data"]["position"]).get_node("Sprite/Area2D").set_hex_card(null)
		print ("R_CELL: ", self.get_parent().get_parent().get_parent().get_child(N + 1).get_node("Sprite/Area2D").get_hex_data())
			
	elif (N < ( (GameState.board_length * GameState.board_height) - 1) and N > (GameState.board_length * GameState.board_height) - GameState.board_length): #Bottom
		print("Bottom: ", N)
		print("R: ", self.get_parent().get_parent().get_parent().get_child(N + 1).get_node("Sprite/Area2D").get_hex_data())
		print("L: ", self.get_parent().get_parent().get_parent().get_child(N-1).get_node("Sprite/Area2D").get_hex_data())
		print("TR: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length+1).get_node("Sprite/Area2D").get_hex_data())
		print("TL: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length-1).get_node("Sprite/Area2D").get_hex_data())
		pass # Check N-1, N+1, N-length-1, N-length+1, N-length
	elif (N == 0): # Corner top left
		print("TL Corner: ", N)
		print("R: ", self.get_parent().get_parent().get_parent().get_child(N + 1).get_node("Sprite/Area2D").get_hex_data())
		print("B: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length).get_node("Sprite/Area2D").get_hex_data())
		print("BR: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length+1).get_node("Sprite/Area2D").get_hex_data())
	elif (N == GameState.board_length - 1): # Corner top right 
		print("TR Corner: ",N)
		print("L: ", self.get_parent().get_parent().get_parent().get_child(N-1).get_node("Sprite/Area2D").get_hex_data())
		print("B: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length).get_node("Sprite/Area2D").get_hex_data())
		print("BL: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length-1).get_node("Sprite/Area2D").get_hex_data())
	elif (N == ((GameState.board_length * GameState.board_height) - GameState.board_length )): # Corner bottom left
		print("BL Corner: ",N)
		print("T: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length).get_node("Sprite/Area2D").get_hex_data())
		print("R: ", self.get_parent().get_parent().get_parent().get_child(N + 1).get_node("Sprite/Area2D").get_hex_data())
		print("TR: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length+1).get_node("Sprite/Area2D").get_hex_data())
	elif (N == (GameState.board_length * GameState.board_height ) -1 ): # Corner bottom right
		print("BR Corner: ",N)
		print("T: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length).get_node("Sprite/Area2D").get_hex_data())
		print("L: ", self.get_parent().get_parent().get_parent().get_child(N-1).get_node("Sprite/Area2D").get_hex_data())
		print("TL: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length-1).get_node("Sprite/Area2D").get_hex_data())
	elif ((GameState.board_length * row) % N == 0): # Edges
		var right_edge = N - 1
		print("Left Edge: ", N, " - ", GameState.board_length, " * ", row)
		print("Right Edge: ", right_edge, " - ", GameState.board_length, " * ", row)
		if N == right_edge:
			print("L: ", self.get_parent().get_parent().get_parent().get_child(N-1).get_node("Sprite/Area2D").get_hex_data())
			print("TL: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length-1).get_node("Sprite/Area2D").get_hex_data())
			print("BL: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length-1).get_node("Sprite/Area2D").get_hex_data())
		else:
			print("R: ", self.get_parent().get_parent().get_parent().get_child(N + 1).get_node("Sprite/Area2D").get_hex_data())
			print("TR: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length+1).get_node("Sprite/Area2D").get_hex_data())
			print("BR: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length+1).get_node("Sprite/Area2D").get_hex_data())
		print("B: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length).get_node("Sprite/Area2D").get_hex_data())
		print("T: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length).get_node("Sprite/Area2D").get_hex_data())
	elif N > GameState.board_length and N < GameState.board_height * GameState.board_length:
		print("I: ", N)
		print("L: ", self.get_parent().get_parent().get_parent().get_child(N-1).get_node("Sprite/Area2D").get_hex_data())
		print("R: ", self.get_parent().get_parent().get_parent().get_child(N + 1).get_node("Sprite/Area2D").get_hex_data())
		print("B: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length).get_node("Sprite/Area2D").get_hex_data())
		print("T: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length).get_node("Sprite/Area2D").get_hex_data())
		print("TL: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length-1).get_node("Sprite/Area2D").get_hex_data())
		print("TR: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length+1).get_node("Sprite/Area2D").get_hex_data())
		print("BR: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length+1).get_node("Sprite/Area2D").get_hex_data())
		print("BL: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length-1).get_node("Sprite/Area2D").get_hex_data())
		pass

func _on_hex_attack_changed():
	print("hex_atk_changed")
	pass
func _on_hex_defense_changed():
	print("hex_def_changed")
	pass
func _on_hex_card_changed():
	print("hex_card_changed")
	pass
	
#TODO Combine into one callback function, might need it for daemon actions
func _on_computer_1_pressed( arg1 ):
	action = arg1
func _on_computer_2_pressed( arg1 ):
	action = arg1
func _on_server_pressed( arg1 ):
	action = arg1
func _on_high_pressed( arg1 ):
	action = arg1
func _on_medium_pressed( arg1 ):
	action = arg1
func _on_low_pressed( arg1 ):
	action = arg1
func _on_special_pressed( arg1 ):
	action = arg1
	
#TODO Combine into one callback function, might need it for daemon actions
func _on_action_placed():
	action = null
func _on_computer_1_placed():
	action = null
func _on_computer_2_placed():
	action = null
func _on_server_placed():
	action = null
func _on_high_placed():
	action = null
func _on_medium_placed():
	action = null
func _on_low_placed():
	action = null
func _on_special_placed():
	action = null