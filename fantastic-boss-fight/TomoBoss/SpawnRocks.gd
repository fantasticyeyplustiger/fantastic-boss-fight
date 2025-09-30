extends Node3D

const MAX_ROCK_DISTANCE : float = 1.5

var distance_between_rocks : float = 0.0
var old_position : Vector3

func _ready() -> void:
	old_position = global_position
	set_physics_process(false)

## No need for rotation, inherits from parent node
func _physics_process(_delta: float) -> void:
	
	var distance : float = old_position.distance_to(global_position)
	
	distance_between_rocks += distance
	
	if distance_between_rocks > MAX_ROCK_DISTANCE:
		SpawnObject.rock_group(global_position, global_rotation)
		distance_between_rocks = 0.0
	
	old_position = global_position
		

func start_spawning_rocks() -> void:
	set_physics_process(true)
	distance_between_rocks = 0.0
	SpawnObject.rock_group(global_position, global_rotation)

func spawn_rocks_for(seconds : float) -> void:
	start_spawning_rocks()
	await get_tree().create_timer(seconds * Global.difficulty_speed).timeout
	stop_spawning_rocks()

func stop_spawning_rocks() -> void:
	set_physics_process(false)
	
