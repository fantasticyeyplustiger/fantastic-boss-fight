extends Area3D

## For knocking back the player if they get hit by this hitbox.
@export var knockback_power : float = 5.0
## Launches player up if they get hit by this hitbox.
@export var launch_power : float = 0.0
## Whether or not attack is parryable.
@export var parryable : bool = false
