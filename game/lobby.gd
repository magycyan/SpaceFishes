extends Control

func _ready():
	game.connect("player_list_changed", self, "update_player_list")
	game.connect("connection_succeeded", self, "_on_connection_success")
	game.connect("game_error", self, "show_error")

func show_error(what):
	$error_label.text = what

func update_player_list():
	var players = game.get_player_list()
	players.sort()

	$waiting_group/player_list.clear()
	for p in players:
		$waiting_group/player_list.add_item(p)

	$waiting_group/start_button.disabled = not get_tree().is_network_server()

func _on_host_button_pressed():
	$error_label.text = ""
	game.host_game($start_group/playername_input.text)
	$start_group.hide()
	$waiting_group.show()

func _on_join_button_pressed():
	$error_label.text = ""
	$start_group/host_button.disabled = false
	$start_group/join_button.disabled = false
	game.join_game($start_group/ip_input.text, $start_group/playername_input.text)

func _on_connection_success():
	$start_group.hide()
	$waiting_group.show()

func _on_connection_failed():
	$start_group/host_button.disabled = false
	$start_group/join_button.disabled = false

func _on_start_button_pressed():
	game.begin_game()

func _on_abort_button_pressed():
	game.leave_game()
	$start_group.show()
	$waiting_group.hide()
	$start_group/host_button.disabled = false
	$start_group/join_button.disabled = false

