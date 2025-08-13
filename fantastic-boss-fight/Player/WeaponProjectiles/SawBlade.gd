extends CharacterBody3D

enum buffs {PUNCHED, RAILGUN, EXPLODED, ORB_SLICED}

const ADD_BUFF_DMG : Dictionary[buffs, float] = {
	buffs.PUNCHED : 1.0,
	buffs.RAILGUN : 3.0,
	buffs.EXPLODED : 0.5,
	buffs.ORB_SLICED : 0.75
}

## How many times it can hit an enemy without dying.
const BASE_ATK_DURABILITY : float = 3.0
## Environment durability, i.e. how many times it can hit the wall or floor without breaking.
const BASE_ENVIRON_DURABILITY : float = 20.0
## In seconds.
const BASE_MAX_ORBIT_TIME : float = 7.5
const BASE_SPEED : float = 35.0

var current_velocity : Vector3
var current_buff_stack : float = 1.0

var max_orbit_time : float = BASE_MAX_ORBIT_TIME
var orbit_time : float
var damage : float
var environment_durability : float = BASE_ENVIRON_DURABILITY
var attack_durability : float = BASE_ATK_DURABILITY

var can_orbit : bool = true
var current_orbit_angle : float


func _ready() -> void:
	rotation = Global.player_rotation
	
	var target_position : Vector3 = $Pivot/VelocityDirection.global_position
	
	velocity = BASE_SPEED * (target_position - $Pivot.global_position)
	current_velocity = velocity

## Moves and ricochets.
func _physics_process(delta: float) -> void:
	move_and_slide()
	
	if $EnvironmentRay.is_colliding():
		ricochet()
	
	can_orbit = orbit_time < max_orbit_time
	
	if can_orbit and Global.sawblades_orbiting:
		orbit_time += delta
		orbit()

func initialize(spawn_position : Vector3, new_damage : float) -> void:
	position = spawn_position
	damage = new_damage

func orbit() -> void:
	
	if not Global.sawblades_orbiting:
		return
	
	var speed_multiplier : float = BASE_SPEED * current_buff_stack * 2.0
	var radius : Vector3 = Global.player_position - global_position
	radius.y += 1.5 # So it's not on the floor
	
	if radius.length() < 2.5:
		return # It shouldn't orbit that close to the player.
	
	var orbit_speed : Vector3 = radius.normalized()
	orbit_speed = orbit_speed.rotated(Vector3.UP, deg_to_rad(60 - orbit_time))
	
	point_ray_towards_velocity(global_position + orbit_speed)
	
	velocity = speed_multiplier * orbit_speed

## Ricochets the sawblade when it hits a surface from the environment.
## i.e. a wall or a floor.
func ricochet() -> void:
	var saw_direction : Vector3 = velocity.normalized()
	var surface_normal : Vector3 = $EnvironmentRay.get_collision_normal()
	
	var new_saw_direction : Vector3 = saw_direction.bounce(surface_normal)
	
	point_ray_towards_velocity(global_position + new_saw_direction)
	
	environment_durability -= 1.0
	velocity = (BASE_SPEED * current_buff_stack) * new_saw_direction.normalized()

## Implement this later.
func damage_enemy(_body: Node3D) -> void:
	
	# damage the enemy here
	
	attack_durability -= 1.0

func add_buff(buff : buffs) -> void:
	damage += ADD_BUFF_DMG[buff]
	max_orbit_time *= 1.5
	
	if buff == buffs.PUNCHED:
		current_buff_stack += 1.0
	elif buff == buffs.RAILGUN:
		current_buff_stack += 2.0

## Points $EnvironmentRay in the same direction as velocity.
func point_ray_towards_velocity(look_direction : Vector3) -> void:
	# Make EnvironmentRay pointed towards velocity direction
	look_at(look_direction)
	rotation.z = 0.0 # Prevents "unwanted rotation around local Z axis"
	$EnvironmentRay.force_raycast_update()
