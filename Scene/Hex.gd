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
var timer
var card = null

var hex_owner
var hex_defense = 1
var hex_attack = 1
var hex_card = null

var game_state

func _ready():
	game_state = get_node("/root/GameState")
	# Subscribe all hex instances to the action buttons
	self.get_tree().get_root().get_node("Node2D/Computer_1").connect("action_pressed",self,"_on_action_pressed")
	self.get_tree().get_root().get_node("Node2D/Computer_2").connect("action_pressed",self,"_on_action_pressed")
	self.get_tree().get_root().get_node("Node2D/Server").connect("action_pressed",self,"_on_action_pressed")
	self.get_tree().get_root().get_node("Node2D/High").connect("action_pressed",self,"_on_action_pressed")
	self.get_tree().get_root().get_node("Node2D/Medium").connect("action_pressed",self,"_on_action_pressed")
	self.get_tree().get_root().get_node("Node2D/Low").connect("action_pressed",self,"_on_action_pressed")
	self.get_tree().get_root().get_node("Node2D/Special").connect("action_pressed",self,"_on_action_pressed")
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

func _on_Area2D_input_event( viewport, event, shape_idx ):
	if event.action_match(event):
		if event.is_pressed() and event.button_index == BUTTON_LEFT:
			if self.hex_owner == game_state.player_name:
				if action == 2:
					card = game_state.computer_1_card
					emit_signal("computer_1_placed", self.get_parent().get_parent().get_position_in_parent())
				elif action == 3:
					card = game_state.computer_2_card
					emit_signal("computer_2_placed", self.get_parent().get_parent().get_position_in_parent())
				elif action == 4:
					card = game_state.server_card
					emit_signal("server_placed", self.get_parent().get_parent().get_position_in_parent())
				elif action == 5:
					emit_signal("high_placed", self.get_parent().get_parent().get_position_in_parent())
				elif action == 6:
					emit_signal("medium_placed", self.get_parent().get_parent().get_position_in_parent())
				elif action == 7:
					emit_signal("low_placed", self.get_parent().get_parent().get_position_in_parent())
				elif action == 8:
					emit_signal("special_placed", self.get_parent().get_parent().get_position_in_parent())

				set_hex_card( card )
			else:
				get_tree().get_root().get_node("Node2D/InfoText").set_bbcode("[center]You can only place programs in computers you own[/center]")

func _on_card_drawn(arg):
	card = arg

func set_hex_owner( name ):
	hex_owner = name
	var player_node = Node2D.new()
	var p_sprite = Sprite.new()
	var p_marker = GameState.get_player_marker( hex_owner )
	p_sprite.set_texture(p_marker)
	player_node.add_child(p_sprite)
	# If the player_node is on the node, replace it
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
		self.get_parent().set_texture(load(card.tile))
		print("set_hex_card ", card)
		if card.has("defense") and card.has("attack"):
			hex_defense = int(card["defense"])
			hex_attack = int(card["attack"])
			self.get_parent().add_child(game_state.get_strength_indicator(hex_attack))
		emit_signal("hex_card_changed")
	update_board()

func get_hex_data():
	return {"hex_data":{"hex_card":hex_card, "hex_attack":hex_attack, "hex_defense":hex_defense, "hex_owner":hex_owner}}


func update_board():
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
	if _is_hex_enemy(N + game_state.board_length + 1) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N + game_state.board_length + 1))
	if _is_hex_enemy(N + game_state.board_length - 1) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N + game_state.board_length - 1))
	if _is_hex_enemy(N - game_state.board_length + 1) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N - game_state.board_length + 1))
	if _is_hex_enemy(N - game_state.board_length - 1) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N - game_state.board_length - 1))
	if _is_hex_enemy(N + game_state.board_length ) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N + game_state.board_length ))
	if _is_hex_enemy(N - game_state.board_length ) != null:
		surrounding_hex_cells.append(_is_hex_enemy(N - game_state.board_length ))

	# print ("surrounding_enemy_hex_cells: ", surrounding_hex_cells)
	for cell in surrounding_hex_cells: 
		print(self.get_hex_data()["hex_data"]["hex_attack"], " : ", cell["hex_data"]["hex_defense"])
		if int(self.get_hex_data()["hex_data"]["hex_attack"]) > cell["hex_data"]["hex_defense"]:
			print("child: ",cell["hex_data"]["position"])
			self.get_parent().get_parent().get_parent().get_child(cell["hex_data"]["position"]).get_node("Sprite/Area2D").set_hex_owner( game_state.player_name )
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
		if hex_data["hex_data"]["hex_owner"] != game_state.player_name:
			hex_data["hex_data"]["position"] = location_in_parent
			return hex_data
	else:
		return null

func _on_action_pressed( arg1 ):
	action = arg1

#TODO Will need it for daemon actions
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