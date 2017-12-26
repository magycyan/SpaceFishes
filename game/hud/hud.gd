extends CanvasLayer

const PLAYER_NAME_MAX_WIDTH = 70

var players

func set_players(p):
	players = p

	var y_offset = 0
	for p_id in players:
		var bar_group = Node2D.new()
		bar_group.position.y = y_offset
		bar_group.set_name(str(p_id))

		var label = Label.new()
		label.text = players[p_id].player_name
		label.rect_clip_content = true
		label.rect_size.x = PLAYER_NAME_MAX_WIDTH

		var bar = ProgressBar.new()
		bar.set_name("health")
		bar.rect_size = Vector2(150, 16)
		bar.rect_position.x = PLAYER_NAME_MAX_WIDTH
		bar.max_value = players[p_id].MAX_HITPOINTS
		bar.min_value = 0

		y_offset += 20

		bar_group.add_child(label)
		bar_group.add_child(bar)
		$bars.add_child(bar_group)

func update_bars():
	for p_id in players:
		get_node("bars/" + str(p_id) + "/health").value = players[p_id].hitpoints
