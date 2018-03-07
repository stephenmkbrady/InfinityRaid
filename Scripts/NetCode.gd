extends Node

# Default game port
const DEFAULT_PORT = 10567

# Max number of players
const MAX_PEERS = 12


# Signals to let lobby GUI know what's going on
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error()

# Callback from SceneTree
func _player_connected(id):
	# This is not used in this demo, because _connected_ok is called for clients
	# on success and will do the job.
	pass

# Callback from SceneTree
func _player_disconnected(id):
	if (get_tree().is_network_server()):
		if (has_node("/root/world")): # Game is in progress
			emit_signal("game_error", "Player " + GameState.players[id] + " disconnected")
			GameState.end_game()
		else: # Game is not in progress
			# If we are the server, send to the new dude all the already registered players
			unregister_player(id)
			for p_id in GameState.players:
				# Erase in the server
				rpc_id(p_id, "unregister_player", id)

# Callback from SceneTree, only for clients (not server)
func _connected_ok():
	# Registration of a client beings here, tell everyone that we are here
	print("connected_ok")
	rpc("register_player", get_tree().get_network_unique_id(), GameState.player_name)
	emit_signal("connection_succeeded")

# Callback from SceneTree, only for clients (not server)
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	GameState.end_game()

# Callback from SceneTree, only for clients (not server)
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")

# Lobby management functions

remote func register_player(id, new_player_name):
	print("register_player: ", id, " ", new_player_name)
	if (get_tree().is_network_server()):
		print("server_register_player: ", id, " ", new_player_name)
		# If we are the server, let everyone know about the new player
		rpc_id(id, "register_player", 1, GameState.player_name) # Send myself to new dude
		for p_id in GameState.players: # Then, for each remote player
			print("player: ", p_id)
			rpc_id(id, "register_player", p_id, GameState.players[p_id]) # Send player to new dude
			rpc_id(p_id, "register_player", id, new_player_name) # Send new dude to player

	GameState.players[id] = new_player_name
	emit_signal("player_list_changed")

remote func unregister_player(id):
	GameState.players.erase(id)
	emit_signal("player_list_changed")

func host_game(new_player_name):
	GameState.player_name = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)

func join_game(ip, new_player_name):
	GameState.player_name = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)

func get_player_list():
	return GameState.players.values()

func get_player_name():
	return GameState.player_name

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
