extends CharacterBody2D

var speed = -30
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite_2d = $AnimatedSprite2D

var facing_right = false

func _ready():
	animated_sprite_2d.play("walk")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = speed
	move_and_slide()
	if !$RayCast2D.is_colliding() && is_on_floor():
		flip()

func flip():
	facing_right = !facing_right
	scale.x = abs(scale.x) * -1
	if facing_right:
		speed = abs(speed)
	else:
		speed = abs(speed) * -1
