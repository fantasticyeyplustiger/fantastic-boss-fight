extends MeshInstance3D

## An ice cream cone that launches balls of deadly ice cream from the sky to the ground.
## Think of it as a mortar.

var attacks : int = 0

func _ready() -> void:
	$Animation.play("appear")
	await get_tree().create_timer(2.0).timeout
	attack()


func attack() -> void:
	attacks += 1
	
	await get_tree().create_timer(0.2).timeout
	
	if attacks > 8:
		queue_free()
		return
	
	SpawnObject.air_shockwave($Twinkle.global_position, Vector3.ZERO)
	SpawnObject.bombardment(Global.player_position)
	$Twinkle.restart()
	$Sparks.restart()
