extends Node3D

func _ready() -> void:
	$Animation.play("shockwave")

func destroy_self(_anim_name : StringName) -> void:
	queue_free()

func set_sprite_color(hex_color : String) -> void:
	$Sprite3D.modulate = Color(hex_color)

func disable_billboard() -> void:
	$Sprite3D.billboard = BaseMaterial3D.BILLBOARD_DISABLED
