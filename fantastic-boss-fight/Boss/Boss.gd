extends CharacterBody3D

enum attacks {PUNCH_RUSH}

const LOW_DAMAGE : float = 25.0
const MED_DAMAGE : float = 50.0
const HIGH_DAMAGE : float = 100.0

const WALK_SPEED : float = 7.5
const SPRINT_SPEED : float = 35.0

const GRAVITY : float = 19.6

const PLAYER_HEAD_POSITION : Vector3 = Vector3(0.0, 0.8, 0.0)

const MAX_HEALTH : float = 1_000_000 # in case i ever want to have healing abilities

var health : float = 1_000_000

var attacking : bool = false
var attack_cooldown : bool = true
var can_walk : bool = true
var dashing : bool = false
var should_look_at_player : bool = false
var parrying : bool = false

var previous_attack : attacks
var current_attack : attacks = attacks.PUNCH_RUSH

func _ready() -> void:
	set_atk_cooldown_in_seconds(2.0)

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	if not attacking:
		attacking = true
		choose_attack()
	elif not attacking and can_walk:
		walk_towards_player()
	
	if should_look_at_player:
		look_at(Global.player_position + PLAYER_HEAD_POSITION)
	
	if dashing:
		move_and_slide()
	Global.boss_position = global_position

func choose_attack() -> void:
	# Later on, make dynamic attack loop
	punch_rush()
	pass

func punch_rush() -> void:
	$Animations.play("right_hook")
	
	await get_tree().create_timer(0.2).timeout
	
	global_position = Global.boss_to_player
	look_at_player()
	
	await get_tree().create_timer(0.25).timeout
	
	dash_towards_player_for_seconds(0.2)
	flash_hitbox_on_for_seconds($BodyAttacks/PunchRush/RightHook, 0.2)
	
	await get_tree().create_timer(2.0).timeout
	
	$Animations.play("left_uppercut")
	
	await get_tree().create_timer(0.3).timeout
	
	global_position = Global.boss_to_player
	look_at_player()
	
	await get_tree().create_timer(0.2).timeout
	
	dash_towards_player_for_seconds(0.2)
	flash_hitbox_on_for_seconds($BodyAttacks/PunchRush/LeftUppercut, 0.2)
	
	set_atk_cooldown_in_seconds(2.0)

## Turns the corresponding collision on for x seconds before turning it off again.
func flash_hitbox_on_for_seconds(collision : CollisionShape3D, seconds : float) -> void:
	collision.set_deferred("disabled", false)
	get_tree().create_timer(seconds)
	collision.set_deferred("disabled", true)

## Predicts where the player will be at x seconds and makes boss go in front of that position.
func go_to_predicted_position_at_seconds(seconds : float) -> void:
	var predicted_position : Vector3 = Global.predict_player_position_at_seconds_for_boss(seconds)
	position = predicted_position

## Makes the boss dash towards the player at a high speed.
func dash_towards_player_for_seconds(seconds : float) -> void:
	var vector2_pos = Vector3(global_position.x, 0.0, global_position.z)
	var predicted_pos = Global.predict_player_position_at_seconds(seconds + 0.1)
	var vector2_predicted_pos = Vector3(predicted_pos.x, 0.0, predicted_pos.z)
	
	var direction = vector2_pos.direction_to(vector2_predicted_pos)
	
	velocity = direction * WALK_SPEED
	look_at_player()
	
	dashing = true
	await get_tree().create_timer(seconds).timeout
	dashing = false

## Makes the boss walk towards the player.
func walk_towards_player() -> void:
	var direction = get_2d_angle_to_player()
	# play walk animation
	
	velocity = direction * WALK_SPEED
	
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
