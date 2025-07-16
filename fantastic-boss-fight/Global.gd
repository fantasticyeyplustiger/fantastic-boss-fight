extends Node

const BOUND_ONE : Vector3 = Vector3(-22.0, 0.0, 23.0)
const BOUND_TWO : Vector3 = Vector3(22.0, 0.0, -23.0)

var player_position : Vector3

# Useful for seeing where the player is looking at.
var front_of_player : Vector3

# Location where boss should appear in front of the player.
var boss_to_player : Vector3

var player_rotation : Vector3
var player_velocity : Vector3
var player_in_air : bool

var boss_position : Vector3

## Predicts where player will be at x seconds according to current velocity.
func predict_player_position_at_seconds(seconds : float) -> Vector3:
	var prediction : Vector3 = player_position + (player_velocity * seconds)
	
	# If it's under 0.0, position will be underground and inaccessible.
	if prediction.y < 0.0:
		prediction.y = 0.0
	
	return prediction

## Predicts where player will be at x seconds according to current velocity FOR BOSS POSITIONING.
# This is for where the boss should spawn to attack the predicted position.
func predict_player_position_at_seconds_for_boss(seconds : float) -> Vector3:
	var prediction : Vector3 = boss_to_player + (player_velocity * seconds)
	
	# If it's under 0.0, position will be underground and inaccessible.
	if prediction.y < 0.0:
		prediction.y = 0.0
	
	return prediction
