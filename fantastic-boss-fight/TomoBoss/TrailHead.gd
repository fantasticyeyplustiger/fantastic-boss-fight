extends Node3D

class_name TomoTrailHead

static var material_hue : float = 0.0

var material : ShaderMaterial
var material_color : Color = Color(0.934, 1.353, 1.353)
var previous_position : Vector3 = Vector3.ZERO

var orb_material : ShaderMaterial

var parent : Node
var velocity : float
var transparency : float

func _ready() -> void:
	material = $Surrounding.get_surface_override_material(0)
	orb_material = $Orb.get_surface_override_material(0)
	
	parent = self.get_parent_node_3d()
	
	if parent == null:
		set_physics_process(false)
	
	$Sparks.draw_pass_1.size *= self.scale.length() / 2.0
	$Sparks2.draw_pass_1.size *= self.scale.length() / 2.0
	
	

func _physics_process(_delta: float) -> void:
	
	# per second not per frame
	velocity = (previous_position.distance_to(global_position)) * 60.0
	
	if velocity > 5.0:
		transparency = 0.0
	else:
		transparency = lerpf(transparency, clampf(1.0 - (velocity / 5.0), 0.0, 0.9), 0.02)
	
	material_color.h = material_hue
	
	material.set_shader_parameter("TomoTrailHeadColor", material_color)
	material.set_shader_parameter("AnimationSpeed", Vector2(0.0, velocity + 1.0))
	material.set_shader_parameter("Transparency", transparency)
	orb_material.set_shader_parameter("Transparency", transparency * 2.0)
	
	$Ring.transparency = transparency * 3.0
	
	$Sparks.emitting = not global_position == previous_position or not parent.visible
	$Sparks2.emitting = $Sparks.emitting
	
	previous_position = global_position
