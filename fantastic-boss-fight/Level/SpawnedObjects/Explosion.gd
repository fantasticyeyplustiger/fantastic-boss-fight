extends MeshInstance3D

var sfx : bool = true

func _ready() -> void:
	$AnimationPlayer.play("explode")
	
	if sfx:
		$LargeExplosion.play()

func destroy_self(_anim_name: StringName) -> void:
	queue_free()

func disable_sound(disable : bool) -> void:
	sfx = not disable
