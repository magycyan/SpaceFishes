extends Area2D

signal hit

export (int) var SPEED
const COOLDOWN_DURATION = 0.5

var velocity = Vector2()
var screensize
var player_name
var cooldown = 0

slave var slave_position = Vector2()

func _ready():
	screensize = get_viewport_rect().size

func set_player_name(name):
	player_name = name

func _process(delta):
	if is_network_master():
		velocity = Vector2() 
		if Input.is_action_pressed("ui_right"):
			velocity.x += 1
		if Input.is_action_pressed("ui_left"):
			velocity.x -= 1
		if Input.is_action_pressed("ui_up"):
			velocity.y -= 1
		if Input.is_action_pressed("ui_down"):
			velocity.y += 1
		if velocity.length() > 0:
			$AnimatedSprite.play()
			velocity = velocity.normalized() * SPEED
		else:
			$AnimatedSprite.stop()
		
		if Input.is_mouse_button_pressed(BUTTON_LEFT) and can_shoot():
			spawn_projectile()
		if cooldown > 0:
			cooldown -= delta
		
		position += velocity * delta
		position.x = clamp(position.x, 0, screensize.x)
		position.y = clamp(position.y, 0, screensize.y)
		
		if velocity.x != 0:
			$AnimatedSprite.animation = "right"
			$AnimatedSprite.flip_v = false
			$AnimatedSprite.flip_h = velocity.x < 0
			$Particles.rotation_degrees = 180 if velocity.x > 0 else 0 
		elif velocity.y != 0:
			$AnimatedSprite.animation = "up"
			$AnimatedSprite.flip_v= velocity.y > 0
			$Particles.rotation_degrees = 270 if velocity.y > 0 else 90
		rset("slave_position", position)
	else:
		position = slave_position

func _on_Player_body_entered( body ):
	hide()
	emit_signal("hit")
	call_deferred("set_monitoring", false)

func start(pos):
	position = pos
	show()
	monitoring = true

func spawn_projectile():
	var projectile = preload("res://effects/plasma_projectile.tscn").instance()
	projectile.position = global_position
	projectile.rotation = get_angle_to(get_global_mouse_position())
	cooldown = COOLDOWN_DURATION
	get_parent().add_child(projectile)
	
func can_shoot():
	return cooldown <= 0



