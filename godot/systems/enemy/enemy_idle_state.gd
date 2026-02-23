extends EnemyState
class_name EnemyIdleState

func physics_update(controller: EnemyStateMachine, delta: float) -> void:
	controller.apply_gravity(delta)
	controller.velocity.x = move_toward(controller.velocity.x, 0, controller.config.patrol_speed * delta * 5.0)
	controller.move_and_slide()
	if controller.in_chase_range():
		controller.request_state_chase()
