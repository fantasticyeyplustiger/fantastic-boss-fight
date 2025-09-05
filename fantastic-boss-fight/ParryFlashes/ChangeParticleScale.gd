extends GPUParticles3D

func change_scale(new_scale : float) -> void:
	
	var new_process_material := process_material.duplicate()
	
	new_process_material.scale_min = new_scale
	new_process_material.scale_max = new_scale
	
	self.process_material = new_process_material
