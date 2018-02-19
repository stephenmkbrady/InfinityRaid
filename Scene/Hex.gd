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
	
	self.connect("hex_owner_changed",self,"_on_hex_owner_changed")
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
					card = GameState.computer_1_card
					self.get_parent().set_texture(load(card.tile))
					self.set_hex_card(card)
					update_hex()
					emit_signal("computer_1_placed", self.get_parent().get_parent().get_position_in_parent())
				elif action == 3:
					card = GameState.computer_2_card
					self.get_parent().set_texture(load(card.tile))
					set_hex_card( card)
					update_hex()
					emit_signal("computer_2_placed", self.get_parent().get_parent().get_position_in_parent())
					
				elif action == 4:
					card = GameState.server_card
					self.get_parent().set_texture(load(card.tile))
					set_hex_card( card)
					update_hex()
					emit_signal("server_placed", self.get_parent().get_parent().get_position_in_parent())
			
				if card != null and card.has("type") and card["type"] == "computer":
					if action == 5:
						set_hex_card( card )
						
						self.add_child(attack_indicator_array[int(card["attack"]) - 1])
						self.get_parent().set_texture(load(card.tile)) #"res://Assets/hex_green.png"
						
						update_hex()
						emit_signal("high_placed", self.get_parent().get_parent().get_position_in_parent())
					elif action == 6:
						set_hex_card( card )
						
						self.add_child(attack_indicator_array[int(card["attack"]) - 1])
						self.get_parent().set_texture(load(card.tile)) #"res://Assets/hex_gold.png"
						
						update_hex()
						emit_signal("medium_placed", self.get_parent().get_parent().get_position_in_parent())
					elif action == 7:
						set_hex_card( card )
						self.add_child(attack_indicator_array[int(card["attack"]) - 1])
						self.get_parent().set_texture(load(card.tile)) #"res://Assets/hex_red.png"
						update_hex()
						emit_signal("low_placed", self.get_parent().get_parent().get_position_in_parent())
					elif action == 8:
						set_hex_card( card )
						self.add_child(attack_indicator_array[int(card["attack"]) - 1])
						self.get_parent().set_texture(load(card.tile)) #"res://Assets/hex_blue.png"
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
	var player_node = Node2D.new()
	var p_sprite = Sprite.new()
	var p_marker = load("res://Assets/hex_player_"+name+".png")
	p_sprite.set_texture(p_marker)
	player_node.add_child(p_sprite)
	if self.get_child(1) != null:
		self.get_child(1).queue_free()

	self.add_child(player_node)
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
		print("set_hex_card ", card.values())
		hex_defense = card["defense"]
		hex_attack = card["attack"]
		emit_signal("hex_card_changed")

func get_hex_data():
	return {"hex_data":{"hex_card":hex_card, "hex_attack":hex_attack, "hex_defense":hex_defense, "hex_owner":hex_owner}}


func update_hex():
	# Get list of surrounding enemy hex's, add to list and do calculation
	# Compare tile atk to surrounding def
	# if self.atk > targethex.def sorrounding tile is owned by player, reset tile to empty
	# if if atk == def, nothing happens
	# else def=def-atk, show cracks on minus defense
	var surrounding_hex_cells = []
	var N = self.get_parent().get_parent().get_position_in_parent()
	
	if _is_hex_enemy(N - 1) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N - 1))
	if _is_hex_enemy(N + 1) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N + 1))
	if _is_hex_enemy(N + GameState.board_length + 1) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N + GameState.board_length + 1))
	if _is_hex_enemy(N + GameState.board_length - 1) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N + GameState.board_length - 1))
	if _is_hex_enemy(N - GameState.board_length + 1) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N - GameState.board_length + 1))
	if _is_hex_enemy(N - GameState.board_length - 1) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N - GameState.board_length - 1))
	if _is_hex_enemy(N + GameState.board_length ) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N + GameState.board_length ))
	if _is_hex_enemy(N - GameState.board_length ) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N - GameState.board_length ))

	print ("surrounding_enemy_hex_cells: ", surrounding_hex_cells)
	for cell in surrounding_hex_cells: 
		print(self.get_hex_data()["hex_data"]["hex_attack"], " : ", cell["hex_data"]["hex_defense"])
		if int(self.get_hex_data()["hex_data"]["hex_attack"]) > cell["hex_data"]["hex_defense"]:
			print("child: ",cell["hex_data"]["position"])
			self.get_parent().get_parent().get_parent().get_child(cell["hex_data"]["position"]).get_node("Sprite/Area2D").set_hex_owner( GameState.player_name )
			self.get_parent().get_parent().get_parent().get_child(cell["hex_data"]["position"]).get_node("Sprite/Area2D").set_hex_attack( 1 )
			self.get_parent().get_parent().get_parent().get_child(cell["hex_data"]["position"]).get_node("Sprite/Area2D").set_hex_defence( 1 )
			self.get_parent().get_parent().get_parent().get_child(cell["hex_data"]["position"]).get_node("Sprite/Area2D").set_hex_card(null)
	print ("R_CELL: ", self.get_parent().get_parent().get_parent().get_child(N + 1).get_node("Sprite/Area2D").get_hex_data())

func _on_hex_attack_changed():
	print("hex_atk_changed")
	pass
func _on_hex_defense_changed():
	print("hex_def_changed")
	pass
func _on_hex_card_changed():
	print("hex_card_changed")
	pass
func _on_hex_owner_changed():
	print("hex_owner_changed")
	pass
func _is_hex_enemy( location_in_parent ):
	# Returns hex_data if belongs to other player
	# Returns null if not
	if(self.get_parent().get_parent().get_parent().get_child(location_in_parent) != null):
		var hex_data = self.get_parent().get_parent().get_parent().get_child(location_in_parent).get_node("Sprite/Area2D").get_hex_data()
		if hex_data["hex_data"]["hex_owner"] != GameState.player_name:
			hex_data["hex_data"]["position"] = location_in_parent
			return hex_data
	else:
		return null

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