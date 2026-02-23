extends EnemyState
class_name EnemyPatrolState

func physics_update(controller: EnemyStateMachine, delta: float) -> void:
	controller.apply_gravity(delta)
	controller.move_and_turn(controller.config.patrol_speed, delta)
	if controller.can_attack_target():
		controller.request_state_attack()
	elif controller.in_chase_range():
		if controller.should_enter_alert():
			controller.request_state_alert()
		else:
			controller.request_state_chase()
