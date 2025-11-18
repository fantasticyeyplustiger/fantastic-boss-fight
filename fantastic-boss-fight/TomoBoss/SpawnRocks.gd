extends Node3D

const MAX_ROCK_DISTANCE : float = 1.5

@onready var floor_detector : RayCast3D = RayCast3D.new()

var distance_between_rocks : float = 0.0
var old_position : Vector3

func _ready() -> void:
	# Automatically spawn raycast with collision mask 1, seeing the floor
	floor_detector.target_position = Vector3(0.0, -0.5, 0.0)
	add_child(floor_detector)
	
	old_position = global_position
	set_physics_process(false)

## No need for rotation, inherits from parent node
func _physics_process(_delta: float) -> void:
	
	var distance : float = old_position.distance_to(global_position)
	
	distance_between_rocks += distance
	
	if distance_between_rocks > MAX_ROCK_DISTANCE and floor_detector.is_colliding():
		SpawnObject.rock_group(global_position, global_rotation)
		distance_between_rocks = 0.0
	
	old_position = global_position
		

func start_spawning_rocks() -> void:
	set_physics_process(true)

func spawn_rocks_for(seconds : float) -> void:
	start_spawning_rocks()
	await get_tree().create_timer(seconds * Global.difficulty_speed).timeout
	stop_spawning_rocks()

func stop_spawning_rocks() -> void:
	set_physics_process(false)
	
