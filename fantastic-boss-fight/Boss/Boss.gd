extends CharacterBody3D

## Make sure all Area3Ds correlated to attack hitboxes have Knockback.gd as a script!

enum attacks {PUNCH_RUSH}

const LOW_DAMAGE : float = 15.0
const MED_DAMAGE : float = 30.0
const HIGH_DAMAGE : float = 50.0

const WALK_SPEED : float = 7.5
const SPRINT_SPEED : float = 35.0

const GRAVITY : float = 19.6

const PLAYER_HEAD_POSITION : Vector3 = Vector3(0.0, 0.8, 0.0)
## 90 degrees on the x-axis. Mainly for air shockwaves to be rotated.
const RIGHT_X_ANGLE : Vector3 = Vector3(0.5, 0.0, 0.0)

const MAX_HEALTH : float = 1_000_000 # in case i ever want to have healing abilities

var health : float = 1_000_000
var damage : float

var attacking : bool = true
var can_walk : bool = true

## If turned true, have 'dash_towards()' used right after.
var dashing : bool = false

var should_fall : bool = false
var should_look_at_player : bool = false
var parrying : bool = false

var previous_attack : attacks
var current_attack : attacks = attacks.PUNCH_RUSH

func _ready() -> void:
	set_atk_cooldown_in_seconds(2.0)

func _physics_process(delta: float) -> void:
	
	# Prevent constant attack calls
	if not attacking:
		attacking = true
		choose_attack()
	# Shouldn't walk towards player while attacking
	elif not attacking and can_walk:
		walk_towards_player()
	
	# Difference between look_at_player() is that this includes X and Z rotation
	if should_look_at_player:
		look_at(Global.player_position + PLAYER_HEAD_POSITION)
	
	if dashing:
		
		if should_fall:
			velocity.y -= GRAVITY * delta
		
		move_and_slide()
		
	elif not can_walk and should_fall:
		velocity = Vector3.ZERO
		velocity.y -= GRAVITY * delta
	
	Global.boss_position = global_position

func choose_attack() -> void:
	# Later on, make dynamic attack loop
	punch_rush()
	pass

func punch_rush() -> void:
	should_fall = true
	# Wait for each attack before starting the next one.
	await right_hook()
	await left_uppercut()
	await set_atk_cooldown_in_seconds(1.0)

## Makes the boss throw a right hook while dashing towards the player.
func right_hook() -> void:
	damage = MED_DAMAGE
	$Animations.play("right_hook")
	
	look_at_player()
	
	await get_tree().create_timer(0.3).timeout
	
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	global_position = Global.boss_to_player
	look_at_player()
	
	await get_tree().create_timer(0.2).timeout
	
	dashing = true
	dash_towards(Global.player_position)
	toggle_hitbox($RightHook/CollisionShape3D)
	
	await get_tree().create_timer(0.2).timeout
	
	dashing = false
	toggle_hitbox($RightHook/CollisionShape3D)
	
	await get_tree().create_timer(0.1).timeout # COOLDOWN

## Makes the boss throw a left uppercut while dashing towards the player. Launches the player up.
func left_uppercut() -> void:
	damage = HIGH_DAMAGE
	$Animations.play("left_uppercut")
	
	look_at_player()
	
	await get_tree().create_timer(0.3).timeout
	
	SpawnObject.air_shockwave(global_position, global_rotation + RIGHT_X_ANGLE)
	global_position = Global.boss_to_player
	look_at_player()
	
	await get_tree().create_timer(0.2).timeout
	
	dashing = true
	dash_towards(Global.player_position)
	toggle_hitbox($LeftUppercut/CollisionShape3D)
	
	await get_tree().create_timer(0.2).timeout
	
	dashing = false
	toggle_hitbox($LeftUppercut/CollisionShape3D)
	
	await get_tree().create_timer(0.1).timeout # COOLDOWN

## Turns the corresponding collision on for x seconds before turning it off again.
# Mainly for turning attack hitboxes on and off.
func toggle_hitbox(collision : CollisionShape3D) -> void:
	collision.set_deferred("disabled", not collision.disabled)

## Predicts where the player will be at x seconds and makes boss go in front of that position.
func go_to_predicted_position_at_seconds(seconds : float) -> void:
	var predicted_position : Vector3 = Global.predict_player_position_at_seconds_for_boss(seconds)
	position = predicted_position

## Makes the boss dash towards the position at a high speed.
# Also makes the boss look at that direction.
func dash_towards(target_position : Vector3) -> void:
	var direction = global_position.direction_to(target_position)
	
	# add to global_position so that direction is actually relative to boss
	look_at(global_position + direction)
	rotation.x = 0
	rotation.z = 0
	
	velocity = (direction * SPRINT_SPEED) * 1.5

## Makes the boss walk towards the player.
func walk_towards_player() -> void:
	var direction = get_2d_angle_to_player()
	# play walk animation
	
	velocity = direction * WALK_SPEED
	velocity.y -= GRAVITY * (1.0/60.0)
	
	look_at_player()
	move_and_slide()

## Rotates the boss' y-axis to look at the player.
# Forces boss' x and z rotation axis to be 0.
func look_at_player() -> void:
	
	if global_position.cross(Global.player_position).is_zero_approx(): # Attempt to fix look_at issue.
		return
	
	look_at(Global.player_position)
	rotation.x = 0
	rotation.z = 0

## Gets the angle from the boss' position to the player on a flat plane.
# IGNORES Y POSITION.
func get_2d_angle_to_player() -> Vector3:
	var vector2_pos = Vector3(global_position.x, 0.0, global_position.z)
	var vector2_player_pos = Vector3(Global.player_position.x, 0.0, Global.player_position.z)
	
	var direction : Vector3 = vector2_pos.direction_to(vector2_player_pos)
	
	return direction

## Gets the distance to the player in LENGTH, not as a pure Vector3.
func get_distance_to_player() -> float:
	return (global_position - Global.player_position).length()

## Resets 'attacking' after the amount of seconds inputted to be false.
func set_atk_cooldown_in_seconds(seconds : float) -> void:
	await get_tree().create_timer(seconds).timeout
	attacking = false

## Resets 'can_walk' after the amount of seconds inputted to be true.
func can_walk_again_in_seconds(seconds : float) -> void:
	await get_tree().create_timer(seconds).timeout
	can_walk = true
