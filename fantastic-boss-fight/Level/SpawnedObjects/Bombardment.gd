extends Node3D

const damage : float = 35

# Hex codes for bomb color
const BROWN : String = "#964B00"
const PINK : String = "#FFC0CB"
const WHITE : String = "FFFFFF"

var color : String

func _ready() -> void:
	$Animations.play("bomb")
	var random_color : int = randi_range(0, 2)
	
	match random_color:
		0: color = BROWN
		1: color = PINK
		2: color = WHITE

func bomb(_anim_name: StringName) -> void:
	SpawnObject.air_shockwave(global_position, Vector3.ZERO)
	SpawnObject.bomb_shockwave(global_position)
	
	$Area3D/Hitbox.set_deferred("disabled", false)
	
	await get_tree().create_timer(0.25).timeout
	$Area3D/Hitbox.set_deferred("disabled", true)
	
	SpawnObject.colored_bomb(global_position, color)
	
	queue_free()
