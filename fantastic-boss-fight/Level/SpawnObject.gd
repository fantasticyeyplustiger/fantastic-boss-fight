extends Node3D

@onready var ground_shockwave_mesh = preload("res://Level/SpawnedObjects/GroundShockwave.tscn")

func ground_shockwave(target_position : Vector3) -> void:
	var new_shockwave : MeshInstance3D = ground_shockwave_mesh.instantiate()
	new_shockwave.position = Vector3(target_position.x, 0.0, target_position.z)
	new_shockwave.visible = true
	add_child(new_shockwave)
