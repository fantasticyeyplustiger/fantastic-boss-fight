extends MeshInstance3D

class_name HitscanTrail

@export var trail_height : float = 0.008

func _ready() -> void:
	var duplicated_mat = material_override.duplicate()
	material_override = duplicated_mat

## Draws a line between two points and fades it.
# Credits:
# LegionGames "Hitscan Guns, Weapon Switching and Crosshairs - 3D Godot FPS Tutorial"
func initialize(position_one : Vector3, target_position : Vector3) -> void:
	var draw_mesh = ImmediateMesh.new()
	var trail_size : Vector3 = Vector3(0.0, trail_height, 0.0)
	
	mesh = draw_mesh
	draw_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material_override)
	
	# Essentially draws a 2D plane with 2 triangles
	draw_mesh.surface_add_vertex(position_one - trail_size)
	draw_mesh.surface_add_vertex(target_position - trail_size)
	draw_mesh.surface_add_vertex(position_one + trail_size)
	
	draw_mesh.surface_add_vertex(position_one + trail_size)
	draw_mesh.surface_add_vertex(target_position + trail_size)
	draw_mesh.surface_add_vertex(position_one - trail_size)
	
	$Sprite3D.position = position_one
	$Sprite3D.look_at_from_position(position_one, target_position)
	
	draw_mesh.surface_end()
	$Sprite3D.visible = true
	
	$AnimationPlayer.play("fade")


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()
