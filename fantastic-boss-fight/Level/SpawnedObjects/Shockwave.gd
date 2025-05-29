extends MeshInstance3D

func _ready() -> void:
	$Animation.play("shockwave")

func destroy_self() -> void:
	queue_free()
