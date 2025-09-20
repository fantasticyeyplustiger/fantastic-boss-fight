extends Node

## This script only runs when the game is paused.
## If the player dashes during parry (game gets paused),
## this node will tell the player to immediately dash right after the freeze time.

var player : Player
var parrying : bool = false # Mainly so player can't dash when game is actually meant to be paused.

func _ready() -> void:
	player = self.get_parent()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dash") and parrying:
		player.dashed_during_parry = true
		parrying = false
