extends CanvasLayer

var hitpoint_bars = {}
var players

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func set_players(p):
	players = p
	
	var y_offset = 0
	for p_id in players:
		var bar = ProgressBar.new()
		bar.rect_size = Vector2(150, 16)
		bar.rect_position.y = y_offset
		bar.max_value = players[p_id].MAX_HITPOINTS
		bar.min_value = 0
		y_offset += 20
		$health_bars.add_child(bar)
		hitpoint_bars[p_id] = bar

func update_bars():
	for p_id in players:
		print("HITPOINTS: " + str(players[p_id].hitpoints))
		hitpoint_bars[p_id].value = players[p_id].hitpoints