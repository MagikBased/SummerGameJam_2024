extends EnemyState
class_name EnemyChaseState

func physics_update(controller: EnemyStateMachine, delta: float) -> void:
	controller.apply_gravity(delta)
	if controller.target == null:
		controller.request_state_patrol()
		return
	controller.facing_right = controller.target.global_position.x > controller.global_position.x
	controller.scale.x = abs(controller.scale.x) * (-1 if controller.facing_right else 1)
	controller.velocity.x = controller.config.chase_speed if controller.facing_right else -controller.config.chase_speed
	controller.move_and_slide()
	if controller.can_attack_target():
		controller.request_state_attack()
	elif not controller.in_chase_range():
		controller.request_state_patrol()
