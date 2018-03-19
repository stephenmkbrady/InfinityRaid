extends Node

var high_deck # Strong computers and daemons with secondary effects
var medium_deck # Strong computers and daemons
var low_deck # Average computers and daemons
var decks = {}
var computer_1_card
var computer_2_card
var server_card

var player_name = "1"

# Names for remote players in id:name format
var players = {}

var board_update_time = 5
var power_time = 90 
var board_height = 12
var board_length = 12
var board_cell_count = board_height * board_length
var green_indicator = load("res://Scene/StatusIndicator.tscn")
var yellow_indicator = load("res://Scene/StatusIndicator.tscn")
var red_indicator = load("res://Scene/StatusIndicator.tscn")

var hand = load("res://Scene/hand.tscn")
var hand_pos
var hand_node

var active_effects_scene = load("res://Scene/ActiveEffects.tscn")
var active_effects_pos
var active_effects_node

var p_marker
var card
var active_effects = []

signal card_drawn()
signal deck_empty()
signal game_ended()
signal game_error(what)

var background_video 
var timer
#var board_timer
var progress_bar

signal Computer_1_placed()
signal Computer_2_placed()
signal Server_placed()
signal High_placed()
signal Medium_placed()
signal Low_placed()

func _ready():
	randomize()
	
	decks = {}
	var file = File.new()
	file.open("res://Assets/Deck/Deck.json", file.READ)
	var text = file.get_as_text()
	decks = JSON.parse(text).result
	file.close()
	
	if power_time < 60:
		power_time = 60
	
	high_deck = decks["High_deck"]
	medium_deck = decks["Medium_deck"]
	low_deck = decks["Low_deck"]
	computer_1_card = decks["Computer_1_card"]
	computer_2_card = decks["Computer_2_card"]
	server_card = decks["Server_card"]
	
func _process(delta):
	if timer != null:
		progress_bar.set_value(power_time - int(timer.time_left))
	if background_video != null and not background_video.is_playing():
		background_video.play()
	
	# Process any effects applied to player
	for e in active_effects:
		if e.has("effect_duration") and e["effect_duration"].get_time_left() == 0:
			print(get_children())
			print( e.name)
			get_node(e["name"]).queue_free()
			# If the effect is a timer effect then undo it
			if e["card"]["effects"]["type"] == "timer":
				power_time = power_time + e["card"]["effects"]["value"]
			elif e["card"]["effects"]["type"] == "unit":
				pass
			active_effects.remove(active_effects.find(e))

	#print(get_children())
	if timer != null:
		set_info(str(timer.get_time_left()))
		active_effects_node.set_active_effects()

func get_player_list():
	return players.values()

func get_player_name():
	return player_name

func get_player_marker(name):
	return load("res://Assets/hex_player_"+str(name)+".png")

func _on_player_name_changed ( new_name ):
	player_name = new_name

remote func draw_card( deck, r_id ):
	if (get_tree().is_network_server()):
		var r = str(randi() % deck.size() + 1)
		if deck.has(r):
			if r_id != 1:
				rpc_id(r_id, "remote_on_card_drawn", deck[r])
			else:
				emit_signal("card_drawn", deck[r])
		else:
			emit_signal("deck_empty")
	else:
		rpc_id(1,'draw_card', deck, r_id)

remote func remove_card(deck, r):
	deck.erase(r)

func _on_card_drawn(card):
	if card["type"] == "computer":
		hand_node.add_card(card)
		for n in hand_node.get_children():
			print("hand: ", n)
	if card.has("image"):
		var dialog = load("res://Scene/Dialog.tscn").instance()
		#dialog.get_child(0).set_texture(load(card["image"]))
		dialog.get_node("dialog_base").get_node("Area2D").set_card(card)
		get_tree().get_root().get_node("Node2D/DialogPosition").add_child(dialog)


remote func remote_on_card_drawn(card):
	_on_card_drawn(card)
	emit_signal("card_drawn", card)

remote func pre_start_game():
	# Change scene
	var world = load("res://Scene/GameScreen.tscn").instance()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("lobby").hide()

	progress_bar = get_tree().get_root().get_node("Node2D/TextureProgress")
	background_video = get_tree().get_root().get_node("Node2D/VideoPlayer")
	get_tree().get_root().get_node("Node2D/player_logo").set_texture(load("res://Assets/player_"+ player_name +"_logo.png"))
	_connect_to_action_buttons()
	_setup_and_start_timer()
	
	_generate_map(board_length, board_height)

	get_tree().get_root().get_node("/root/GameState").connect("card_drawn",self, "_on_card_drawn")

	if (not get_tree().is_network_server()):
		# Tell server we are ready to start
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
		
	elif GameState.players.size() == 0:
		post_start_game()

remote func post_start_game():
	print("post_start_game")
	get_tree().set_pause(false) # Unpause and unleash the game!

var players_ready = []

remote func ready_to_start(id):
	assert(get_tree().is_network_server())
	if (not id in GameState.players_ready):
		players_ready.append(id)

	if (GameState.players_ready.size() == GameState.players.size()):
		for p in GameState.players:
			rpc_id(p, "post_start_game")
		post_start_game()

func begin_game():
	assert(get_tree().is_network_server())
	for p in GameState.players:
		print("player: ", GameState.players[p])
		rpc_id(p, "pre_start_game")
	pre_start_game()

func end_game():
	if (has_node("/root/world")): # Game is in progress
		# End it
		get_node("/root/world").queue_free()
	emit_signal("game_ended")
	GameState.players.clear()
	get_tree().set_network_peer(null) # End networking

func _generate_map(board_width, board_height):
	hand_pos = self.get_tree().get_root().get_node("Node2D/HandPosition")
	hand_node = hand.instance()
	hand_pos.add_child(hand_node)
	
	active_effects_pos = self.get_tree().get_root().get_node("Node2D/EffectsPosition")
	active_effects_node = active_effects_scene.instance()
	active_effects_pos.add_child(active_effects_node)
	
	var ref_pos = self.get_tree().get_root().get_node("Node2D/Position2D").get_global_transform()
	var tile_width = 56
	var tile_height = 44
	var tile = load("res://Scene/Hex.tscn")
	var p1_marker = load("res://Assets/hex_player_1.png")
	var p2_marker = load("res://Assets/hex_player_2.png")
 	
	for y in range(0, board_height):
		for x in range(0, board_width):
			var tile_node = tile.instance()
			
			if y == 0: 
				if x == 0:
					tile_node.get_node("Sprite").set_texture(load("res://Assets/hex_grid_top_left.png"))
				elif x == board_length-1:
					tile_node.get_node("Sprite").set_texture(load("res://Assets/hex_grid_top_right.png"))
				else:
					tile_node.get_node("Sprite").set_texture(load("res://Assets/hex_grid_top.png"))
			elif y == board_height - 1:
				if x == 0:
					tile_node.get_node("Sprite").set_texture(load("res://Assets/hex_grid_bottom_left.png"))
				elif x == board_length - 1:
					tile_node.get_node("Sprite").set_texture(load("res://Assets/hex_grid_bottom_right.png"))
				else:
					tile_node.get_node("Sprite").set_texture(load("res://Assets/hex_grid_bottom.png"))
			elif y > 0 and y < board_height:
				if x == 0 and y%2 != 0:
					tile_node.get_node("Sprite").set_texture(load("res://Assets/hex_grid_left.png"))
				elif x == board_length - 1 and y%2 == 0:
					tile_node.get_node("Sprite").set_texture(load("res://Assets/hex_grid_right.png"))
				
			if y%2 == 0:
				var tile_pos_even = ref_pos.translated((Vector2((x * tile_width + (tile_width/2)), (y * tile_height))))
				tile_node.translate(tile_pos_even.get_origin())
			else:
				var tile_pos_odd = ref_pos.translated((Vector2((x * tile_width), y * tile_height)))
				tile_node.translate(tile_pos_odd.get_origin())
			self.get_tree().get_root().get_node("Node2D/Position2D").add_child(tile_node)
			#Finally connect signals between the hex tiles and thie main GameScreen
			tile_node.get_child(0).get_child(0).connect("Computer_1_placed", self, "_on_computer_1_placed")
			tile_node.get_child(0).get_child(0).connect("Computer_2_placed", self, "_on_computer_2_placed")
			tile_node.get_child(0).get_child(0).connect("Server_placed", self, "_on_server_placed")
			
			tile_node.get_child(0).get_child(0).connect("High_placed", self, "_on_high_placed")
			tile_node.get_child(0).get_child(0).connect("Medium_placed", self, "_on_medium_placed")
			tile_node.get_child(0).get_child(0).connect("Low_placed", self, "_on_low_placed")
			
			tile_node.get_child(0).get_child(0).connect("hex_owner_changed",self,"_on_hex_owner_changed")
			tile_node.get_child(0).get_child(0).connect("hex_attack_changed",self,"_on_hex_attack_changed")
			tile_node.get_child(0).get_child(0).connect("hex_defense_changed",self,"_on_hex_defense_changed")
			tile_node.get_child(0).get_child(0).connect("hex_card_changed",self,"_on_hex_card_changed")
			#Disable the hex's until unit card is drawn
			tile_node.get_child(0).get_child(0).set_pickable(false)
	 #_draw_border()
	
func _connect_to_action_buttons():
	# Subscribe to the action buttons
	self.get_tree().get_root().get_node("Node2D/ActionButtons/Computer_1").connect("action_pressed",self,"_on_computer_1_pressed")
	self.get_tree().get_root().get_node("Node2D/ActionButtons/Computer_2").connect("action_pressed",self,"_on_computer_2_pressed")
	self.get_tree().get_root().get_node("Node2D/ActionButtons/Server").connect("action_pressed",self,"_on_server_pressed")
	self.get_tree().get_root().get_node("Node2D/ActionButtons/High").connect("action_pressed",self,"_on_high_pressed")
	self.get_tree().get_root().get_node("Node2D/ActionButtons/Medium").connect("action_pressed",self,"_on_medium_pressed")
	self.get_tree().get_root().get_node("Node2D/ActionButtons/Low").connect("action_pressed",self,"_on_low_pressed")

func _setup_and_start_timer():
	timer = self.get_tree().get_root().get_node("Node2D/Power_Timer")
	timer.set_wait_time(power_time)
	timer.start()
	#board_timer = get_tree().get_root().get_node("Node2D/Board_Update_Timer")
	#board_timer.set_wait_time(board_update_time)
	#board_timer.start()

func _on_computer_1_pressed( arg1 ):
	_set_hex_pickable(true)

func _on_computer_2_pressed( arg1 ):
	_set_hex_pickable(true)

func _on_server_pressed( arg1 ):
	_set_hex_pickable(true)

func _on_high_pressed( arg1 ):
	draw_card(high_deck, get_tree().get_network_unique_id())
	timer.stop()

func _on_medium_pressed( arg1 ):
	draw_card(medium_deck, get_tree().get_network_unique_id())
	timer.stop()
	
func _on_low_pressed( arg1 ):
	draw_card(low_deck, get_tree().get_network_unique_id())
	timer.stop()

func _on_effect_placed(r_id, r_card):
	set_info(" local " + r_card["name"] +" : "+ r_card["type"])
	rpc("set_info", r_card["name"] +" : "+ r_card["type"])
	
	if r_card["effects"]["target"] == "local":
		set_effect(r_id, r_card)
	elif r_card["effects"]["target"] == "remote":
		rpc("add_effect", r_id, r_card)
	elif r_card["effects"]["target"] == "all":
		set_effect(r_id, r_card)
		rpc("add_effect", r_id, r_card)
	timer.start()

remote func set_effect(r_id, r_card):
	var active_effect = {}
	if r_card["effects"].has("duration"):
		# Add card, duration timer and name of the node to the effect object. 
		# Node name and effect name are the same for finding and deletion of node later
		active_effect.card = r_card
		active_effect.effect_duration = get_timer(int(r_card["effects"]["duration"]), true)
		active_effect.name = "effect_duration_" + str(active_effect.effect_duration.get_instance_id())
		active_effect.effect_duration.set_name(active_effect.name)
		add_child(active_effect.effect_duration)
	
	if r_card["effects"]["type"] == "timer":
		if r_card["effects"]["operator"] == "-":
			if power_time - r_card["effects"]["value"] > 0:
				power_time = power_time - r_card["effects"]["value"]
			else:
				power_time = 10
		elif r_card["effects"]["operator"] == "+":
			power_time = power_time + r_card["effects"]["value"]
		timer.stop()
		timer.set_wait_time(power_time)
		timer.start()
		
	# effect for drawing/removing a specific unit card
	elif r_card["effects"]["type"] == "unit":
		if r_card["effects"]["operator"] == "-":
			pass
		elif r_card["effects"]["operator"] == "+":
			get_card(r_card["effects"]["value"])
	# effect for adding/removing computers or server
	elif r_card["effects"]["type"] == "computers":
		pass
	
	active_effects.append(active_effect)

# Return a card 
func get_card(card_name):
	for d in decks:
		if not d.ends_with("card"):
			for card in decks[d]:
				if card_name == decks[d][card]["name"]:
					return(decks[d][card])
	return null

# Return a started timer
func get_timer(wait_time, one_shot = false):
	var t = Timer.new()
	t.set_wait_time(wait_time)
	if one_shot:
		t.set_one_shot(true)
	t.start()
	return t

remote func set_info(text):
	if get_tree().get_root().get_node("Node2D/InfoText") :
		get_tree().get_root().get_node("Node2D/InfoText").set_bbcode("[center]"+ text +"[/center]")

func _on_computer_1_placed(arg1):
	emit_signal("Computer_1_placed")
	power_time = power_time - 12
	timer.stop()
	timer.set_wait_time(power_time)
	_set_hex_pickable(false)
	timer.start()

func _on_computer_2_placed(arg1):
	emit_signal("Computer_2_placed")
	power_time = power_time - 12
	timer.stop()
	timer.set_wait_time(power_time)
	_set_hex_pickable(false)
	timer.start()

func _on_server_placed(arg1):
	emit_signal("Server_placed")
	power_time = power_time - 28
	timer.stop()
	timer.set_wait_time(power_time)
	_set_hex_pickable(false)
	timer.start()

func _on_high_placed(arg1):
	emit_signal("High_placed")
	_set_hex_pickable(false)
	timer.start()

func _on_medium_placed(arg1):
	emit_signal("Medium_placed")
	_set_hex_pickable(false)
	timer.start()

func _on_low_placed(arg1):
	emit_signal("Low_placed")
	_set_hex_pickable(false)
	timer.start()

func _set_hex_pickable( arg ):
	for c in get_tree().get_root().get_node("Node2D/Position2D").get_children():
		if c.get_child(0).has_node("Area2D"):
			c.get_child(0).get_child(0).set_pickable(arg)
