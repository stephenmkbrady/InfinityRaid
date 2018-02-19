extends Node2D

var timer
var progress_bar

signal action_placed
signal computer_1_placed
signal computer_2_placed
signal server_placed
signal high_placed
signal medium_placed
signal low_placed
signal special_placed

func _ready():
	progress_bar = get_node("TextureProgress")
	_connect_to_action_buttons()
	_setup_and_start_timer()
	_generate_map(GameState.board_length, GameState.board_height)

func _process(delta):
	progress_bar.set_value(GameState.power_time - int(timer.time_left))

func _on_computer_1_pressed( arg1 ):
	_set_hex_pickable(true)
func _on_computer_2_pressed( arg1 ):
	_set_hex_pickable(true)
func _on_server_pressed( arg1 ):
	_set_hex_pickable(true)

func _on_high_pressed( arg1 ):
	timer.stop()

func _on_medium_pressed( arg1 ):
	timer.stop()
	
func _on_low_pressed( arg1 ):
	timer.stop()

func _on_special_pressed( arg1 ):
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
	
func _on_card_drawn(card):
	print("card: ", card)
	if card.has("image"):
		var dialog = load("res://Scene/Dialog.tscn").instance()
		dialog.get_child(0).set_texture(load(card["image"]))
		get_tree().get_root().get_node("Node2D/DialogPosition").add_child(dialog)

func _generate_map(board_width, board_height):
	var ref_pos = get_node("Position2D").get_global_transform()
	var tile_width = 400*0.2
	var tile_height = 300*0.2
	#TODO: get rid of these
	var y_offset = -7
	var x_offset = -3
	var tile = load("res://Scene/Hex.tscn")
	var p1_marker = load("res://Assets/hex_player_1.png")
	var p2_marker = load("res://Assets/hex_player_2.png")
	
	for y in range(0, board_height):
		for x in range(0, board_width):
			var tile_node = tile.instance()
			#var player_node = Node2D.new()
			#var p1_sprite = Sprite.new()
			#var p2_sprite = Sprite.new()

			#p1_sprite.set_texture(p1_marker)
			#p1_sprite.set_scale(Vector2(0.2,0.2))
			#p2_sprite.set_texture(p2_marker)
			#p2_sprite.set_scale(Vector2(0.2,0.2))
			
			if x < ((board_width/2) ):
				#player_node.add_child(p1_sprite)
				tile_node.get_child(0).get_child(0).set_hex_owner(GameState.player_name)
			else:
				#player_node.add_child(p2_sprite)
				tile_node.get_child(0).get_child(0).set_hex_owner(GameState.opponent_name)
			# Every second row is offset again by half the tile width to form hex pattern
			if y%2 == 0:
				var tile_pos_even = ref_pos.translated((Vector2((x * tile_width + (tile_width/2)), (y * tile_height))))
				tile_node.global_translate(tile_pos_even.get_origin())
			else:
				var tile_pos_odd = ref_pos.translated((Vector2((x * tile_width), y * tile_height)))
				tile_node.global_translate(tile_pos_odd.get_origin())
			#tile_node.add_child(player_node)
			get_node("Position2D").add_child(tile_node)
			
			#Finally connect signals between the hex tiles and thie main GameScreen
			tile_node.get_child(0).get_child(0).connect("computer_1_placed", self, "_on_computer_1_placed")
			tile_node.get_child(0).get_child(0).connect("computer_2_placed", self, "_on_computer_2_placed")
			tile_node.get_child(0).get_child(0).connect("server_placed", self, "_on_server_placed")
			
			tile_node.get_child(0).get_child(0).connect("high_placed", self, "_on_high_placed")
			tile_node.get_child(0).get_child(0).connect("medium_placed", self, "_on_medium_placed")
			tile_node.get_child(0).get_child(0).connect("low_placed", self, "_on_low_placed")
			tile_node.get_child(0).get_child(0).connect("special_placed", self, "_on_special_placed")
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

func _setup_and_start_timer():
	timer = get_node("Power_Timer")
	timer.set_wait_time(GameState.power_time)
	timer.start()

func _set_hex_pickable( arg ):
	for c in get_tree().get_root().get_node("Node2D/Position2D").get_children():
		if c.get_child(0).has_node("Area2D"):
			c.get_child(0).get_child(0).set_pickable(arg)
