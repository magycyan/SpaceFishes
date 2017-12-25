extends Area2D

const SPEED = 100

func _ready():
	set_process(true)

func _process(delta):
	move_local_x(delta * SPEED, true)