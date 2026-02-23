extends RefCounted
class_name DualViewportPresentation

func update_overlays(left_overlay: CanvasItem, right_overlay: CanvasItem, left_player: Player, right_player: Player) -> void:
	if left_overlay != null and left_player != null:
		left_overlay.visible = not left_player.control_state
	if right_overlay != null and right_player != null:
		right_overlay.visible = not right_player.control_state
