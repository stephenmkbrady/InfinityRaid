extends Node2D
var action
var default_tex = load("res://Assets/hex_empty.png")
signal action_pressed()
signal card_drawn()

var hand = []
func _ready():
	for node in self.get_tree().get_root().get_node("Node2D/ActionButtons").get_children():
		node.connect("action_pressed",self,"_on_action_pressed")

func _process(delta):
	pass
	
func add_card(card):
	if hand.size() <= 7:
		hand.append(card)
		refresh_hand()
	else:
		GameState.set_debug_info(str("hand is full"))
	
func remove_from_hand(idx):
	GameState.set_debug_info(str(hand))
	hand.remove(idx)
	refresh_hand()
	GameState.set_debug_info(str(hand))
func find_in_hand(item):
	pass
func set_hand(arr):
	hand = arr
func get_hand():
	return hand

func refresh_hand():
	var i = 0
	# Reset the texture button and remove the block indicators
	for n in get_children():
		if n.get_name() != "Label" or n.get_name().find("Label") == -1:
			n.get_child(0).set_disabled(true)
			n.get_child(0).set_normal_texture(default_tex)
			for c in n.get_child(0).get_children():
				if c.get_name() == "indicator" or c.get_name().find("indicator") != -1:
					c.queue_free()

	for c in hand:
		if i <= 6:
			get_node(str(i)).get_node(str(i)).set_normal_texture(load(c.tile))
			var indicator = load("res://Scene/StatusIndicator.tscn").instance()
			indicator.get_node("def").set_text(str(c["attack"]))
			indicator.get_node("atk").set_text(str(c["defense"]))
			indicator.set_scale(Vector2(6.6,6.6))
			indicator.translate(Vector2(180,180))
			get_node(str(i)).get_node(str(i)).add_child(indicator)
			if get_node(str(i)).get_node(str(i)).is_disabled():
				get_node(str(i)).get_node(str(i)).set_disabled(false)
		i = i + 1
				
				
func _on_action_pressed(arg):
	action = arg

func _on_0_pressed():
	set_cursor_enable_hex_tiles(0)
func _on_1_pressed():
	set_cursor_enable_hex_tiles(1)
func _on_2_pressed():
	set_cursor_enable_hex_tiles(2)
func _on_3_pressed():
	set_cursor_enable_hex_tiles(3)
func _on_4_pressed():
	set_cursor_enable_hex_tiles(4)
func _on_5_pressed():
	set_cursor_enable_hex_tiles(5)
func _on_6_pressed():
	set_cursor_enable_hex_tiles(6)

func set_cursor_enable_hex_tiles(num):
	emit_signal("card_drawn", hand[num])
	emit_signal("action_pressed", hand[num].level)
	Input.set_custom_mouse_cursor(load("res://Assets/hex_action_mouse.png"))
	remove_from_hand(num)
	for c in get_tree().get_root().get_node("Node2D/Position2D").get_children():
		if c.get_child(0).has_node("Area2D"):
			c.get_child(0).get_child(0).set_pickable(true)