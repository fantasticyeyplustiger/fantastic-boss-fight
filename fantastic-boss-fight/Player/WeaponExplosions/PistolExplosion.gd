extends Node3D

func _ready() -> void:
	# Check if it hit an orb or saw before regularly exploding
	$AnimationPlayer.play("explode")

func destroy_self(_anim_name: StringName) -> void:
	queue_free()
