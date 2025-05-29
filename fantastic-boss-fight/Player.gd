extends CharacterBody3D

const JUMP_VELOCITY : float = 9.0
const GRAVITY : float = 19.6
const WALK_SPEED : float = 15.0
const SPRINT_SPEED : float = 25.0

var SENSITIVITY : float = 0.003

var speed : float = 15.0
var jump : float = 9.0

var health : float = 5000.0

var can_move : bool = true
var parrying : bool = false

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
		jump = JUMP_VELOCITY * 2
	else:
		speed = WALK_SPEED
		jump = JUMP_VELOCITY
	
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump
	
	if Input.is_action_just_pressed("parry") and not parrying:
		parrying = true
		parry()
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# (For movement direction.)
	var input_direction : Vector2 = Input.get_vector("left", "right", "up", "down")
	var direction : Vector3 = (head.transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	
	if is_on_floor() and can_move:
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	elif can_move: # Being in mid-air means you have inertia
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 5.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 5.0)
	
	Global.player_in_air = not is_on_floor()
	Global.player_position = global_position
	move_and_slide()

func parry() -> void:
	await get_tree().create_timer(1.0).timeout
	parrying = false

func get_hit(area: Area3D) -> void:
	if not parrying or (parrying and not area.parryable):
		health -= area.get_parent().damage
	else:
		print("successful parry")
	
	if health <= 0.0:
		can_move = false
	
	if area.knockback:
		get_knockbacked(area.global_position, area.launch_up)

func get_knockbacked(position_of_kb : Vector3, launch_up : bool) -> void:
	velocity -= (position_of_kb.normalized() - global_position.normalized()) * 10
	if launch_up:
		velocity.y = 35.0
	else:
		velocity.y = 0.0
	
	print(velocity)
	move_and_slide()
