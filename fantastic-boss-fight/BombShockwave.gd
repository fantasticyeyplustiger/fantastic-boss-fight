extends Node3D

func _ready() -> void:
	$Animation.play("shockwave")

func destroy_self(_anim_name : StringName) -> void:
	queue_free()
