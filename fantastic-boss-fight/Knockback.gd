extends CollisionShape3D

class_name Knockback

## NOTE:
## If you use this script, it is assumed that you are using it on a
## collision shape with an Area3D parent and some kind of Body3D parent.
## 
## It is also assumed that this is for an "enemy" attack.
##
## The player's script automatically tries to get the damage from the
## parent of the parent of this node when its hit.
##
## Example:
## 
## CharacterBody3D ( has "damage" variable )
## |_ Area3D
##    |_ CollisionShape3D ( has Knockback.gd script )
##
## As a side note, the Area3D should have "ENEMY_ATTACKS" collision
## layer on only with no collision masks.
##
## KNOCKBACK FORMULA:
## velocity -= (position_of_kb - global_position).normalized() * knockback_power
## velocity.y = launch_power


## For knocking back the player if they get hit by this hitbox.
## Note: Player knockback direction comes from the AREA's position, not CollisionShape3D
@export var knockback_power : float = 5.0

## Launches player up if they get hit by this hitbox.
## Note: Player knockback direction comes from the AREA's position, not CollisionShape3D
@export var launch_power : float = 0.0

## Whether or not attack is parryable.
## DEPRECATED. Please use a separate hitbox for parry collisions!
#@export var parryable : bool = false
