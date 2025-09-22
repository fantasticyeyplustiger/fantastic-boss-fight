extends Node3D

@export var position_range : Vector3
@export var rotation_range : Vector3
@export var scale_range_one : Vector3
@export var scale_range_two : Vector3
@export var has_GPUParticles3D : bool

func _ready() -> void:
	
	if has_GPUParticles3D:
		$GPUParticles3D.emitting = true
	
	for child in self.get_children():
		
		if not child is MeshInstance3D:
			continue
		
		if randi_range(0, 2) == 2:
			child.queue_free()
			continue
		
		var new_position : Vector3
		new_position.x += randf_range(-position_range.x, position_range.x)
		new_position.y += randf_range(-position_range.y, position_range.y)
		new_position.z += randf_range(-position_range.z, position_range.z)
		
		child.position = new_position
		
		var new_rotation : Vector3
		new_rotation.x = randf_range(0.0, rotation_range.x)
		new_rotation.y = randf_range(0.0, rotation_range.y)
		new_rotation.z = randf_range(0.0, rotation_range.z)
		
		var new_scale : Vector3
		new_scale.x = randf_range(scale_range_one.x, scale_range_two.x)
		new_scale.y = randf_range(scale_range_one.y, scale_range_two.y)
		new_scale.z = randf_range(scale_range_one.z, scale_range_two.z)
		child.scale *= new_scale
		
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
