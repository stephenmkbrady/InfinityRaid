extends Node

var high_deck # Strong computers and daemons with secondary effects
var medium_deck # Strong computers and daemons
var low_deck # Average computers and daemons
var special_deck # Daemons with good or bad effects, gamble
var computer_1_card
var computer_2_card
var server_card

var player_name = "1"
var opponent_name = "2"
var board_update_time = 5
var power_time = 30 
var board_height = 8
var board_length = 11
var board_timer
# effect: butthurt/buttblasted

var card
signal card_drawn
signal deck_empty

func _ready():
	randomize()
	print("mod: ", (22%11))
	_setup_and_start_timer()
	self.get_tree().get_root().get_node("Node2D/High").connect("action_pressed",self,"_on_high_pressed")
	self.get_tree().get_root().get_node("Node2D/Medium").connect("action_pressed",self,"_on_medium_pressed")
	self.get_tree().get_root().get_node("Node2D/Low").connect("action_pressed",self,"_on_low_pressed")
	self.get_tree().get_root().get_node("Node2D/Special").connect("action_pressed",self,"_on_special_pressed")
	self.connect("card_drawn",self.get_tree().get_root().get_node("Node2D"), "_on_card_drawn")
	
	high_deck = {
	"1":
		{
			"type" : "computer",
			"name" : "Prophet Terry Davis",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc" : "Special ability: adds Temple unit",
			"seconday" : "computer",
			"attack" : 1,
			"defense" : 1
		},
	"2":
		{
			"type":"computer",
			"name":"The Supreme Gentleman",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"Special ability: adds Purifier effect",
			"seconday" : "daemon",
			"attack":1,
			"defense":1
		},
	"3":{
			"type":"computer",
			"name":"chrischan",
			"desc":"Special ability: adds Rosechu 2 turns later via cwcville daemon",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"seconday" : "daemon",
			"attack":1,
			"defense":1
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
			"attack":1,
			"defense":1
		},
	"2":
		{
			"type":"computer",
			"name":"foreign hordes",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"",
			"attack":3,
			"defense":1
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
			"attack":1,
			"defense":1
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
			"defense":1
		},
		
	"2":
		{
			"type":"computer",
			"name":"sperg",
			"desc":"REEEEEEE",
			"tile":"res://Assets/Deck/Hex_Sperg.png",
			"image":"res://Assets/Deck/Dialog_Sperg.png",
			"attack":3,
			"defense":1
		},
	"3":{
			"type":"computer",
			"name":"The merchant",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"... cries out as it strikes you",
			"attack":3,
			"defense":1
		},
	"4":{
			"type":"computer",
			"name":"anon",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"... is not your personal army",
			"attack":3,
			"defense":1
		},
	"5":{
			"type":"computer",
			"name":"OP",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"desc":"... is a fag",
			"attack":3,
			"defense":1
		},
	"6":{
			"type":"computer",
			"name":"Evazephon of Yandere",
			"tile":"res://Assets/Deck/Hex_Temple_OS.png",
			"image":"res://Assets/Deck/Dialog_Temple_OS.png",
			"description":"Stop sending me mail!",
			"attack":3,
			"defense":1
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
	if int(board_timer.time_left) == 0:
		#For each tile on the board, from left to right, top to bottom, update it's attack/defense/owner
		for tile in get_tree().get_root().get_node("Node2D/Position2D").get_children():
			pass
			

func _on_high_pressed( arg1 ):
	_draw_card(high_deck)
	pass

func _on_medium_pressed( arg1 ):
	_draw_card(medium_deck)
	pass

func _on_low_pressed( arg1 ):
	_draw_card(low_deck)
	pass

func _on_special_pressed( arg1 ):
	_draw_card(special_deck)
	pass
	
func _draw_card( deck ):
	var r = str(randi() % deck.size() + 1)
	if deck.has(r):
		emit_signal("card_drawn", deck[r])
		deck.erase(r)
	else:
		emit_signal("deck_empty")

func _setup_and_start_timer():
	board_timer = get_tree().get_root().get_node("Node2D/Board_Update_Timer")
	board_timer.set_wait_time(board_update_time)
	board_timer.start()

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
