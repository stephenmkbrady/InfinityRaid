extends Node

var high_deck # Strong computers and daemons with secondary effects
var medium_deck # Strong computers and daemons
var low_deck # Average computers and daemons
var computer_1_card
var computer_2_card
var server_card

var player_name = "1"

# Names for remote players in id:name format
var players = {}

var board_update_time = 5
var power_time = 90 #30 (30 15 15)
var board_height = 10
var board_length = 12
var board_cell_count = 88
var green_indicator = load("res://Scene/StatusIndicator.tscn")
var yellow_indicator = load("res://Scene/StatusIndicator.tscn")
var red_indicator = load("res://Scene/StatusIndicator.tscn")
var p_marker
var card

signal card_drawn()
signal deck_empty()
signal game_ended()
signal game_error(what)

var background_video 
var timer
var board_timer
var progress_bar
signal action_placed()
signal computer_1_placed()
signal computer_2_placed()
signal server_placed()
signal high_placed()
signal medium_placed()
signal low_placed()

func _ready():
	randomize()
	var decks = {}
	var file = File.new()
	file.open("res://Assets/Deck/Deck.json", file.READ)
	var text = file.get_as_text()
	decks = JSON.parse(text).result
	file.close()
	
	high_deck = decks["high_deck"]
	medium_deck = decks["medium_deck"]
	low_deck = decks["low_deck"]
	computer_1_card = decks["computer_1_card"]
	computer_2_card = decks["computer_2_card"]
	server_card = decks["server_card"]

func _process(delta):
	if timer != null:
		progress_bar.set_value(power_time - int(timer.time_left))
	if background_video != null and not background_video.is_playing():
		background_video.play()

func get_player_list():
	return players.values()

func get_player_name():
	return player_name

func get_player_marker(name):
	return load("res://Assets/hex_player_"+name+".png")
	
func get_strength_indicator(atk, def):
	var indicator
	if atk >= 2:
		indicator = green_indicator.instance()
	elif atk == 1:
		indicator = yellow_indicator.instance()
		indicator.get_child(0).set_texture(load("res://Assets/hex_barcode_green_2.png"))
	elif atk == 0:
		indicator = red_indicator.instance()
		indicator.get_child(0).set_texture(load("res://Assets/hex_barcode_green_1.png"))
	return indicator

func _on_player_name_changed ( new_name ):
	player_name = new_name

remote func _draw_card( deck, r_id ):
	if (get_tree().is_network_server()):
		var r = str(randi() % deck.size() + 1)
		if deck.has(r):
			if r_id != 1:
				print("remote_on_card_drawn")
				rpc_id(r_id, "remote_on_card_drawn", deck[r])
			else:
				emit_signal("card_drawn", deck[r])
			deck.erase(r)
		else:
			print("implement empty deck condition")
			emit_signal("deck_empty")
	else:
		rpc_id(1,'_draw_card', deck, r_id)

func _on_card_drawn(card):
	print("card: ", card["tile"])
	if card.has("image"):
		var dialog = load("res://Scene/Dialog.tscn").instance()
		dialog.get_child(0).set_texture(load(card["image"]))
		get_tree().get_root().get_node("Node2D/DialogPosition").add_child(dialog)
		
remote func remote_on_card_drawn(card):
	print("card_remote: ", card["tile"])
	if card.has("image"):
		var dialog = load("res://Scene/Dialog.tscn").instance()
		dialog.get_child(0).set_texture(load(card["image"]))
		get_tree().get_root().get_node("Node2D/DialogPosition").add_child(dialog)
		emit_signal("card_drawn", card)

remote func pre_start_game():
	# Change scene
	var world = load("res://Scene/GameScreen.tscn").instance()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("lobby").hide()

	progress_bar = get_tree().get_root().get_node("Node2D/ActionButtons/TextureProgress")
	background_video = get_tree().get_root().get_node("Node2D/VideoPlayer")
	background_video.play()

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
	var ref_pos = self.get_tree().get_root().get_node("Node2D/Position2D").get_global_transform()
	var tile_width = 77
	var tile_height = 58
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
				tile_node.global_translate(tile_pos_even.get_origin())
			else:
				var tile_pos_odd = ref_pos.translated((Vector2((x * tile_width), y * tile_height)))
				tile_node.global_translate(tile_pos_odd.get_origin())
			self.get_tree().get_root().get_node("Node2D/Position2D").add_child(tile_node)
			#Finally connect signals between the hex tiles and thie main GameScreen
			tile_node.get_child(0).get_child(0).connect("computer_1_placed", self, "_on_computer_1_placed")
			tile_node.get_child(0).get_child(0).connect("computer_2_placed", self, "_on_computer_2_placed")
			tile_node.get_child(0).get_child(0).connect("server_placed", self, "_on_server_placed")
			
			tile_node.get_child(0).get_child(0).connect("high_placed", self, "_on_high_placed")
			tile_node.get_child(0).get_child(0).connect("medium_placed", self, "_on_medium_placed")
			tile_node.get_child(0).get_child(0).connect("low_placed", self, "_on_low_placed")
			#tile_node.get_child(0).get_child(0).connect("special_placed", self, "_on_special_placed")
			
			tile_node.get_child(0).get_child(0).connect("hex_owner_changed",self,"_on_hex_owner_changed")
			tile_node.get_child(0).get_child(0).connect("hex_attack_changed",self,"_on_hex_attack_changed")
			tile_node.get_child(0).get_child(0).connect("hex_defense_changed",self,"_on_hex_defense_changed")
			tile_node.get_child(0).get_child(0).connect("hex_card_changed",self,"_on_hex_card_changed")
			#Disable the hex's until unit card is drawn
			tile_node.get_child(0).get_child(0).set_pickable(false)
	 #_draw_border()
	
func _connect_to_action_buttons():
	# Subscribe to the action buttons
	self.get_tree().get_root().get_node("Node2D/Computer_1").connect("action_pressed",self,"_on_computer_1_pressed")
	self.get_tree().get_root().get_node("Node2D/Computer_2").connect("action_pressed",self,"_on_computer_2_pressed")
	self.get_tree().get_root().get_node("Node2D/Server").connect("action_pressed",self,"_on_server_pressed")
	self.get_tree().get_root().get_node("Node2D/ActionButtons/High").connect("action_pressed",self,"_on_high_pressed")
	self.get_tree().get_root().get_node("Node2D/ActionButtons/Medium").connect("action_pressed",self,"_on_medium_pressed")
	self.get_tree().get_root().get_node("Node2D/ActionButtons/Low").connect("action_pressed",self,"_on_low_pressed")
	#self.get_tree().get_root().get_node("Node2D/Special").connect("action_pressed",self,"_on_special_pressed")
	pass

func _setup_and_start_timer():
	timer = self.get_tree().get_root().get_node("Node2D/Power_Timer")
	timer.set_wait_time(power_time)
	timer.start()
	board_timer = get_tree().get_root().get_node("Node2D/Board_Update_Timer")
	board_timer.set_wait_time(board_update_time)
	board_timer.start()

func _on_computer_1_pressed( arg1 ):
	_set_hex_pickable(true)

func _on_computer_2_pressed( arg1 ):
	_set_hex_pickable(true)

func _on_server_pressed( arg1 ):
	_set_hex_pickable(true)

func _on_high_pressed( arg1 ):
	_draw_card(high_deck, get_tree().get_network_unique_id())
	timer.stop()

func _on_medium_pressed( arg1 ):
	_draw_card(medium_deck, get_tree().get_network_unique_id())
	timer.stop()
	
func _on_low_pressed( arg1 ):
	_draw_card(low_deck, get_tree().get_network_unique_id())
	timer.stop()

func _on_computer_1_placed(arg1):
	emit_signal("computer_1_placed")
	power_time = power_time - 15
	_set_hex_pickable(false)

func _on_computer_2_placed(arg1):
	emit_signal("computer_2_placed")
	power_time = power_time - 15
	_set_hex_pickable(false)

func _on_server_placed(arg1):
	emit_signal("server_placed")
	power_time = power_time - 30
	_set_hex_pickable(false)

func _on_high_placed(arg1):
	emit_signal("high_placed")
	_set_hex_pickable(false)
	timer.start()

func _on_medium_placed(arg1):
	emit_signal("medium_placed")
	_set_hex_pickable(false)
	timer.start()

func _on_low_placed(arg1):
	emit_signal("low_placed")
	_set_hex_pickable(false)
	timer.start()

func _set_hex_pickable( arg ):
	for c in get_tree().get_root().get_node("Node2D/Position2D").get_children():
		if c.get_child(0).has_node("Area2D"):
			c.get_child(0).get_child(0).set_pickable(arg)
