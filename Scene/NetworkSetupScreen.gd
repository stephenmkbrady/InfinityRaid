extends Node2D

var net_code
var player_name = "2"
var server_ip = "127.0.0.1"
signal player_name_changed()

func _ready():
	net_code = self.get_tree().get_root().get_node("/root/NetCode")
	net_code.connect("connection_failed", self, "_on_connection_failed")
	net_code.connect("connection_succeeded", self, "_on_connection_success")
	net_code.connect("player_list_changed", self, "refresh_lobby")
	net_code.connect("game_ended", self, "_on_game_ended")
	net_code.connect("game_error", self, "_on_game_error")
	self.connect("player_name_changed", GameState, "_on_player_name_changed")
	emit_signal("player_name_changed", player_name)

func _on_ClientJoinButton_pressed():
	print("client mode")
	net_code.join_game(server_ip, "2")

func _on_PlayerNameEdit_text_changed( new_text ):
	player_name = new_text
	emit_signal("player_name_changed", player_name)

func _on_IPEdit_text_changed( new_text ):
	server_ip = new_text

func _on_PlayerNameEdit_text_entered( new_text ):
	_on_PlayerNameEdit_text_changed( new_text )

func _on_IPEdit_text_entered( new_text ):
	_on_IPEdit_text_changed( new_text )

func _on_HostButton_pressed():
	
	get_node("connect").hide()
	get_node("players").show()
	player_name = "1"
	emit_signal("player_name_changed", player_name)
	net_code.host_game(player_name)


func _on_connection_success():
	get_node("connect").hide()
	get_node("players").show()

func _on_connection_failed():
	get_node("connect/HostButton").disabled=false
	get_node("connect/ClientJoinButton").disabled=false
	get_node("connect/error_label").set_text("Connection failed.")

func _on_game_ended():
	show()
	get_node("connect").show()
	get_node("players").hide()
	get_node("connect/host").disabled=false
	get_node("connect/join").disabled

func _on_game_error(errtxt):
	get_node("error").dialog_text = errtxt
	get_node("error").popup_centered_minsize()
	
func refresh_lobby():
	var players = GameState.get_player_list()
	print("lobby_refresh: ", players)
	players.sort()
	get_node("players/list").clear()
	get_node("players/list").add_item(GameState.get_player_name() + " (You)")
	for p in players:
		get_node("players/list").add_item(p)

	get_node("players/start").disabled=not get_tree().is_network_server()

func _on_start_pressed():
	GameState.begin_game()
