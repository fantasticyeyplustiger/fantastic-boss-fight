extends CharacterBody3D

const JUMP_VELOCITY : float = 18.0
const GRAVITY : float = 19.6
const WALK_SPEED : float = 25.0
const SPRINT_SPEED : float = 25.0
const PLAYER_HEAD_POSITION : Vector3 = Vector3(0.0, 0.8, 0.0)

var CAMERA_SENSITIVITY : float = 0.003

var speed : float = 25.0
var jump : float = 18.0

var health : float = 5000.0

var can_move : bool = true
var parrying : bool = false
var parry_cooldown : bool = false

@onready var head : Node3D = $Head
@onready var camera : Camera3D = $Head/Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$PlayerGUI.hp.text = "HP: " + str(int(roundf(health)))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * CAMERA_SENSITIVITY)
		camera.rotate_x(-event.relative.y * CAMERA_SENSITIVITY)
		camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		
		$FrontOfBodyPivot.rotation.y = head.rotation.y
		$FrontOfBodyPivot/SecondPivot.rotation.x = camera.rotation.x


func _physics_process(delta: float) -> void:
	
	if Input.is_action_just_pressed("dash"):
		pass # Maybe a movement skill or something later
	
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump
	
	if Input.is_action_just_pressed("parry") and not parrying and not parry_cooldown:
		parrying = true
		parry_cooldown = true
		parry() # 0.25-second window for parrying, 0.5-second cooldown.
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	if Input.is_action_just_pressed("crush"):
		velocity.y -= 70.0
	
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
	Global.front_of_player = $FrontOfBodyPivot/FrontOfBody.global_position
	Global.player_rotation = Vector3($FrontOfBodyPivot.global_rotation.x, $FrontOfBodyPivot/SecondPivot.global_rotation.y, 0.0)
	Global.boss_to_player = $FrontOfBodyPivot/FrontOfBody2.global_position
	Global.player_velocity = velocity
	move_and_slide()

func parry() -> void:
	$Animations.play("parry")
	await get_tree().create_timer(0.25).timeout
	parrying = false
	$Animations.play("RESET")
	await get_tree().create_timer(0.25).timeout
	parry_cooldown = false

func get_hit(area: Area3D) -> void:
	if not parrying or (parrying and not area.parryable):
		health -= area.get_parent().damage
		$PlayerGUI.hp.text = "HP: " + str(int(roundf(health)))
		
		if area.knockback:
			get_knockbacked(area.global_position, area.launch_up, area.knockback_power)
	else:
		$PlayerGUI.parry.text = "PARRIED!!!"
		reset_parry_text()
	
	if health <= 0.0:
		can_move = false

func get_knockbacked(position_of_kb : Vector3, launch_up : bool, knockback_power : float) -> void:
	velocity -= (position_of_kb - global_position).normalized() * knockback_power
	
	if launch_up:
		velocity.y = 25.0
	else:
		velocity.y = 0.5
	
	move_and_slide()

func reset_parry_text() -> void:
	await get_tree().create_timer(1.0).timeout
	$PlayerGUI.parry.text = ""
