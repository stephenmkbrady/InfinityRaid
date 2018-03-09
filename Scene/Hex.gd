extends Area2D

signal computer_1_placed()
signal computer_2_placed()
signal server_placed()
signal high_placed()
signal medium_placed()
signal low_placed()

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
var game_state

func _ready():
	snd_drop_action = get_tree().get_root().get_node("Node2D/audio/drop_action")
	game_state = get_node("/root/GameState")
	tile_tex = self.get_parent().get_texture()
	# Subscribe all hex instances to the action buttons
	self.get_tree().get_root().get_node("Node2D/Computer_1").connect("action_pressed",self,"_on_action_pressed")
	self.get_tree().get_root().get_node("Node2D/Computer_2").connect("action_pressed",self,"_on_action_pressed")
	self.get_tree().get_root().get_node("Node2D/Server").connect("action_pressed",self,"_on_action_pressed")
	self.get_tree().get_root().get_node("Node2D/ActionButtons/High").connect("action_pressed",self,"_on_action_pressed")
	self.get_tree().get_root().get_node("Node2D/ActionButtons/Medium").connect("action_pressed",self,"_on_action_pressed")
	self.get_tree().get_root().get_node("Node2D/ActionButtons/Low").connect("action_pressed",self,"_on_action_pressed")
	# Subscribe to root node to know when another hex instance has fired hex_selected
	var game_state = get_tree().get_root().get_node("/root/GameState")
	game_state.connect("action_placed",self,"_on_action_placed")
	game_state.connect("computer_1_placed",self,"_on_computer_1_placed")
	game_state.connect("computer_2_placed",self,"_on_computer_2_placed")
	game_state.connect("server_placed",self,"_on_server_placed")
	game_state.connect("action_placed", self, "_on_high_placed")
	game_state.connect("high_placed", self, "_on_high_placed")
	game_state.connect("medium_placed", self, "_on_medium_placed")
	game_state.connect("low_placed", self, "_on_low_placed")
	
	self.get_tree().get_root().get_node("/root/GameState").connect("card_drawn", self, "_on_card_drawn")
	self.connect("input_event",self,"_on_Area2D_input_event")
	


func _on_Area2D_input_event( viewport, event, shape_idx ):
	if event.action_match(event):
		if event.is_pressed() and event.button_index == BUTTON_LEFT:
			if self.hex_owner == game_state.player_name or self.hex_owner == null:
				snd_drop_action.play()
				if action == "Computer_1":
					card = game_state.computer_1_card
					emit_signal("computer_1_placed", self.get_parent().get_parent().get_position_in_parent())
				elif action == "Computer_2":
					card = game_state.computer_2_card
					emit_signal("computer_2_placed", self.get_parent().get_parent().get_position_in_parent())
				elif action == "Server":
					card = game_state.server_card
					emit_signal("server_placed", self.get_parent().get_parent().get_position_in_parent())
				elif action == "High":
					emit_signal("high_placed", self.get_parent().get_parent().get_position_in_parent())
				elif action == "Medium":
					emit_signal("medium_placed", self.get_parent().get_parent().get_position_in_parent())
				elif action == "Low":
					emit_signal("low_placed", self.get_parent().get_parent().get_position_in_parent())
				set_hex_card( card, true )
			else:
				get_tree().get_root().get_node("Node2D/InfoText").set_bbcode("[center]You can only place programs in computers you own[/center]")

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

func set_hex_defence( value ):
	hex_defense = value

func set_hex_card(card, sync_remote = false ):
	hex_card = card
	if card != null:
		set_hex_owner(get_tree().get_network_unique_id(), GameState.player_name, true)
		self.get_parent().set_texture(load(card.tile))
		var pos = self.get_parent().get_parent().get_position_in_parent()
		if card.has("defense") and card.has("attack"):
			hex_defense = int(card["defense"])
			hex_attack = int(card["attack"])
			self.get_parent().add_child(game_state.get_strength_indicator(hex_attack, hex_defense))
		if sync_remote:
			rpc("remote_update_hex_card", card, pos)
		update_board()
	else: 
		self.get_parent().set_texture(self.tile_tex)

remote func remote_update_hex_card(card, pos):
	var hex_cell = self.get_tree().get_root().get_node('Node2D/Position2D').get_child(pos).get_child(0).get_child(0)
	hex_cell.hex_card = card
	self.get_parent().set_texture(load(card.tile))
	if card.has("defense") and card.has("attack"):
		hex_cell.set_hex_defence(int(card["defense"]))
		hex_cell.set_hex_attack(int(card["attack"]))
		hex_cell.get_parent().add_child(game_state.get_strength_indicator(int(card["attack"]), int(card["defense"])))

func get_hex_data():
	return {"hex_data":{"hex_card":hex_card, "hex_attack":hex_attack, "hex_defense":hex_defense, "hex_owner":hex_owner}}


func update_board():
#	var hex_cell = self.get_tree().get_root().get_node('Node2D/Position2D').get_child(pos).get_child(0).get_child(0)
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

	for cell in surrounding_hex_cells: 
		if int(self.get_hex_data()["hex_data"]["hex_attack"]) > cell["hex_data"]["hex_defense"]:
			self.get_parent().get_parent().get_parent().get_child(cell["hex_data"]["position"]).get_node("Sprite/Area2D").set_hex_owner(get_tree().get_network_unique_id(), game_state.player_name, true )
			self.get_parent().get_parent().get_parent().get_child(cell["hex_data"]["position"]).get_node("Sprite/Area2D").set_hex_attack( 1 )
			self.get_parent().get_parent().get_parent().get_child(cell["hex_data"]["position"]).get_node("Sprite/Area2D").set_hex_defence( 1 )
			self.get_parent().get_parent().get_parent().get_child(cell["hex_data"]["position"]).get_node("Sprite/Area2D").set_hex_card(null, false)

func _is_hex_enemy( location_in_parent ):
	# Returns hex_data if belongs to other player
	# Returns null if not
	if(location_in_parent >= 0 and location_in_parent < GameState.board_cell_count and self.get_parent().get_parent().get_parent().get_child(location_in_parent) != null):
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