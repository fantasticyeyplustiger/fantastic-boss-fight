extends Node

enum fists {PARRY_FIST, HEAVY_FIST, HOOK}

const FIST_DAMAGE : Dictionary[fists, float] = {
	fists.PARRY_FIST : 1.0,
	fists.HEAVY_FIST : 2.5,
	fists.HOOK : 0.5
}

const BOUND_ONE : Vector3 = Vector3(-22.0, 0.0, 23.0)
const BOUND_TWO : Vector3 = Vector3(22.0, 0.0, -23.0)

const HITSCAN_THE_ENEMY_METHOD : String = "get_hitscanned"
const PUNCH_THE_ENEMY_METHOD : String = "get_punched"
const GET_TOP_NODE_METHOD : String = "get_top_node"

@warning_ignore_start("unused_signal")
signal hitscan
signal hitscan_environment_particles
signal hitscan_enemy_particles
signal punch

var current_fist : fists = fists.PARRY_FIST

var difficulty_speed : float = 1.0

var player_position : Vector3

## Useful for seeing where the player is looking at.
var front_of_player : Vector3

## Location where boss should appear in front of the player.
var boss_to_player : Vector3

## Global position where player's camera is.
var camera_position : Vector3

## In radians.
var player_rotation : Vector3

var player_velocity : Vector3

## A hitscan pointing towards where the player's camera is looking at. Roughly 400m long.
var player_target_position : Vector3

## same as player not is_on_floor()
var player_in_air : bool

## Makes sawblades orbit around player if true
var sawblades_orbiting : bool = false

## If true and player punches with Parry Fist, projectile boost.
var can_projectile_boost : bool = false

## Allows projectiles to home into boss.
var boss_position : Vector3

## Predicts where player will be at [param seconds] according to current velocity.
func predict_player_position_at_seconds(seconds : float) -> Vector3:
	var prediction : Vector3 = player_position + (player_velocity * seconds)
	
	# If it's under 0.0, position will be underground and inaccessible.
	if prediction.y < 0.0:
		prediction.y = 0.0
	
	return prediction

## Predicts where player will be at [param seconds] according to current velocity FOR BOSS POSITIONING.[br]
## This is for where the boss should spawn to attack the predicted position.
func predict_player_position_at_seconds_for_boss(seconds : float) -> Vector3:
	var prediction : Vector3 = boss_to_player + (player_velocity * seconds)
	
	# If it's under 0.0, position will be underground and inaccessible.
	if prediction.y < 0.0:
		prediction.y = 0.0
	
	return prediction
