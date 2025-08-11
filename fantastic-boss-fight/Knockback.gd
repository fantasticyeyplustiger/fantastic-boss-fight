extends Area3D

## For knocking back the player if they get hit by this hitbox.
## Note: Player knockback direction comes from the AREA's position, not CollisionShape3D
@export var knockback_power : float = 5.0
## Launches player up if they get hit by this hitbox.
## Note: Player knockback direction comes from the AREA's position, not CollisionShape3D
@export var launch_power : float = 0.0
## Whether or not attack is parryable.
@export var parryable : bool = false
