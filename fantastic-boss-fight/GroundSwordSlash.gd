extends Node3D

@onready var collisions = $Area3D.get_children()

const damage = 75.0

func _ready() -> void:
	$Animation.play("swing")


func attack(_anim_name: StringName) -> void:
	$Meshes.visible = false
	for collision in collisions:
		collision.set_deferred("disabled", false)
	
	await get_tree().create_timer(0.1).timeout
	queue_free()
