extends Area3D

## Further info can be found in the regular Knockback.gd script.

## For knocking back the player if they get hit by this hitbox.
## NOTE: Player knockback direction comes from the AREA's position, not CollisionShape3D
@export var knockback_power : float = 5.0

## Launches player up if they get hit by this hitbox.
## NOTE: Player knockback direction comes from the AREA's position, not CollisionShape3D
@export var launch_power : float = 0.0

## Whether or not attack is parryable.
## DEPRECATED. Please use a separate hitbox for parry collisions!
#@export var parryable : bool = false
