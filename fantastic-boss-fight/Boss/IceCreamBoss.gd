extends Boss

class_name IceCreamBoss

## Make sure all Area3Ds correlated to attack hitboxes have Knockback.gd as a script!
## Additionally, every hitbox collision should be DISABLED at start.

enum attacks {PUNCH_RUSH, CLAP}

## Has no use as of now because boss doesn't heal.
#const MAX_HEALTH : float = 1_000_000

@export var testing : bool = false

## All of these trails move with their corresponding body parts.
@onready var right_arm_side_trail = $Torso/RightArmPivot/SideTrail
@onready var left_arm_side_trail = $Torso/LeftArmPivot/SideTrail
@onready var left_arm_behind_trail = $Torso/LeftArmPivot/BehindTrail
@onready var right_fist_trail = $Torso/RightArmPivot/FistTrail
@onready var left_fist_trail = $Torso/LeftArmPivot/FistTrail
#@onready var torso_trail = $Torso/Trail
#@onready var horizontal_torso_trail = $Torso/Trail2

var previous_attack : attacks
var current_attack : attacks = attacks.PUNCH_RUSH

func _ready() -> void:
	
	if testing:
		set_physics_process(false)
	
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
