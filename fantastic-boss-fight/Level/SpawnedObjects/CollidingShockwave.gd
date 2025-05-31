extends Node3D

const damage : float = 200.0

func _ready() -> void:
	$Animation.play("shockwave")
	$TorusHitbox.set_deferred("monitorable", true)

func destroy_self(_anim_name : StringName) -> void:
	queue_free()
