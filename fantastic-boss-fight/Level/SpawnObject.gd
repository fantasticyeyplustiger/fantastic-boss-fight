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

@onready var pistol_explosion_mesh = preload("res://Player/WeaponExplosions/PistolExplosion.tscn")
@onready var explosion_mesh = preload("res://Level/SpawnedObjects/Explosion.tscn")

#region old boss
#@onready var right_arm_mesh = preload("res://Level/SpawnedObjects/RightArm.tscn")
#@onready var colored_bomb_mesh = preload("res://Level/SpawnedObjects/ColoredBomb.tscn")
#@onready var ice_cream_cone_mesh = preload("res://Level/SpawnedObjects/IceCreamCone.tscn")
#
#@onready var mortar_attack = preload("res://Level/SpawnedObjects/Bombardment.tscn")
#@onready var sword_attack = preload("res://Level/SpawnedObjects/GroundSwordSlash.tscn")
#endregion

#region shockwaves
## Instantiates and sets the transform of the given node.
func new_object(node : PackedScene, target_position : Vector3,
				angle : Vector3 = Vector3.ZERO, new_scale : float = 1.0) -> Node3D:
	
	var new_node = node.instantiate()
	new_node.position = target_position
	new_node.rotation = angle
	new_node.scale = Vector3(new_scale, new_scale, new_scale)
	
	return new_node

func ground_shockwave(target_position : Vector3, new_scale : float = 1.0) -> void:
	
	var mesh = new_object(
		ground_shockwave_mesh, target_position,
		Vector3.ZERO, new_scale
	)
	
	mesh.position.y = 0.0 # or just floor
	add_child(mesh)

func bomb_shockwave(target_position : Vector3, new_scale : float = 1.0) -> void:
	
	var mesh = new_object(
		bomb_shockwave_mesh, target_position,
		Vector3.ZERO, new_scale
	)
	
	mesh.position.y = 0.0 # or just floor
	add_child(mesh)

func air_shockwave(target_position : Vector3, angle : Vector3 = Vector3.ZERO,
					new_scale : float = 1.0) -> void:
	
	var mesh = new_object(air_shockwave_mesh, target_position, angle, new_scale)
	add_child(mesh)

func colliding_shockwave(target_position : Vector3, angle : Vector3 = Vector3.ZERO,
						new_scale : float = 1.0) -> void:
	
	var node = new_object(colliding_shockwave_mesh, target_position, angle, new_scale)
	add_child(node)

func particle_shockwave(target_position : Vector3, angle : Vector3 = Vector3.ZERO,
						hex_color : String = "#FFFFFF", new_scale : float = 1.0,
						disable_billboard : bool = false) -> void:
	
	var node = new_object(particle_shockwave_mesh, target_position, angle, new_scale)
	node.set_sprite_color(hex_color)
	
	if disable_billboard:
		node.disable_billboard()
	
	add_child(node)
	
#endregion

#region old boss
#func colored_bomb(target_position : Vector3, hex_code : String) -> void:
	#var new_bomb : Node3D = colored_bomb_mesh.instantiate()
	#new_bomb.position = Vector3(target_position.x, 0.0, target_position.z)
	#new_bomb.set_color(hex_code)
	#add_child(new_bomb)
#
### Spawns from the boss' right arm. Homes into the player.
#func right_arm(arm_position : Vector3) -> void:
	#var new_arm : CharacterBody3D = right_arm_mesh.instantiate()
	#new_arm.position = arm_position
	#add_child(new_arm)
#
### Spawns an ice cream cone that launches projectiles.
#func ice_cream_cone(cone_position : Vector3) -> void:
	#var cone : MeshInstance3D = ice_cream_cone_mesh.instantiate()
	#cone.position = cone_position
	#add_child(cone)
#
### Spawns 3 attacks at once on the floor.
#func bombardment(target_position : Vector3) -> void:
	#target_position = Vector3(target_position.x, 0.0, target_position.z)
	#
	#var random_x : float
	#var random_z : float
	#
	#for i in 3:
		#var new_mortar : Node3D = mortar_attack.instantiate()
		#
		#random_x = randf_range(target_position.x - 12.0, target_position.x + 12.0)
		#random_z = randf_range(target_position.z - 12.0, target_position.z + 12.0)
		#
		#target_position = Vector3(random_x, 0.0, random_z)
		#
		#new_mortar.position = target_position
		#add_child(new_mortar)
		#
#
#func ground_slash(target_position : Vector3, angle : Vector3) -> void:
	#var new_slash = sword_attack.instantiate()
	#new_slash.position = Vector3(target_position.x, 0.0, target_position.z)
	#
	## Angle y has 180 degrees added because boss faces the other way around...
	#new_slash.rotation = Vector3(0.0, angle.y + deg_to_rad(180.0), 0.0)
	#
	#add_child(new_slash)
#endregion

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
	
	new_explosion.material_override = new_explosion.mesh.material.duplicate()
	new_explosion.material_override.albedo_color = Color(new_color)
	new_explosion.set_scale(Vector3(new_scale, new_scale, new_scale))
	new_explosion.position = target_position
	new_explosion.disable_sound(disable_sound)
	
	add_child(new_explosion)
