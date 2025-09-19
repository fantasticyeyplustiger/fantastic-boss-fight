extends Node3D

func _ready() -> void:
	
	for child in self.get_children():
		
		if not child is MeshInstance3D:
			continue
		
		var new_position : Vector3
		new_position.x = randf_range(-1.0, 1.0)
		new_position.y += randf_range(-0.1, 0.1)
		new_position.z = randf_range(-0.5, 0.5)
		
		child.position = new_position
		
		var new_rotation : Vector3
		new_rotation.x = randf_range(0.0, PI * 2)
		new_rotation.y = randf_range(0.0, PI * 2)
		new_rotation.z = randf_range(0.0, PI * 2)
		
		var new_scale : float = randf_range(1.2, 1.8)
		child.scale *= Vector3(new_scale, new_scale, new_scale)
		
		child.rotation = new_rotation
	
	var disappearing_time : float = randf_range(1.0, 2.5)
	
	await get_tree().create_timer(disappearing_time).timeout
	
	for child in self.get_children():
		
		if not child is MeshInstance3D:
			continue
		
		var tween : Tween = get_tree().create_tween()
		
		tween.tween_property(
			child,
			"transparency",
			1.0,
			disappearing_time / 2.0
		)
	
	await get_tree().create_timer(5.0).timeout
	
	queue_free()
