extends Node

const BOUND_ONE : Vector3 = Vector3(-22.0, 0.0, 23.0)
const BOUND_TWO : Vector3 = Vector3(22.0, 0.0, -23.0)

var player_position : Vector3
var front_of_player : Vector3 # Useful for seeing where the player is looking at.
var boss_to_player : Vector3 # Location where boss should appear in front of the player.
var player_rotation : Vector3
var player_velocity : Vector3
var player_in_air : bool
var predicted_player_position : Vector3

var boss_position : Vector3

## Predicts where player will be at x seconds according to current velocity.
func predict_player_position_at_seconds(seconds : float) -> Vector3:
	return player_position + (player_velocity * seconds)

## Predicts where player will be at x seconds according to current velocity FOR BOSS POSITIONING.
# This is for where the boss should spawn to attack the predicted position.
func predict_player_position_at_seconds_for_boss(seconds : float) -> Vector3:
	return boss_to_player + (player_velocity * seconds)
