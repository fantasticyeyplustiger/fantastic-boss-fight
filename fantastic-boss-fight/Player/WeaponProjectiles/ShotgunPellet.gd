extends Node3D

class_name ShotgunPellet

const DEFAULT_SPEED : float = 40.0
const PROJECTILE_BOOST_SPEED : float = 70.0

const DELTA : float = 1.0 / 60.0

var damage : float = 0.5
var velocity : Vector3
var pellet : RayCast3D

func _ready() -> void:
	velocity = Vector3.FORWARD * DEFAULT_SPEED
	pellet = $LocalMovement/EnemyDetection
	$LocalMovement.rotation.z = randf_range(0, PI)
	
	await get_tree().create_timer(0.2).timeout
	$LocalMovement/PelletTrail.visible = true
	
	# delete self after 15 seconds of not hitting anything so no lag
	await get_tree().create_timer(15.0).timeout
	
	queue_free()

func projectile_boost() -> void:
	velocity = velocity.normalized() * PROJECTILE_BOOST_SPEED

func _physics_process(_delta: float) -> void:
	$LocalMovement.position += velocity * DELTA
	
	## code stolen from my player script lol
	if pellet.is_colliding():
		if not pellet.get_collider().is_in_group("background"):
			# If it can be hit by the pellet and isn't the background,
			# it's an enemy's hitbox.
			var area := pellet.get_collider()
			
			if area.has_method(Global.HITSCAN_THE_ENEMY_METHOD):
				area.call(Global.HITSCAN_THE_ENEMY_METHOD, damage)
			
		queue_free()
