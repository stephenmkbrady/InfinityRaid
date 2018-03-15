extends Area2D

signal Computer_1_placed()
signal Computer_2_placed()
signal Server_placed()
signal High_placed()
signal Medium_placed()
signal Low_placed()

signal hex_attack_changed()
signal hex_defense_changed()
signal hex_card_changed()
signal hex_owner_changed()

var DEBUG = false
var action
var card = null

var hex_contents = {}
var tile_tex


var snd_drop_action
var tile_effect 

func _ready():
	hex_contents = {
		"hex_owner":null,
		"hex_defense":"0",
		"hex_attack":0,
		"hex_card":null,
		"hex_position": self.get_parent().get_parent().get_position_in_parent(),
		"hex_base_tile": self.get_parent().get_texture() 
		}
	tile_effect = load("res://Scene/node_effect.tscn")
	snd_drop_action = get_tree().get_root().get_node("Node2D/audio/drop_action")

	# Subscribe hex instance to the action buttons
	for node in self.get_tree().get_root().get_node("Node2D/ActionButtons").get_children():
		node.connect("action_pressed",self,"_on_action_pressed")

	# Subscribe to root node to know when another hex instance has updated
	GameState.connect("Computer_1_placed",self,"_on_computer_1_placed")
	GameState.connect("Computer_2_placed",self,"_on_computer_2_placed")
	GameState.connect("Server_placed",self,"_on_server_placed")
	GameState.connect("High_placed", self, "_on_high_placed")
	GameState.connect("Medium_placed", self, "_on_medium_placed")
	GameState.connect("Low_placed", self, "_on_low_placed")
	# Listen for card_drawn to know what card to place if pressed
	GameState.connect("card_drawn", self, "_on_card_drawn")

	self.connect("input_event",self,"_on_Area2D_input_event")

func _on_Area2D_input_event( viewport, event, shape_idx ):
	if event.action_match(event):
		if event.is_pressed() and event.button_index == BUTTON_LEFT:
			if DEBUG:
				print("Action placing: ", action)
			# If the hex is owned by current player or not owned then it's ok to place a piece
			if hex_contents["hex_owner"] == GameState.player_name or hex_contents["hex_owner"] == null:
				get_tree().get_root().get_node("Node2D/InfoText").set_bbcode("[center][/center]") # Clear the info text
				if action == "Computer_1" or action == "Computer_2" or action == "Server":
					card = GameState.decks[action + "_card"]
				
				set_hex_contents( card )
				set_hex_owner( GameState.player_name)
				set_hex_indicator(card["attack"], card["defense"])
				rpc("set_hex_contents", card)
				rpc("set_hex_owner", GameState.player_name)
				rpc("set_hex_indicator", card["attack"], card["defense"])
				
				update_board_on_action_placed()
				
				snd_drop_action.play()
				emit_signal(action + "_placed", self.get_parent().get_parent().get_position_in_parent())
			else:
				get_tree().get_root().get_node("Node2D/InfoText").set_bbcode("[center]You can only place in area you own[/center]")

func _on_card_drawn(arg):
	card = arg

remote func set_hex_owner(name):
	if DEBUG:
		print(get_parent().get_parent().get_position_in_parent(), " previous hex_contents['hex_owner']", hex_contents['hex_owner'])
	hex_contents["hex_owner"] = name
	if DEBUG:
		print(get_parent().get_parent().get_position_in_parent(), " hex_contents['hex_owner'] = ", hex_contents["hex_owner"])
	# Create player marker node
	var player_marker = load("res://Scene/player_marker.tscn").instance()
	player_marker.get_node("Sprite").set_texture(GameState.get_player_marker( name ))
	# Remove existing player_marker
	for c in get_parent().get_parent().get_children():
		if DEBUG:
			print(get_parent().get_parent().get_position_in_parent(), " looking for player_marker: ", c.get_name())
		# Network layer mangles node names by changing name to something like @name@123
		if c.get_name() == "player_marker" or c.get_name().find("player_marker") != -1:
			if DEBUG:
				print(get_parent().get_parent().get_position_in_parent(), " PLAYER_MARKER FOUND")
				print("REMOVING: ",get_parent().get_parent().get_node(c.get_name()).get_name())
			get_parent().get_parent().get_node(c.get_name()).queue_free()
	self.get_parent().get_parent().add_child(player_marker)

remote func set_hex_indicator( atk_value, def_value ):
	if DEBUG:
		print("hex_contents['hex_attack'] = ", atk_value, " hex_contents['hex_defense'] = ", def_value)
	if atk_value != null:
		hex_contents["hex_attack"] = atk_value
	if def_value != null:
		hex_contents["hex_defense"] = def_value
	# Network layer mangles node names by changing name to something like @name@123
	for c in self.get_parent().get_parent().get_children():
		if c.get_name() == "indicator" or c.get_name().find("indicator") != -1:
			self.get_parent().get_parent().get_node(c.get_name()).queue_free()
	
	var indicator = GameState.get_strength_indicator(hex_contents["hex_attack"], hex_contents["hex_defense"])
	if indicator != null:
		self.get_parent().get_parent().add_child(indicator)

remote func set_hex_contents(card):
	hex_contents["hex_card"] = card
	if DEBUG:
		print("hex_contents['hex_card'] = ", card)
	if card != null:
		#var player = GameState.player_name
		self.get_parent().set_texture(load(card.tile))
		self.get_parent().set_z_index(6)
		#Spark effect will queue_free() itself once played
		self.get_parent().get_parent().add_child(tile_effect.instance())
		self.get_parent().get_parent().get_node("effect").set_z_index(5)
		self.get_parent().get_parent().get_node("effect").get_node("spark").play()
		
	else: # Were're deleting a game piece from the cell
		self.get_parent().set_texture(hex_contents["hex_base_tile"])
		for c in self.get_parent().get_parent().get_children():
			if c.get_name() == "indicator":
				self.get_parent().get_parent().add_child(tile_effect.instance())
				self.get_parent().get_parent().get_node("effect").set_z_index(5)
				self.get_parent().get_parent().get_node("effect").get_node("death").play()

func get_hex_contents():
	return hex_contents

func update_board_on_action_placed():
	var N = self.get_parent().get_parent().get_position_in_parent()
	var positions = [N - 1, N + 1, 
					 N + GameState.board_length + 1, N + GameState.board_length - 1, 
					 N - GameState.board_length + 1, N - GameState.board_length - 1,
					 N + GameState.board_length, N - GameState.board_length]
	attack_hex_enemies(positions)

func attack_hex_enemies(positions):
	var surrounding_enemies = []
	for p in positions:
		if hex_enemy_data(p) != null:
			surrounding_enemies.append(hex_enemy_data(p))
	
	for enemy in surrounding_enemies: 
		var enemy_instance  = self.get_tree().get_root().get_node('Node2D/Position2D').get_child(enemy["hex_position"]).get_node("Sprite/Area2D")
		#If enemy hex is defeated immediately
		if int(hex_contents["hex_attack"]) >= int(enemy["hex_defense"]):
			enemy_instance.set_hex_owner(GameState.player_name)
			enemy_instance.rpc("set_hex_owner",GameState.player_name)
			_kill_hex(enemy_instance)
			
		# If enemy defense stronger than hex's attack, drop enem's def but enemy attacks back
		elif int(hex_contents["hex_attack"]) < int(enemy["hex_defense"]):
			enemy["hex_defense"] = enemy["hex_defense"] - hex_contents["hex_attack"]
			enemy_instance.set_hex_indicator(null, enemy["hex_defense"])
			enemy_instance.rpc("set_hex_indicator", null, enemy["hex_defense"]) 
			# Enemy attack back and is hex is immediately defeated
			if int(hex_contents["hex_defense"]) <= int(enemy["hex_attack"]):
				for p in GameState.players:
					print("set_hex_owner: ", GameState.players[p])
					set_hex_owner(GameState.players[p])
					rpc("set_hex_owner", GameState.players[p])
				_kill_hex(self)

			# Enemy attack back and does damage
			elif int(enemy["hex_attack"]) < int(hex_contents["hex_defense"]):
				hex_contents["hex_defense"] = hex_contents["hex_defense"] - enemy["hex_attack"]
				set_hex_indicator(null, hex_contents["hex_defense"])
				rpc("set_hex_indicator", null, hex_contents["hex_defense"]) 

func _kill_hex(hex_instance):
	if hex_instance.get_hex_contents()["hex_card"] != null:
		print("Hex killed: ", hex_instance.get_hex_contents())
		if hex_instance.get_hex_contents()["hex_card"]["name"] == "Computer_1" or hex_instance.get_hex_contents()["hex_card"]["name"] == "Computer_2":
			rpc("set_power_time", 12)
		elif hex_instance.get_hex_contents()["hex_card"]["name"] == "Server":
			rpc("set_power_time", 28)
	hex_instance.set_hex_contents(null)
	hex_instance.set_hex_indicator(0,0)
	hex_instance.rpc("set_hex_contents",null)
	hex_instance.rpc("set_hex_indicator", 0, 0 )

remote func set_power_time(t):
	GameState.power_time = GameState.power_time + t
	
func hex_enemy_data( location_in_parent ):
	#Returns hex_data if enemy or not allocated to hex asking, or returns null if not the enemy of the hex asking or if hex doesn't exist
	if(location_in_parent >= 0 and location_in_parent < GameState.board_cell_count and self.get_parent().get_parent().get_parent().get_child(location_in_parent) != null):
		var enemy_hex_data = self.get_parent().get_parent().get_parent().get_child(location_in_parent).get_node("Sprite/Area2D").get_hex_contents()
		if enemy_hex_data["hex_owner"] != str(GameState.player_name):
			# enemy_hex_data["position"] = location_in_parent
			return enemy_hex_data
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