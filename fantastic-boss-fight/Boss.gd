extends CharacterBody3D

class_name Boss

'''
Has a whole bunch of utility functions for bosses to use.
Note: This class assumes that the floor's Y position is always 0.0
'''

const LOW_DAMAGE : float = 15.0
const MED_DAMAGE : float = 30.0
const HIGH_DAMAGE : float = 50.0

const WALK_SPEED : float = 10.0
const SPRINT_SPEED : float = 10.0

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

## Multiplies the speed of the dash with this every frame boss is dashing.
## Mainly for making the dash not "static" (not in the programmer sense)
var dash_acceleration : float = 1.0

var should_fall : bool = false
var should_look_at_player : bool = false

## If boss can be parried, set this to true.
## If boss is "punched" with the parry arm while this is true, parried should be set to true.
## Otherwise, nothing happens.
## Easy way to use this is by setting this true at the start of the parry timing window and then
## checking if parried is true at the end of the timing window and code logic accordingly.
var can_be_parried : bool = false

## Check if this is true for parryable attacks.
## See 'can_be_parried' for proper usage.
var parried : bool = false

## Movement logic.
func _physics_process(delta: float) -> void:
	
	var distance_to_player := get_distance_to_player()
	
	# Prevent constant attack calls
	if not attacking:
		attacking = true
		choose_attack()
	# Shouldn't walk towards player while attacking
	elif can_walk and distance_to_player > 5:
		walk_towards_player()
	elif can_walk and distance_to_player <= 5:
		stop_walk_animation()
	
	# Difference between look_at_player() is that this includes X and Z rotation
	if should_look_at_player:
		look_at(Global.player_position + PLAYER_HEAD_POSITION)
	
	if dashing:
		
		if should_fall:
			velocity.y -= GRAVITY * delta
		
		move_and_slide()
		
		velocity *= dash_acceleration
		
	elif not can_walk and should_fall:
		velocity = Vector3.ZERO
		velocity.y -= GRAVITY * delta
	
	Global.boss_position = global_position


func choose_attack() -> void:
	assert(false, "Please override choose_attack()!")
	pass


## Predicts where the player will be at x seconds and makes boss go in front of that position.
func go_to_predicted_position_at_seconds(seconds_to_wait : float) -> void:
	var predicted_position : Vector3 = Global.predict_player_position_at_seconds_for_boss(seconds_to_wait)
	position = predicted_position

## Makes the boss dash towards the position at a high speed.
## Also makes the boss look at that direction.
## 'dashing' is automatically set to true when this function is called.
## 'dash_acceleration' is automatically set to 1.0 to prevent any issues with other attacks
## when this function is called.
func dash_towards(target_position : Vector3, speed : float = SPRINT_SPEED) -> void:
	dashing = true
	var direction = global_position.direction_to(target_position)
	
	# add to global_position so that direction is actually relative to boss
	look_at(global_position + direction)
	rotation.x = 0
	rotation.z = 0
	
	velocity = (direction * speed) * 1.5
	dash_acceleration = 1.0

## Makes the boss go to the ground and dash towards another position on the ground.
## Also makes the boss look at that direction.
## 'dashing' is automatically set to true when this function is called.
## 'target_position' does not need its y-value set to 0.
func dash_towards_on_ground(target_position : Vector3, speed : float = SPRINT_SPEED) -> void:
	global_position.y = 0.0
	
	var ground_target = Vector3(target_position.x, 0.0, target_position.z)
	
	dash_towards(ground_target, speed)

## Sets 'dashing' to be false.
func stop_dashing() -> void:
	dashing = false

## Sets 'dashing' to be false in 'n' seconds.
func stop_dashing_in_seconds(n : float) -> void:
	await seconds(n)
	dashing = false

## Sets the dash acceleration.
## Dash speed will be multiplied with 'n' every frame where 'dashing' is true.
func set_dash_acceleration(n : float) -> void:
	dash_acceleration = n

func stop_walk_animation() -> void:
	pass

## Makes the boss walk towards the player.
## Doesn't play the walk animation automatically.
func walk_towards_player() -> void:
	var direction = get_2d_angle_to_player()
	# play walk animation
	
	velocity = direction * WALK_SPEED
	velocity.y -= GRAVITY * (1.0/60.0)
	
	look_at_player()
	move_and_slide()

## Rotates the boss' y-axis to look at the player.
## Forces boss' x and z rotation axis to be 0.
func look_at_player() -> void:
	
	# Attempt to fix look_at issue.
	if global_position.cross(Global.player_position).is_zero_approx():
		return
	
	look_at(Global.player_position)
	rotation.x = 0
	rotation.z = 0

## Gets the angle from the boss' position to the player on a flat plane.
## IGNORES Y POSITION.
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
func set_atk_cooldown_in_seconds(seconds_to_wait : float) -> void:
	await seconds(seconds_to_wait)
	attacking = false

## Resets 'can_walk' after the amount of seconds inputted to be true.
func can_walk_again_in_seconds(seconds_to_wait : float) -> void:
	await seconds(seconds_to_wait)
	can_walk = true

## Switches 'visible' of trail to be the opposite state.
## Also edits the length to make trail emitting less noticeable when visible is true again.
## 'new_length' is the amount of frames the end of the trail will last.
## Only use 'new_length' if intending to toggle the trails ON. It does nothing otherwise.
func toggle_trail(trail : GPUTrail3D, new_length : int = 60) -> void:
	trail.visible = not trail.visible
	
	if trail.length > 1:
		trail.length = 1
	else:
		trail.length = new_length # Frames.

## Toggles all of the trails in the parent node.
## Ignores any children nodes that aren't trails.
## 'new_length' is the amount of frames the end of the trail will last.
## Only use 'new_length' if intending to toggle the trails ON. It does nothing otherwise.
func toggle_all_trails_in(parent_node : Node3D, new_length : int = 60) -> void:
	
	var children := parent_node.get_children()
	
	for child in children:
		if not child is GPUTrail3D:
			continue
		
		toggle_trail(child, new_length)

## Switches 'disabled' of collision to be the opposite state.
## If collision has Knockback.gd as its script and an Area3D as a parent that
## also has AreaKnockback.gd, set_kb_stats will be called with those two as parameters.
func toggle_hitbox(collision : CollisionShape3D) -> void:
	collision.set_deferred("disabled", not collision.disabled)
	
	# Collision disabled gets changed at the END of the frame, so it hasn't changed yet
	if not collision.disabled:
		return
	
	var parent := collision.get_parent()
	
	if not parent is Area3D:
		return
	
	if parent.get_script() == null:
		return
	
	var script_path : String = parent.get_script().get_path()
	var script_name : String = script_path.get_file().get_basename()
	
	if script_name == "AreaKnockback":
		set_kb_stats(parent, collision)

## Switches 'disabled' of collision to be the opposite state for 'seconds_to_wait'.
## After that period of time, collision will switch back.
## i.e. toggle_hitbox_on_for_seconds(collision, 2.0):
## collision.disabled = true at the start
## collision.disabled = false
## wait 2.0 seconds
## collision.disabled = true again
func toggle_hitbox_on_for_seconds(collision : CollisionShape3D, seconds_to_wait : float) -> void:
	toggle_hitbox(collision)
	await seconds(seconds_to_wait)
	toggle_hitbox(collision)

## Sets the given area's knockback power and launch power to be that of the
## given knockback_collision.
## NOTE: Assumes that both area and knockback_collision have
##       AreaKnockback.gd and Knockback.gd respectively!
func set_kb_stats(area : Area3D, knockback_collision : CollisionShape3D) -> void:
	area.knockback_power = knockback_collision.knockback_power
	area.launch_power = knockback_collision.launch_power

## Waits n seconds.
## NOTE: MUST USE 'await' KEYWORD FOR PROPER USAGE
## Example: await seconds(1).
## 'process_always' will pause when SceneTree is paused unless set to true. This is for parrying.
func seconds(n : float, process_always : bool = false) -> void:
	await get_tree().create_timer(n, process_always).timeout

## Waits n milliseconds.
## NOTE: MUST USE 'await' KEYWORD FOR PROPER USAGE
## Example: await milliseconds(1).
## 'process_always' will pause when SceneTree is paused unless set to true. This is for parrying.
## seconds() is technically more efficient, but the difference is so small it doesn't matter.
func milliseconds(n : float, process_always : bool = false) -> void:
	await seconds(n / 1000, process_always)
