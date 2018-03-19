extends Area2D
var card
signal effect_placed()

func _ready():
	self.connect("input_event",self,"_on_Area2D_input_event")
	self.connect("effect_placed", get_tree().get_root().get_node("GameState"), "_on_effect_placed")
	#get_parent().set_texture(load(card["image"]))
	#GameState.connect("card_drawn", self, "_on_card_drawn")

func _on_Area2D_input_event(viewport, event, shape_idx):
	if event.action_match(event):
		if event.is_pressed() and event.button_index == BUTTON_LEFT:
			if card["type"] == "computer":
				get_parent().get_parent().queue_free()
			elif card["type"] == "daemon":
				emit_signal("effect_placed", get_tree().get_network_unique_id(), card)
				get_parent().get_parent().queue_free()


func set_card(arg):
	card = arg