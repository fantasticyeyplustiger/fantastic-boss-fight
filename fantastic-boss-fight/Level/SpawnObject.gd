extends Node3D

# Preload all of the meshes since they're going to be loaded in at some point anyway.
@onready var ground_shockwave_mesh = preload("res://Level/SpawnedObjects/GroundShockwave.tscn")
@onready var air_shockwave_mesh = preload("res://Level/SpawnedObjects/AirShockwave.tscn")
@onready var colliding_shockwave_mesh = preload("res://Level/SpawnedObjects/CollidingShockwave.tscn")
@onready var bomb_shockwave_mesh = preload("res://Level/SpawnedObjects/BombShockwave.tscn")

@onready var right_arm_mesh = preload("res://Level/SpawnedObjects/RightArm.tscn")
@onready var colored_bomb_mesh = preload("res://Level/SpawnedObjects/ColoredBomb.tscn")
@onready var ice_cream_cone_mesh = preload("res://Level/SpawnedObjects/IceCreamCone.tscn")

@onready var mortar_attack = preload("res://Level/SpawnedObjects/Bombardment.tscn")
@onready var sword_attack = preload("res://Level/SpawnedObjects/GroundSwordSlash.tscn")

## This script essentially spawns an object at a given position (and maybe angle) whenever needed.
## Mainly used for spawning shockwaves and globally placed attacks.
#
## Methods don't have "spawn" in their names, as the script name itself makes it self-explanatory.

func ground_shockwave(target_position : Vector3) -> void:
	var new_shockwave : MeshInstance3D = ground_shockwave_mesh.instantiate()
	new_shockwave.position = Vector3(target_position.x, 0.0, target_position.z)
	add_child(new_shockwave)

func bomb_shockwave(target_position : Vector3) -> void:
	var new_shockwave : Node3D = bomb_shockwave_mesh.instantiate()
	new_shockwave.position = Vector3(target_position.x, 0.0, target_position.z)
	add_child(new_shockwave)

func air_shockwave(target_position : Vector3, angle : Vector3) -> void:
	var new_shockwave : MeshInstance3D = air_shockwave_mesh.instantiate()
	new_shockwave.position = target_position
	new_shockwave.rotation = angle
	add_child(new_shockwave)

func colliding_shockwave(target_position : Vector3, angle : Vector3) -> void:
	var new_shockwave : Node3D = colliding_shockwave_mesh.instantiate()
	new_shockwave.position = target_position
	new_shockwave.rotation = angle
	add_child(new_shockwave)


func colored_bomb(target_position : Vector3, hex_code : String) -> void:
	var new_bomb : Node3D = colored_bomb_mesh.instantiate()
	new_bomb.position = Vector3(target_position.x, 0.0, target_position.z)
	new_bomb.set_color(hex_code)
	add_child(new_bomb)


func right_arm(arm_position : Vector3) -> void:
	var new_arm : CharacterBody3D = right_arm_mesh.instantiate()
	new_arm.position = arm_position
	add_child(new_arm)


func ice_cream_cone(cone_position : Vector3) -> void:
	var cone : MeshInstance3D = ice_cream_cone_mesh.instantiate()
	cone.position = cone_position
	add_child(cone)


func bombardment(target_position : Vector3) -> void:
	target_position = Vector3(target_position.x, 0.0, target_position.z)
	
	var random_x : float
	var random_z : float
	
	for i in 3:
		var new_mortar : Node3D = mortar_attack.instantiate()
		
		random_x = randf_range(target_position.x - 12.0, target_position.x + 12.0)
		random_z = randf_range(target_position.z - 12.0, target_position.z + 12.0)
		
		target_position = Vector3(random_x, 0.0, random_z)
		
		new_mortar.position = target_position
		add_child(new_mortar)
		

func ground_slash(target_position : Vector3, angle : Vector3) -> void:
	var new_slash = sword_attack.instantiate()
	new_slash.position = Vector3(target_position.x, 0.0, target_position.z)
	
	# Angle y has 180 degrees added because boss faces the other way around...
	new_slash.rotation = Vector3(0.0, angle.y + deg_to_rad(180.0), 0.0)
	
	add_child(new_slash)
