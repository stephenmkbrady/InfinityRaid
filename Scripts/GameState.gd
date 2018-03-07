extends Node

var high_deck # Strong computers and daemons with secondary effects
var medium_deck # Strong computers and daemons
var low_deck # Average computers and daemons
var special_deck # Daemons with good or bad effects, gamble
var computer_1_card
var computer_2_card
var server_card

var player_name = "1"

# Names for remote players in id:name format
var players = {}

var board_update_time = 5
var power_time = 30 
var board_height = 8
var board_length = 11
var board_cell_count = 88
var green_indicator = load("res://Scene/Gem.tscn")
var yellow_indicator = load("res://Scene/Gem.tscn")
var red_indicator = load("res://Scene/Gem.tscn")
var p_marker
var card

signal card_drawn()
signal deck_empty()
signal game_ended()
signal game_error(what)


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
signal special_placed()

func _ready():
	randomize()

	high_deck = {
	"1":
		{
			"type" : "computer",
			"name" : "Prophet Terry Davis",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc" : "Special ability: adds Temple unit",
			"seconday" : "computer",
			"attack" : 2,
			"defense" : 2
		},
	"2":
		{
			"type":"computer",
			"name":"The Supreme Gentleman",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"Special ability: adds Purifier effect",
			"seconday" : "daemon",
			"attack":2,
			"defense":2
		},
	"3":{
			"type":"computer",
			"name":"chrischan",
			"desc":"Special ability: adds Rosechu 2 turns later via cwcville daemon",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"seconday" : "daemon",
			"attack":2,
			"defense":2
		}
	}
	medium_deck = { 
	"1":
		{
			"type" : "computer",
			"name" : "a real human bean",
			"desc" : "... and a real hero",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"attack":2,
			"defense":2
		},
	"2":
		{
			"type":"computer",
			"name":"foreign hordes",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"",
			"attack":3,
			"defense":2
		},
	"3":{
			"type":"computer",
			"name":"Lolcow",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"",
			"attack":2,
			"defense":2
		},
	"4":{
			"type":"computer",
			"name":"Temple OS",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"",
			"attack":2,
			"defense":2
		},
	"5":{
			"type":"computer",
			"name":"trolls",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"",
			"attack":2,
			"defense":2
		},
	"6":{
			"type":"computer",
			"name":"rosechu",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"",
			"attack":2,
			"defense":2
		}
	}
	low_deck = {
	"1":
		{
			"type" : "computer",
			"name" : "mod",
			"desc" : "... he does it for free",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"attack":3,
			"defense":2
		},
		
	"2":
		{
			"type":"computer",
			"name":"sperg",
			"desc":"REEEEEEE",
			"tile":"res://Assets/Deck/Hex_Sperg.png",
			"image":"res://Assets/Deck/Dialog_Sperg.png",
			"attack":3,
			"defense":2
		},
	"3":{
			"type":"computer",
			"name":"The merchant",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"... cries out as it strikes you",
			"attack":3,
			"defense":2
		},
	"4":{
			"type":"computer",
			"name":"anon",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"... is not your personal army",
			"attack":3,
			"defense":2
		},
	"5":{
			"type":"computer",
			"name":"OP",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"... is a fag",
			"attack":3,
			"defense":2
		},
	"6":{
			"type":"computer",
			"name":"Evazephon of Yandere",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"description":"Stop sending me mail!",
			"attack":3,
			"defense":2
		}
	}
	special_deck = {
	"1":
		{
			"type" : "daemon",
			"name" : "The fringe wizard's smile",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc" : "Reduces defense on all computers for 2 turns"
		},
	"2":
		{
			"type":"daemon",
			"name":"Academics, please respond!?",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"Reduces attack on all computers to 0 for 2 turns"
		},
	"3":{
			"type":"daemon",
			"name":"Magical realm of the gypsy",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"Consumes enemy unit, remove enemy computer of your choice"
		},
	"4":{
			"type":"daemon",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"name":"This is ribrary!",
			"desc":""
		}
	}
	computer_1_card = { 
			"type" : "computer",
			"name" : "Linux_box",
			"tile":"res://Assets/hex_computer_1.png",
			"desc" : "",
			"attack" : 5,
			"defense" : 5
	}
	computer_2_card = { 
			"type" : "computer",
			"name" : "Linux_box_2",
			"tile":"res://Assets/hex_computer_2.png",
			"desc" : "",
			"attack" : 5,
			"defense" : 5
	}
	server_card = { 
			"type" : "computer",
			"name" : "Server",
			"tile":"res://Assets/hex_server.png",
			"desc" : "",
			"attack" : 10,
			"defense" : 5
	}
func _process(delta):
	if timer != null:
		progress_bar.set_value(power_time - int(timer.time_left))
	
func get_player_list():
	return players.values()

func get_player_name():
	return player_name

func get_player_marker(name):
	return load("res://Assets/hex_player_"+name+".png")
	
func get_strength_indicator(value):
	var indicator
	if value >= 2:
		indicator = green_indicator.instance()
	elif value == 1:
		indicator = yellow_indicator.instance()
		indicator.get_child(0).set_texture(load("res://Assets/hex_gem_yellow_simple.png"))
	elif value == 0:
		indicator = red_indicator.instance()
		indicator.get_child(0).set_texture(load("res://Assets/hex_gem_red_simple.png"))
	return indicator

func _on_player_name_changed ( new_name ):
	player_name = new_name

remote func _draw_card( deck, r_id ):
	if (get_tree().is_network_server()):
		var r = str(randi() % deck.size() + 1)
		if deck.has(r):
			if r_id != 1:
				rpc_id(r_id, "_on_card_drawn", deck[r])
			else:
				emit_signal("card_drawn", deck[r])
			deck.erase(r)
		else:
			emit_signal("deck_empty")
	else:
		rpc_id(1,'_draw_card', deck, r_id)

# Not using this yet
func _check_board(board_length, board_height):
	# Describes the edges and corners and center hexes of the board.
	var row = 0
	for c in get_tree().get_root().get_node("Node2D/Position2D").get_children():
		var N = c.get_position_in_parent()
		if (N < board_length - 1 and N > 0): # Top, not including corners: N<length-1, N>0
			print("Top: ",N)
			pass # Check N-1, N+1, N+length-1, N+length+1, N+length
		elif (N < ( (board_length * board_height) - 1) and N > (board_length* board_height)-board_length): #Bottom
			print("Bottom: ",N)
			pass # Check N-1, N+1, N-length-1, N-length+1, N-length
		elif (N == 0): # Corner top left
			print("TL Corner: ",N)
			pass # Check N+1, N+lenght, N+length+1
		elif (N == board_length - 1): # Corner top right 
			print("TR Corner: ",N) #10
			pass # Check N -1, N+length, N+length -1
		elif (N == ((board_length * board_height) - board_length )): # Corner bottom left #77
			print("BL Corner: ",N)
			pass # Check N+1, N-lenght, N-length+1
		elif (N == (board_length * board_height ) -1 ): # Corner bottom right #87
			print("BR Corner: ",N)
			pass # Check N-1, N-lenght, N-length-1
		elif ((board_length * row) % N == 0) :
			print("Left Edge: ", N, " - ", board_length, " * ", row)
			print("Right Edge: ", N-1, " - ", board_length, " * ", row)
			#pass # Check N-1, N+length, N-length, N+length-1, N-length-1 
		else:
			print("I: ", N)
			pass
		if(N != 0 and (board_length * row) % N == 0):
			row = row + 1

remote func pre_start_game():
	# Change scene
	var world = load("res://Scene/GameScreen.tscn").instance()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("lobby").hide()

	progress_bar = get_tree().get_root().get_node("Node2D/TextureProgress")
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
	var tile_width = 80
	var tile_height = 60
	var tile = load("res://Scene/Hex.tscn")
	var p1_marker = load("res://Assets/hex_player_1.png")
	var p2_marker = load("res://Assets/hex_player_2.png")
	
	for y in range(0, board_height):
		for x in range(0, board_width):
			var tile_node = tile.instance()
			if x < ((board_width/2) ):
				tile_node.get_child(0).get_child(0).set_hex_owner("1", "1")
			else:
				tile_node.get_child(0).get_child(0).set_hex_owner("2", "2")
			# Every second row is offset again by half the tile width to form hex pattern
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
			tile_node.get_child(0).get_child(0).connect("special_placed", self, "_on_special_placed")
			
			tile_node.get_child(0).get_child(0).connect("hex_owner_changed",self,"_on_hex_owner_changed")
			tile_node.get_child(0).get_child(0).connect("hex_attack_changed",self,"_on_hex_attack_changed")
			tile_node.get_child(0).get_child(0).connect("hex_defense_changed",self,"_on_hex_defense_changed")
			tile_node.get_child(0).get_child(0).connect("hex_card_changed",self,"_on_hex_card_changed")
			#Disable the hex's until unit card is drawn
			tile_node.get_child(0).get_child(0).set_pickable(false)


func _connect_to_action_buttons():
	# Subscribe to the action buttons
	self.get_tree().get_root().get_node("Node2D/Computer_1").connect("action_pressed",self,"_on_computer_1_pressed")
	self.get_tree().get_root().get_node("Node2D/Computer_2").connect("action_pressed",self,"_on_computer_2_pressed")
	self.get_tree().get_root().get_node("Node2D/Server").connect("action_pressed",self,"_on_server_pressed")
	self.get_tree().get_root().get_node("Node2D/High").connect("action_pressed",self,"_on_high_pressed")
	self.get_tree().get_root().get_node("Node2D/Medium").connect("action_pressed",self,"_on_medium_pressed")
	self.get_tree().get_root().get_node("Node2D/Low").connect("action_pressed",self,"_on_low_pressed")
	self.get_tree().get_root().get_node("Node2D/Special").connect("action_pressed",self,"_on_special_pressed")
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

func _on_special_pressed( arg1 ):
	_draw_card(special_deck, get_tree().get_network_unique_id())
	timer.stop()

func _on_computer_1_placed(arg1):
	emit_signal("computer_1_placed")
	_set_hex_pickable(false)

func _on_computer_2_placed(arg1):
	emit_signal("computer_2_placed")
	_set_hex_pickable(false)

func _on_server_placed(arg1):
	emit_signal("server_placed")
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

func _on_special_placed(arg1):
	emit_signal("special_placed")
	_set_hex_pickable(false)
	timer.start()

func _on_hex_attack_changed():
	pass
func _on_hex_defense_changed():
	pass

#func _on_hex_card_changed(card, pos):
#	print("hex_card_changed: ", pos, " - ",card["name"])
#	for p in GameState.players:
#		print("pl: ", p)
#		rpc_id(p, "remote_update_hex_card", card, pos)
	#pass

#remote func remote_update_hex_card( card, pos):
#	print("remote_update_hex_card: ", pos, " - ",card["name"])
#	self.get_tree().get_root().get_node('Node2D/Position2D').get_child(pos).get_child(0).get_child(0).set_hex_card(get_tree().get_network_unique_id(), card)

#func _on_hex_owner_changed( id, pos ):
#	print("hex_owner_changed: ", id, " : ", pos)

remote func _on_card_drawn(card):
	print("card: ", card)
	if card.has("image"):
		var dialog = load("res://Scene/Dialog.tscn").instance()
		dialog.get_child(0).set_texture(load(card["image"]))
		get_tree().get_root().get_node("Node2D/DialogPosition").add_child(dialog)

func _set_hex_pickable( arg ):
	for c in get_tree().get_root().get_node("Node2D/Position2D").get_children():
		if c.get_child(0).has_node("Area2D"):
			c.get_child(0).get_child(0).set_pickable(arg)
