extends Node3D

func _ready() -> void:
	#rotate_y((PI) * delta)
	
	while true:
		
		await get_tree().create_timer(2.5).timeout
		
		var tween : Tween = get_tree().create_tween()
		
		tween.tween_property(self, "position", Vector3(15.0, 5.0, 0.0), 1.0)
		
		await tween.finished
		
		tween = get_tree().create_tween()
		tween.tween_property(self, "position", Vector3(15.0, 5.0, 15.0), 1.0)
		
		await tween.finished
		
		tween = get_tree().create_tween()
		tween.tween_property(self, "position", Vector3(0.0, 5.0, 15.0), 1.0)
		
		await tween.finished
		
		tween = get_tree().create_tween()
		tween.tween_property(self, "position", Vector3(0.0, 5.0, 0.0), 1.0)
		
		await tween.finished

func _physics_process(delta: float) -> void:
	rotate_x((1) * delta)
	rotate_y((1) * delta)
	rotate_z((1) * delta)
	
