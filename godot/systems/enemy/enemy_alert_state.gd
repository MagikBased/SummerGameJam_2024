extends EnemyState
class_name EnemyAlertState

func enter(controller: EnemyStateMachine) -> void:
	controller.start_alert_timer()

func physics_update(controller: EnemyStateMachine, delta: float) -> void:
	controller.apply_gravity(delta)
	controller.velocity.x = move_toward(controller.velocity.x, 0, controller.config.patrol_speed * delta * 8.0)
	controller.move_and_slide()
	if not controller.in_chase_range():
		controller.request_state_patrol()
		return
	if not controller.is_alerting():
		if controller.can_attack_target():
			controller.request_state_attack()
		else:
			controller.request_state_chase()
