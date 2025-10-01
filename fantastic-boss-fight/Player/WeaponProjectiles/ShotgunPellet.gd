extends Node3D

const DEFAULT_SPEED : float = 6.0
const PROJECTILE_BOOST_SPEED : float = 10.0

const DELTA : float = 1.0 / 60.0

var damage : float = 0.5
var velocity : Vector3
var pellet : RayCast3D

func _ready() -> void:
	look_at(global_position + velocity)
	pellet = $EnemyDetection

## Gives the shotgun pellet its velocity. Pellet will look at direction of velocity.
func initialize(direction : Vector3) -> void:
	velocity = direction * DEFAULT_SPEED

func projectile_boost() -> void:
	velocity = velocity.normalized() * PROJECTILE_BOOST_SPEED

func _physics_process(_delta: float) -> void:
	position += velocity * DELTA
	
	## code stolen from my player script lol
	if pellet.is_colliding():
		if not pellet.get_collider().is_in_group("background"):
			# If it can be hit by the pellet and isn't the background,
			# it's an enemy's hitbox.
			var area := pellet.get_collider()
			
			if area.has_method(Global.HITSCAN_THE_ENEMY_METHOD):
				area.call(Global.HITSCAN_THE_ENEMY_METHOD, damage)
			
			queue_free()
