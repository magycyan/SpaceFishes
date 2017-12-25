extends Area2D

signal hitpoints_changed

const BASE_SPEED = 120
const COOLDOWN_DURATION = 0.5
const MAX_HITPOINTS = 130

var velocity = Vector2()
var speed = BASE_SPEED
var screensize
var player_name
var network_id
var cooldown = 0
var hitpoints = MAX_HITPOINTS

slave var slave_position = Vector2()

func _ready():
	screensize = get_viewport_rect().size

func set_player_name(name):
	player_name = name

func set_network_id(id):
	network_id = id

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
			velocity = velocity.normalized() * speed
		else:
			$AnimatedSprite.stop()
		
		if Input.is_mouse_button_pressed(BUTTON_LEFT) and can_shoot():
			_spawn_projectile()
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

func get_network_id():
	return network_id

func start(pos):
	position = pos
	show()
	monitoring = true

func _spawn_projectile():
	rpc("spawn_projectile",
		global_position,
		get_angle_to(get_global_mouse_position()),
		get_tree().get_network_unique_id())
	cooldown = COOLDOWN_DURATION

sync func spawn_projectile(pos, rot, owner):
	var projectile = preload("res://effects/plasma_projectile.tscn").instance()
	projectile.position = pos
	projectile.rotation = rot
	projectile.owner = owner
	cooldown = COOLDOWN_DURATION
	get_parent().add_child(projectile)

func can_shoot():
	return cooldown <= 0

func take_damage(damage, by):
	rpc("took_damage", damage)

sync func took_damage(damage):
	hitpoints -= damage
	emit_signal("hitpoints_changed")
	if hitpoints <= 0:
		queue_free()

sync func won_points(points):
	points += points
