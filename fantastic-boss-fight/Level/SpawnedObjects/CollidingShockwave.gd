extends Node3D

const damage : float = 25.0

var sound_disabled : bool = false

func _ready() -> void:
	$Animation.play("shockwave")
	$Animation.speed_scale /= (Global.difficulty_speed * 0.6)
	$TorusHitbox.set_deferred("monitorable", true)
	
	if not sound_disabled:
		$ShockwaveSFX.play()
	
	var tween_1 : Tween = get_tree().create_tween()
	var tween_2 : Tween = get_tree().create_tween()
	var animation_time : float = 1 / (Global.difficulty_speed * 0.6)
	
	tween_1.tween_property(self, "scale", Vector3(75.0, 3.4, 75.0), animation_time)
	tween_2.tween_property($MeshInstance3D2,
	"transparency", 1.0, animation_time).from_current().set_ease(Tween.EASE_IN)

func destroy_self(_anim_name : StringName) -> void:
	queue_free()

func disable_sound() -> void:
	sound_disabled = true
