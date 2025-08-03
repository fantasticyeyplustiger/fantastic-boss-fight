extends CharacterBody3D

const JUMP_VELOCITY : float = 18.0
const GRAVITY : float = 19.6
const WALK_SPEED : float = 15.0
const DASH_SPEED : float = 40.0

const SLIDE_JUMP_SPEED_LIMIT : float = 50.0

## In seconds.
const DASH_TIME : float = 0.2

const PLAYER_HEAD_POSITION : Vector3 = Vector3(0.0, 0.8, 0.0)
const SLIDING_HEAD_POSITION : Vector3 = Vector3(0.0, 0.4, 0.0)
const FORWARD_DIRECTION : Vector3 = Vector3(0.0, 0.0, -1.0)

var dash_direction : Vector3 = Vector3.ZERO
var slide_velocity : Vector3 = Vector3.ZERO

var CAMERA_SENSITIVITY : float = 0.003

var speed : float = 15.0
var jump : float = 18.0
var dash_multiplier : float = 1.0

var health : float = 5000.0

var can_move : bool = true
var parrying : bool = false
var parry_cooldown : bool = false
var sliding : bool = false
var slide_jumped : bool = false
#var slam_jump : bool = false

var dashing : bool = false
var dash_jumped : bool = false
var was_on_floor : bool = false
var should_fall : bool = true
var crushing : bool = false

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
	
	# Just so it doesn't have to repeat the same call over and over
	var on_floor = is_on_floor()
	
	if Input.is_action_just_pressed("jump") and dashing and was_on_floor:
		dash_multiplier = 2.0
		dash_jumped = true
	elif Input.is_action_just_pressed("jump") and on_floor and sliding:
		$JumpSFX.play()
		$ResetSlideJump.stop()
		slide_velocity.y = jump / 1.5
		slide_jumped = true
	#elif Input.is_action_pressed("jump") and on_floor and slam_jump:
		#$JumpSFX.play()
		#velocity.y = jump * 2.0
	
	## CANNOT BE is_action_just_pressed otherwise dash and slide jump don't work as intended.
	elif Input.is_action_pressed("jump") and on_floor:
		$JumpSFX.play()
		velocity.y = jump
	
	#region Dash logic
	if Input.is_action_just_pressed("dash") and not dashing:
		
		was_on_floor = is_on_floor()
		
		dash_direction = get_movement_direction()
	
		# Must dash even if no movement input
		if dash_direction == Vector3.ZERO:
			dash_direction = (head.transform.basis * FORWARD_DIRECTION).normalized()
		
		dashing = true
		can_move = false
		velocity.y = 0.2
		
		# Resets after DASH_TIME seconds.
		reset_dash()
	
	if dashing:
		dash()
	#endregion
	
	#region Slide and Crush logic
	if on_floor and Input.is_action_just_pressed("crush"):
		begin_slide()
		switch_hurtboxes(false)
		sliding = true
	elif not Input.is_action_pressed("crush"):
		sliding = false
		$SlideSFX.stop()
		$Head/Camera3D.position = PLAYER_HEAD_POSITION
		switch_hurtboxes(true)
	
	if sliding:
		velocity *= 0.99 # Slows slide down over time
	
	# Can't be on floor, otherwise LandingSFX can be spammed
	if not on_floor and Input.is_action_just_pressed("crush"):
		velocity.y -= 70.0
		crushing = true
		dashing = false # Cancels dash
	if on_floor and crushing:
		SpawnObject.air_shockwave(global_position, Vector3.ZERO)
		$LandingSFX.play()
		crushing = false
		#slam_jump = true
	
	#endregion
	
	if Input.is_action_just_pressed("parry") and not parrying and not parry_cooldown:
		$PunchSFX.play()
		parrying = true
		parry_cooldown = true
		parry() # 0.25-second window for parrying, 0.5-second cooldown.
	
	if not on_floor and should_fall:
		velocity.y -= GRAVITY * delta
	
	if not dashing and not sliding:
		var direction = get_movement_direction()
		
		# Allow player to slightly tilt direction without losing speed boost
		if slide_jumped:
			velocity.x = lerpf(velocity.x, direction.x * velocity.length(), 0.02)
			velocity.z = lerpf(velocity.z, direction.z * velocity.length(), 0.02)
		
		elif on_floor and can_move:
			dash_jumped = false
			
			if direction:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
			else:
				velocity.x = 0.0
				velocity.z = 0.0
		
		# Being in mid-air means you have inertia
		elif dash_jumped or sliding:
			velocity.x = lerpf(velocity.x, direction.x * speed, delta)
			velocity.z = lerpf(velocity.z, direction.z * speed, delta)
		
		elif can_move:
			velocity.x = lerpf(velocity.x, direction.x * speed, delta * 5.0)
			velocity.z = lerpf(velocity.z, direction.z * speed, delta * 5.0)
	
	
	set_global_variables()
	
	move_and_slide()

func begin_slide() -> void:
	if sliding: return
	
	$ResetSlideJump.start()
	
	var direction = get_movement_direction()
	
	# Must slide no matter what
	if direction == Vector3.ZERO:
			direction = (head.transform.basis * FORWARD_DIRECTION).normalized()
	
	if slide_jumped and not velocity.is_equal_approx(Vector3.ZERO):
		
		var angle : float = velocity.normalized().angle_to(direction)
		
		if velocity.length() < SLIDE_JUMP_SPEED_LIMIT:
			velocity *= 1.5
		velocity = velocity.rotated(Vector3(0.0, 1.0, 0.0), angle)
	else:
		velocity = direction * speed * 1.5
	
	velocity.y = 0.0
	$SlideSFX.play()
	$Head/Camera3D.position = SLIDING_HEAD_POSITION

## Dashes in the direction the player is moving for 0.2 seconds.
# If not moving, dash forward.
func dash() -> void:
	velocity.x = dash_direction.x * DASH_SPEED * dash_multiplier
	velocity.z = dash_direction.z * DASH_SPEED * dash_multiplier

func reset_dash() -> void:
	await get_tree().create_timer(DASH_TIME).timeout
	
	dash_multiplier = 1.0
	dashing = false
	can_move = true
	
	if not dash_jumped:
		velocity = Vector3.ZERO

## Set global variables for boss to use
func set_global_variables() -> void:
	
	Global.player_in_air = not is_on_floor
	Global.player_position = global_position
	Global.front_of_player = $FrontOfBodyPivot/FrontOfBody.global_position
	Global.player_rotation = Vector3($FrontOfBodyPivot.global_rotation.x, $FrontOfBodyPivot/SecondPivot.global_rotation.y, 0.0)
	Global.boss_to_player = $FrontOfBodyPivot/FrontOfBody2.global_position - Vector3(0.0, 0.3, 0.0)
	Global.player_velocity = velocity

func parry() -> void:
	$Animations.play("parry")
	await get_tree().create_timer(0.25).timeout
	parrying = false
	$Animations.play("RESET")
	await get_tree().create_timer(0.25).timeout
	parry_cooldown = false

## Gets the movement direction from the player. Calculates from both input and camera rotation.
func get_movement_direction() -> Vector3:
	var input_direction : Vector2 = Input.get_vector("left", "right", "up", "down")
	var direction : Vector3 = (head.transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	return direction

## Damages the player if possible.
func get_hit(area: Area3D) -> void:
	if (not parrying or not area.parryable) and not dashing:
		
		health -= area.get_parent().damage
		$PlayerGUI.hp.text = "HP: " + str(int(roundf(health)))
		
		get_knockbacked(area.global_position, area.launch_power, area.knockback_power)
	else:
		if parrying:
			$ParrySFX.play()
			$PlayerGUI.parry.text = "PARRIED!!!"
			reset_parry_text()
		else:
			$PlayerGUI.parry.text = "I-FRAMED!"
			reset_parry_text()
	
	if health <= 0.0:
		can_move = false

## Knocks the player back / up depending on parameters given.
# Position of knockback should always the other hitbox's global position.
func get_knockbacked(position_of_kb : Vector3, launch_power : float, knockback_power : float) -> void:
	velocity -= (position_of_kb - global_position).normalized() * knockback_power
	velocity.y = launch_power
	move_and_slide()

func reset_parry_text() -> void:
	await get_tree().create_timer(1.0).timeout
	$PlayerGUI.parry.text = ""

## For swapping between standing and sliding hitboxes.
func switch_hurtboxes(standing : bool) -> void:
	$Hurtbox/Standing.set_deferred("disabled", standing)
	$Hurtbox/Sliding.set_deferred("disabled", not standing)

## Sets slide jump to false. Not actually needed, just more convenient with Timer node
func reset_slide_jump() -> void:
	slide_jumped = false

func reset_slam_jump() -> void:
	pass
	#slam_jump = false
