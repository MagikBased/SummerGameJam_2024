extends Node

@onready var characters := {
	"left": {
		viewport = $HBoxContainer/SubViewportContainer/SubViewport,
		camera = $HBoxContainer/SubViewportContainer/SubViewport/Camera2D,
		target = $HBoxContainer/SubViewportContainer/SubViewport/World/LeftPlayer
	},
	"right": {
		viewport = $HBoxContainer/SubViewportContainer2/SubViewport2,
		camera = $HBoxContainer/SubViewportContainer2/SubViewport2/Camera2D,
		target = $HBoxContainer/SubViewportContainer/SubViewport/World/RightPlayer
	}
}
@onready var label = $Victory/Label
@onready var control_state_controller = $HBoxContainer/SubViewportContainer/SubViewport/World/ControlStateController
@onready var color_rect = $HBoxContainer/SubViewportContainer/ColorRect
@onready var color_rect2 = $HBoxContainer/SubViewportContainer2/ColorRect


func _ready() -> void:
	characters["right"].viewport.world_2d = characters["left"].viewport.world_2d
	for node in characters.values():
		var remote_transform := RemoteTransform2D.new()
		remote_transform.remote_path = node.camera.get_path()
		node.target.add_child(remote_transform)
	control_state_controller.connect("states_flipped", Callable(self, "_on_states_flipped"))

func _on_states_flipped() -> void:
	color_rect.visible = not color_rect.visible
	color_rect2.visible = not color_rect2.visible
	
func victory() -> void:
	label.visible = true
