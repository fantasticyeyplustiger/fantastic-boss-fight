extends Node3D
class_name TrailRenderer

#############################
# EXPORT PARAMS
#############################
# width
@export var width: float = 0.5
@export var width_curve: Curve
# length
@export var max_points := 100
@export var material: Material
# show or hide
@export var show_render: bool = true


#############################
# PARAMS
#############################
@onready var half_width = width * 0.5
var points := []
var render : MeshInstance3D

#############################
# OVERRIDE FUNCTIONS
#############################
func _ready() -> void:
	
	render = MeshInstance3D.new()
	render.name = "Render"
	self.add_child(render)


func _process(_delta: float) -> void:
	if show_render:
		# add new point and render
		add_point()
		_draw_trail()
	else:
		# slowly hide the trail
		if points.size() > 0:
			var last_point = points.pop_back()
			last_point.queue_free()


#############################
# API
#############################
func add_point() -> void:
	var new_point = Transform3D()
	new_point.origin = self.global_position
	new_point.basis.x = self.global_transform.basis.get_euler()
	
	points.insert(0, new_point)
	
	if points.size() > max_points:
		points.pop_back()
		

func _draw_trail() -> void:
	if points.size() < 2:
		return
	# create surface tool
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# draw triangles
	for i in range(points.size() - 1):
		_points_to_rect(st, points[i], points[i + 1], i)
	
	# commit
	st.generate_normals()
	st.generate_tangents()

	render.mesh = st.commit()
	render.set_surface_override_material(0, material)


func _points_to_rect(st: SurfaceTool, p1: Transform3D, p2: Transform3D, idx: float) -> void:
	var num_points = points.size() - 1
	
	var offset1 = idx / num_points
	var mod1 = half_width * width_curve.sample(offset1)
	
	var v1 = (p1.origin + p1.basis.x * mod1) + global_position
	var uv1 = Vector2(0, offset1)
	
	var v2 = (p1.origin - p1.basis.x * mod1) + global_position
	var uv2 = Vector2(1, offset1)
	
	var offset2 = (idx + 1) / num_points
	var mod2 = half_width * width_curve.sample(offset2)
	
	var v3 = (p2.origin + p2.basis.x * mod2) + global_position
	var uv3 = Vector2(0, offset2)
	
	var v4 = (p2.origin - p2.basis.x * mod2) + global_position
	var uv4 = Vector2(1, offset2)
	
	st.set_uv(uv1)
	st.add_vertex(v1)
	st.set_uv(uv2)
	st.add_vertex(v2)
	st.set_uv(uv3)
	st.add_vertex(v3)
	
	st.set_uv(uv3)
	st.add_vertex(v3)
	st.set_uv(uv2)
	st.add_vertex(v2)
	st.set_uv(uv1)
	st.add_vertex(v1)
	
	st.set_uv(uv3)
	st.add_vertex(v3)
	st.set_uv(uv4)
	st.add_vertex(v4)
	st.set_uv(uv2)
	st.add_vertex(v2)
	
	st.set_uv(uv2)
	st.add_vertex(v2)
	st.set_uv(uv4)
	st.add_vertex(v4)
	st.set_uv(uv3)
	st.add_vertex(v3)
