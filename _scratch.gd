extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


#Describes the edges, corners and middle cells of the board
#Might need it for the AI
#Needs fixing as it takes N-board_length-1 which isn't surrounding N, N-board_length and N-board_length+1 are (I think)
#It needs testing
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
		print("L: ", self.get_parent().get_parent().get_parent().get_child(N - 1).get_node("Sprite/Area2D").get_hex_data())
		print("R: ", self.get_parent().get_parent().get_parent().get_child(N + 1).get_node("Sprite/Area2D").get_hex_data())
		print("B: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length).get_node("Sprite/Area2D").get_hex_data())
		print("T: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length).get_node("Sprite/Area2D").get_hex_data())
		print("TL: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length-1).get_node("Sprite/Area2D").get_hex_data())
		print("TR: ", self.get_parent().get_parent().get_parent().get_child(N - GameState.board_length+1).get_node("Sprite/Area2D").get_hex_data())
		print("BR: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length+1).get_node("Sprite/Area2D").get_hex_data())
		print("BL: ", self.get_parent().get_parent().get_parent().get_child(N + GameState.board_length-1).get_node("Sprite/Area2D").get_hex_data())
