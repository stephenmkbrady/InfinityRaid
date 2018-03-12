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

var action
var card = null

var hex_owner
var hex_defense = 1
var hex_attack = 1
var hex_card = null

var snd_drop_action
var tile_tex
var tile_effect 

func _ready():
	tile_effect = load("res://Scene/node_effect.tscn")
	snd_drop_action = get_tree().get_root().get_node("Node2D/audio/drop_action")
	tile_tex = self.get_parent().get_texture() 

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
			# If the hex is owned by current player or not owned then it's ok to place a piece
			if self.hex_owner == GameState.player_name or self.hex_owner == null:
				get_tree().get_root().get_node("Node2D/InfoText").set_bbcode("[center][/center]")
				snd_drop_action.play()
				if action == "Computer_1" or action == "Computer_2" or action == "Server":
					card = GameState.decks[action + "_card"]
				#print ("CARD__ ", GameState.decks[action + "_card"])
				set_hex_card( card, true )
				
				self.get_parent().get_parent().add_child(tile_effect.instance())
				self.get_parent().get_parent().get_node("effect").set_z_index(5)
				self.get_parent().get_parent().get_node("effect").get_node("pulse").play()
				self.get_parent().get_parent().get_node("effect").get_node("spark").play()
				rpc("remote_play_effect", self.get_parent().get_parent().get_position_in_parent(), ["pulse", "spark"])
				emit_signal(action + "_placed", self.get_parent().get_parent().get_position_in_parent())
			else:
				get_tree().get_root().get_node("Node2D/InfoText").set_bbcode("[center]You can only place programs in computers you own[/center]")

remote func remote_play_effect(pos, effects):
	get_tree().get_root().get_node("Node2D/Position2D").get_child(pos).add_child(tile_effect.instance())
	get_tree().get_root().get_node("Node2D/Position2D").get_child(pos).get_node("effect").set_z_index(5)
	for effect in effects:
		get_tree().get_root().get_node("Node2D/Position2D").get_child(pos).get_node("effect").get_node(effect).play()

func _on_card_drawn(arg):
	card = arg

func set_hex_owner(id,  name, sync_remote = false ):
	hex_owner = name
	var player_node = Node2D.new()
	var p_sprite = Sprite.new()
	var p_marker = GameState.get_player_marker( hex_owner )
	p_sprite.set_texture(p_marker)
	player_node.add_child(p_sprite)
	# If the player_node is on the node, replace it
	# TODO: reproduce and bug if not already: has_node() only works for child(0) and doesn't return true for child(1)
	for c in self.get_children():
		if c.get_name().begins_with("@"):
			if self.get_child(1) != null:
				self.get_child(1).queue_free()
	self.add_child(player_node)
	
	if sync_remote:
		var pos = self.get_parent().get_parent().get_position_in_parent()
		for p in GameState.players:
			rpc_id(p, "remote_update_hex_owner", name, pos)

remote func remote_update_hex_owner(id, pos):
	self.get_tree().get_root().get_node('Node2D/Position2D').get_child(pos).get_child(0).get_child(0).set_hex_owner(get_tree().get_network_unique_id(), id)

func set_hex_attack( value ):
	hex_attack = value

func set_hex_defense( value ):
	hex_defense = value

remote func remote_set_hex_defense(data):
	#var hex_instance  = self.get_parent().get_parent().get_parent().get_child(pos).get_node("Sprite/Area2D")
	self.set_hex_defense(data["hex_data"]["hex_defense"])
	for c in self.get_parent().get_children():
		if c.get_name() == "indicator":
			self.get_parent().get_node("indicator").queue_free()
	var indicator = GameState.get_strength_indicator( data["hex_data"]["hex_attack"], data["hex_data"]["hex_defense"])
	if indicator != null:
		self.get_parent().add_child(indicator)

func set_hex_card(card, sync_remote = false ):
	hex_card = card
	var pos = self.get_parent().get_parent().get_position_in_parent()
	if card != null:
		set_hex_owner(get_tree().get_network_unique_id(), GameState.player_name, true)
		self.get_parent().set_texture(load(card.tile))
		self.get_parent().set_z_index(6)
		if card.has("defense") and card.has("attack"):
			hex_defense = int(card["defense"])
			hex_attack = int(card["attack"])
			self.get_parent().add_child(GameState.get_strength_indicator(hex_attack, hex_defense))
		update_board()
	else: # Were're deleting a game piece from the cell
		self.get_parent().set_texture(self.tile_tex)
		hex_defense = 1
		hex_attack = 1
		for c in self.get_parent().get_parent().get_children():
			if c.get_name() == "effect":
				self.get_parent().get_parent().get_node("effect").queue_free()
		for c in self.get_parent().get_children():
			if c.get_name() == "indicator":
				self.get_parent().get_node("indicator").queue_free()
	if sync_remote:
		rpc("remote_update_hex_card", card)

remote func remote_update_hex_card(card):
	if card != null:
		self.hex_card = card
		self.get_parent().set_texture(load(card.tile))
		self.get_parent().set_z_index(6)
		if card.has("defense") and card.has("attack"):
			self.set_hex_defense(int(card["defense"]))
			self.set_hex_attack(int(card["attack"]))
			self.get_parent().add_child(GameState.get_strength_indicator(int(card["attack"]), int(card["defense"])))
	else: 
		self.get_parent().set_texture(self.tile_tex)
		for c in self.get_parent().get_parent().get_children():
			if c.get_name() == "effect":
				self.get_parent().get_parent().get_node("effect").queue_free()
		for c in self.get_parent().get_children():
			if c.get_name() == "indicator":
				self.get_parent().get_node("indicator").queue_free()
		self.set_hex_defense(1)
		self.set_hex_attack(1)

func get_hex_data():
	return {"hex_data":{"hex_card":hex_card, "hex_attack":hex_attack, "hex_defense":hex_defense, "hex_owner":hex_owner}}

func update_board():
	var N = self.get_parent().get_parent().get_position_in_parent()
	var positions = [N - 1, N + 1, 
					 N + GameState.board_length + 1, N + GameState.board_length - 1, 
					 N - GameState.board_length + 1, N - GameState.board_length - 1,
					 N + GameState.board_length, N - GameState.board_length]
	attack_enemies(positions)


func attack_enemies(positions):
	var surrounding_enemies = []
	for p in positions:
		if _is_hex_enemy(p) != null:
			surrounding_enemies.append(_is_hex_enemy(p))
	
	for enemy in surrounding_enemies: 
		var enemy_instance  = self.get_tree().get_root().get_node('Node2D/Position2D').get_child(enemy["hex_data"]["position"]).get_node("Sprite/Area2D")
		print("self - atk: ", self.get_hex_data()["hex_data"]["hex_attack"], " | enemy - atk: ", enemy["hex_data"]["hex_attack"])
		print("self - def: ", self.get_hex_data()["hex_data"]["hex_defense"], " | enemy - def: ", enemy["hex_data"]["hex_defense"])

		if self.get_hex_data()["hex_data"]["hex_attack"] >= enemy["hex_data"]["hex_defense"]:
			enemy_instance.set_hex_owner(get_tree().get_network_unique_id(), GameState.player_name, true )
			enemy_instance.set_hex_attack( 1 )
			enemy_instance.set_hex_defense( 1 )
			enemy_instance.set_hex_card(null, true)
		elif self.get_hex_data()["hex_data"]["hex_attack"] < enemy["hex_data"]["hex_defense"]:
			enemy["hex_data"]["hex_defense"] = enemy["hex_data"]["hex_defense"] - self.get_hex_data()["hex_data"]["hex_attack"]
			enemy_instance.set_hex_defense(enemy["hex_data"]["hex_defense"] - self.get_hex_data()["hex_data"]["hex_attack"])
			
			for c in enemy_instance.get_parent().get_children():
				if c.get_name() == "indicator":
					enemy_instance.get_parent().get_node("indicator").queue_free()
			var indicator = GameState.get_strength_indicator( enemy["hex_data"]["hex_attack"], enemy["hex_data"]["hex_defense"])
			if indicator:
				enemy_instance.get_parent().add_child(indicator)
			
			rpc("remote_set_hex_defense", enemy) #enemy["hex_data"]["position"],

func _is_hex_enemy( location_in_parent ):
	# Returns hex_data if belongs to other player
	# Returns null if not
	if(location_in_parent >= 0 and location_in_parent < GameState.board_cell_count and self.get_parent().get_parent().get_parent().get_child(location_in_parent) != null):
		var hex_data = self.get_parent().get_parent().get_parent().get_child(location_in_parent).get_node("Sprite/Area2D").get_hex_data()
		if hex_data["hex_data"]["hex_owner"] != GameState.player_name:
			hex_data["hex_data"]["position"] = location_in_parent
			return hex_data
	else:
		return null

func _is_hex_friend( location_in_parent ):
	# Returns hex_data if belongs to other player
	# Returns null if not
	if(location_in_parent >= 0 and location_in_parent < GameState.board_cell_count and self.get_parent().get_parent().get_parent().get_child(location_in_parent) != null):
		var hex_data = self.get_parent().get_parent().get_parent().get_child(location_in_parent).get_node("Sprite/Area2D").get_hex_data()
		if hex_data["hex_data"]["hex_owner"] == GameState.player_name:
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