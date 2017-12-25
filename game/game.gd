extends Node2D

signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

const DEFAULT_PORT = 17123
const MAX_PEERS = 6

var players = {}
var players_ready = []
var my_player_name

func _ready():
	get_tree().set_auto_accept_quit(false)

	get_tree().connect("connected_to_server", self, "_on_connection_succeeded")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("server_disconnected", self, "signal_error", ["Server Disconnected"])
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")

func signal_error(what):
	emit_signal("game_error", what)

func my_id():
	return get_tree().get_network_unique_id()

func _on_player_disconnected(id):
	for p_id in all_players_but_me():
		rpc_id(p_id, "unregister_player")
	emit_signal("update_player_list")

func _on_connection_succeeded():
	print("CONNECTED.")
	rpc("register_player", my_id(), my_player_name)
	emit_signal("connection_succeeded")

func _on_connection_failed():
	emit_signal("connection_failed")

func host_game(name):
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)
	get_tree().set_meta("network_peer", host)

	my_player_name = name
	players[my_id()] = name
	emit_signal("player_list_changed")

func join_game(ip, name):
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)
	get_tree().set_meta("network_peer", host)

	my_player_name = name
	players[my_id()] = name
	emit_signal("player_list_changed")

func leave_game():
	rpc("unregister_player", my_id())
	get_tree().get_meta("network_peer").close_connection()
	emit_signal("player_list_changed")

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		leave_game()
		get_tree().quit()

func get_my_player_name():
	return my_player_name

func get_player_list():
	return players.values()

func begin_game():
	assert(get_tree().is_network_server())
	randomize()

	var spawn_points = {}
	for p in players:
		spawn_points[p] = Vector2(randi() % 1000, randi() % 1000)
	for p in players:
		rpc_id(p, "setup_game", spawn_points)

	players_ready = []
	setup_game(spawn_points)

remote func setup_game(spawn_points):
	var world = load("res://game/world.tscn").instance()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("lobby").hide()

	var player_scene = load("res://characters/player/player.tscn")
	for p_id in spawn_points:
		var player = player_scene.instance()
		player.set_name(str(p_id))
		player.position = spawn_points[p_id]
		player.set_network_master(p_id)

		player.set_player_name(players[p_id])
		world.get_node("players").add_child(player)

	if (not get_tree().is_network_server()):
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 1:
		everybody_is_setup()

remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if (not id in players_ready):
		players_ready.append(id)

	if (players_ready.size() == players.size()):
		for p_id in players:
			rpc_id(p_id, "everybody_is_setup")

remote func everybody_is_setup():
	get_tree().set_pause(false)

remote func register_player(new_player_id, new_player_name):
	# 1, 2, 3 are there
	# 4 joins.
	# Send register(4) to 1, 2, 3
	# Send register(1), register(2), register(3) to 4

	if get_tree().is_network_server():
		for p_id in players:
			if p_id != my_id(): # we already know about the new player
				rpc_id(p_id, "register_player", new_player_id, new_player_name)
			rpc_id(new_player_id, "register_player", p_id, players[p_id])
	players[new_player_id] = new_player_name
	emit_signal("player_list_changed")

remote func unregister_player(player_id):
	if get_tree().is_network_server():
		for p_id in players:
			if p_id != my_id():
				rpc_id(p_id, "unregister_player", player_id)
	players.erase(player_id)
