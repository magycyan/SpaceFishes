extends Area2D

const SPEED = 200
const DAMAGE = 1

var owner

func _ready():
	set_process(true)

func _process(delta):
	move_local_x(delta * SPEED, true)
	
func set_owner(player):
	owner = player

func _on_plasma_projectile_area_entered(area):
	if area.is_in_group("characters") and (not area.has_method("get_network_id") or area.get_network_id() != owner):
		area.take_damage(DAMAGE, owner)
		queue_free()
