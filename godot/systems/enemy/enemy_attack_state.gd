extends EnemyState
class_name EnemyAttackState

func enter(controller: EnemyStateMachine) -> void:
	controller.trigger_attack()

func physics_update(controller: EnemyStateMachine, delta: float) -> void:
	controller.apply_gravity(delta)
	controller.velocity.x = move_toward(controller.velocity.x, 0, controller.config.patrol_speed * delta * 8.0)
	controller.move_and_slide()
	if controller.attack_cooldown_left <= 0.0:
		if controller.in_chase_range():
			if controller.should_enter_alert():
				controller.request_state_alert()
			else:
				controller.request_state_chase()
		else:
			controller.request_state_patrol()
