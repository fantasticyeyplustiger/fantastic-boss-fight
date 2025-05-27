extends CharacterBody3D

const JUMP_VELOCITY : float = 9
const GRAVITY : float = 19.6
const WALK_SPEED : float = 5.0
const SPRINT_SPEED : float = 15.0

var SENSITIVITY : float = 0.003
var speed : float = 5.0

@onready var head : Node3D = $Head
@onready var camera : Camera3D = $Head/Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func _physics_process(delta: float) -> void:
	
	if Input.is_action_pressed("dash"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	var input_direction : Vector2 = Input.get_vector("left", "right", "up", "down")
	var direction : Vector3 = (head.transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 5.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 5.0)
		
	
	move_and_slide()
