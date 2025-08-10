extends MeshInstance3D

func _ready() -> void:
	var duplicated_mat = material_override.duplicate()
	material_override = duplicated_mat

## Draws a line between two points and fades it.
# Credits:
# LegionGames "Hitscan Guns, Weapon Switching and Crosshairs - 3D Godot FPS Tutorial"
func initialize(position_one : Vector3, target_position : Vector3) -> void:
	var draw_mesh = ImmediateMesh.new()
	mesh = draw_mesh
	draw_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material_override)
	
	draw_mesh.surface_add_vertex(position_one)
	draw_mesh.surface_add_vertex(target_position)
	
	$Sprite3D.position = position_one
	$Sprite3D.look_at_from_position(position_one, target_position)
	
	draw_mesh.surface_end()
	$Sprite3D.visible = true
	
	$AnimationPlayer.play("fade")


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()
