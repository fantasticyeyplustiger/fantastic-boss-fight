extends Node3D

func _ready() -> void:
	await get_tree().create_timer(2.0).timeout
	
	for child in self.get_children():
		
		if not child is MeshInstance3D:
			continue
		
		var tween : Tween = get_tree().create_tween()
		
		tween.tween_property(
			child,
			"transparency",
			1.0,
			3.0
		)
	
	await get_tree().create_timer(4.5).timeout
	
	queue_free()
