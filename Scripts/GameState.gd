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

var hand = load("res://Scene/hand.tscn")
var hand_pos
var hand_node

var active_effects_scene = load("res://Scene/ActiveEffects.tscn")
var active_effects_pos
var active_effects_node

var particle_scene = load("res://Scene/Particle.tscn")
var particle_pos 
var particle_node
var particle_pos_target = Vector2(0,0)
var p_marker
var card
var active_effects = []

signal card_drawn()
signal deck_empty()
signal game_ended()
signal game_error(what)

var background_video 
var timer
var progress_bar
var score_bar
var score = 0
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
			get_node(e["name"]).queue_free()
			if e["card"]["effects"]["type"] == "timer":
				power_time = power_time + e["card"]["effects"]["value"]
				timer.set_wait_time(power_time)
				progress_bar.set_max(power_time)
			elif e["card"]["effects"]["type"] == "unit":
				pass
			active_effects.remove(active_effects.find(e))

	if timer != null:
		set_info(str(timer.wait_time) + " : "+ str(timer.get_time_left()))
		active_effects_node.set_active_effects()
		update_locations(delta)

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
		randomize()
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
		dialog.get_node("dialog_base").get_node("Area2D").set_card(card)
		get_tree().get_root().get_node("Node2D/DialogPosition").add_child(dialog)


remote func remote_on_card_drawn(card):
	emit_signal("card_drawn", card)

remote func pre_start_game():
	# Change scene
	var world = load("res://Scene/GameScreen.tscn").instance()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("lobby").hide()
	progress_bar = get_tree().get_root().get_node("Node2D/TextureProgress")
	score_bar = get_tree().get_root().get_node("Node2D/score_bar")
	#score_bar.set_max(1600)
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
	
	particle_pos = self.get_tree().get_root().get_node("Node2D/particle")
	particle_pos_target = particle_pos.get_global_transform().get_origin()
	particle_node = particle_scene.instance()
	particle_pos.add_child(particle_node)
	
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
	progress_bar.set_max(power_time)
	timer.start()

func _on_computer_1_pressed( arg1 ):
	_set_hex_pickable(true)

func _on_computer_2_pressed( arg1 ):
	_set_hex_pickable(true)

func _on_server_pressed( arg1 ):
	_set_hex_pickable(true)

func _on_high_pressed( arg1 ):
	draw_card(high_deck, get_tree().get_network_unique_id())
	#timer.stop()

func _on_medium_pressed( arg1 ):
	draw_card(medium_deck, get_tree().get_network_unique_id())
	#timer.stop()
	
func _on_low_pressed( arg1 ):
	draw_card(low_deck, get_tree().get_network_unique_id())
	#timer.stop()

func _on_effect_placed(r_id, r_card):
	set_info(" local " + r_card["name"] +" : "+ r_card["type"])
	rpc("set_info", r_card["name"] +" : "+ r_card["type"])
	
	if r_card["effects"]["target"] == "local":
		set_effect(r_id, r_card)
	elif r_card["effects"]["target"] == "remote":
		rpc("set_effect", r_id, r_card)
	elif r_card["effects"]["target"] == "all":
		set_effect(r_id, r_card)
		rpc("set_effect", r_id, r_card)

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
		progress_bar.set_max(power_time)
		timer.start()
		
	# effect for drawing/removing a specific unit card
	elif r_card["effects"]["type"] == "unit":
		if r_card["effects"]["operator"] == "-":
			remove_card_in_play(get_card(r_card["effects"]["value"]))
		elif r_card["effects"]["operator"] == "+":
			print("secondary card: ", str(get_card(r_card["effects"]["value"])))
			emit_signal("card_drawn", get_card(r_card["effects"]["value"]))
	# effect for adding/removing computers or server
	elif r_card["effects"]["type"] == "computers":
		pass
	
	active_effects.append(active_effect)

# Find and remove all cards matching
func remove_card_in_play(r_card):
	var i = 0
	for c in hand_node.get_hand():
		if c["name"] == r_card["name"]:
			hand_node.remove_from_hand(i)
		i = i + 1
	
	i = 0
	for c in self.get_tree().get_root().get_node("Node2D/Position2D").get_children():
		var hex_contents = c.get_child(0).get_child(0).get_hex_contents()
		if hex_contents.has("hex_card") and hex_contents["hex_card"] != null:
			if hex_contents["hex_card"]["name"] == r_card["name"]:
				c.get_child(0).get_child(0).kill_hex(self.get_tree().get_root().get_node('Node2D/Position2D').get_child(i).get_node("Sprite/Area2D"))
		i = i + 1
	
# Return a card from the decks using the name
func get_card(card_name):
	var c = null
	for d in decks:
		if not d.ends_with("card"):
			for card in decks[d]:
				print("card)) ",card_name," : ", decks[d][card]["name"])
				if card_name == decks[d][card]["name"]:
					print("found card: ", card, " : ", decks[d][card]["name"])
					c = decks[d][card]
	return(c)

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
	update_score(10)
	power_time = power_time - 12
	timer.stop()
	timer.set_wait_time(power_time)
	progress_bar.set_max(power_time)
	_set_hex_pickable(false)
	timer.start()

func _on_computer_2_placed(arg1):
	emit_signal("Computer_2_placed")
	update_score(10)
	power_time = power_time - 12
	timer.stop()
	timer.set_wait_time(power_time)
	progress_bar.set_max(power_time)
	_set_hex_pickable(false)
	timer.start()

func _on_server_placed(arg1):
	emit_signal("Server_placed")
	update_score(20)
	power_time = power_time - 28
	timer.stop()
	timer.set_wait_time(power_time)
	progress_bar.set_max(power_time)
	_set_hex_pickable(false)
	timer.start()

func _on_high_placed(arg1):
	emit_signal("High_placed")
	update_score(20)
	_set_hex_pickable(false)
	if timer.is_stopped():
		timer.start()

func _on_medium_placed(arg1):
	emit_signal("Medium_placed")
	update_score(20)
	_set_hex_pickable(false)
	if timer.is_stopped():
		timer.start()
		
func _on_low_placed(arg1):
	emit_signal("Low_placed")
	update_score(20)
	_set_hex_pickable(false)
	if timer.is_stopped():
		timer.start()

func update_score(val):
	score = score + val
	print("score: ",str(score), " - ",str(particle_pos_target.x + score))
	particle_pos_target = particle_pos_target + Vector2(score, 0)
	
func update_locations(delta):
	var speed = 80
	if int(particle_pos.get_global_transform().get_origin().x) != int(particle_pos_target.x):
		particle_node.get_child(0).set_emitting(true)
		print("pos: ", str(particle_pos.get_global_transform().get_origin().x), " : ", str(particle_pos_target.x))
		
		if int(particle_pos.get_global_transform().get_origin().x) < int(particle_pos_target.x):
			print("+set: ", str(score_bar.get_global_transform().get_origin() + Vector2(score_bar.get_size().x * score_bar.get_scale().x, 0) ))
			#particle_pos.translate(score_bar.get_global_transform().get_origin() + Vector2(score_bar.get_size().x * score_bar.get_scale().x, 0 ))
			score_bar.set_size(score_bar.get_size() + Vector2(speed*33*delta,0))
		elif int(particle_pos.get_global_transform().get_origin().x) > int(particle_pos_target.x):
			print("+set: ", str(score_bar.get_global_transform().get_origin() + Vector2(score_bar.get_size().x * score_bar.get_scale().x, 0) ))
			#particle_pos.translate(score_bar.get_global_transform().get_origin() + Vector2(score_bar.get_size().x * score_bar.get_scale().x, 0 ))
			#particle_pos.move_local_x(-speed * delta)
			score_bar.set_size(score_bar.get_size() + Vector2(-speed*33*delta,0))
		else:
			pass
	else:
		pass
		particle_node.get_child(0).set_emitting(false)

func _set_hex_pickable( arg ):
	for c in get_tree().get_root().get_node("Node2D/Position2D").get_children():
		if c.get_child(0).has_node("Area2D"):
			c.get_child(0).get_child(0).set_pickable(arg)
