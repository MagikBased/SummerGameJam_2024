extends Node2D
class_name EnemySpawnDirector

@export var spawn_scene: PackedScene
@export var spawn_points_root_path: NodePath
@export var max_alive: int = 3
@export var total_to_spawn: int = 6
@export var spawn_interval_seconds: float = 2.0
@export var start_active: bool = true

@onready var _spawn_points_root: Node = get_node_or_null(spawn_points_root_path)

var _spawn_timer_left: float = 0.0
var _spawned_count: int = 0
var _alive: Array[Node2D] = []
var _active: bool = true

func _ready() -> void:
	_active = start_active
	_spawn_timer_left = spawn_interval_seconds

func _physics_process(delta: float) -> void:
	if not _active:
		return
	_cleanup_dead()
	if _spawned_count >= total_to_spawn:
		return
	if _alive.size() >= max_alive:
		return
	_spawn_timer_left = max(0.0, _spawn_timer_left - delta)
	if _spawn_timer_left > 0.0:
		return
	_spawn_timer_left = spawn_interval_seconds
	_spawn_one()

func set_active(active: bool) -> void:
	_active = active

func _spawn_one() -> void:
	if spawn_scene == null:
		return
	var spawn_point := _pick_spawn_point()
	if spawn_point == null:
		return
	var spawned_node: Node = spawn_scene.instantiate()
	if not (spawned_node is Node2D):
		return
	var spawned := spawned_node as Node2D
	spawned.global_position = spawn_point.global_position
	add_child(spawned)
	_alive.append(spawned)
	_spawned_count += 1

func _pick_spawn_point() -> Node2D:
	if _spawn_points_root == null:
		return null
	var points: Array[Node2D] = []
	for child in _spawn_points_root.get_children():
		if child is Node2D:
			points.append(child as Node2D)
	if points.is_empty():
		return null
	var idx: int = randi() % points.size()
	return points[idx]

func _cleanup_dead() -> void:
	var keep: Array[Node2D] = []
	for node in _alive:
		if node != null and is_instance_valid(node):
			keep.append(node)
	_alive = keep
