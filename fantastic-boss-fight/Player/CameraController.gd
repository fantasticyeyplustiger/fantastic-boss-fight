extends Node3D

@onready var yaw_node : Node3D = $CamYaw
@onready var pitch_node : Node3D = $CamYaw/CamPitch
@onready var camera : Camera3D = $CamYaw/CamPitch/Camera3D

var camera_rotation : Vector3

var yaw : float = 0.0
var pitch : float = 0.0

var yaw_sensitivity : float = 0.15
var pitch_sensitivity : float = 0.15

var yaw_acceleration : float = 15
var pitch_acceleration : float = 15

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * yaw_sensitivity
		pitch -= event.relative.y * pitch_sensitivity

func _physics_process(_delta: float) -> void:
	yaw_node.rotation_degrees.y = yaw
	pitch_node.rotation_degrees.x = pitch
	camera_rotation = Vector3(yaw, pitch, 1)
