extends Node3D

const damage : float = 25.0

func _ready() -> void:
	$Animation.play("shockwave")
	$TorusHitbox.set_deferred("monitorable", true)
	$ShockwaveSFX.play()

func destroy_self(_anim_name : StringName) -> void:
	queue_free()
