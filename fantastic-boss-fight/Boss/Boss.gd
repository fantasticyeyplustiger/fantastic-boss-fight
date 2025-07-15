extends CharacterBody3D

enum ATTACKS {}

const LOW_DAMAGE : float = 25.0
const MED_DAMAGE : float = 50.0
const HIGH_DAMAGE : float = 100.0

const WALK_SPEED : float = 7.5
const SPRINT_SPEED : float = 35.0

const GRAVITY : float = 19.6

const PLAYER_HEAD_POSITION : Vector3 = Vector3(0.0, 0.8, 0.0)

const MAX_HEALTH : float = 1_000_000 # in case i ever want to have healing abilities

var health : float = 1_000_000

var attacking : bool = false # failsafe for attack cooldown
var attack_cooldown : bool = true # should always
var can_walk : bool = true
var should_look_at_player : bool = false
var parrying : bool = false

var previous_attack

func _ready() -> void:
	reset_atk_cooldown_in_seconds(2.0)

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	if not attacking and not attack_cooldown:
		attacking = true
		choose_attack()
	elif not attacking and can_walk:
		walk_towards_player()
	
	if should_look_at_player:
		look_at(Global.player_position + PLAYER_HEAD_POSITION)
	
	Global.boss_position = global_position

func choose_attack() -> void:
	# Later on, make dynamic attack loop
	punch_rush()
	pass

func punch_rush() -> void:
	go_to_predicted_position_at_seconds(0.6)
	$Animations.play("right_hook")

## Predicts where the player will be at x seconds and makes boss go in front of that position.
func go_to_predicted_position_at_seconds(seconds : float) -> void:
	var predicted_position : Vector3 = Global.predict_player_position_at_seconds_for_boss(seconds)
	position = predicted_position

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

func get_distance_to_player() -> float:
	return (global_position - Global.player_position).length()

## Resets 'attack_cooldown' after the amount of seconds inputted to false.
func reset_atk_cooldown_in_seconds(seconds : float) -> void:
	await get_tree().create_timer(seconds).timeout
	attack_cooldown = false

## Resets 'can_walk' after the amount of seconds inputted to true.
func can_walk_again_in_seconds(seconds : float) -> void:
	await get_tree().create_timer(seconds).timeout
	can_walk = true
