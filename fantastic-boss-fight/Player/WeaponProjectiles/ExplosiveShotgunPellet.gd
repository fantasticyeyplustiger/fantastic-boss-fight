extends ShotgunPellet

func _physics_process(_delta: float) -> void:
	super(_delta)
	
	if pellet.is_colliding():
		SpawnObject.pistol_explosion($LocalMovement/EnemyDetection.get_collision_point())
