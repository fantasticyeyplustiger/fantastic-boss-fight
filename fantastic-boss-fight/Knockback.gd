extends Area3D

## For knocking back the player if they get hit by this hitbox.
@export var knockback : bool = false
@export var launch_up : bool = false
@export var parryable : bool = false
@export var knockback_power : float = 10.0
