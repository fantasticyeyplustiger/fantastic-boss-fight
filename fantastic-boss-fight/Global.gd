extends Node

const BOUND_ONE : Vector3 = Vector3(-22.0, 0.0, 23.0)
const BOUND_TWO : Vector3 = Vector3(22.0, 0.0, -23.0)

var player_position : Vector3
var front_of_player : Vector3 # Useful for seeing where the player is looking at.
var boss_to_player : Vector3 # Location where boss should appear in front of the player.
var player_rotation : Vector3
var player_in_air : bool

var boss_position : Vector3
