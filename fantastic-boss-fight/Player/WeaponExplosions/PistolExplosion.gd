extends Node3D

func _ready() -> void:
	$AnimationPlayer.play("explode")

func destroy_self(_anim_name: StringName) -> void:
	queue_free()
