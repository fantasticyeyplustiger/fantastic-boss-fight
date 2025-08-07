extends CharacterBody3D

class_name Boss

const LOW_DAMAGE : float = 15.0
const MED_DAMAGE : float = 30.0
const HIGH_DAMAGE : float = 50.0

const WALK_SPEED : float = 5.0
const SPRINT_SPEED : float = 40.0

const GRAVITY : float = 19.6

## Where the player's camera is located relative to 'player_position'.
const PLAYER_HEAD_POSITION : Vector3 = Vector3(0.0, 0.8, 0.0)

## Approximately 90 degrees on the x-axis. Mainly for air shockwaves to be rotated.
const RIGHT_X_ANGLE : Vector3 = Vector3(1.571, 0.0, 0.0)

## Approximately 90 degrees on the y-axis. Makes air shockwaves perpendicular to the boss' face.
const RIGHT_Y_ANGLE : Vector3 = Vector3(0.0, 1.571, 0.0)

var health : float = 1_000_000
var damage : float

var attacking : bool = true
var can_walk : bool = true

## If turned true, have 'dash_towards()' used right after.
var dashing : bool = false

var should_fall : bool = false
var should_look_at_player : bool = false
var parrying : bool = false

#region Utility functions

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

## Makes the boss go to the ground and dash towards another position on the ground.
# Also makes the boss look at that direction.
# 'target_position' does not need its y-value set to 0.
func dash_towards_on_ground(target_position : Vector3) -> void:
	global_position.y = 0.0
	
	var ground_target = Vector3(target_position.x, 0.0, target_position.z)
	
	dash_towards(ground_target)

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

## Gets the distance to the player on a 2D plane in LENGTH, not as a pure Vector3.
func get_2d_distance_to_player() -> float:
	var boss_position : Vector2 = Vector2(global_position.x, global_position.z)
	var player_position : Vector2 = Vector2(Global.player_position.x, Global.player_position.z)
	
	return (boss_position - player_position).length()

## Resets 'attacking' after the amount of seconds inputted to be false.
func set_atk_cooldown_in_seconds(seconds : float) -> void:
	await get_tree().create_timer(seconds).timeout
	attacking = false

## Resets 'can_walk' after the amount of seconds inputted to be true.
func can_walk_again_in_seconds(seconds : float) -> void:
	await get_tree().create_timer(seconds).timeout
	can_walk = true
#endregion
