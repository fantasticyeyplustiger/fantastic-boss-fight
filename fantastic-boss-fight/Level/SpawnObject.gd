extends Node3D

'''

This script essentially spawns an object at a given position (and maybe angle) whenever needed.
Mainly used for spawning shockwaves and globally placed attacks.

Methods don't have "spawn" in their names, as the script name itself makes it self-explanatory.

'''

# Preload all of the meshes since they're going to be loaded in at some point anyway.
@onready var ground_shockwave_mesh = preload("res://Level/SpawnedObjects/GroundShockwave.tscn")
@onready var air_shockwave_mesh = preload("res://Level/SpawnedObjects/AirShockwave.tscn")
@onready var colliding_shockwave_mesh = preload("res://Level/SpawnedObjects/CollidingShockwave.tscn")
@onready var bomb_shockwave_mesh = preload("res://Level/SpawnedObjects/BombShockwave.tscn")
@onready var particle_shockwave_mesh = preload("res://Level/SpawnedObjects/ParticleShockwave.tscn")

@onready var blue_flash_node = preload("res://ParryFlashes/UnparriableFlash.tscn")

@onready var pistol_explosion_mesh = preload("res://Player/WeaponExplosions/PistolExplosion.tscn")
@onready var explosion_mesh = preload("res://Level/SpawnedObjects/Explosion.tscn")

@onready var rock_group_mesh = preload("res://Rocks/RockGroup.tscn")

## Instantiates and sets the transform of the given node.
func new_object(node : PackedScene, target_position : Vector3,
				angle : Vector3 = Vector3.ZERO, new_scale : float = 1.0) -> Node3D:
	
	var new_node = node.instantiate()
	new_node.position = target_position
	new_node.rotation = angle
	new_node.scale = Vector3(new_scale, new_scale, new_scale)
	
	return new_node

func ground_shockwave(target_position : Vector3, new_scale : float = 1.0) -> void:
	
	var mesh := new_object(ground_shockwave_mesh, target_position, Vector3.ZERO, new_scale)
	
	mesh.position.y = 0.0 # or just floor
	add_child(mesh)

func bomb_shockwave(target_position : Vector3, new_scale : float = 1.0) -> void:
	
	var mesh := new_object(bomb_shockwave_mesh, target_position, Vector3.ZERO, new_scale)
	
	mesh.position.y = 0.0 # or just floor
	add_child(mesh)

func air_shockwave(target_position : Vector3, angle : Vector3 = Vector3.ZERO,
					new_scale : float = 1.0) -> void:
	
	var mesh := new_object(air_shockwave_mesh, target_position, angle, new_scale)
	add_child(mesh)

func colliding_shockwave(target_position : Vector3, angle : Vector3 = Vector3.ZERO,
						new_scale : float = 1.0) -> void:
	
	var node := new_object(colliding_shockwave_mesh, target_position, angle, new_scale)
	add_child(node)

func particle_shockwave(target_position : Vector3, angle : Vector3 = Vector3.ZERO,
						hex_color : String = "#FFFFFF", new_scale : float = 1.0,
						disable_billboard : bool = false) -> void:
	
	var node := new_object(particle_shockwave_mesh, target_position, angle, new_scale)
	node.set_sprite_color(hex_color)
	
	if disable_billboard:
		node.disable_billboard()
	
	add_child(node)

func rock_group(target_position : Vector3, angle : Vector3) -> void:
	var node := new_object(rock_group_mesh, target_position, angle)
	add_child(node)

func blue_flash(target_position : Vector3, angle : Vector3, new_scale : float) -> void:
	var node := new_object(blue_flash_node, target_position, angle)
	
	node.change_scale(new_scale * 2.5)
	
	add_child(node)
	node.emitting = true
	
	await get_tree().create_timer(1.0).timeout
	node.queue_free()

## Adds an explosion where the player is aiming.
func pistol_explosion() -> void:
	var new_explosion = pistol_explosion_mesh.instantiate()
	new_explosion.position = Global.player_target_position
	add_child(new_explosion)

func explosion(target_position : Vector3, disable_sound : bool = false) -> void:
	var new_explosion = explosion_mesh.instantiate()
	new_explosion.position = target_position
	new_explosion.disable_sound(disable_sound)
	add_child(new_explosion)

func explosion_detailed(target_position : Vector3, new_color : String = "#FFFFFF",
						new_scale : float = 1.0, disable_sound : bool = false) -> void:
	
	var new_explosion = explosion_mesh.instantiate()
	
	# So it only changes the color of this explosion and not every other explosion
	new_explosion.material_override = new_explosion.mesh.material.duplicate()
	new_explosion.material_override.albedo_color = Color(new_color)
	
	new_explosion.set_scale(Vector3(new_scale, new_scale, new_scale))
	new_explosion.position = target_position
	new_explosion.disable_sound(disable_sound)
	
	add_child(new_explosion)

## Spawns an instant trail of rocks from the start position to end position.
## Sets y of both positions to be zero (zero acts as the floor currently).
func rock_trail(start_position : Vector3, end_position : Vector3) -> void:
	
	start_position.y = 0.0
	end_position.y = 0.0
	
	var direction := start_position.direction_to(end_position)
	var new_rotation := start_position.angle_to(end_position)
	
	var new_spawn_position := start_position
	var distance := start_position.distance_to(end_position)
	var current_distance : float = 0.0
	
	while distance > current_distance:
		
		var new_rocks = rock_group_mesh.instantiate()
		new_rocks.position = new_spawn_position
		new_rocks.rotation = Vector3(0.0, new_rotation, 0.0)
		
		add_child(new_rocks)
		
		new_spawn_position += direction * 1.2
		current_distance += direction.length() * 1.2
