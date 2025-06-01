extends Node3D

const damage : float = 100.0

func _ready() -> void:
	$Shockwave.emitting = true
	$Animation.play("explode")

func set_color(hex_code : String) -> void:
	$Sphere.get_surface_override_material(0).albedo_color = Color(hex_code)
	$BombShockwavePart.get_surface_override_material(0).albedo_color = Color(hex_code)

func destroy_self(_anim_name: StringName) -> void:
	queue_free()
