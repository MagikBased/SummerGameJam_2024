extends CharacterBody2D
class_name Player

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var coyote_time = $CoyoteTime
@onready var control_state_controller = $"../ControlStateController"

@export var movement_data: PlayerMovementData
@export var other_player: CharacterBody2D
@export var control_state: bool = true
@export var is_left_player: bool
signal victory

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_wall_jumped_left: bool = false
var has_wall_jumped_right: bool = false
var other_player_offset: Vector2
var respawn_point: Vector2
var is_dying: bool = false

func _ready():
	other_player_offset = other_player.global_position - global_position
	respawn_point = global_position
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		checkpoint.connect("checkpoint_reached", Callable(self, "set_respawn_point"))

#func _process(delta):
	#if is_left_player:
		#print(other_player.test_move(other_player.transform, Vector2(0, 0)))

func _physics_process(delta):
	if is_dying: return
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		
	var direction = Input.get_axis("ui_left", "ui_right")
	update_animations(direction)
	
	if Input.is_action_just_pressed("ui_accept") and is_left_player: #and can_flip_control() 
		control_state_controller.flip_control_states()
	
	if control_state:
		if not is_on_floor():
			velocity.y += gravity * movement_data.gravity_scale * delta
		else:
			has_wall_jumped_left = true
			has_wall_jumped_right = true
		
		handle_acceleration(direction, delta)
		jump()
		handle_wall_jump()
		var was_on_floor: bool = is_on_floor()
		move_and_slide()
		var over_ledge: bool = was_on_floor and not is_on_floor() and velocity.y >= 0
		if over_ledge:
			coyote_time.start()
	else:
		global_position = other_player.global_position - other_player_offset

func jump():
	if is_on_floor() or coyote_time.time_left > 0.0:
		if Input.is_action_just_pressed("ui_up"):
			velocity.y = movement_data.jump_velocity
			
	if not is_on_floor():
		if Input.is_action_just_released("ui_up") and velocity.y < movement_data.jump_velocity / 2:
			velocity.y = movement_data.jump_velocity / 2

func update_animations(direction):
	if direction != 0:
		animated_sprite_2d.flip_h = direction < 0
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
	if not is_on_floor():
		animated_sprite_2d.play("jump")

func handle_acceleration(direction, delta):
	var acceleration: float
	if is_dying:
		return
	if is_on_floor():
		acceleration = movement_data.acceleration
	else:
		acceleration = movement_data.air_acceleration
	if direction:
		velocity.x = move_toward(velocity.x, movement_data.speed * direction, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, movement_data.friction * delta)

func handle_wall_jump():
	if not is_on_wall_only(): return
	var wall_normal = get_wall_normal()
	if Input.is_action_just_pressed("ui_left") and wall_normal == Vector2.LEFT and has_wall_jumped_left:
		velocity.x = wall_normal.x * movement_data.speed
		velocity.y = movement_data.jump_velocity
		has_wall_jumped_left = false
		has_wall_jumped_right = true
	if Input.is_action_just_pressed("ui_right") and wall_normal == Vector2.RIGHT and has_wall_jumped_right:
		velocity.x = wall_normal.x * movement_data.speed
		velocity.y = movement_data.jump_velocity
		has_wall_jumped_left = true
		has_wall_jumped_right = false

func _on_hurt_box_area_entered(_area):
	if control_state:
		die()
		other_player.die()

func can_flip_control() -> bool:
	return not other_player.is_on_floor() and not other_player.is_on_wall()

func die() -> void:
	if is_dying: return
	is_dying = true
	animated_sprite_2d.play("death")
	await move_player_death()
	
func move_player_death() -> void:
	var start_position = position
	var up_position = start_position + Vector2(0,-60)
	var down_position = start_position + Vector2(0,50)
	
	while position.y > up_position.y:
		position.y -= 4
		await get_tree().create_timer(.01).timeout
	while position.y < down_position.y:
		position.y += 3
		await get_tree().create_timer(.01).timeout
	on_deathtimer_timeout()
		
func on_deathtimer_timeout() -> void:
	is_dying = false
	velocity.y = 0
	velocity.x = 0
	if is_left_player:
		GameManager.respawn_player(self)
