extends MeshInstance3D

func _ready() -> void:
	$AnimationPlayer.play("explode")
	$LargeExplosion.play()

func destroy_self(_anim_name: StringName) -> void:
	queue_free()
