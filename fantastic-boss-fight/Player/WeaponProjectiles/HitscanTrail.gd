extends MeshInstance3D

class_name HitscanTrail

@export var trail_height : float = 0.008

func _ready() -> void:
	var duplicated_mat = material_override.duplicate()
	material_override = duplicated_mat
	
	# When this trail becomes invisible just queue free
	# Also so it just automatically connects signal
	$AnimationPlayer.connect("animation_finished", destroy_self)

## Draws a plane between two points and fades it.
## Thanks to LegionGames on Youtube for idea of concept
func initialize(position_one : Vector3, target_position : Vector3) -> void:
	
	var trail_size : Vector3 = Vector3(0.0, trail_height, 0.0)
	
	mesh = draw_mesh(position_one, target_position, trail_size)
	
	$Sprite3D.position = position_one
	$Sprite3D.look_at_from_position(position_one, target_position)
	
	$Sprite3D.visible = true
	
	$AnimationPlayer.play("fade")

func draw_mesh(position_one : Vector3, target_position : Vector3, trail_size) -> ImmediateMesh:
	var new_mesh = ImmediateMesh.new()
	
	new_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material_override)
	
	# Essentially draws a 2D plane with 2 triangles
	new_mesh.surface_add_vertex(position_one - trail_size)
	new_mesh.surface_add_vertex(target_position - trail_size)
	new_mesh.surface_add_vertex(position_one + trail_size)
	
	new_mesh.surface_add_vertex(position_one + trail_size)
	new_mesh.surface_add_vertex(target_position + trail_size)
	new_mesh.surface_add_vertex(position_one - trail_size)
	
	new_mesh.surface_end()
	
	return new_mesh

func destroy_self(_anim_name: StringName) -> void:
	queue_free()
