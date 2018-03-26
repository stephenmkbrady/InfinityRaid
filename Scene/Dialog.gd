extends Area2D
var card
var timer
var inc = 0.1
signal effect_placed()
var opened = true
func _ready():
	inc = 0.1
	timer = self.get_tree().get_root().get_node("Node2D/Power_Timer")
	self.connect("input_event",self,"_on_Area2D_input_event")
	self.connect("effect_placed", get_tree().get_root().get_node("GameState"), "_on_effect_placed")
	get_parent().get_node("image").set_texture(load(card["image"]))
	var label_text = card["name"] + "\n" + card["type"] 
	if card["desc"] != "":
		label_text = label_text + "\nDescription: " + card["desc"] 
	if card["type"] == "computer":
		label_text = label_text + "\natk: " + str(card["attack"]) + "\ndef: " + str(card["defense"])
	get_parent().set_scale(Vector2(0.2,0.2))
	get_parent().get_node("Label").set_text(label_text)
func _process(delta):
	
	if opened and get_parent().get_scale().x <= 0.7 and inc < 0.9:
		inc = inc + 0.1 * delta * 30
		GameState.set_debug_info(str(inc))
		get_parent().set_scale(Vector2(inc,inc))
	elif not opened and get_parent().get_scale().x > 0.0:
		inc = inc - 0.1
		GameState.set_debug_info(str(inc))
		get_parent().set_scale(Vector2(inc,inc))
		
	if not opened and get_parent().get_scale().x <= 0.0:
		get_parent().get_parent().queue_free()
	
func _on_Area2D_input_event(viewport, event, shape_idx):
	if event.action_match(event):
		if event.is_pressed() and event.button_index == BUTTON_LEFT:
			GameState.set_debug_info(str(card["name"]))
			if card["type"] == "computer":
				opened = false
			elif card["type"] == "daemon":
				opened = false
				emit_signal("effect_placed", get_tree().get_network_unique_id(), card)
			if timer.is_stopped():
				timer.start()

func set_card(arg):
	card = arg