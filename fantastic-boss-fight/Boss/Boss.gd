extends CharacterBody3D

## Make sure all Area3Ds correlated to attack hitboxes have Knockback.gd as a script!
## Additionally, every hitbox collision should be DISABLED at start.

enum attacks {PUNCH_RUSH, CLAP}

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

## Has no use as of now because boss doesn't heal.
#const MAX_HEALTH : float = 1_000_000

## All of these trails move with their corresponding body parts.
@onready var right_arm_side_trail = $Torso/RightArmPivot/SideTrail
@onready var left_arm_side_trail = $Torso/LeftArmPivot/SideTrail
@onready var left_arm_behind_trail = $Torso/LeftArmPivot/BehindTrail
@onready var right_fist_trail = $Torso/RightArmPivot/FistTrail
@onready var left_fist_trail = $Torso/LeftArmPivot/FistTrail
#@onready var torso_trail = $Torso/Trail
#@onready var horizontal_torso_trail = $Torso/Trail2

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
	elif can_walk:
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
	
	var attack_cooldown : float
	
	if Global.player_in_air:
		if not previous_attack == attacks.CLAP:
			await clap()
			attack_cooldown = 0.2
	
	else:
		await punch_rush()
		attack_cooldown = 0.5
	
	set_atk_cooldown_in_seconds(attack_cooldown)

#region ATTACKS
## NOTE: All attacks are related to the corresponding animation that plays with them.
## Sync all attacks to the animation!

## Claps the player and produces a massive, damaging shockwave.
func clap() -> void:
	previous_attack = attacks.CLAP
	should_fall = false
	can_walk = false
	damage = HIGH_DAMAGE
	
	$Aura.emitting = true
	$Animations.play("clap")
	
	look_at_player()
	
	await get_tree().create_timer(0.15).timeout
	
	$DashSFX.pitch_scale = 0.3
	$DashSFX.play()
	
	SpawnObject.air_shockwave(global_position, global_rotation - RIGHT_X_ANGLE)
	
	go_to_predicted_position_at_seconds(0.05)
	look_at_player()
	
	toggle_trail(right_arm_side_trail)
	toggle_trail(left_arm_side_trail)
	
	await get_tree().create_timer(0.35).timeout
	
	dashing = true
	dash_towards(Global.player_position)
	toggle_hitbox($Clap/CollisionShape3D)
	
	await get_tree().create_timer(0.1).timeout
	
	var shockwave_position = $Clap/CollisionShape3D.global_position
	
	dashing = false
	$AirExplosionSFX.play()
	SpawnObject.colliding_shockwave(shockwave_position, global_rotation - RIGHT_X_ANGLE - RIGHT_Y_ANGLE)
	toggle_hitbox($Clap/CollisionShape3D)
	
	await get_tree().create_timer(0.2).timeout
	
	can_walk = true
	should_fall = true
	
	await get_tree().create_timer(0.5).timeout
	
	toggle_trail(right_arm_side_trail)
	toggle_trail(left_arm_side_trail)

## Launches rush of 4 attacks one after another.
func punch_rush() -> void:
	previous_attack = attacks.PUNCH_RUSH
	can_walk = false
	should_fall = true
	
	$Aura.emitting = true
	
	# Wait for each attack to happen before starting the next one.
	await right_hook()
	await left_uppercut()
	
	if Global.player_in_air:
		await air_chop()
	else:
		await right_hook()
	
	await slam()
	
	$Aura.emitting = false
	
	await get_tree().create_timer(0.2).timeout
	can_walk = true

## Makes the boss throw a right hook while dashing towards the player.
func right_hook() -> void:
	damage = MED_DAMAGE
	$Animations.play("right_hook")
	
	look_at_player()
	position.y = 0.0
	
	await get_tree().create_timer(0.3).timeout
	
	$DashSFX.pitch_scale = randf_range(0.1, 0.2)
	$DashSFX.play()
	toggle_trail(right_arm_side_trail)
	SpawnObject.air_shockwave(global_position, global_rotation - RIGHT_X_ANGLE)
	global_position = Global.boss_to_player
	position.y = 0.0
	look_at_player()
	
	await get_tree().create_timer(0.2).timeout
	
	$DashSFX.pitch_scale = 1.0
	$DashSFX.play()
	dashing = true
	dash_towards_on_ground(Global.player_position)
	toggle_hitbox($RightHook/CollisionShape3D)
	
	await get_tree().create_timer(0.2).timeout
	
	dashing = false
	toggle_hitbox($RightHook/CollisionShape3D)
	toggle_trail(right_arm_side_trail)
	
	# NO COOLDOWN

## Makes the boss throw a left uppercut while dashing towards the player. Launches the player up.
func left_uppercut() -> void:
	damage = MED_DAMAGE
	$Animations.play("left_uppercut")
	
	look_at_player()
	
	await get_tree().create_timer(0.3).timeout
	
	$DashSFX.pitch_scale = randf_range(0.1, 0.2)
	$DashSFX.play()
	toggle_trail(left_arm_behind_trail)
	SpawnObject.air_shockwave(global_position, global_rotation - RIGHT_X_ANGLE)
	global_position = Global.boss_to_player
	position.y = 0.0
	look_at_player()
	
	await get_tree().create_timer(0.2).timeout
	
	$DashSFX.pitch_scale = 1.0
	$DashSFX.play()
	dashing = true
	dash_towards(Global.player_position)
	toggle_hitbox($LeftUppercut/CollisionShape3D)
	
	await get_tree().create_timer(0.2).timeout
	
	dashing = false
	toggle_hitbox($LeftUppercut/CollisionShape3D)
	toggle_trail(left_arm_behind_trail)
	
	# NO COOLDOWN

## Makes the boss slam his arms into the ground. Launches the player up.
func slam() -> void:
	damage = HIGH_DAMAGE
	$Animations.play("slam")
	$Parryable.emitting = true
	
	look_at_player()
	
	await get_tree().create_timer(0.2).timeout
	
	SpawnObject.air_shockwave(global_position, global_rotation - RIGHT_X_ANGLE)
	toggle_trail(left_fist_trail)
	toggle_trail(right_fist_trail)
	global_position = Global.boss_to_player
	position.y = 0.0
	look_at_player()
	
	await get_tree().create_timer(0.25).timeout
	
	$DashSFX.pitch_scale = randf_range(0.6, 0.9)
	$DashSFX.play()
	dashing = true
	dash_towards_on_ground(Global.player_position)
	
	await get_tree().create_timer(0.2).timeout
	
	SpawnObject.ground_shockwave(global_position)
	$ExplosionSFX.play()
	
	toggle_trail(left_fist_trail)
	toggle_trail(right_fist_trail)
	dashing = false
	toggle_hitbox($Slam/CollisionShape3D)
	
	await get_tree().create_timer(0.1).timeout
	
	toggle_hitbox($Slam/CollisionShape3D)
	$Animations.play("slam_to_reset")
	$Parryable.emitting = false
	
	await get_tree().create_timer(0.5).timeout # ATTACK COOLDOWN

## Makes the boss predict where the player will be and air chop them to the ground in the air.
func air_chop() -> void:
	damage = HIGH_DAMAGE
	$Animations.play("air_chop")
	
	$DashSFX.pitch_scale = 1.5
	$DashSFX.play()
	
	toggle_trail(right_fist_trail)
	toggle_trail(right_arm_side_trail)
	look_at_player()
	SpawnObject.air_shockwave(global_position, global_rotation)
	go_to_predicted_position_at_seconds(0.3)
	
	await get_tree().create_timer(0.4).timeout
	
	$CraterSFX.pitch_scale = randf_range(1.0, 2.0)
	$CraterSFX.play()
	$DashSFX.pitch_scale = randf_range(0.3, 0.5)
	$DashSFX.play()
	
	dashing = true
	dash_towards(Global.player_position)
	toggle_hitbox($AirChop/CollisionShape3D)
	
	await get_tree().create_timer(0.2).timeout
	
	dashing = false
	toggle_hitbox($AirChop/CollisionShape3D)
	toggle_trail(right_arm_side_trail)
	toggle_trail(right_fist_trail)
	
	await get_tree().create_timer(0.1).timeout # ATTACK COOLDOWN

#endregion

## Switches 'visible' of trail to be the opposite state.
# Also edits the length to make trail emitting less noticeable when visible is true again.
func toggle_trail(trail : GPUTrail3D) -> void:
	trail.visible = not trail.visible
	
	if not trail.length <= 1:
		trail.length = 1
	else:
		trail.length = 60 # Frames.

## Switches 'disabled' of collision to be the opposite state.
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

## Resets 'attacking' after the amount of seconds inputted to be false.
func set_atk_cooldown_in_seconds(seconds : float) -> void:
	await get_tree().create_timer(seconds).timeout
	attacking = false

## Resets 'can_walk' after the amount of seconds inputted to be true.
func can_walk_again_in_seconds(seconds : float) -> void:
	await get_tree().create_timer(seconds).timeout
	can_walk = true
