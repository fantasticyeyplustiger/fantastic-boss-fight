extends Node3D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("grapple"):
		get_tree().reload_current_scene()
		var bgm = MusicAndGlobalSfx.get_child(0)
		bgm.play(0.0)
