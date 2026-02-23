extends Node
class_name DualWorldCoordinator

signal states_flipped

var control_sync := DualControlSync.new()
var checkpoint_sync := DualCheckpointSync.new()
var presentation := DualViewportPresentation.new()
@export var control_flip_snap_pixels: int = 4
@export var flip_block_shake_strength: float = 4.5
@export var flip_block_shake_duration: float = 0.18
@export var flip_block_sfx_path: NodePath

var left_lane: CharacterLane
var right_lane: CharacterLane
var left_player: Player
var right_player: Player
var left_overlay: CanvasItem
var right_overlay: CanvasItem
var left_camera: Camera2D
var right_camera: Camera2D
var flip_block_sfx_player: Node

func _ready() -> void:
	_resolve_flip_block_sfx_player()

func configure(left_lane_ref: CharacterLane, right_lane_ref: CharacterLane, left_tint: CanvasItem, right_tint: CanvasItem, left_camera_ref: Camera2D, right_camera_ref: Camera2D) -> void:
	left_lane = left_lane_ref
	right_lane = right_lane_ref
	left_camera = left_camera_ref
	right_camera = right_camera_ref
	left_lane.configure_lane(&"left")
	right_lane.configure_lane(&"right")
	left_lane.get_lane_world().initialize_checkpoint()
	right_lane.get_lane_world().initialize_checkpoint()
	left_player = left_lane.get_player()
	right_player = right_lane.get_player()
	left_overlay = left_tint
	right_overlay = right_tint
	_wire_players()
	if not GameManager.checkpoint_updated.is_connected(_on_checkpoint_updated):
		GameManager.checkpoint_updated.connect(_on_checkpoint_updated)
	if GameManager.current_checkpoint_id != -1:
		_on_checkpoint_updated(GameManager.current_checkpoint_id, &"configure")

func request_flip_controls() -> void:
	if left_player == null or right_player == null:
		return
	var active_player := left_player if left_player.control_state else right_player
	var next_active := right_player if left_player.control_state else left_player
	if not _prepare_next_active_player(next_active):
		_shake_current_screen(active_player)
		return
	control_sync.flip_controls(left_player, right_player)
	control_sync.sync_inactive_player(left_player, right_player)
	_update_overlays()
	emit_signal("states_flipped")

func _wire_players() -> void:
	if left_player == null or right_player == null:
		return
	control_sync.wire_players(left_player, right_player, self)
	control_sync.sync_inactive_player(left_player, right_player)
	_update_overlays()

func _update_overlays() -> void:
	presentation.update_overlays(left_overlay, right_overlay, left_player, right_player)

func _on_checkpoint_updated(checkpoint_id: int, _source_lane_id: StringName) -> void:
	if checkpoint_id == -1:
		return
	checkpoint_sync.apply_checkpoint(left_lane, right_lane, checkpoint_id)
	if left_player != null:
		var left_respawn: Variant = GameManager.get_lane_respawn_point(left_lane.lane_id)
		if left_respawn != null:
			left_player.set_respawn_point(left_respawn)
	if right_player != null:
		var right_respawn: Variant = GameManager.get_lane_respawn_point(right_lane.lane_id)
		if right_respawn != null:
			right_player.set_respawn_point(right_respawn)

func set_left_player_active(is_active: bool) -> void:
	if left_player == null or right_player == null:
		return
	left_player.control_state = is_active
	right_player.control_state = not is_active
	control_sync.sync_inactive_player(left_player, right_player)
	_update_overlays()

func _prepare_next_active_player(player: Player) -> bool:
	if player == null:
		return false
	return player.try_resolve_terrain_overlap(control_flip_snap_pixels)

func _shake_current_screen(active_player: Player) -> void:
	if active_player == null:
		return
	var active_camera := left_camera if active_player == left_player else right_camera
	if active_camera != null and active_camera.has_method("start_shake"):
		active_camera.call("start_shake", flip_block_shake_strength, flip_block_shake_duration)
	_play_flip_block_sfx()

func _resolve_flip_block_sfx_player() -> void:
	if flip_block_sfx_path == NodePath():
		flip_block_sfx_player = null
		return
	flip_block_sfx_player = get_node_or_null(flip_block_sfx_path)

func _play_flip_block_sfx() -> void:
	if flip_block_sfx_player == null:
		return
	if flip_block_sfx_player.has_method("play"):
		flip_block_sfx_player.call("play")
